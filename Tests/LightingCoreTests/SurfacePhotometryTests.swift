import Foundation
import XCTest
@testable import LightingCore

final class SurfacePhotometryTests: XCTestCase {
    private let origin = Position(x: 0, y: 0, z: 0)
    private func direction(_ x: Double, _ y: Double, _ z: Double) throws -> UnitDirection {
        try XCTUnwrap(UnitDirection(x: x, y: y, z: z))
    }

    private func emitter(width: Double = 1, height: Double = 0.6, intensity: Double = 1000) throws -> LambertianRectangle {
        try XCTUnwrap(LambertianRectangle(center: origin, right: direction(1, 0, 0), up: direction(0, 1, 0),
                                         widthMeters: width, heightMeters: height, onAxisCandela: intensity))
    }

    func testDirectionNormalizesAndRejectsInvalid() throws {
        let n = try direction(3, 4, 0)
        XCTAssertEqual(n.x, 0.6, accuracy: 1e-12)
        XCTAssertEqual(n.y, 0.8, accuracy: 1e-12)
        XCTAssertNotNil(UnitDirection(x: .greatestFiniteMagnitude, y: .greatestFiniteMagnitude, z: 0))
        XCTAssertNil(UnitDirection(x: 0, y: 0, z: 0))
        XCTAssertNil(UnitDirection(x: .nan, y: 1, z: 0))
        XCTAssertNil(UnitDirection(x: .infinity, y: 1, z: 0))
    }

    func testPointCosineAndInverseSquare() throws {
        let light = Position(x: 0, y: 0, z: 2)
        for degrees in [0.0, 30, 60, 90, 120, 180] {
            let radians = degrees * .pi / 180
            let n = try direction(sin(radians), 0, cos(radians))
            let result = try XCTUnwrap(Photometry.pointIlluminance(candela: 400, source: light, receiver: origin, receiverNormal: n))
            XCTAssertEqual(result, 100 * max(0, cos(radians)), accuracy: 1e-9)
        }
        let normal = try direction(0, 0, 1)
        let close = try XCTUnwrap(Photometry.pointIlluminance(candela: 400, source: .init(x: 0, y: 0, z: 1), receiver: origin, receiverNormal: normal))
        XCTAssertEqual(close, 400, accuracy: 1e-9)
        XCTAssertNil(Photometry.pointIlluminance(candela: 400, source: origin, receiver: origin, receiverNormal: normal))
        XCTAssertNil(Photometry.pointIlluminance(candela: -.infinity, source: light, receiver: origin, receiverNormal: normal))
    }

    // Closed-form projected solid angle of a centered parallel rectangle.
    // Integrate d^2/(d^2+x^2+y^2)^2 using its planar divergence antiderivative.
    private func analytic(width: Double, height: Double, distance: Double, intensity: Double) -> Double {
        let a = width / 2, b = height / 2
        let da = (distance * distance + a * a).squareRoot()
        let db = (distance * distance + b * b).squareRoot()
        return 2 * intensity / (width * height) * (a / da * atan(b / da) + b / db * atan(a / db))
    }

    func testRectangleMatchesAnalyticParallelFixtures() throws {
        let n = try direction(0, 0, -1)
        for (w, h, d) in [(1.0, 1.0, 0.25), (1, 0.6, 0.5), (1, 0.6, 1.0), (0.3, 1.5, 0.4), (2, 0.5, 1), (0.05, 0.05, 2)] {
            let actual = try XCTUnwrap(Photometry.rectangularIlluminance(emitter: emitter(width: w, height: h), receiver: .init(x: 0, y: 0, z: d), receiverNormal: n))
            let expected = analytic(width: w, height: h, distance: d, intensity: 1000)
            let relativeError = abs(actual - expected) / expected
            print("Parallel fixture \(w)x\(h) @ \(d)m relative error: \(relativeError)")
            XCTAssertLessThan(relativeError, 0.01)
        }
    }

    // Independent composite Simpson quadrature for an offset, tilted receiver
    // with the source in the XY plane. The test does not reuse production math.
    private func simpsonReference(x: Double, y: Double, z: Double, nx: Double, ny: Double, nz: Double) -> Double {
        let n = 160, width = 1.0, height = 0.6
        let dx = width / Double(n), dy = height / Double(n)
        func weight(_ i: Int) -> Double { i == 0 || i == n ? 1 : (i % 2 == 0 ? 2 : 4) }
        var sum = 0.0
        for j in 0...n {
            let sy = -height / 2 + Double(j) * dy
            for i in 0...n {
                let sx = -width / 2 + Double(i) * dx
                let a = sx - x, b = sy - y
                let r2 = a * a + b * b + z * z
                let projection = max(0, a * nx + b * ny - z * nz)
                sum += weight(i) * weight(j) * z * projection / (r2 * r2)
            }
        }
        return sum * dx * dy / 9 * 1000 / (width * height)
    }

    func testRectangleMatchesIndependentOffAxisNumericalReference() throws {
        let e = try emitter()
        for (x, y, z, angle) in [(0.4, 0.2, 0.5, 0.2), (-0.3, 0.1, 0.25, -0.7), (1.2, -0.4, 1.5, 0.8), (0.0, 0.1, 0.5, 1.5)] {
            let nx = sin(angle), nz = -cos(angle)
            let normal = try direction(nx, 0, nz)
            let actual = try XCTUnwrap(Photometry.rectangularIlluminance(emitter: e, receiver: .init(x: x, y: y, z: z), receiverNormal: normal))
            let expected = simpsonReference(x: x, y: y, z: z, nx: nx, ny: 0, nz: nz)
            let relativeError = abs(actual - expected) / expected
            print("Offset fixture (\(x),\(y),\(z)) angle \(angle) relative error: \(relativeError)")
            XCTAssertLessThan(relativeError, 0.05)
        }
    }

    func testRectangleBackfaceNearPlaneAndInvalidGeometry() throws {
        let e = try emitter(), toward = try direction(0, 0, -1), away = try direction(0, 0, 1)
        XCTAssertEqual(Photometry.rectangularIlluminance(emitter: e, receiver: .init(x: 0, y: 0, z: -1), receiverNormal: away), 0)
        XCTAssertEqual(Photometry.rectangularIlluminance(emitter: e, receiver: .init(x: 0, y: 0, z: 1), receiverNormal: away), 0)
        XCTAssertNil(Photometry.rectangularIlluminance(emitter: e, receiver: .init(x: 0, y: 0, z: 0.24), receiverNormal: toward))
        XCTAssertNil(Photometry.rectangularIlluminance(emitter: e, receiver: .init(x: .nan, y: 0, z: 1), receiverNormal: toward))
        let right = try direction(1, 0, 0), up = try direction(0, 1, 0)
        XCTAssertNil(LambertianRectangle(center: origin, right: right, up: right, widthMeters: 1, heightMeters: 1, onAxisCandela: 100))
        XCTAssertNil(LambertianRectangle(center: origin, right: right, up: up, widthMeters: -1, heightMeters: 1, onAxisCandela: 100))
    }

    func testFarFieldAndIntensityScaling() throws {
        let normal = try direction(0, 0, -1)
        let receiver = Position(x: 0, y: 0, z: 20)
        let a = try XCTUnwrap(Photometry.rectangularIlluminance(emitter: emitter(), receiver: receiver, receiverNormal: normal))
        let b = try XCTUnwrap(Photometry.rectangularIlluminance(emitter: emitter(intensity: 2000), receiver: receiver, receiverNormal: normal))
        XCTAssertEqual(a, 2.5, accuracy: 0.005)
        XCTAssertEqual(b, 2 * a, accuracy: 1e-9)
    }
}
