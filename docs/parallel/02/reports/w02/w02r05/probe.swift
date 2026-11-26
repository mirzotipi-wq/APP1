import Foundation
import LightingCore

let inputSHA = "f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b"
let subject = Position(x: 0, y: 1.5, z: 0)
let scene = try LightingScene(
    subject: subject,
    camera: Position(x: 0.2, y: 1.6, z: 3),
    lights: [
        StudioLight(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    name: "Determinism Point", position: .init(x: -1.5, y: 2.1, z: 1.2),
                    candela: 900, kelvin: 5600, optics: .init(kind: .point)),
        StudioLight(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                    name: "Determinism Directional", position: .init(x: 1.5, y: 1.7, z: 1.5),
                    candela: 300, kelvin: 3200,
                    optics: .init(kind: .directional, aimTarget: .init(x: 0.2, y: 1.45, z: 0.1))),
        StudioLight(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                    name: "Determinism Rectangle", position: .init(x: -0.2, y: 2.6, z: 2),
                    candela: 650, kelvin: 7200,
                    optics: .init(kind: .rectangle, aimTarget: subject,
                                  widthMeters: 0.8, heightMeters: 1.2, rollDegrees: 23))
    ],
    previewSettings: .init(whiteBalanceKelvin: 5000, exposureStops: 0.75)
).validated()

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
print("inputSHA=\(inputSHA)")
print("fixture_json=\(String(data: try encoder.encode(scene), encoding: .utf8)!)")
let labels = ["pointLux", "directionalLux", "rectangleLux", "totalLux",
              "incidentXYZ.x", "incidentXYZ.y", "incidentXYZ.z",
              "display.red", "display.green", "display.blue"]
var baselineBits: [UInt64] = []
var baselinePreview: NeutralCardPreview?
var scalarComparisons = 0
var scalarMismatches = 0
var previewComparisons = 0
var previewMismatches = 0
var evaluations = 0

// Exactly 32 complete observations, including the baseline; no warm-up evaluation.
for iteration in 0..<32 {
    let perLight = scene.lights.map { light -> Double in
        guard let lux = StudioPhotometry.illuminance(for: light, in: scene),
              lux.isFinite, lux > 0 else { fatalError("Unsupported or nonpositive fixture lux") }
        return lux
    }
    guard let card = NeutralCardPreview(scene: scene) else { fatalError("Unsupported card fixture") }
    let values = perLight + [card.totalLux, card.incidentXYZ.x, card.incidentXYZ.y, card.incidentXYZ.z,
                            card.display.red, card.display.green, card.display.blue]
    precondition(values.count == labels.count && values.allSatisfy { $0.isFinite })
    let bits = values.map(\.bitPattern)
    if iteration == 0 {
        baselineBits = bits
        baselinePreview = card
        for (label, value) in zip(labels, values) {
            print("baseline.\(label)=\(String(format: "%.17g", value)) bits=0x\(String(value.bitPattern, radix: 16))")
        }
    } else {
        for index in bits.indices {
            scalarComparisons += 1
            if bits[index] != baselineBits[index] {
                scalarMismatches += 1
                print("MISMATCH run=\(iteration + 1) field=\(labels[index])")
            }
        }
        previewComparisons += 1
        if card != baselinePreview! { previewMismatches += 1 }
    }
    evaluations += 1
    print("run=\(iteration + 1) bits=\(bits.map { String($0, radix: 16) }.joined(separator: ","))")
}
print("evaluations=\(evaluations) repeatComparisons=\(evaluations - 1) scalarBitPatternComparisons=\(scalarComparisons) scalarMismatches=\(scalarMismatches) previewEquatableComparisons=\(previewComparisons) previewMismatches=\(previewMismatches)")
precondition(evaluations == 32 && scalarComparisons == 310 && previewComparisons == 31)
precondition(scalarMismatches == 0 && previewMismatches == 0, "Determinism check failed")
print("result=PASS scope=one immutable mixed rig; same process; fixed order; not physical calibration")
