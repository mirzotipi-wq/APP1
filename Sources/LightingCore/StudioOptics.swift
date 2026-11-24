import Foundation

public enum EmitterKind: String, Codable, CaseIterable, Sendable {
    case point, directional, rectangle

    public var title: String {
        switch self {
        case .point: return "Bare point"
        case .directional: return "Directional"
        case .rectangle: return "Rectangular softbox"
        }
    }
    public var isAimed: Bool { self != .point }
}

/// Ideal emitter geometry, not a measured modifier or equipment profile.
/// Nil aimTarget follows the subject. A manual target is an absolute world position in meters.
public struct LightOptics: Codable, Equatable, Sendable {
    public static let dimensionRange: ClosedRange<Double> = 0.05...4
    public static let rollRange: ClosedRange<Double> = -180...180
    public var kind: EmitterKind
    public var aimTarget: Position?
    public var widthMeters: Double
    public var heightMeters: Double
    /// Rotation about the emitting normal. Nil preserves the legacy world-up orientation.
    public var rollDegrees: Double?

    public init(kind: EmitterKind = .point, aimTarget: Position? = nil,
                widthMeters: Double = 0.6, heightMeters: Double = 0.9,
                rollDegrees: Double? = nil) {
        self.kind = kind; self.aimTarget = aimTarget
        self.widthMeters = widthMeters; self.heightMeters = heightMeters
        self.rollDegrees = rollDegrees
    }

    public var effectiveRollDegrees: Double { rollDegrees ?? 0 }

    public var isValid: Bool {
        (aimTarget?.isValid ?? true) && widthMeters.isFinite && heightMeters.isFinite &&
        Self.dimensionRange.contains(widthMeters) && Self.dimensionRange.contains(heightMeters) &&
        effectiveRollDegrees.isFinite && Self.rollRange.contains(effectiveRollDegrees)
    }
}

extension StudioLight {
    public var effectiveOptics: LightOptics { optics ?? .init() }
    public func target(subject: Position) -> Position { effectiveOptics.aimTarget ?? subject }
}

/// Right-handed world-space basis; right × up = emitting normal.
/// Zero roll follows world up, with a deterministic basis at a vertical aim.
/// Positive roll turns right toward up around the emitting normal (the right-hand rule).
public struct EmitterFrame: Equatable, Sendable {
    public let right: UnitDirection
    public let up: UnitDirection
    public let normal: UnitDirection

    public init?(source: Position, target: Position, rollDegrees: Double = 0) {
        guard source.isValid, target.isValid, rollDegrees.isFinite,
              LightOptics.rollRange.contains(rollDegrees),
              let n = UnitDirection(x: target.x - source.x, y: target.y - source.y, z: target.z - source.z) else { return nil }
        let horizontal = hypot(n.x, n.z)
        let r = horizontal > 1e-12
            ? UnitDirection(x: n.z, y: 0, z: -n.x)
            : UnitDirection(x: 1, y: 0, z: 0)
        guard let r, let u = UnitDirection(x: n.y * r.z - n.z * r.y,
                                           y: n.z * r.x - n.x * r.z,
                                           z: n.x * r.y - n.y * r.x) else { return nil }
        // Keep legacy sample coordinates exactly unchanged when no roll is requested.
        if rollDegrees == 0 {
            self.right = r; self.up = u; self.normal = n
            return
        }
        let radians = rollDegrees * .pi / 180
        let c = cos(radians), s = sin(radians)
        guard let rolledRight = UnitDirection(x: c * r.x + s * u.x,
                                              y: c * r.y + s * u.y,
                                              z: c * r.z + s * u.z),
              let rolledUp = UnitDirection(x: -s * r.x + c * u.x,
                                           y: -s * r.y + c * u.y,
                                           z: -s * r.z + c * u.z) else { return nil }
        self.right = rolledRight; self.up = rolledUp; self.normal = n
    }
}

/// Estimates illuminance at the subject's center on a plane facing the scene camera.
/// This is a diagnostic sample, not exposure or the brightness of a rendered face.
public enum StudioPhotometry {
    public static func receiverNormal(in scene: LightingScene) -> UnitDirection? {
        guard scene.subject.isValid, scene.camera.isValid else { return nil }
        return UnitDirection(x: scene.camera.x - scene.subject.x,
                             y: scene.camera.y - scene.subject.y,
                             z: scene.camera.z - scene.subject.z)
    }

    public static func frame(for light: StudioLight, subject: Position) -> EmitterFrame? {
        guard light.isValid, light.effectiveOptics.kind.isAimed else { return nil }
        return EmitterFrame(source: light.position, target: light.target(subject: subject),
                            rollDegrees: light.effectiveOptics.effectiveRollDegrees)
    }

    public static func illuminance(for light: StudioLight, in scene: LightingScene) -> Double? {
        guard light.isValid, let normal = receiverNormal(in: scene) else { return nil }
        let optics = light.effectiveOptics
        switch optics.kind {
        case .point:
            return Photometry.pointIlluminance(candela: light.candela, source: light.position,
                                              receiver: scene.subject, receiverNormal: normal)
        case .directional:
            // Ideal one-sided cosine emitter. Not a hard-edged spotlight or a measured beam.
            guard let frame = frame(for: light, subject: scene.subject),
                  let ray = UnitDirection(x: scene.subject.x - light.position.x,
                                          y: scene.subject.y - light.position.y,
                                          z: scene.subject.z - light.position.z),
                  let lux = Photometry.pointIlluminance(candela: light.candela, source: light.position,
                                                        receiver: scene.subject, receiverNormal: normal) else { return nil }
            let n = frame.normal
            let emission = min(1, max(0, n.x * ray.x + n.y * ray.y + n.z * ray.z))
            return lux * emission
        case .rectangle:
            guard let frame = frame(for: light, subject: scene.subject),
                  let emitter = LambertianRectangle(center: light.position, right: frame.right, up: frame.up,
                                                      widthMeters: optics.widthMeters, heightMeters: optics.heightMeters,
                                                      onAxisCandela: light.candela) else { return nil }
            return Photometry.rectangularIlluminance(emitter: emitter, receiver: scene.subject, receiverNormal: normal)
        }
    }
}
