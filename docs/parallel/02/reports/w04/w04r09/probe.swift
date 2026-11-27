import Foundation
import Dispatch
import LightingCore

// W04R09: exactly one batch of 100 calls for each of three paths.
// Construction, classification, finite checks, and reporting are outside timing.
let count = 100
let sourceCommit = "1b286885cb803ba17e159713651515ab119e17f1"
let worktreeHead = "47de6afe6afe24a7822f4276950f70bd3db9f57d"
struct Fixture {
    let path: String
    let light: StudioLight
    let scene: LightingScene
    let partial: Bool
    let scaled: Bool
}
func fixture(_ path: String, partial: Bool, intensity: Double, scaled: Bool) -> Fixture {
    let light = StudioLight(name: path, position: .init(x: 0, y: 0, z: 0),
        candela: intensity, kelvin: 5600,
        optics: .init(kind: .rectangle, widthMeters: 1, heightMeters: 1))
    let scene = LightingScene(subject: .init(x: 0, y: 0, z: 2),
        camera: partial ? .init(x: 1, y: 0, z: 2) : .init(x: 0, y: 0, z: 1), lights: [light])
    return Fixture(path: path, light: light, scene: scene, partial: partial, scaled: scaled)
}
let fixtures = [
    fixture("full_rectangle", partial: false, intensity: 1000, scaled: false),
    fixture("partially_clipped_rectangle", partial: true, intensity: 1000, scaled: false),
    fixture("scaled_tiny_clipped_rectangle", partial: true, intensity: Double.leastNormalMagnitude, scaled: true)
]
func preflight(_ f: Fixture) throws {
    _ = try f.scene.validated()
    guard let n = StudioPhotometry.receiverNormal(in: f.scene),
          let frame = StudioPhotometry.frame(for: f.light, subject: f.scene.subject) else {
        fatalError("invalid orientation")
    }
    let corners = [(-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)]
    let incidence = corners.map { x, y in
        n.x * (frame.right.x * x + frame.up.x * y) +
        n.y * (frame.right.y * x + frame.up.y * y) +
        n.z * (frame.right.z * x + frame.up.z * y - 2)
    }
    precondition(incidence.allSatisfy { $0.isFinite })
    precondition(2 * frame.normal.z >= 0.25)
    if f.partial { precondition(incidence.min()! < 0 && incidence.max()! > 0) }
    else { precondition(incidence.allSatisfy { $0 > 0 }) }
    let threshold = Double.leastNormalMagnitude * 1024
    precondition((f.light.candela < threshold) == f.scaled)
    print("INPUT path=\(f.path) source_m=(0,0,0) receiver_m=(0,0,2) camera_m=(\(f.scene.camera.x),\(f.scene.camera.y),\(f.scene.camera.z)) normal=(\(n.x),\(n.y),\(n.z)) dimensions_m=(1,1) candela=\(f.light.candela) roll=0")
    print("CLASSIFICATION path=\(f.path) depth_m=2 minimum_depth_m=0.25 corner_incidence_m=\(incidence) geometry=\(f.partial ? "partial_half_face_2_triangles" : "full_face_32x32") intensity=\(f.scaled ? "unit_scaling_then_partial_integration" : "ordinary") scaling_threshold_cd=\(threshold)")
}
@inline(never)
func measure(_ f: Fixture) -> (row: [String: Any], lux: Double) {
    var values = [Double?]()
    values.reserveCapacity(count)
    let start = DispatchTime.now().uptimeNanoseconds
    for _ in 0..<count {
        values.append(StudioPhotometry.illuminance(for: f.light, in: f.scene))
    }
    let end = DispatchTime.now().uptimeNanoseconds
    // All validity/classification work follows the stop timestamp.
    let results = values.compactMap { $0 }
    precondition(results.count == count)
    precondition(results.allSatisfy { $0.isFinite && $0 > 0 })
    let first = results[0]
    precondition(results.allSatisfy { $0.bitPattern == first.bitPattern })
    precondition(first.isSubnormal == f.scaled)
    let elapsed = end - start
    print("RESULT path=\(f.path) calls=\(count) finite_positive=\(results.count) deterministic=true classification=\(first.isSubnormal ? "subnormal" : "normal") total_ns=\(elapsed) mean_ns_per_call=\(Double(elapsed)/Double(count)) lux=\(first)")
    return (["path": f.path, "calls": count, "start_uptime_ns": start, "end_uptime_ns": end,
             "total_ns": elapsed, "mean_ns_per_call": Double(elapsed) / Double(count),
             "all_finite_positive": true, "bitwise_deterministic": true,
             "result_classification": first.isSubnormal ? "subnormal" : "normal",
             "intensity_cd": f.light.candela, "raw_lux": results], first)
}
print("W04R09 snapshot=v1 module_revision=\(sourceCommit) worktree_head=\(worktreeHead) compiler=Swift6.0.3 target=x86_64-unknown-linux-gnu module_configuration=Debug probe_configuration=swiftc_without_O")
print("OS \(ProcessInfo.processInfo.operatingSystemVersionString)")
print("METHOD one batch per path, exactly 100 calls each, no warmup, DispatchTime monotonic clock; loop and array append included; construction/classification/validation excluded")
for f in fixtures { try preflight(f) }
let measured = fixtures.map(measure)
let ordinaryCoefficient = measured[1].lux / 1000
let scaledExpected = ordinaryCoefficient * Double.leastNormalMagnitude
let actualTiny = measured[2].lux
let ulpDistance = actualTiny.bitPattern > scaledExpected.bitPattern
    ? actualTiny.bitPattern - scaledExpected.bitPattern
    : scaledExpected.bitPattern - actualTiny.bitPattern
precondition(ulpDistance <= 2, "tiny/ordinary intensity proportionality")
print("CHECK ordinary_partial_coefficient=\(ordinaryCoefficient) expected_tiny_lux=\(scaledExpected) actual_tiny_lux=\(actualTiny) ulp_distance=\(ulpDistance); proportionality consistency only, not an independent area-accuracy reference")
let document: [String: Any] = [
    "task": "W04R09", "snapshot": "v1", "module_revision": sourceCommit,
    "worktree_head": worktreeHead, "module_configuration": "Debug (coordinator supplied)",
    "probe_configuration": "swiftc without -O", "compiler": "Swift 6.0.3",
    "platform": "x86_64-unknown-linux-gnu", "os": ProcessInfo.processInfo.operatingSystemVersionString,
    "method": "One batch, 100 calls per path, no warmup; loop/append included; setup/validation excluded",
    "measurements": measured.map { $0.row },
    "tiny_expected_from_ordinary_lux": scaledExpected,
    "tiny_scaling_ulp_distance": ulpDistance,
    "limitations": "Unoptimized host diagnostic only; no performance threshold, device, calibration or area-accuracy claim; 1% point and 5% area gates unchanged"
]
let data = try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
let executable = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
try data.write(to: executable.deletingLastPathComponent().appendingPathComponent("raw-results.json"))
print("PASS 300/300 finite positive bitwise-deterministic results; normal/normal/subnormal classifications; no performance threshold")
