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

/// A vertex of the emitting face in its local meter coordinates. Incidence
/// is the unnormalized projection toward the receiver's front hemisphere.
/// Keeping it at vertices permits stable positive barycentric interpolation
/// even for a very narrow, nearly tangent contributing part of the face.
private struct IncidenceVertex {
    let point: SIMD2<Double>
    let incidence: Double
}

/// Eight-point Gauss-Legendre nodes and weights mapped to [0, 1].
/// We integrate the clipped polygon as a fan of triangles using a square-to-
/// triangle map. These constants integrate polynomials through degree 15
/// along each axis; smooth inverse-distance terms converge numerically.
private let gauss8: [(node: Double, weight: Double)] = [
    (0.0198550717512319, 0.0506142681451881),
    (0.101666761293187, 0.111190517226687),
    (0.237233795041836, 0.156853322938944),
    (0.408282678752175, 0.181341891689181),
    (0.591717321247825, 0.181341891689181),
    (0.762766204958164, 0.156853322938944),
    (0.898333238706813, 0.111190517226687),
    (0.980144928248768, 0.0506142681451881)
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
    /// with L = on-axis cd / emitter area. Clip the rectangular face to the
    /// receiver's front hemisphere before integrating. This avoids losing
    /// a narrow positive-incidence region between fixed midpoint samples.
    /// A convex rectangle clipped by a half-plane has at most five vertices;
    /// 8x8 Gaussian quadrature per triangle keeps the diagnostic cost bounded.
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
            for (u, wu) in gauss8 {
                let remaining = 1 - u
                for (v, wv) in gauss8 {
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
}
