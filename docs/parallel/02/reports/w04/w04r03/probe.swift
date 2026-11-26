import Foundation
import LightingCore

// W04 R03: fixed exact-separation boundary matrix, independent scalar oracle.
let right = UnitDirection(x: 1, y: 0, z: 0)!
let up = UnitDirection(x: 0, y: 1, z: 0)!
let origin = Position(x: 0, y: 0, z: 0)
var failures = 0
var count = 0
var nilCount = 0
var zeroCount = 0
var positiveCount = 0
var maximumAreaError = 0.0
func decimal(_ value: Double) -> String { String(format: "%.17g", value) }
print("size_m\tminimum_depth_m\tboundary\temitter_side\treceiver_facing\tdepth_m\texpected\tactual_lux\treference_lux\trelative_error\tpass")
for size in [0.1, 1.0] {
    let minimum = size == 0.1 ? 0.05 : 0.25
    let emitter = LambertianRectangle(center: origin, right: right, up: up,
        widthMeters: size, heightMeters: size, onAxisCandela: 1000)!
    let depths = [("below", minimum.nextDown), ("exact", minimum), ("above", minimum.nextUp)]
    for (boundary, depth) in depths {
        for side in [1.0, -1.0] {
            for facingToward in [true, false] {
                let normalZ = facingToward ? -side : side
                let normal = UnitDirection(x: 0, y: 0, z: normalZ)!
                let actual = Photometry.rectangularIlluminance(emitter: emitter,
                    receiver: Position(x: 0, y: 0, z: side * depth), receiverNormal: normal)
                let expected: String
                let reference: Double?
                if boundary == "below" {
                    expected = "nil"; reference = nil; nilCount += 1
                } else if side < 0 || !facingToward {
                    expected = "zero"; reference = 0; zeroCount += 1
                } else {
                    expected = "positive"; positiveCount += 1
                    // Exact centered-square projected-solid-angle antiderivative.
                    // E = I / a^2 * a/sqrt(a^2+d^2) * atan(a/sqrt(a^2+d^2)).
                    let a = size / 2
                    let h = sqrt(a * a + depth * depth)
                    reference = 1000 / (a * a) * a / h * atan(a / h)
                }
                var error: Double? = nil
                let passed: Bool
                if expected == "nil" {
                    passed = actual == nil
                } else if expected == "zero" {
                    passed = actual == 0
                } else if let actual, let reference {
                    error = abs(actual / reference - 1)
                    maximumAreaError = max(maximumAreaError, error!)
                    passed = actual.isFinite && actual > 0 && error! <= 0.05
                } else {
                    passed = false
                }
                count += 1
                if !passed { failures += 1 }
                let fields = [decimal(size), decimal(minimum), boundary,
                    side > 0 ? "front" : "back", facingToward ? "toward" : "away",
                    decimal(side * depth), expected, actual.map(decimal) ?? "nil",
                    reference.map(decimal) ?? "n/a", error.map(decimal) ?? "n/a", String(passed)]
                print(fields.joined(separator: "\t"))
            }
        }
    }
}
print("SUMMARY cases=\(count) nil=\(nilCount) zero=\(zeroCount) positive=\(positiveCount) failures=\(failures) max_area_relative_error=\(decimal(maximumAreaError)) area_gate=0.05 point_gate_unchanged=0.01")
if failures > 0 { exit(1) }
