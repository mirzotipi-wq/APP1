import Foundation

/// A finite, normalized direction. Scene positions remain in meters.
public struct UnitDirection: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init?(x: Double, y: Double, z: Double) {
        guard x.isFinite, y.isFinite, z.isFinite else { return nil }
        let scale = max(abs(x), max(abs(y), abs(z)))
        guard scale > 0 else { return nil }
        let a = x / scale, b = y / scale, c = z / scale
        let length = (a * a + b * b + c * c).squareRoot()
        self.x = a / length; self.y = b / length; self.z = c / length
    }

    fileprivate var vector: SIMD3<Double> { .init(x, y, z) }
}

private func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
    a.x * b.x + a.y * b.y + a.z * b.z
}

private func vector(_ p: Position) -> SIMD3<Double> { .init(p.x, p.y, p.z) }

/// Uniform, one-sided Lambertian rectangle; not a calibrated equipment profile.
/// `right` cross `up` points along the emitting normal. `onAxisCandela` is the
/// total far-field intensity along that normal, not luminous flux or watts.
public struct LambertianRectangle: Sendable {
    public let center: Position
    public let right: UnitDirection
    public let up: UnitDirection
    public let widthMeters: Double
    public let heightMeters: Double
    public let onAxisCandela: Double
    fileprivate let normal: SIMD3<Double>

    public init?(center: Position, right: UnitDirection, up: UnitDirection,
                 widthMeters: Double, heightMeters: Double, onAxisCandela: Double) {
        guard center.isValid, widthMeters.isFinite, heightMeters.isFinite,
              (0.05...4).contains(widthMeters), (0.05...4).contains(heightMeters),
              onAxisCandela.isFinite, (0...100_000).contains(onAxisCandela),
              abs(dot(right.vector, up.vector)) <= 1e-8 else { return nil }
        self.center = center; self.right = right; self.up = up
        self.widthMeters = widthMeters; self.heightMeters = heightMeters
        self.onAxisCandela = onAxisCandela
        let r = right.vector, u = up.vector
        normal = .init(r.y * u.z - r.z * u.y, r.z * u.x - r.x * u.z, r.x * u.y - r.y * u.x)
    }
}

extension Photometry {
    /// Ideal isotropic point source incident on an oriented surface, in lux.
    /// Intensity is the candela in the receiver's direction; no occlusion.
    /// Returns nil for invalid input or distances below 5 cm.
    public static func pointIlluminance(candela: Double, source: Position, receiver: Position,
                                        receiverNormal: UnitDirection) -> Double? {
        guard source.isValid, receiver.isValid else { return nil }
        let delta = vector(source) - vector(receiver)
        let distance = dot(delta, delta).squareRoot()
        guard let normalLux = normalIlluminance(candela: candela, distanceMeters: distance) else { return nil }
        return normalLux * min(1, max(0, dot(delta / distance, receiverNormal.vector)))
    }

    /// Integrates E = L cos(thetaEmitter) cos(thetaReceiver) dA / r^2.
    /// L = on-axis cd / emitter area; a fixed 32x32 midpoint grid bounds work.
    /// The receiver must be separated from the emitter plane by at least 5 cm
    /// and one quarter of its longest side. Nearer configurations return nil
    /// rather than pretending that coarse quadrature is reliable.
    /// No occlusion, reflection, spectral effects or modifier transmission.
    public static func rectangularIlluminance(emitter: LambertianRectangle, receiver: Position,
                                              receiverNormal: UnitDirection) -> Double? {
        guard receiver.isValid else { return nil }
        let toReceiver = vector(receiver) - vector(emitter.center)
        let depth = dot(toReceiver, emitter.normal)
        let minimumDepth = max(0.05, max(emitter.widthMeters, emitter.heightMeters) / 4)
        guard abs(depth) >= minimumDepth else { return nil }
        if depth < 0 || emitter.onAxisCandela == 0 { return 0 }

        let samples = 32
        let candelaPerCell = emitter.onAxisCandela / Double(samples * samples)
        var lux = 0.0
        for j in 0..<samples {
            let y = ((Double(j) + 0.5) / Double(samples) - 0.5) * emitter.heightMeters
            for i in 0..<samples {
                let x = ((Double(i) + 0.5) / Double(samples) - 0.5) * emitter.widthMeters
                let delta = toReceiver - emitter.right.vector * x - emitter.up.vector * y
                let r2 = dot(delta, delta)
                let direction = delta / r2.squareRoot()
                let emission = min(1, max(0, dot(direction, emitter.normal)))
                let incidence = min(1, max(0, -dot(direction, receiverNormal.vector)))
                lux += candelaPerCell * emission * incidence / r2
            }
        }
        return lux
    }
}
