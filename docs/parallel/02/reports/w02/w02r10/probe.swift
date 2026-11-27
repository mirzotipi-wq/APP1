import Foundation
import LightingCore

// Measured API output only; no reference values are embedded in this probe.
struct Measurement: Encodable {
    let kelvin: Int
    let X: Double
    let Y: Double
    let Z: Double
    let x: Double
    let y: Double
}

let temperatures = [1000, 2000, 2856, 3200, 5600, 6500, 10000, 20000]
let measurements = temperatures.map { temperature -> Measurement in
    guard let xyz = PreviewColorimetry.blackbody(kelvin: Double(temperature)),
          let xy = xyz.chromaticity else {
        fatalError("Expected finite blackbody result at \(temperature) K")
    }
    return Measurement(kelvin: temperature, X: xyz.x, Y: xyz.y, Z: xyz.z,
                       x: xy.x, y: xy.y)
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
print(String(decoding: try encoder.encode(measurements), as: UTF8.self))
