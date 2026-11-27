import Foundation

@main enum PortraitCameraDepthProbe {
    static func main() throws {
        var results: [[String: Any]] = []
        for distance in [0.18] {
          for focal in [35.0, 50.0, 85.0, 135.0, 200.0] {
            for axis in ["above", "front", "side"] {
                var scene = LightingScene.portrait()
                scene.subject = .init(x: 0, y: 0, z: 0)
                scene.camera = axis == "above" ? .init(x: 0.001, y: distance, z: 0) :
                    axis == "front" ? .init(x: 0, y: 0, z: distance) : .init(x: distance, y: 0, z: 0)
                scene.cameraLens = .init(focalLengthMillimeters: focal)
                scene.lights = []
                do {
                    let image = try PortraitStudyRenderer.render(scene: scene, width: 24)
                    results.append(["axis": axis, "distance": distance, "focal": focal,
                                    "unsupportedPixels": image.unsupportedPixels])
                } catch {
                    results.append(["axis": axis, "distance": distance, "focal": focal, "error": String(describing: error)])
                }
            }
        }
        }
        print(String(decoding: try JSONSerialization.data(withJSONObject: results,
            options: [.sortedKeys, .prettyPrinted]), as: UTF8.self))
    }
}
