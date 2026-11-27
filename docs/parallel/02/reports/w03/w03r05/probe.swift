import Foundation
import Dispatch
import LightingCore

// This probe reads only frozen value fixtures. Each concurrent lane owns a
// distinct result slot. A slot lock covers publishing/reading only, never math.
struct Fixture: Sendable {
    let name: String
    let light: StudioLight
    let scene: LightingScene
    let directPoint: Bool

    func evaluate() -> Double? {
        if directPoint {
            guard let n = StudioPhotometry.receiverNormal(in: scene) else { return nil }
            return Photometry.pointIlluminance(candela: light.candela, source: light.position,
                                              receiver: scene.subject, receiverNormal: n)
        }
        return StudioPhotometry.illuminance(for: light, in: scene)
    }
}

final class ResultSlot: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [UInt64?] = []
    private var threadName: String = ""
    func publish(_ values: [UInt64?], thread: String) {
        lock.lock(); defer { lock.unlock() }
        stored = values
        threadName = thread
    }
    func read() -> ([UInt64?], String) {
        lock.lock(); defer { lock.unlock() }
        return (stored, threadName)
    }
}

func fixture(_ name: String, _ kind: EmitterKind = .point,
             source: Position = .init(x: 0, y: 0, z: 2),
             receiver: Position = .init(x: 0, y: 0, z: 0),
             camera: Position = .init(x: 0, y: 0, z: 3),
             cd: Double = 400, aim: Position? = nil,
             direct: Bool = false) -> Fixture {
    let light = StudioLight(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                            name: name, position: source, candela: cd, kelvin: 5600,
                            optics: .init(kind: kind, aimTarget: aim))
    let scene = LightingScene(subject: receiver, camera: camera, lights: [light])
    return Fixture(name: name, light: light, scene: scene, directPoint: direct)
}

let fixtures: [Fixture] = [
    fixture("point-direct-on-axis", direct: true),
    fixture("point-wrapper-on-axis"),
    fixture("point-direct-off-axis", source: .init(x: 1.3, y: -0.7, z: 2.1),
            camera: .init(x: 0.4, y: 0.9, z: 3.0), cd: 1379, direct: true),
    fixture("point-wrapper-off-axis", source: .init(x: -1.2, y: 0.8, z: 1.4),
            camera: .init(x: 0.2, y: 0.7, z: 2.6), cd: 731),
    fixture("point-back-facing", camera: .init(x: 0, y: 0, z: -3)),
    fixture("point-zero-output", cd: 0),
    fixture("point-tiny-output", cd: Double.leastNormalMagnitude),
    fixture("point-near-unsupported", source: .init(x: 0, y: 0, z: 0.049)),
    fixture("point-normal-unsupported", camera: .init(x: 0, y: 0, z: 0)),
    fixture("directional-on-axis", .directional),
    fixture("directional-double-cosine", .directional,
            camera: .init(x: sqrt(3.0), y: 0, z: 1),
            aim: .init(x: sqrt(3.0), y: 0, z: 1)),
    fixture("directional-off-axis", .directional,
            source: .init(x: 1.1, y: 0.6, z: 1.8),
            camera: .init(x: -0.3, y: 0.7, z: 2.8), cd: 1463,
            aim: .init(x: -0.4, y: 0.2, z: -0.1)),
    fixture("directional-vertical", .directional,
            source: .init(x: 0, y: 2, z: 0), camera: .init(x: 0, y: 3, z: 0)),
    fixture("directional-aim-away", .directional, aim: .init(x: 0, y: 0, z: 3)),
    fixture("directional-back-facing", .directional, camera: .init(x: 0, y: 0, z: -3)),
    fixture("directional-zero-output", .directional, cd: 0),
    fixture("directional-tiny-output", .directional, cd: Double.leastNormalMagnitude),
    fixture("directional-aim-unsupported", .directional, aim: .init(x: 0, y: 0, z: 2))
]
let serial = fixtures.map { $0.evaluate() }
let serialBits = serial.map { $0?.bitPattern }
let lanes = 8
let repeats = 256
let slots: [ResultSlot] = (0..<lanes).map { _ in ResultSlot() }
let start = DispatchTime.now().uptimeNanoseconds
DispatchQueue.concurrentPerform(iterations: lanes) { lane in
    var local: [UInt64?] = []
    local.reserveCapacity(repeats * fixtures.count)
    // Reverse each odd lane's fixture order to avoid relying on shared call order.
    for _ in 0..<repeats {
        for step in fixtures.indices {
            let index = lane % 2 == 0 ? step : fixtures.count - 1 - step
            local.append(fixtures[index].evaluate()?.bitPattern)
        }
    }
    slots[lane].publish(local, thread: String(describing: Thread.current))
}
let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start) / 1e9
var mismatches = 0
var compared = 0
var threadNames: Set<String> = []
for lane in 0..<lanes {
    let (values, thread) = slots[lane].read()
    threadNames.insert(thread)
    precondition(values.count == repeats * fixtures.count)
    for repeatIndex in 0..<repeats {
        for step in fixtures.indices {
            let index = lane % 2 == 0 ? step : fixtures.count - 1 - step
            let value = values[repeatIndex * fixtures.count + step]
            if value != serialBits[index] { mismatches += 1 }
            compared += 1
        }
    }
}
var reference = "fixture,api,serial_lux,ieee754_hex\n"
for index in fixtures.indices {
    let value = serial[index].map { String(format: "%.17g", $0) } ?? "nil"
    let bits = serialBits[index].map { String($0, radix: 16) } ?? "nil"
    let api = fixtures[index].directPoint ? "Photometry.pointIlluminance" : "StudioPhotometry.illuminance"
    reference += "\(fixtures[index].name),\(api),\(value),\(bits)\n"
}
try reference.write(toFile: "private-output/serial-reference.csv", atomically: true, encoding: .utf8)
print(reference, terminator: "")
print("fixtures=\(fixtures.count) lanes=\(lanes) repeats_per_lane=\(repeats) comparisons=\(compared)")
print("distinct_execution_threads=\(threadNames.count) active_processors=\(ProcessInfo.processInfo.activeProcessorCount)")
print("serial_nil=\(serial.filter { $0 == nil }.count) serial_zero=\(serial.filter { $0 == 0 }.count)")
print("exact_optional_and_ieee754_mismatches=\(mismatches)")
print("concurrent_phase_seconds=\(elapsed)")
print("result=\(mismatches == 0 ? "PASS" : "FAIL")")
precondition(mismatches == 0)
