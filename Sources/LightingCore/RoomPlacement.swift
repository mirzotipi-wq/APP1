import Foundation

public enum RoomPlacementError: Error, Equatable {
    case invalidRoom
}

/// Session-only, user-measured rectangular room. X increases from the left
/// wall and Z from the near wall. Y is height above the studio floor.
/// Positive yaw rotates scene +Z toward room +X; scale is always 1:1.
public struct ManualRoom: Equatable, Sendable {
    public static let dimensionRange: ClosedRange<Double> = 1...30
    public var widthMeters: Double
    public var depthMeters: Double
    public var subjectX: Double
    public var subjectZ: Double
    public var yawDegrees: Double

    public init(widthMeters: Double = 6, depthMeters: Double = 7,
                subjectX: Double = 3, subjectZ: Double = 2, yawDegrees: Double = 0) {
        self.widthMeters = widthMeters; self.depthMeters = depthMeters
        self.subjectX = subjectX; self.subjectZ = subjectZ; self.yawDegrees = yawDegrees
    }

    public var isValid: Bool {
        widthMeters.isFinite && depthMeters.isFinite &&
        Self.dimensionRange.contains(widthMeters) && Self.dimensionRange.contains(depthMeters) &&
        subjectX.isFinite && subjectZ.isFinite && subjectX >= 0 && subjectX <= widthMeters &&
        subjectZ >= 0 && subjectZ <= depthMeters &&
        yawDegrees.isFinite && (-360...360).contains(yawDegrees)
    }
}

public struct RoomPlacementPoint: Identifiable, Equatable, Sendable {
    public enum Kind: String, Sendable { case subject, camera, light }
    public let id: String
    public let kind: Kind
    public let name: String
    /// Signed tape-measure coordinates. Negative values are beyond the
    /// corresponding wall. Values greater than width/depth exceed the far wall.
    public let xFromLeft: Double
    public let zFromNear: Double
    public let heightMeters: Double
    public let horizontalDistanceFromSubject: Double
    public let insideRoom: Bool
}

/// Deterministic mapping from a validated studio snapshot into a measured room.
/// Checks floor-projected center positions only, not equipment footprints,
/// wall clearance for bodies/modifiers, ceiling height, or collision safety.
public struct RoomPlacementPlan: Equatable, Sendable {
    public let room: ManualRoom
    public let points: [RoomPlacementPoint]
    public var outsideCount: Int { points.filter { !$0.insideRoom }.count }

    public init(scene: LightingScene, room: ManualRoom) throws {
        guard room.isValid else { throw RoomPlacementError.invalidRoom }
        let scene = try scene.validated()
        let radians = room.yawDegrees * .pi / 180
        let c = cos(radians), s = sin(radians)
        // Remove tiny floating-point residuals at exact wall boundaries.
        func snap(_ value: Double, limit: Double) -> Double {
            if abs(value) <= 1e-9 { return 0 }
            if abs(value - limit) <= 1e-9 { return limit }
            return value
        }
        func point(_ id: String, _ kind: RoomPlacementPoint.Kind, _ name: String,
                   _ p: Position) -> RoomPlacementPoint {
            let dx = p.x - scene.subject.x, dz = p.z - scene.subject.z
            let x = snap(room.subjectX + c * dx + s * dz, limit: room.widthMeters)
            let z = snap(room.subjectZ - s * dx + c * dz, limit: room.depthMeters)
            return .init(id: id, kind: kind, name: name, xFromLeft: x, zFromNear: z,
                         heightMeters: p.y, horizontalDistanceFromSubject: hypot(dx, dz),
                         insideRoom: x >= 0 && x <= room.widthMeters && z >= 0 && z <= room.depthMeters)
        }
        self.room = room
        self.points = [
            point("subject", .subject, "Subject", scene.subject),
            point("camera", .camera, "Camera", scene.camera)
        ] + scene.lights.map { point($0.id.uuidString, .light, $0.name, $0.position) }
    }
}
