import Foundation
import LightingCore

@main enum PortraitCameraVisual {
    static func main() throws {
        let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var results: [[String: Any]] = []
        for distance in [0.18, 0.20] {
            var scene = LightingScene.portrait()
            scene.subject = .init(x: 0, y: 0, z: 0)
            scene.camera = .init(x: 0.001, y: distance, z: 0)
            scene.cameraLens = .init(focalLengthMillimeters: 50)
            scene.lights = []
            let name = distance == 0.18 ? "overhead-clipped" : "overhead-clear"
            do {
                let image = try PortraitStudyRenderer.render(scene: scene, width: 144)
                var ppm = Data("P6\n\(image.width) \(image.height)\n255\n".utf8)
                for index in stride(from: 0, to: image.rgba.count, by: 4) {
                    ppm.append(contentsOf: image.rgba[index..<index + 3])
                }
                try ppm.write(to: folder.appendingPathComponent(name + ".ppm"))
                try image.unsupportedPixelMask.write(to: folder.appendingPathComponent(name + ".mask"))
                results.append(["name": name, "distance": distance, "width": image.width,
                                "height": image.height, "unsupportedPixels": image.unsupportedPixels])
            } catch {
                results.append(["name": name, "distance": distance, "error": String(describing: error)])
            }
        }
        let json = try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: folder.appendingPathComponent("result.json"))
        print(String(decoding: json, as: UTF8.self))
    }
}
