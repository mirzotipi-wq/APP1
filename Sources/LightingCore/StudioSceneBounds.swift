import Foundation

/// Finite bounds of authored studio geometry in world meters. View fitting must
/// depend on the rig's dimensions, not its distance from the world origin.
/// Includes camera/subject/light centers, visible aim targets and rectangular
/// emitting-face corners. Does not imply bounds for a floor, stands or housing.
public struct StudioSceneBounds: Equatable, Sendable {
    public let minimum: Position
    public let maximum: Position
    /// A rectangle with coincident source and target has no defined orientation.
    /// Keep its center in the bounds and report the omitted face explicitly.
    public let unavailableModifierIDs: [UUID]

    public init(scene: LightingScene) throws {
        let validated = try scene.validated()
        var positions = [validated.subject, validated.camera]
        var unavailable: [UUID] = []
        for light in validated.lights {
            positions.append(light.position)
            let optics = light.effectiveOptics
            if optics.kind.isAimed { positions.append(light.target(subject: validated.subject)) }
            guard optics.kind == .rectangle else { continue }
            guard let frame = StudioPhotometry.frame(for: light, subject: validated.subject) else {
                unavailable.append(light.id)
                continue
            }
            for (horizontal, vertical) in [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)] {
                let dx = horizontal * optics.widthMeters / 2
                let dy = vertical * optics.heightMeters / 2
                // Derived corners may extend beyond the authoring coordinate
                // limit when a valid emitter center is near that boundary.
                positions.append(.init(x: light.position.x + frame.right.x * dx + frame.up.x * dy,
                                       y: light.position.y + frame.right.y * dx + frame.up.y * dy,
                                       z: light.position.z + frame.right.z * dx + frame.up.z * dy))
            }
        }
        var low = validated.subject, high = validated.subject
        for p in positions {
            low = .init(x: min(low.x, p.x), y: min(low.y, p.y), z: min(low.z, p.z))
            high = .init(x: max(high.x, p.x), y: max(high.y, p.y), z: max(high.z, p.z))
        }
        minimum = low
        maximum = high
        unavailableModifierIDs = unavailable
    }

    public var center: Position {
        .init(x: (minimum.x + maximum.x) / 2,
              y: (minimum.y + maximum.y) / 2,
              z: (minimum.z + maximum.z) / 2)
    }

    public var halfExtents: Position {
        .init(x: (maximum.x - minimum.x) / 2,
              y: (maximum.y - minimum.y) / 2,
              z: (maximum.z - minimum.z) / 2)
    }

    /// Radius of a sphere containing these bounds, useful for an initial orbit
    /// fit. A coincident empty rig has zero radius; adapters choose a view minimum.
    public var radiusMeters: Double {
        let half = halfExtents
        return sqrt(half.x * half.x + half.y * half.y + half.z * half.z)
    }

    /// Aspect-preserving overhead transform, with +X right and +Z down.
    /// Padding is in viewport points. A minimum world span keeps a small or
    /// coincident rig useful without introducing a world-origin dependency.
    public func overheadFit(width: Double, height: Double, padding: Double = 40,
                            minimumSpanMeters: Double = 2) -> StudioOverheadProjection? {
        guard width.isFinite, height.isFinite, width > 0, height > 0,
              padding.isFinite, padding >= 0, padding < min(width, height) / 2,
              minimumSpanMeters.isFinite, minimumSpanMeters > 0 else { return nil }
        let xSpan = max(minimumSpanMeters, maximum.x - minimum.x)
        let zSpan = max(minimumSpanMeters, maximum.z - minimum.z)
        let scale = min((width - 2 * padding) / xSpan, (height - 2 * padding) / zSpan)
        guard scale.isFinite, scale > 0 else { return nil }
        return .init(width: width, height: height, center: center, pointsPerMeter: scale)
    }
}

public struct StudioViewportPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
}

public struct StudioOverheadProjection: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let center: Position
    public let pointsPerMeter: Double

    /// Projects finite world/derived geometry without clamping it to the view.
    /// Points beyond the fitted bounds remain outside, preserving spatial truth.
    public func project(_ position: Position) -> StudioViewportPoint {
        .init(x: width / 2 + (position.x - center.x) * pointsPerMeter,
              y: height / 2 + (position.z - center.z) * pointsPerMeter)
    }

    /// A world-aligned grid with bounded drawing work, even when fitting a
    /// large rig into a viewport barely wider than its requested padding.
    /// Spacing is 1, 2 or 5 times a power of ten, never less than one meter.
    /// The safety ceiling is 512 lines per axis; requests below two are invalid.
    public func grid(maximumLinesPerAxis requestedLimit: Int = 128) -> StudioPlanGrid? {
        guard requestedLimit >= 2,
              width.isFinite, height.isFinite, width > 0, height > 0,
              pointsPerMeter.isFinite, pointsPerMeter > 0,
              center.x.isFinite, center.z.isFinite else { return nil }
        let limit = min(requestedLimit, 512)
        let xSpan = width / pointsPerMeter, zSpan = height / pointsPerMeter
        guard xSpan.isFinite, zSpan.isFinite, xSpan > 0, zSpan > 0 else { return nil }
        let left = center.x - xSpan / 2, right = center.x + xSpan / 2
        let near = center.z - zSpan / 2, far = center.z + zSpan / 2
        guard left.isFinite, right.isFinite, near.isFinite, far.isFinite else { return nil }

        func niceCeiling(_ value: Double) -> Double? {
            guard value.isFinite, value > 0 else { return nil }
            let decade = pow(10, floor(log10(max(1, value))))
            guard decade.isFinite, decade > 0 else { return nil }
            let fraction = value / decade
            let multiplier = fraction <= 1 ? 1.0 : fraction <= 2 ? 2.0 : fraction <= 5 ? 5.0 : 10.0
            let step = decade * multiplier
            return step.isFinite && step >= 1 ? step : nil
        }

        func coordinates(from lower: Double, through upper: Double, step: Double) -> [Double]? {
            let first = ceil(lower / step), last = floor(upper / step)
            guard first.isFinite, last.isFinite else { return nil }
            if first > last { return [] }
            let count = last - first + 1
            guard count.isFinite, count <= Double(limit) else { return nil }
            var result: [Double] = []
            result.reserveCapacity(limit)
            // Never convert an unbounded world coordinate or line count to Int.
            // Iteration count is independent of viewport aspect ratio and scale.
            for offset in 0..<limit {
                let index = first + Double(offset)
                if index > last { break }
                let coordinate = index * step
                guard coordinate.isFinite else { return nil }
                if coordinate >= lower && coordinate <= upper {
                    result.append(coordinate == 0 ? 0 : coordinate)
                }
            }
            return result
        }

        let required = max(1, max(xSpan, zSpan) / Double(limit - 1))
        guard var step = niceCeiling(required) else { return nil }
        // A larger nice step resolves a possible boundary-rounding extra line.
        // Retry count and each coordinate loop are independently bounded.
        for _ in 0..<4 {
            if let vertical = coordinates(from: left, through: right, step: step),
               let horizontal = coordinates(from: near, through: far, step: step) {
                return .init(spacingMeters: step, verticalWorldCoordinates: vertical,
                             horizontalWorldCoordinates: horizontal)
            }
            guard let larger = niceCeiling(step * 2), larger > step else { return nil }
            step = larger
        }
        return nil
    }
}

public struct StudioPlanGrid: Equatable, Sendable {
    public let spacingMeters: Double
    /// X coordinates of vertical lines, in meters.
    public let verticalWorldCoordinates: [Double]
    /// Z coordinates of horizontal lines, in meters.
    public let horizontalWorldCoordinates: [Double]
}
