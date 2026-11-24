import Foundation
import XCTest
import LightingCore

final class DevelopmentGeometryTests: XCTestCase {
    func testSchemaFivePreservesRoomAndRollAndReadsLegacyFour() throws {
        var scene = LightingScene.portrait()
        scene.placementRoom = .init(widthMeters: 1, depthMeters: 30, subjectX: 1,
                                    subjectZ: 30, yawDegrees: -360, ceilingHeightMeters: 1)
        scene.lights[0].optics = .init(kind: .rectangle, rollDegrees: -180)
        let restored = try SceneCodec.decode(SceneCodec.encode(scene))
        XCTAssertEqual(restored.schemaVersion, 5)
        XCTAssertEqual(restored, scene)
        scene.placementRoom?.ceilingHeightMeters = Double(1).nextDown
        XCTAssertThrowsError(try SceneCodec.encode(scene))
        scene.placementRoom = nil
        scene.lights[0].optics?.rollDegrees = Double(180).nextUp
        XCTAssertThrowsError(try SceneCodec.encode(scene))
        scene.lights[0].optics?.rollDegrees = nil
        scene.schemaVersion = 4
        let legacy = try SceneCodec.decode(JSONEncoder().encode(scene))
        XCTAssertEqual(legacy.schemaVersion, 5)
        XCTAssertNil(legacy.placementRoom)
        XCTAssertNil(legacy.lights[0].optics?.rollDegrees)
        XCTAssertEqual(legacy.lights, scene.lights)
    }

    func testARQuarterTurnKeepsAuthoredHeightAndOneToOneDistances() throws {
        let scene = LightingScene(subject: .init(x: 2, y: 1.5, z: 3),
                                  camera: .init(x: 2, y: 1.5, z: 6), lights: [
            .init(name: "Key", position: .init(x: 5, y: 2.5, z: 7), candela: 900, kelvin: 5600)
        ])
        let layout = try ARPlacementLayout(scene: scene, origin: .init(x: 10, y: 0.25, z: -4), yawDegrees: 90)
        XCTAssertEqual(layout.items.map(\.position), [.init(x: 10, y: 1.75, z: -4),
                        .init(x: 13, y: 1.75, z: -4), .init(x: 14, y: 2.75, z: -7)])
        XCTAssertEqual(layout.items[2].floorPosition, .init(x: 14, y: 0.25, z: -7))
        XCTAssertEqual(layout.items[2].heightAboveFloorMeters, 2.5)
        XCTAssertEqual(layout.items[2].horizontalDistanceFromSubjectMeters, 5)
        XCTAssertEqual(layout.items[2].distanceFromSubjectMeters, sqrt(26), accuracy: 1e-12)
        XCTAssertEqual(layout.transform(position: .init(x: 2, y: 0, z: 93)), .init(x: 100, y: 0.25, z: -4))
        XCTAssertNil(layout.transform(position: .init(x: 2, y: 0, z: Double(93).nextUp)))
    }

    func testTransformsPreserveRolledDownwardFaceCornerSets() throws {
        let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 3, y: 1.5, z: 3), lights: [
            .init(name: "Overhead", position: .init(x: 2, y: 3, z: 1), candela: 900, kelvin: 5600,
                  optics: .init(kind: .rectangle, aimTarget: .init(x: 2, y: 1, z: 1),
                                widthMeters: 2, heightMeters: 1, rollDegrees: 45))
        ])
        // Half the short edge projected onto X/Z is sqrt(2)/4.
        let b = sqrt(2) / 4
        let cases: [(LightingScene, [(Double, Double)])] = [
            (try SceneTransform.mirroringLights(scene),
             [(1 - 3*b, 2 - b), (1 + b, 2 + 3*b), (1 + 3*b, 2 + b), (1 - b, 2 - 3*b)]),
            (try SceneTransform.rotatingLights(scene, byDegrees: 90),
             [(1 - 3*b, -2 + b), (1 + b, -2 - 3*b), (1 + 3*b, -2 - b), (1 - b, -2 + 3*b)])
        ]
        for (transformed, expected) in cases {
            let face = try XCTUnwrap(ARPlacementLayout(scene: transformed,
                origin: .init(x: 0, y: 0, z: 0)).modifierFaces.first)
            XCTAssertEqual(face.corners.count, 4)
            for (x, z) in expected {
                XCTAssertEqual(face.corners.filter { $0.distance(to: .init(x: x, y: 3, z: z)) < 1e-12 }.count, 1)
            }
        }
    }

    func testMeasuredHeightContactOverhangAndUnknownCeilingIncludeFaceCorners() throws {
        var scene = LightingScene(subject: .init(x: 0, y: 0, z: 0),
                                  camera: .init(x: 0, y: 2, z: 3), lights: [
            .init(name: "Rolled", position: .init(x: 0, y: 1, z: 1), candela: 900, kelvin: 5600,
                  optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 1, z: 0),
                                widthMeters: 2, heightMeters: 1, rollDegrees: 90))
        ])
        var room = ManualRoom(ceilingHeightMeters: 2)
        let plan = try RoomPlacementPlan(scene: scene, room: room)
        let face = try XCTUnwrap(plan.modifierFootprints.first)
        XCTAssertEqual(face.cornerHeightsMeters.sorted(), [0, 0, 2, 2])
        XCTAssertEqual(face.verticalClearance.touchingBoundaries, [.floor, .ceiling])
        XCTAssertEqual(face.verticalClearance.crossedBoundaries, [])
        XCTAssertEqual(face.verticalClearance.isInsideRoomHeight, true)
        XCTAssertEqual(plan.verticalTouchingPointCount, 2)
        room.ceilingHeightMeters = Double(2).nextDown
        let over = try RoomPlacementPlan(scene: scene, room: room)
        XCTAssertEqual(over.modifierFootprints[0].verticalClearance.crossedBoundaries, [.ceiling])
        XCTAssertEqual(over.verticalOutsideCount, 1)
        room.ceilingHeightMeters = nil
        let unknown = try RoomPlacementPlan(scene: scene, room: room)
        XCTAssertNil(unknown.modifierFootprints[0].verticalClearance.isInsideRoomHeight)
        XCTAssertNil(unknown.modifierFootprints[0].verticalClearance.minimumCeilingClearanceMeters)
        scene.lights[0].position.y = Double(1).nextDown
        scene.lights[0].optics?.aimTarget?.y = Double(1).nextDown
        let below = try RoomPlacementPlan(scene: scene, room: room)
        XCTAssertEqual(below.modifierFootprints[0].verticalClearance.crossedBoundaries, [.floor])
        XCTAssertEqual(below.modifierFootprints[0].verticalClearance.isInsideRoomHeight, false)
    }
}
