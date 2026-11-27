import Foundation
import XCTest
@testable import LightingCore

/// Starts from prescribed surfaces and analytic gradients, not a copy of the
/// production quadratic or production-returned distances.
final class PortraitVisibilityProbeTests: XCTestCase {
    private let shadowGuard = 1e-5

    func testShoulderSurfaceDistancesAndNormalsMatchIndependentGradient() throws {
        let radii = SIMD3<Double>(0.107, 0.086, 0.090)
        for translation: SIMD3<Double> in [.zero, .init(8, 3, -6)] {
            let geometry = PortraitGeometry(center: .init(x: translation.x, y: translation.y, z: translation.z))
            for sign in [-1.0, 1.0] {
                let center = SIMD3<Double>(sign * 0.129, -0.294, -0.020)
                let unitPoint = SIMD3<Double>(sign * 0.8, 0.6, 0)
                let surface = translation + center + radii * unitPoint
                // 0.8^2 + 0.6^2 = 1. Selected |x| = 0.2146 is beyond the
                // torso's entire 0.203 m radius, isolating this shoulder.
                XCTAssertEqual(dot(unitPoint, unitPoint), 1, accuracy: 1e-15)
                let expectedNormal = unit(unitPoint / radii)
                let travel = 0.2
                let origin = surface + expectedNormal * travel
                let hit = try XCTUnwrap(geometry.hit(origin: origin, direction: -expectedNormal, minimum: shadowGuard))
                XCTAssertEqual(hit.region, .clothing)
                XCTAssertEqual(hit.distance, travel, accuracy: 1e-10)
                assertVector(origin - expectedNormal * hit.distance, equals: surface, accuracy: 1e-10)
                assertVector(hit.normal, equals: expectedNormal, accuracy: 1e-10)
                assertVector(hit.geometricNormal, equals: expectedNormal, accuracy: 1e-10)
                XCTAssertEqual(dot(hit.normal, hit.normal), 1, accuracy: 1e-12)
                XCTAssertGreaterThan(dot(hit.normal, surface - translation - center), 0)
            }
        }
    }

    func testShoulderInsideExitAndFiniteShadowSegmentsUseAnalyticDistances() throws {
        let geometry = PortraitGeometry(center: .init(x: 0, y: 0, z: 0))
        for sign in [-1.0, 1.0] {
            let center = SIMD3<Double>(sign * 0.129, -0.294, -0.020)
            let outward = SIMD3<Double>(sign, 0, 0)
            let radius = 0.107
            let surface = center + outward * radius
            let inside = center + outward * (0.95 * radius)
            let outside = center + outward * (1.05 * radius)
            XCTAssertTrue(geometry.contains(inside))
            XCTAssertFalse(geometry.contains(outside))
            let exit = try XCTUnwrap(geometry.hit(origin: inside, direction: outward, minimum: shadowGuard))
            XCTAssertEqual(exit.region, .clothing)
            XCTAssertEqual(exit.distance, 0.05 * radius, accuracy: 1e-12)
            assertVector(exit.normal, equals: outward, accuracy: 1e-12)
            XCTAssertNil(geometry.hit(origin: outside, direction: outward, minimum: shadowGuard))
            XCTAssertFalse(geometry.occludes(origin: outside, direction: outward, distance: 1))

            let travel = 0.1
            let origin = surface + outward * travel
            let inward = -outward
            let entry = try XCTUnwrap(geometry.hit(origin: origin, direction: inward, minimum: shadowGuard))
            XCTAssertEqual(entry.distance, travel, accuracy: 1e-12)
            // Brackets remain >=5 micrometers from the effective endpoint;
            // quadratic roundoff cannot decide these booleans.
            for distance in [travel - 2 * shadowGuard, travel, travel + shadowGuard / 2] {
                XCTAssertFalse(geometry.occludes(origin: origin, direction: inward, distance: distance))
            }
            XCTAssertTrue(geometry.occludes(origin: origin, direction: inward, distance: travel + 2 * shadowGuard))
        }
    }

    func testPanelHasInclusivePrimaryMinimumAndExclusiveShadowEnd() throws {
        let geometry = PortraitGeometry(center: .init(x: 0, y: 0, z: 0))
        let panelY = -0.565
        let travel = 0.125
        let origin = SIMD3<Double>(0.7, panelY + travel, 0.2)
        let downward = SIMD3<Double>(0, -1, 0)
        // x = 0.7 is outside all bust parts and their broad-phase bound.
        let hit = try XCTUnwrap(geometry.hit(origin: origin, direction: downward, minimum: travel))
        XCTAssertEqual(hit.region, .panel)
        XCTAssertEqual(hit.distance, travel)
        assertVector(hit.normal, equals: .init(0, 1, 0), accuracy: 0)
        XCTAssertNil(geometry.hit(origin: origin, direction: downward, minimum: travel.nextUp))
        // Binary-exact plane distance, independent of production hit data.
        let endpoint = travel + shadowGuard
        XCTAssertEqual(endpoint - shadowGuard, travel)
        XCTAssertFalse(geometry.occludes(origin: origin, direction: downward, distance: endpoint))
        XCTAssertTrue(geometry.occludes(origin: origin, direction: downward, distance: travel + 2 * shadowGuard))
    }

    func testPanelEdgesAreFiniteAndInclusive() throws {
        let geometry = PortraitGeometry(center: .init(x: 0, y: 0, z: 0))
        let cases: [(x: Double, z: Double, isInside: Bool)] = [
            (3, 3, true), (-3, -3, true), (0.7, 3, true), (0.7, -3, true),
            (3.000001, 3, false), (-3.000001, -3, false),
            (0.7, 3.000001, false), (0.7, -3.000001, false)
        ]
        for probe in cases {
            let origin = SIMD3<Double>(probe.x, -0.565 + 0.125, probe.z)
            let direction = SIMD3<Double>(0, -1, 0)
            let hit = geometry.hit(origin: origin, direction: direction, minimum: shadowGuard)
            XCTAssertEqual(hit != nil, probe.isInside, "x=\(probe.x), z=\(probe.z)")
            XCTAssertEqual(geometry.occludes(origin: origin, direction: direction, distance: 0.125 + 2 * shadowGuard),
                           probe.isInside, "x=\(probe.x), z=\(probe.z)")
            if probe.isInside {
                XCTAssertEqual(try XCTUnwrap(hit).distance, 0.125)
                XCTAssertEqual(try XCTUnwrap(hit).region, .panel)
            }
        }
    }

    private func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        a.x * b.x + a.y * b.y + a.z * b.z
    }

    private func unit(_ value: SIMD3<Double>) -> SIMD3<Double> {
        value / sqrt(dot(value, value))
    }

    private func assertVector(_ actual: SIMD3<Double>, equals expected: SIMD3<Double>, accuracy: Double,
                              file: StaticString = #filePath, line: UInt = #line) {
        for axis in 0..<3 {
            XCTAssertEqual(actual[axis], expected[axis], accuracy: accuracy, "axis \(axis)", file: file, line: line)
        }
    }
}
