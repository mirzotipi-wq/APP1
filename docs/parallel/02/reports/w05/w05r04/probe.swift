import Foundation
import LightingCore

func require(_ condition: Bool, _ detail: String) {
    guard condition else { print("FAIL\t\(detail)"); exit(1) }
}

// The same three fixtures and assertions as the proposed XCTest candidate.
        let fixtures: [(source: StudioLight, referenceCandela: Double)] = [
            (.init(name: "Oblique point", position: .init(x: -1.65, y: 2.7, z: 2.4),
                   candela: 860, kelvin: 4700,
                   optics: .init(kind: .point)), 37.25),
            (.init(name: "Manually aimed directional", position: .init(x: 2.4, y: 2.05, z: 3.2),
                   candela: 0, kelvin: 5200,
                   optics: .init(kind: .directional,
                                 aimTarget: .init(x: -0.45, y: 1.7, z: -0.2))), 1875.5),
            (.init(name: "Rolled nonsquare rectangle", position: .init(x: -0.85, y: 2.8, z: 1.95),
                   candela: 400, kelvin: 6100,
                   optics: .init(kind: .rectangle,
                                 aimTarget: .init(x: -0.25, y: 0.95, z: -0.15),
                                 widthMeters: 0.85, heightMeters: 1.35,
                                 rollDegrees: 37)), 12345.75)
        ]

print("kind\tinitialCandela\treferenceCandela\ttargetLux\tadjustedCandela\tachievedLux\trelativeCandelaError\trelativeLuxError\tmaximumLux")
for (source, referenceCandela) in fixtures {
            let scene = LightingScene(subject: .init(x: 0.35, y: 1.25, z: -0.45),
                                      camera: .init(x: 1.1, y: 1.8, z: 4.2),
                                      lights: [source])
    _ = try scene.validated()
    var reference = source
    reference.candela = referenceCandela
    guard let target = StudioPhotometry.illuminance(for: reference, in: scene) else {
        fatalError("Unsupported reference: \(source.name)")
    }
    require(target.isFinite && target > 0, "Positive finite target: \(source.name)")
    var maximum = source
    maximum.candela = 100_000
    guard let maximumLux = StudioPhotometry.illuminance(for: maximum, in: scene) else {
        fatalError("Unsupported maximum: \(source.name)")
    }
    require(target < maximumLux, "Interior target: \(source.name)")
    let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)
    guard let achieved = StudioPhotometry.illuminance(for: adjusted, in: scene) else {
        fatalError("Unsupported adjusted result: \(source.name)")
    }
    let candelaError = abs(adjusted.candela / referenceCandela - 1)
    let luxError = abs(achieved / target - 1)
    require(adjusted.isValid, "Valid adjusted source: \(source.name)")
    require(candelaError <= 1e-9, "Recovered reference intensity: \(source.name)")
    require(luxError <= 1e-9, "Forward target round trip: \(source.name)")
    print("\(source.effectiveOptics.kind.rawValue)\t\(source.candela)\t\(referenceCandela)\t\(target)\t\(adjusted.candela)\t\(achieved)\t\(candelaError)\t\(luxError)\t\(maximumLux)")
}
print("PASS\t3 attainable interior round trips; relative lux and candela errors <= 1e-9")
