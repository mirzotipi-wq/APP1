import Foundation
import LightingCore
var output: [String: Double] = [:]
output["point_diagonal"] = Photometry.pointIlluminance(candela: 1200, source: Position(x: 2, y: 0, z: 2), receiver: Position(x: 0, y: 0, z: 0), receiverNormal: UnitDirection(x: 0, y: 0, z: 1)!)!
output["point_three_axis"] = Photometry.pointIlluminance(candela: 300, source: Position(x: -1, y: 2, z: 2), receiver: Position(x: 0, y: 0, z: 0), receiverNormal: UnitDirection(x: 0, y: 0, z: 1)!)!
output["rectangle_centered"] = Photometry.rectangularIlluminance(emitter: LambertianRectangle(center: Position(x: 0, y: 0, z: 0), right: UnitDirection(x: 1, y: 0, z: 0)!, up: UnitDirection(x: 0, y: 1, z: 0)!, widthMeters: 1.2, heightMeters: 0.6, onAxisCandela: 1000)!, receiver: Position(x: 0, y: 0, z: 0.9), receiverNormal: UnitDirection(x: 0, y: 0, z: -1)!)!
output["rectangle_minimum_depth"] = Photometry.rectangularIlluminance(emitter: LambertianRectangle(center: Position(x: 0, y: 0, z: 0), right: UnitDirection(x: 1, y: 0, z: 0)!, up: UnitDirection(x: 0, y: 1, z: 0)!, widthMeters: 2.0, heightMeters: 0.5, onAxisCandela: 1000)!, receiver: Position(x: 0, y: 0, z: 0.5), receiverNormal: UnitDirection(x: 0, y: 0, z: -1)!)!
output["rectangle_oblique"] = Photometry.rectangularIlluminance(emitter: LambertianRectangle(center: Position(x: 0.2, y: -0.4, z: 0.6), right: UnitDirection(x: 0.8, y: 0, z: -0.6)!, up: UnitDirection(x: 0, y: 1, z: 0)!, widthMeters: 0.7, heightMeters: 1.0, onAxisCandela: 850)!, receiver: Position(x: 1.14, y: -0.55, z: 1.27), receiverNormal: UnitDirection(x: -0.76, y: 0.1, z: -0.68)!)!
output["rectangle_partial"] = Photometry.rectangularIlluminance(emitter: LambertianRectangle(center: Position(x: 0, y: 0, z: 0), right: UnitDirection(x: 1, y: 0, z: 0)!, up: UnitDirection(x: 0, y: 1, z: 0)!, widthMeters: 1.2, heightMeters: 0.6, onAxisCandela: 950)!, receiver: Position(x: 0.2, y: -0.1, z: 0.6), receiverNormal: UnitDirection(x: 1, y: 0.3, z: 0.2)!)!
let bytes = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys, .prettyPrinted])
print(String(data: bytes, encoding: .utf8)!)
