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
            let candidate = try renderer.render(scene: fixture.scene, width: 96)
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

    func testEngineUsesCPUForFarGeometry() async throws {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 1.5, z: 25)
        let engine = StudyRenderEngine()
        let rendered = try await engine.render(scene: scene, width: 48)
        XCTAssertEqual(rendered.backend, .cpu)
    }
}
