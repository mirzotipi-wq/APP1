import Foundation
import LightingCore

// Exactly one fixture. Expected values below never call any LightingCore helper.
let source = Position(x: 1.25, y: -0.75, z: 2.5)
let receiver = Position(x: -0.5, y: 1, z: -0.25)
let camera = Position(x: 2.5, y: 2, z: 1.75)
let manualTarget = Position(x: 0.25, y: 2.25, z: 1.5)
let light = StudioLight(name: "Independent scalar fixture", position: source,
                        candela: 1739, kelvin: 5600,
                        optics: .init(kind: .directional, aimTarget: manualTarget))
let scene = LightingScene(subject: receiver, camera: camera, lights: [light])
_ = try scene.validated()

// Receiver-to-source d=(7,-7,11)/4; emitter aim e=(-1,3,-1);
// receiver normal raw n=(3,1,2). These integer dot products are independent.
let rSquared: Double = (7.0 * 7 + (-7.0) * (-7) + 11.0 * 11) / 16
let emitterRawSquared: Double = (-1.0) * (-1) + 3.0 * 3 + (-1.0) * (-1)
let receiverRawSquared: Double = 3.0 * 3 + 1.0 * 1 + 2.0 * 2
let emitterDotToReceiver: Double = ((-1.0) * (-7) + 3.0 * 7 + (-1.0) * (-11)) / 4
let receiverDotToSource: Double = (3.0 * 7 + 1.0 * (-7) + 2.0 * 11) / 4
let emitterCosine = emitterDotToReceiver / sqrt(emitterRawSquared * rSquared)
let receiverCosine = receiverDotToSource / sqrt(receiverRawSquared * rSquared)
let independentLux = 1739.0 * emitterCosine * receiverCosine / rSquared
guard let actualLux = StudioPhotometry.illuminance(for: light, in: scene) else {
    fatalError("Supported independent fixture unexpectedly returned nil")
}
let relativeError = abs(actualLux - independentLux) / independentLux
let output: [String: Any] = [
    "source_revision": "1b286885cb803ba17e159713651515ab119e17f1",
    "snapshot": "v1", "fixture_count": 1,
    "r_squared_m2": rSquared,
    "emitter_dot_m2": emitterDotToReceiver,
    "receiver_dot_m2": receiverDotToSource,
    "emitter_cosine": emitterCosine, "receiver_cosine": receiverCosine,
    "inverse_square_m_minus2": 1 / rSquared,
    "independent_double_lux": independentLux, "actual_lux": actualLux,
    "relative_error": relativeError, "point_gate_fraction": 0.01,
    "passes_point_gate": relativeError <= 0.01
]
let data = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
print(String(data: data, encoding: .utf8)!)
precondition(relativeError <= 0.01, "Point-model error exceeds unchanged 1% gate")
