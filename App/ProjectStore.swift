import Foundation
import LightingCore

struct ProjectStore {
    private let store: ProjectLibraryFileStore
    #if DEBUG
    private let simulateConflict: Bool
    #endif
    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var directory = base.appendingPathComponent("KeyAndFill", isDirectory: true)
        #if DEBUG
        var simulateConflict = false
        let process = ProcessInfo.processInfo
        if process.arguments.contains("-ui-testing") {
            directory = base.appendingPathComponent("KeyAndFill-UITests", isDirectory: true)
            if let rawID = process.environment["KEYFILL_UI_TEST_ID"], let id = UUID(uuidString: rawID) {
                directory.appendPathComponent(id.uuidString, isDirectory: true)
                simulateConflict = process.environment["KEYFILL_UI_TEST_CONFLICT"] == "1"
                if process.environment["KEYFILL_UI_TEST_CORRUPT"] == "1" {
                    // Debug-only fixture in a UUID-scoped namespace. Never overwrite an existing fixture.
                    let fixture = directory.appendingPathComponent("portrait.json")
                    do {
                        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                        try Data("intentional UI test corruption".utf8).write(to: fixture, options: .withoutOverwriting)
                    } catch {
                        // If the fixture cannot be prepared, the UI test's protected-state assertion fails.
                    }
                }
            }
        }
        self.simulateConflict = simulateConflict
        #endif
        store = ProjectLibraryFileStore(directory: directory)
    }
    func load() throws -> ProjectLibrary? { try store.load() }
    func saveRecoveryCopy(name: String, scene: LightingScene) throws -> ProjectLibrary {
        try store.saveRecoveryCopy(name: name, scene: scene)
    }
    func save(_ library: ProjectLibrary, replacing expected: ProjectLibrary?) throws {
        #if DEBUG
        // A real competing transaction in the UUID-scoped test directory.
        // No normal debug or release data can be changed by this fixture.
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
