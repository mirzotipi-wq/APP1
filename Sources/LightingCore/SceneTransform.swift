import Foundation

public enum SceneTransformError: Error, Equatable, LocalizedError {
    case invalidTransform, undefinedCameraDirection, outsideSupportedScene

    public var errorDescription: String? {
        switch self {
        case .invalidTransform: return "Enter finite position or rotation values."
        case .undefinedCameraDirection: return "Move the camera horizontally away from the subject before mirroring the lights."
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
        let degrees = angle.truncatingRemainder(dividingBy: 360)
        guard degrees != 0 else { return scene }
        // Exact quarter turns must not push an on-boundary coordinate outside
        // the supported range through a small trigonometric residual.
        let c: Double, s: Double
        switch degrees {
        case 90, -270: c = 0; s = 1
        case -90, 270: c = 0; s = -1
        case 180, -180: c = -1; s = 0
        default:
            let radians = degrees * .pi / 180
            c = cos(radians); s = sin(radians)
        }
        let center = scene.subject
        func rotated(_ p: Position) -> Position {
            let x = p.x - center.x, z = p.z - center.z
            return .init(x: center.x + c * x + s * z, y: p.y,
                         z: center.z - s * x + c * z)
        }
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = rotated(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = rotated(target) }
            Self.adjustVerticalRoll(from: light, to: &next, subject: center) { direction in
                .init(x: c * direction.x + s * direction.z, y: direction.y,
                      z: -s * direction.x + c * direction.z)
            }
            return next
        }
        guard let validated = try? scene.validated() else { throw SceneTransformError.outsideSupportedScene }
        return validated
    }

    /// Reflects lighting across the camera's vertical center plane.
    public static func mirroringLights(_ source: LightingScene) throws -> LightingScene {
        var scene = try source.validated()
        let center = scene.subject
        let dx = scene.camera.x - center.x, dz = scene.camera.z - center.z
        let horizontalDistance = hypot(dx, dz)
        guard horizontalDistance > 1e-9 else { throw SceneTransformError.undefinedCameraDirection }
        // The reflection plane is vertical even when the camera is tilted.
        // The unnormalized form also keeps axis-aligned and diagonal camera
        // planes exact, avoiding square-root roundoff at the scene boundary.
        let squaredDistance = dx * dx + dz * dz
        let diagonal = (dx * dx - dz * dz) / squaredDistance
        let cross = 2 * (dx * dz) / squaredDistance
        func reflectedDirection(_ p: Position) -> Position {
            .init(x: diagonal * p.x + cross * p.z, y: p.y,
                  z: cross * p.x - diagonal * p.z)
        }
        func mirrored(_ p: Position) -> Position {
            let x = p.x - center.x, z = p.z - center.z
            return .init(x: p.x + ((diagonal - 1) * x + cross * z), y: p.y,
                         z: p.z + (cross * x - (diagonal + 1) * z))
        }
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = mirrored(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = mirrored(target) }
            if let roll = next.optics?.rollDegrees { next.optics?.rollDegrees = -roll }
            Self.adjustVerticalRoll(from: light, to: &next, subject: center) { direction in
                let reflected = reflectedDirection(direction)
                // A reflection reverses handedness; negating the width axis
                // restores the emitter normal without changing its rectangle.
                return .init(x: -reflected.x, y: -reflected.y, z: -reflected.z)
            }
            return next
        }
        guard let validated = try? scene.validated() else { throw SceneTransformError.outsideSupportedScene }
        return validated
    }

    /// World-up frames rotate covariantly except at their vertical fallback.
    /// Reconstruct only that case, preserving entered rolls elsewhere.
    private static func adjustVerticalRoll(from light: StudioLight, to next: inout StudioLight,
                                           subject: Position, transform: (Position) -> Position) {
        guard light.effectiveOptics.kind == .rectangle,
              let original = StudioPhotometry.frame(for: light, subject: subject),
              let baseline = EmitterFrame(source: next.position, target: next.target(subject: subject)),
              hypot(original.normal.x, original.normal.z) <= 1e-12 ||
                hypot(baseline.normal.x, baseline.normal.z) <= 1e-12 else { return }
        let right = transform(.init(x: original.right.x, y: original.right.y, z: original.right.z))
        let cosine = right.x * baseline.right.x + right.y * baseline.right.y + right.z * baseline.right.z
        let sine = right.x * baseline.up.x + right.y * baseline.up.y + right.z * baseline.up.z
        let roll = atan2(sine, cosine) * 180 / .pi
        if roll != 0 || next.optics?.rollDegrees != nil { next.optics?.rollDegrees = roll }
    }
}
