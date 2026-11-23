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


    // The collector protects test observations; the store must independently
    // serialize its own check-and-write transaction across different instances.
    private final class Observations<Value: Sendable>: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [Value] = []

        func append(_ value: Value) {
            lock.lock()
            defer { lock.unlock() }
            values.append(value)
        }

        func snapshot() -> [Value] {
            lock.lock()
            defer { lock.unlock() }
            return values
        }
    }

    private enum SaveOutcome: Equatable, Sendable {
        case saved(String)
        case stale
        case unexpected(String)
    }

    private func assertSingleWinner(_ outcomes: [SaveOutcome], store: ProjectLibraryFileStore,
                                    attempts: Int) throws {
        XCTAssertEqual(outcomes.count, attempts)
        let winners = outcomes.compactMap { outcome -> String? in
            if case let .saved(name) = outcome { return name }
            return nil
        }
        XCTAssertEqual(winners.count, 1, "Only one snapshot may commit")
        XCTAssertEqual(outcomes.filter { $0 == .stale }.count, attempts - 1)
        XCTAssertEqual(try store.load()?.activeProject?.name, try XCTUnwrap(winners.first))
    }

    func testConcurrentFirstSavesAllowExactlyOneWriter() throws {
        try withStore { store in
            let outcomes = Observations<SaveOutcome>()
            let attempts = 12
            let directory = store.directory
            DispatchQueue.concurrentPerform(iterations: attempts) { index in
                let name = "New \(index)"
                do {
                    let candidate = try ProjectLibrary(name: name, scene: .portrait())
                    try ProjectLibraryFileStore(directory: directory).save(candidate, replacing: nil)
                    outcomes.append(.saved(name))
                } catch ProjectLibraryError.staleSnapshot {
                    outcomes.append(.stale)
                } catch {
                    outcomes.append(.unexpected(String(describing: error)))
                }
            }
            try assertSingleWinner(outcomes.snapshot(), store: store, attempts: attempts)
        }
    }

    func testConcurrentEditsFromSameSnapshotAllowExactlyOneWriter() throws {
        try withStore { store in
            let baseline = try ProjectLibrary(name: "Original", scene: .portrait())
            try store.save(baseline, replacing: nil)
            let outcomes = Observations<SaveOutcome>()
            let attempts = 12
            let directory = store.directory
            DispatchQueue.concurrentPerform(iterations: attempts) { index in
                let name = "Edit \(index)"
                do {
                    var candidate = baseline
                    try candidate.rename(candidate.activeID, to: name)
                    try ProjectLibraryFileStore(directory: directory).save(candidate, replacing: baseline)
                    outcomes.append(.saved(name))
                } catch ProjectLibraryError.staleSnapshot {
                    outcomes.append(.stale)
                } catch {
                    outcomes.append(.unexpected(String(describing: error)))
                }
            }
            try assertSingleWinner(outcomes.snapshot(), store: store, attempts: attempts)
            XCTAssertEqual(try store.load()?.activeID, baseline.activeID)
            XCTAssertEqual(try store.load()?.activeProject?.scene, baseline.activeProject?.scene)
        }
    }

    func testConcurrentLegacyMigrationReturnsOneStableIdentity() throws {
        try withStore { store in
            try SceneFileStore(url: store.legacyURL).save(.portrait())
            let originalBytes = try Data(contentsOf: store.legacyURL)
            let outcomes = Observations<ProjectLibrary?>()
            let attempts = 12
            let directory = store.directory
            DispatchQueue.concurrentPerform(iterations: attempts) { _ in
                do {
                    outcomes.append(try ProjectLibraryFileStore(directory: directory).load())
                } catch {
                    outcomes.append(nil)
                }
            }
            let results = outcomes.snapshot()
            let persisted = try XCTUnwrap(store.load())
            XCTAssertEqual(results.count, attempts)
            XCTAssertTrue(results.allSatisfy { $0 == persisted },
                          "Every window must observe the same migrated snapshot and ID")
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), originalBytes)
        }
    }

    func testRecoveryCopyPreservesNewerOriginalAndOtherProjects() throws {
        try withStore { store in
            var baseline = try ProjectLibrary(name: "Portrait", scene: .portrait())
            let originalID = baseline.activeID
            try baseline.create(name: "Other", scene: .portrait())
            try baseline.select(originalID)
            try store.save(baseline, replacing: nil)
            var local = try XCTUnwrap(baseline.activeProject?.scene)
            local.lights[0].candela = 1111
            var stale = baseline
            try stale.updateActiveScene(local)
            var newer = baseline
            var remote = try XCTUnwrap(newer.activeProject?.scene)
            remote.lights[0].candela = 2222
            try newer.updateActiveScene(remote)
            try newer.rename(originalID, to: "Newer original")
            try store.save(newer, replacing: baseline)
            XCTAssertThrowsError(try store.save(stale, replacing: baseline)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            let recovered = try store.saveRecoveryCopy(name: "Portrait recovery", scene: local)
            XCTAssertNotEqual(recovered.activeID, originalID)
            XCTAssertEqual(recovered.activeProject?.scene, local)
            XCTAssertEqual(recovered.activeProject?.name, "Portrait recovery")
            XCTAssertEqual(recovered.projects.filter { $0.id != recovered.activeID }, newer.projects)
            XCTAssertEqual(try store.load(), recovered)
        }
    }

    func testRecoveryCopyAtCapacityAndInvalidInputsLeaveBytesUnchanged() throws {
        try withStore { store in
            var library = try ProjectLibrary(name: "Original", scene: .portrait())
            for i in 1..<ProjectLibrary.maximumProjects {
                try library.create(name: "Project \(i)", scene: .portrait())
            }
            try store.save(library, replacing: nil)
            let bytes = try Data(contentsOf: store.url)
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Copy", scene: .portrait())) {
                XCTAssertEqual($0 as? ProjectLibraryError, .capacity)
            }
            var invalid = LightingScene.portrait()
            invalid.subject.x = .infinity
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Invalid", scene: invalid))
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "", scene: .portrait()))
            XCTAssertEqual(try Data(contentsOf: store.url), bytes)
            XCTAssertEqual(try store.load(), library)
        }
    }

    func testRecoveryCopyRefusesMissingOrCorruptLibrary() throws {
        try withStore { store in
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Copy", scene: .portrait())) {
                XCTAssertEqual($0 as? ProjectLibraryError, .invalidLibrary)
            }
            XCTAssertNil(try store.load())
            let initial = try ProjectLibrary(name: "Original", scene: .portrait())
            try store.save(initial, replacing: nil)
            let corrupt = Data("damaged library".utf8)
            try corrupt.write(to: store.url)
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Copy", scene: .portrait()))
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
        }
    }

    func testConcurrentRecoveryCopiesPreserveAllRecords() throws {
        try withStore { store in
            let initial = try ProjectLibrary(name: "Original", scene: .portrait())
            try store.save(initial, replacing: nil)
            let outcomes = Observations<UUID?>()
            let directory = store.directory
            let count = 12
            DispatchQueue.concurrentPerform(iterations: count) { i in
                do {
                    let result = try ProjectLibraryFileStore(directory: directory)
                        .saveRecoveryCopy(name: "Recovery \(i)", scene: .portrait())
                    outcomes.append(result.activeID)
                } catch {
                    outcomes.append(nil)
                }
            }
            let ids = outcomes.snapshot().compactMap { $0 }
            let latest = try XCTUnwrap(store.load())
            XCTAssertEqual(ids.count, count)
            XCTAssertEqual(Set(ids).count, count)
            XCTAssertEqual(latest.projects.count, count + 1)
            XCTAssertEqual(Set(latest.projects.map(\.id)), Set(ids + [initial.activeID]))
            XCTAssertEqual(latest.projects.first { $0.id == initial.activeID }, initial.activeProject)
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
