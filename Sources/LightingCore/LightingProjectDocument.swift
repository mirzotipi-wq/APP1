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
        try requireValidStringsAndUniqueObjectKeys(in: data)
        return try .init(name: envelope.name, scene: envelope.scene)
    }

    private struct ObjectKeyScope {
        let isObject: Bool
        var expectsKey: Bool
        var keys = Set<Data>()

        init(isObject: Bool) {
            self.isObject = isObject
            expectsKey = isObject
        }
    }

    /// Foundation has accepted the JSON structure and closed envelope, but may
    /// defer decoding ignored string values. Validate every string with the same
    /// Unicode rules as typed values, and reject duplicate decoded object names.
    /// This policy applies only to external project documents; legacy stored
    /// library decoding and valid unknown scene metadata are unchanged.
    private static func requireValidStringsAndUniqueObjectKeys(in data: Data) throws {
        let bytes = try envelopeUTF8(data)
        let stringDecoder = JSONDecoder()
        var index = 0
        var scopes: [ObjectKeyScope] = []
        while index < bytes.count {
            switch bytes[index] {
            case 0x22: // String: skip escaped quotes and structural punctuation.
                let start = index
                var hasEscape = false
                var hasNonASCII = false
                index += 1
                while index < bytes.count, bytes[index] != 0x22 {
                    let byte = bytes[index]
                    guard byte >= 0x20 else { throw DocumentError.invalidDocument }
                    if byte == 0x5c {
                        hasEscape = true
                        index += 2
                    } else {
                        hasNonASCII = hasNonASCII || byte >= 0x80
                        index += 1
                    }
                }
                guard index < bytes.count else { throw DocumentError.invalidDocument }
                let isKey = scopes.indices.last.map { scopes[$0].expectsKey } ?? false
                if isKey || hasEscape {
                    let token = Data(bytes[start...index])
                    let value: String
                    do { value = try stringDecoder.decode(String.self, from: token) }
                    catch { throw DocumentError.invalidDocument }
                    if let scope = scopes.indices.last, isKey {
                        // Decode escapes, then compare exact UTF-8 sequences. Swift
                        // String equality would also merge distinct NFC/NFD names.
                        // Mutate the stored set in place to avoid copying all earlier
                        // names for each member of a wide object.
                        guard scopes[scope].keys.insert(Data(value.utf8)).inserted else {
                            throw DocumentError.invalidDocument
                        }
                        scopes[scope].expectsKey = false
                    }
                } else if hasNonASCII {
                    // Unescaped ASCII was validated during the scan. For other
                    // unescaped values, reject malformed UTF-8 without invoking
                    // a JSON decoder for each ignored metadata value. This strict
                    // initializer must not repair invalid byte sequences.
                    guard String(validating: bytes[(start + 1)..<index], as: UTF8.self) != nil else {
                        throw DocumentError.invalidDocument
                    }
                }
            case 0x7b, 0x5b: // Object or array.
                scopes.append(ObjectKeyScope(isObject: bytes[index] == 0x7b))
            case 0x7d, 0x5d:
                guard let scope = scopes.last, scope.isObject == (bytes[index] == 0x7d) else {
                    throw DocumentError.invalidDocument
                }
                scopes.removeLast() // Release this object's names before a sibling.
                // Remaining bytes were already validated as trailing JSON
                // whitespace. Avoid scanning large padding a second time.
                if scopes.isEmpty { return }
            case 0x2c:
                if let scope = scopes.indices.last, scopes[scope].isObject {
                    scopes[scope].expectsKey = true
                }
            default: break
            }
            index += 1
        }
        throw DocumentError.invalidDocument
    }

    /// Preserve the decoder's Unicode JSON inputs. The first ASCII structural
    /// or whitespace character identifies UTF-16/32 byte order without a BOM;
    /// UTF-8 stays on the direct bounded-byte path. JSON structure has already
    /// been checked; the token scan also validates ignored string values.
    private static func envelopeUTF8(_ data: Data) throws -> [UInt8] {
        let prefix = Array(data.prefix(4))
        let encoding: String.Encoding
        if prefix.starts(with: [0x00, 0x00, 0xfe, 0xff]) {
            encoding = .utf32BigEndian
        } else if prefix.starts(with: [0xff, 0xfe, 0x00, 0x00]) {
            encoding = .utf32LittleEndian
        } else if prefix.starts(with: [0xfe, 0xff]) {
            encoding = .utf16BigEndian
        } else if prefix.starts(with: [0xff, 0xfe]) {
            encoding = .utf16LittleEndian
        } else if prefix.count == 4 && prefix[0] == 0 && prefix[1] == 0 && prefix[2] == 0 {
            encoding = .utf32BigEndian
        } else if prefix.count == 4 && prefix[1] == 0 && prefix[2] == 0 && prefix[3] == 0 {
            encoding = .utf32LittleEndian
        } else if prefix.count == 4 && prefix[0] == 0 && prefix[2] == 0 {
            encoding = .utf16BigEndian
        } else if prefix.count == 4 && prefix[1] == 0 && prefix[3] == 0 {
            encoding = .utf16LittleEndian
        } else {
            return Array(data)
        }
        guard let text = String(data: data, encoding: encoding) else {
            throw DocumentError.invalidDocument
        }
        return Array(text.utf8)
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
