import Foundation
import LightingCore

// One partially illuminated rectangle; independent closed-form reference.
let d = 1.0, a = 2.0, b = 2.0, x0 = -1.0
func edge(_ x: Double) -> Double {
    let h = sqrt(d * d + x * x)
    return atan(b / h) / h
}
let h = sqrt(d * d + b * b)
let xIntegral = d * (edge(x0) - edge(a))
let zIntegral = a * edge(a) - x0 * edge(x0)
    + b / h * (atan(a / h) - atan(x0 / h))
let coefficient = (xIntegral + zIntegral) / (16 * sqrt(2.0))
let intensity = 8 * Double.leastNonzeroMagnitude
let expected = coefficient * intensity
let right = UnitDirection(x: 1, y: 0, z: 0)!
let up = UnitDirection(x: 0, y: 1, z: 0)!
let normal = UnitDirection(x: 1, y: 0, z: -1)!
func illuminance(_ candela: Double) -> Double {
    let emitter = LambertianRectangle(
        center: .init(x: 0, y: 0, z: 0), right: right, up: up,
        widthMeters: 4, heightMeters: 4, onAxisCandela: candela)!
    return Photometry.rectangularIlluminance(
        emitter: emitter, receiver: .init(x: 0, y: 0, z: 1),
        receiverNormal: normal)!
}
let unitActual = illuminance(1)
let actual = illuminance(intensity)
let error = abs(actual / expected - 1)
let unitError = abs(unitActual / coefficient - 1)
print("fixture: width=4m height=4m depth=1m normal=(1,0,-1)/sqrt(2)")
print("positive domain: x in (-1,2], y in [-2,2]; area fraction=0.75")
print(String(format: "analytic x integral=%.17g z integral=%.17g", xIntegral, zIntegral))
print(String(format: "analytic coefficient=%.17g lx/cd unit actual=%.17g lx relative error=%.17g", coefficient, unitActual, unitError))
print(String(format: "intensity=%.17g cd direct intensity/area=%.17g", intensity, intensity / 16))
print(String(format: "expected=%.17g lx actual=%.17g lx relative error=%.17g", expected, actual, error))
print("bit patterns: intensity=\(intensity.bitPattern) expected=\(expected.bitPattern) actual=\(actual.bitPattern)")
precondition(intensity / 16 == 0, "fixture must expose premature radiance underflow")
precondition(expected == Double.leastNonzeroMagnitude && actual > 0)
precondition(error <= 0.05 && unitError <= 0.05, "unchanged area-model gate")
print("PASS: tiny clipped-face result preserves one representable lux step")
