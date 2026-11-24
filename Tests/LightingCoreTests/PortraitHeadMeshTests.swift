import Foundation
import XCTest
@testable import LightingCore

/// The oracle shares only the prescribed mesh vertices/topology. It performs
/// an unaccelerated ray/plane intersection followed by a projected 2D area
/// test, independently of production triangle intersection and BVH bounds.
final class PortraitHeadMeshTests: XCTestCase {
    private struct Ray: Sendable {
        let name: String
        let origin: SIMD3<Double>
        let direction: SIMD3<Double>

        init(_ name: String, origin: SIMD3<Double>, target: SIMD3<Double>) {
            self.name = name
            self.origin = origin
            let delta = target - origin
            self.direction = delta / sqrt(Self.dot(delta, delta))
        }

        private static func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
            a.x * b.x + a.y * b.y + a.z * b.z
        }
    }

    private struct OracleTriangle: Sendable {
        let a: SIMD3<Double>
        let b: SIMD3<Double>
        let c: SIMD3<Double>
        let normal: SIMD3<Double>
        let firstAxis: Int
        let secondAxis: Int
        let signedArea: Double

        init?(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ c: SIMD3<Double>) {
            let rawNormal = cross(b - a, c - a)
            let magnitude = sqrt(dot(rawNormal, rawNormal))
            guard magnitude > 0 else { return nil } // Coincident pole vertices.
            self.a = a; self.b = b; self.c = c
            normal = rawNormal / magnitude
            let largest = abs(rawNormal.x) >= abs(rawNormal.y) && abs(rawNormal.x) >= abs(rawNormal.z)
                ? 0 : abs(rawNormal.y) >= abs(rawNormal.z) ? 1 : 2
            firstAxis = (largest + 1) % 3
            secondAxis = (largest + 2) % 3
            signedArea = Self.area(a, b, c, firstAxis, secondAxis)
        }

        func distance(_ ray: Ray, minimum: Double, maximum: Double) -> Double? {
            let denominator = dot(normal, ray.direction)
            guard abs(denominator) > 1e-14 else { return nil }
            let distance = dot(normal, a - ray.origin) / denominator
            guard distance >= minimum, distance < maximum else { return nil }
            let point = ray.origin + ray.direction * distance
            let wa = Self.area(point, b, c, firstAxis, secondAxis) / signedArea
            let wb = Self.area(a, point, c, firstAxis, secondAxis) / signedArea
            let wc = Self.area(a, b, point, firstAxis, secondAxis) / signedArea
            // Dimensionless edge tolerance accommodates exact shared vertices;
            // nearest distance is compared separately to an absolute 1e-8 m.
            guard wa >= -1e-10, wb >= -1e-10, wc >= -1e-10 else { return nil }
            return distance
        }

        private static func area(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ c: SIMD3<Double>,
                                 _ x: Int, _ y: Int) -> Double {
            (b[x] - a[x]) * (c[y] - a[y]) - (b[y] - a[y]) * (c[x] - a[x])
        }
    }

    private struct OracleHit {
        let distance: Double
        let outwardNormal: SIMD3<Double>
    }

    private static let triangles: [OracleTriangle] = {
        let rows = PortraitHeadMesh.latitudeSegments
        let columns = PortraitHeadMesh.longitudeSegments
        func vertex(_ row: Int, _ column: Int) -> SIMD3<Double> {
            PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(row),
                angle: 2 * Double.pi * Double(column % columns) / Double(columns))
        }
        var result: [OracleTriangle] = []
        for row in 0..<rows {
            for column in 0..<columns {
                let a = vertex(row, column), b = vertex(row, column + 1)
                let c = vertex(row + 1, column), d = vertex(row + 1, column + 1)
                if let face = OracleTriangle(a, b, c) { result.append(face) }
                if let face = OracleTriangle(b, d, c) { result.append(face) }
            }
        }
        return result
    }()

    func testBVHMatchesIndependentOracleAcrossExteriorViewsAndMisses() {
        XCTAssertEqual(Self.triangles.count, PortraitHeadMesh.standard.triangleCount)
        let angles = [0.0, Double.pi / 2, Double.pi, 3 * Double.pi / 2, Double.pi / 4, -Double.pi / 3]
        var hits = 0, misses = 0, count = 0
        for (view, angle) in angles.enumerated() {
            let origin = SIMD3<Double>(0.6 * sin(angle), 0.02, 0.6 * cos(angle))
            let right = SIMD3<Double>(cos(angle), 0, -sin(angle))
            for y in [-0.16, -0.11, -0.055, 0, 0.055, 0.11, 0.16] {
                for x in [-0.12, -0.06, 0, 0.06, 0.12] {
                    let target = right * x + SIMD3<Double>(0, y, 0)
                    let ray = Ray("view\(view) x\(x) y\(y)", origin: origin, target: target)
                    if compare(ray, facesCamera: true) { hits += 1 } else { misses += 1 }
                    count += 1
                }
            }
        }
        XCTAssertEqual(count, 210)
        XCTAssertGreaterThan(hits, 60)
        XCTAssertGreaterThan(misses, 40)
        print("BVH independent oracle: \(count) exterior rays, \(hits) hits and \(misses) misses")
    }

    func testSeamPolesSharedEdgesAndNearGrazingRaysMatchOracle() {
        var rays: [Ray] = []
        for row in [1, 7, 19, 27, 35, 41] {
            for column in [0, 1, 16, 32, 63] {
                let point = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(row),
                    angle: 2 * Double.pi * Double(column) / Double(PortraitHeadMesh.longitudeSegments))
                let radial = unit(point - SIMD3<Double>(0, 0, -0.005))
                rays.append(Ray("ring\(row) column\(column)", origin: point + radial * 0.5, target: point))
            }
        }
        for row in [0, PortraitHeadMesh.latitudeSegments] {
            let point = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(row), angle: 0)
            let side = row == 0 ? -1.0 : 1.0
            rays.append(Ray("pole\(row)", origin: point + SIMD3<Double>(0, side * 0.5, 0), target: point))
        }
        for index in stride(from: 31, to: Self.triangles.count, by: 431) {
            let triangle = Self.triangles[index]
            let edge = (triangle.a + triangle.b) / 2
            rays.append(Ray("edge\(index)", origin: edge + triangle.normal * 0.5, target: edge))
        }
        for row in [10, 20, 30] {
            for sign in [-1.0, 1.0] {
                let point = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(row), angle: sign * .pi / 2)
                for offset in [-1e-6, 0, 1e-6] {
                    let origin = SIMD3<Double>(point.x + offset, point.y, 0.6)
                    rays.append(Ray("grazing\(row) sign\(sign) offset\(offset)", origin: origin,
                                    target: origin + SIMD3<Double>(0, 0, -1)))
                }
            }
        }
        XCTAssertEqual(rays.count, 63)
        for ray in rays { _ = compare(ray, facesCamera: true) }
        print("BVH independent oracle: \(rays.count) seam, pole, shared-edge and grazing rays")
    }

    func testInteriorOriginsReturnNearestExitWithOutwardUnitNormals() {
        let directions: [SIMD3<Double>] = [.init(1, 0, 0), .init(-1, 0, 0), .init(0, 1, 0),
                                          .init(0, -1, 0), .init(0, 0, 1), .init(0, 0, -1)]
        var count = 0
        for origin: SIMD3<Double> in [.init(0, 0, 0), .init(0, 0.04, -0.02)] {
            for direction in directions {
                let ray = Ray("inside\(origin) direction\(direction)", origin: origin, target: origin + direction)
                XCTAssertTrue(compare(ray, facesCamera: false))
                count += 1
            }
        }
        XCTAssertEqual(count, 12)
    }

    func testFiniteSegmentsStopAtTheLightAndUseHalfOpenIntervals() throws {
        let mesh = PortraitHeadMesh.standard
        var count = 0
        for angle in [0.0, Double.pi / 4, Double.pi / 2, Double.pi, -Double.pi / 3] {
            for y in [-0.08, 0, 0.08] {
                let ray = Ray("segment\(angle) y\(y)",
                              origin: .init(0.6 * sin(angle), y, 0.6 * cos(angle)), target: .init(0, y, 0))
                let expected = try XCTUnwrap(oracle(ray, minimum: 1e-6, maximum: .infinity))
                XCTAssertFalse(compare(ray, minimum: 1e-6, maximum: expected.distance - 1e-7, facesCamera: true))
                XCTAssertTrue(compare(ray, minimum: 1e-6, maximum: expected.distance + 1e-7, facesCamera: true))
                XCTAssertFalse(compare(ray, minimum: expected.distance + 1e-7,
                                       maximum: expected.distance + 2e-7, facesCamera: true))
                let hit = try XCTUnwrap(mesh.hit(origin: ray.origin, direction: ray.direction,
                                                minimum: 1e-6, maximum: .infinity))
                // Use the production-returned value only for exact floating-
                // point boundary semantics; independent distances above bracket
                // the true first surface without sharing intersection math.
                XCTAssertFalse(mesh.occludes(origin: ray.origin, direction: ray.direction,
                                              minimum: 1e-6, maximum: hit.distance), ray.name)
                XCTAssertNotNil(mesh.hit(origin: ray.origin, direction: ray.direction,
                                         minimum: hit.distance, maximum: hit.distance.nextUp), ray.name)
                for interval in [(1.0, 1.0), (1.0, 0.5)] {
                    XCTAssertFalse(compare(ray, minimum: interval.0, maximum: interval.1, facesCamera: true))
                }
                count += 1
            }
        }
        XCTAssertEqual(count, 15)
    }

    func testExactSilhouetteVertexRendersWithoutUnsupportedPixels() throws {
        let point = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(10), angle: -.pi / 2)
        let width = 24, height = 16
        let x = 8, y = 13
        // Solve the camera distance and focal length so this exact side
        // vertex projects onto pixel (8, 13), with the pixel ray along -Z.
        let sensorX = Double(2 * x + 1 - width)
        let sensorY = Double(height - 2 * y - 1)
        let ratio = sensorX * point.y / (sensorY * point.x)
        let cameraZ = sqrt((point.x * point.x + point.y * point.y) / (ratio * ratio - 1))
        let focalLength = sensorY * 12 * hypot(point.x, cameraZ) / (Double(height) * point.y)
        var scene = LightingScene.portrait()
        scene.subject = .init(x: 0, y: 0, z: 0)
        scene.camera = .init(x: point.x, y: point.y, z: cameraZ)
        scene.cameraLens = .init(focalLengthMillimeters: focalLength)
        scene.lights = []
        let camera = try XCTUnwrap(CameraFraming(scene: scene))
        let projection = try XCTUnwrap(camera.project(.init(x: point.x, y: point.y, z: point.z)))
        XCTAssertEqual(projection.x, sensorX / Double(width), accuracy: 1e-12)
        XCTAssertEqual(projection.y, sensorY / Double(height), accuracy: 1e-12)
        let image = try PortraitStudyRenderer.render(scene: scene, width: width)
        XCTAssertEqual(image.unsupportedPixels, 0)
        let index = 4 * (y * width + x)
        XCTAssertEqual(Array(image.rgba[index..<index + 4]), [0, 0, 0, 255])
    }

    func testCoincidentSilhouetteFacesKeepExactSegmentEndpoints() throws {
        let mesh = PortraitHeadMesh.standard
        for (row, side) in [(10, -1.0), (20, 1.0)] {
            let point = PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(row), angle: side * .pi / 2)
            let origin = SIMD3<Double>(point.x, point.y, 0.6)
            let direction = SIMD3<Double>(0, 0, -1)
            let hit = try XCTUnwrap(mesh.hit(origin: origin, direction: direction,
                                            minimum: 1e-6, maximum: .infinity))
            XCTAssertGreaterThan(dot(hit.normal, -direction), 0)
            // Choosing a face normal at a numerical tie must never advance
            // the reported minimum distance or admit the excluded endpoint.
            XCTAssertNil(mesh.hit(origin: origin, direction: direction, minimum: 1e-6, maximum: hit.distance))
            XCTAssertFalse(mesh.occludes(origin: origin, direction: direction,
                                          minimum: 1e-6, maximum: hit.distance))
            let narrow = try XCTUnwrap(mesh.hit(origin: origin, direction: direction,
                                               minimum: hit.distance, maximum: hit.distance.nextUp))
            XCTAssertEqual(narrow.distance, hit.distance)
            XCTAssertTrue(mesh.occludes(origin: origin, direction: direction,
                                         minimum: hit.distance, maximum: hit.distance.nextUp))
        }
    }

    @discardableResult
    private func compare(_ ray: Ray, minimum: Double = 1e-6, maximum: Double = .infinity,
                         facesCamera: Bool, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        for vector in [ray.origin, ray.direction] {
            XCTAssertTrue(vector.x.isFinite && vector.y.isFinite && vector.z.isFinite,
                          ray.name, file: file, line: line)
        }
        XCTAssertEqual(sqrt(dot(ray.direction, ray.direction)), 1, accuracy: 1e-12,
                       ray.name, file: file, line: line)
        let expected = oracle(ray, minimum: minimum, maximum: maximum)
        let mesh = PortraitHeadMesh.standard
        let actual = mesh.hit(origin: ray.origin, direction: ray.direction, minimum: minimum, maximum: maximum)
        XCTAssertEqual(actual != nil, expected != nil, ray.name, file: file, line: line)
        XCTAssertEqual(mesh.occludes(origin: ray.origin, direction: ray.direction, minimum: minimum, maximum: maximum),
                       expected != nil, ray.name, file: file, line: line)
        guard let actual, let expected else { return false }
        XCTAssertEqual(actual.distance, expected.distance, accuracy: 1e-8, ray.name, file: file, line: line)
        for normal in [actual.normal, actual.geometricNormal] {
            XCTAssertTrue(normal.x.isFinite && normal.y.isFinite && normal.z.isFinite, ray.name, file: file, line: line)
            XCTAssertEqual(sqrt(dot(normal, normal)), 1, accuracy: 1e-10, ray.name, file: file, line: line)
        }
        // Shared-edge ties may choose either adjacent outward face. Do not
        // require identical face normals or the same triangle-array ordering.
        XCTAssertGreaterThan(dot(actual.geometricNormal, expected.outwardNormal), 0, ray.name, file: file, line: line)
        XCTAssertGreaterThan(dot(actual.normal, actual.geometricNormal), 0, ray.name, file: file, line: line)
        if facesCamera {
            XCTAssertGreaterThanOrEqual(dot(actual.normal, -ray.direction), -1e-10, ray.name, file: file, line: line)
        } else {
            XCTAssertGreaterThan(dot(actual.normal, ray.direction), 0, ray.name, file: file, line: line)
        }
        return true
    }

    private func oracle(_ ray: Ray, minimum: Double, maximum: Double) -> OracleHit? {
        guard minimum < maximum else { return nil }
        var closest: OracleHit?
        for triangle in Self.triangles {
            if let distance = triangle.distance(ray, minimum: minimum, maximum: closest?.distance ?? maximum) {
                closest = .init(distance: distance, outwardNormal: triangle.normal)
            }
        }
        return closest
    }
}

private func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
    a.x * b.x + a.y * b.y + a.z * b.z
}

private func cross(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> SIMD3<Double> {
    .init(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
}

private func unit(_ value: SIMD3<Double>) -> SIMD3<Double> {
    value / sqrt(dot(value, value))
}
