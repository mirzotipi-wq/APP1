import Foundation

public enum RoomPlacementError: Error, Equatable {
    case invalidRoom
}

/// User-measured rectangular room stored with a scene. X increases from the left
/// wall and Z from the near wall. Y is height above the studio floor.
/// Positive yaw rotates scene +Z toward room +X; scale is always 1:1.
public struct ManualRoom: Codable, Equatable, Sendable {
    public static let dimensionRange: ClosedRange<Double> = 1...30
    public var widthMeters: Double
    public var depthMeters: Double
    /// Nil means the ceiling height has not been measured.
    public var ceilingHeightMeters: Double?
    public var subjectX: Double
    public var subjectZ: Double
    public var yawDegrees: Double

    public init(widthMeters: Double = 6, depthMeters: Double = 7,
                subjectX: Double = 3, subjectZ: Double = 2, yawDegrees: Double = 0,
                ceilingHeightMeters: Double? = nil) {
        self.widthMeters = widthMeters; self.depthMeters = depthMeters
        self.ceilingHeightMeters = ceilingHeightMeters
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
        (ceilingHeightMeters.map { $0.isFinite && Self.dimensionRange.contains($0) } ?? true) &&
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

public enum RoomVerticalBoundary: String, CaseIterable, Equatable, Sendable {
    case floor, ceiling
}

/// Vertical extent of a center or an ideal emitting face, measured from the
/// same floor as the scene. This does not describe a complete fixture, stand,
/// boom, subject body, or required working clearance.
public struct RoomVerticalClearance: Equatable, Sendable {
    /// Nil when the geometry is unavailable, for example an undefined face aim.
    public let lowestHeightMeters: Double?
    public let highestHeightMeters: Double?
    /// Nil means unmeasured, independently of whether geometry is available.
    public let ceilingHeightMeters: Double?

    init(heights: [Double], ceilingHeightMeters: Double?) {
        self.ceilingHeightMeters = ceilingHeightMeters
        guard !heights.isEmpty, heights.allSatisfy({ $0.isFinite }) else {
            lowestHeightMeters = nil
            highestHeightMeters = nil
            return
        }
        // Do not round or snap heights: even a tiny entered overhang must
        // remain a violation rather than becoming contact or positive space.
        lowestHeightMeters = heights.min()
        highestHeightMeters = heights.max()
    }

    public var isAvailable: Bool { lowestHeightMeters != nil && highestHeightMeters != nil }
    public var isCeilingMeasured: Bool { ceilingHeightMeters != nil }

    /// Signed minimum distances. Negative values extend below the floor or
    /// above the measured ceiling; zero is contact, not positive clearance.
    public var minimumFloorClearanceMeters: Double? { lowestHeightMeters }
    public var minimumCeilingClearanceMeters: Double? {
        guard let ceilingHeightMeters, let highestHeightMeters else { return nil }
        return ceilingHeightMeters - highestHeightMeters
    }

    /// Boundaries with geometry outside their permitted half-space. A face
    /// wholly above the ceiling is included even if it does not meet the plane.
    public var crossedBoundaries: [RoomVerticalBoundary] {
        var boundaries: [RoomVerticalBoundary] = []
        if let distance = minimumFloorClearanceMeters, distance < 0 { boundaries.append(.floor) }
        if let distance = minimumCeilingClearanceMeters, distance < 0 { boundaries.append(.ceiling) }
        return boundaries
    }

    /// Boundaries with exactly zero minimum distance and no overhang through
    /// that boundary. Contact is reported separately from a negative distance.
    public var touchingBoundaries: [RoomVerticalBoundary] {
        var boundaries: [RoomVerticalBoundary] = []
        if minimumFloorClearanceMeters == 0 { boundaries.append(.floor) }
        if minimumCeilingClearanceMeters == 0 { boundaries.append(.ceiling) }
        return boundaries
    }

    /// Boundary planes met by the point or convex face, including contact.
    /// This also distinguishes a straddling face from one wholly outside.
    public var intersectedBoundaries: [RoomVerticalBoundary] {
        guard let lowestHeightMeters, let highestHeightMeters else { return [] }
        var boundaries: [RoomVerticalBoundary] = []
        if lowestHeightMeters <= 0, highestHeightMeters >= 0 { boundaries.append(.floor) }
        if let ceilingHeightMeters,
           lowestHeightMeters <= ceilingHeightMeters, highestHeightMeters >= ceilingHeightMeters {
            boundaries.append(.ceiling)
        }
        return boundaries
    }

    /// False for a known floor or ceiling violation, nil for unavailable
    /// geometry or an unmeasured ceiling, and true only for full measured-height
    /// containment. True includes exact contact and is not an equipment check.
    public var isInsideRoomHeight: Bool? {
        guard isAvailable else { return nil }
        if !crossedBoundaries.isEmpty { return false }
        return isCeilingMeasured ? true : nil
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
    /// Containment of the center's floor projection only, preserved separately
    /// from the optional measured-ceiling check.
    public let insideRoom: Bool
    public let verticalClearance: RoomVerticalClearance

    init(id: String, kind: Kind, name: String, xFromLeft: Double, zFromNear: Double,
         heightMeters: Double, horizontalDistanceFromSubject: Double, insideRoom: Bool,
         ceilingHeightMeters: Double? = nil) {
        self.id = id; self.kind = kind; self.name = name
        self.xFromLeft = xFromLeft; self.zFromNear = zFromNear
        self.heightMeters = heightMeters
        self.horizontalDistanceFromSubject = horizontalDistanceFromSubject
        self.insideRoom = insideRoom
        self.verticalClearance = .init(heights: [heightMeters], ceilingHeightMeters: ceilingHeightMeters)
    }
}

/// A projected floor coordinate in the measured room's wall-relative system.
public struct RoomFloorPoint: Equatable, Sendable {
    public let xFromLeft: Double
    public let zFromNear: Double
}

public enum RoomWall: String, CaseIterable, Equatable, Sendable {
    case left, right, near, far
}

/// The rectangular emitting face's floor projection and corner heights, not
/// the entire modifier housing, stand, boom, or safety clearance. Degenerate
/// aim yields unavailable geometry rather than reporting a clear surface.
public struct RoomModifierFootprint: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let corners: [RoomFloorPoint]
    public let crossedWalls: [RoomWall]
    /// Signed minimum distance to the four room boundaries; nil when unknown.
    public let minimumWallClearanceMeters: Double?
    /// Heights in the same winding order as the floor-projected corners.
    /// Empty when face geometry is unavailable. Room yaw does not change height.
    public let cornerHeightsMeters: [Double]
    public let verticalClearance: RoomVerticalClearance
    public var isAvailable: Bool { corners.count == 4 }
    /// Containment of the floor projection only; see verticalClearance for Y.
    public var isInsideRoom: Bool? { isAvailable ? crossedWalls.isEmpty : nil }

    init(id: UUID, name: String, corners: [RoomFloorPoint], crossedWalls: [RoomWall],
         minimumWallClearanceMeters: Double?, cornerHeightsMeters: [Double] = [],
         ceilingHeightMeters: Double? = nil) {
        self.id = id; self.name = name; self.corners = corners
        self.crossedWalls = crossedWalls
        self.minimumWallClearanceMeters = minimumWallClearanceMeters
        self.cornerHeightsMeters = cornerHeightsMeters
        self.verticalClearance = .init(
            heights: corners.count == 4 && cornerHeightsMeters.count == 4 ? cornerHeightsMeters : [],
            ceilingHeightMeters: ceilingHeightMeters)
    }
}

/// Deterministic 1:1 mapping from a validated studio snapshot into a measured
/// room. Checks floor-projected centers and ideal rectangular emitting faces.
/// Vertical checks use the floor and, when measured, a flat horizontal ceiling.
/// It does not check complete equipment bodies, cables, or equipment collisions.
public struct RoomPlacementPlan: Equatable, Sendable {
    public let room: ManualRoom
    public let points: [RoomPlacementPoint]
    public let modifierFootprints: [RoomModifierFootprint]
    /// Horizontal checks retain their original room-outline semantics.
    public var outsideCount: Int { points.filter { !$0.insideRoom }.count }
    public var crossingModifierCount: Int { modifierFootprints.filter { $0.isInsideRoom == false }.count }
    public var unavailableModifierCount: Int { modifierFootprints.filter { !$0.isAvailable }.count }
    /// Known vertical violations, including the floor when no ceiling was
    /// measured. Each point or face is counted once even if both limits fail.
    public var verticalOutsideCount: Int {
        points.filter { $0.verticalClearance.isInsideRoomHeight == false }.count
    }
    public var verticalCrossingModifierCount: Int {
        modifierFootprints.filter { !$0.verticalClearance.crossedBoundaries.isEmpty }.count
    }
    public var verticalTouchingPointCount: Int {
        points.filter { !$0.verticalClearance.touchingBoundaries.isEmpty }.count
    }
    public var verticalTouchingModifierCount: Int {
        modifierFootprints.filter { !$0.verticalClearance.touchingBoundaries.isEmpty }.count
    }

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
                                     f.zFromNear >= 0 && f.zFromNear <= room.depthMeters,
                         ceilingHeightMeters: room.ceilingHeightMeters)
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
                             crossedWalls: [], minimumWallClearanceMeters: nil,
                             ceilingHeightMeters: room.ceilingHeightMeters)
            }
            let signs: [(Double, Double)] = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            let absoluteRoll = abs(optics.effectiveRollDegrees)
            // World-up frames have no vertical right component before roll.
            // At exact quarter/half turns, remove only the known trigonometric
            // zero residual so mathematical contact is not a false overhang.
            // Do not apply a distance tolerance to entered heights or ceilings.
            let rightHeight = absoluteRoll == 180 ? 0 : frame.right.y
            let upHeight = absoluteRoll == 90 ? 0 : frame.up.y
            let worldCorners = signs.map { a, b -> Position in
                let dx = a * optics.widthMeters / 2, dy = b * optics.heightMeters / 2
                return .init(x: light.position.x + dx * frame.right.x + dy * frame.up.x,
                             y: light.position.y + dx * rightHeight + dy * upHeight,
                             z: light.position.z + dx * frame.right.z + dy * frame.up.z)
            }
            let corners = worldCorners.map(floorPoint)
            // A rectangle and its orthogonal projection are convex: checking
            // the four extremal corners proves containment in a rectangle.
            let xs = corners.map(\.xFromLeft), zs = corners.map(\.zFromNear)
            let distances: [(RoomWall, Double)] = [
                (.left, xs.min()!), (.right, room.widthMeters - xs.max()!),
                (.near, zs.min()!), (.far, room.depthMeters - zs.max()!)
            ]
            return .init(id: light.id, name: light.name, corners: corners,
                         crossedWalls: distances.filter { $0.1 < 0 }.map { $0.0 },
                         minimumWallClearanceMeters: distances.map { $0.1 }.min(),
                         cornerHeightsMeters: worldCorners.map(\.y),
                         ceilingHeightMeters: room.ceilingHeightMeters)
        }
    }
}
