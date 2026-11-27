import Foundation

public enum LightingRecipeError: Error, Equatable, Sendable, LocalizedError {
    case invalidScene
    case degenerateHorizontalDirection
    case outsideSupportedScene

    public var errorDescription: String? {
        switch self {
        case .invalidScene:
            return "The current scene must have valid settings before applying a lighting recipe."
        case .degenerateHorizontalDirection:
            return "Move the camera horizontally away from the subject to set the recipe's viewing direction."
        case .outsideSupportedScene:
            return "This recipe would place a light or its aim outside the supported scene. Move the subject farther from the scene boundary and try again."
        }
    }
}

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

    public var lightCount: Int {
        switch self {
        case .threePoint: return 3
        case .rembrandt, .butterfly: return 2
        case .silhouette: return 1
        }
    }

    /// The presets retain their authored ideal sources and output values.
    public var assumptions: String {
        "Ideal bare point sources with assumed output and color temperature. Positions are a starting point; room clearance and real equipment output need checking."
    }

    /// Replaces only the lights, keeping the current subject, camera, lens,
    /// preview settings and measured room. Distances remain in meters; camera
    /// distance and tilt do not scale or tilt the recipe.
    ///
    /// Horizontal offsets follow the camera's viewing direction. Each light's
    /// height and any explicit aim retain their authored offset from the subject.
    /// Every applied light receives a fresh identity. Invalid input, an undefined
    /// horizontal viewing direction, or an out-of-bounds result throws without
    /// changing the source. Room clearance is not inferred or adjusted.
    public func scene(applyingTo source: LightingScene) throws -> LightingScene {
        guard var scene = try? source.validated() else { throw LightingRecipeError.invalidScene }
        let template = makeScene()

        func horizontalBasis(in scene: LightingScene) throws -> (right: Position, towardCamera: Position) {
            let x = scene.camera.x - scene.subject.x
            let z = scene.camera.z - scene.subject.z
            let distance = hypot(x, z)
            guard distance.isFinite, distance > 1e-9 else {
                throw LightingRecipeError.degenerateHorizontalDirection
            }
            let towardCamera = Position(x: x / distance, y: 0, z: z / distance)
            return (.init(x: towardCamera.z, y: 0, z: -towardCamera.x), towardCamera)
        }

        let authoredBasis = try horizontalBasis(in: template)
        let currentBasis = try horizontalBasis(in: scene)
        let subject = scene.subject
        func placed(_ point: Position) -> Position {
            let x = point.x - template.subject.x
            let z = point.z - template.subject.z
            let right = x * authoredBasis.right.x + z * authoredBasis.right.z
            let front = x * authoredBasis.towardCamera.x + z * authoredBasis.towardCamera.z
            return .init(x: subject.x + right * currentBasis.right.x + front * currentBasis.towardCamera.x,
                         y: subject.y + (point.y - template.subject.y),
                         z: subject.z + right * currentBasis.right.z + front * currentBasis.towardCamera.z)
        }

        scene.lights = template.lights.map { light in
            var applied = light
            applied.id = UUID()
            applied.position = placed(light.position)
            if let target = light.optics?.aimTarget { applied.optics?.aimTarget = placed(target) }
            return applied
        }
        guard let validated = try? scene.validated() else {
            throw LightingRecipeError.outsideSupportedScene
        }
        return validated
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
