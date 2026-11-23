import Foundation

public enum ProjectLibraryError: Error, Equatable, LocalizedError {
    case invalidName, invalidLibrary, unsupportedVersion, duplicateID, capacity
    case notFound, archived, activeCannotArchive, staleSnapshot, notRegularFile, tooLarge
    case mustArchiveBeforeDeletion

    public var errorDescription: String? {
        switch self {
        case .invalidName: return "Enter a project name of 1–80 characters, without line breaks or control characters."
        case .invalidLibrary: return "The project library is invalid. Existing data has been protected."
        case .unsupportedVersion: return "This project library was created by a newer or unsupported version."
        case .duplicateID: return "Duplicate project identifiers were detected."
        case .capacity: return "This version supports up to 64 projects, including archived projects."
        case .notFound: return "The project could not be found."
        case .archived: return "Restore this project before opening or editing it."
        case .activeCannotArchive: return "Open a different project before archiving this one."
        case .mustArchiveBeforeDeletion: return "Only an archived, inactive project can be permanently removed from the library."
        case .staleSnapshot: return "The library changed in another window. Your edits have not been overwritten."
        case .notRegularFile: return "The saved library is not a regular file. Existing data has been protected."
        case .tooLarge: return "The project library exceeds the supported storage size."
        }
    }
}

public struct LightingProject: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public fileprivate(set) var name: String
    public fileprivate(set) var scene: LightingScene
    public fileprivate(set) var isArchived: Bool
}

/// One bounded, versioned snapshot. Scene schemas are migrated independently.
/// All mutation methods validate before changing the snapshot.
public struct ProjectLibrary: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let maximumProjects = 64
    public static let maximumNameLength = 80
    public private(set) var schemaVersion: Int = currentSchemaVersion
    public private(set) var projects: [LightingProject]
    public private(set) var activeID: UUID

    public init(name: String, scene: LightingScene, id: UUID = UUID()) throws {
        projects = [.init(id: id, name: try Self.normalizedName(name), scene: try scene.validated(), isArchived: false)]
        activeID = id
    }

    public var activeProject: LightingProject? { projects.first { $0.id == activeID && !$0.isArchived } }

    public static func normalizedName(_ input: String) throws -> String {
        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let forbidden = CharacterSet.controlCharacters.union(.newlines)
        guard !name.isEmpty, name.count <= maximumNameLength,
              !name.unicodeScalars.contains(where: { forbidden.contains($0) }) else {
            throw ProjectLibraryError.invalidName
        }
        return name
    }

    public func validated() throws -> Self {
        guard schemaVersion == Self.currentSchemaVersion else { throw ProjectLibraryError.unsupportedVersion }
        guard !projects.isEmpty, projects.count <= Self.maximumProjects else { throw ProjectLibraryError.invalidLibrary }
        guard Set(projects.map(\.id)).count == projects.count else { throw ProjectLibraryError.duplicateID }
        guard activeProject != nil else { throw ProjectLibraryError.invalidLibrary }
        var result = self
        for i in result.projects.indices {
            result.projects[i].name = try Self.normalizedName(result.projects[i].name)
            result.projects[i].scene = try result.projects[i].scene.validated()
        }
        return result
    }

    private func index(_ id: UUID) throws -> Int {
        guard let i = projects.firstIndex(where: { $0.id == id }) else { throw ProjectLibraryError.notFound }
        return i
    }

    public mutating func create(name: String, scene: LightingScene, id: UUID = UUID()) throws {
        guard projects.count < Self.maximumProjects else { throw ProjectLibraryError.capacity }
        guard !projects.contains(where: { $0.id == id }) else { throw ProjectLibraryError.duplicateID }
        let project = LightingProject(id: id, name: try Self.normalizedName(name),
                                      scene: try scene.validated(), isArchived: false)
        projects.insert(project, at: 0)
        activeID = id
    }

    public mutating func select(_ id: UUID) throws {
        let i = try index(id)
        guard !projects[i].isArchived else { throw ProjectLibraryError.archived }
        activeID = id
    }

    public mutating func updateActiveScene(_ scene: LightingScene) throws {
        let i = try index(activeID)
        guard !projects[i].isArchived else { throw ProjectLibraryError.archived }
        projects[i].scene = try scene.validated()
    }

    public mutating func rename(_ id: UUID, to name: String) throws {
        let i = try index(id)
        guard !projects[i].isArchived else { throw ProjectLibraryError.archived }
        projects[i].name = try Self.normalizedName(name)
    }

    public mutating func duplicate(_ id: UUID, name: String, newID: UUID = UUID()) throws {
        let i = try index(id)
        guard !projects[i].isArchived else { throw ProjectLibraryError.archived }
        let source = projects[i].scene
        try create(name: name, scene: source, id: newID)
    }

    public mutating func archive(_ id: UUID) throws {
        guard id != activeID else { throw ProjectLibraryError.activeCannotArchive }
        projects[try index(id)].isArchived = true
    }

    public mutating func restore(_ id: UUID) throws {
        projects[try index(id)].isArchived = false
    }

    /// Removes one archived record. The active project, other records and
    /// the legacy migration backup are untouched. Persist via the store's
    /// atomic, stale-snapshot-checked save; this is not secure file erasure.
    public mutating func deleteArchived(_ id: UUID) throws {
        let i = try index(id)
        guard id != activeID, projects[i].isArchived else {
            throw ProjectLibraryError.mustArchiveBeforeDeletion
        }
        projects.remove(at: i)
    }
}

/// A library is atomically replaced only after validating its previous snapshot.
/// The legacy portrait.json is deliberately left untouched after migration.
/// A process-wide transaction lock protects the comparison and replacement,
/// including first-time migration, across independent windows/store instances.
/// External processes writing directly to the directory are outside this contract.
public struct ProjectLibraryFileStore: Sendable {
    public static let maximumBytes = 8 * 1024 * 1024
    private static let transactionLock = NSLock()
    public let directory: URL
    public var url: URL { directory.appendingPathComponent("projects.json") }
    public var legacyURL: URL { directory.appendingPathComponent("portrait.json") }

    public init(directory: URL) { self.directory = directory }

    public func load() throws -> ProjectLibrary? {
        Self.transactionLock.lock()
        defer { Self.transactionLock.unlock() }
        return try loadWhileLocked()
    }

    /// Must only be called while holding transactionLock. Migration writes to
    /// disk, so it belongs inside the same transaction as snapshot validation.
    private func loadWhileLocked() throws -> ProjectLibrary? {
        if let data = try readLibrary() {
            return try JSONDecoder().decode(ProjectLibrary.self, from: data).validated()
        }
        guard let legacy = try SceneFileStore(url: legacyURL).load() else { return nil }
        let migrated = try ProjectLibrary(name: "Portrait setup", scene: legacy)
        try write(migrated)
        return migrated
    }

    /// Passing the actual loaded snapshot prevents stale windows from silently
    /// overwriting another project's edits or metadata.
    public func save(_ library: ProjectLibrary, replacing expected: ProjectLibrary?) throws {
        let validated = try library.validated()
        Self.transactionLock.lock()
        defer { Self.transactionLock.unlock() }
        guard try loadWhileLocked() == expected else { throw ProjectLibraryError.staleSnapshot }
        try write(validated)
    }

    private func write(_ library: ProjectLibrary) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(library)
        guard data.count <= Self.maximumBytes else { throw ProjectLibraryError.tooLarge }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func readLibrary() throws -> Data? {
        let attributes: [FileAttributeKey: Any]
        do {
            attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
            (error.code == NSFileNoSuchFileError || error.code == NSFileReadNoSuchFileError) {
            return nil
        }
        guard attributes[.type] as? FileAttributeType == .typeRegular else {
            throw ProjectLibraryError.notRegularFile
        }
        guard let size = attributes[.size] as? NSNumber,
              size.uint64Value <= UInt64(Self.maximumBytes) else { throw ProjectLibraryError.tooLarge }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var data = Data()
        let limit = Self.maximumBytes + 1
        while data.count < limit {
            guard let chunk = try handle.read(upToCount: min(64 * 1024, limit - data.count)),
                  !chunk.isEmpty else { break }
            data.append(chunk)
        }
        guard data.count <= Self.maximumBytes else { throw ProjectLibraryError.tooLarge }
        return data
    }
}
