import Foundation
import XCTest
@testable import LightingCore

final class ProjectLibraryTests: XCTestCase {
    private func withStore(_ work: (ProjectLibraryFileStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try work(ProjectLibraryFileStore(directory: directory))
    }

    func testFirstSaveAndIndependentProjectsRoundTrip() throws {
        try withStore { store in
            XCTAssertNil(try store.load())
            let original = LightingScene.portrait()
            var library = try ProjectLibrary(name: "  Portrait  ", scene: original)
            let originalID = library.activeID
            try store.save(library, replacing: nil)
            let snapshot = try XCTUnwrap(store.load())
            try library.create(name: "Editorial", scene: .portrait())
            let secondID = library.activeID
            XCTAssertNotEqual(secondID, originalID)
            var edited = try XCTUnwrap(library.activeProject?.scene)
            edited.lights[0].candela = 1234
            try library.updateActiveScene(edited)
            try store.save(library, replacing: snapshot)
            var reopened = try XCTUnwrap(store.load())
            XCTAssertEqual(reopened.activeID, secondID)
            XCTAssertEqual(reopened.activeProject?.scene, edited)
            try reopened.select(originalID)
            XCTAssertEqual(reopened.activeProject?.scene, original)
            XCTAssertEqual(reopened.activeProject?.name, "Portrait")
        }
    }

    func testLegacyMigrationIsIdempotentAndPreservesOriginalBytes() throws {
        try withStore { store in
            var legacy = LightingScene.portrait()
            legacy.schemaVersion = 1
            try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
            let bytes = try JSONEncoder().encode(legacy)
            try bytes.write(to: store.legacyURL)
            let first = try XCTUnwrap(store.load())
            XCTAssertEqual(first.activeProject?.scene.schemaVersion, LightingScene.currentSchemaVersion)
            XCTAssertEqual(first.activeProject?.scene.lights, legacy.lights)
            XCTAssertEqual(first, try store.load())
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), bytes)
            var next = first
            try next.rename(first.activeID, to: "Migrated portrait")
            try store.save(next, replacing: first)
            XCTAssertEqual(try store.load(), next)
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), bytes)
        }
    }

    func testMalformedLegacyNeverCreatesLibrary() throws {
        try withStore { store in
            try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
            let corrupt = Data("bad legacy".utf8)
            try corrupt.write(to: store.legacyURL)
            XCTAssertThrowsError(try store.load())
            XCTAssertThrowsError(try store.save(ProjectLibrary(name: "New", scene: .portrait()), replacing: nil))
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.url.path))
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), corrupt)
        }
    }

    func testCorruptLibraryNeverFallsBackToLegacyOrOverwrites() throws {
        try withStore { store in
            try SceneFileStore(url: store.legacyURL).save(.portrait())
            let migrated = try XCTUnwrap(store.load())
            let corrupt = Data("damaged library".utf8)
            try corrupt.write(to: store.url)
            XCTAssertThrowsError(try store.load())
            XCTAssertThrowsError(try store.save(migrated, replacing: migrated))
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
        }
    }

    func testStaleSnapshotDoesNotOverwriteAnotherWindow() throws {
        try withStore { store in
            let initial = try ProjectLibrary(name: "Portrait", scene: .portrait())
            try store.save(initial, replacing: nil)
            var first = initial
            try first.rename(first.activeID, to: "Window A")
            try store.save(first, replacing: initial)
            var stale = initial
            try stale.rename(stale.activeID, to: "Window B")
            XCTAssertThrowsError(try store.save(stale, replacing: initial)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertEqual(try store.load(), first)
        }
    }

    func testDuplicateArchiveRestorePreserveSceneAndActiveIdentity() throws {
        try withStore { store in
            var library = try ProjectLibrary(name: "Portrait", scene: .portrait())
            let source = try XCTUnwrap(library.activeProject)
            try library.duplicate(source.id, name: "Copy")
            let duplicate = try XCTUnwrap(library.activeProject)
            XCTAssertNotEqual(duplicate.id, source.id)
            XCTAssertEqual(duplicate.scene, source.scene)
            XCTAssertThrowsError(try library.archive(duplicate.id))
            try library.archive(source.id)
            XCTAssertThrowsError(try library.select(source.id))
            XCTAssertThrowsError(try library.rename(source.id, to: "Unavailable"))
            try store.save(library, replacing: nil)
            var reopened = try XCTUnwrap(store.load())
            XCTAssertEqual(reopened.activeID, duplicate.id)
            XCTAssertTrue(reopened.projects.first { $0.id == source.id }!.isArchived)
            try reopened.restore(source.id)
            try reopened.select(source.id)
            XCTAssertEqual(reopened.activeProject, source)
        }
    }

    func testInvalidNamesIDsAndScenesLeaveLibraryUnchanged() throws {
        var library = try ProjectLibrary(name: "Portrait", scene: .portrait())
        let original = library
        for name in [" ", "two\nlines", "bad\u{0000}name", String(repeating: "a", count: 81)] {
            XCTAssertThrowsError(try library.rename(library.activeID, to: name))
            XCTAssertThrowsError(try library.create(name: name, scene: .portrait()))
        }
        XCTAssertThrowsError(try library.create(name: "Duplicate ID", scene: .portrait(), id: original.activeID))
        var invalid = LightingScene.portrait()
        invalid.subject.x = .infinity
        XCTAssertThrowsError(try library.updateActiveScene(invalid))
        XCTAssertThrowsError(try library.select(UUID()))
        XCTAssertEqual(library, original)
    }

    func testCapacityIsBoundedIncludingArchivedProjects() throws {
        var library = try ProjectLibrary(name: "Original", scene: .portrait())
        let original = library.activeID
        for i in 1..<ProjectLibrary.maximumProjects {
            try library.create(name: "Project \(i)", scene: .portrait())
        }
        try library.archive(original)
        let snapshot = library
        XCTAssertThrowsError(try library.create(name: "Extra", scene: .portrait())) {
            XCTAssertEqual($0 as? ProjectLibraryError, .capacity)
        }
        XCTAssertEqual(library, snapshot)
    }

    func testOnlyArchivedProjectsCanBeDeletedAndOtherRecordsSurviveReopen() throws {
        try withStore { store in
            var library = try ProjectLibrary(name: "Original", scene: .portrait())
            let original = try XCTUnwrap(library.activeProject)
            try library.duplicate(original.id, name: "Archived copy")
            let archived = library.activeID
            try library.create(name: "Active", scene: .portrait())
            let active = try XCTUnwrap(library.activeProject)
            let before = library
            XCTAssertThrowsError(try library.deleteArchived(original.id)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .mustArchiveBeforeDeletion)
            }
            XCTAssertThrowsError(try library.deleteArchived(active.id))
            XCTAssertThrowsError(try library.deleteArchived(UUID())) {
                XCTAssertEqual($0 as? ProjectLibraryError, .notFound)
            }
            XCTAssertEqual(library, before)
            try library.archive(archived)
            try store.save(library, replacing: nil)
            let saved = try XCTUnwrap(store.load())
            try library.deleteArchived(archived)
            XCTAssertEqual(library.activeProject, active)
            XCTAssertEqual(library.projects.first { $0.id == original.id }, original)
            try store.save(library, replacing: saved)
            var reopened = try XCTUnwrap(store.load())
            XCTAssertEqual(reopened, library)
            XCTAssertFalse(reopened.projects.contains { $0.id == archived })
            XCTAssertThrowsError(try reopened.restore(archived))
        }
    }

    func testArchivedDeletionFreesCapacityAndStaleDeletionCannotOverwrite() throws {
        try withStore { store in
            var library = try ProjectLibrary(name: "Original", scene: .portrait())
            let archived = library.activeID
            for i in 1..<ProjectLibrary.maximumProjects {
                try library.create(name: "Project \(i)", scene: .portrait())
            }
            try library.archive(archived)
            try store.save(library, replacing: nil)
            let original = try XCTUnwrap(store.load())
            var deletion = original
            try deletion.deleteArchived(archived)
            try deletion.create(name: "New project", scene: .portrait())
            XCTAssertEqual(deletion.projects.count, ProjectLibrary.maximumProjects)
            var otherWindow = original
            try otherWindow.restore(archived)
            try store.save(otherWindow, replacing: original)
            XCTAssertThrowsError(try store.save(deletion, replacing: original)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertEqual(try store.load(), otherWindow)
        }
    }

    func testInvalidMetadataAndFutureSchemaAreRejected() throws {
        let initial = try ProjectLibrary(name: "Portrait", scene: .portrait())
        let data = try JSONEncoder().encode(initial)
        let base = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for (key, value): (String, Any) in [
            ("schemaVersion", 2), ("activeID", UUID().uuidString), ("projects", [])
        ] {
            var changed = base
            changed[key] = value
            let decoded = try JSONDecoder().decode(ProjectLibrary.self, from: JSONSerialization.data(withJSONObject: changed))
            XCTAssertThrowsError(try decoded.validated())
        }
        var changed = base
        let projects = try XCTUnwrap(base["projects"] as? [[String: Any]])
        changed["projects"] = projects + projects
        let duplicate = try JSONDecoder().decode(ProjectLibrary.self, from: JSONSerialization.data(withJSONObject: changed))
        XCTAssertThrowsError(try duplicate.validated()) {
            XCTAssertEqual($0 as? ProjectLibraryError, .duplicateID)
        }
    }

    func testOversizedLibraryAndNonregularPathRemainProtected() throws {
        try withStore { store in
            try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
            let bytes = Data(repeating: 0x20, count: ProjectLibraryFileStore.maximumBytes + 1)
            try bytes.write(to: store.url)
            XCTAssertThrowsError(try store.load()) { XCTAssertEqual($0 as? ProjectLibraryError, .tooLarge) }
            let initial = try ProjectLibrary(name: "New", scene: .portrait())
            XCTAssertThrowsError(try store.save(initial, replacing: nil))
            XCTAssertEqual(try Data(contentsOf: store.url), bytes)
            try FileManager.default.removeItem(at: store.url)
            try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: true)
            XCTAssertThrowsError(try store.load()) { XCTAssertEqual($0 as? ProjectLibraryError, .notRegularFile) }
            XCTAssertThrowsError(try store.save(initial, replacing: nil))
        }
    }
}
