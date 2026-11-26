import Foundation
import LightingCore
let right = UnitDirection(x: 1, y: 0, z: 0)!
let up = UnitDirection(x: 0, y: 1, z: 0)!
let receiver = Position(x: 0, y: 0, z: 0.05)
let threshold = Double.leastNormalMagnitude * 1024
func evaluate(_ intensity: Double, _ normal: UnitDirection) -> Double {
    let e = LambertianRectangle(center: .init(x: 0,y: 0,z: 0), right: right, up: up,
        widthMeters: 0.05, heightMeters: 0.05, onAxisCandela: intensity)!
    return Photometry.rectangularIlluminance(emitter: e, receiver: receiver, receiverNormal: normal)!
}
print("threshold=\(threshold)")
for (label, normal) in [("full", UnitDirection(x: 0,y: 0,z: -1)!),
                        ("partial", UnitDirection(x: 1,y: 0,z: 0)!)] {
    let unit = evaluate(1, normal)
    precondition(unit.isFinite && unit > 0)
    print("\(label) unit=\(unit)")
    for intensity in [Double.leastNonzeroMagnitude, Double.leastNormalMagnitude, threshold.nextDown, threshold] {
        let actual = evaluate(intensity,normal)
        let expected = unit * intensity
        precondition(actual.isFinite && actual > 0)
        if intensity < threshold { precondition(actual.bitPattern == expected.bitPattern) }
        print("\(label) intensity=\(intensity) actual=\(actual) scaled=\(expected) exact=\(actual.bitPattern == expected.bitPattern)")
    }
}
print("PASS: 8 finite positive values; 6 tiny-branch cases match unit-product exactly.")
