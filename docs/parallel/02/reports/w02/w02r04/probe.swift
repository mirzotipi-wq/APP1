import Foundation
import LightingCore

let center = Position(x: 0.4, y: 1.5, z: -0.3)
guard let frame = EmitterFrame(
    source: center, target: .init(x: 2.4, y: 4.5, z: 5.7), rollDegrees: 37),
    let emitter = LambertianRectangle(
        center: center, right: frame.right, up: frame.up,
        widthMeters: 1.2, heightMeters: 0.6, onAxisCandela: 1000),
    let receiverNormal = UnitDirection(
        x: 0.4557804691331652, y: 0.8127556480146011, z: -0.362894503371321)
else { fatalError("Fixture construction failed") }
let receiver = Position(
    x: 0.754342288931758, y: 1.752115732184385, z: 0.1558280375972214)
guard let actual = Photometry.rectangularIlluminance(
    emitter: emitter, receiver: receiver, receiverNormal: receiverNormal)
else { fatalError("Supported fixture returned nil") }
let expectedLux = 133.78670191052524
let relativeError = abs(actual - expectedLux) / expectedLux
precondition(relativeError <= 0.05, "Unchanged area-model contract")
precondition(relativeError <= 1e-6, "Rolled partial-face reference")
let result: [String: Any] = [
    "snapshot_sha": "f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b",
    "execution": "Standalone expressions against frozen LightingCore v1; candidate XCTest not package-executed",
    "fixture": "37-degree rolled oblique partial face, 1.2 by 0.6 m, 0.6 m depth, 1000 cd",
    "actual_lux": actual,
    "independent_reference_lux": expectedLux,
    "relative_error": relativeError,
    "area_contract_relative_tolerance": 0.05,
    "fixture_relative_tolerance": 1e-6,
    "status": "pass"
]
let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: data, as: UTF8.self))
