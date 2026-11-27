import Foundation
import LightingCore

// One bounded classification table. Expected classes follow the public API
// validation order; the two point equations below are independent scalar values.
struct CaseRow {
    let name: String
    let target: Double
    let source: StudioLight
    let scene: LightingScene
    let expected: String
    let expectedCandela: Double?
}

let origin = Position(x: 0, y: 0, z: 0)
let source = StudioLight(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
    name: "Classification source", position: Position(x: 0, y: 0, z: 2),
    candela: 100, kelvin: 5600)
let scene = LightingScene(subject: origin, camera: Position(x: 0, y: 0, z: 3), lights: [])
var badSource = source
badSource.candela = -1
var badOptics = source
badOptics.optics = LightOptics(kind: .point, widthMeters: 0.01)
var badScene = scene
badScene.subject.x = 101
var badSchema = scene
badSchema.schemaVersion = 6
var badSceneLight = scene
badSceneLight.lights = [badSource]
var duplicateScene = scene
duplicateScene.lights = [source, source]
var coincidentCamera = scene
coincidentCamera.camera = origin
var tooClose = source
tooClose.position.z = 0.049
var behindReceiver = source
behindReceiver.position.z = -2
var degenerateAim = source
degenerateAim.optics = LightOptics(kind: .directional, aimTarget: source.position)
var nearRectangle = source
nearRectangle.position.z = 0.1
nearRectangle.optics = LightOptics(kind: .rectangle, widthMeters: 0.6, heightMeters: 0.9)
var atFiveCentimeters = source
atFiveCentimeters.position.z = 0.05
var offSource = source
offSource.candela = 0

func row(_ name: String, _ target: Double, _ light: StudioLight = source,
         _ fixture: LightingScene = scene, _ expected: String,
         _ expectedCandela: Double? = nil) -> CaseRow {
    CaseRow(name: name, target: target, source: light, scene: fixture,
            expected: expected, expectedCandela: expectedCandela)
}

let rows: [CaseRow] = [
    row("target_negative", -1, source, scene, "invalidTargetLux"),
    row("target_nan", .nan, source, scene, "invalidTargetLux"),
    row("target_positive_infinity", .infinity, source, scene, "invalidTargetLux"),
    row("target_negative_infinity", -.infinity, source, scene, "invalidTargetLux"),
    row("target_precedes_invalid_source_and_scene", -1, badSource, badScene, "invalidTargetLux"),
    row("source_negative_candela", 1, badSource, scene, "invalidLight"),
    row("source_invalid_optical_dimensions", 1, badOptics, scene, "invalidLight"),
    row("source_precedes_invalid_scene", 1, badSource, badScene, "invalidLight"),
    row("scene_invalid_subject", 1, source, badScene, "unsupportedGeometry"),
    row("scene_unsupported_schema", 1, source, badSchema, "unsupportedGeometry"),
    row("scene_unrelated_invalid_light", 1, source, badSceneLight, "unsupportedGeometry"),
    row("scene_duplicate_light_ids", 1, source, duplicateScene, "unsupportedGeometry"),
    row("geometry_coincident_camera_subject", 1, source, coincidentCamera, "unsupportedGeometry"),
    row("geometry_point_below_5cm", 1, tooClose, scene, "unsupportedGeometry"),
    row("geometry_receiver_back_facing_zero", 1, behindReceiver, scene, "unsupportedGeometry"),
    row("geometry_directional_degenerate_aim", 1, degenerateAim, scene, "unsupportedGeometry"),
    row("geometry_rectangle_below_plane_limit", 1, nearRectangle, scene, "unsupportedGeometry"),
    row("zero_bypasses_photometric_geometry", 0, source, coincidentCamera, "success", 0),
    row("zero_does_not_bypass_scene_validation", 0, source, badScene, "unsupportedGeometry"),
    row("zero_does_not_bypass_source_validation", 0, badSource, scene, "invalidLight"),
    // E = I / 2^2. The exact 100,000 cd ceiling produces exactly 25,000 lx.
    row("range_above_analytic_point_maximum", Double(25_000).nextUp, source, scene, "outputOutOfRange"),
    // E/I approximately 400 at 5 cm; leastNonzeroMagnitude / 400 rounds to zero.
    row("range_unrepresentable_positive_candela", .leastNonzeroMagnitude, atFiveCentimeters, scene, "outputOutOfRange"),
    row("ordinary_attainable_point", 250, source, scene, "success", 1_000),
    row("off_source_attainable_positive_target", 2.5, offSource, scene, "success", 10)
]

func number(_ value: Double?) -> String {
    guard let value else { return "nil" }
    return String(format: "%.17g", value)
}

var failures = 0
var counts: [String: Int] = [:]
print("case\ttarget_lux\tsource_valid\tscene_valid\tunit_lux\texpected\tactual\toutput_cd\tachieved_lux\trelative_error\tpass")
for entry in rows {
    let sceneValid = (try? entry.scene.validated()) != nil
    var unit = entry.source
    unit.candela = 1
    let unitValue = entry.source.isValid && sceneValid
        ? number(StudioPhotometry.illuminance(for: unit, in: entry.scene)) : "not_sampled"
    var actual = "unknown"
    var output: Double? = nil
    var achieved: Double? = nil
    var relativeError: Double? = nil
    var validSuccess = true
    do {
        let adjusted = try LightOutputAdjustment.light(entry.source, targetingLux: entry.target, in: entry.scene)
        actual = "success"
        output = adjusted.candela
        achieved = StudioPhotometry.illuminance(for: adjusted, in: entry.scene)
        validSuccess = adjusted.isValid && entry.expectedCandela == adjusted.candela
        if entry.target > 0 {
            if let achieved {
                relativeError = abs(achieved / entry.target - 1)
                validSuccess = validSuccess && achieved.isFinite && achieved > 0 && relativeError! <= 1e-9
            } else {
                validSuccess = false
            }
        }
    } catch let error as LightOutputAdjustmentError {
        actual = String(describing: error)
    } catch {
        actual = "unexpected_error:\(error)"
    }
    let passed = actual == entry.expected && validSuccess
    if !passed { failures += 1 }
    counts[actual, default: 0] += 1
    print([entry.name, number(entry.target), String(entry.source.isValid), String(sceneValid),
           unitValue, entry.expected, actual, number(output), number(achieved),
           number(relativeError), passed ? "PASS" : "FAIL"].joined(separator: "\t"))
}
print("SUMMARY cases=\(rows.count) failures=\(failures) counts=\(counts.keys.sorted().map { "\($0):\(counts[$0]!)" }.joined(separator: ","))")
print("CONTRACT target_relative_gate=1e-9 point_error_gate=1_percent area_error_gate=5_percent; classification_only; no_device_or_calibration_claim")
if failures > 0 { exit(1) }
