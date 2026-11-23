import Foundation

public struct Position: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(x: Double, y: Double, z: Double) {
        self.x = x; self.y = y; self.z = z
    }
    public var isValid: Bool {
        [x, y, z].allSatisfy { $0.isFinite && abs($0) <= 100 }
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
    public init(id: UUID = UUID(), name: String, position: Position, candela: Double, kelvin: Double) {
        self.id = id; self.name = name; self.position = position
        self.candela = candela; self.kelvin = kelvin
    }
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 80 &&
        position.isValid && candela.isFinite && (0...100_000).contains(candela) &&
        kelvin.isFinite && (1_000...20_000).contains(kelvin)
    }
}

public enum SceneError: Error, Equatable {
    case unsupportedVersion, invalidScene, invalidLight, duplicateLight
}

public struct LightingScene: Codable, Equatable, Sendable {
    public var schemaVersion: Int = 1
    public var subject: Position
    public var camera: Position
    public var lights: [StudioLight]

    public init(subject: Position, camera: Position, lights: [StudioLight]) {
        self.subject = subject; self.camera = camera; self.lights = lights
    }

    public func validated() throws -> Self {
        guard schemaVersion == 1 else { throw SceneError.unsupportedVersion }
        guard subject.isValid, camera.isValid, lights.count <= 12 else { throw SceneError.invalidScene }
        guard lights.allSatisfy({ $0.isValid }) else { throw SceneError.invalidLight }
        guard Set(lights.map(\.id)).count == lights.count else { throw SceneError.duplicateLight }
        return self
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
