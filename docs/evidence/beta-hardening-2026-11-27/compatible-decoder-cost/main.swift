import Foundation
import Dispatch

@inline(never)
func decodeChecked(_ data: Data, variant: String) throws -> Int {
    let name: String
    let scene: LightingScene
    switch variant {
    case "old":
        let document = try OldProjectDocument.decode(data)
        name = document.name
        scene = document.scene
    case "compatible":
        let document = try LightingProjectDocument.decode(data)
        name = document.name
        scene = document.scene
    default:
        fatalError("Unknown parser variant")
    }
    precondition(name == "Benchmark")
    precondition(scene.schemaVersion == LightingScene.currentSchemaVersion)
    precondition(scene.subject == Position(x: 0, y: 1.5, z: 0))
    precondition(scene.camera == Position(x: 0, y: 1.5, z: 3))
    precondition(scene.lights.isEmpty)
    return name.utf8.count + scene.schemaVersion
}

let args = CommandLine.arguments
precondition(args.count == 5)
let variant = args[1]
let input = try Data(contentsOf: URL(fileURLWithPath: args[2]))
let warmups = Int(args[3])!
let iterations = Int(args[4])!
precondition(warmups >= 0 && iterations > 0)
var checksum = 0
for _ in 0..<warmups { checksum += try decodeChecked(input, variant: variant) }
let start = DispatchTime.now().uptimeNanoseconds
for _ in 0..<iterations { checksum += try decodeChecked(input, variant: variant) }
let elapsed = DispatchTime.now().uptimeNanoseconds - start
let record: [String: Any] = [
    "variant": variant, "input_bytes": input.count,
    "warmups": warmups, "iterations": iterations,
    "elapsed_nanoseconds": elapsed,
    "nanoseconds_per_decode": Double(elapsed) / Double(iterations),
    "checksum": checksum,
]
let output = try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
FileHandle.standardOutput.write(output)
FileHandle.standardOutput.write(Data([0x0a]))
