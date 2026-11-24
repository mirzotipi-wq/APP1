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

    func testRoomInputSupportsLocalDigitsWithoutGroupingOrSigns() {
        XCTAssertEqual(RoomMeasurementInput.parse("٦٫٣٥", decimalSeparator: "٫", in: 1...30), 6.35)
        XCTAssertEqual(RoomMeasurementInput.parse("۶,۳۵", decimalSeparator: ",", in: 1...30), 6.35)
        XCTAssertEqual(RoomMeasurementInput.draft(1.23456789, decimalSeparator: ","), "1,23456789")
        XCTAssertEqual(RoomMeasurementInput.parse(RoomMeasurementInput.draft(1.23456789, decimalSeparator: "٫"),
                                                  decimalSeparator: "٫", in: 1...30), 1.23456789)
        for input in ["-0", "−0", "+1", "6٬٣٥", "6٫٣٫٥", "²", "1e1", "1 2"] {
            XCTAssertNil(RoomMeasurementInput.parse(input, decimalSeparator: "٫", in: 0...30), input)
        }
        XCTAssertNil(RoomMeasurementInput.parse("6.35", decimalSeparator: "..", in: 0...30))
    }

    func testResizeRangesPreserveSubjectWithoutSilentRelocation() throws {
        var room = ManualRoom()
        XCTAssertEqual(room.widthEditRange, 3...30)
        XCTAssertEqual(room.depthEditRange, 2...30)
        XCTAssertNil(RoomMeasurementInput.parse("2", in: room.widthEditRange))
        XCTAssertNil(RoomMeasurementInput.parse("1.5", in: room.depthEditRange))
        let originalSubject = (room.subjectX, room.subjectZ)
        room.widthMeters = try XCTUnwrap(RoomMeasurementInput.parse("3.25", in: room.widthEditRange))
        room.depthMeters = try XCTUnwrap(RoomMeasurementInput.parse("2.5", in: room.depthEditRange))
        XCTAssertTrue(room.isValid)
        XCTAssertEqual(room.subjectX, originalSubject.0)
        XCTAssertEqual(room.subjectZ, originalSubject.1)
        room.subjectX = 0.25
        room.subjectZ = 0.75
        XCTAssertEqual(room.widthEditRange, ManualRoom.dimensionRange)
        XCTAssertEqual(room.depthEditRange, ManualRoom.dimensionRange)
        room.widthMeters = try XCTUnwrap(RoomMeasurementInput.parse("1", in: room.widthEditRange))
        XCTAssertTrue(room.isValid)
        XCTAssertEqual(room.subjectX, 0.25)
        room.subjectX = 1
        XCTAssertEqual(room.widthEditRange, 1...30)
        room.subjectX = .nan
        XCTAssertEqual(room.widthEditRange, ManualRoom.dimensionRange)
    }

    func testSignedRoomDisplayDoesNotRoundRealCrossingToZero() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        let scene = LightingScene.portrait()
        let crossing = try RoomPlacementPlan(scene: scene, room: .init(subjectX: 1.4999))
        let key = try XCTUnwrap(crossing.points.first { $0.name == "Key" })
        XCTAssertFalse(key.insideRoom)
        XCTAssertEqual(RoomMeasurementDisplay.distance(key.xFromLeft, locale: locale), "-0.0001 m")
        let touching = try RoomPlacementPlan(scene: scene, room: .init(subjectX: 1.5))
        let contact = try XCTUnwrap(touching.points.first { $0.name == "Key" })
        XCTAssertTrue(contact.insideRoom)
        XCTAssertEqual(RoomMeasurementDisplay.distance(contact.xFromLeft, locale: locale), "0.00 m")
        XCTAssertEqual(RoomMeasurementDisplay.distance(0.003, locale: locale), "0.003 m")
        XCTAssertEqual(RoomMeasurementDisplay.distance(0.00000001, locale: locale), "less than 0.000001 m")
        XCTAssertEqual(RoomMeasurementDisplay.distance(-0.00000001, locale: locale), "between -0.000001 and 0 m")
        XCTAssertEqual(RoomMeasurementDisplay.distance(-0.0, locale: locale), "0.00 m")
        XCTAssertEqual(RoomMeasurementDisplay.distance(3.25, locale: Locale(identifier: "fr_FR")), "3,25 m")
        XCTAssertEqual(RoomMeasurementDisplay.distance(.nan, locale: locale), "Unavailable")
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
