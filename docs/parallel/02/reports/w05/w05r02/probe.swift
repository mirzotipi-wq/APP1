import Foundation
import LightingCore
import Glibc

func log(_ values: [String: Any]) {
    let data = try! JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
    print(String(data: data, encoding: .utf8)!)
}
func positionBits(_ p: Position) -> String {
    [p.x, p.y, p.z].map { String($0.bitPattern) }.joined(separator: ",")
}
func preservedFields(_ s: StudioLight) -> [String: String] {
    var fields = ["id": s.id.uuidString, "nameUTF8": Data(s.name.utf8).base64EncodedString(),
                  "positionBits": positionBits(s.position), "kelvinBits": String(s.kelvin.bitPattern)]
    if let o = s.optics {
        fields["opticsPresence"] = "some"
        fields["optics.kind"] = o.kind.rawValue
        fields["optics.aimTarget"] = o.aimTarget.map(positionBits) ?? "nil"
        fields["optics.widthBits"] = String(o.widthMeters.bitPattern)
        fields["optics.heightBits"] = String(o.heightMeters.bitPattern)
        fields["optics.rollBits"] = o.rollDegrees.map { String($0.bitPattern) } ?? "nil"
    } else {
        fields["opticsPresence"] = "nil"
    }
    return fields
}
func encoded<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(value)
}
struct ProbeFailure: Error { let message: String }
func require(_ value: Bool, _ message: String) throws {
    if !value { throw ProbeFailure(message: message) }
}

let subject = Position(x: 0.2, y: 1.35, z: 0.1)
let legacy = StudioLight(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!,
    name: "\tKey – α  \n", position: .init(x: -1.3, y: 2.05, z: 2.4), candela: 271.25, kelvin: 3123.5)
let explicitPoint = StudioLight(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!,
    name: " Point with retained optics ", position: .init(x: 1.1, y: 1.85, z: 3.2), candela: 389.75, kelvin: 6789.25,
    optics: .init(kind: .point, aimTarget: .init(x: 0.4, y: 1.15, z: -0.2),
                  widthMeters: 0.73, heightMeters: 1.31, rollDegrees: -0.0))
let directional = StudioLight(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!,
    name: "Directional Ω", position: .init(x: -0.8, y: 2.25, z: 2.9), candela: 523.125, kelvin: 4567.125,
    optics: .init(kind: .directional, aimTarget: nil, widthMeters: 0.47, heightMeters: 0.91, rollDegrees: nil))
let rectangle = StudioLight(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000004")!,
    name: "Rolled rectangle β", position: .init(x: 1.45, y: 2.75, z: 2.6), candela: 647.5, kelvin: 9876.75,
    optics: .init(kind: .rectangle, aimTarget: subject, widthMeters: 0.87, heightMeters: 1.29, rollDegrees: 37.25))
let spectator = StudioLight(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000005")!,
    name: "Unrelated fill", position: .init(x: -2, y: 1.8, z: 2), candela: 81.5, kelvin: 5100.25)
let scene = LightingScene(subject: subject, camera: .init(x: 0.55, y: 1.7, z: 4.5),
    lights: [legacy, rectangle, spectator], cameraLens: .init(focalLengthMillimeters: 83.25),
    previewSettings: .init(whiteBalanceKelvin: 4375, exposureStops: -1.25),
    placementRoom: .init(widthMeters: 7.2, depthMeters: 9.6, subjectX: 3.4, subjectZ: 2.1,
                         yawDegrees: 32.5, ceilingHeightMeters: 3.8))
let fixtures: [(String, StudioLight)] = [("legacy_point", legacy), ("explicit_point", explicitPoint),
                                      ("directional", directional), ("rolled_rectangle", rectangle)]

do {
    _ = try scene.validated()
    let originalScene = scene
    let originalSceneData = try encoded(scene)
    log(["event": "scene", "value": String(data: originalSceneData, encoding: .utf8)!])
    var count = 0
    var maximumRelativeError = 0.0
    for (label, base) in fixtures {
        try require(base.isValid, "invalid fixture: \(label)")
        guard let exactLux = StudioPhotometry.illuminance(for: base, in: scene), exactLux > 0 else {
            throw ProbeFailure(message: "fixture has no positive contribution: \(label)")
        }
        log(["event": "source", "fixture": label, "preservedFingerprint": preservedFields(base),
             "source": String(data: try encoded(base), encoding: .utf8)!])
        for mode in ["zero", "changed_positive", "already_exact", "initially_off"] {
            var input = base
            if mode == "initially_off" { input.candela = 0 }
            let originalSource = input
            let originalSourceData = try encoded(input)
            let target = mode == "zero" ? 0 : (mode == "already_exact" ? exactLux : 123.456)
            let result = try LightOutputAdjustment.light(input, targetingLux: target, in: scene)
            let before = preservedFields(input)
            let after = preservedFields(result)
            var restored = result
            restored.candela = input.candela
            let fieldsMatch = before == after
            let allOtherFieldsEqual = restored == input
            let sourceAfterData = try encoded(input)
            let sceneAfterData = try encoded(scene)
            let sourceUnchanged = input == originalSource && sourceAfterData == originalSourceData
            let sceneUnchanged = scene == originalScene && sceneAfterData == originalSceneData
            try require(fieldsMatch && allOtherFieldsEqual && sourceUnchanged && sceneUnchanged,
                        "preservation failure: \(label)/\(mode)")
            try require(result.isValid, "invalid adjusted source")
            guard let achieved = StudioPhotometry.illuminance(for: result, in: scene) else {
                throw ProbeFailure(message: "missing achieved lux")
            }
            let relativeError = target == 0 ? 0 : abs(achieved / target - 1)
            try require(target == 0 ? (result.candela == 0 && achieved == 0) : relativeError <= 1e-9,
                        "unchanged target gate failed: \(label)/\(mode)")
            if mode == "already_exact" {
                try require(try encoded(result) == originalSourceData, "exact source did not round-trip")
            } else {
                try require(result.candela.bitPattern != input.candela.bitPattern, "output was not changed")
            }
            maximumRelativeError = max(maximumRelativeError, relativeError)
            count += 1
            log(["event": "case", "fixture": label, "mode": mode,
                 "memberOfScene": scene.lights.contains { $0.id == input.id },
                 "inputCandela": input.candela, "outputCandela": result.candela,
                 "targetLux": target, "achievedLux": achieved, "relativeError": relativeError,
                 "preservedFields": before.keys.sorted(), "fieldBitPatternsPreserved": fieldsMatch,
                 "allNonOutputFieldsEqual": allOtherFieldsEqual,
                 "sourceUnchanged": sourceUnchanged, "sceneUnchanged": sceneUnchanged, "pass": true])
        }
    }
    log(["event": "summary", "cases": count, "passed": count, "failed": 0,
         "maximumRelativeTargetError": maximumRelativeError, "targetRelativeTolerance": 1e-9,
         "pointGateUnchanged": 0.01, "areaGateUnchanged": 0.05,
         "scope": "Synthetic identity/value-preservation probe; no independent photometric-accuracy, device or calibration claim."])
} catch {
    log(["event": "failure", "error": String(describing: error)])
    exit(1)
}
