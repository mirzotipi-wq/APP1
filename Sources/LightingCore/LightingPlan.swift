import Foundation

public enum PlanUnits: String, CaseIterable, Sendable {
    case metric, imperial
    public var symbol: String { self == .metric ? "m" : "ft" }
    public func fromMeters(_ meters: Double) -> Double { self == .metric ? meters : meters / 0.3048 }
    public func toMeters(_ value: Double) -> Double { self == .metric ? value : value * 0.3048 }
    public func distance(_ meters: Double) -> String { "\(Self.number(fromMeters(meters), decimals: 2)) \(symbol)" }
    public func coordinates(_ position: Position) -> String {
        let values = [position.x, position.y, position.z].map { Self.number(fromMeters($0), decimals: 2) }
        return "(\(values.joined(separator: ", "))) \(symbol)"
    }
    /// Editable parameters retain up to six fractional digits in the report.
    /// Keep a minimum for familiar readouts; derived distances remain at two.
    public static func parameterNumber(_ value: Double, minimumDecimals: Int = 0) -> String {
        let minimum = min(6, max(0, minimumDecimals))
        var text = number(value, decimals: 6)
        guard let dot = text.firstIndex(of: ".") else { return text }
        while text.last == "0", text.distance(from: dot, to: text.endIndex) > minimum + 1 { text.removeLast() }
        if text.last == "." { text.removeLast() }
        return text
    }
    public func parameterDistance(_ meters: Double) -> String {
        "\(Self.parameterNumber(fromMeters(meters), minimumDecimals: 2)) \(symbol)"
    }
    public func parameterCoordinates(_ position: Position) -> String {
        let values = [position.x, position.y, position.z].map { Self.parameterNumber(fromMeters($0), minimumDecimals: 2) }
        return "(\(values.joined(separator: ", "))) \(symbol)"
    }
    /// Wall coordinates and projected overhangs must retain their sign even
    /// below the report's six-decimal display precision. The threshold is in
    /// the selected export unit, not implicitly in meters.
    public func roomDistance(_ meters: Double) -> String {
        let value = fromMeters(meters)
        guard value.isFinite else { return "Unavailable" }
        if value != 0, abs(value) < 0.000001 {
            return value < 0 ? "between -0.000001 and 0 \(symbol)" : "less than 0.000001 \(symbol)"
        }
        return parameterDistance(meters)
    }
    public static func number(_ value: Double, decimals: Int = 1) -> String {
        // Foundation on Apple SDKs rejects the dynamic-precision vararg
        // signature used here previously. A fixed, bounded format has one Double.
        let precision = min(12, max(0, decimals))
        let threshold = 0.5 * pow(10.0, -Double(precision))
        let normalized: Double = abs(value) < threshold ? 0.0 : value
        return String(format: "%.\(precision)f", locale: Locale(identifier: "en_US_POSIX"), normalized)
    }
}

public enum PlanPaper: String, CaseIterable, Sendable {
    case letter, a4
    public var title: String { self == .letter ? "US Letter" : "A4" }
    public var width: Double { self == .letter ? 612 : 595.28 }
    public var height: Double { self == .letter ? 792 : 841.89 }
}

/// x and y in PDF points, or world x and z when explicitly described as world coordinates.
public struct PlanPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
    fileprivate init(_ position: Position) { self.init(x: position.x, y: position.z) }
    public func distance(to other: Self) -> Double { hypot(x - other.x, y - other.y) }
}

public struct PlanMarker: Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case subject, camera, light }
    public let kind: Kind
    public let label: String
    /// Actual projected point, never displaced for readability.
    public let anchor: PlanPoint
    /// Numbered label center; a leader connects this to anchor when displaced.
    public let center: PlanPoint
}

public struct PlanLine: Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case camera, aim, modifier }
    public let kind: Kind
    public let points: [PlanPoint]
}

public struct PlanGridLine: Equatable, Sendable {
    public let from: PlanPoint
    public let to: PlanPoint
    public let isAxis: Bool
}

public struct PlanDiagram: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let pointsPerMeter: Double
    public let worldCenter: PlanPoint
    public let gridStep: Double // in selected display units
    public let grid: [PlanGridLine]
    public let markers: [PlanMarker]
    public let lines: [PlanLine]
    public let units: PlanUnits

    public func project(_ world: PlanPoint) -> PlanPoint {
        .init(x: width / 2 + (world.x - worldCenter.x) * pointsPerMeter,
              y: height / 2 + (world.y - worldCenter.y) * pointsPerMeter)
    }
    public var scaleLabel: String { "Grid: \(PlanUnits.number(gridStep, decimals: gridStep < 1 ? 2 : 1)) \(units.symbol)" }
}

public struct PlanLight: Equatable, Sendable {
    public let number: Int
    public let name: String
    public let position: Position
    public let kind: EmitterKind
    public let candela: Double
    public let kelvin: Double
    public let subjectDistance: Double
    public let aimTarget: Position?
    public let followsSubject: Bool
    public let aimIsValid: Bool
    public let widthMeters: Double?
    public let heightMeters: Double?
    /// Only rectangular emitters have a reported roll. Nil preserves the
    /// legacy settings line; an explicitly entered zero remains visible.
    public let rollDegrees: Double?

    public func settings(units: PlanUnits) -> String {
        var output = "\(PlanUnits.parameterNumber(candela, minimumDecimals: 1)) cd · \(PlanUnits.parameterNumber(kelvin)) K"
        if let widthMeters, let heightMeters {
            output += " · \(units.parameterDistance(widthMeters)) × \(units.parameterDistance(heightMeters))"
        }
        if let rollDegrees { output += " · Roll \(PlanUnits.parameterNumber(rollDegrees))°" }
        return output
    }
    public func placement(units: PlanUnits) -> String {
        "XYZ \(units.parameterCoordinates(position)) · Subject distance \(units.distance(subjectDistance))"
    }
    public func aim(units: PlanUnits) -> String {
        guard let aimTarget else { return "Omnidirectional ideal source · no aiming direction" }
        guard aimIsValid else { return "Aim undefined: target coincides with source" }
        return "Aim \(units.parameterCoordinates(aimTarget)) · \(followsSubject ? "follows subject" : "manual target")"
    }
}

/// One wall-relative export row. Markers match the overhead diagram and the
/// equipment schedule, including when light names are duplicated or truncated.
public struct PlanRoomItem: Equatable, Sendable {
    public let marker: String
    public let name: String
    public let point: RoomPlacementPoint
    public let modifierFootprint: RoomModifierFootprint?

    public var centerStatus: String {
        point.insideRoom ? "Center inside room outline" : "CENTER OUTSIDE ROOM OUTLINE"
    }

    public var hasWarning: Bool {
        !point.insideRoom || modifierFootprint.map { !$0.isAvailable || $0.isInsideRoom == false } == true
    }

    public func coordinates(units: PlanUnits) -> String {
        "X from left wall: \(units.roomDistance(point.xFromLeft)); Z from near wall: \(units.roomDistance(point.zFromNear)); Height: \(units.roomDistance(point.heightMeters)); Floor distance to subject: \(units.roomDistance(point.horizontalDistanceFromSubject))"
    }

    /// Only the ideal emitting face's floor projection is described. These
    /// values cannot establish equipment-body or ceiling clearance.
    public func projectedFaceStatus(units: PlanUnits) -> String? {
        guard let footprint = modifierFootprint else { return nil }
        guard footprint.isAvailable else { return "Emitting-face projection unavailable; check aim." }
        var status = footprint.crossedWalls.isEmpty
            ? "Emitting-face projection within room outline."
            : "Emitting-face projection crosses \(footprint.crossedWalls.map(\.rawValue).joined(separator: ", ")) wall boundaries."
        if let clearance = footprint.minimumWallClearanceMeters {
            status += clearance < 0
                ? " Projected wall overhang: \(units.roomDistance(-clearance))."
                : " Minimum projected wall distance: \(units.roomDistance(clearance))."
        }
        return status
    }
}

/// Immutable export snapshot, no reference images or externally supplied paths.
public struct LightingPlan: Equatable, Sendable {
    public static let reportVersion = 1
    public let title: String
    public let scene: LightingScene
    public let units: PlanUnits
    public let paper: PlanPaper
    public let lights: [PlanLight]
    public let roomPlacement: RoomPlacementPlan?
    public static let lightsPerPage = 5
    /// Four bounded rows leave room for two-line Unicode names, signed wall
    /// coordinates, face warnings and the scope notes on both paper sizes.
    public static let roomItemsPerPage = 4
    public static let roomPlacementCoordinateNote = "X/Z are measured from the left/near walls; height is above the studio floor. Negative values are beyond those walls or below the floor. Floor distance is horizontal distance to the subject."
    public static let roomPlacementLimitations = "Manual measurements, calculated at 1:1 scale. Only centers and ideal rectangular emitting-face floor projections are checked. Verify complete fixtures, stands, booms, cables and ceiling clearance physically. Ceiling clearance is not calculated; displayed precision is not measurement accuracy."

    public init(scene: LightingScene, title: String, units: PlanUnits = .metric, paper: PlanPaper = .letter) throws {
        let scene = try scene.validated()
        self.scene = scene; self.units = units; self.paper = paper
        let safe = Self.printable(title)
        self.title = safe.isEmpty ? "Portrait setup" : safe
        self.lights = scene.lights.enumerated().map { index, light in
            let optics = light.effectiveOptics
            let name = Self.printable(light.name)
            return PlanLight(number: index + 1, name: name.isEmpty ? "Light \(index + 1)" : name, position: light.position,
                             kind: optics.kind, candela: light.candela, kelvin: light.kelvin,
                             subjectDistance: light.position.distance(to: scene.subject),
                             aimTarget: optics.kind.isAimed ? light.target(subject: scene.subject) : nil,
                             followsSubject: optics.kind.isAimed && optics.aimTarget == nil,
                             aimIsValid: !optics.kind.isAimed || StudioPhotometry.frame(for: light, subject: scene.subject) != nil,
                             widthMeters: optics.kind == .rectangle ? optics.widthMeters : nil,
                             heightMeters: optics.kind == .rectangle ? optics.heightMeters : nil,
                             rollDegrees: optics.kind == .rectangle && (optics.rollDegrees != nil || optics.effectiveRollDegrees != 0)
                                ? optics.effectiveRollDegrees : nil)
        }
        self.roomPlacement = try scene.placementRoom.map { try RoomPlacementPlan(scene: scene, room: $0) }
    }

    /// Prevent line/control injection; keep ordinary Unicode names. Bound hostile
    /// long combining sequences before handing them to text layout.
    private static func printable(_ text: String) -> String {
        StudioDisplayName.display(text)
    }

    public var equipmentPages: [[PlanLight]] {
        if lights.isEmpty { return [[]] }
        return stride(from: 0, to: lights.count, by: Self.lightsPerPage).map {
            Array(lights[$0..<min($0 + Self.lightsPerPage, lights.count)])
        }
    }
    public var roomPlacementItems: [PlanRoomItem] {
        guard let roomPlacement else { return [] }
        return roomPlacement.points.enumerated().map { index, point in
            let marker: String
            let fallback: String
            switch point.kind {
            case .subject: marker = "S"; fallback = "Subject"
            case .camera: marker = "C"; fallback = "Camera"
            case .light: marker = String(index - 1); fallback = "Light \(index - 1)"
            }
            return PlanRoomItem(marker: marker, name: StudioDisplayName.label(point.name, fallback: fallback),
                                point: point, modifierFootprint: roomPlacement.modifierFootprints.first { $0.id.uuidString == point.id })
        }
    }
    public var roomPlacementPages: [[PlanRoomItem]] {
        let items = roomPlacementItems
        return stride(from: 0, to: items.count, by: Self.roomItemsPerPage).map {
            Array(items[$0..<min($0 + Self.roomItemsPerPage, items.count)])
        }
    }
    public var pageCount: Int { 1 + equipmentPages.count + roomPlacementPages.count }

    /// Shared, unit-aware page header and text-export metadata. An absent room
    /// adds no pages or text to existing lighting plans.
    public var roomPlacementSummary: [String] {
        guard let placement = roomPlacement else { return [] }
        let room = placement.room
        return [
            "Room width: \(units.roomDistance(room.widthMeters)) · Room depth: \(units.roomDistance(room.depthMeters))",
            room.ceilingHeightMeters.map { "Ceiling height: \(units.roomDistance($0)) (recorded only)" } ?? "Ceiling height: Unmeasured",
            "Subject floor position: X \(units.roomDistance(room.subjectX)) from left wall; Z \(units.roomDistance(room.subjectZ)) from near wall",
            "Rig rotation: \(PlanUnits.parameterNumber(room.yawDegrees))° · Positive rotation turns scene +Z toward room +X (right wall).",
            "Centers outside room outline: \(placement.outsideCount) of \(placement.points.count) · Emitting faces crossing walls: \(placement.crossingModifierCount) · Unavailable: \(placement.unavailableModifierCount)"
        ]
    }

    public var roomPlacementText: String? {
        guard roomPlacement != nil else { return nil }
        var lines = ["Manual room placement"] + roomPlacementSummary + [Self.roomPlacementCoordinateNote]
        for item in roomPlacementItems {
            lines += ["", "\(item.marker). \(item.name)", item.coordinates(units: units), item.centerStatus]
            if let status = item.projectedFaceStatus(units: units) { lines.append(status) }
        }
        lines += ["", Self.roomPlacementLimitations]
        return lines.joined(separator: "\n")
    }
    public var cameraSettings: String {
        "\(PlanUnits.parameterNumber(scene.effectiveCameraLens.focalLengthMillimeters)) mm · 36 × 24 mm sensor · \(units.distance(scene.camera.distance(to: scene.subject))) to subject"
    }
    public var previewSettings: String {
        let settings = scene.effectivePreviewSettings
        return "\(PlanUnits.parameterNumber(settings.whiteBalanceKelvin)) K balance · \(PlanUnits.parameterNumber(settings.exposureStops, minimumDecimals: 2)) relative stops"
    }

    /// Same validated snapshot, settings and aim semantics used by the vector PDF.
    /// Deliberately excludes reference images, paths and other project data.
    public var plainText: String {
        let header = ["Key & Fill: \(title) lighting plan",
                      "Coordinates: XYZ in \(units.symbol); Y is elevation.",
                      "Subject: \(units.parameterCoordinates(scene.subject))",
                      "Camera: \(units.parameterCoordinates(scene.camera)); \(cameraSettings)",
                      "Test card: \(previewSettings)"]
        let entries = lights.map { light in
            "\(light.number). \(light.name): \(light.kind.title) · \(light.settings(units: units)) · \(light.placement(units: units)) · \(light.aim(units: units))"
        }
        let precision = roomPlacement == nil
            ? "Entered settings and converted coordinates rounded to six fractional digits; derived distances to two."
            : "Entered settings and converted coordinates rounded to six fractional digits; equipment subject distances to two. Room distances retain up to six fractional digits, with bounds for smaller nonzero values."
        var lines = header + entries + [precision,
                                       "Ideal source parameters; not calibrated photometry. No reference images included."]
        if let roomPlacementText { lines += ["", roomPlacementText] }
        return lines.joined(separator: "\n")
    }

    /// A square-world-unit overhead projection; +X points right, +Z down.
    /// Geometry bounds include every visible target and rectangular emitter corner.
    /// Numbered labels are packed separately from anchor positions to prevent overlap.
    public func diagram() -> PlanDiagram {
        let width = paper.width - 80, height = 384.0
        let subject = PlanPoint(scene.subject), camera = PlanPoint(scene.camera)
        var positions = [subject, camera]
        var worldLines: [(PlanLine.Kind, [PlanPoint])] = []
        if subject != camera { worldLines.append((.camera, [camera, subject])) }
        for light in scene.lights {
            let origin = PlanPoint(light.position)
            positions.append(origin)
            let optics = light.effectiveOptics
            if optics.kind.isAimed {
                let target = PlanPoint(light.target(subject: scene.subject))
                positions.append(target)
                if target != origin { worldLines.append((.aim, [origin, target])) }
            }
            if optics.kind == .rectangle, let frame = StudioPhotometry.frame(for: light, subject: scene.subject) {
                let corners = [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)].map { a, b -> PlanPoint in
                    let dx = a * optics.widthMeters / 2, dy = b * optics.heightMeters / 2
                    return .init(x: origin.x + frame.right.x * dx + frame.up.x * dy,
                                 y: origin.y + frame.right.z * dx + frame.up.z * dy)
                }
                positions += corners
                worldLines.append((.modifier, corners + [corners[0]]))
            }
        }
        let minX = positions.map(\.x).min()!, maxX = positions.map(\.x).max()!
        let minZ = positions.map(\.y).min()!, maxZ = positions.map(\.y).max()!
        let worldCenter = PlanPoint(x: (minX + maxX) / 2, y: (minZ + maxZ) / 2)
        let padding = 54.0
        let scale = min((width - 2 * padding) / max(2, maxX - minX),
                        (height - 2 * padding) / max(2, maxZ - minZ))
        func project(_ p: PlanPoint) -> PlanPoint {
            .init(x: width / 2 + (p.x - worldCenter.x) * scale,
                  y: height / 2 + (p.y - worldCenter.y) * scale)
        }
        // Select 1/2/5-based grid spacing with ~7 lines along the long side.
        let targetStep = units.fromMeters(max(width, height) / scale) / 7
        let decade = pow(10, floor(log10(targetStep)))
        let step = ([1.0, 2.0, 5.0, 10.0].first { $0 * decade >= targetStep } ?? 10) * decade
        let stepMeters = units.toMeters(step)
        var grid: [PlanGridLine] = []
        let xmin = worldCenter.x - width / (2 * scale), xmax = worldCenter.x + width / (2 * scale)
        let zmin = worldCenter.y - height / (2 * scale), zmax = worldCenter.y + height / (2 * scale)
        func indices(_ minimum: Double, _ maximum: Double) -> [Int] {
            let first = Int(ceil(minimum / stepMeters)), last = Int(floor(maximum / stepMeters))
            return first <= last ? Array(first...last) : []
        }
        for i in indices(xmin, xmax) {
            let x = Double(i) * stepMeters
            grid.append(.init(from: project(.init(x: x, y: zmin)), to: project(.init(x: x, y: zmax)), isAxis: i == 0))
        }
        for i in indices(zmin, zmax) {
            let z = Double(i) * stepMeters
            grid.append(.init(from: project(.init(x: xmin, y: z)), to: project(.init(x: xmax, y: z)), isAxis: i == 0))
        }
        var markers: [PlanMarker] = []
        let entries: [(PlanMarker.Kind, String, PlanPoint)] = [(.subject, "S", subject), (.camera, "C", camera)] +
            lights.map { (.light, String($0.number), PlanPoint($0.position)) }
        let labelRadius = 11.0, spacing = 27.0
        // Precompute anchors so displaced labels do not cover other actual positions.
        let anchors = entries.map { project($0.2) }
        for (index, entry) in entries.enumerated() {
            let anchor = anchors[index]
            var candidates = [anchor]
            for ring in 1...5 {
                let radius = spacing * Double(ring), count = 8 * ring
                candidates += (0..<count).map { i in
                    let angle = 2 * Double.pi * Double(i) / Double(count)
                    return PlanPoint(x: anchor.x + radius * cos(angle), y: anchor.y + radius * sin(angle))
                }
            }
            func fits(_ p: PlanPoint) -> Bool {
                p.x >= labelRadius && p.x <= width - labelRadius && p.y >= labelRadius && p.y <= height - labelRadius &&
                markers.allSatisfy { p.distance(to: $0.center) >= spacing - 0.001 }
            }
            // A page-wide lattice is a bounded fallback if all local rings are occupied.
            // There are far more disjoint lattice positions than the 14 supported markers.
            for y in stride(from: labelRadius, through: height - labelRadius, by: spacing) {
                for x in stride(from: labelRadius, through: width - labelRadius, by: spacing) {
                    candidates.append(.init(x: x, y: y))
                }
            }
            let center = candidates.first { candidate in
                fits(candidate) && (candidate == anchor || anchors.enumerated().allSatisfy { j, p in j == index || candidate.distance(to: p) > labelRadius + 3 })
            } ?? candidates.first(where: fits) ?? anchor
            markers.append(.init(kind: entry.0, label: entry.1, anchor: anchor, center: center))
        }
        return .init(width: width, height: height, pointsPerMeter: scale, worldCenter: worldCenter,
                     gridStep: step, grid: grid, markers: markers,
                     lines: worldLines.map { .init(kind: $0.0, points: $0.1.map(project)) }, units: units)
    }
}
