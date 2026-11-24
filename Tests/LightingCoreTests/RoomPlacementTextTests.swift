import Foundation
import XCTest
@testable import LightingCore

final class RoomPlacementTextTests: XCTestCase {
    private let english = Locale(identifier: "en_US_POSIX")

    func testQuarterTurnExportsActualRoomCoordinatesAndDoesNotMutateInputs() throws {
        let light = StudioLight(name: "Key", position: .init(x: 2, y: 2.5, z: 4),
                                candela: 900, kelvin: 5600)
        let scene = LightingScene(subject: .init(x: 1, y: 1.5, z: 2),
                                  camera: .init(x: 1, y: 1.25, z: 5), lights: [light])
        let room = ManualRoom(widthMeters: 8.125, depthMeters: 9.5,
                              subjectX: 3, subjectZ: 4, yawDegrees: 90)
        let originalScene = scene, originalRoom = room
        let plan = try RoomPlacementPlan(scene: scene, room: room)
        let text = plan.textSummary(locale: english)

        XCTAssertTrue(text.contains("Room width: 8.125 m"))
        XCTAssertTrue(text.contains("Room depth: 9.50 m"))
        XCTAssertTrue(text.contains("Rig rotation: 90°"))
        XCTAssertTrue(text.contains("Positive rotation turns scene +Z toward room +X"))
        XCTAssertTrue(text.contains("1. Subject\nCenter inside room\nX from left wall: 3.00 m\nZ from near wall: 4.00 m"))
        XCTAssertTrue(text.contains("2. Camera\nCenter inside room\nX from left wall: 6.00 m\nZ from near wall: 4.00 m\nHeight: 1.25 m\nFloor distance to subject: 3.00 m"))
        XCTAssertTrue(text.contains("3. Key\nCenter inside room\nX from left wall: 5.00 m\nZ from near wall: 3.00 m\nHeight: 2.50 m"))
        XCTAssertTrue(text.contains("Floor distance to subject: 2.236068 m"))
        XCTAssertTrue(text.contains("no room sensing or collision checking"))
        XCTAssertEqual(scene, originalScene)
        XCTAssertEqual(room, originalRoom)
        XCTAssertFalse(text.contains(light.id.uuidString))
    }

    func testTinyOutsideCenterAndModifierOverhangNeverBecomeZeroOrClear() throws {
        let outside = StudioLight(name: "Outside", position: .init(x: -2.0000001, y: 1.5, z: 0),
                                  candela: 900, kelvin: 5600)
        let softbox = StudioLight(name: "Softbox", position: .init(x: -1.5001, y: 1.5, z: 0),
                                  candela: 900, kelvin: 5600,
                                  optics: .init(kind: .rectangle,
                                                aimTarget: .init(x: -1.5001, y: 1.5, z: 1),
                                                widthMeters: 1, heightMeters: 1))
        let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1.5, z: 1), lights: [outside, softbox])
        let room = ManualRoom(widthMeters: 4, depthMeters: 4, subjectX: 2, subjectZ: 2)
        let text = try RoomPlacementPlan(scene: scene, room: room).textSummary(locale: english)

        XCTAssertTrue(text.contains("Centers outside room: 1 of 4"))
        XCTAssertTrue(text.contains("3. Outside\nCENTER OUTSIDE ROOM\nX from left wall: between -0.000001 and 0 m"))
        XCTAssertTrue(text.contains("Rectangular emitting-face projections crossing a wall: 1; unavailable: 0"))
        XCTAssertTrue(text.contains("4. Softbox\nCenter inside room"))
        XCTAssertTrue(text.contains("Emitting-face projection crosses left wall boundaries."))
        XCTAssertTrue(text.contains("Projected wall overhang: 0.0001 m"))
        XCTAssertFalse(text.contains("Emitting-face projection within room outline."))
    }

    func testDegenerateAimRemainsUnavailableAndIsNotReportedAsClear() throws {
        let point = Position(x: 0, y: 1.5, z: 0)
        let light = StudioLight(name: "Unknown face", position: point, candela: 900, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: point))
        let scene = LightingScene(subject: point, camera: .init(x: 0, y: 1.5, z: 1), lights: [light])
        let text = try RoomPlacementPlan(scene: scene, room: ManualRoom()).textSummary(locale: english)

        XCTAssertTrue(text.contains("crossing a wall: 0; unavailable: 1"))
        XCTAssertTrue(text.contains("Emitting-face projection unavailable; check aim."))
        XCTAssertFalse(text.contains("Minimum projected wall distance"))
        XCTAssertFalse(text.contains("Emitting-face projection within room outline"))
    }

    func testNamesStayBoundedAndNumberedWithoutChangingLegacyValues() throws {
        // Legacy scene names are bounded by graphemes, not scalar/byte count.
        // A single scalar-heavy grapheme can therefore require truncation.
        let sharedPrefix = "照" + String(repeating: "\u{0301}", count: 400)
        let firstName = sharedPrefix + " first"
        let secondName = sharedPrefix + " second"
        let rtlName = "نور 👩🏽‍💻"
        let names = [firstName, secondName, rtlName, "Key\nINJECT", "\u{200E}"]
        let lights = names.enumerated().map { index, name in
            StudioLight(name: name, position: .init(x: Double(index), y: 1.5, z: 0), candela: 10, kelvin: 5600)
        }
        let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1.5, z: 1), lights: lights)
        let text = try RoomPlacementPlan(scene: scene, room: ManualRoom()).textSummary(locale: english)
        let shown = StudioDisplayName.display(firstName)

        XCTAssertEqual(shown, StudioDisplayName.display(secondName))
        XCTAssertTrue(text.contains("3. \(shown)\n"))
        XCTAssertTrue(text.contains("4. \(shown)\n"))
        XCTAssertTrue(text.contains("5. \(rtlName)\n"))
        XCTAssertTrue(text.contains("6. Key INJECT\n"))
        XCTAssertTrue(text.contains("7. Light\n"))
        XCTAssertFalse(text.contains("Key\nINJECT"))
        XCTAssertFalse(text.contains(firstName))
        XCTAssertEqual(scene.lights.map(\.name), names)
        XCTAssertLessThan(text.utf8.count, 5000)
    }

    func testLocaleAppliesToMeasurementsAndRotationWithoutChangingGeometry() throws {
        let room = ManualRoom(widthMeters: 6.125, depthMeters: 7.5, subjectX: 3.25,
                              subjectZ: 2.125, yawDegrees: -12.5)
        let plan = try RoomPlacementPlan(scene: .portrait(), room: room)
        let french = plan.textSummary(locale: Locale(identifier: "fr_FR"))
        let englishText = plan.textSummary(locale: english)

        XCTAssertTrue(french.contains("Room width: 6,125 m"))
        XCTAssertTrue(french.contains("Room depth: 7,50 m"))
        XCTAssertTrue(french.contains("Rig rotation: -12,5°"))
        XCTAssertTrue(englishText.contains("Room width: 6.125 m"))
        XCTAssertEqual(plan.room, room)
    }
}
