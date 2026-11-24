import Foundation

public enum SceneTransformError: Error, Equatable, LocalizedError {
    case invalidTransform, outsideSupportedScene

    public var errorDescription: String? {
        switch self {
        case .invalidTransform: return "Enter finite position or rotation values."
        case .outsideSupportedScene: return "This move would place part of the setup outside the supported scene. Nothing was moved."
        }
    }
}

/// Atomic transforms preserve source identity, photometric settings and room context.
public enum SceneTransform {
    public static func translated(_ source: LightingScene, by offset: Position) throws -> LightingScene {
        guard offset.x.isFinite, offset.y.isFinite, offset.z.isFinite else {
            throw SceneTransformError.invalidTransform
        }
        var scene = try source.validated()
        func shifted(_ p: Position) -> Position {
            .init(x: p.x + offset.x, y: p.y + offset.y, z: p.z + offset.z)
        }
        scene.subject = shifted(scene.subject)
        scene.camera = shifted(scene.camera)
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = shifted(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = shifted(target) }
            return next
        }
        guard let validated = try? scene.validated() else { throw SceneTransformError.outsideSupportedScene }
        return validated
    }

    /// Rotates lights and their explicit aims about the subject's vertical axis.
    /// The camera and measured subject position stay fixed.
    public static func rotatingLights(_ source: LightingScene, byDegrees angle: Double) throws -> LightingScene {
        guard angle.isFinite else { throw SceneTransformError.invalidTransform }
        var scene = try source.validated()
        let radians = angle.truncatingRemainder(dividingBy: 360) * .pi / 180
        let c = cos(radians), s = sin(radians), center = scene.subject
        func rotated(_ p: Position) -> Position {
            let x = p.x - center.x, z = p.z - center.z
            return .init(x: center.x + c * x + s * z, y: p.y,
                         z: center.z - s * x + c * z)
        }
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = rotated(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = rotated(target) }
            return next
        }
        guard let validated = try? scene.validated() else { throw SceneTransformError.outsideSupportedScene }
        return validated
    }

    /// Reflects lighting across the camera's vertical center plane.
    public static func mirroringLights(_ source: LightingScene) throws -> LightingScene {
        var scene = try source.validated()
        guard let framing = CameraFraming(scene: scene) else { throw SceneTransformError.invalidTransform }
        let center = scene.subject, right = framing.right
        func mirrored(_ p: Position) -> Position {
            let distance = (p.x - center.x) * right.x + (p.y - center.y) * right.y + (p.z - center.z) * right.z
            return .init(x: p.x - 2 * distance * right.x,
                         y: p.y - 2 * distance * right.y,
                         z: p.z - 2 * distance * right.z)
        }
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = mirrored(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = mirrored(target) }
            if let roll = next.optics?.rollDegrees { next.optics?.rollDegrees = -roll }
            return next
        }
        guard let validated = try? scene.validated() else { throw SceneTransformError.outsideSupportedScene }
        return validated
    }
}
