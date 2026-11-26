import Foundation
import LightingCore

// W04 R02: one bounded invariance probe, two fixed receiver orientations.
// For the same physical face, roll+90 with width/height exchanged maps
// (right, up) to (up, -right); roll+180 reverses both in-plane axes.
let center = Position(x: 0.4, y: 1.5, z: -0.3)
let target = Position(x: 2.4, y: 4.5, z: 5.7)
let receiver = Position(x: 0.754342288931758,
                        y: 1.752115732184385, z: 0.1558280375972214)
let fixtures: [(String, UnitDirection)] = [
    ("full", UnitDirection(x: -2, y: -3, z: -6)!),
    ("partial", UnitDirection(x: 0.4557804691331652,
                              y: 0.8127556480146011, z: -0.362894503371321)!)
]
let variants: [(String, Double, Double, Double)] = [
    ("base", 37, 1.2, 0.6),
    ("roll90_swap", 127, 0.6, 1.2),
    ("roll180", -143, 1.2, 0.6)
]
func format(_ value: Double) -> String { String(format: "%.17g", value) }
var maxRelativeDelta = 0.0
var rows: [[String: Any]] = []
for (name, normal) in fixtures {
    var baseline = 0.0
    for (variant, roll, width, height) in variants {
        guard let frame = EmitterFrame(source: center, target: target, rollDegrees: roll),
              let emitter = LambertianRectangle(center: center, right: frame.right, up: frame.up,
                                                widthMeters: width, heightMeters: height,
                                                onAxisCandela: 1000),
              let lux = Photometry.rectangularIlluminance(emitter: emitter, receiver: receiver,
                                                         receiverNormal: normal),
              lux.isFinite, lux > 0 else { fatalError("Unsupported fixture: \(name) \(variant)") }
        if variant == "base" { baseline = lux }
        let absoluteDelta = abs(lux - baseline)
        let relativeDelta = absoluteDelta / baseline
        maxRelativeDelta = max(maxRelativeDelta, relativeDelta)
        var incidence: [Double] = []
        for x in [-width / 2, width / 2] {
            for y in [-height / 2, height / 2] {
                incidence.append((center.x + frame.right.x * x + frame.up.x * y - receiver.x) * normal.x
                    + (center.y + frame.right.y * x + frame.up.y * y - receiver.y) * normal.y
                    + (center.z + frame.right.z * x + frame.up.z * y - receiver.z) * normal.z)
            }
        }
        let minimum = incidence.min()!, maximum = incidence.max()!
        precondition(name == "full" ? minimum > 0 : (minimum < 0 && maximum > 0))
        precondition(relativeDelta <= 0.05, "Unchanged area-model gate")
        print("\(name),\(variant),roll=\(format(roll)),width=\(format(width)),height=\(format(height)),lux=\(format(lux)),abs_delta=\(format(absoluteDelta)),rel_delta=\(format(relativeDelta)),incidence_min=\(format(minimum)),incidence_max=\(format(maximum))")
        rows.append(["fixture": name, "variant": variant, "roll_degrees": roll,
                     "width_m": width, "height_m": height, "lux": lux,
                     "absolute_delta_lux": absoluteDelta, "relative_delta": relativeDelta,
                     "corner_incidence_min": minimum, "corner_incidence_max": maximum])
    }
}
let evidence: [String: Any] = [
    "snapshot": "v1", "source_sha": "1b286885cb803ba17e159713651515ab119e17f1",
    "center_m": [center.x, center.y, center.z], "target_m": [target.x, target.y, target.z],
    "receiver_m": [receiver.x, receiver.y, receiver.z], "candela": 1000,
    "area_gate_relative": 0.05, "point_gate_relative_unchanged": 0.01,
    "max_relative_delta": maxRelativeDelta, "rows": rows
]
let path = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    .appendingPathComponent("scalars.json")
try JSONSerialization.data(withJSONObject: evidence, options: [.prettyPrinted, .sortedKeys]).write(to: path)
print("PASS six evaluations; max_relative_delta=\(format(maxRelativeDelta)); area_gate=0.05; point_gate=0.01 unchanged, not exercised")
