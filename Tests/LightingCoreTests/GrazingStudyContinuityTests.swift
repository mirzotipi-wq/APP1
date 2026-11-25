import Foundation
import XCTest
@testable import LightingCore

final class GrazingStudyContinuityTests: XCTestCase {
    private let receiver = Position(x: 0, y: 0, z: 0.25)

    private func scene(receiver: Position? = nil, candela: Double = 1000) -> LightingScene {
        .init(subject: receiver ?? self.receiver, camera: .init(x: 0, y: 0, z: 3), lights: [
            .init(name: "Grazing rectangle", position: .init(x: 0, y: 0, z: 0), candela: candela, kelvin: 5600,
                  optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 0, z: 1), widthMeters: 1, heightMeters: 0.6))
        ])
    }

    private func normal(cut: Double, slope: Double, receiver: Position? = nil) -> UnitDirection {
        let p = receiver ?? self.receiver
        return UnitDirection(x: 1, y: slope, z: (cut - p.x - slope * p.y) / p.z)!
    }

    private func signal(_ lighting: StudyLighting, cut: Double, slope: Double = 0,
                        receiver: Position? = nil, material: StudyMaterial = .diffuse(reflectance: 1)) throws -> StudySurfaceSignal {
        let p = receiver ?? self.receiver, n = normal(cut: cut, slope: slope, receiver: p)
        return try lighting.evaluate(receiver: p, normal: n, view: n, material: material)
    }

    // Independent composite Simpson integral over exact vertical slices. Split
    // at the change between partial/full-height slices. This shares neither the
    // production polygon operations nor the column-centroid quadrature rule.
    private func reference(cut: Double, slope: Double, receiver: Position? = nil) -> Double {
        let p = receiver ?? self.receiver, count = 160
        let nz = (cut - p.x - slope * p.y) / p.z
        let length = sqrt(1 + slope * slope + nz * nz)
        let start = max(-0.5, cut - abs(slope) * 0.3), end = 0.5
        guard start < end else { return 0 }
        let corner = cut + abs(slope) * 0.3
        var breaks = [start]
        if corner > start && corner < end { breaks.append(corner) }
        breaks.append(end)
        func weight(_ i: Int) -> Double { i == 0 || i == count ? 1 : i.isMultiple(of: 2) ? 2 : 4 }
        var integral = 0.0
        for k in 0..<(breaks.count - 1) {
            let dx = (breaks[k + 1] - breaks[k]) / Double(count)
            var sum = 0.0
            for i in 0...count {
                let x = breaks[k] + Double(i) * dx
                var lower = -0.3, upper = 0.3
                if slope > 0 { lower = max(lower, (cut - x) / slope) }
                else if slope < 0 { upper = min(upper, (cut - x) / slope) }
                guard lower < upper else { continue }
                let dy = (upper - lower) / Double(count)
                var slice = 0.0
                for j in 0...count {
                    let y = lower + Double(j) * dy
                    let r2 = (x - p.x) * (x - p.x) + (y - p.y) * (y - p.y) + p.z * p.z
                    slice += weight(j) * p.z * max(0, x + slope * y - cut) / length / (r2 * r2)
                }
                sum += weight(i) * slice * dy / 3
            }
            integral += sum * dx / 3 * 1000 / 0.6
        }
        return integral
    }

    func testRetainedInternalCellCounterexampleIsContinuous() throws {
        for quality in [StudyQuality.interactive, .reference] {
            let lighting = try StudyLighting(scene: scene(), quality: quality)
            let cuts = [0.6 - 1e-8, 0.6, 0.6 + 1e-8]
            let values = try cuts.map { try signal(lighting, cut: $0, slope: 1).visibleLux }
            let expected = cuts.map { reference(cut: $0, slope: 1) }
            // The held candidate jumped 0.0874044675 lx here. Physical variation
            // is about 6.96288e-7 lx; retain this exact counterexample.
            XCTAssertLessThan(abs(values[2] - values[0]), 2 * abs(expected[2] - expected[0]))
            for i in cuts.indices { XCTAssertLessThan(abs(values[i] - expected[i]) / expected[i], 0.05) }
        }
    }

    func testMovingClipAndColumnTopologyRemainContinuous() throws {
        // Whole-face, polygon-vertex, and interior-column boundaries at 8×8.
        let cuts = [-0.8, -0.675, -0.55, -0.425, -0.3, -0.2, 0, 0.8 - 4.8 / 7, 0.2, 0.6]
        for quality in [StudyQuality.interactive, .reference] {
            let lighting = try StudyLighting(scene: scene(), quality: quality)
            for cut in cuts {
                let low = try signal(lighting, cut: cut - 1e-8, slope: 1).visibleLux
                let high = try signal(lighting, cut: cut + 1e-8, slope: 1).visibleLux
                let expectedLow = reference(cut: cut - 1e-8, slope: 1)
                let expectedHigh = reference(cut: cut + 1e-8, slope: 1)
                XCTAssertLessThan(abs(high - low), 2 * abs(expectedHigh - expectedLow) + 1e-9,
                                  "quality=\(quality), cut=\(cut)")
            }
        }
    }

    func testNarrowPositiveStripsAndCornersRetainAccuracy() throws {
        for quality in [StudyQuality.interactive, .reference] {
            let lighting = try StudyLighting(scene: scene(), quality: quality)
            for (cut, slope) in [(0.48, 0.0), (0.499, 0.0), (0.49999, 0.0), (0.79, 1.0), (0.799, 1.0), (0.79999, 1.0)] {
                let actual = try signal(lighting, cut: cut, slope: slope)
                let expected = reference(cut: cut, slope: slope)
                XCTAssertGreaterThan(actual.visibleLux, 0)
                XCTAssertLessThan(abs(actual.visibleLux - expected) / expected, 0.002,
                                  "quality=\(quality), cut=\(cut), slope=\(slope)")
                XCTAssertEqual(actual.visibleLux, actual.unoccludedLux)
                XCTAssertEqual(actual.signalXYZ.y, actual.visibleLux / 1000, accuracy: expected * 1e-12)
            }
        }
    }

    func testHeldOutOffCenterAndSignedSlopeCasesMeetAreaTolerance() throws {
        let cases: [(Double, Double, Position)] = [
            (0.13, 0.35, .init(x: -0.2, y: 0.12, z: 0.37)),
            (-0.55, 1.7, .init(x: 0.41, y: -0.16, z: 0.25)),
            (0.68, 3.24, .init(x: 0.25, y: 0.2, z: 0.37)),
            (-0.31, -1.57, .init(x: -0.45, y: -0.07, z: 0.25)),
            (0.47, 0, .init(x: 0.3, y: 0.19, z: 0.8)),
            (0.11, -2.1, .init(x: -0.12, y: 0.3, z: 2))
        ]
        for quality in [StudyQuality.interactive, .reference] {
            for (cut, slope, p) in cases {
                let lighting = try StudyLighting(scene: scene(receiver: p), quality: quality)
                let actual = try signal(lighting, cut: cut, slope: slope, receiver: p).visibleLux
                let expected = reference(cut: cut, slope: slope, receiver: p)
                XCTAssertGreaterThan(actual, 0)
                XCTAssertLessThan(abs(actual - expected) / expected, 0.05)
            }
        }
    }

    func testFullFaceRetainsOriginalMidpointValuesAndSampleCount() throws {
        for (quality, grid) in [(StudyQuality.interactive, 8), (.reference, 32)] {
            let lighting = try StudyLighting(scene: scene(), quality: quality)
            let n = normal(cut: -1, slope: 1)
            var expected = 0.0
            for row in 0..<grid {
                let y = ((Double(row) + 0.5) / Double(grid) - 0.5) * 0.6
                for col in 0..<grid {
                    let x = (Double(col) + 0.5) / Double(grid) - 0.5
                    let r2 = x * x + y * y + 0.0625, distance = sqrt(r2)
                    let nl = (n.x * x + n.y * y - n.z * 0.25) / distance
                    expected += 1000 / Double(grid * grid) * (0.25 / distance) * nl / r2
                }
            }
            XCTAssertEqual(try signal(lighting, cut: -1, slope: 1).visibleLux, expected, accuracy: 1e-10)
            XCTAssertEqual(lighting.sampleCount, grid * grid)
        }
    }

    func testClippedAreaWeightsAndWorkAreBounded() {
        let half = StudyAreaSamplingPlane(center: 0, x: 0, y: 1)
        let cases: [(StudyAreaSamplingPlane, StudyAreaSamplingPlane?, Double)] = [
            (.init(center: 1, x: 0.2, y: 0.3), nil, 1),
            (.init(center: 0, x: 1, y: 0), nil, 0.5),
            (.init(center: -0.499, x: 0.5, y: 0), nil, 0.001),
            (.init(center: -0.79, x: 0.5, y: 0.3), nil, 0.01 * 0.01 / 1.2),
            (.init(center: -0.499, x: 0.5, y: 0), half, 0.0005),
            (.init(center: 0, x: 1, y: 1), .init(center: 0, x: 1, y: -1), 0.25)
        ]
        for grid in [8, 32] {
            for (plane, geometric, fraction) in cases {
                var count = 0, totalWeight = 0.0
                StudyAreaSliceSampling.forEach(grid: grid, normal: plane, geometric: geometric) { p, weight in
                    count += 1; totalWeight += weight / Double(grid * grid)
                    XCTAssertTrue((-1...1).contains(p.x) && (-1...1).contains(p.y))
                    XCTAssertGreaterThan(plane.at(p), 0)
                    if let geometric { XCTAssertGreaterThan(geometric.at(p), 0) }
                    XCTAssertGreaterThan(weight, 0)
                }
                XCTAssertEqual(count, grid * grid)
                XCTAssertEqual(totalWeight, fraction, accuracy: 1e-13)
            }
        }
    }

    func testRemappedSamplesRetainVisibilityMaterialAndGeometricHemisphere() throws {
        let lighting = try StudyLighting(scene: scene(), quality: .interactive)
        let unit = normal(cut: 0.499, slope: 0)
        let n = SIMD3<Double>(unit.x, unit.y, unit.z), p = SIMD3<Double>(0, 0, 0.25)
        let geometric = SIMD3<Double>(0, 1, 0)
        var calls = 0
        let partial = try lighting.evaluate(receiver: p, normal: n, view: n, material: .diffuse(reflectance: 0.25),
                                            occlusionTest: { origin, direction, length in
            calls += 1
            let endpoint = origin + direction * length
            XCTAssertEqual(origin.y, 1e-5, accuracy: 1e-15)
            XCTAssertEqual(endpoint.z, 0, accuracy: 1e-14)
            XCTAssertGreaterThan(endpoint.x, 0.499)
            XCTAssertGreaterThan(endpoint.y, 0)
            return endpoint.y > 0.15
        }, geometricNormal: geometric)
        XCTAssertEqual(calls, 64)
        let expected = reference(cut: 0.499, slope: 0) / 2
        XCTAssertLessThan(abs(partial.unoccludedLux - expected) / expected, 0.002)
        XCTAssertGreaterThan(partial.visibleLux, 0)
        XCTAssertLessThan(partial.visibleLux, partial.unoccludedLux)
        XCTAssertEqual(partial.signalXYZ.y, partial.visibleLux * 0.25 / 1000, accuracy: 1e-18)
        let blocked = try lighting.evaluate(receiver: p, normal: n, view: n,
                                            material: .dielectric(reflectance: 0.18, roughness: 0.32, f0: 0.04),
                                            occlusionTest: { _, _, _ in true }, geometricNormal: geometric)
        XCTAssertEqual(blocked.visibleLux, 0)
        XCTAssertEqual(blocked.signalXYZ.y, 0)
        XCTAssertEqual(blocked.unoccludedLux, partial.unoccludedLux)
        let diffuse = try signal(lighting, cut: 0.499)
        let dielectric = try signal(lighting, cut: 0.499, material: .dielectric(reflectance: 0.18, roughness: 0.32, f0: 0.04))
        XCTAssertEqual(dielectric.visibleLux, diffuse.visibleLux)
        XCTAssertGreaterThan(dielectric.signalXYZ.y, 0)
        XCTAssertNotEqual(dielectric.signalXYZ.y, diffuse.signalXYZ.y)
    }

    func testDarkTangentEmissionBackfaceAndNearFieldRemainDistinct() throws {
        for quality in [StudyQuality.interactive, .reference] {
            let lighting = try StudyLighting(scene: scene(), quality: quality)
            for (cut, slope) in [(0.5, 0.0), (0.501, 0.0), (0.8, 1.0), (0.81, 1.0)] {
                XCTAssertEqual(try signal(lighting, cut: cut, slope: slope).visibleLux, 0, accuracy: 1e-20)
            }
            let toward = UnitDirection(x: 0, y: 0, z: 1)!
            XCTAssertEqual(try lighting.evaluate(receiver: .init(x: 0, y: 0, z: -0.25), normal: toward,
                                                view: toward, material: .diffuse(reflectance: 1)).visibleLux, 0)
            XCTAssertThrowsError(try lighting.evaluate(receiver: .init(x: 0, y: 0, z: 0.249), normal: toward,
                                                       view: toward, material: .diffuse(reflectance: 1))) {
                XCTAssertEqual($0 as? StudyError, .invalidSurface)
            }
        }
    }

    func testPackedAreaMetadataStaysAlignedAcrossMixedSources() throws {
        var s = scene()
        let area = s.lights[0]
        let point = StudioLight(name: "Point", position: .init(x: 0, y: 0, z: 1.5), candela: 500, kelvin: 5600)
        var directional = point
        directional.id = UUID()
        directional.optics = .init(kind: .directional)
        var secondArea = area
        secondArea.id = UUID()
        s.lights = [point, area, directional, secondArea]
        let packed = try StudyComputeInput(scene: s, width: 24)
        XCTAssertEqual(packed.parameters[5].w, 8)
        XCTAssertEqual(packed.parameters[5].x, 130)
        XCTAssertEqual(packed.parameters[5].y, 2)
        XCTAssertEqual(packed.samples[2].w, 0)
        XCTAssertEqual(packed.samples[3 * 65 + 2].w, 0)
        for i in 1...64 { XCTAssertEqual(packed.samples[3 * i + 2].w, 1) }
        for i in 66..<130 { XCTAssertEqual(packed.samples[3 * i + 2].w, 2) }
    }
}
