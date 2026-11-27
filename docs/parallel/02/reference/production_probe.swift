import Foundation
import LightingCore

struct Fixture: Codable {
    let id: String
    let kind: String
    let source: [Double]
    let receiver: [Double]
    let normal: [Double]
    let width: Double?
    let height: Double?
    let roll: Double?
    let candela: Double
    let expected: Double
    var actual: Double?
}
let url = URL(fileURLWithPath: CommandLine.arguments[1])
var fixtures = try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
func position(_ a: [Double]) -> Position { .init(x: a[0], y: a[1], z: a[2]) }
for i in fixtures.indices {
    let f = fixtures[i]
    guard let normal = UnitDirection(x: f.normal[0], y: f.normal[1], z: f.normal[2]) else { fatalError("Invalid fixture normal") }
    if f.kind == "point" {
        fixtures[i].actual = Photometry.pointIlluminance(candela: f.candela, source: position(f.source), receiver: position(f.receiver), receiverNormal: normal)
    } else {
        let angle = (f.roll ?? 0) * .pi / 180
        let emitter = LambertianRectangle(center: position(f.source), right: UnitDirection(x: cos(angle), y: sin(angle), z: 0)!, up: UnitDirection(x: -sin(angle), y: cos(angle), z: 0)!, widthMeters: f.width!, heightMeters: f.height!, onAxisCandela: f.candela)!
        fixtures[i].actual = Photometry.rectangularIlluminance(emitter: emitter, receiver: position(f.receiver), receiverNormal: normal)
    }
}
let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
FileHandle.standardOutput.write(try encoder.encode(fixtures))
