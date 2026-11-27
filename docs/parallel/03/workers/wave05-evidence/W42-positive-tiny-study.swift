// W42: positive tiny emitter output must survive supported near-field evaluation.
// Baseline: c9ff1a71c173774e7b7c794e475f8bdf5d633853.
// Compile together with Sources/LightingCore/*.swift; uses only public API.
// Fixed fixtures/expectations: do not edit to turn a baseline failure into a pass.
import Foundation

@main
struct W42PositiveTinyStudyProbe {
    struct Fixture {
        let name: String
        let light: StudioLight
        let receiver: Position
        let normal: UnitDirection
        let view: UnitDirection
        let material: StudyMaterial
        let quality: StudyQuality
        let tinyCandela: Double
        let expectedSamples: Int
        let analyticUnitLux: Double?
        let analyticUnitY: Double?
    }

    static func main() {
        let quantum = Double.leastNonzeroMagnitude
        let depth = 0.06 // Strictly outside both the 5 cm point and rectangle guards.
        let receiver = Position(x: 0, y: 0, z: depth)
        let areaOutput = 16 * quantum // /64 and /1024 both round to zero on the baseline.
        var fixtures: [Fixture] = []
        for (quality, grid) in [(StudyQuality.interactive, 8), (.reference, 32)] {
            for (name, n, v) in [
                ("full", UnitDirection(x: 0.25, y: 0.1, z: -1)!,
                 UnitDirection(x: 0.1, y: -0.1, z: -1)!),
                ("clipped", UnitDirection(x: 1, y: 0.2, z: -0.5)!,
                 UnitDirection(x: 1, y: 0.1, z: -0.8)!)
            ] {
                fixtures.append(Fixture(
                    name: "rectangle-\(name)-\(grid)x\(grid)",
                    light: StudioLight(
                        name: "W42 rectangle", position: .init(x: 0, y: 0, z: 0),
                        candela: 1, kelvin: 5600,
                        optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 0, z: 1),
                                      widthMeters: 0.1, heightMeters: 0.1)),
                    receiver: receiver, normal: n, view: v, material: .diffuse(reflectance: 1),
                    quality: quality, tinyCandela: areaOutput, expectedSamples: grid * grid,
                    analyticUnitLux: nil, analyticUnitY: nil))
            }
        }

        // L=(0,0,1); tilted N and its reflected V give N.L=N.V=0.1 and H=N.
        // The independent GGX expression below uses these exact geometric identities.
        let cosine = 0.1
        let nx = sqrt(1 - cosine * cosine)
        let n = UnitDirection(x: nx, y: 0, z: cosine)!
        let v = UnitDirection(x: 2 * cosine * nx, y: 0, z: 2 * cosine * cosine - 1)!
        let roughness = 0.05, f0 = 0.08
        let alpha = roughness * roughness
        let a2 = alpha * alpha
        let fresnel = f0 + (1 - f0) * pow(1 - cosine, 5)
        let response = (1 / a2) * fresnel /
            (4 * cosine * sqrt(cosine * cosine * (1 - a2) + a2))
        for (kind, emission) in [(EmitterKind.point, 1.0), (.directional, 0.5)] {
            let unitLux = emission * cosine / (depth * depth)
            // The directional source points 60 degrees away from the receiver ray.
            let aim = Position(x: sqrt(0.75), y: 0, z: depth - 0.5)
            fixtures.append(Fixture(
                name: "\(kind.rawValue)-grazing-GGX",
                light: StudioLight(
                    name: "W42 grazing", position: .init(x: 0, y: 0, z: depth),
                    candela: 1, kelvin: 5600, optics: .init(kind: kind, aimTarget: aim)),
                receiver: .init(x: 0, y: 0, z: 0), normal: n, view: v,
                material: .dielectric(reflectance: 0, roughness: roughness, f0: f0),
                quality: .interactive, tinyCandela: quantum, expectedSamples: 1,
                analyticUnitLux: unitLux, analyticUnitY: unitLux * response / 1000))
        }

        var checks = 0, failures = 0
        func check(_ condition: Bool, _ message: String) {
            checks += 1
            if !condition {
                failures += 1
                print("FAIL \(message)")
            }
        }
        func observe(_ label: String, actual: Double, expected: Double) {
            print("\(label) actual=\(actual) expected=\(expected) " +
                  "actualQuanta=\(actual / quantum) expectedQuanta=\(expected / quantum)")
            check(actual.isFinite && actual >= 0, "\(label): finite, nonnegative")
            check(expected.isFinite && expected >= 0, "\(label): reference is finite, nonnegative")
            if expected > 0 {
                check(actual > 0, "\(label): representable positive reference must not become zero")
            }
            // Quantization-aware bound, frozen before baseline execution.
            // 1% is the linearity bound; four subnormal ulps account for final rounding.
            let tolerance = max(abs(expected) * 0.01, 4 * quantum)
            check(abs(actual - expected) <= tolerance,
                  "\(label): fixed 1%/4-ulp linearity bound (tolerance=\(tolerance))")
        }
        func evaluate(_ fixture: Fixture, candela: Double) throws -> StudySurfaceSignal {
            var light = fixture.light
            light.candela = candela
            let scene = LightingScene(
                subject: fixture.receiver, camera: .init(x: 0, y: 0, z: 3), lights: [light])
            let lighting = try StudyLighting(scene: scene, quality: fixture.quality)
            check(lighting.sampleCount == fixture.expectedSamples, "\(fixture.name): sample count")
            return try lighting.evaluate(receiver: fixture.receiver, normal: fixture.normal,
                                         view: fixture.view, material: fixture.material)
        }

        print("W42 baseline=c9ff1a71c173774e7b7c794e475f8bdf5d633853 fixtures=\(fixtures.count)")
        print("Geometry: point distance=0.06 m; rectangle=0.1x0.1 m, depth=0.06 m, guard=0.05 m.")
        print("Acceptance: positive finite lux and every representable positive XYZ component; " +
              "fixed unit-output linearity and independent point/directional closed forms.")
        check(areaOutput > 0 && areaOutput / 64 == 0 && areaOutput / 1024 == 0,
              "fixture must exercise positive candela/grid-squared underflow")
        check(quantum * cosine == 0 && quantum * 0.5 == 0,
              "fixture must exercise positive candela/cosine underflow")
        for fixture in fixtures {
            do {
                let unit = try evaluate(fixture, candela: 1)
                let actual = try evaluate(fixture, candela: fixture.tinyCandela)
                check(unit.visibleLux > 0 && unit.visibleLux.isFinite,
                      "\(fixture.name): supported unit fixture is positive and finite")
                check(actual.visibleLux == actual.unoccludedLux,
                      "\(fixture.name): absent visibility geometry preserves all incident light")
                let metrics = [
                    ("visibleLux", actual.visibleLux, unit.visibleLux),
                    ("unoccludedLux", actual.unoccludedLux, unit.unoccludedLux),
                    ("signalXYZ.x", actual.signalXYZ.x, unit.signalXYZ.x),
                    ("signalXYZ.y", actual.signalXYZ.y, unit.signalXYZ.y),
                    ("signalXYZ.z", actual.signalXYZ.z, unit.signalXYZ.z)
                ]
                for (metric, value, unitValue) in metrics {
                    observe("\(fixture.name).\(metric)", actual: value,
                            expected: unitValue * fixture.tinyCandela)
                }
                if let expectedLux = fixture.analyticUnitLux,
                   let expectedY = fixture.analyticUnitY {
                    check(abs(unit.visibleLux / expectedLux - 1) <= 1e-10,
                          "\(fixture.name): unit lux agrees with inverse-square/cosine closed form")
                    check(abs(unit.signalXYZ.y / expectedY - 1) <= 1e-8,
                          "\(fixture.name): unit Y agrees with symmetric GGX closed form")
                    observe("\(fixture.name).closed-form-lux", actual: actual.visibleLux,
                            expected: expectedLux * fixture.tinyCandela)
                    observe("\(fixture.name).closed-form-Y", actual: actual.signalXYZ.y,
                            expected: expectedY * fixture.tinyCandela)
                }
            } catch {
                check(false, "\(fixture.name): unexpected public-API rejection: \(error)")
            }
        }
        print("W42 RESULT checks=\(checks) failures=\(failures)")
        if failures > 0 { exit(1) }
    }
}
