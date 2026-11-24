import XCTest
@testable import LightingCore

final class PortraitStudyTests: XCTestCase {
    private func framedScene() -> LightingScene {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 1.60, z: 1.7)
        scene.cameraLens = .init(focalLengthMillimeters: 70)
        return scene
    }

    func testNearestHeadAndClothingSurfacesHaveAnalyticOutwardNormals() throws {
        let geometry = PortraitGeometry(center: .init(x: 0, y: 0, z: 0))
        let front = SIMD3<Double>(0, 0, -1)
        let noseY = PortraitHeadMesh.ringY(19)
        let nose = PortraitHeadMesh.surfacePoint(y: noseY, angle: 0)
        let head = try XCTUnwrap(geometry.hit(origin: .init(0, noseY, 1), direction: front, minimum: 0.05))
        XCTAssertEqual(head.region, .head)
        // At an actual shared ring vertex, the nearest triangle intersection
        // must reproduce the prescribed continuous face surface.
        XCTAssertEqual(head.distance, 1 - nose.z, accuracy: 1e-9)
        XCTAssertGreaterThan(head.normal.z, 0.65)
        XCTAssertEqual(head.normal.x, 0, accuracy: 1e-8)
        let shoulder = try XCTUnwrap(geometry.hit(origin: .init(0.16, -0.29, 1), direction: front, minimum: 0.05))
        XCTAssertEqual(shoulder.region, .clothing)
        XCTAssertGreaterThan(shoulder.normal.z, 0)
        let length = sqrt(shoulder.normal.x * shoulder.normal.x + shoulder.normal.y * shoulder.normal.y + shoulder.normal.z * shoulder.normal.z)
        XCTAssertEqual(length, 1, accuracy: 1e-12)
        XCTAssertNil(geometry.hit(origin: .init(0.6, 0.2, 1), direction: front, minimum: 0.05))
        XCTAssertTrue(geometry.contains(.init(0, 0, 0)))
        XCTAssertFalse(geometry.contains(.init(0, 0, 1)))
    }

    func testContinuousHeadSurfaceIsSymmetricAndHasIntegratedFacialRelief() throws {
        let mesh = PortraitHeadMesh.standard
        XCTAssertEqual(mesh.triangleCount, 2 * PortraitHeadMesh.longitudeSegments * (PortraitHeadMesh.latitudeSegments - 1))
        for y in [-0.12, -0.08, -0.032, 0.023, 0.08, 0.13] {
            for angle in [0.0, 0.2, 0.7, 1.4, 2.9] {
                let a = PortraitHeadMesh.surfacePoint(y: y, angle: angle)
                let b = PortraitHeadMesh.surfacePoint(y: y, angle: -angle)
                XCTAssertEqual(a.x, -b.x, accuracy: 1e-12)
                XCTAssertEqual(a.y, b.y)
                XCTAssertEqual(a.z, b.z, accuracy: 1e-12)
                let adjacent = PortraitHeadMesh.surfacePoint(y: y + 0.00001, angle: angle)
                XCTAssertLessThan(abs(adjacent.z - a.z), 0.0001)
            }
        }
        let nose = PortraitHeadMesh.surfacePoint(y: -0.032, angle: 0)
        let cheek = PortraitHeadMesh.surfacePoint(y: -0.032, angle: 0.65)
        XCTAssertGreaterThan(nose.z - cheek.z, 0.025)
        let direction = SIMD3<Double>(0, 0, -1)
        XCTAssertFalse(mesh.occludes(origin: .init(0, -0.032, 1), direction: direction, minimum: 1e-5, maximum: 0.5))
        XCTAssertTrue(mesh.occludes(origin: .init(0, -0.032, 1), direction: direction, minimum: 1e-5, maximum: 1.5))
    }

    func testShadowSegmentsStopAtActualLightAndRespectGeometry() {
        let geometry = PortraitGeometry(center: .init(x: 0, y: 0, z: 0))
        let origin = SIMD3<Double>(0, 0, 0.4), direction = SIMD3<Double>(0, 0, -1)
        XCTAssertFalse(geometry.occludes(origin: origin, direction: direction, distance: 0.10))
        XCTAssertTrue(geometry.occludes(origin: origin, direction: direction, distance: 0.80))
        XCTAssertFalse(geometry.occludes(origin: .init(0.4, 0, 0.4), direction: direction, distance: 0.80))
        XCTAssertTrue(geometry.occludes(origin: .init(0.7, 0, 0.2), direction: .init(0, -1, 0), distance: 1))
    }

    func testStudyIsDeterministicAndRespondsToRealLightingAndExposure() throws {
        let scene = framedScene()
        let baseline = try PortraitStudyRenderer.render(scene: scene, width: 72)
        XCTAssertEqual(baseline.width, 72)
        XCTAssertEqual(baseline.height, 48)
        XCTAssertEqual(baseline.rgba.count, 72 * 48 * 4)
        XCTAssertEqual(baseline.unsupportedPixels, 0)
        XCTAssertEqual(baseline, try PortraitStudyRenderer.render(scene: scene, width: 72))
        XCTAssertNotEqual(baseline, try ReferenceStudyRenderer.render(scene: scene, width: 72))
        var dark = scene
        dark.lights = []
        let unlit = try PortraitStudyRenderer.render(scene: dark, width: 72)
        XCTAssertNotEqual(unlit, baseline)
        XCTAssertTrue(stride(from: 3, to: unlit.rgba.count, by: 4).allSatisfy { unlit.rgba[$0] == 255 })
        let center = 4 * (24 * 72 + 36)
        XCTAssertEqual(Array(unlit.rgba[center..<center+3]), [0, 0, 0])
        XCTAssertGreaterThan(Int(baseline.rgba[center]) + Int(baseline.rgba[center+1]) + Int(baseline.rgba[center+2]), 0)
        var brighter = scene
        brighter.previewSettings = .init(whiteBalanceKelvin: 5600, exposureStops: 1)
        let exposed = try PortraitStudyRenderer.render(scene: brighter, width: 72)
        let before = (0..<3).reduce(0) { $0 + Int(baseline.rgba[center + $1]) }
        let after = (0..<3).reduce(0) { $0 + Int(exposed.rgba[center + $1]) }
        XCTAssertGreaterThan(after, before)
    }

    func testTranslationAndPhysicalCameraFraming() throws {
        let scene = framedScene()
        let a = try PortraitStudyRenderer.render(scene: scene, width: 72)
        var moved = scene
        func translate(_ point: Position) -> Position { .init(x: point.x + 8, y: point.y + 3, z: point.z - 6) }
        moved.subject = translate(scene.subject)
        moved.camera = translate(scene.camera)
        for i in moved.lights.indices { moved.lights[i].position = translate(scene.lights[i].position) }
        let b = try PortraitStudyRenderer.render(scene: moved, width: 72)
        XCTAssertEqual(a.unsupportedPixels, b.unsupportedPixels)
        let maximumDifference = zip(a.rgba, b.rgba).map { abs(Int($0) - Int($1)) }.max() ?? 0
        XCTAssertLessThanOrEqual(maximumDifference, 1)
        var wider = scene
        wider.cameraLens = .init(focalLengthMillimeters: 35)
        XCTAssertNotEqual(a, try PortraitStudyRenderer.render(scene: wider, width: 72))
    }

    func testFullResolutionObliqueAreaLitPortraitHasNoInvalidSilhouettePixels() throws {
        var scene = framedScene()
        scene.camera = .init(x: 0.84, y: 1.63, z: 1.45)
        scene.cameraLens = .init(focalLengthMillimeters: 85)
        scene.previewSettings = .init(whiteBalanceKelvin: 4300, exposureStops: 1.25)
        scene.lights[0].optics = .init(kind: .rectangle, widthMeters: 1, heightMeters: 1.2)
        scene.lights[1].optics = .init(kind: .rectangle, widthMeters: 0.8, heightMeters: 0.8)
        scene.lights[2].optics = .init(kind: .rectangle, widthMeters: 0.4, heightMeters: 0.8)
        let image = try PortraitStudyRenderer.render(scene: scene, width: 144)
        XCTAssertEqual(image.unsupportedPixels, 0)
        XCTAssertEqual(image.height, 96)
        XCTAssertFalse(stride(from: 0, to: image.rgba.count, by: 4).contains { i in
            image.rgba[i] == 255 && image.rgba[i + 1] == 0 && image.rgba[i + 2] == 255
        })
    }

    func testInvalidCameraNearFieldAndCancellationAreHonest() throws {
        var scene = framedScene()
        XCTAssertThrowsError(try PortraitStudyRenderer.render(scene: scene, width: 145)) {
            XCTAssertEqual($0 as? StudyError, .invalidResolution)
        }
        XCTAssertThrowsError(try PortraitStudyRenderer.render(scene: scene, width: 72, isCancelled: { true })) {
            XCTAssertEqual($0 as? StudyError, .cancelled)
        }
        scene.camera = scene.subject
        XCTAssertThrowsError(try PortraitStudyRenderer.render(scene: scene, width: 72)) {
            XCTAssertEqual($0 as? StudyError, .invalidCamera)
        }
        scene = framedScene()
        scene.lights = [.init(name: "Near", position: .init(x: 0, y: scene.subject.y, z: scene.subject.z + 0.10),
                              candela: 500, kelvin: 5600)]
        let near = try PortraitStudyRenderer.render(scene: scene, width: 72)
        XCTAssertGreaterThan(near.unsupportedPixels, 0)
    }
}
