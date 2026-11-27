import Foundation
import LightingCore

@main enum PortraitCameraDepthProbe {
    static func main() throws {
        var results: [[String: Any]] = []
        for distance in [0.171, 0.18, 0.20, 0.25, 0.30] {
            for axis in ["above", "front", "side"] {
                var scene = LightingScene.portrait()
                scene.subject = .init(x: 0, y: 0, z: 0)
                scene.camera = axis == "above" ? .init(x: 0.001, y: distance, z: 0) :
                    axis == "front" ? .init(x: 0, y: 0, z: distance) : .init(x: distance, y: 0, z: 0)
                scene.cameraLens = .init(focalLengthMillimeters: 50)
                scene.lights = []
                do {
                    let image = try PortraitStudyRenderer.render(scene: scene, width: 24)
                    results.append(["axis": axis, "distance": distance,
                                    "unsupportedPixels": image.unsupportedPixels])
                } catch {
                    results.append(["axis": axis, "distance": distance, "error": String(describing: error)])
                }
            }
        }
        print(String(decoding: try JSONSerialization.data(withJSONObject: results,
            options: [.sortedKeys, .prettyPrinted]), as: UTF8.self))
    }
}
