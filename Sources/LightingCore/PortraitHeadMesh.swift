import Foundation

/// An original continuous, closed mannequin head surface. The cross-section
/// profile and smooth local facial displacements are synthetic neutral study
/// geometry, not a biometric model or a scan. All dimensions are meters.
struct PortraitHeadMesh: Sendable {
    static let latitudeSegments = 42
    static let longitudeSegments = 64
    private static let lowerY = -0.133
    private static let upperY = 0.143
    private static let profile: [Profile] = [
        .init(y: -0.133, width: 0, front: 0.026, back: 0.026),
        .init(y: -0.123, width: 0.030, front: 0.058, back: -0.008),
        .init(y: -0.105, width: 0.052, front: 0.072, back: -0.035),
        .init(y: -0.080, width: 0.069, front: 0.077, back: -0.052),
        .init(y: -0.049, width: 0.080, front: 0.075, back: -0.075),
        .init(y: -0.015, width: 0.087, front: 0.080, back: -0.094),
        .init(y:  0.020, width: 0.091, front: 0.076, back: -0.105),
        .init(y:  0.052, width: 0.089, front: 0.074, back: -0.104),
        .init(y:  0.083, width: 0.078, front: 0.065, back: -0.093),
        .init(y:  0.108, width: 0.059, front: 0.051, back: -0.071),
        .init(y:  0.130, width: 0.032, front: 0.028, back: -0.043),
        .init(y:  0.143, width: 0, front: -0.005, back: -0.005)
    ]

    private struct Profile: Sendable {
        let y: Double
        let width: Double
        let front: Double
        let back: Double
    }

    struct Hit: Sendable {
        let distance: Double
        let normal: SIMD3<Double>
        let geometricNormal: SIMD3<Double>
    }

    private struct Vertex: Sendable {
        let position: SIMD3<Double>
        let normal: SIMD3<Double>
    }

    private struct Bounds: Sendable {
        var low = SIMD3<Double>(repeating: .infinity)
        var high = SIMD3<Double>(repeating: -.infinity)

        mutating func include(_ p: SIMD3<Double>) {
            low = .init(min(low.x, p.x), min(low.y, p.y), min(low.z, p.z))
            high = .init(max(high.x, p.x), max(high.y, p.y), max(high.z, p.z))
        }

        mutating func include(_ other: Bounds) {
            include(other.low)
            include(other.high)
        }

        func contains(_ p: SIMD3<Double>) -> Bool {
            p.x >= low.x && p.x <= high.x && p.y >= low.y && p.y <= high.y &&
            p.z >= low.z && p.z <= high.z
        }

        func intersects(origin: SIMD3<Double>, direction: SIMD3<Double>,
                        minimum: Double, maximum: Double) -> Bool {
            var near = minimum, far = maximum
            for axis in 0..<3 {
                let lo = low[axis] - 1e-10, hi = high[axis] + 1e-10
                if abs(direction[axis]) < 1e-14 {
                    if origin[axis] < lo || origin[axis] > hi { return false }
                } else {
                    let a = (lo - origin[axis]) / direction[axis]
                    let b = (hi - origin[axis]) / direction[axis]
                    near = max(near, min(a, b))
                    far = min(far, max(a, b))
                    if near > far { return false }
                }
            }
            return true
        }
    }

    private struct Triangle: Sendable {
        let a: Vertex
        let b: Vertex
        let c: Vertex
        let edge1: SIMD3<Double>
        let edge2: SIMD3<Double>
        let bounds: Bounds
        let centroid: SIMD3<Double>

        init?(_ a: Vertex, _ b: Vertex, _ c: Vertex) {
            let e1 = b.position - a.position, e2 = c.position - a.position
            let areaVector = headCross(e1, e2)
            guard headDot(areaVector, areaVector) > 1e-24 else { return nil }
            var box = Bounds()
            box.include(a.position); box.include(b.position); box.include(c.position)
            self.a = a; self.b = b; self.c = c
            self.edge1 = e1; self.edge2 = e2
            self.bounds = box
            self.centroid = (a.position + b.position + c.position) / 3
        }

        /// Two-sided segment intersection. Interpolated outward normals are
        /// independent of triangle winding and continuous across shared edges.
        func intersection(origin: SIMD3<Double>, direction: SIMD3<Double>,
                          minimum: Double, maximum: Double) -> (Double, Double, Double)? {
            let p = headCross(direction, edge2)
            let determinant = headDot(edge1, p)
            guard abs(determinant) > 1e-14 else { return nil }
            let inverse = 1 / determinant, offset = origin - a.position
            let u = headDot(offset, p) * inverse
            let tolerance = 1e-10
            guard u >= -tolerance, u <= 1 + tolerance else { return nil }
            let q = headCross(offset, edge1)
            let v = headDot(direction, q) * inverse
            guard v >= -tolerance, u + v <= 1 + tolerance else { return nil }
            let t = headDot(edge2, q) * inverse
            guard t >= minimum, t < maximum else { return nil }
            return (t, u, v)
        }

        func hit(origin: SIMD3<Double>, direction: SIMD3<Double>,
                 minimum: Double, maximum: Double) -> Hit? {
            guard let (t, u, v) = intersection(origin: origin, direction: direction,
                                               minimum: minimum, maximum: maximum),
                  let normal = headUnit(a.normal * (1 - u - v) + b.normal * u + c.normal * v)
            else { return nil }
            guard let faceNormal = headUnit(headCross(edge1, edge2)) else { return nil }
            // A smooth interpolated normal can face away from a grazing camera ray
            // although the intersected triangle is front-facing. In that case use
            // the actual outward geometric normal, not a flipped shading normal.
            let safeNormal = headDot(normal, -direction) > 0 && headDot(normal, faceNormal) > 0
                ? normal : faceNormal
            return .init(distance: t, normal: safeNormal, geometricNormal: faceNormal)
        }
    }

    private struct Node: Sendable {
        let bounds: Bounds
        var first: Int
        var count: Int
        var left = -1
        var right = -1
    }

    private let triangles: [Triangle]
    private let nodes: [Node]

    /// One immutable mesh/BVH shared by every study frame. The latitude
    /// mapping clusters samples near the poles to retain the silhouette.
    static let standard = PortraitHeadMesh()

    static func ringY(_ index: Int) -> Double {
        let t = Double(index) / Double(latitudeSegments)
        return lowerY + (upperY - lowerY) * (1 - cos(.pi * t)) / 2
    }

    private static func profileValue(_ y: Double, key: KeyPath<Profile, Double>) -> Double {
        if y <= lowerY { return profile[0][keyPath: key] }
        if y >= upperY { return profile[profile.count - 1][keyPath: key] }
        let i = profile.indices.dropLast().first { y <= profile[$0 + 1].y }!
        func secant(_ j: Int) -> Double {
            (profile[j + 1][keyPath: key] - profile[j][keyPath: key]) /
                (profile[j + 1].y - profile[j].y)
        }
        func slope(_ j: Int) -> Double {
            if j == 0 { return secant(0) }
            if j == profile.count - 1 { return secant(j - 1) }
            let a = secant(j - 1), b = secant(j)
            // Shape-preserving Hermite interpolation: no overshoot across
            // monotone intervals, zero slope at local extrema.
            return a * b > 0 ? 2 * a * b / (a + b) : 0
        }
        let h = profile[i + 1].y - profile[i].y
        let t = (y - profile[i].y) / h, t2 = t * t, t3 = t2 * t
        let a = profile[i][keyPath: key], b = profile[i + 1][keyPath: key]
        return (2 * t3 - 3 * t2 + 1) * a + (t3 - 2 * t2 + t) * h * slope(i) +
            (-2 * t3 + 3 * t2) * b + (t3 - t2) * h * slope(i + 1)
    }

    /// One continuous shell with an integrated jaw, nose, brow and shallow
    /// eye/mouth relief, rather than visible overlapping facial primitives.
    static func surfacePoint(y: Double, angle: Double) -> SIMD3<Double> {
        let clampedY = min(upperY, max(lowerY, y))
        if clampedY == lowerY { return .init(0, lowerY, profile[0].front) }
        if clampedY == upperY { return .init(0, upperY, profile[profile.count - 1].front) }
        let width = max(0, profileValue(clampedY, key: \.width))
        let front = profileValue(clampedY, key: \.front)
        let back = profileValue(clampedY, key: \.back)
        let cosine = cos(angle), x = width * sin(angle)
        var z = (front + back) / 2 + (front - back) * cosine / 2
        if cosine > 0 {
            func bump(_ centerX: Double, _ centerY: Double, _ sx: Double, _ sy: Double) -> Double {
                let dx = (x - centerX) / sx, dy = (clampedY - centerY) / sy
                return exp(-0.5 * (dx * dx + dy * dy))
            }
            var relief = 0.020 * bump(0, 0.004, 0.012, 0.033)
            relief += 0.037 * bump(0, -0.032, 0.014, 0.016)
            relief += 0.005 * bump(0, -0.048, 0.021, 0.010)
            for sign in [-1.0, 1.0] {
                relief -= 0.014 * bump(sign * 0.037, 0.023, 0.018, 0.013)
                relief += 0.007 * bump(sign * 0.039, 0.044, 0.022, 0.010)
                relief += 0.008 * bump(sign * 0.047, -0.026, 0.022, 0.020)
            }
            relief += 0.005 * bump(0, -0.071, 0.030, 0.006)
            relief -= 0.004 * bump(0, -0.079, 0.029, 0.0035)
            relief += 0.004 * bump(0, -0.087, 0.026, 0.006)
            z += relief * cosine * cosine * min(1, width / 0.05)
        }
        return .init(x, clampedY, z)
    }

    private static func vertex(y: Double, angle: Double) -> Vertex {
        let p = surfacePoint(y: y, angle: angle)
        if y <= lowerY { return .init(position: p, normal: .init(0, -1, 0)) }
        if y >= upperY { return .init(position: p, normal: .init(0, 1, 0)) }
        let tangent = surfacePoint(y: y, angle: angle + 1e-4) -
            surfacePoint(y: y, angle: angle - 1e-4)
        let vertical = surfacePoint(y: y + 1e-5, angle: angle) -
            surfacePoint(y: y - 1e-5, angle: angle)
        let normal = headUnit(headCross(tangent, vertical)) ?? .init(0, 0, 1)
        return .init(position: p, normal: normal)
    }

    private init() {
        let columns = Self.longitudeSegments
        let rows = Self.latitudeSegments
        var vertices: [Vertex] = []
        vertices.reserveCapacity((rows + 1) * columns)
        for row in 0...rows {
            for column in 0..<columns {
                let angle = 2 * Double.pi * Double(column) / Double(columns)
                vertices.append(Self.vertex(y: Self.ringY(row), angle: angle))
            }
        }
        var mesh: [Triangle] = []
        mesh.reserveCapacity(2 * rows * columns)
        for row in 0..<rows {
            for column in 0..<columns {
                let next = (column + 1) % columns
                let a = vertices[row * columns + column], b = vertices[row * columns + next]
                let c = vertices[(row + 1) * columns + column], d = vertices[(row + 1) * columns + next]
                if let triangle = Triangle(a, b, c) { mesh.append(triangle) }
                if let triangle = Triangle(b, d, c) { mesh.append(triangle) }
            }
        }
        var hierarchy: [Node] = []
        func build(_ first: Int, _ end: Int) -> Int {
            var box = Bounds(), centers = Bounds()
            for i in first..<end { box.include(mesh[i].bounds); centers.include(mesh[i].centroid) }
            let index = hierarchy.count
            hierarchy.append(.init(bounds: box, first: first, count: end - first))
            if end - first > 8 {
                let extent = centers.high - centers.low
                let axis = extent.x >= extent.y && extent.x >= extent.z ? 0 : extent.y >= extent.z ? 1 : 2
                let sorted = mesh[first..<end].sorted { $0.centroid[axis] < $1.centroid[axis] }
                mesh.replaceSubrange(first..<end, with: sorted)
                let middle = (first + end) / 2
                let left = build(first, middle), right = build(middle, end)
                hierarchy[index].left = left
                hierarchy[index].right = right
                hierarchy[index].count = 0
            }
            return index
        }
        _ = build(0, mesh.count)
        self.triangles = mesh
        self.nodes = hierarchy
    }

    var triangleCount: Int { triangles.count }

    /// Conservative head exclusion for a camera originating inside the bust.
    /// The renderer also requires a minimum subject distance of 17 cm.
    func containsExclusionBounds(_ point: SIMD3<Double>) -> Bool {
        nodes[0].bounds.contains(point)
    }

    func hit(origin: SIMD3<Double>, direction: SIMD3<Double>,
             minimum: Double, maximum: Double) -> Hit? {
        var closest: Hit?
        // Incident faces can report the same vertex/edge a few ulps apart.
        // Keep the true minimum distance, but allow a front-facing outward
        // face to supply its normal at that tie. Otherwise an exterior
        // silhouette can select a back face and become an invalid pixel.
        // The 1 pm floor is far below mesh dimensions; the ulp term keeps
        // this a numerical tie at larger camera distances.
        func tieTolerance(_ distance: Double) -> Double {
            max(1e-12, 8 * distance.ulp)
        }
        func searchLimit() -> Double {
            guard let closest else { return maximum }
            return min(maximum, closest.distance + tieTolerance(closest.distance))
        }
        func visit(_ index: Int) {
            let node = nodes[index]
            guard node.bounds.intersects(origin: origin, direction: direction,
                                          minimum: minimum, maximum: searchLimit()) else { return }
            if node.count > 0 {
                for i in node.first..<(node.first + node.count) {
                    if let hit = triangles[i].hit(origin: origin, direction: direction,
                                                   minimum: minimum, maximum: searchLimit()) {
                        guard let previous = closest else { closest = hit; continue }
                        var surface = hit.distance < previous.distance ? hit : previous
                        if abs(hit.distance - previous.distance) <= tieTolerance(previous.distance) {
                            let previousFacesRay = headDot(previous.geometricNormal, -direction) > 0
                            let hitFacesRay = headDot(hit.geometricNormal, -direction) > 0
                            if previousFacesRay != hitFacesRay {
                                surface = previousFacesRay ? previous : hit
                            }
                        }
                        closest = .init(distance: min(previous.distance, hit.distance),
                                        normal: surface.normal, geometricNormal: surface.geometricNormal)
                    }
                }
            } else {
                visit(node.left); visit(node.right)
            }
        }
        visit(0)
        return closest
    }

    func occludes(origin: SIMD3<Double>, direction: SIMD3<Double>,
                  minimum: Double, maximum: Double) -> Bool {
        func visit(_ index: Int) -> Bool {
            let node = nodes[index]
            guard node.bounds.intersects(origin: origin, direction: direction,
                                          minimum: minimum, maximum: maximum) else { return false }
            if node.count > 0 {
                return (node.first..<(node.first + node.count)).contains { i in
                    triangles[i].intersection(origin: origin, direction: direction,
                                              minimum: minimum, maximum: maximum) != nil
                }
            }
            return visit(node.left) || visit(node.right)
        }
        return visit(0)
    }
}

private func headDot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x * b.x + a.y * b.y + a.z * b.z }
private func headCross(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> SIMD3<Double> {
    .init(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
}
private func headUnit(_ v: SIMD3<Double>) -> SIMD3<Double>? {
    let length = sqrt(headDot(v, v))
    guard length.isFinite, length > 0 else { return nil }
    return v / length
}
