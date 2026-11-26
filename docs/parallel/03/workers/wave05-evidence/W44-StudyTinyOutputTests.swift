import Foundation
import XCTest
@testable import LightingCore

final class StudyTinyOutputTests: XCTestCase {
    private let origin = Position(x: 0, y: 0, z: 0)
    private let quantum = Double.leastNonzeroMagnitude
    private let forward = UnitDirection(x: 0, y: 0, z: 1)!

    private func scene(_ lights: [StudioLight]) -> LightingScene {
        .init(subject: origin, camera: .init(x: 0, y: 0, z: 3), lights: lights)
    }

    private func light(_ kind: EmitterKind, candela: Double, depth: Double = 0.06) -> StudioLight {
        .init(name: "Tiny output", position: .init(x: 0, y: 0, z: depth), candela: candela, kelvin: 5600,
              optics: .init(kind: kind, aimTarget: origin, widthMeters: 0.1, heightMeters: 0.1))
    }

    private func assertScaled(_ actual: StudySurfaceSignal, unit: StudySurfaceSignal, by scale: Double,
                              file: StaticString = #filePath, line: UInt = #line) {
        let pairs = [(actual.visibleLux, unit.visibleLux), (actual.unoccludedLux, unit.unoccludedLux),
                     (actual.signalXYZ.x, unit.signalXYZ.x), (actual.signalXYZ.y, unit.signalXYZ.y),
                     (actual.signalXYZ.z, unit.signalXYZ.z)]
        for (value, unitValue) in pairs {
            let expected = unitValue * scale
            XCTAssertTrue(value.isFinite && value >= 0, file: file, line: line)
            XCTAssertEqual(value, expected, file: file, line: line)
            if expected > 0 { XCTAssertGreaterThan(value, 0, file: file, line: line) }
        }
    }

    func testSubnormalPointAndDirectionalPreserveFiniteMirroredGrazingGGX() throws {
        let cosine = 0.1, nx = sqrt(1 - cosine * cosine)
        let normal = try XCTUnwrap(UnitDirection(x: nx, y: 0, z: cosine))
        let view = try XCTUnwrap(UnitDirection(x: 2 * cosine * nx, y: 0, z: 2 * cosine * cosine - 1))
        let material = StudyMaterial.dielectric(reflectance: 0, roughness: 0.05, f0: 0.08)
        let a2 = pow(0.05, 4)
        let fresnel = 0.08 + 0.92 * pow(1 - cosine, 5)
        let response = fresnel / (a2 * 4 * cosine * sqrt(cosine * cosine * (1 - a2) + a2))
        for (kind, emission) in [(EmitterKind.point, 1.0), (.directional, 0.5)] {
            var source = light(kind, candela: 1)
            source.optics?.aimTarget = .init(x: sqrt(0.75), y: 0, z: 0.06 - 0.5)
            let unit = try StudyLighting(scene: scene([source])).evaluate(
                receiver: origin, normal: normal, view: view, material: material)
            let expectedLux = emission * cosine / (0.06 * 0.06)
            XCTAssertEqual(unit.visibleLux / expectedLux, 1, accuracy: 1e-10)
            XCTAssertEqual(unit.signalXYZ.y / (expectedLux * response / 1000), 1, accuracy: 1e-8)
            for output in [quantum, Double.leastNormalMagnitude / 2] {
                source.candela = output
                let prepared = try StudyLighting(scene: scene([source]))
                XCTAssertEqual(prepared.sampleCount, 1)
                let actual = try prepared.evaluate(receiver: origin, normal: normal, view: view, material: material)
                XCTAssertGreaterThan(unit.signalXYZ.y * output, 0)
                assertScaled(actual, unit: unit, by: output)
            }
        }
    }

    func testTinyFullAndClippedRectanglesScaleAfterIntegrationAtBothQualities() throws {
        let normals = [UnitDirection(x: 0.25, y: 0.1, z: 1)!, UnitDirection(x: 1, y: 0.2, z: 0.5)!]
        for (quality, count) in [(StudyQuality.interactive, 64), (.reference, 1024)] {
            for normal in normals {
                var source = light(.rectangle, candela: 1)
                let unit = try StudyLighting(scene: scene([source]), quality: quality).evaluate(
                    receiver: origin, normal: normal, view: normal, material: .diffuse(reflectance: 1))
                XCTAssertGreaterThan(unit.visibleLux, 0)
                // Include positive output that divides to zero, and normal emitter output
                // whose per-cell share is subnormal at both supported sample budgets.
                for output in [16 * quantum, Double.leastNormalMagnitude, 32 * Double.leastNormalMagnitude] {
                    source.candela = output
                    let prepared = try StudyLighting(scene: scene([source]), quality: quality)
                    XCTAssertEqual(prepared.sampleCount, count)
                    let actual = try prepared.evaluate(receiver: origin, normal: normal, view: normal,
                                                       material: .diffuse(reflectance: 1))
                    assertScaled(actual, unit: unit, by: output)
                }
            }
        }
    }

    func testMixedOrdinaryAndTinyEmittersRetainEachContributionAndOrder() throws {
        let normal = try XCTUnwrap(UnitDirection(x: 1, y: 0.2, z: 0.5))
        let material = StudyMaterial.diffuse(reflectance: 1)
        for ordinaryOutput in [1.0, Double.leastNormalMagnitude] {
            let sources = [light(.point, candela: ordinaryOutput, depth: 1),
                           light(.point, candela: quantum),
                           light(.directional, candela: Double.leastNormalMagnitude / 2),
                           light(.rectangle, candela: 16 * quantum)]
            for ordered in [sources, Array(sources.reversed())] {
                let individual = try ordered.map {
                    try StudyLighting(scene: scene([$0])).evaluate(receiver: origin, normal: normal,
                                                                  view: normal, material: material)
                }
                let prepared = try StudyLighting(scene: scene(ordered))
                XCTAssertEqual(prepared.sampleCount, 67)
                let actual = try prepared.evaluate(receiver: origin, normal: normal, view: normal, material: material)
                XCTAssertEqual(actual.visibleLux, individual.reduce(0) { $0 + $1.visibleLux })
                XCTAssertEqual(actual.unoccludedLux, individual.reduce(0) { $0 + $1.unoccludedLux })
                XCTAssertEqual(actual.signalXYZ.x, individual.reduce(0) { $0 + $1.signalXYZ.x })
                XCTAssertEqual(actual.signalXYZ.y, individual.reduce(0) { $0 + $1.signalXYZ.y })
                XCTAssertEqual(actual.signalXYZ.z, individual.reduce(0) { $0 + $1.signalXYZ.z })
            }
        }
    }

    func testTinyPositiveSourcesRetainUnsupportedNearFieldGuards() throws {
        for kind in [EmitterKind.point, .directional, .rectangle] {
            for quality in [StudyQuality.interactive, .reference] {
                var source = light(kind, candela: quantum, depth: 0.04)
                // Area guard must still reject even when its emitting face points away.
                if kind == .rectangle { source.optics?.aimTarget = .init(x: 0, y: 0, z: 1) }
                let prepared = try StudyLighting(scene: scene([source]), quality: quality)
                XCTAssertGreaterThan(prepared.sampleCount, 0)
                XCTAssertThrowsError(try prepared.evaluate(receiver: origin, normal: forward, view: forward,
                                                           material: .diffuse(reflectance: 1))) {
                    XCTAssertEqual($0 as? StudyError, .invalidSurface)
                }
                source.candela = 0
                let dark = try StudyLighting(scene: scene([source]), quality: quality)
                XCTAssertEqual(dark.sampleCount, 0)
                XCTAssertEqual(try dark.evaluate(receiver: origin, normal: forward, view: forward,
                                                 material: .diffuse(reflectance: 1)).visibleLux, 0)
            }
        }
    }

    func testTinyComputePackingKeepsRowsGeometryAndFloat32ZeroOutput() throws {
        let sources = [light(.point, candela: 1000), light(.point, candela: quantum),
                       light(.directional, candela: quantum), light(.rectangle, candela: 16 * quantum)]
        let packed = try StudyComputeInput(scene: scene(sources), width: 24)
        let unitSources = sources.map { source -> StudioLight in
            var unit = source; unit.candela = 1; return unit
        }
        let unit = try StudyComputeInput(scene: scene(unitSources), width: 24)
        XCTAssertEqual(packed.samples.count, 67 * 3)
        XCTAssertEqual(packed.parameters, unit.parameters)
        XCTAssertEqual(packed.areas, unit.areas)
        XCTAssertEqual(packed.parameters[5].x, 67)
        XCTAssertEqual(packed.parameters[5].y, 1)
        for index in packed.samples.indices {
            var expected = unit.samples[index]
            if index.isMultiple(of: 3) { expected.w = index == 0 ? 1000 : 0 }
            XCTAssertEqual(packed.samples[index], expected)
        }
    }
}
