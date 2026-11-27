import Foundation
import LightingCore

// One held-out fixture. R is a full 3D proper rotation from quaternion (1,2,3,4)/sqrt(30).
// Scalar reference values come from reference.py (70-digit Decimal, exact rational geometry).
func rotate(_ p: Position) -> Position {
    Position(x: (-10 * p.x + 2 * p.y + 11 * p.z) / 15,
             y: (10 * p.x - 5 * p.y + 10 * p.z) / 15,
             z: (5 * p.x + 14 * p.y + 2 * p.z) / 15)
}
func transform(_ p: Position) -> Position {
    let r = rotate(p)
    return Position(x: r.x + 7, y: r.y - 11, z: r.z + 13)
}
func relative(_ actual: Double, _ expected: Double) -> Double { abs(actual - expected) / abs(expected) }
func value(_ result: Double?, _ label: String) -> Double {
    guard let result, result.isFinite else { fatalError("Unsupported or nonfinite: \(label)") }
    return result
}
let point = StudioLight(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                        name: "Point", position: .init(x: -1, y: 2, z: 3), candela: 1375, kelvin: 5600)
let directional = StudioLight(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                              name: "Directional", position: .init(x: 3, y: -1, z: 2.5), candela: 863, kelvin: 5600,
                              optics: .init(kind: .directional, aimTarget: .init(x: 1.5, y: 2, z: -1)))
let original = try LightingScene(subject: .init(x: 0.5, y: -0.25, z: 0.75),
                                 camera: .init(x: 2, y: 1, z: 4), lights: [point, directional]).validated()
var moved = original
moved.subject = transform(original.subject)
moved.camera = transform(original.camera)
for index in moved.lights.indices {
    moved.lights[index].position = transform(original.lights[index].position)
    if let aim = original.lights[index].optics?.aimTarget {
        moved.lights[index].optics?.aimTarget = transform(aim)
    }
}
moved = try moved.validated()
let independentNormal = Position(x: 1.5 / sqrt(14.375), y: 1.25 / sqrt(14.375), z: 3.25 / sqrt(14.375))
let expectedMovedNormal = rotate(independentNormal)
guard let baseNormal = StudioPhotometry.receiverNormal(in: original),
      let movedNormal = StudioPhotometry.receiverNormal(in: moved) else { fatalError("Missing receiver normal") }
let normalErrors = [abs(baseNormal.x - independentNormal.x), abs(baseNormal.y - independentNormal.y),
                    abs(baseNormal.z - independentNormal.z), abs(movedNormal.x - expectedMovedNormal.x),
                    abs(movedNormal.y - expectedMovedNormal.y), abs(movedNormal.z - expectedMovedNormal.z)]
let normalMax = normalErrors.max()!
precondition(normalMax <= 1e-12, "Receiver normal did not rotate covariantly")
print("snapshot,v1,source_sha,1b286885cb803ba17e159713651515ab119e17f1")
print("receiver_normal_max_abs_component_error,\(normalMax)")
print("kind,original_lux,transformed_lux,reference_lux,original_relative_error,transformed_relative_error,transform_relative_change")
let references = [65.6041816634788814073923452932106380665782639380699,
                  49.6248723103128096353713519403462018693705863575121]
for index in original.lights.indices {
    let kind = original.lights[index].name
    let base = value(StudioPhotometry.illuminance(for: original.lights[index], in: original), kind)
    let next = value(StudioPhotometry.illuminance(for: moved.lights[index], in: moved), "transformed \(kind)")
    let reference = references[index]
    let baseError = relative(base, reference), movedError = relative(next, reference), drift = relative(next, base)
    print("\(kind),\(base),\(next),\(reference),\(baseError),\(movedError),\(drift)")
    precondition(max(baseError, max(movedError, drift)) <= 1e-12, "Rigid-transform fixture mismatch")
    precondition(baseError <= 0.01 && movedError <= 0.01, "Point-model 1% gate exceeded")
}
print("PASS: one rigid transform, two emitter modes, receiver normal and scalar references")
