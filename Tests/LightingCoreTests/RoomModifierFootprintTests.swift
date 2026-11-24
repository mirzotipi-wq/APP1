import XCTest
@testable import LightingCore

final class RoomModifierFootprintTests: XCTestCase {
    private func scene(light: StudioLight) -> LightingScene {
        .init(subject: .init(x: 0, y: 1.5, z: 0),
              camera: .init(x: 0, y: 1.5, z: 1), lights: [light])
    }
    private var room: ManualRoom {
        .init(widthMeters: 4, depthMeters: 4, subjectX: 2, subjectZ: 2)
    }
    private func rectangle(at p: Position, aim: Position, width: Double = 1, height: Double = 1) -> StudioLight {
        .init(name: "Softbox", position: p, candela: 900, kelvin: 5600,
              optics: .init(kind: .rectangle, aimTarget: aim, widthMeters: width, heightMeters: height))
    }

    func testCenterInsideDoesNotHideCrossingModifier() throws {
        let light = rectangle(at: .init(x: -1.75, y: 1.5, z: 0), aim: .init(x: -1.75, y: 1.5, z: 1))
        let plan = try RoomPlacementPlan(scene: scene(light: light), room: room)
        XCTAssertEqual(plan.outsideCount, 0)
        XCTAssertEqual(plan.crossingModifierCount, 1)
        let face = try XCTUnwrap(plan.modifierFootprints.first)
        XCTAssertEqual(face.id, light.id)
        XCTAssertEqual(face.corners.count, 4)
        XCTAssertEqual(face.isInsideRoom, false)
        XCTAssertEqual(face.crossedWalls, [.left])
        XCTAssertEqual(try XCTUnwrap(face.minimumWallClearanceMeters), -0.25, accuracy: 1e-10)
    }

    func testQuarterTurnChangesWallButPreservesOverhang() throws {
        let light = rectangle(at: .init(x: -1.75, y: 1.5, z: 0), aim: .init(x: -1.75, y: 1.5, z: 1))
        var rotated = room
        rotated.yawDegrees = 90
        let face = try XCTUnwrap(RoomPlacementPlan(scene: scene(light: light), room: rotated).modifierFootprints.first)
        XCTAssertEqual(face.crossedWalls, [.far])
        XCTAssertEqual(try XCTUnwrap(face.minimumWallClearanceMeters), -0.25, accuracy: 1e-10)
    }

    func testVerticalAimProjectsBothDimensionsAndExactWallContact() throws {
        let light = rectangle(at: .init(x: 1.5, y: 2, z: 1.5), aim: .init(x: 1.5, y: 0, z: 1.5))
        let plan = try RoomPlacementPlan(scene: scene(light: light), room: room)
        let face = try XCTUnwrap(plan.modifierFootprints.first)
        XCTAssertEqual(face.isInsideRoom, true)
        XCTAssertEqual(face.crossedWalls, [])
        XCTAssertEqual(try XCTUnwrap(face.minimumWallClearanceMeters), 0, accuracy: 1e-10)
        XCTAssertEqual(Set(face.corners.map(\.xFromLeft)), [3, 4])
        XCTAssertEqual(Set(face.corners.map(\.zFromNear)), [3, 4])
        var bigger = light
        bigger.optics?.heightMeters = 2
        bigger.optics?.widthMeters = 2
        let overhang = try XCTUnwrap(RoomPlacementPlan(scene: scene(light: bigger), room: room).modifierFootprints.first)
        XCTAssertEqual(overhang.crossedWalls, [.right, .far])
        XCTAssertEqual(try XCTUnwrap(overhang.minimumWallClearanceMeters), -0.5, accuracy: 1e-10)
    }

    func testDegenerateAimIsUnavailableRatherThanClear() throws {
        let p = Position(x: 0, y: 1.5, z: 0)
        let light = rectangle(at: p, aim: p)
        let plan = try RoomPlacementPlan(scene: scene(light: light), room: room)
        let face = try XCTUnwrap(plan.modifierFootprints.first)
        XCTAssertFalse(face.isAvailable)
        XCTAssertNil(face.isInsideRoom)
        XCTAssertNil(face.minimumWallClearanceMeters)
        XCTAssertEqual(plan.unavailableModifierCount, 1)
        XCTAssertEqual(plan.crossingModifierCount, 0)
    }

    func testNonRectangularEmittersHaveNoClaimedFootprint() throws {
        var rig = LightingScene.portrait()
        rig.lights[0].optics = .init(kind: .directional)
        let original = rig
        let plan = try RoomPlacementPlan(scene: rig, room: room)
        XCTAssertTrue(plan.modifierFootprints.isEmpty)
        XCTAssertEqual(rig, original)
    }

    func testWorldTranslationPreservesProjectedCorners() throws {
        let light = rectangle(at: .init(x: -1.75, y: 1.5, z: 0.2), aim: .init(x: -1, y: 0, z: 1))
        let original = scene(light: light)
        var moved = original
        func move(_ p: Position) -> Position { .init(x: p.x + 8, y: p.y, z: p.z - 6) }
        moved.subject = move(original.subject)
        moved.camera = move(original.camera)
        moved.lights[0].position = move(light.position)
        moved.lights[0].optics?.aimTarget = move(try XCTUnwrap(light.optics?.aimTarget))
        var angled = room
        angled.yawDegrees = 37
        let a = try XCTUnwrap(RoomPlacementPlan(scene: original, room: angled).modifierFootprints.first)
        let b = try XCTUnwrap(RoomPlacementPlan(scene: moved, room: angled).modifierFootprints.first)
        XCTAssertEqual(a.crossedWalls, b.crossedWalls)
        for (p, q) in zip(a.corners, b.corners) {
            XCTAssertEqual(p.xFromLeft, q.xFromLeft, accuracy: 1e-10)
            XCTAssertEqual(p.zFromNear, q.zFromNear, accuracy: 1e-10)
        }
    }
}
