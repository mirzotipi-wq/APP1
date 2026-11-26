import Foundation
import LightingCore

func p(_ x: Double, _ y: Double, _ z: Double) -> Position { .init(x: x, y: y, z: z) }
struct Fixture {
    let id: String; let kind: EmitterKind; let cd: Double
    let source: Position; let receiver: Position; let camera: Position; let aim: Position
}
let fixtures: [Fixture] = [
    .init(id: "P01", kind: .point, cd: 120, source: p(0,1.5,1), receiver: p(0,1.5,0), camera: p(0,1.5,3), aim: p(0,1.5,0)),
    .init(id: "P02", kind: .point, cd: 850, source: p(0,1.5,2), receiver: p(0,1.5,0), camera: p(0,1.5,3), aim: p(0,1.5,0)),
    .init(id: "P03", kind: .point, cd: 640, source: p(1.2,1.5,1.6), receiver: p(0,1.5,0), camera: p(0,1.5,3), aim: p(0,1.5,0)),
    .init(id: "P04", kind: .point, cd: 900, source: p(-0.9,2.8,1.9), receiver: p(0.3,1.2,-0.5), camera: p(-0.1,1.5,2.1), aim: p(0.3,1.2,-0.5)),
    .init(id: "P05", kind: .point, cd: 430, source: p(2,2,2), receiver: p(0.5,0.8,0.2), camera: p(1.3,1.4,2.6), aim: p(0.5,0.8,0.2)),
    .init(id: "P06", kind: .point, cd: 700, source: p(2.8,1.1,0.2), receiver: p(-0.2,1.4,-0.8), camera: p(-0.2,1.4,2.2), aim: p(-0.2,1.4,-0.8)),
    .init(id: "C07", kind: .directional, cd: 800, source: p(0,1.5,2), receiver: p(0,1.5,0), camera: p(0,1.5,3), aim: p(0,1.5,0)),
    .init(id: "C08", kind: .directional, cd: 800, source: p(1.2,1.5,1.6), receiver: p(0,1.5,0), camera: p(0,1.5,3), aim: p(1.2,1.5,0)),
    .init(id: "C09", kind: .directional, cd: 950, source: p(-1.5,2.3,2), receiver: p(0,1.1,0), camera: p(0.5,1.5,3), aim: p(0.3,1.2,0.4)),
    .init(id: "C10", kind: .directional, cd: 1250, source: p(1,2,3), receiver: p(-0.5,1,0), camera: p(-0.3,1.9,2.7), aim: p(-0.8,2.4,0.6)),
    .init(id: "C11", kind: .directional, cd: 550, source: p(-2,0.8,1.5), receiver: p(-0.5,1.2,-0.3), camera: p(-1.4,1.5,2.4), aim: p(-0.3,2.1,-0.7)),
    .init(id: "C12", kind: .directional, cd: 1000, source: p(1.7,2.1,0.8), receiver: p(0.2,0.6,-0.4), camera: p(1.3,0.8,1.5), aim: p(0.4,0.2,-0.8))
]
print("id\tkind\tcd\tsx\tsy\tsz\trx\try\trz\tcx\tcy\tcz\tax\tay\taz\tpoint_lux\tstudio_lux")
for f in fixtures {
    let n = UnitDirection(x: f.camera.x-f.receiver.x, y: f.camera.y-f.receiver.y, z: f.camera.z-f.receiver.z)!
    let light = StudioLight(name: f.id, position: f.source, candela: f.cd, kelvin: 5600,
                            optics: .init(kind: f.kind, aimTarget: f.aim))
    let scene = LightingScene(subject: f.receiver, camera: f.camera, lights: [light])
    guard let point = Photometry.pointIlluminance(candela: f.cd, source: f.source, receiver: f.receiver, receiverNormal: n),
          let studio = StudioPhotometry.illuminance(for: light, in: scene) else { fatalError("Unexpected nil: \(f.id)") }
    let numbers = [f.cd, f.source.x, f.source.y, f.source.z, f.receiver.x, f.receiver.y, f.receiver.z,
                   f.camera.x, f.camera.y, f.camera.z, f.aim.x, f.aim.y, f.aim.z, point, studio]
    print(([f.id, f.kind.rawValue] + numbers.map { String($0) }).joined(separator: "\t"))
}
