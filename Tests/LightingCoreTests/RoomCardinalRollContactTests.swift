import Foundation
import XCTest
@testable import LightingCore

final class RoomCardinalRollContactTests: XCTestCase {
    private let cardinalRolls: [Double] = [0, 90, -90, 180, -180]

    private func scene(position: Position, target: Position, roll: Double) -> LightingScene {
        .init(subject: .init(x: 0, y: 1.5, z: 0),
              camera: .init(x: 0, y: 1.5, z: 1), lights: [
            .init(name: "Rolled softbox", position: position, candela: 900, kelvin: 5600,
                  optics: .init(kind: .rectangle, aimTarget: target,
                                widthMeters: 2, heightMeters: 1, rollDegrees: roll))
        ])
    }

    func testCardinalRollKeepsExactWallContactForBothVerticalAimDirections() throws {
        let room = ManualRoom(widthMeters: 4, depthMeters: 4, subjectX: 0, subjectZ: 0)
        for direction in [-1.0, 1.0] {
            for roll in cardinalRolls {
                let halfX = abs(roll) == 90 ? 0.5 : 1.0
                let halfZ = abs(roll) == 90 ? 1.0 : 0.5
                // All four room corners cover contact with every horizontal wall.
                for x in [halfX, 4 - halfX] {
                    for z in [halfZ, 4 - halfZ] {
                        let rig = scene(position: .init(x: x, y: 2, z: z),
                                        target: .init(x: x, y: 2 + direction, z: z), roll: roll)
                        let plan = try RoomPlacementPlan(scene: rig, room: room)
                        let face = try XCTUnwrap(plan.modifierFootprints.first)
                        let context = "aim Y \(direction), roll \(roll), center (\(x), \(z))"
                        XCTAssertEqual(face.corners.count, 4, context)
                        XCTAssertEqual(Set(face.corners.map(\.xFromLeft)), [x - halfX, x + halfX], context)
                        XCTAssertEqual(Set(face.corners.map(\.zFromNear)), [z - halfZ, z + halfZ], context)
                        XCTAssertEqual(face.minimumWallClearanceMeters, 0, context)
                        XCTAssertEqual(face.crossedWalls, [], context)
                        XCTAssertEqual(face.isInsideRoom, true, context)
                        XCTAssertEqual(plan.crossingModifierCount, 0, context)
                    }
                }
            }
        }
    }

    func testCardinalRollKeepsExactFloorAndCeilingContactForHorizontalAimDirections() throws {
        let directions: [(x: Double, z: Double)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        for direction in directions {
            for roll in cardinalRolls {
                let halfHeight = abs(roll) == 90 ? 1.0 : 0.5
                let ceiling = 2 * halfHeight
                let rig = scene(position: .init(x: 0, y: halfHeight, z: 0),
                                target: .init(x: direction.x, y: halfHeight, z: direction.z), roll: roll)
                let room = ManualRoom(widthMeters: 4, depthMeters: 4, subjectX: 2, subjectZ: 2,
                                      ceilingHeightMeters: ceiling)
                let plan = try RoomPlacementPlan(scene: rig, room: room)
                let face = try XCTUnwrap(plan.modifierFootprints.first)
                let context = "aim (\(direction.x), \(direction.z)), roll \(roll)"
                XCTAssertEqual(face.cornerHeightsMeters.sorted(), [0, 0, ceiling, ceiling], context)
                XCTAssertEqual(face.verticalClearance.minimumFloorClearanceMeters, 0, context)
                XCTAssertEqual(face.verticalClearance.minimumCeilingClearanceMeters, 0, context)
                XCTAssertEqual(face.verticalClearance.touchingBoundaries, [.floor, .ceiling], context)
                XCTAssertEqual(face.verticalClearance.crossedBoundaries, [], context)
                XCTAssertEqual(face.verticalClearance.isInsideRoomHeight, true, context)
                XCTAssertEqual(plan.verticalCrossingModifierCount, 0, context)
                // AR consumes the shared frame without the room's legacy Y correction.
                let placed = try XCTUnwrap(ARPlacementLayout(scene: rig,
                    origin: .init(x: 0, y: 0, z: 0)).modifierFaces.first)
                XCTAssertEqual(placed.corners.map(\.y).sorted(), [0, 0, ceiling, ceiling], context)
            }
        }
    }

    func testCardinalRollStillRejectsOneRepresentableStepOfWallOverhang() throws {
        let x = Double(0.5).nextDown
        let rig = scene(position: .init(x: x, y: 2, z: 1),
                        target: .init(x: x, y: 0, z: 1), roll: 90)
        let room = ManualRoom(widthMeters: 4, depthMeters: 4, subjectX: 0, subjectZ: 0)
        let plan = try RoomPlacementPlan(scene: rig, room: room)
        let face = try XCTUnwrap(plan.modifierFootprints.first)
        XCTAssertEqual(face.corners.map(\.xFromLeft).min(), x - 0.5)
        XCTAssertEqual(face.corners.map(\.zFromNear).min(), 0)
        XCTAssertEqual(face.minimumWallClearanceMeters, x - 0.5)
        XCTAssertEqual(face.crossedWalls, [.left])
        XCTAssertEqual(face.isInsideRoom, false)
        XCTAssertEqual(plan.crossingModifierCount, 1)
    }

    func testNoncardinalRollRetainsObliqueFaceGeometry() throws {
        let q = sqrt(0.5)
        let room = ManualRoom(widthMeters: 4, depthMeters: 4, subjectX: 0, subjectZ: 0)
        for sign in [-1.0, 1.0] {
            let rig = scene(position: .init(x: 2, y: 2, z: 2),
                            target: .init(x: 2, y: 0, z: 2), roll: sign * 45)
            let frame = try XCTUnwrap(StudioPhotometry.frame(for: rig.lights[0], subject: rig.subject))
            // For downward N=(0,-1,0), R=(1,0,0) and U=N×R=(0,0,1).
            // Positive roll rotates R toward U around that downward normal.
            XCTAssertEqual(frame.right.x, q, accuracy: 1e-15)
            XCTAssertEqual(frame.right.y, 0)
            XCTAssertEqual(frame.right.z, sign * q, accuracy: 1e-15)
            XCTAssertEqual(frame.up.x, -sign * q, accuracy: 1e-15)
            XCTAssertEqual(frame.up.y, 0)
            XCTAssertEqual(frame.up.z, q, accuracy: 1e-15)
            let face = try XCTUnwrap(RoomPlacementPlan(scene: rig, room: room).modifierFootprints.first)
            XCTAssertEqual(try XCTUnwrap(face.corners.map(\.xFromLeft).min()), 2 - 1.5 * q, accuracy: 1e-15)
            XCTAssertEqual(try XCTUnwrap(face.corners.map(\.zFromNear).min()), 2 - 1.5 * q, accuracy: 1e-15)
            XCTAssertEqual(face.crossedWalls, [])
            XCTAssertEqual(face.isInsideRoom, true)
        }
    }

    func testAnglesAdjacentToCardinalRollsKeepTheirNonzeroComponents() throws {
        let source = Position(x: 0, y: 2, z: 0)
        let target = Position(x: 0, y: 0, z: 0)
        for roll in [Double(90).nextDown, Double(90).nextUp,
                     Double(-90).nextDown, Double(-90).nextUp] {
            let frame = try XCTUnwrap(EmitterFrame(source: source, target: target, rollDegrees: roll))
            XCTAssertNotEqual(frame.right.x, 0, "roll \(roll)")
        }
        for roll in [Double(180).nextDown, Double(-180).nextUp] {
            let frame = try XCTUnwrap(EmitterFrame(source: source, target: target, rollDegrees: roll))
            XCTAssertNotEqual(frame.right.z, 0, "roll \(roll)")
        }
    }
}
