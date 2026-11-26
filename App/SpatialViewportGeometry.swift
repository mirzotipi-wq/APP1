import Foundation
import LightingCore

/// Bounds of the equipment represented by the spatial adapters. Core bounds
/// deliberately omit stands and housings; keep those display details here so
/// the Plan and photometry contracts do not change when a viewport is fitted.
struct SpatialViewportBounds: Equatable, Sendable {
    static let aimTargetRadiusMeters = 0.0275
    let minimum: Position
    let maximum: Position

    init(scene: LightingScene) throws {
        let bounds = try StudioSceneBounds(scene: scene)
        var low = bounds.minimum
        var high = bounds.maximum
        func include(_ point: Position) {
            low = .init(x: min(low.x, point.x), y: min(low.y, point.y), z: min(low.z, point.z))
            high = .init(x: max(high.x, point.x), y: max(high.y, point.y), z: max(high.z, point.z))
        }
        func box(around position: Position, x: Double, below: Double, above: Double, z: Double) {
            include(.init(x: position.x - x, y: position.y - below, z: position.z - z))
            include(.init(x: position.x + x, y: position.y + above, z: position.z + z))
        }

        // Enclose both adapters' busts at every horizontal facing, and the
        // camera body/lens at every orientation. The infinite floor is excluded.
        box(around: scene.subject, x: 0.36, below: 0.96, above: 0.24, z: 0.36)
        box(around: scene.camera, x: 0.24, below: 0.24, above: 0.24, z: 0.24)
        for light in scene.lights {
            let optics = light.effectiveOptics
            if StudioPhotometry.frame(for: light, subject: scene.subject) != nil {
                let radius = Self.aimTargetRadiusMeters
                box(around: light.target(subject: scene.subject), x: radius, below: radius, above: radius, z: radius)
            }
            if optics.kind == .point {
                box(around: light.position, x: 0.12, below: 0.12, above: 0.12, z: 0.12)
            } else {
                // Include the full housing and selection outline, even when a
                // coincident aim has no core emitter frame. In that case both
                // adapters display a world-aligned, non-emitting housing.
                let frame = StudioPhotometry.frame(for: light, subject: scene.subject)
                let right = frame?.right ?? UnitDirection(x: 1, y: 0, z: 0)!
                let up = frame?.up ?? UnitDirection(x: 0, y: 1, z: 0)!
                let normal = frame?.normal ?? UnitDirection(x: 0, y: 0, z: 1)!
                let halfWidth = (optics.kind == .rectangle ? optics.widthMeters : 0.22) / 2 + 0.03
                let halfHeight = (optics.kind == .rectangle ? optics.heightMeters : 0.18) / 2 + 0.03
                for x in [-halfWidth, halfWidth] {
                    for y in [-halfHeight, halfHeight] {
                        for z in [-0.15, 0.08] {
                            include(.init(x: light.position.x + right.x * x + up.x * y + normal.x * z,
                                          y: light.position.y + right.y * x + up.y * y + normal.y * z,
                                          z: light.position.z + right.z * x + up.z * y + normal.z * z))
                        }
                    }
                }
            }
            if light.position.y > 0.05 {
                // World-floor stands are intentionally not vertically
                // translation invariant. Their bases must remain in the fit.
                box(around: .init(x: light.position.x, y: 0.014, z: light.position.z),
                    x: 0.24, below: 0.014, above: 0.014, z: 0.24)
            }
        }
        minimum = low
        maximum = high
    }

    var center: Position {
        .init(x: (minimum.x + maximum.x) / 2,
              y: (minimum.y + maximum.y) / 2,
              z: (minimum.z + maximum.z) / 2)
    }

    var radiusMeters: Double { minimum.distance(to: maximum) / 2 }
}

/// Pure camera navigation shared by the RealityKit adapter and regression
/// tests. Coordinates stay in Double until the final native transform upload.
/// A gesture never edits the authored camera or any scene equipment.
struct SpatialOrbitState: Equatable, Sendable {
    static let fieldOfViewDegrees = 48.0
    static let distanceRange: ClosedRange<Double> = 0.45...1_500
    private(set) var target = Position(x: 0, y: 1, z: 0)
    private(set) var yaw = 0.56
    private(set) var pitch = 0.36
    private(set) var distance = 7.0

    mutating func fit(_ bounds: SpatialViewportBounds) {
        target = bounds.center
        distance = Self.clamp(max(0.8, bounds.radiusMeters) / sin(24 * .pi / 180) * 1.12,
                              to: Self.distanceRange)
        yaw = 0.56
        pitch = 0.36
    }

    var position: Position {
        .init(x: target.x + sin(yaw) * cos(pitch) * distance,
              y: target.y + sin(pitch) * distance,
              z: target.z + cos(yaw) * cos(pitch) * distance)
    }

    var farDistance: Double {
        // Target panning is bounded to +/-300 m; authored centers are within
        // +/-100 m, plus modifier margins. Enclose their full relative diagonal
        // even after panning and orbiting at minimum distance. Translation of a
        // fitted rig must not change its clipping depth.
        distance + 750
    }

    static func verticalFieldOfView(width: Double, height: Double) -> Double? {
        guard width.isFinite, height.isFinite, width > 0, height > 0 else { return nil }
        if width >= height { return fieldOfViewDegrees }
        let halfTangent = tan(fieldOfViewDegrees * .pi / 360) * (height / width)
        let result = 2 * atan(halfTangent) * 180 / .pi
        return result.isFinite && result < 180 ? result : nil
    }

    mutating func orbit(horizontal: Double, vertical: Double) {
        guard horizontal.isFinite, vertical.isFinite else { return }
        yaw = (yaw - horizontal * 0.008).remainder(dividingBy: 2 * .pi)
        pitch = Self.clamp(pitch + vertical * 0.008, to: -1.35...1.35)
    }

    mutating func pan(horizontal: Double, vertical: Double, width: Double, height: Double) {
        guard horizontal.isFinite, vertical.isFinite,
              width.isFinite, height.isFinite, width > 0, height > 0 else { return }
        let metersPerPoint = 2 * distance * tan(Self.fieldOfViewDegrees * .pi / 360) / min(width, height)
        // Camera right = (cos yaw, 0, -sin yaw); camera up is the
        // orthogonal pitch basis. Drag follows the image plane at the target.
        let x = target.x + (-cos(yaw) * horizontal - sin(yaw) * sin(pitch) * vertical) * metersPerPoint
        let y = target.y + cos(pitch) * vertical * metersPerPoint
        let z = target.z + (sin(yaw) * horizontal - cos(yaw) * sin(pitch) * vertical) * metersPerPoint
        guard x.isFinite, y.isFinite, z.isFinite else { return }
        target = .init(x: Self.clamp(x, to: -300...300), y: Self.clamp(y, to: -300...300),
                       z: Self.clamp(z, to: -300...300))
    }

    mutating func zoom(scale: Double) {
        guard scale.isFinite, scale > 0 else { return }
        distance = Self.clamp(distance / scale, to: Self.distanceRange)
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, value))
    }
}
