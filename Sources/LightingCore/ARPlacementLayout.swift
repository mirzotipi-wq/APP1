import Foundation

public enum ARPlacementError: Error, Equatable, Sendable, LocalizedError {
    case invalidOrigin
    case invalidYaw
    case outsideSupportedScene

    public var errorDescription: String? {
        switch self {
        case .invalidOrigin:
            return "The floor anchor is outside the supported scene coordinates. Choose another floor position."
        case .invalidYaw:
            return "Enter a finite rotation for the setup."
        case .outsideSupportedScene:
            return "This placement would put part of the setup outside the supported scene coordinates. Move the anchor or adjust the setup."
        }
    }
}

/// A marker in the anchor's world coordinate system. All positions and
/// distances are in meters and describe the authored rig, not measured
/// equipment or an estimate of AR tracking accuracy.
public struct ARPlacementItem: Identifiable, Equatable, Sendable {
    public enum Role: String, Equatable, Sendable { case subject, camera, light }

    public let id: String
    public let role: Role
    public let name: String
    /// The original light ID; subject and camera do not have source UUIDs.
    public let sourceID: UUID?
    public let position: Position
    /// The vertical projection onto the plane through the floor anchor.
    public let floorPosition: Position
    /// Signed authored height above the anchor's floor plane.
    public let heightAboveFloorMeters: Double
    public let horizontalDistanceFromSubjectMeters: Double
    public let distanceFromSubjectMeters: Double
}

/// The ideal rectangular emitting face, including authored aim and roll.
/// Corners follow the perimeter in local (-right,-up), (+right,-up),
/// (+right,+up), (-right,+up) order. An undefined aim produces no corners.
/// These bounds do not include a stand, housing, cables or safety clearance.
public struct ARPlacementModifierFace: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let corners: [Position]
    public var isAvailable: Bool { corners.count == 4 }
}

/// Deterministic rigid placement at 1:1 scale in meters, independent of ARKit.
/// The subject's authored X/Z maps onto the floor anchor's X/Z. Authored Y
/// remains height above that anchor, so subject height is never subtracted.
/// Positive yaw rotates scene +Z toward world +X around the vertical axis.
///
/// Both source and placed geometry must fit Position.coordinateRange. This
/// mathematical bound is not a claim that AR tracking supports that distance;
/// device tracking suitability belongs to the native session adapter.
public struct ARPlacementLayout: Equatable, Sendable {
    public let origin: Position
    /// Canonical orientation in (-180, 180].
    public let yawDegrees: Double
    /// Stable order: subject, camera, then lights in authored scene order.
    public let items: [ARPlacementItem]
    public let modifierFaces: [ARPlacementModifierFace]
    public var unavailableModifierIDs: [UUID] {
        modifierFaces.filter { !$0.isAvailable }.map(\.id)
    }

    private let sourceSubject: Position
    private let cosine: Double
    private let sine: Double

    public init(scene: LightingScene, origin: Position, yawDegrees: Double = 0) throws {
        let scene = try scene.validated()
        guard origin.isValid else { throw ARPlacementError.invalidOrigin }
        guard yawDegrees.isFinite else { throw ARPlacementError.invalidYaw }

        var angle = yawDegrees.truncatingRemainder(dividingBy: 360)
        if angle > 180 { angle -= 360 }
        if angle <= -180 { angle += 360 }
        if angle == 0 { angle = 0 }

        // Exact quarter turns preserve exact coordinate boundaries rather
        // than rejecting a valid placement for a trigonometric residual.
        let c: Double, s: Double
        switch angle {
        case 0: c = 1; s = 0
        case 90: c = 0; s = 1
        case 180: c = -1; s = 0
        case -90: c = 0; s = -1
        default:
            let radians = angle * .pi / 180
            c = cos(radians); s = sin(radians)
        }

        func placed(_ position: Position) throws -> Position {
            guard let result = Self.transformed(position, subject: scene.subject,
                                                origin: origin, cosine: c, sine: s) else {
                throw ARPlacementError.outsideSupportedScene
            }
            return result
        }

        func item(id: String, role: ARPlacementItem.Role, name: String,
                  sourceID: UUID? = nil, position: Position) throws -> ARPlacementItem {
            let worldPosition = try placed(position)
            return .init(id: id, role: role, name: name, sourceID: sourceID,
                         position: worldPosition,
                         floorPosition: .init(x: worldPosition.x, y: origin.y, z: worldPosition.z),
                         heightAboveFloorMeters: position.y,
                         horizontalDistanceFromSubjectMeters:
                            hypot(position.x - scene.subject.x, position.z - scene.subject.z),
                         distanceFromSubjectMeters: position.distance(to: scene.subject))
        }

        var markers = [
            try item(id: "subject", role: .subject, name: "Subject", position: scene.subject),
            try item(id: "camera", role: .camera, name: "Camera", position: scene.camera)
        ]
        var faces: [ARPlacementModifierFace] = []
        for light in scene.lights {
            markers.append(try item(id: light.id.uuidString, role: .light, name: light.name,
                                    sourceID: light.id, position: light.position))
            let optics = light.effectiveOptics
            // Explicit targets are scene geometry even if the current emitter
            // kind does not use its stored target. Never silently drop bounds.
            if let target = optics.aimTarget { _ = try placed(target) }
            guard optics.kind == .rectangle else { continue }
            guard let frame = StudioPhotometry.frame(for: light, subject: scene.subject) else {
                faces.append(.init(id: light.id, name: light.name, corners: []))
                continue
            }
            let signs: [(Double, Double)] = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            let corners = try signs.map { horizontal, vertical -> Position in
                let rightOffset = horizontal * optics.widthMeters / 2
                let upOffset = vertical * optics.heightMeters / 2
                let source = Position(
                    x: light.position.x + rightOffset * frame.right.x + upOffset * frame.up.x,
                    y: light.position.y + rightOffset * frame.right.y + upOffset * frame.up.y,
                    z: light.position.z + rightOffset * frame.right.z + upOffset * frame.up.z
                )
                return try placed(source)
            }
            faces.append(.init(id: light.id, name: light.name, corners: corners))
        }

        self.origin = origin
        self.yawDegrees = angle
        self.items = markers
        self.modifierFaces = faces
        self.sourceSubject = scene.subject
        self.cosine = c
        self.sine = s
    }

    /// Applies the same subject-relative rigid transform to another authored
    /// point. Invalid source coordinates or out-of-bounds results return nil;
    /// no coordinates are clamped and no scale adjustment is made.
    public func transform(position: Position) -> Position? {
        Self.transformed(position, subject: sourceSubject, origin: origin,
                         cosine: cosine, sine: sine)
    }

    private static func transformed(_ position: Position, subject: Position,
                                    origin: Position, cosine: Double, sine: Double) -> Position? {
        guard position.isValid else { return nil }
        let x = position.x - subject.x, z = position.z - subject.z
        let result = Position(x: origin.x + cosine * x + sine * z,
                              y: origin.y + position.y,
                              z: origin.z - sine * x + cosine * z)
        return result.isValid ? result : nil
    }
}
