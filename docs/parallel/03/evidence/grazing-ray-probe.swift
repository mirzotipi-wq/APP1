import Foundation

// Independent ray/plane and projected-area witness. Shares prescribed vertices,
// not the BVH or production Moller-Trumbore intersection implementation.
@main enum GrazingRayProbe {
    static func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        a.x * b.x + a.y * b.y + a.z * b.z
    }
    static func cross(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> SIMD3<Double> {
        .init(a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x)
    }
    static func area(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ c: SIMD3<Double>,
                     _ i: Int, _ j: Int) -> Double {
        (b[i]-a[i])*(c[j]-a[j])-(b[j]-a[j])*(c[i]-a[i])
    }
    static func main() throws {
        let origin = SIMD3<Double>(3.404646637409472e-5, -0.1327573713979657, 0.026792162348130817)
        let direction = SIMD3<Double>(0.08733597770659, 0.2924411459428683, 0.9522870382178139)
        let minimum = 1e-6, maximum = 1e-4
        let angle = 2 * Double.pi / Double(PortraitHeadMesh.longitudeSegments)
        let a = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(0), angle: angle)
        let b = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(1), angle: angle)
        let c = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(1), angle: 0)
        let rawNormal = cross(b-a, c-a)
        let magnitude = sqrt(dot(rawNormal, rawNormal)), normal = rawNormal / magnitude
        let distance = dot(normal, a-origin) / dot(normal, direction)
        let point = origin + direction * distance
        let axes = (0..<3).filter { $0 != (0..<3).max(by: { abs(normal[$0]) < abs(normal[$1]) })! }
        let denominator = area(a,b,c,axes[0],axes[1])
        let weights = [area(point,b,c,axes[0],axes[1]),area(a,point,c,axes[0],axes[1]),
                       area(a,b,point,axes[0],axes[1])].map { $0 / denominator }
        let expected = distance >= minimum && distance < maximum && weights.allSatisfy { $0 > 0 }
        let mesh = PortraitHeadMesh.standard
        let actual = mesh.hit(origin: origin, direction: direction, minimum: minimum, maximum: maximum)
        let occluded = mesh.occludes(origin: origin, direction: direction, minimum: minimum, maximum: maximum)
        let result: [String: Any] = ["oracleHit": expected, "oracleDistanceMeters": distance,
            "oracleBarycentricWeights": weights, "triangleTwiceAreaSquareMeters": magnitude,
            "incidenceCosine": dot(normal,direction), "bvhHit": actual != nil,
            "bvhDistanceMeters": actual.map { $0.distance as Any } ?? NSNull(), "occludes": occluded,
            "matches": expected == (actual != nil) && expected == occluded]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted,.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
