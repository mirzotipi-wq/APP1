import Foundation

let cases: [(String, Position, Position, Position)] = [
    ("valid_false_rejection", .init(x: 1, y: 1.5, z: 0), .init(x: 2, y: 1.5, z: 2), .init(x: -100, y: 2, z: 48)),
    ("rounded_false_acceptance", .init(x: 0, y: 1.5, z: 0), .init(x: 1, y: 1.5, z: 2), .init(x: -81, y: 2, z: Double(64.25).nextUp)),
    ("axis_contract_control", .init(x: 50, y: 1.5, z: 0), .init(x: 50, y: 1.5, z: 1), .init(x: -Double.leastNonzeroMagnitude, y: 2, z: 0))
]
for (name, subject, camera, point) in cases {
    for storedAim in [false, true] {
        let source = LightingScene(subject: subject, camera: camera, lights: [
            .init(name: name, position: storedAim ? subject : point, candela: 900, kelvin: 5600,
                  optics: storedAim ? .init(kind: .point, aimTarget: point) : nil)
        ])
        print("\(name) storedAim=\(storedAim) input_valid=\((try? source.validated()) != nil)")
        for arranged in [false, true] {
            let label = arranged ? "arranged" : "standalone"
            do {
                let result = arranged
                    ? try SceneTransform.arranged(source, subjectAt: subject, mirroringLights: true)
                    : try SceneTransform.mirroringLights(source)
                let p = storedAim ? result.lights[0].optics!.aimTarget! : result.lights[0].position
                print("\(label): accepted x=\(p.x) z=\(p.z) xBits=\(String(p.x.bitPattern, radix: 16)) zBits=\(String(p.z.bitPattern, radix: 16))")
            } catch { print("\(label): rejected \(error)") }
        }
    }
}
