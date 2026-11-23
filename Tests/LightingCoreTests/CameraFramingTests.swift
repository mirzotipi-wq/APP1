import Foundation
import XCTest
@testable import LightingCore

final class CameraFramingTests: XCTestCase {
    private func scene(focal: Double = 50) -> LightingScene {
        .init(subject: .init(x: 0, y: 0, z: 0), camera: .init(x: 0, y: 0, z: 3), lights: [], cameraLens: .init(focalLengthMillimeters: focal))
    }

    func testFullFrameFieldOfViewAndCoverage() throws {
        let camera = try XCTUnwrap(CameraFraming(scene: scene()))
        XCTAssertEqual(camera.horizontalFieldOfViewDegrees, 39.597752709, accuracy: 1e-8)
        XCTAssertEqual(camera.verticalFieldOfViewDegrees, 26.991466562, accuracy: 1e-8)
        XCTAssertEqual(camera.subjectPlaneWidthMeters, 2.16, accuracy: 1e-12)
        XCTAssertEqual(camera.subjectPlaneHeightMeters, 1.44, accuracy: 1e-12)
        XCTAssertEqual(CameraFraming.aspectRatio, 1.5)
    }

    func testProjectionCenterEdgesAndBehind() throws {
        let camera = try XCTUnwrap(CameraFraming(scene: scene()))
        let center = try XCTUnwrap(camera.project(.init(x: 0, y: 0, z: 0)))
        XCTAssertEqual(center.x, 0); XCTAssertEqual(center.y, 0); XCTAssertEqual(center.depthMeters, 3)
        XCTAssertTrue(center.isInsideFrame)
        let edge = try XCTUnwrap(camera.project(.init(x: 1.08, y: 0.72, z: 0)))
        XCTAssertEqual(edge.x, 1, accuracy: 1e-12); XCTAssertEqual(edge.y, 1, accuracy: 1e-12)
        let left = try XCTUnwrap(camera.project(.init(x: -2, y: 0, z: 0)))
        XCTAssertLessThan(left.x, -1); XCTAssertFalse(left.isInsideFrame)
        XCTAssertNil(camera.project(.init(x: 0, y: 0, z: 4)))
        XCTAssertNil(camera.project(.init(x: 0, y: 0, z: 2.99)))
        XCTAssertNil(camera.project(.init(x: .nan, y: 0, z: 0)))
    }

    func testFocalLengthAndDistanceChangeFrameLinearly() throws {
        let normal = try XCTUnwrap(CameraFraming(scene: scene()))
        let tele = try XCTUnwrap(CameraFraming(scene: scene(focal: 100)))
        XCTAssertEqual(tele.subjectPlaneWidthMeters, normal.subjectPlaneWidthMeters / 2, accuracy: 1e-12)
        XCTAssertLessThan(tele.horizontalFieldOfViewDegrees, normal.horizontalFieldOfViewDegrees)
        var far = scene(); far.camera.z = 6
        XCTAssertEqual(try XCTUnwrap(CameraFraming(scene: far)).subjectPlaneHeightMeters, normal.subjectPlaneHeightMeters * 2, accuracy: 1e-12)
    }

    func testRotatedAndVerticalCameraConventions() throws {
        var s = scene(); s.camera = .init(x: 3, y: 0, z: 0)
        let side = try XCTUnwrap(CameraFraming(scene: s))
        // Facing -X, image right is world -Z.
        XCTAssertGreaterThan(try XCTUnwrap(side.project(.init(x: 0, y: 0, z: -1))).x, 0)
        XCTAssertGreaterThan(try XCTUnwrap(side.project(.init(x: 0, y: 1, z: 0))).y, 0)
        s.camera = .init(x: 0, y: 3, z: 0)
        let overhead = try XCTUnwrap(CameraFraming(scene: s))
        let p = try XCTUnwrap(overhead.project(s.subject))
        XCTAssertEqual(p.x, 0, accuracy: 1e-12); XCTAssertEqual(p.y, 0, accuracy: 1e-12)
        XCTAssertEqual(p.depthMeters, 3, accuracy: 1e-12)
    }

    func testInvalidLensAndCoincidentOrNearCamera() throws {
        for focal in [0, 13.99, 200.01, .nan, .infinity] {
            let s = scene(focal: focal)
            XCTAssertNil(CameraFraming(scene: s)); XCTAssertThrowsError(try SceneCodec.encode(s))
        }
        var s = scene(); s.camera = s.subject
        XCTAssertNil(CameraFraming(scene: s))
        s.camera.z = 0.01; XCTAssertNil(CameraFraming(scene: s))
        s.camera.z = 0.05; XCTAssertNotNil(CameraFraming(scene: s))
    }

    func testSchema2MigratesOpticsAndDefaultLens() throws {
        var old = LightingScene.portrait(); old.schemaVersion = 2
        old.lights[0].optics = .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.6)
        // Encode the old representation without invoking the current migration first.
        let migrated = try SceneCodec.decode(JSONEncoder().encode(old))
        XCTAssertEqual(migrated.schemaVersion, LightingScene.currentSchemaVersion)
        XCTAssertEqual(migrated.lights, old.lights)
        XCTAssertEqual(migrated.effectiveCameraLens.focalLengthMillimeters, 50)
        XCTAssertNil(migrated.cameraLens)
        old.cameraLens = .init(focalLengthMillimeters: 85)
        XCTAssertThrowsError(try old.validated())
    }

    func testLensAndPosePersist() throws {
        var s = scene(focal: 85); s.camera = .init(x: 1, y: 0.5, z: 4)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SceneFileStore(url: folder.appendingPathComponent("scene.json"))
        try store.save(s)
        XCTAssertEqual(try store.load(), s)
        XCTAssertEqual(try SceneCodec.decode(SceneCodec.encode(s)), s)
    }
}
