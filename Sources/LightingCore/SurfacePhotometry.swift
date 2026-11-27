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
        // The cross product of two represented unit axes can be slightly
        // shorter than one after rounding. Depth is a distance, so its normal
        // must itself be normalized; otherwise rolling a rectangle can reject
        // an exact minimum-separation receiver. No separation epsilon is used.
        guard let direction = UnitDirection(x: r.y * u.z - r.z * u.y,
                                            y: r.z * u.x - r.x * u.z,
                                            z: r.x * u.y - r.y * u.x) else { return nil }
        normal = direction.vector
    }
}

/// A vertex of the emitting face in its local meter coordinates. Incidence
/// is the unnormalized projection toward the receiver's front hemisphere.
/// Keeping it at vertices permits stable positive barycentric interpolation
/// even for a very narrow, nearly tangent contributing part of the face.
private struct IncidenceVertex {
    let point: SIMD2<Double>
    let incidence: Double
}

/// Twelve-point Gauss-Legendre nodes and weights on [0, 1].
/// A square-to-triangle map integrates the clipped polygon as a triangle fan.
/// The higher order keeps the partial/full transition error small even at
/// the minimum supported plane separation.
private let gauss12: [(node: Double, weight: Double)] = [
    (0.009219682876640378, 0.023587668193255706),
    (0.0479413718147626, 0.05346966299765953),
    (0.11504866290284765, 0.08003916427167321),
    (0.20634102285669126, 0.10158371336153287),
    (0.31608425050090994, 0.1167462682691773),
    (0.43738329574426554, 0.12457352290670134),
    (0.5626167042557344, 0.12457352290670134),
    (0.6839157494990901, 0.1167462682691773),
    (0.7936589771433087, 0.10158371336153287),
    (0.8849513370971523, 0.08003916427167321),
    (0.9520586281852375, 0.05346966299765953),
    (0.9907803171233596, 0.023587668193255706)
]

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

    /// Integrates E = L cos(thetaEmitter) cos(thetaReceiver) dA / r^2,
    /// with L = on-axis cd / emitter area. Fully front-facing emitters use
    /// the same 32x32 midpoint grid as the unoccluded reference renderer.
    /// Partially front-facing emitters are clipped to the receiver hemisphere,
    /// preventing a narrow contributing strip from disappearing between samples.
    /// A clipped rectangle has at most five vertices; 12x12 Gaussian quadrature
    /// per triangle bounds this partial-face calculation to 432 evaluations.
    /// The sampled renderer remains approximate at grazing incidence.
    /// The receiver must still be separated from the emitter plane by at least
    /// 5 cm and one quarter of the longest side; nearer configurations abstain.
    /// No occlusion, reflection, spectral effects or modifier transmission.
    public static func rectangularIlluminance(emitter: LambertianRectangle, receiver: Position,
                                              receiverNormal: UnitDirection) -> Double? {
        guard receiver.isValid else { return nil }
        let toReceiver = vector(receiver) - vector(emitter.center)
        let depth = dot(toReceiver, emitter.normal)
        let minimumDepth = max(0.05, max(emitter.widthMeters, emitter.heightMeters) / 4)
        guard abs(depth) >= minimumDepth else { return nil }
        if depth < 0 || emitter.onAxisCandela == 0 { return 0 }

        // Keep the geometric integration at unit intensity when dividing an
        // extremely small output among cells would lose its significant bits.
        // Apply intensity once, after summation. The ordinary-output path keeps
        // its established sample ordering and rounding for renderer parity.
        if emitter.onAxisCandela < Double.leastNormalMagnitude * 1024 {
            guard let unit = LambertianRectangle(
                center: emitter.center, right: emitter.right, up: emitter.up,
                widthMeters: emitter.widthMeters, heightMeters: emitter.heightMeters,
                onAxisCandela: 1),
                let unitLux = rectangularIlluminance(emitter: unit, receiver: receiver,
                                                     receiverNormal: receiverNormal) else { return nil }
            return unitLux * emitter.onAxisCandela
        }

        let right = emitter.right.vector, up = emitter.up.vector
        let normal = receiverNormal.vector
        let nx = dot(right, normal), ny = dot(up, normal)
        let offset = dot(toReceiver, normal)
        let halfWidth = emitter.widthMeters / 2
        let halfHeight = emitter.heightMeters / 2
        let corners: [SIMD2<Double>] = [
            .init(-halfWidth, -halfHeight), .init(halfWidth, -halfHeight),
            .init(halfWidth, halfHeight), .init(-halfWidth, halfHeight)
        ]
        let vertices = corners.map { p in
            IncidenceVertex(point: p, incidence: nx * p.x + ny * p.y - offset)
        }
        if vertices.allSatisfy({ $0.incidence <= 0 }) { return 0 }
        if vertices.allSatisfy({ $0.incidence >= 0 }) {
            // Preserve the existing 32x32 sample convention, ordering, and
            // normalization for ordinary fully illuminated surfaces.
            return fullRectangleMidpoint(emitter: emitter, toReceiver: toReceiver,
                                         receiverNormal: receiverNormal)
        }
        var polygon: [IncidenceVertex] = []
        polygon.reserveCapacity(5)
        // Sutherland-Hodgman clipping against one affine half-plane. A
        // boundary vertex has zero contribution; avoid duplicating it.
        for i in vertices.indices {
            let a = vertices[(i + vertices.count - 1) % vertices.count]
            let b = vertices[i]
            if (a.incidence < 0 && b.incidence > 0) || (a.incidence > 0 && b.incidence < 0) {
                let t = a.incidence / (a.incidence - b.incidence)
                polygon.append(.init(point: a.point + (b.point - a.point) * t, incidence: 0))
            }
            if b.incidence >= 0 { polygon.append(b) }
        }
        guard polygon.count >= 3 else { return 0 }

        var integral = 0.0
        let a = polygon[0]
        for i in 1..<(polygon.count - 1) {
            let b = polygon[i], c = polygon[i + 1]
            let ab = b.point - a.point, ac = c.point - a.point
            let determinant = abs(ab.x * ac.y - ab.y * ac.x)
            if determinant == 0 { continue }
            // Duffy map: p = a + u(b-a) + (1-u)v(c-a).
            // The Jacobian is determinant * (1-u).
            for (u, wu) in gauss12 {
                let remaining = 1 - u
                for (v, wv) in gauss12 {
                    let cWeight = remaining * v
                    let aWeight = remaining * (1 - v)
                    let p = a.point + ab * u + ac * cWeight
                    // The signed projection is affine across each triangle.
                    // Its three nonnegative vertex values prevent cancellation
                    // from erasing a sliver of grazing-angle illumination.
                    let incidence = aWeight * a.incidence + u * b.incidence + cWeight * c.incidence
                    let delta = toReceiver - right * p.x - up * p.y
                    let r2 = dot(delta, delta)
                    integral += determinant * wu * wv * remaining * depth * incidence / (r2 * r2)
                }
            }
        }
        let radiance = emitter.onAxisCandela / (emitter.widthMeters * emitter.heightMeters)
        return radiance * integral
    }

    /// Existing reference-grid integration for fully front-facing receivers.
    private static func fullRectangleMidpoint(emitter: LambertianRectangle,
                                              toReceiver: SIMD3<Double>,
                                              receiverNormal: UnitDirection) -> Double {
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
