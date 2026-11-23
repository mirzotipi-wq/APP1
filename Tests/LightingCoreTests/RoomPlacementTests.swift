import XCTest
@testable import LightingCore

final class RoomPlacementTests: XCTestCase {
    func testDefaultPortraitFitsAndPreservesHeightAndDistance() throws {
        let scene = LightingScene.portrait()
        let plan = try RoomPlacementPlan(scene: scene, room: .init())
        XCTAssertEqual(plan.points.count, 5)
        XCTAssertEqual(plan.outsideCount, 0)
        let camera = try XCTUnwrap(plan.points.first { $0.kind == .camera })
        XCTAssertEqual(camera.xFromLeft, 3, accuracy: 1e-10)
        XCTAssertEqual(camera.zFromNear, 5, accuracy: 1e-10)
        XCTAssertEqual(camera.heightMeters, scene.camera.y)
        XCTAssertEqual(camera.horizontalDistanceFromSubject, 3, accuracy: 1e-10)
        let key = try XCTUnwrap(plan.points.first { $0.name == "Key" })
        XCTAssertEqual(key.xFromLeft, 1.5, accuracy: 1e-10)
        XCTAssertEqual(key.zFromNear, 3.2, accuracy: 1e-10)
        XCTAssertEqual(key.id, scene.lights[0].id.uuidString)
    }

    func testQuarterTurnAndHalfTurnRotateWithoutScaling() throws {
        let scene = LightingScene.portrait()
        let quarter = try RoomPlacementPlan(scene: scene, room: .init(yawDegrees: 90))
        let camera = quarter.points[1]
        XCTAssertEqual(camera.xFromLeft, 6, accuracy: 1e-10)
        XCTAssertEqual(camera.zFromNear, 2, accuracy: 1e-10)
        XCTAssertTrue(camera.insideRoom)
        let half = try RoomPlacementPlan(scene: scene, room: .init(yawDegrees: 180))
        XCTAssertEqual(half.points[1].zFromNear, -1, accuracy: 1e-10)
        XCTAssertFalse(half.points[1].insideRoom)
        for (a, b) in zip(quarter.points, half.points) {
            XCTAssertEqual(a.horizontalDistanceFromSubject, b.horizontalDistanceFromSubject, accuracy: 1e-10)
            XCTAssertEqual(a.heightMeters, b.heightMeters)
        }
    }

    func testArbitraryWorldTranslationDoesNotChangeRoomCoordinates() throws {
        let original = LightingScene.portrait()
        var translated = original
        func move(_ p: Position) -> Position { .init(x: p.x + 11, y: p.y, z: p.z - 8) }
        translated.subject = move(original.subject)
        translated.camera = move(original.camera)
        for i in translated.lights.indices { translated.lights[i].position = move(original.lights[i].position) }
        let room = ManualRoom(yawDegrees: 37)
        let a = try RoomPlacementPlan(scene: original, room: room)
        let b = try RoomPlacementPlan(scene: translated, room: room)
        for (p, q) in zip(a.points, b.points) {
            XCTAssertEqual(p.id, q.id)
            XCTAssertEqual(p.xFromLeft, q.xFromLeft, accuracy: 1e-10)
            XCTAssertEqual(p.zFromNear, q.zFromNear, accuracy: 1e-10)
            XCTAssertEqual(p.horizontalDistanceFromSubject, q.horizontalDistanceFromSubject, accuracy: 1e-10)
            XCTAssertEqual(p.insideRoom, q.insideRoom)
        }
    }

    func testOutsideCoordinatesRemainSignedAndNotClamped() throws {
        let scene = LightingScene.portrait()
        let plan = try RoomPlacementPlan(scene: scene, room: .init(widthMeters: 1, depthMeters: 1, subjectX: 0, subjectZ: 0))
        XCTAssertEqual(plan.points[0].xFromLeft, 0)
        XCTAssertTrue(plan.points[0].insideRoom)
        XCTAssertEqual(plan.points[1].zFromNear, 3, accuracy: 1e-10)
        XCTAssertFalse(plan.points[1].insideRoom)
        XCTAssertLessThan(try XCTUnwrap(plan.points.first { $0.name == "Key" }).xFromLeft, 0)
        XCTAssertGreaterThan(plan.outsideCount, 0)
    }

    func testMeasurementInputAcceptsExactLocalizedValuesAndRejectsInvalidText() throws {
        let range = 1.0...30.0
        XCTAssertEqual(RoomMeasurementInput.parse(" 6.35 ", in: range), 6.35)
        XCTAssertEqual(RoomMeasurementInput.parse("6,35", decimalSeparator: ",", in: range), 6.35)
        XCTAssertEqual(RoomMeasurementInput.parse("30", in: range), 30)
        XCTAssertEqual(RoomMeasurementInput.parse("0.01", in: 0...1), 0.01)
        for text in ["", " ", "NaN", "inf", "1e1", "6.3.5", "6m", "0.99", "30.01", "-6", "1,234", "1 2"] {
            XCTAssertNil(RoomMeasurementInput.parse(text, in: range), text)
        }
        XCTAssertNil(RoomMeasurementInput.parse("6.35", decimalSeparator: ",", in: range))
        XCTAssertNil(RoomMeasurementInput.parse("6,35", decimalSeparator: ".", in: range))
        XCTAssertNil(RoomMeasurementInput.parse(String(repeating: "1", count: 40), in: range))
    }

    func testRejectsInvalidRoomAndScene() throws {
        for room in [
            ManualRoom(widthMeters: 0), ManualRoom(depthMeters: .infinity),
            ManualRoom(subjectX: -1), ManualRoom(subjectZ: 8),
            ManualRoom(yawDegrees: .nan), ManualRoom(yawDegrees: 361)
        ] {
            XCTAssertThrowsError(try RoomPlacementPlan(scene: .portrait(), room: room)) {
                XCTAssertEqual($0 as? RoomPlacementError, .invalidRoom)
            }
        }
        var scene = LightingScene.portrait()
        scene.camera.x = .nan
        XCTAssertThrowsError(try RoomPlacementPlan(scene: scene, room: .init()))
    }
}
