import XCTest
@testable import LightingCore

final class RoomRotationTests: XCTestCase {
    func testHalfTurnIsRelativeAtArbitraryAnglesAndBoundaries() {
        let fixtures: [(Double, Double)] = [
            (0, 180), (45, -135), (-45, 135), (179, -1),
            (-179, 1), (180, 0), (-180, 0), (360, 180), (-360, 180)
        ]
        for (initial, expected) in fixtures {
            var room = ManualRoom(yawDegrees: initial)
            XCTAssertTrue(room.rotate(byDegrees: 180))
            XCTAssertEqual(room.yawDegrees, expected, accuracy: 1e-12)
            XCTAssertTrue(room.isValid)
            XCTAssertTrue((-180...180).contains(room.yawDegrees))
        }
    }

    func testTwoHalfTurnsPreserveActualPlacementAndModifierProjection() throws {
        var scene = LightingScene.portrait()
        scene.lights[0].optics = .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.8)
        let originalScene = scene
        for initial in [-360.0, -180, -137.25, -45, 0, 45, 137.25, 180, 360] {
            var room = ManualRoom(widthMeters: 12, depthMeters: 11,
                                  subjectX: 5.25, subjectZ: 4.75, yawDegrees: initial)
            let originalRoom = room
            let before = try RoomPlacementPlan(scene: scene, room: room)
            XCTAssertTrue(room.rotate(byDegrees: 180))
            XCTAssertTrue(room.rotate(byDegrees: 180))
            let after = try RoomPlacementPlan(scene: scene, room: room)
            XCTAssertEqual(room.widthMeters, originalRoom.widthMeters)
            XCTAssertEqual(room.depthMeters, originalRoom.depthMeters)
            XCTAssertEqual(room.subjectX, originalRoom.subjectX)
            XCTAssertEqual(room.subjectZ, originalRoom.subjectZ)
            for (a, b) in zip(before.points, after.points) {
                XCTAssertEqual(a.id, b.id)
                XCTAssertEqual(a.xFromLeft, b.xFromLeft, accuracy: 1e-10)
                XCTAssertEqual(a.zFromNear, b.zFromNear, accuracy: 1e-10)
                XCTAssertEqual(a.heightMeters, b.heightMeters)
                XCTAssertEqual(a.horizontalDistanceFromSubject, b.horizontalDistanceFromSubject)
                XCTAssertEqual(a.insideRoom, b.insideRoom)
            }
            XCTAssertEqual(before.modifierFootprints.count, after.modifierFootprints.count)
            for (a, b) in zip(before.modifierFootprints, after.modifierFootprints) {
                XCTAssertEqual(a.id, b.id)
                XCTAssertEqual(a.crossedWalls, b.crossedWalls)
                XCTAssertEqual(a.corners.count, b.corners.count)
                for (p, q) in zip(a.corners, b.corners) {
                    XCTAssertEqual(p.xFromLeft, q.xFromLeft, accuracy: 1e-10)
                    XCTAssertEqual(p.zFromNear, q.zFromNear, accuracy: 1e-10)
                }
            }
        }
        XCTAssertEqual(scene, originalScene)
    }

    func testRelativeRotationPreservesSignedBoundaryAndDistanceGeometry() throws {
        let scene = LightingScene.portrait()
        var room = ManualRoom(subjectX: 3, subjectZ: 2, yawDegrees: 45)
        let before = try RoomPlacementPlan(scene: scene, room: room)
        room.rotate(byDegrees: 180)
        let after = try RoomPlacementPlan(scene: scene, room: room)
        for (a, b) in zip(before.points, after.points) {
            // A half-turn negates each offset around the measured subject;
            // equipment outside the room remains signed rather than clamped.
            XCTAssertEqual(b.xFromLeft - room.subjectX, -(a.xFromLeft - room.subjectX), accuracy: 1e-10)
            XCTAssertEqual(b.zFromNear - room.subjectZ, -(a.zFromNear - room.subjectZ), accuracy: 1e-10)
            XCTAssertEqual(a.horizontalDistanceFromSubject, b.horizontalDistanceFromSubject)
            XCTAssertEqual(a.heightMeters, b.heightMeters)
        }
        XCTAssertLessThan(after.points[1].zFromNear, 0)
        XCTAssertFalse(after.points[1].insideRoom)
    }

    func testFiniteLargeDeltasNormalizeAndInvalidInputsDoNotMutateRoom() {
        for delta in [Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude, 0, 720, -720] {
            var room = ManualRoom(yawDegrees: 45)
            XCTAssertTrue(room.rotate(byDegrees: delta))
            XCTAssertTrue(room.yawDegrees.isFinite)
            XCTAssertTrue((-180...180).contains(room.yawDegrees))
            XCTAssertTrue(room.isValid)
        }
        for delta in [Double.nan, .infinity, -.infinity] {
            var room = ManualRoom(yawDegrees: 45)
            let original = room
            XCTAssertFalse(room.rotate(byDegrees: delta))
            XCTAssertEqual(room, original)
        }
        for invalid in [ManualRoom(yawDegrees: 361), ManualRoom(widthMeters: 0)] {
            var room = invalid
            XCTAssertFalse(room.rotate(byDegrees: 180))
            XCTAssertEqual(room, invalid)
        }
        var invalidYaw = ManualRoom(yawDegrees: .nan)
        XCTAssertFalse(invalidYaw.rotate(byDegrees: 180))
        XCTAssertTrue(invalidYaw.yawDegrees.isNaN)
        var zero = ManualRoom(yawDegrees: -180)
        zero.rotate(byDegrees: 180)
        XCTAssertEqual(zero.yawDegrees, 0)
        XCTAssertEqual(zero.yawDegrees.sign, .plus)
    }
}
