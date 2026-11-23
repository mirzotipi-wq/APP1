import Foundation

public enum LightingRecipe: String, CaseIterable, Sendable {
    case threePoint = "Three-point portrait"
    case rembrandt = "Rembrandt"
    case butterfly = "Butterfly"
    case silhouette = "Silhouette"

    public var detail: String {
        switch self {
        case .threePoint: return "Balanced key, fill and warm rim."
        case .rembrandt: return "Elevated side key with restrained fill."
        case .butterfly: return "Centered high key with lower fill."
        case .silhouette: return "Backlight with a dark foreground."
        }
    }
    public func makeScene() -> LightingScene {
        var scene = LightingScene.portrait()
        switch self {
        case .threePoint: break
        case .rembrandt:
            scene.lights = [
                .init(name: "Key", position: .init(x: -1.6, y: 2.4, z: 0.9), candela: 1100, kelvin: 5600),
                .init(name: "Fill", position: .init(x: 1.6, y: 1.6, z: 1.6), candela: 120, kelvin: 5600)
            ]
        case .butterfly:
            scene.lights = [
                .init(name: "Key", position: .init(x: 0, y: 2.7, z: 1.5), candela: 950, kelvin: 5600),
                .init(name: "Fill", position: .init(x: 0, y: 0.9, z: 1.4), candela: 200, kelvin: 5600)
            ]
        case .silhouette:
            scene.lights = [
                .init(name: "Backlight", position: .init(x: 0, y: 2.0, z: -1.7), candela: 1400, kelvin: 4300)
            ]
        }
        return scene
    }
}
