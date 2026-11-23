import Foundation
import LightingCore

struct ProjectStore {
    private let store: ProjectLibraryFileStore
    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var directory = base.appendingPathComponent("KeyAndFill", isDirectory: true)
        #if DEBUG
        let process = ProcessInfo.processInfo
        if process.arguments.contains("-ui-testing") {
            directory = base.appendingPathComponent("KeyAndFill-UITests", isDirectory: true)
            if let rawID = process.environment["KEYFILL_UI_TEST_ID"], let id = UUID(uuidString: rawID) {
                directory.appendPathComponent(id.uuidString, isDirectory: true)
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
        #endif
        store = ProjectLibraryFileStore(directory: directory)
    }
    func load() throws -> ProjectLibrary? { try store.load() }
    func save(_ library: ProjectLibrary, replacing expected: ProjectLibrary?) throws {
        try store.save(library, replacing: expected)
    }
}
