import Foundation
import XCTest
import Metal
import LightingCore
@testable import KeyAndFill

final class StudyPrecisionMatrixTests: XCTestCase {
    func testMetalMatchesCPUForEightRequiredPrecisionFixtures() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available; the eight-case GPU precision matrix is not verified.")
        }
        let renderer = try MetalStudyRenderer(device: device)
        let width = 192
        var fixtures: [(String, LightingScene)] = []
        let base = StudyValidationFixtures.all().first { $0.name == "soft" }!.scene

        // Keep these constructors and UUID normalization aligned with the
        // eight required cases in scripts/precision-boundary.swift.
        for distance in [19.0, 19.999999, 20.0] {
            for focal in [85.0, 200.0] {
                var scene = base
                scene.camera = .init(x: scene.subject.x, y: scene.subject.y, z: scene.subject.z + distance)
                scene.cameraLens = .init(focalLengthMillimeters: focal)
                fixtures.append(("area-camera-\(distance)-lens-\(Int(focal))", scene))
            }
        }

        // Both translations start from the sixth area-camera fixture, exactly
        // as in the host fixture generator: distance 20 m, focal length 200 mm.
        for offset in [SIMD3<Double>(77, 70, 75), SIMD3<Double>(-77, -70, -75)] {
            var scene = fixtures[5].1
            func move(_ p: Position) -> Position {
                .init(x: p.x + offset.x, y: p.y + offset.y, z: p.z + offset.z)
            }
            scene.subject = move(scene.subject)
            scene.camera = move(scene.camera)
            for index in scene.lights.indices {
                scene.lights[index].position = move(scene.lights[index].position)
                if let aim = scene.lights[index].optics?.aimTarget {
                    scene.lights[index].optics?.aimTarget = move(aim)
                }
            }
            fixtures.append(("world-translation-\(Int(offset.x))", scene))
        }

        XCTAssertEqual(fixtures.count, 8)
        for (name, inputScene) in fixtures {
            var scene = try inputScene.validated()
            for index in scene.lights.indices {
                scene.lights[index].id = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", index + 1))!
            }
            let cameraDistance = scene.camera.distance(to: scene.subject)
            let lightDistance = scene.lights.map { $0.position.distance(to: scene.subject) }.max() ?? 0
            guard cameraDistance <= 20, lightDistance <= 20 else { throw StudyError.invalidScene }

            let reference = try ReferenceStudyRenderer.render(scene: scene, width: width)
            // This entry point submits the raw Metal kernels without allowing
            // production precision routing to satisfy the test with CPU output.
            let candidate = try renderer.renderValidationFixture(scene: scene, width: width)
            let metrics = try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: candidate),
                                        "\(name): invalid parity inputs")
            print("Metal precision \(name): mean \(metrics.meanChannelError), max \(metrics.maximumChannelError), outliers \(metrics.fractionAboveFour), mask \(metrics.invalidMaskMatches)")
            XCTAssertTrue(metrics.passes, "\(name): \(metrics)")
            XCTAssertLessThanOrEqual(metrics.maximumChannelError, 1, "\(name): \(metrics)")
            XCTAssertEqual(candidate.unsupportedPixelMask, reference.unsupportedPixelMask,
                           "\(name): unsupported pixel masks must match exactly")
        }
    }
}
