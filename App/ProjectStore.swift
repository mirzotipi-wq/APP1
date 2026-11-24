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
                if process.environment["KEYFILL_UI_TEST_FULL_LIBRARY"] == "1" {
                    // A real full library, confined to the validated test UUID.
                    // A relaunch must retain the recovery result instead of
                    // recreating the original fixture or overwriting any bytes.
                    let fixtureStore = ProjectLibraryFileStore(directory: directory)
                    do {
                        if try fixtureStore.load() == nil {
                            var fixture = try ProjectLibrary(name: "Portrait setup", scene: .portrait())
                            let originalID = fixture.activeID
                            for index in 1..<(ProjectLibrary.maximumProjects - 1) {
                                try fixture.create(name: "Saved setup \(index)", scene: .portrait())
                            }
                            try fixture.create(name: "Archived setup", scene: .portrait())
                            let archivedID = fixture.activeID
                            try fixture.select(originalID)
                            try fixture.archive(archivedID)
                            try fixtureStore.save(fixture, replacing: nil)
                        }
                    } catch {
                        // Fixture failure is exposed by the UI test's required
                        // saved-state/capacity assertions, never a simulated pass.
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
    func saveRecoveryCopy(name: String, scene: LightingScene,
                          replacingArchived expected: LightingProject) throws -> ProjectLibrary {
        try store.saveRecoveryCopy(name: name, scene: scene, replacingArchived: expected)
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
