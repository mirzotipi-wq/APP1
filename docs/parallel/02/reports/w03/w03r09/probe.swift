import Foundation
import LightingCore

// Snapshot v1: 1b286885cb803ba17e159713651515ab119e17f1.
// Independent expected values use the literal axis separation and scalar I/r^2.
// No production normalization or photometry helper computes expected values.
let origin = Position(x: 0, y: 0, z: 0)
let camera = Position(x: 0, y: 0, z: 1)
let front = UnitDirection(x: 0, y: 0, z: 1)!
let boundary = 0.05
let distances = [("nextDown", boundary.nextDown), ("exact", boundary), ("nextUp", boundary.nextUp)]
var checks = 0
var maximumRelativeError = 0.0

func value(_ x: Double?) -> String {
    x.map { String(format: "%.17g", $0) } ?? "unsupported"
}

func check(_ name: String, _ actual: Double?, _ expected: Double?) {
    checks += 1
    switch (actual, expected) {
    case (nil, nil): break
    case let (.some(a), .some(e)):
        precondition(a.isFinite, "\(name): nonfinite")
        if e == 0 {
            precondition(a == 0, "\(name): supported zero was \(a)")
        } else {
            let error = abs(a - e) / abs(e)
            maximumRelativeError = max(maximumRelativeError, error)
            precondition(error <= 0.01, "\(name): point error exceeds 1%: \(error)")
        }
    default: preconditionFailure("\(name): actual \(value(actual)), expected \(value(expected))")
    }
}

print("case\tdistance_m\trecomputed_distance_m\tfacing\tlight_count\tscalar_expected_lux\tactual_total_lux\tindividual_sum_lux")
for (label, distance) in distances {
    let supported = label != "nextDown"
    check("normal-\(label)", Photometry.normalIlluminance(candela: 1, distanceMeters: distance),
          supported ? 1 / (distance * distance) : nil)
    check("zero-candela-point-\(label)", Photometry.pointIlluminance(candela: 0,
          source: Position(x: 0, y: 0, z: distance), receiver: origin, receiverNormal: front),
          supported ? 0 : nil)
    for sign in [1.0, -1.0] {
        let source = Position(x: 0, y: 0, z: sign * distance)
        for count in 1...3 {
            // Equal nonzero point sources isolate exactly 1x, 2x, and 3x light scaling.
            let lights = (0..<count).map { index in
                StudioLight(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
                            name: "Point \(index + 1)", position: source, candela: 1, kelvin: 5600)
            }
            let scene = LightingScene(subject: origin, camera: camera, lights: lights)
            let expectedSingle: Double? = supported ? (sign > 0 ? 1 / (distance * distance) : 0) : nil
            let expectedTotal = expectedSingle.map { $0 * Double(count) }
            let actualValues = lights.map { StudioPhotometry.illuminance(for: $0, in: scene) }
            for (index, actual) in actualValues.enumerated() {
                check("\(label)/\(sign)/\(count)/point\(index)", actual, expectedSingle)
            }
            // Never compactMap unsupported into a zero contribution.
            let individualSum: Double? = actualValues.allSatisfy { $0 != nil }
                ? actualValues.reduce(0) { $0 + $1! } : nil
            let total = NeutralCardPreview(scene: scene)?.totalLux
            check("\(label)/\(sign)/\(count)/scalar-total", total, expectedTotal)
            check("\(label)/\(sign)/\(count)/additivity", total, individualSum)
            print("\(label)\t\(value(distance))\t\(value(origin.distance(to: source)))\t\(sign > 0 ? "front" : "back")\t\(count)\t\(value(expectedTotal))\t\(value(total))\t\(value(individualSum))")
        }
    }
}

// Mixing a valid positive contribution with a close point must retain nil;
// mixing with a supported back-facing zero must retain the positive contribution.
for (label, distance) in [("mixed-unsupported", boundary.nextDown), ("mixed-zero", boundary)] {
    let lights = [
        StudioLight(name: "Positive", position: Position(x: 0, y: 0, z: 1), candela: 7, kelvin: 5600),
        StudioLight(name: "Back", position: Position(x: 0, y: 0, z: -distance), candela: 1, kelvin: 5600)
    ]
    let scene = LightingScene(subject: origin, camera: camera, lights: lights)
    let expected: Double? = label == "mixed-unsupported" ? nil : 7
    let actual = NeutralCardPreview(scene: scene)?.totalLux
    check(label, actual, expected)
    print("\(label)\t\(value(distance))\t\(value(distance))\tmixed\t2\t\(value(expected))\t\(value(actual))\tn/a")
}
print("PASS checks=\(checks) scene_cases=20 max_relative_error=\(value(maximumRelativeError)) point_gate=0.01")
