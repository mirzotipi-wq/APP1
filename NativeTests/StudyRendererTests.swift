import Foundation
import XCTest
import Metal
import LightingCore
@testable import KeyAndFill

final class StudyRendererTests: XCTestCase {
    func testMetalMatchesCPUOnAvailableDevice() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available; GPU parity is not verified by this simulator.")
        }
        let renderer = try MetalStudyRenderer(device: device)
        for fixture in StudyValidationFixtures.all() {
            let reference = try ReferenceStudyRenderer.render(scene: fixture.scene, width: 96)
            // Exercise all raw kernels, including the deliberate invalid-mask
            // fixture that production precision routing sends to Double CPU.
            let candidate = try renderer.renderValidationFixture(scene: fixture.scene, width: 96)
            let metrics = try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: candidate))
            print("Metal \(fixture.name): mean \(metrics.meanChannelError), max \(metrics.maximumChannelError), outliers \(metrics.fractionAboveFour), invalid match \(metrics.invalidCountMatches)")
            XCTAssertTrue(metrics.passes, "\(fixture.name): \(metrics)")
        }
    }

    func testEnginePublishesRealFrameWithEitherBackend() async throws {
        let scene = LightingScene.portrait()
        let engine = StudyRenderEngine()
        let rendered = try await engine.render(scene: scene, width: 48)
        let reference = try ReferenceStudyRenderer.render(scene: scene, width: 48)
        let metrics = try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: rendered.image))
        XCTAssertTrue(metrics.passes)
        print("Validated engine selected \(rendered.backend.rawValue)")
    }

    func testEngineMannequinUsesCPUAndPublishesDistinctFrame() async throws {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 1.6, z: 1.7)
        scene.cameraLens = .init(focalLengthMillimeters: 70)
        let engine = StudyRenderEngine()
        let rendered = try await engine.render(scene: scene, width: 72, subject: .bust)
        XCTAssertEqual(rendered.backend, .cpu)
        XCTAssertEqual(rendered.image, try PortraitStudyRenderer.render(scene: scene, width: 72))
        XCTAssertEqual(rendered.image.unsupportedPixels, 0)
        XCTAssertNotEqual(rendered.image, try ReferenceStudyRenderer.render(scene: scene, width: 72))
    }

    func testEngineUsesCPUForFarGeometry() async throws {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 1.5, z: 25)
        let engine = StudyRenderEngine()
        let rendered = try await engine.render(scene: scene, width: 48)
        XCTAssertEqual(rendered.backend, .cpu)
    }

    func testNearFieldRoutingDoesNotPermanentlyDowngradeValidatedMetal() async throws {
        guard MTLCreateSystemDefaultDevice() != nil else {
            throw XCTSkip("No Metal device available; per-scene GPU routing cannot be verified.")
        }
        let engine = StudyRenderEngine()
        let normal = LightingScene.portrait()
        let first = try await engine.render(scene: normal, width: 48)
        XCTAssertEqual(first.backend, .metal)

        let guarded = try XCTUnwrap(StudyValidationFixtures.all().first { $0.name == "near-field" }).scene
        XCTAssertFalse(MetalStudyRenderer.supports(guarded))
        let fallback = try await engine.render(scene: guarded, width: 48)
        XCTAssertEqual(fallback.backend, .cpu)
        XCTAssertEqual(fallback.image, try ReferenceStudyRenderer.render(scene: guarded, width: 48))

        let last = try await engine.render(scene: normal, width: 48)
        XCTAssertEqual(last.backend, .metal)
        XCTAssertEqual(last.image, first.image)
    }

    private final class CancellationProbe: @unchecked Sendable {
        private let lock = NSLock()
        private var remainingChecks = 5
        private var enabled = true

        func requested() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            guard enabled else { return false }
            remainingChecks -= 1
            return remainingChecks <= 0
        }

        func resume() {
            lock.lock()
            enabled = false
            lock.unlock()
        }
    }

    func testCancelledInitialParityValidationCanRetryMetalOnSameEngine() async throws {
        guard MTLCreateSystemDefaultDevice() != nil else {
            throw XCTSkip("No Metal device available; interrupted GPU validation cannot be verified.")
        }
        let cancellation = CancellationProbe()
        let engine = StudyRenderEngine(cancellationRequested: { cancellation.requested() })
        let scene = LightingScene.portrait()
        do {
            // Cancellation arrives after the initial request check, while the
            // first CPU parity fixture is being evaluated. No timing sleep is
            // needed, and the real backend is used on both attempts.
            _ = try await engine.render(scene: scene, width: 48)
            XCTFail("Interrupted validation must not return a frame")
        } catch {
            XCTAssertEqual(error as? StudyError, .cancelled)
        }
        cancellation.resume()
        let rendered = try await engine.render(scene: scene, width: 48)
        XCTAssertEqual(rendered.backend, .metal,
                       "An interrupted validation must not permanently select CPU")
        let reference = try ReferenceStudyRenderer.render(scene: scene, width: 48)
        XCTAssertTrue(try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: rendered.image)).passes)
    }

    func testAdditionalCancellationPredicateCannotSuppressTaskCancellation() async throws {
        let engine = StudyRenderEngine(cancellationRequested: { false })
        let operation = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await engine.render(scene: .portrait(), width: 48)
        }
        do {
            _ = try await operation.value
            XCTFail("A cancelled task must not publish a frame")
        } catch {
            XCTAssertEqual(error as? StudyError, .cancelled)
        }
    }

    func testExactWidth24SilhouetteRoutesToCPUWithoutDisablingLaterMetal() async throws {
        guard MTLCreateSystemDefaultDevice() != nil else {
            throw XCTSkip("No Metal device available; silhouette routing and subsequent GPU validation cannot be verified.")
        }
        let silhouette = LightingScene(
            subject: .init(x: 0, y: 1.5, z: 0),
            camera: .init(x: 0, y: 1.5, z: 3),
            lights: [],
            cameraLens: .init(focalLengthMillimeters: 161.27198111190464))
        XCTAssertFalse(MetalStudyRenderer.supports(silhouette, width: 24))

        let engine = StudyRenderEngine()
        let fallback = try await engine.render(scene: silhouette, width: 24)
        XCTAssertEqual(fallback.backend, .cpu)
        XCTAssertEqual(fallback.image, try ReferenceStudyRenderer.render(scene: silhouette, width: 24))

        // The first request requires CPU; a later eligible scene must still
        // perform initial Metal validation on this same engine.
        let normal = LightingScene.portrait()
        XCTAssertTrue(MetalStudyRenderer.supports(normal, width: 48))
        let rendered = try await engine.render(scene: normal, width: 48)
        XCTAssertEqual(rendered.backend, .metal)
        let reference = try ReferenceStudyRenderer.render(scene: normal, width: 48)
        XCTAssertTrue(try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: rendered.image)).passes)
    }

    func testEngineInvalidWidthsPreserveResolutionError() async throws {
        let engine = StudyRenderEngine()
        let scene = LightingScene.portrait()
        for width in [Int.min, 0, 23, 25, 193, 195, Int.max] {
            do {
                _ = try await engine.render(scene: scene, width: width)
                XCTFail("Invalid width \(width) must not return a frame")
            } catch {
                XCTAssertEqual(error as? StudyError, .invalidResolution, "Width \(width)")
            }
        }
    }

    func testMetalInvalidCameraPreservesConstructorErrorBeforePrecisionRouting() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available; direct renderer camera errors cannot be verified.")
        }
        let renderer = try MetalStudyRenderer(device: device)
        for camera in [Position(x: 0, y: 1.2, z: 3), Position(x: 0, y: 1.5, z: 0.25)] {
            let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0), camera: camera, lights: [])
            XCTAssertThrowsError(try renderer.render(scene: scene, width: 24)) { error in
                XCTAssertEqual(error as? StudyError, .invalidCamera)
            }
        }
    }

    func testMetalInvalidWidthsPreserveResolutionErrorBeforePrecisionRouting() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available; direct renderer resolution errors cannot be verified.")
        }
        let renderer = try MetalStudyRenderer(device: device)
        let scene = LightingScene.portrait()
        for width in [Int.min, 0, 23, 25, 193, 195, Int.max] {
            XCTAssertThrowsError(try renderer.render(scene: scene, width: width)) { error in
                XCTAssertEqual(error as? StudyError, .invalidResolution,
                               "Width \(width) must fail resolution validation before precision routing")
            }
        }
    }
}
