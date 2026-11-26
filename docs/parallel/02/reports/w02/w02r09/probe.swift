import Foundation
import Dispatch
import LightingCore

// W02R09: one diagnostic batch; exactly 100 photometry calls per fixture.
// Fixture construction, branch/domain checks, and reporting are outside timing.
let count = 100
let origin = Position(x: 0, y: 0, z: 0)
let receiver = Position(x: 0, y: 0, z: 2)
let forwardCamera = Position(x: 0, y: 0, z: 1)

struct Fixture {
    let label: String
    let light: StudioLight
    let scene: LightingScene
    let expectedScalar: Double?
}

func fixture(_ label: String, kind: EmitterKind, camera: Position,
             aim: Position? = nil, expected: Double? = nil) -> Fixture {
    let light = StudioLight(name: label, position: origin, candela: 1_000, kelvin: 5_600,
        optics: LightOptics(kind: kind, aimTarget: aim, widthMeters: 1, heightMeters: 1))
    let scene = LightingScene(subject: receiver, camera: camera, lights: [light])
    return Fixture(label: label, light: light, scene: scene, expectedScalar: expected)
}

let fixtures = [
    fixture("point", kind: .point, camera: forwardCamera, expected: 250),
    fixture("directional", kind: .directional, camera: forwardCamera,
            aim: Position(x: 1, y: 0, z: 1), expected: 250 / sqrt(2)),
    fixture("full_rectangle", kind: .rectangle, camera: forwardCamera),
    fixture("clipped_rectangle", kind: .rectangle, camera: Position(x: 1, y: 0, z: 2))
]

func dot(_ a: UnitDirection, _ x: Double, _ y: Double, _ z: Double) -> Double {
    a.x * x + a.y * y + a.z * z
}

func preflight(_ f: Fixture) throws {
    _ = try f.scene.validated()
    guard let n = StudioPhotometry.receiverNormal(in: f.scene) else {
        fatalError("Missing receiver normal: \(f.label)")
    }
    print("INPUT path=\(f.label) source_m=(0,0,0) receiver_m=(0,0,2) camera_m=(\(f.scene.camera.x),\(f.scene.camera.y),\(f.scene.camera.z)) normal=(\(n.x),\(n.y),\(n.z)) candela=1000 kelvin=5600")
    precondition(f.light.position.distance(to: f.scene.subject) == 2)
    if f.light.effectiveOptics.kind == .directional {
        guard let frame = StudioPhotometry.frame(for: f.light, subject: f.scene.subject) else {
            fatalError("Missing directional frame")
        }
        print("DOMAIN path=directional aim_m=(1,0,1) emission_cosine=\(frame.normal.z) distance_m=2 minimum_distance_m=0.05")
    } else if f.light.effectiveOptics.kind == .rectangle {
        guard let frame = StudioPhotometry.frame(for: f.light, subject: f.scene.subject) else {
            fatalError("Missing rectangle frame")
        }
        let offsets = [(-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)]
        let incidence = offsets.map { x, y in
            dot(n, frame.right.x * x + frame.up.x * y,
                   frame.right.y * x + frame.up.y * y,
                   frame.right.z * x + frame.up.z * y - 2)
        }
        let lo = incidence.min()!, hi = incidence.max()!
        let depth = 2 * frame.normal.z
        precondition(depth >= max(0.05, 1.0 / 4))
        if f.label == "full_rectangle" {
            precondition(lo > 0)
        } else {
            precondition(lo < 0 && hi > 0)
        }
        print("DOMAIN path=\(f.label) width_m=1 height_m=1 emitter_normal=(\(frame.normal.x),\(frame.normal.y),\(frame.normal.z)) depth_m=\(depth) minimum_depth_m=0.25 corner_incidence_m=\(incidence) branch=\(f.label == "full_rectangle" ? "32x32_midpoint" : "clipped_half_face_2_triangles_288_nodes")")
    } else {
        print("DOMAIN path=point distance_m=2 minimum_distance_m=0.05")
    }
}

@inline(never)
func measure(_ f: Fixture) -> [String: Any] {
    var values = [Double?]()
    values.reserveCapacity(count)
    let start = DispatchTime.now().uptimeNanoseconds
    for _ in 0..<count {
        values.append(StudioPhotometry.illuminance(for: f.light, in: f.scene))
    }
    let elapsed = DispatchTime.now().uptimeNanoseconds - start
    let finite = values.compactMap { $0 }.filter { $0.isFinite }
    precondition(finite.count == count, "Nil/nonfinite result: \(f.label)")
    precondition(finite.allSatisfy { $0 >= 0 }, "Negative lux: \(f.label)")
    let lo = finite.min()!, hi = finite.max()!
    precondition(lo == hi, "Nondeterministic result: \(f.label)")
    var row: [String: Any] = [
        "path": f.label, "calls": count, "finite_nonnegative": finite.count,
        "total_ns": elapsed, "mean_ns_per_call": Double(elapsed) / Double(count),
        "minimum_lux": lo, "maximum_lux": hi, "checksum_lux": finite.reduce(0, +)
    ]
    if let expected = f.expectedScalar {
        let relativeError = abs(lo - expected) / expected
        precondition(relativeError <= 0.01, "Point/directional analytic 1% gate")
        row["analytic_reference_lux"] = expected
        row["relative_error"] = relativeError
    }
    print("RESULT path=\(f.label) calls=\(count) finite_nonnegative=\(finite.count) total_ns=\(elapsed) mean_ns_per_call=\(Double(elapsed) / Double(count)) min_lux=\(lo) max_lux=\(hi) checksum_lux=\(finite.reduce(0, +))")
    if let expected = f.expectedScalar {
        print("REFERENCE path=\(f.label) analytic_lux=\(expected) relative_error=\(abs(lo - expected) / expected)")
    }
    return row
}

print("W02R09 source=1b286885cb803ba17e159713651515ab119e17f1 snapshot=v1 platform=x86_64-unknown-linux-gnu swift=6.0.3 module=Debug probe=swiftc_without_O")
print("OS \(ProcessInfo.processInfo.operatingSystemVersionString)")
print("METHOD one batch per path; 100 calls each; no warmup; DispatchTime monotonic batch clock; result-array append overhead included; setup and validation excluded")
print("SUPPORTED_DOMAIN finite position coordinates [-100,100] m; candela [0,100000]; point distance >=0.05 m; rectangle dimensions [0.05,4] m; rectangle abs(plane_depth)>=max(0.05,longest_side/4); normalized finite receiver normals")
for f in fixtures { try preflight(f) }
let measurements = fixtures.map(measure)
let document: [String: Any] = [
    "task": "W02R09", "source_commit": "1b286885cb803ba17e159713651515ab119e17f1",
    "snapshot": "v1", "scope": "Single Debug Linux host diagnostic, not optimized/device performance or calibration evidence",
    "method": "100 calls per path, no warmup; includes loop and result append overhead; setup and validation excluded",
    "measurements": measurements,
    "area_accuracy": "Not measured by this timing probe; existing 5% area gate unchanged"
]
let data = try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
let executable = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
try data.write(to: executable.deletingLastPathComponent().appendingPathComponent("scalar-results.json"))
print("PASS calls=400 finite_nonnegative=400; no performance threshold applied; existing 1% point/5% area requirements unchanged")
