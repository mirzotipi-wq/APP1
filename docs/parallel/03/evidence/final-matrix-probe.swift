import Foundation
import LightingCore

/// Re-render the frozen original scenes; archive RGBA and validity separately.
@main struct FinalStudyMatrix {
    struct Fixture: Decodable { let name: String; let subject: String; let expectedWidth: Int; let sceneFile: String }
    struct Original: Decodable { let fixtures: [Fixture] }
    struct Result: Codable {
        let name: String; let subject: String; let width: Int; let height: Int
        let rgbaBytes: Int; let maskBytes: Int; let unsupportedPixels: Int
        let originalScene: String; let opaque: Bool; let validMask: Bool
    }
    static func main() throws {
        guard CommandLine.arguments.count == 3 else { throw StudyError.invalidResolution }
        let original = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let decoder = JSONDecoder()
        let manifest = try decoder.decode(Original.self, from: Data(contentsOf: original.appendingPathComponent("manifest.json")))
        guard manifest.fixtures.count == 12, Set(manifest.fixtures.map(\.name)).count == 12 else { throw StudyError.invalidScene }
        var results: [Result] = []
        for fixture in manifest.fixtures {
            let sceneData = try Data(contentsOf: original.appendingPathComponent(fixture.sceneFile))
            let scene = try decoder.decode(LightingScene.self, from: sceneData)
            let image: StudyImage
            switch fixture.subject {
            case "sphere": image = try ReferenceStudyRenderer.render(scene: scene, width: fixture.expectedWidth)
            case "neutral-mannequin": image = try PortraitStudyRenderer.render(scene: scene, width: fixture.expectedWidth)
            default: throw StudyError.invalidScene
            }
            let opaque = stride(from: 3, to: image.rgba.count, by: 4).allSatisfy { image.rgba[$0] == 255 }
            let validMask = image.unsupportedPixelMask.count == image.width * image.height &&
                image.unsupportedPixelMask.allSatisfy { $0 <= 1 } &&
                image.unsupportedPixelMask.reduce(0, { $0 + Int($1) }) == image.unsupportedPixels
            guard opaque, validMask, image.rgba.count == 4 * image.width * image.height else { throw StudyError.invalidComputeOutput }
            var ppm = Data("P6\n\(image.width) \(image.height)\n255\n".utf8)
            for i in stride(from: 0, to: image.rgba.count, by: 4) { ppm.append(image.rgba[i..<i+3]) }
            try ppm.write(to: output.appendingPathComponent(fixture.name + ".ppm"))
            try image.rgba.write(to: output.appendingPathComponent(fixture.name + ".rgba"))
            try image.unsupportedPixelMask.write(to: output.appendingPathComponent(fixture.name + ".mask"))
            try sceneData.write(to: output.appendingPathComponent(fixture.sceneFile))
            results.append(.init(name: fixture.name, subject: fixture.subject, width: image.width, height: image.height,
                                 rgbaBytes: image.rgba.count, maskBytes: image.unsupportedPixelMask.count,
                                 unsupportedPixels: image.unsupportedPixels, originalScene: fixture.sceneFile,
                                 opaque: opaque, validMask: validMask))
            print("\(fixture.name): \(image.width)x\(image.height), unsupported=\(image.unsupportedPixels)")
        }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(results).write(to: output.appendingPathComponent("manifest.json"))
    }
}

