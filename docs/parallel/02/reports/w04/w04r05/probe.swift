import Foundation
import LightingCore

// W04 R05: bounded determinism check, not a timing or accuracy benchmark.
struct Fixture: Sendable {
    let name: String
    let emitter: LambertianRectangle
    let receiver: Position
    let receiverNormal: UnitDirection
}

struct Sample: Sendable {
    let fixtureIndex: Int
    let repetition: Int
    let lux: Double?
}

func decimal(_ value: Double) -> String { String(format: "%.17g", value) }
func bits(_ value: Double) -> String { String(value.bitPattern, radix: 16) }

let standardEmitter = LambertianRectangle(
    center: Position(x: 0, y: 0, z: 0),
    right: UnitDirection(x: 1, y: 0, z: 0)!,
    up: UnitDirection(x: 0, y: 1, z: 0)!,
    widthMeters: 1, heightMeters: 0.6, onAxisCandela: 1000)!
let centeredReceiver = Position(x: 0, y: 0, z: 0.25)
let fixtures: [Fixture] = [
    Fixture(name: "strip_1mm", emitter: standardEmitter,
            receiver: centeredReceiver,
            receiverNormal: UnitDirection(x: 1, y: 0, z: 0.499 / 0.25)!),
    Fixture(name: "corner_10um", emitter: standardEmitter,
            receiver: centeredReceiver,
            receiverNormal: UnitDirection(x: 1, y: 1, z: 0.79999 / 0.25)!),
    Fixture(name: "five_vertex_face", emitter: standardEmitter,
            receiver: centeredReceiver,
            receiverNormal: UnitDirection(x: 1, y: 1, z: -0.7 / 0.25)!),
    Fixture(name: "rolled_partial", emitter: LambertianRectangle(
        center: Position(x: 0.1, y: -0.2, z: 0.05),
        right: UnitDirection(x: 0.8, y: 0.6, z: 0)!,
        up: UnitDirection(x: -0.6, y: 0.8, z: 0)!,
        widthMeters: 1.2, heightMeters: 0.8, onAxisCandela: 2500)!,
        receiver: Position(x: 0.18, y: -0.13, z: 0.65),
        receiverNormal: UnitDirection(x: 0.8, y: 0.3, z: 0.1)!)
]

// Scalar corner signs confirm every fixture crosses the receiver hemisphere.
// This classification is not an independent illuminance reference.
for fixture in fixtures {
    let e = fixture.emitter, n = fixture.receiverNormal
    let nx = e.right.x * n.x + e.right.y * n.y + e.right.z * n.z
    let ny = e.up.x * n.x + e.up.y * n.y + e.up.z * n.z
    let offset = (fixture.receiver.x - e.center.x) * n.x
        + (fixture.receiver.y - e.center.y) * n.y
        + (fixture.receiver.z - e.center.z) * n.z
    let w = e.widthMeters / 2, h = e.heightMeters / 2
    let corners: [(Double, Double)] = [(-w, -h), (w, -h), (w, h), (-w, h)]
    let incidence = corners.map { nx * $0.0 + ny * $0.1 - offset }
    precondition(incidence.min()! < 0 && incidence.max()! > 0)
    print("fixture=\(fixture.name) corner_incidence_m=\(incidence.map(decimal).joined(separator: ","))")
}

let serial: [Double] = fixtures.map { fixture in
    guard let lux = Photometry.rectangularIlluminance(
        emitter: fixture.emitter, receiver: fixture.receiver,
        receiverNormal: fixture.receiverNormal), lux.isFinite, lux > 0 else {
        fatalError("Expected finite positive serial result: \(fixture.name)")
    }
    return lux
}

let repetitions = 64
let concurrent: [Sample] = await withTaskGroup(of: Sample.self, returning: [Sample].self) { group in
    for fixtureIndex in fixtures.indices {
        let fixture = fixtures[fixtureIndex]
        for repetition in 0..<repetitions {
            group.addTask {
                Sample(fixtureIndex: fixtureIndex, repetition: repetition,
                       lux: Photometry.rectangularIlluminance(
                           emitter: fixture.emitter, receiver: fixture.receiver,
                           receiverNormal: fixture.receiverNormal))
            }
        }
    }
    // Only the parent task mutates this array; children return independent values.
    var completed: [Sample] = []
    completed.reserveCapacity(fixtures.count * repetitions)
    for await sample in group { completed.append(sample) }
    return completed
}

let ordered = concurrent.sorted {
    ($0.fixtureIndex, $0.repetition) < ($1.fixtureIndex, $1.repetition)
}
let uniqueKeys = Set(ordered.map { $0.fixtureIndex * repetitions + $0.repetition })
var rows = ["mode,fixture,repetition,lux,bit_pattern,serial_bit_pattern,bitwise_match"]
for index in fixtures.indices {
    let value = serial[index]
    rows.append("serial,\(fixtures[index].name),0,\(decimal(value)),\(bits(value)),\(bits(value)),true")
    print("serial fixture=\(fixtures[index].name) lux=\(decimal(value)) bits=\(bits(value))")
}
var mismatches = 0
var maxAbsoluteDifference = 0.0
var maxRelativeDifference = 0.0
for sample in ordered {
    let expected = serial[sample.fixtureIndex]
    let matches = sample.lux?.bitPattern == expected.bitPattern
    if !matches { mismatches += 1 }
    if let value = sample.lux, value.isFinite {
        maxAbsoluteDifference = max(maxAbsoluteDifference, abs(value - expected))
        maxRelativeDifference = max(maxRelativeDifference, abs(value - expected) / expected)
    }
    rows.append("concurrent,\(fixtures[sample.fixtureIndex].name),\(sample.repetition),\(sample.lux.map(decimal) ?? "nil"),\(sample.lux.map(bits) ?? "nil"),\(bits(expected)),\(matches)")
}
let output = "/tmp/keyfill02-r2-workers/w04r05/private-output/scalars.csv"
try (rows.joined(separator: "\n") + "\n").write(toFile: output, atomically: true, encoding: .utf8)
let expectedCount = fixtures.count * repetitions
let passed = concurrent.count == expectedCount && uniqueKeys.count == expectedCount && mismatches == 0
print("fixtures=\(fixtures.count) repeats_per_fixture=\(repetitions) concurrent_results=\(concurrent.count) unique_results=\(uniqueKeys.count) bitwise_mismatches=\(mismatches)")
print("maximum_absolute_difference_lux=\(decimal(maxAbsoluteDifference)) maximum_relative_difference=\(decimal(maxRelativeDifference))")
print("result=\(passed ? "PASS" : "FAIL") scope=host_scalar_concurrency_determinism_only")
if !passed { exit(1) }
