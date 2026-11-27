import Foundation
import LightingCore
struct Row {
    let name: String
    let kind: EmitterKind
    let source: Position
    let camera: Position
    let aim: Position?
    let candela: Double
}
let rows: [Row] = [
    Row(name: "point_front", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: nil, candela: 400.0),
    Row(name: "point_receiver_60", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 1.7320508075688772, y: 0.0, z: 1.0), aim: nil, candela: 400.0),
    Row(name: "point_near_grazing", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 1.999899997499875, y: 0.0, z: 0.02), aim: nil, candela: 400.0),
    Row(name: "point_distance_4m", kind: .point, source: .init(x: 0.0, y: 0.0, z: 4.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: nil, candela: 400.0),
    Row(name: "point_max_candela", kind: .point, source: .init(x: 0.0, y: 0.0, z: 0.5), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: nil, candela: 100000.0),
    Row(name: "point_zero_candela", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: nil, candela: 0.0),
    Row(name: "point_receiver_tangent", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 2.0, y: 0.0, z: 0.0), aim: nil, candela: 400.0),
    Row(name: "point_receiver_back", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: -2.0), aim: nil, candela: 400.0),
    Row(name: "directional_front", kind: .directional, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: .init(x: 0.0, y: 0.0, z: 1.0), candela: 400.0),
    Row(name: "directional_emitter_60", kind: .directional, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: .init(x: 0.8660254037844386, y: 0.0, z: 1.5), candela: 400.0),
    Row(name: "directional_both_60", kind: .directional, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 1.7320508075688772, y: 0.0, z: 1.0), aim: .init(x: 0.8660254037844386, y: 0.0, z: 1.5), candela: 400.0),
    Row(name: "directional_near_grazing", kind: .directional, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 1.999899997499875, y: 0.0, z: 0.02), aim: .init(x: 0.9682458365518543, y: 0.0, z: 1.75), candela: 400.0),
    Row(name: "directional_emitter_back", kind: .directional, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: .init(x: 0.0, y: 0.0, z: 3.0), candela: 400.0),
    Row(name: "directional_emitter_tangent", kind: .directional, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: .init(x: 1.0, y: 0.0, z: 2.0), candela: 400.0),
    Row(name: "unsupported_under_5cm", kind: .point, source: .init(x: 0.0, y: 0.0, z: 0.049), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: nil, candela: 400.0),
    Row(name: "unsupported_camera_coincident", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 0.0), aim: nil, candela: 400.0),
    Row(name: "unsupported_directional_aim", kind: .directional, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: .init(x: 0.0, y: 0.0, z: 2.0), candela: 400.0),
    Row(name: "unsupported_candela", kind: .point, source: .init(x: 0.0, y: 0.0, z: 2.0), camera: .init(x: 0.0, y: 0.0, z: 2.0), aim: nil, candela: 100001.0)
]
print("name,actual_lux")
for row in rows {
    let light = StudioLight(name: "Matrix", position: row.source, candela: row.candela,
                            kelvin: 5600, optics: .init(kind: row.kind, aimTarget: row.aim))
    let scene = LightingScene(subject: .init(x: 0, y: 0, z: 0), camera: row.camera, lights: [light])
    let actual = StudioPhotometry.illuminance(for: light, in: scene)
    print(row.name + "," + (actual.map { String(format: "%.17g", $0) } ?? "nil"))
}
