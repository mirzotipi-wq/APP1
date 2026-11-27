import Foundation

public enum SceneLightCreationError: Error, Equatable, LocalizedError {
    case capacityReached, outsideSupportedScene

    public var errorDescription: String? {
        switch self {
        case .capacityReached:
            return "A setup can contain up to 12 lights."
        case .outsideSupportedScene:
            return "There is no room for the new light beside this subject within the supported scene. Move the subject away from the scene boundary and try again."
        }
    }
}

/// Creates one light beside the current subject, relative to the camera's
/// horizontal direction. The complete result is validated before adoption.
public enum SceneLightCreation {
    public static func addingLight(to source: LightingScene, id: UUID = UUID()) throws -> LightingScene {
        var next = try source.validated()
        guard next.lights.count < 12 else { throw SceneLightCreationError.capacityReached }
        let dx = next.camera.x - next.subject.x
        let dz = next.camera.z - next.subject.z
        let distance = hypot(dx, dz)
        // A vertical or coincident camera has no horizontal viewing direction.
        // Use the same world-facing convention as the default portrait rig.
        let forwardX = distance > 1e-9 ? dx / distance : 0
        let forwardZ = distance > 1e-9 ? dz / distance : 1
        let position = Position(x: next.subject.x + forwardZ + forwardX,
                                y: next.subject.y + 0.5,
                                z: next.subject.z - forwardX + forwardZ)
        guard position.isValid else { throw SceneLightCreationError.outsideSupportedScene }
        var number = 1
        while next.lights.contains(where: { $0.name == "Light \(number)" }) { number += 1 }
        next.lights.append(StudioLight(id: id, name: "Light \(number)", position: position,
                                      candela: 500, kelvin: 5600))
        return try next.validated()
    }
}
