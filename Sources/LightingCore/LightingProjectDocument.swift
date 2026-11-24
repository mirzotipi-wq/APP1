import Foundation

/// An editable, bounded single-project backup. It carries scene values only:
/// no library identity, active selection, archive state or reference photograph.
/// Importers must create a new project rather than replacing an existing ID.
public struct LightingProjectDocument: Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let maximumBytes = 8 * 1024 * 1024

    public enum DocumentError: Error, Equatable, LocalizedError {
        case tooLarge, unsupportedVersion, invalidDocument, invalidName, invalidScene

        public var errorDescription: String? {
            switch self {
            case .tooLarge: return "This project file exceeds the supported 8 MiB size."
            case .unsupportedVersion: return "This project file was created by a newer or unsupported version of Key & Fill."
            case .invalidDocument: return "This is not a valid Key & Fill project file. No saved projects have been changed."
            case .invalidName: return "The project file contains an invalid project name."
            case .invalidScene: return "The project file contains invalid or unsupported lighting settings."
            }
        }
    }

    public var schemaVersion: Int { Self.currentSchemaVersion }
    public let name: String
    public let scene: LightingScene

    public init(name: String, scene: LightingScene) throws {
        // Use the storage-compatible policy, not the stricter new-entry policy:
        // exporting an existing legacy name must not make the backup unreadable.
        do { self.name = try ProjectLibrary.normalizedName(name) }
        catch { throw DocumentError.invalidName }
        do { self.scene = try scene.validated() }
        catch { throw DocumentError.invalidScene }
    }

    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Envelope(schemaVersion: schemaVersion, name: name, scene: scene))
        guard data.count <= Self.maximumBytes else { throw DocumentError.tooLarge }
        return data
    }

    public static func decode(_ data: Data) throws -> Self {
        guard data.count <= maximumBytes else { throw DocumentError.tooLarge }
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: data) }
        catch let error as DocumentError { throw error }
        catch { throw DocumentError.invalidDocument }
        return try .init(name: envelope.name, scene: envelope.scene)
    }

    /// Private decoding prevents callers from bypassing validation through a
    /// synthesized public Decodable initializer. Version 1 has a closed envelope;
    /// unexpected fields are not silently accepted as an editable backup.
    private struct Envelope: Codable {
        let schemaVersion: Int
        let name: String
        let scene: LightingScene

        init(schemaVersion: Int, name: String, scene: LightingScene) {
            self.schemaVersion = schemaVersion
            self.name = name
            self.scene = scene
        }

        private struct Key: CodingKey {
            let stringValue: String
            var intValue: Int? { nil }
            init(_ value: String) { stringValue = value }
            init?(stringValue: String) { self.init(stringValue) }
            init?(intValue: Int) { return nil }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            schemaVersion = try container.decode(Int.self, forKey: Key("schemaVersion"))
            guard schemaVersion == LightingProjectDocument.currentSchemaVersion else {
                throw DocumentError.unsupportedVersion
            }
            guard Set(container.allKeys.map(\.stringValue)) == ["schemaVersion", "name", "scene"] else {
                throw DocumentError.invalidDocument
            }
            name = try container.decode(String.self, forKey: Key("name"))
            scene = try container.decode(LightingScene.self, forKey: Key("scene"))
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(schemaVersion, forKey: Key("schemaVersion"))
            try container.encode(name, forKey: Key("name"))
            try container.encode(scene, forKey: Key("scene"))
        }
    }
}
