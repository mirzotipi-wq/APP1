import Foundation
import LightingCore

// W02R07: exactly two ordinary fixtures; one receiver, one normal, no geometry.
let receiver = Position(x: 0.15, y: 1.2, z: -0.2)
let camera = Position(x: 0.75, y: 0.9, z: 2.8)
let fixtures: [(String, StudioLight)] = [
    ("ordinary_directional", StudioLight(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000071")!,
        name: "W02R07 directional", position: .init(x: 1.1, y: 2.0, z: 2.4),
        candela: 1375, kelvin: 5600,
        optics: .init(kind: .directional, aimTarget: .init(x: 0.45, y: 1.0, z: -0.2)))),
    ("ordinary_rolled_rectangle", StudioLight(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000072")!,
        name: "W02R07 rectangle", position: .init(x: -0.65, y: 2.15, z: 2.2),
        candela: 900, kelvin: 5600,
        optics: .init(kind: .rectangle, widthMeters: 0.9, heightMeters: 0.6,
                      rollDegrees: 37)))
]

func position(_ p: Position) -> [Double] { [p.x, p.y, p.z] }
func direction(_ n: UnitDirection) -> [Double] { [n.x, n.y, n.z] }
func dot(_ a: [Double], _ b: [Double]) -> Double {
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

let relativeTolerance = 1e-12
var rows: [[String: Any]] = []
var passed = true
for (name, light) in fixtures {
    let scene = LightingScene(subject: receiver, camera: camera, lights: [light])
    guard let normal = StudioPhotometry.receiverNormal(in: scene),
          let meter = StudioPhotometry.illuminance(for: light, in: scene),
          let frame = StudioPhotometry.frame(for: light, subject: receiver) else {
        fatalError("Ordinary fixture unexpectedly unsupported: \(name)")
    }
    let study = try StudyLighting(scene: scene, quality: .reference)
    let surface = try study.evaluate(receiver: receiver, normal: normal, view: normal,
                                     material: .diffuse(reflectance: 1), geometry: nil)
    let absoluteError = abs(meter - surface.unoccludedLux)
    let relativeError = absoluteError / meter
    let expectedSamples = light.effectiveOptics.kind == .rectangle ? 1024 : 1
    var row: [String: Any] = [
        "fixture": name, "kind": light.effectiveOptics.kind.rawValue,
        "source_m": position(light.position), "target_m": position(light.target(subject: receiver)),
        "candela": light.candela, "kelvin": light.kelvin,
        "receiver_m": position(receiver), "camera_m": position(camera),
        "receiver_normal": direction(normal), "view": direction(normal),
        "emitter_normal": direction(frame.normal), "study_quality": "reference",
        "geometry": "nil", "material": "diffuse reflectance=1",
        "study_sample_count": study.sampleCount, "meter_lux": meter,
        "study_unoccluded_lux": surface.unoccludedLux,
        "absolute_error_lux": absoluteError, "relative_error": relativeError,
        "relative_tolerance": relativeTolerance
    ]
    var ordinaryDomain = meter.isFinite && meter > 0 && surface.unoccludedLux.isFinite
    if light.effectiveOptics.kind == .rectangle {
        let optics = light.effectiveOptics
        let delta = [light.position.x - receiver.x, light.position.y - receiver.y,
                     light.position.z - receiver.z]
        let centerProjection = dot(direction(normal), delta)
        let xProjection = dot(direction(normal), direction(frame.right)) * optics.widthMeters / 2
        let yProjection = dot(direction(normal), direction(frame.up)) * optics.heightMeters / 2
        let minimumCornerProjection = centerProjection - abs(xProjection) - abs(yProjection)
        let emitterDepth = -dot(delta, direction(frame.normal))
        let minimumDepth = max(0.05, max(optics.widthMeters, optics.heightMeters) / 4)
        ordinaryDomain = ordinaryDomain && minimumCornerProjection > 0 && emitterDepth > minimumDepth
        row["width_m"] = optics.widthMeters
        row["height_m"] = optics.heightMeters
        row["roll_degrees"] = optics.effectiveRollDegrees
        row["minimum_corner_receiver_projection_m"] = minimumCornerProjection
        row["emitter_depth_m"] = emitterDepth
        row["minimum_supported_depth_m"] = minimumDepth
        row["entire_face_in_front_hemisphere"] = minimumCornerProjection > 0
    }
    let fixturePassed = ordinaryDomain && study.sampleCount == expectedSamples && relativeError <= relativeTolerance
    row["passed"] = fixturePassed
    rows.append(row)
    passed = passed && fixturePassed
}
let result: [String: Any] = [
    "role": "W02R07", "source_sha": "f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b",
    "fixture_count": rows.count, "passed": passed, "fixtures": rows,
    "limitation": "Ordinary unoccluded CPU samples only. Partial-face/grazing meter clipping and Study sampled rendering can differ; this probe makes no grazing, shadow, frame, GPU/device, or physical-calibration claim."
]
let json = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
print(String(data: json, encoding: .utf8)!)
exit(passed ? 0 : 1)
