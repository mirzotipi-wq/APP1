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

    /// Resizing is independent of the subject's location. The editor must
    /// require an explicit subject move before accepting a smaller room.
    public var widthEditRange: ClosedRange<Double> { dimensionRangePreserving(subjectX) }
    public var depthEditRange: ClosedRange<Double> { dimensionRangePreserving(subjectZ) }

    private func dimensionRangePreserving(_ offset: Double) -> ClosedRange<Double> {
        guard offset.isFinite, offset >= 0, offset <= Self.dimensionRange.upperBound else {
            return Self.dimensionRange
        }
        return max(Self.dimensionRange.lowerBound, offset)...Self.dimensionRange.upperBound
    }

    /// Rotate relative to the current placement, preserving dimensions and
    /// subject offsets. Canonical output is in (-180, 180], matching the UI's
    /// slider range. Invalid input leaves the entire room unchanged.
    @discardableResult
    public mutating func rotate(byDegrees degrees: Double) -> Bool {
        guard isValid, degrees.isFinite else { return false }
        // Reduce the delta before addition so even a very large finite input
        // cannot overflow or lose the bounded starting orientation.
        var angle = (yawDegrees + degrees.truncatingRemainder(dividingBy: 360))
            .truncatingRemainder(dividingBy: 360)
        if angle > 180 { angle -= 360 }
        if angle <= -180 { angle += 360 }
        yawDegrees = angle == 0 ? 0 : angle
        return true
    }

    public var isValid: Bool {
        widthMeters.isFinite && depthMeters.isFinite &&
        Self.dimensionRange.contains(widthMeters) && Self.dimensionRange.contains(depthMeters) &&
        subjectX.isFinite && subjectZ.isFinite && subjectX >= 0 && subjectX <= widthMeters &&
        subjectZ >= 0 && subjectZ <= depthMeters &&
        yawDegrees.isFinite && (-360...360).contains(yawDegrees)
    }
}

/// Strict decimal input for manual tape measurements. Accept the current
/// locale's separator, but never grouping, exponents or partial invalid input.
public enum RoomMeasurementInput {
    public static func parse(_ text: String, decimalSeparator: String = ".",
                             in range: ClosedRange<Double>) -> Double? {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = input.first, input.count <= 24,
              first != "+", first != "-", first != "−" else { return nil }
        // Share the scene editor's strict decimal grammar and support local digits.
        return StudioNumericInput.parse(input, decimalSeparator: decimalSeparator, in: range)
    }

    /// Editable text uses ASCII digits and the selected decimal separator, not
    /// locale-inserted grouping or directional marks. Unchanged drafts must
    /// not be written back as rounded measurements.
    public static func draft(_ value: Double, decimalSeparator: String = ".") -> String {
        value.formatted(.number.precision(.fractionLength(0...12)).grouping(.never)
            .locale(Locale(identifier: "en_US_POSIX")))
            .replacingOccurrences(of: ".", with: decimalSeparator)
    }
}

/// Display calculated room geometry without disguising a nonzero overhang
/// or signed wall coordinate as zero. These are model calculations, not a
/// measurement-accuracy guarantee. Use a bounded readout for tiny distances.
public enum RoomMeasurementDisplay {
    public static func distance(_ value: Double, locale: Locale = .current) -> String {
        guard value.isFinite else { return "Unavailable" }
        let limit = 0.000001
        let style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2...6))
            .grouping(.never).locale(locale)
        if value != 0, abs(value) < limit {
            let threshold = limit.formatted(style)
            let negativeThreshold = (-limit).formatted(style)
            return value < 0 ? "between \(negativeThreshold) and 0 m" : "less than \(threshold) m"
        }
        return (value == 0 ? 0.0 : value).formatted(style) + " m"
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

/// A projected floor coordinate in the measured room's wall-relative system.
public struct RoomFloorPoint: Equatable, Sendable {
    public let xFromLeft: Double
    public let zFromNear: Double
}

public enum RoomWall: String, CaseIterable, Equatable, Sendable {
    case left, right, near, far
}

/// The rectangular emitting face projected onto the floor, not the entire
/// modifier housing, stand, boom, or safety clearance. Degenerate aim yields
/// unavailable geometry rather than silently reporting a clear surface.
public struct RoomModifierFootprint: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let corners: [RoomFloorPoint]
    public let crossedWalls: [RoomWall]
    /// Signed minimum distance to the four room boundaries; nil when unknown.
    public let minimumWallClearanceMeters: Double?
    public var isAvailable: Bool { corners.count == 4 }
    public var isInsideRoom: Bool? { isAvailable ? crossedWalls.isEmpty : nil }
}

/// Deterministic 1:1 mapping from a validated studio snapshot into a measured
/// room. Checks floor-projected centers and ideal rectangular emitting faces.
/// It does not check complete equipment bodies, ceiling, cables or collisions.
public struct RoomPlacementPlan: Equatable, Sendable {
    public let room: ManualRoom
    public let points: [RoomPlacementPoint]
    public let modifierFootprints: [RoomModifierFootprint]
    public var outsideCount: Int { points.filter { !$0.insideRoom }.count }
    public var crossingModifierCount: Int { modifierFootprints.filter { $0.isInsideRoom == false }.count }
    public var unavailableModifierCount: Int { modifierFootprints.filter { !$0.isAvailable }.count }

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
        func floorPoint(_ p: Position) -> RoomFloorPoint {
            let dx = p.x - scene.subject.x, dz = p.z - scene.subject.z
            return .init(xFromLeft: snap(room.subjectX + c * dx + s * dz, limit: room.widthMeters),
                         zFromNear: snap(room.subjectZ - s * dx + c * dz, limit: room.depthMeters))
        }
        func point(_ id: String, _ kind: RoomPlacementPoint.Kind, _ name: String,
                   _ p: Position) -> RoomPlacementPoint {
            let f = floorPoint(p)
            return .init(id: id, kind: kind, name: name, xFromLeft: f.xFromLeft, zFromNear: f.zFromNear,
                         heightMeters: p.y,
                         horizontalDistanceFromSubject: hypot(p.x - scene.subject.x, p.z - scene.subject.z),
                         insideRoom: f.xFromLeft >= 0 && f.xFromLeft <= room.widthMeters &&
                                     f.zFromNear >= 0 && f.zFromNear <= room.depthMeters)
        }
        self.room = room
        self.points = [
            point("subject", .subject, "Subject", scene.subject),
            point("camera", .camera, "Camera", scene.camera)
        ] + scene.lights.map { point($0.id.uuidString, .light, $0.name, $0.position) }
        self.modifierFootprints = scene.lights.compactMap { light -> RoomModifierFootprint? in
            let optics = light.effectiveOptics
            guard optics.kind == .rectangle else { return nil }
            guard let frame = StudioPhotometry.frame(for: light, subject: scene.subject) else {
                return .init(id: light.id, name: light.name, corners: [],
                             crossedWalls: [], minimumWallClearanceMeters: nil)
            }
            let signs: [(Double, Double)] = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            let corners = signs.map { a, b -> RoomFloorPoint in
                let dx = a * optics.widthMeters / 2, dy = b * optics.heightMeters / 2
                return floorPoint(.init(x: light.position.x + dx * frame.right.x + dy * frame.up.x,
                                        y: light.position.y + dx * frame.right.y + dy * frame.up.y,
                                        z: light.position.z + dx * frame.right.z + dy * frame.up.z))
            }
            // A rectangle and its orthogonal projection are convex: checking
            // the four extremal corners proves containment in a rectangle.
            let xs = corners.map(\.xFromLeft), zs = corners.map(\.zFromNear)
            let distances: [(RoomWall, Double)] = [
                (.left, xs.min()!), (.right, room.widthMeters - xs.max()!),
                (.near, zs.min()!), (.far, room.depthMeters - zs.max()!)
            ]
            return .init(id: light.id, name: light.name, corners: corners,
                         crossedWalls: distances.filter { $0.1 < 0 }.map { $0.0 },
                         minimumWallClearanceMeters: distances.map { $0.1 }.min())
        }
    }
}
