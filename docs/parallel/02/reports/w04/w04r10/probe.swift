import Foundation
import LightingCore

let center: Position = .init(x: -0.80000000000000004, y: 1.1000000000000001, z: 0.40000000000000002)
let receiver: Position = .init(x: -0.81629242770760213, y: 0.88967987067474374, z: 0.80500000000000005)
guard let frame = EmitterFrame(source: center,
    target: .init(x: -0.80000000000000004, y: 1.1000000000000001, z: 2.3999999999999999),
    rollDegrees: -63),
    let emitter = LambertianRectangle(center: center, right: frame.right, up: frame.up,
        widthMeters: 1.6000000000000001, heightMeters: 0.90000000000000002, onAxisCandela: 1375),
    let normal = UnitDirection(x: -0.036063088564055545, y: -1.1407012990451186, z: 1.1839506172839507),
    let actual = Photometry.rectangularIlluminance(emitter: emitter,
        receiver: receiver, receiverNormal: normal)
else { fatalError("Fixture must be supported") }
let expected = 10.232645081164865
let relativeError = abs(actual - expected) / expected
let output: [String: Any] = [
    "fixture": "minus63_roll_triangular_grazing_corner",
    "execution": "actual frozen LightingCore v1 Swift standalone probe",
    "actual_lux": actual,
    "independent_reference_lux": expected,
    "absolute_error_lux": abs(actual - expected),
    "relative_error": relativeError,
    "relative_error_percent": relativeError * 100,
    "area_gate_unchanged": 0.05,
    "passes_area_gate": actual.isFinite && relativeError <= 0.05,
    "frame_right": [frame.right.x, frame.right.y, frame.right.z],
    "frame_up": [frame.up.x, frame.up.y, frame.up.z]
]
let data = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys, .prettyPrinted])
print(String(decoding: data, as: UTF8.self))
precondition(actual.isFinite && relativeError <= 0.05, "Unchanged 5% area-model gate")
