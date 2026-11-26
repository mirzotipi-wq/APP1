import XCTest
@testable import LightingCore

final class PortraitCameraDepthTests: XCTestCase {
    private func scene(distance: Double, axis: Int) -> LightingScene {
        var scene = LightingScene.portrait()
        scene.subject = .init(x: 0, y: 0, z: 0)
        scene.camera = axis == 0 ? .init(x: 0.001, y: distance, z: 0) :
            axis == 1 ? .init(x: 0, y: 0, z: distance) : .init(x: distance, y: 0, z: 0)
        scene.cameraLens = .init(focalLengthMillimeters: 50)
        scene.lights = []
        return scene
    }

    func testNearPlaneCannotExposeTheBackOfAClosedMannequin() {
        // No lights: magenta would falsely attribute a camera-clipping defect
        // to unsupported lighting. Reject the camera instead of publishing it.
        for distance in [0.171, 0.18] {
            XCTAssertThrowsError(try PortraitStudyRenderer.render(scene: scene(distance: distance, axis: 0), width: 24)) {
                XCTAssertEqual($0 as? StudyError, .invalidCamera)
            }
        }
    }

    func testCloseFrontAndSideCamerasAndSafeOverheadViewsRemainSupported() throws {
        for axis in 0...2 {
            for distance in [0.171, 0.18, 0.20, 0.25, 0.30] where axis != 0 || distance >= 0.20 {
                let image = try PortraitStudyRenderer.render(scene: scene(distance: distance, axis: axis), width: 24)
                XCTAssertEqual(image.unsupportedPixels, 0, "axis \(axis), distance \(distance)")
                XCTAssertTrue(image.unsupportedPixelMask.allSatisfy { $0 == 0 })
            }
        }
    }

    func testClippedCameraWitnessHasAFrontEntryAndABackExit() throws {
        let input = scene(distance: 0.18, axis: 0)
        let camera = try XCTUnwrap(CameraFraming(scene: input))
        let geometry = PortraitGeometry(center: input.subject)
        let origin = SIMD3<Double>(input.camera.x, input.camera.y, input.camera.z)
        let forward = SIMD3<Double>(camera.forward.x, camera.forward.y, camera.forward.z)
        let right = SIMD3<Double>(camera.right.x, camera.right.y, camera.right.z)
        let up = SIMD3<Double>(camera.up.x, camera.up.y, camera.up.z)
        func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x*b.x + a.y*b.y + a.z*b.z }
        var witnessedClippedExit = false
        // The center ray can hit a separate neck entry. Find an actual pixel
        // whose nearest retained face is an exit, using the shipped camera grid.
        for y in 0..<16 {
            for x in 0..<24 {
                let px = (2 * (Double(x) + 0.5) / 24 - 1) * 36 / 100
                let py = (1 - 2 * (Double(y) + 0.5) / 16) * 24 / 100
                let vector = forward + right * px + up * py
                let ray = vector / sqrt(dot(vector, vector))
                let minimum = CameraFraming.minimumDepthMeters / dot(ray, forward)
                guard let exit = geometry.hit(origin: origin, direction: ray, minimum: minimum),
                      dot(exit.geometricNormal, -ray) < 0 else { continue }
                let entry = try XCTUnwrap(geometry.hit(origin: origin, direction: ray, minimum: 1e-6))
                XCTAssertLessThan(entry.distance, minimum)
                XCTAssertGreaterThan(dot(entry.geometricNormal, -ray), 0)
                XCTAssertGreaterThanOrEqual(exit.distance, minimum)
                witnessedClippedExit = true
            }
        }
        XCTAssertTrue(witnessedClippedExit)
    }

    func testClippedHeadCannotRevealAFrontFacingNeckAtAnyPreviewWidth() {
        var input = scene(distance: 0.18, axis: 0)
        // Independent W32 scan: every low-resolution pixel's head entry is
        // clipped, while the later neck entry faces the camera. Normal-facing
        // validation alone therefore cannot detect the hidden first surface.
        input.camera = .init(x: 0.0023027557228276507, y: 0.16976801953781231,
                             z: 0.008594001355012789)
        input.cameraLens = .init(focalLengthMillimeters: 200)
        for width in [24, 48, 72, 120, 144] {
            XCTAssertThrowsError(try PortraitStudyRenderer.render(scene: input, width: width)) {
                XCTAssertEqual($0 as? StudyError, .invalidCamera)
            }
        }
    }
}
