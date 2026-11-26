import Foundation
import LightingCore

let origin = Position(x: 0, y: 0, z: 0)
let front = UnitDirection(x: 0, y: 0, z: 1)!
let source = StudioLight(name: "Fixture", position: .init(x: 0, y: 0, z: 2), candela: 100, kelvin: 5600)
let scene = LightingScene(subject: origin, camera: .init(x: 0, y: 0, z: 3), lights: [])
var near = source
near.position.z = 0.049
var invalid = source
invalid.candela = -1
var back = source
back.position.z = -2
var rectangle = source
rectangle.position.z = 0.1
rectangle.optics = .init(kind: .rectangle, widthMeters: 0.6, heightMeters: 0.9)
var coincidentCamera = scene
coincidentCamera.camera = origin

func classify(_ value: Double?) -> String {
    guard let value else { return "nil" }
    if value == 0 { return "zero" }
    return "value:\(value)"
}
func solve(_ light: StudioLight, _ target: Double, _ scene: LightingScene) -> String {
    do {
        let adjusted = try LightOutputAdjustment.light(light, targetingLux: target, in: scene)
        return "candela-\(classify(adjusted.candela))"
    } catch {
        return "throw:\(error)"
    }
}
var failures = 0
func check(_ id: Int, _ api: String, _ fixture: String, _ expected: String, _ actual: String) {
    let passed = expected == actual
    if !passed { failures += 1 }
    print("\(id)\t\(api)\t\(fixture)\t\(expected)\t\(actual)\t\(passed ? "PASS" : "FAIL")")
}
print("snapshot\tf75aa2758b4c14714e7517c4c0df4adb9f1a8b9b\tfrozen LightingCore v1")
print("id\tAPI\tfixture\texpected\tactual\tresult")
check(1, "Photometry.normal", "-1 cd; 2 m", "nil", classify(Photometry.normalIlluminance(candela: -1, distanceMeters: 2)))
check(2, "Photometry.normal", "0 cd; 2 m", "zero", classify(Photometry.normalIlluminance(candela: 0, distanceMeters: 2)))
check(3, "Photometry.point", "100 cd; 0.049 m", "nil", classify(Photometry.pointIlluminance(candela: 100, source: near.position, receiver: origin, receiverNormal: front)))
check(4, "Photometry.point", "100 cd; coincident source", "nil", classify(Photometry.pointIlluminance(candela: 100, source: origin, receiver: origin, receiverNormal: front)))
check(5, "StudioPhotometry", "coincident camera/subject", "nil", classify(StudioPhotometry.illuminance(for: source, in: coincidentCamera)))
check(6, "StudioPhotometry", "point behind receiver; 2 m", "zero", classify(StudioPhotometry.illuminance(for: back, in: scene)))
check(7, "StudioPhotometry", "0.6x0.9 m rectangle; depth 0.1 m", "nil", classify(StudioPhotometry.illuminance(for: rectangle, in: scene)))
check(8, "LightOutputAdjustment", "target -1 lux; valid source", "throw:invalidTargetLux", solve(source, -1, scene))
check(9, "LightOutputAdjustment", "invalid source -1 cd; target 0 lux", "throw:invalidLight", solve(invalid, 0, scene))
check(10, "LightOutputAdjustment", "near point; target 1 lux", "throw:unsupportedGeometry", solve(near, 1, scene))
check(11, "LightOutputAdjustment", "valid source/scene; near point + coincident camera; target 0 lux", "candela-zero", solve(near, 0, coincidentCamera))
print("SUMMARY\tcases=11\tfailures=\(failures)")
if failures > 0 { exit(1) }
