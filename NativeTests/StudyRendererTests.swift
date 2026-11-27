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

    func testMetalRawDispatchRejectsInvalidPackedMetadata() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available; raw metadata rejection is not verified.")
        }
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let library = try XCTUnwrap(device.makeDefaultLibrary())
        let function = try XCTUnwrap(library.makeFunction(name: "keyfillStudy"))
        let pipeline = try device.makeComputePipelineState(function: function)
        let scene = try XCTUnwrap(StudyValidationFixtures.all().first { $0.name == "soft" }).scene
        let input = try StudyComputeInput(scene: scene, width: 24)
        let pixelCount = input.width * input.height
        let probe = (input.height / 2) * input.width + input.width / 2
        let allUnsupported = Data(repeating: 1, count: pixelCount)
        let allSupported = Data(repeating: 0, count: pixelCount)

        func pixel(_ data: Data, at index: Int) -> [UInt8] {
            Array(data[(index * 4)..<(index * 4 + 4)])
        }
        func render(_ label: String, _ parameters: [SIMD4<Float>],
                    _ samples: [SIMD4<Float>], _ areas: [SIMD4<Float>]) throws -> Data {
            try rawStudyRGBA(device: device, queue: queue, pipeline: pipeline,
                             label: label, width: input.width, height: input.height,
                             parameters: parameters, samples: samples, areas: areas)
        }
        func assertRejected(_ label: String, _ parameters: [SIMD4<Float>],
                            _ samples: [SIMD4<Float>], _ areas: [SIMD4<Float>],
                            expectedMask: Data) throws {
            let raw = try render(label, parameters, samples, areas)
            XCTAssertEqual(pixel(raw, at: probe), [255, 0, 255, 0], label)
            let decoded = try StudyImage.fromComputeRGBA(width: input.width, height: input.height, data: raw)
            XCTAssertEqual(pixel(decoded.rgba, at: probe), [255, 0, 255, 255], label)
            XCTAssertEqual(decoded.unsupportedPixelMask, expectedMask, label)
            XCTAssertEqual(decoded.unsupportedPixels, expectedMask.reduce(0) { $0 + Int($1) }, label)
        }

        // Keep every buffer valid and initialized, including complete records
        // for the first counts beyond the supported 768-sample/12-area limits.
        let sampleRecord = try XCTUnwrap(input.samples.count >= 3 ? Array(input.samples.prefix(3)) : nil)
        let areaRecord = try XCTUnwrap(input.areas.count >= 3 ? Array(input.areas.prefix(3)) : nil)
        var samples = input.samples
        var areas = input.areas
        while samples.count < 769 * 3 { samples.append(contentsOf: sampleRecord) }
        while areas.count < 13 * 3 { areas.append(contentsOf: areaRecord) }
        let validRaw = try render("valid metadata", input.parameters, samples, areas)
        let valid = try StudyImage.fromComputeRGBA(width: input.width, height: input.height, data: validRaw)
        XCTAssertEqual(valid.unsupportedPixelMask, allSupported)
        XCTAssertEqual(valid.unsupportedPixels, 0)

        // With no lights, geometry is exactly black and the background is
        // (18,20,24). Establish a geometry pixel and the expected tag mask
        // independently of the malformed dispatches, without tangent tolerances.
        var emptyParameters = input.parameters
        emptyParameters[5].x = 0
        emptyParameters[5].y = 0
        let emptyRaw = try render("valid empty metadata", emptyParameters, [], [])
        let empty = try StudyImage.fromComputeRGBA(width: input.width, height: input.height, data: emptyRaw)
        XCTAssertEqual(empty.unsupportedPixelMask, allSupported)
        XCTAssertEqual(pixel(emptyRaw, at: probe), [0, 0, 0, 255])
        let geometryMask = Data((0..<pixelCount).map { index -> UInt8 in
            let rgba = pixel(emptyRaw, at: index)
            XCTAssertTrue(rgba == [0, 0, 0, 255] || rgba == [18, 20, 24, 255],
                          "Unexpected unlit pixel \(index): \(rgba)")
            return rgba == [0, 0, 0, 255] ? 1 : 0
        })
        XCTAssertEqual(geometryMask[probe], 1)
        XCTAssertTrue(geometryMask.contains(0), "The control must also exercise background pixels")

        // Mutate packed rows after construction: public constructors reject
        // several of these values before the actual Metal kernel is reached.
        let invalidGrids: [(name: String, value: Float)] = [
            ("zero", 0), ("negative", -1), ("below", 7), ("fractional", 8.5),
            ("above", 9), ("reference-only", 32), ("nan", .nan),
            ("positive-infinity", .infinity), ("negative-infinity", -.infinity)
        ]
        for value in invalidGrids {
            var parameters = input.parameters
            parameters[5].w = value.value
            try assertRejected("grid \(value.name)", parameters, samples, areas, expectedMask: allUnsupported)
            parameters[5].x = 0
            parameters[5].y = 0
            try assertRejected("empty grid \(value.name)", parameters, [], [], expectedMask: allUnsupported)
        }

        let invalidCounts: [(name: String, component: Int, value: Float)] = [
            ("sample-negative", 0, -1), ("sample-fractional", 0, 0.5),
            ("sample-over-limit", 0, 769), ("sample-nan", 0, .nan),
            ("sample-positive-infinity", 0, .infinity), ("sample-negative-infinity", 0, -.infinity),
            ("area-negative", 1, -1), ("area-fractional", 1, 0.5),
            ("area-over-limit", 1, 13), ("area-nan", 1, .nan),
            ("area-positive-infinity", 1, .infinity), ("area-negative-infinity", 1, -.infinity)
        ]
        for value in invalidCounts {
            var parameters = input.parameters
            parameters[5][value.component] = value.value
            try assertRejected(value.name, parameters, samples, areas, expectedMask: allUnsupported)
        }

        let invalidTags: [(name: String, value: Float)] = [
            ("negative", -1), ("below-one", 0.5), ("fractional", 1.5),
            ("over-area-count", input.parameters[5].y + 1), ("nan", .nan),
            ("positive-infinity", .infinity), ("negative-infinity", -.infinity)
        ]
        for value in invalidTags {
            var taggedSamples = samples
            taggedSamples[2].w = value.value
            // Tags are examined only on geometry; background stays supported.
            try assertRejected("tag \(value.name)", input.parameters, taggedSamples, areas,
                               expectedMask: geometryMask)
        }
    }

    /// Test-only raw submission: do not route through constructor validation or
    /// the CPU fallback when testing the kernel's packed-metadata guards.
    private func rawStudyRGBA(device: MTLDevice, queue: MTLCommandQueue,
                              pipeline: MTLComputePipelineState, label: String,
                              width: Int, height: Int, parameters: [SIMD4<Float>],
                              samples: [SIMD4<Float>], areas: [SIMD4<Float>]) throws -> Data {
        func buffer(_ rows: [SIMD4<Float>]) throws -> MTLBuffer {
            // Even a zero count must bind an initialized 16-byte dummy row.
            let storage = rows.isEmpty ? [SIMD4<Float>.zero] : rows
            return try storage.withUnsafeBufferPointer { pointer in
                let base = try XCTUnwrap(pointer.baseAddress)
                return try XCTUnwrap(device.makeBuffer(bytes: UnsafeRawPointer(base),
                                                      length: pointer.count * MemoryLayout<SIMD4<Float>>.stride,
                                                      options: .storageModeShared))
            }
        }
        let parameterBuffer = try buffer(parameters)
        let sampleBuffer = try buffer(samples)
        let areaBuffer = try buffer(areas)
        let byteCount = width * height * 4
        let output = try XCTUnwrap(device.makeBuffer(length: byteCount, options: .storageModeShared))
        output.contents().initializeMemory(as: UInt8.self, repeating: 0xA5, count: byteCount)
        let command = try XCTUnwrap(queue.makeCommandBuffer())
        command.label = "Key & Fill raw metadata: \(label)"
        let encoder = try XCTUnwrap(command.makeComputeCommandEncoder())
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(parameterBuffer, offset: 0, index: 0)
        encoder.setBuffer(sampleBuffer, offset: 0, index: 1)
        encoder.setBuffer(areaBuffer, offset: 0, index: 2)
        encoder.setBuffer(output, offset: 0, index: 3)
        var dimensions = SIMD2<UInt32>(UInt32(width), UInt32(height))
        encoder.setBytes(&dimensions, length: MemoryLayout<SIMD2<UInt32>>.stride, index: 4)
        encoder.dispatchThreadgroups(MTLSize(width: width, height: height, depth: 1),
                                     threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
        encoder.endEncoding()
        command.commit()
        command.waitUntilCompleted()
        guard command.status == .completed else {
            XCTFail("Raw Metal dispatch \(label) failed: \(String(describing: command.error))")
            throw MetalStudyError.command
        }
        return Data(bytes: output.contents(), count: byteCount)
    }
}
