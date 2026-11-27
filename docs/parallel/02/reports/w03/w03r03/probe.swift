import Foundation
import LightingCore

let origin = Position(x: 0, y: 0, z: 0)
let sourcePosition = Position(x: 0, y: 0, z: 2)
let cases: [(String, Position, Double?)] = [
    ("front", Position(x: 0, y: 0, z: 3), 100),
    ("back", Position(x: 0, y: 0, z: -3), 0),
    ("coincident", origin, nil)
]
var checks = 0
for kind in [EmitterKind.point, .directional] {
    let light = StudioLight(name: "Probe", position: sourcePosition,
                            candela: 400, kelvin: 5600, optics: .init(kind: kind))
    for (label, camera, expected) in cases {
        let scene = LightingScene(subject: origin, camera: camera, lights: [light])
        _ = try scene.validated()
        let normal = StudioPhotometry.receiverNormal(in: scene)
        let lux = StudioPhotometry.illuminance(for: light, in: scene)
        precondition((normal == nil) == (label == "coincident"))
        precondition(lux == expected)
        let card = NeutralCardPreview(scene: scene)
        if label == "coincident" {
            precondition(card == nil)
        } else {
            precondition(card?.totalLux == expected)
            if label == "back" {
                precondition(card?.display.red == 0 && card?.display.green == 0 && card?.display.blue == 0)
            }
        }
        checks += 1
        print("\(kind) \(label): validated=true normal=\(normal == nil ? "nil" : "defined") lux=\(lux.map(String.init(describing:)) ?? "nil") card=\(card == nil ? "nil" : "valid")")
    }
}
print("PASS \(checks) cases; back cards valid RGB=(0,0,0); exact analytic front=400/4=100 lx and back=400/4*max(0,-1)=0 lx")
