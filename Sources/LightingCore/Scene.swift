import Foundation

public struct Position: Codable, Equatable, Sendable {
    public static let coordinateRange: ClosedRange<Double> = -100...100
    public var x: Double
    public var y: Double
    public var z: Double
    public init(x: Double, y: Double, z: Double) {
        self.x = x; self.y = y; self.z = z
    }
    public var isValid: Bool {
        [x, y, z].allSatisfy { $0.isFinite && Self.coordinateRange.contains($0) }
    }
    public func distance(to other: Position) -> Double {
        let dx = x - other.x, dy = y - other.y, dz = z - other.z
        return (dx * dx + dy * dy + dz * dz).squareRoot()
    }
}

public struct StudioLight: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var position: Position
    /// On-axis luminous intensity, not electrical watts.
    public var candela: Double
    public var kelvin: Double
    /// Nil preserves the legacy isotropic point source.
    public var optics: LightOptics?
    public init(id: UUID = UUID(), name: String, position: Position, candela: Double, kelvin: Double, optics: LightOptics? = nil) {
        self.id = id; self.name = name; self.position = position
        self.candela = candela; self.kelvin = kelvin; self.optics = optics
    }
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 80 &&
        position.isValid && candela.isFinite && (0...100_000).contains(candela) &&
        kelvin.isFinite && (1_000...20_000).contains(kelvin) && (optics?.isValid ?? true)
    }
}

public enum SceneError: Error, Equatable {
    case unsupportedVersion, invalidScene, invalidLight, duplicateLight
}

public struct LightingScene: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 5
    public var schemaVersion: Int = currentSchemaVersion
    public var subject: Position
    public var camera: Position
    /// Nil uses the default 50 mm full-frame perspective.
    public var cameraLens: CameraLens?
    public var lights: [StudioLight]
    /// Nil retains the default diagnostic card balance and exposure.
    public var previewSettings: PreviewSettings?
    /// Nil means no measured room has been saved with this scene.
    public var placementRoom: ManualRoom?

    public init(subject: Position, camera: Position, lights: [StudioLight], cameraLens: CameraLens? = nil, previewSettings: PreviewSettings? = nil, placementRoom: ManualRoom? = nil) {
        self.subject = subject; self.camera = camera; self.lights = lights; self.cameraLens = cameraLens; self.previewSettings = previewSettings
        self.placementRoom = placementRoom
    }

    public func validated() throws -> Self {
        guard (1...Self.currentSchemaVersion).contains(schemaVersion) else { throw SceneError.unsupportedVersion }
        guard lights.count <= 12 else { throw SceneError.invalidScene }
        // Version 1 never contained optics; reject ambiguous mislabeled files.
        guard schemaVersion != 1 || lights.allSatisfy({ $0.optics == nil }) else { throw SceneError.invalidScene }
        // Version 2 adds light optics, version 3 adds a camera lens.
        guard schemaVersion >= 3 || cameraLens == nil else { throw SceneError.invalidScene }
        guard schemaVersion >= 4 || previewSettings == nil else { throw SceneError.invalidScene }
        // Version 5 adds measured rooms and rectangular-emitter roll.
        guard schemaVersion >= 5 || (placementRoom == nil && lights.allSatisfy({ $0.optics?.rollDegrees == nil })) else {
            throw SceneError.invalidScene
        }
        guard subject.isValid, camera.isValid, (cameraLens?.isValid ?? true), (previewSettings?.isValid ?? true),
              (placementRoom?.isValid ?? true) else { throw SceneError.invalidScene }
        guard lights.allSatisfy({ $0.isValid }) else { throw SceneError.invalidLight }
        guard Set(lights.map(\.id)).count == lights.count else { throw SceneError.duplicateLight }
        var migrated = self
        migrated.schemaVersion = Self.currentSchemaVersion
        return migrated
    }

    public static func portrait() -> Self {
        .init(subject: .init(x: 0, y: 1.5, z: 0),
              camera: .init(x: 0, y: 1.5, z: 3),
              lights: [
                .init(name: "Key", position: .init(x: -1.5, y: 2.1, z: 1.2), candela: 900, kelvin: 5600),
                .init(name: "Fill", position: .init(x: 1.5, y: 1.7, z: 1.5), candela: 300, kelvin: 5600),
                .init(name: "Rim", position: .init(x: 0.8, y: 2.2, z: -1.2), candela: 450, kelvin: 3200)
              ])
    }
}

public enum Photometry {
    /// Ideal point source, normal incidence. No occlusion, falloff pattern, modifier or near-field model.
    public static func normalIlluminance(candela: Double, distanceMeters: Double) -> Double? {
        guard candela.isFinite, (0...100_000).contains(candela),
              distanceMeters.isFinite, distanceMeters >= 0.05 else { return nil }
        return candela / (distanceMeters * distanceMeters)
    }
}
