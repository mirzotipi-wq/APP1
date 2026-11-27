import Foundation
import LightingCore

/// One stable executor per editor. Each method performs the complete synchronous
/// transaction without suspension; the core's process-wide lock still protects
/// CAS and migration across other windows and store instances.
actor ProjectStore {
    private let applicationSupportDirectory: URL?
    private var prepared: ProjectLibraryFileStore?
    #if DEBUG
    private let isUITesting: Bool
    private let testID: UUID?
    private let corruptFixture: Bool
    private let fullLibraryFixture: Bool
    private let largeLibraryFixture: Bool
    private let simulateConflict: Bool
    #endif

    /// Initialization captures configuration only. Directory access, fixture
    /// creation and migration happen after the caller hops to this actor.
    init(applicationSupportDirectory: URL? = nil,
         arguments: [String] = ProcessInfo.processInfo.arguments,
         environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.applicationSupportDirectory = applicationSupportDirectory
        #if DEBUG
        let uiTesting = arguments.contains("-ui-testing")
        isUITesting = uiTesting
        let id = uiTesting
            ? environment["KEYFILL_UI_TEST_ID"].flatMap(UUID.init(uuidString:)) : nil
        testID = id
        corruptFixture = id != nil && environment["KEYFILL_UI_TEST_CORRUPT"] == "1"
        fullLibraryFixture = id != nil && environment["KEYFILL_UI_TEST_FULL_LIBRARY"] == "1"
        largeLibraryFixture = id != nil && environment["KEYFILL_UI_TEST_LARGE_LIBRARY"] == "1"
        simulateConflict = id != nil && environment["KEYFILL_UI_TEST_CONFLICT"] == "1"
        #endif
    }

    /// Cancellation can skip a queued operation. Once synchronous work starts,
    /// its result is authoritative: never throw cancellation after a commit.
    func perform(_ request: ProjectLibraryRequest) throws -> ProjectLibrary? {
        try Task.checkCancellation()
        let store = prepareStore()
        switch request.operation {
        case .load, .reload:
            return try store.load()
        case .save:
            var next = try request.expected ?? ProjectLibrary(name: "Portrait setup", scene: request.scene)
            try next.updateActiveScene(request.scene)
            try save(next, replacing: request.expected, in: store)
            return next
        case let .change(command):
            var next: ProjectLibrary
            if let expected = request.expected {
                next = expected
                try command.apply(to: &next)
            } else if case let .create(name, scene) = command {
                next = try ProjectLibrary(name: name, scene: scene)
            } else {
                throw ProjectLibraryError.invalidLibrary
            }
            // The nil expectation is still a compare-and-save: another
            // window's first save wins without being overwritten here.
            try save(next, replacing: request.expected, in: store)
            return next
        case let .recover(name, candidate):
            if let candidate {
                return try store.saveRecoveryCopy(name: name, scene: request.scene, replacingArchived: candidate)
            }
            return try store.saveRecoveryCopy(name: name, scene: request.scene)
        case let .recoverUnreadable(snapshot):
            let replacement = try ProjectLibrary(name: "Portrait setup", scene: .portrait())
            // Preservation, observation validation and the atomic replacement
            // form one transaction. A returned receipt is already committed.
            return try store.recoverUnreadableLibrary(replacement, replacing: snapshot).library
        }
    }

    /// A read-only observation never migrates a legacy file or adopts it into
    /// the editor. The core also rejects healthy or merely inaccessible files.
    func inspectUnreadableLibrary() throws -> ProjectLibraryRecoverySnapshot {
        try Task.checkCancellation()
        return try prepareStore().inspectUnreadableLibrary()
    }

    /// Reading choices must never adopt the latest library over the unsaved
    /// editor. The confirmed replacement still rechecks the complete candidate.
    func recoveryCandidates() throws -> [LightingProject] {
        let latest = try recoveryLibrarySnapshot()
        return latest.projects.filter { $0.isArchived && $0.id != latest.activeID }
    }

    /// Presentation needs all names and IDs before filtering archived choices.
    /// This read does not adopt a project or mutate any saved or unsaved scene.
    func recoveryLibrarySnapshot() throws -> ProjectLibrary {
        try Task.checkCancellation()
        guard let latest = try prepareStore().load() else { throw ProjectLibraryError.invalidLibrary }
        return latest
    }

    private func prepareStore() -> ProjectLibraryFileStore {
        if let prepared { return prepared }
        let base = applicationSupportDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory,
                                                                            in: .userDomainMask)[0]
        var directory = base.appendingPathComponent("KeyAndFill", isDirectory: true)
        #if DEBUG
        if isUITesting {
            directory = base.appendingPathComponent("KeyAndFill-UITests", isDirectory: true)
            if let testID { directory.appendPathComponent(testID.uuidString, isDirectory: true) }
        }
        #endif
        let store = ProjectLibraryFileStore(directory: directory)
        #if DEBUG
        if corruptFixture {
            // UUID-scoped and create-only. Relaunch cannot overwrite saved data.
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try Data("intentional UI test corruption".utf8)
                    .write(to: store.legacyURL, options: .withoutOverwriting)
            } catch {
                // A fixture failure remains visible to the UI test's assertions.
            }
        }
        if fullLibraryFixture || largeLibraryFixture {
            do {
                if try store.load() == nil {
                    // A real supported legacy name near the byte limit, used
                    // by the native loading/save regression, never a delay.
                    let name = largeLibraryFixture ? "Legacy" + String(repeating: "\u{0301}", count: 4_000_000) : "Portrait setup"
                    var fixture = try ProjectLibrary(name: name, scene: .portrait())
                    if fullLibraryFixture {
                        let originalID = fixture.activeID
                        for index in 1..<(ProjectLibrary.maximumProjects - 1) {
                            try fixture.create(name: "Saved setup \(index)", scene: .portrait())
                        }
                        try fixture.create(name: "Archived setup", scene: .portrait())
                        let archivedID = fixture.activeID
                        try fixture.select(originalID)
                        try fixture.archive(archivedID)
                    }
                    try store.save(fixture, replacing: nil)
                }
            } catch {
                // Never replace an existing library to make a fixture succeed.
            }
        }
        #endif
        prepared = store
        return store
    }

    private func save(_ library: ProjectLibrary, replacing expected: ProjectLibrary?,
                      in store: ProjectLibraryFileStore) throws {
        #if DEBUG
        // The existing real competing transaction remains inside the worker.
        if simulateConflict, let expected,
           expected.activeProject?.name == "Portrait setup",
           try store.load() == expected {
            var competing = expected
            try competing.rename(competing.activeID, to: "Other window")
            try store.save(competing, replacing: expected)
        }
        #endif
        try store.save(library, replacing: expected)
    }
}
