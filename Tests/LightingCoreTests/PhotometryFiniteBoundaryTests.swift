import Foundation
import XCTest
@testable import LightingCore

final class PhotometryFiniteBoundaryTests: XCTestCase {
    func testRollPreservesExactPlaneSeparationWithoutWideningSupportedDomain() throws {
        for size in [0.05, 0.6, 4.0] {
            let depth = max(0.05, size / 4)
            for degrees in [0.0, 1, 37, 90, 179] {
                let angle = degrees * .pi / 180
                let emitter = try XCTUnwrap(LambertianRectangle(
                    center: .init(x: 0, y: 0, z: 0),
                    right: XCTUnwrap(UnitDirection(x: cos(angle), y: sin(angle), z: 0)),
                    up: XCTUnwrap(UnitDirection(x: -sin(angle), y: cos(angle), z: 0)),
                    widthMeters: size, heightMeters: size, onAxisCandela: 1000))
                let normal = try XCTUnwrap(UnitDirection(x: 0, y: 0, z: -1))
                let lux = try XCTUnwrap(Photometry.rectangularIlluminance(
                    emitter: emitter, receiver: .init(x: 0, y: 0, z: depth), receiverNormal: normal))
                XCTAssertGreaterThan(lux, 0)
                XCTAssertNil(Photometry.rectangularIlluminance(
                    emitter: emitter, receiver: .init(x: 0, y: 0, z: depth.nextDown),
                    receiverNormal: normal), "Strict separation must remain intact at roll \(degrees)")
            }
        }
    }

    func testTinyRectangleOutputRetainsRepresentableIlluminance() throws {
        let right = try XCTUnwrap(UnitDirection(x: 1, y: 0, z: 0))
        let up = try XCTUnwrap(UnitDirection(x: 0, y: 1, z: 0))
        let normal = try XCTUnwrap(UnitDirection(x: 0, y: 0, z: -1))
        // Independent centered-rectangle projected-solid-angle antiderivative.
        let a = 0.025, d = 0.05
        let hypotenuse = sqrt(d * d + a * a)
        let coefficient = 4 / (4 * a * a) * a / hypotenuse * atan(a / hypotenuse)
        for steps in [1.0, 202, 2024, 1e12] {
            let intensity = steps * Double.leastNonzeroMagnitude
            let emitter = try XCTUnwrap(LambertianRectangle(
                center: .init(x: 0, y: 0, z: 0), right: right, up: up,
                widthMeters: 0.05, heightMeters: 0.05, onAxisCandela: intensity))
            let actual = try XCTUnwrap(Photometry.rectangularIlluminance(
                emitter: emitter, receiver: .init(x: 0, y: 0, z: d), receiverNormal: normal))
            let expected = coefficient * intensity
            XCTAssertGreaterThan(actual, 0)
            XCTAssertLessThanOrEqual(abs(actual / expected - 1), 0.05)
        }
    }

    func testTinyOutputDoesNotBypassUnsupportedSeparation() throws {
        let emitter = try XCTUnwrap(LambertianRectangle(
            center: .init(x: 0, y: 0, z: 0),
            right: XCTUnwrap(UnitDirection(x: 1, y: 0, z: 0)),
            up: XCTUnwrap(UnitDirection(x: 0, y: 1, z: 0)),
            widthMeters: 0.05, heightMeters: 0.05,
            onAxisCandela: Double.leastNonzeroMagnitude))
        XCTAssertNil(Photometry.rectangularIlluminance(
            emitter: emitter, receiver: .init(x: 0, y: 0, z: 0.049),
            receiverNormal: try XCTUnwrap(UnitDirection(x: 0, y: 0, z: -1))))
    }
}
