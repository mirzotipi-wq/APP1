import Foundation
import Dispatch
import LightingCore

struct Fixture: Sendable {
    let index: Int
    let label: String
    let source: StudioLight
    let scene: LightingScene
    let target: Double
    let expectedError: String?
}

struct Outcome: Equatable, Sendable {
    let adjusted: StudioLight?
    let candelaBits: UInt64?
    let luxBits: UInt64?
    let error: String?
    let invariants: Bool
    let relativeError: Double?
}

struct Run: Sendable {
    let index: Int
    let outcome: Outcome
    let start: UInt64
    let end: UInt64
}

func evaluate(_ fixture: Fixture) -> Outcome {
    let originalSource = fixture.source
    let originalScene = fixture.scene
    do {
        let result = try LightOutputAdjustment.light(fixture.source, targetingLux: fixture.target, in: fixture.scene)
        let lux = StudioPhotometry.illuminance(for: result, in: fixture.scene)
        var expected = fixture.source
        expected.candela = result.candela
        let relativeError = fixture.target > 0 ? lux.map { abs($0 / fixture.target - 1) } : nil
        let forwardOK = fixture.target == 0 ? lux == 0 : (relativeError.map { $0 <= 1e-9 } ?? false)
        return Outcome(adjusted: result, candelaBits: result.candela.bitPattern,
                       luxBits: lux?.bitPattern, error: nil,
                       invariants: fixture.expectedError == nil && result == expected && result.isValid &&
                           forwardOK && fixture.source == originalSource && fixture.scene == originalScene,
                       relativeError: relativeError)
    } catch {
        let code = String(describing: error)
        return Outcome(adjusted: nil, candelaBits: nil, luxBits: nil, error: code,
                       invariants: code == fixture.expectedError && fixture.source == originalSource &&
                           fixture.scene == originalScene, relativeError: nil)
    }
}

func makeFixtures() -> [Fixture] {
    var result: [Fixture] = []
    for (kindIndex, kind) in EmitterKind.allCases.enumerated() {
        let id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", kindIndex + 1))!
        let light = StudioLight(id: id, name: "Independent \(kind.rawValue)",
                                position: .init(x: 0.7, y: 2, z: 2.5), candela: 380, kelvin: 5600,
                                optics: .init(kind: kind, aimTarget: .init(x: 0.3, y: 1.6, z: -0.2),
                                              widthMeters: 0.6, heightMeters: 0.9, rollDegrees: 23))
        let scene = LightingScene(subject: .init(x: 0.1, y: 1.5, z: -0.2),
                                  camera: .init(x: 0.1, y: 1.5, z: 4), lights: [light])
        var off = light
        off.candela = 0
        var maximum = light
        maximum.candela = 100_000
        let existing = StudioPhotometry.illuminance(for: light, in: scene)!
        let aboveMaximum = StudioPhotometry.illuminance(for: maximum, in: scene)!.nextUp
        let cases: [(String, StudioLight, Double, String?)] = [
            ("zero", light, 0, nil),
            ("ordinary-from-off", off, 137.25, nil),
            ("existing", light, existing, nil),
            ("over-max", light, aboveMaximum, "outputOutOfRange")
        ]
        for (name, source, target, expectedError) in cases {
            result.append(Fixture(index: result.count, label: "\(kind.rawValue)/\(name)",
                                  source: source, scene: scene, target: target, expectedError: expectedError))
        }
    }
    return result
}

let fixtures = makeFixtures()
let serial = fixtures.map(evaluate)
let concurrent = await withTaskGroup(of: Run.self, returning: [Run].self) { group in
    // Each closure owns an immutable value copy; child tasks share no mutable storage.
    for fixture in fixtures.reversed() {
        group.addTask {
            let start = DispatchTime.now().uptimeNanoseconds
            let outcome = evaluate(fixture)
            let end = DispatchTime.now().uptimeNanoseconds
            return Run(index: fixture.index, outcome: outcome, start: start, end: end)
        }
    }
    var collected: [Run] = []
    for await run in group { collected.append(run) }
    return collected
}

var mismatches = 0
var invariantFailures = 0
var maxRelativeError = 0.0
var overlapPairs = 0
print("fixture\ttarget_lux\tserial_candela_bits\tconcurrent_candela_bits\tserial_lux_bits\tconcurrent_lux_bits\terror\texact_match\tinvariants\trelative_error\tstart_ns\tend_ns")
for run in concurrent.sorted(by: { $0.index < $1.index }) {
    let fixture = fixtures[run.index]
    let reference = serial[run.index]
    let exact = reference == run.outcome
    if !exact { mismatches += 1 }
    if !reference.invariants || !run.outcome.invariants { invariantFailures += 1 }
    maxRelativeError = max(maxRelativeError, run.outcome.relativeError ?? 0)
    let sb = reference.candelaBits.map(String.init) ?? "nil"
    let cb = run.outcome.candelaBits.map(String.init) ?? "nil"
    let sl = reference.luxBits.map(String.init) ?? "nil"
    let cl = run.outcome.luxBits.map(String.init) ?? "nil"
    let relative = run.outcome.relativeError.map(String.init(describing:)) ?? "n/a"
    print("\(fixture.label)\t\(fixture.target)\t\(sb)\t\(cb)\t\(sl)\t\(cl)\t\(run.outcome.error ?? "success")\t\(exact)\t\(reference.invariants && run.outcome.invariants)\t\(relative)\t\(run.start)\t\(run.end)")
}
for i in concurrent.indices {
    for j in concurrent.indices where j > i {
        if max(concurrent[i].start, concurrent[j].start) < min(concurrent[i].end, concurrent[j].end) {
            overlapPairs += 1
        }
    }
}
print("SUMMARY fixtures=\(fixtures.count) solver_calls=\(fixtures.count * 2) exact_mismatches=\(mismatches) invariant_failures=\(invariantFailures) max_relative_error=\(maxRelativeError) overlapping_task_pairs=\(overlapPairs)")
if mismatches != 0 || invariantFailures != 0 || overlapPairs == 0 { exit(1) }
