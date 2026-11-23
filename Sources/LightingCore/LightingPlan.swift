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

    public func settings(units: PlanUnits) -> String {
        let output = "\(PlanUnits.number(candela)) cd · \(PlanUnits.number(kelvin, decimals: 0)) K"
        if let widthMeters, let heightMeters {
            return "\(output) · \(units.distance(widthMeters)) × \(units.distance(heightMeters))"
        }
        return output
    }
    public func placement(units: PlanUnits) -> String {
        "XYZ \(units.coordinates(position)) · Subject distance \(units.distance(subjectDistance))"
    }
    public func aim(units: PlanUnits) -> String {
        guard let aimTarget else { return "Omnidirectional ideal source · no aiming direction" }
        guard aimIsValid else { return "Aim undefined: target coincides with source" }
        return "Aim \(units.coordinates(aimTarget)) · \(followsSubject ? "follows subject" : "manual target")"
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
    public static let lightsPerPage = 5

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
                             heightMeters: optics.kind == .rectangle ? optics.heightMeters : nil)
        }
    }

    /// Prevent line/control injection; keep ordinary Unicode names. Bound hostile
    /// long combining sequences before handing them to text layout.
    private static func printable(_ text: String) -> String {
        let scalars = text.unicodeScalars.prefix(320).map { scalar -> Unicode.Scalar in
            switch scalar.properties.generalCategory {
            case .control, .lineSeparator, .paragraphSeparator: return " "
            default: return scalar
            }
        }
        let cleaned = String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count > 80 || text.unicodeScalars.count > 320 { return String(cleaned.prefix(79)) + "…" }
        return cleaned
    }

    public var equipmentPages: [[PlanLight]] {
        if lights.isEmpty { return [[]] }
        return stride(from: 0, to: lights.count, by: Self.lightsPerPage).map {
            Array(lights[$0..<min($0 + Self.lightsPerPage, lights.count)])
        }
    }
    public var pageCount: Int { 1 + equipmentPages.count }
    public var cameraSettings: String {
        "\(PlanUnits.number(scene.effectiveCameraLens.focalLengthMillimeters, decimals: 0)) mm · 36 × 24 mm sensor · \(units.distance(scene.camera.distance(to: scene.subject))) to subject"
    }
    public var previewSettings: String {
        let settings = scene.effectivePreviewSettings
        return "\(PlanUnits.number(settings.whiteBalanceKelvin, decimals: 0)) K balance · \(PlanUnits.number(settings.exposureStops, decimals: 2)) relative stops"
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
