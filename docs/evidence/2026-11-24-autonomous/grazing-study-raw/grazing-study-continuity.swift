@testable import LightingCore
import Foundation
import Dispatch

enum GrazingFixture {
    static func scene(intensity: Double = 1000) -> LightingScene {
        let receiver = Position(x: 0, y: 0, z: 0.25)
        let light = StudioLight(name: "Grazing area", position: .init(x: 0, y: 0, z: 0), candela: intensity, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: receiver, widthMeters: 1, heightMeters: 0.6))
        return .init(subject: receiver, camera: .init(x: 0, y: 0, z: 3), lights: [light])
    }
    // Independent vertical-slice Simpson reference, not production clipping.
    static func reference(cut: Double, slope: Double) -> Double {
        let depth = 0.25, width = 1.0, height = 0.6, count = 160
        let length = sqrt(1 + slope * slope + cut * cut / (depth * depth))
        let x0 = max(-width / 2, cut - slope * height / 2), x1 = width / 2
        guard x0 < x1 else { return 0 }
        let dx = (x1 - x0) / Double(count)
        func weight(_ i: Int) -> Double { i == 0 || i == count ? 1 : i % 2 == 0 ? 2 : 4 }
        var sum = 0.0
        for i in 0...count {
            let x = x0 + Double(i) * dx
            let y0 = slope == 0 ? -height / 2 : max(-height / 2, (cut - x) / slope), y1 = height / 2
            if y0 >= y1 { continue }
            let dy = (y1 - y0) / Double(count)
            var slice = 0.0
            for j in 0...count {
                let y = y0 + Double(j) * dy
                let r2 = x * x + y * y + depth * depth
                slice += weight(j) * depth * max(0, (x + slope * y - cut) / length) / (r2 * r2)
            }
            sum += weight(i) * slice * dy / 3
        }
        return sum * dx / 3 * 1000 / (width * height)
    }
}

@main struct GrazingContinuity {
    static func main() throws {
        let lighting = try StudyLighting(scene: GrazingFixture.scene(), quality: .interactive)
        var values: [Double] = [], references: [Double] = []
        for cut in [0.6 - 1e-8, 0.6, 0.6 + 1e-8] {
            let n = UnitDirection(x: 1, y: 1, z: cut / 0.25)!
            let signal = try lighting.evaluate(receiver: .init(x: 0, y: 0, z: 0.25), normal: n, view: n,
                                               material: .diffuse(reflectance: 1))
            let expected = GrazingFixture.reference(cut: cut, slope: 1)
            values.append(signal.visibleLux); references.append(expected)
            print("DOUBLE cut=\(cut) visible_lux=\(signal.visibleLux) simpson_lux=\(expected)")
        }
        print("DOUBLE span_lux=\(abs(values[2]-values[0])) relative_span=\(abs(values[2]-values[0])/values[1]) simpson_span_lux=\(abs(references[2]-references[0]))")
    }
}
