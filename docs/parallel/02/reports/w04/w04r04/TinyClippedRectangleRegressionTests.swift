import Foundation
import XCTest
import LightingCore

final class TinyClippedRectangleRegressionTests: XCTestCase {
    func testTinyClippedFaceRetainsRepresentableIlluminance() throws {
        let intensity = 8 * Double.leastNonzeroMagnitude
        let emitter = try XCTUnwrap(LambertianRectangle(
            center: .init(x: 0, y: 0, z: 0),
            right: XCTUnwrap(UnitDirection(x: 1, y: 0, z: 0)),
            up: XCTUnwrap(UnitDirection(x: 0, y: 1, z: 0)),
            widthMeters: 4, heightMeters: 4, onAxisCandela: intensity))
        let actual = try XCTUnwrap(Photometry.rectangularIlluminance(
            emitter: emitter, receiver: .init(x: 0, y: 0, z: 1),
            receiverNormal: XCTUnwrap(UnitDirection(x: 1, y: 0, z: -1))))

        // Independent scalar antiderivative: the receiver hemisphere clips
        // this face to -1 < x <= 2, -2 <= y <= 2 (75% of its area).
        // E/I = integral[d * (x+d) / (d*d+x*x+y*y)^2] / (16*sqrt(2)).
        // Integrate the x term directly; the d term uses the planar divergence
        // of (x,y)/(d*d+x*x+y*y), which equals 2*d*d/r^4.
        let d = 1.0, a = 2.0, b = 2.0, x0 = -1.0
        func edge(_ x: Double) -> Double {
            let h = sqrt(d * d + x * x)
            return atan(b / h) / h
        }
        let h = sqrt(d * d + b * b)
        let xIntegral = d * (edge(x0) - edge(a))
        let zIntegral = a * edge(a) - x0 * edge(x0)
            + b / h * (atan(a / h) - atan(x0 / h))
        let coefficient = (xIntegral + zIntegral) / (16 * sqrt(2.0))
        let expected = coefficient * intensity

        // Applying intensity/area first rounds to zero. The final physical
        // result remains representable when intensity is applied once at end.
        XCTAssertEqual(expected, Double.leastNonzeroMagnitude)
        XCTAssertGreaterThan(actual, 0)
        // Form the ratio before subtraction; an absolute tolerance underflows.
        XCTAssertLessThanOrEqual(abs(actual / expected - 1), 0.05)
    }
}
