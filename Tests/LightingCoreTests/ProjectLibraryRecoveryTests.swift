import Foundation
import XCTest
@testable import LightingCore

final class ProjectLibraryRecoveryTests: XCTestCase {
    private let corrupt = Data([0x00, 0xFF, 0x7B, 0x22, 0x0A, 0x20])

    private func withStore(_ work: (ProjectLibraryFileStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try work(ProjectLibraryFileStore(directory: directory))
    }

    private func recoveryRoot(_ store: ProjectLibraryFileStore) -> URL {
        store.directory.appendingPathComponent("Recovery", isDirectory: true)
    }

    private func replacement() throws -> ProjectLibrary {
        var scene = LightingScene.portrait()
        scene.lights[0].candela = 1_234
        return try ProjectLibrary(name: "Recovered setup", scene: scene)
    }

    func testInspectionIsReadOnlyAndRecoveryPreservesExactOriginalFiles() throws {
        try withStore { store in
            let legacy = try SceneCodec.encode(.portrait())
            try corrupt.write(to: store.url)
            try legacy.write(to: store.legacyURL)
            let observed = try store.inspectUnreadableLibrary()
            XCTAssertEqual(observed.fileCount, 2)
            XCTAssertEqual(observed.byteCount, corrupt.count + legacy.count)
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacy)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))

            let candidate = try replacement()
            let result = try store.recoverUnreadableLibrary(candidate, replacing: observed)
            XCTAssertEqual(result.library, candidate)
            XCTAssertEqual(try store.load(), candidate)
            XCTAssertEqual(result.archiveDirectory.deletingLastPathComponent(), recoveryRoot(store))
            XCTAssertEqual(try Data(contentsOf: result.archiveDirectory.appendingPathComponent("projects.json")), corrupt)
            XCTAssertEqual(try Data(contentsOf: result.archiveDirectory.appendingPathComponent("portrait.json")), legacy)
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacy)
            XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: result.archiveDirectory.path)),
                           ["projects.json", "portrait.json"])
        }
    }

    func testCorruptLegacyCanBeRecoveredWithoutChangingItsOriginalBytes() throws {
        try withStore { store in
            try corrupt.write(to: store.legacyURL)
            XCTAssertThrowsError(try store.load())
            let observed = try store.inspectUnreadableLibrary()
            XCTAssertEqual(observed.fileCount, 1)
            XCTAssertEqual(observed.byteCount, corrupt.count)
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.url.path))
            let result = try store.recoverUnreadableLibrary(replacement(), replacing: observed)
            XCTAssertEqual(try store.load(), result.library)
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), corrupt)
            XCTAssertEqual(try Data(contentsOf: result.archiveDirectory.appendingPathComponent("portrait.json")), corrupt)
            XCTAssertFalse(FileManager.default.fileExists(atPath: result.archiveDirectory.appendingPathComponent("projects.json").path))
        }
    }

    func testValidLibraryAndValidLegacyNeverAuthorizeRecoveryOrMigration() throws {
        try withStore { store in
            let candidate = try replacement()
            let libraryBytes = try JSONEncoder().encode(candidate)
            try libraryBytes.write(to: store.url)
            try corrupt.write(to: store.legacyURL)
            XCTAssertThrowsError(try store.inspectUnreadableLibrary()) {
                XCTAssertEqual($0 as? ProjectLibraryError, .recoveryNotNeeded)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), libraryBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
        try withStore { store in
            var scene = LightingScene.portrait()
            scene.schemaVersion = 1
            let legacy = try JSONEncoder().encode(scene)
            try legacy.write(to: store.legacyURL)
            XCTAssertThrowsError(try store.inspectUnreadableLibrary()) {
                XCTAssertEqual($0 as? ProjectLibraryError, .recoveryNotNeeded)
            }
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacy)
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.url.path), "Inspection must not migrate a valid legacy scene")
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
    }

    func testMissingLibraryNeverAuthorizesRecoveryOrCreatesFiles() throws {
        try withStore { store in
            XCTAssertThrowsError(try store.inspectUnreadableLibrary()) {
                XCTAssertEqual($0 as? ProjectLibraryError, .recoveryNotNeeded)
            }
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: store.directory.path), [])
            let absent = ProjectLibraryFileStore(directory: store.directory.appendingPathComponent("absent"))
            XCTAssertThrowsError(try absent.inspectUnreadableLibrary()) {
                XCTAssertEqual($0 as? ProjectLibraryError, .recoveryNotNeeded)
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: absent.directory.path))
        }
    }

    func testChangedCorruptBytesAreNotOverwrittenOrArchived() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let observed = try store.inspectUnreadableLibrary()
            let newer = Data("different corrupt bytes".utf8)
            try newer.write(to: store.url)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), newer)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
    }

    func testReplacedFileWithSameBytesStillRequiresFreshConfirmation() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let observed = try store.inspectUnreadableLibrary()
            try corrupt.write(to: store.url, options: .atomic)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
    }

    func testChangedLegacyBytesAndPresenceInvalidateTheCompleteSnapshot() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let withoutLegacy = try store.inspectUnreadableLibrary()
            let legacy = Data("old legacy bytes".utf8)
            try legacy.write(to: store.legacyURL)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: withoutLegacy)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            let withLegacy = try store.inspectUnreadableLibrary()
            let newer = Data("new legacy bytes".utf8)
            try newer.write(to: store.legacyURL)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: withLegacy)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            let changedLegacy = try store.inspectUnreadableLibrary()
            try FileManager.default.removeItem(at: store.legacyURL)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: changedLegacy)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
    }

    func testNowValidOrMissingLibraryRejectsAnEarlierObservation() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let observed = try store.inspectUnreadableLibrary()
            let newer = try JSONEncoder().encode(replacement())
            try newer.write(to: store.url)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), newer)
            try FileManager.default.removeItem(at: store.url)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.url.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
    }

    func testObservationCannotAuthorizeAnotherDirectory() throws {
        try withStore { first in
            try withStore { second in
                try corrupt.write(to: first.url)
                try corrupt.write(to: second.url)
                let observed = try first.inspectUnreadableLibrary()
                XCTAssertThrowsError(try second.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                    XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
                }
                XCTAssertEqual(try Data(contentsOf: first.url), corrupt)
                XCTAssertEqual(try Data(contentsOf: second.url), corrupt)
                XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(second).path))
            }
        }
    }

    func testInvalidReplacementLeavesSourcesUnchangedWithoutCreatingArchive() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let observed = try store.inspectUnreadableLibrary()
            let encoded = try JSONEncoder().encode(replacement())
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            object["schemaVersion"] = ProjectLibrary.currentSchemaVersion + 1
            let invalid = try JSONDecoder().decode(ProjectLibrary.self, from: JSONSerialization.data(withJSONObject: object))
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(invalid, replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .unsupportedVersion)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
    }

    func testArchiveFailureLeavesEveryOriginalAndExistingEvidenceUntouched() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let legacy = Data("legacy evidence".utf8)
            try legacy.write(to: store.legacyURL)
            let observed = try store.inspectUnreadableLibrary()
            let existingEvidence = Data("existing evidence must survive".utf8)
            try existingEvidence.write(to: recoveryRoot(store))
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .recoveryArchiveFailed)
                XCTAssertFalse($0.localizedDescription.contains(store.directory.path))
            }
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacy)
            XCTAssertEqual(try Data(contentsOf: recoveryRoot(store)), existingEvidence)
        }
    }

    func testSymlinkedArchiveDirectoryIsRejectedWithoutWritingThroughIt() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let observed = try store.inspectUnreadableLibrary()
            let target = store.directory.appendingPathComponent("unrelated")
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            try FileManager.default.createSymbolicLink(at: recoveryRoot(store), withDestinationURL: target)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .recoveryArchiveFailed)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: target.path), [])
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: recoveryRoot(store).path), target.path)
        }
    }

    func testNonregularLibraryAndLegacyFilesNeverAuthorizeRecovery() throws {
        for filename in ["projects.json", "portrait.json"] {
            for useSymbolicLink in [false, true] {
                try withStore { store in
                    if filename == "portrait.json" { try corrupt.write(to: store.url) }
                    let location = store.directory.appendingPathComponent(filename)
                    if useSymbolicLink {
                        let target = store.directory.appendingPathComponent("original")
                        try corrupt.write(to: target)
                        try FileManager.default.createSymbolicLink(at: location, withDestinationURL: target)
                    } else {
                        try FileManager.default.createDirectory(at: location, withIntermediateDirectories: false)
                    }
                    XCTAssertThrowsError(try store.inspectUnreadableLibrary()) {
                        XCTAssertEqual($0 as? ProjectLibraryError, .notRegularFile)
                    }
                    XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
                }
            }
        }
    }

    func testSourceChangedToSymlinkAfterInspectionCannotBeRecovered() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let observed = try store.inspectUnreadableLibrary()
            let target = store.directory.appendingPathComponent("unrelated.json")
            let untouched = Data("unrelated private bytes".utf8)
            try untouched.write(to: target)
            try FileManager.default.removeItem(at: store.url)
            try FileManager.default.createSymbolicLink(at: store.url, withDestinationURL: target)
            XCTAssertThrowsError(try store.recoverUnreadableLibrary(replacement(), replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .notRegularFile)
            }
            XCTAssertEqual(try Data(contentsOf: target), untouched)
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: store.url.path), target.path)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
        }
    }

    func testSymlinkedStoreDirectoryIsRejected() throws {
        try withStore { store in
            let target = store.directory.appendingPathComponent("actual")
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            try corrupt.write(to: target.appendingPathComponent("projects.json"))
            let link = store.directory.appendingPathComponent("link")
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
            XCTAssertThrowsError(try ProjectLibraryFileStore(directory: link).inspectUnreadableLibrary()) {
                XCTAssertEqual($0 as? ProjectLibraryError, .notRegularFile)
            }
            XCTAssertEqual(try Data(contentsOf: target.appendingPathComponent("projects.json")), corrupt)
        }
    }

    func testOversizedLibraryAndLegacyRemainProtected() throws {
        for isLegacy in [false, true] {
            try withStore { store in
                if isLegacy { try corrupt.write(to: store.url) }
                let location = isLegacy ? store.legacyURL : store.url
                let limit = isLegacy ? SceneCodec.maximumBytes : ProjectLibraryFileStore.maximumBytes
                let oversized = Data(repeating: 0x20, count: limit + 1)
                try oversized.write(to: location)
                XCTAssertThrowsError(try store.inspectUnreadableLibrary()) {
                    XCTAssertEqual($0 as? ProjectLibraryError, .tooLarge)
                }
                XCTAssertEqual(try Data(contentsOf: location), oversized)
                XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
            }
        }
    }

    func testSubsequentRecoveryUsesANewArchiveAndRetainsEarlierEvidence() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let first = try store.recoverUnreadableLibrary(replacement(), replacing: store.inspectUnreadableLibrary())
            let laterBytes = Data("later corruption".utf8)
            try laterBytes.write(to: store.url)
            let second = try store.recoverUnreadableLibrary(replacement(), replacing: store.inspectUnreadableLibrary())
            XCTAssertNotEqual(first.archiveDirectory, second.archiveDirectory)
            XCTAssertEqual(try Data(contentsOf: first.archiveDirectory.appendingPathComponent("projects.json")), corrupt)
            XCTAssertEqual(try Data(contentsOf: second.archiveDirectory.appendingPathComponent("projects.json")), laterBytes)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: recoveryRoot(store).path).count, 2)
            XCTAssertEqual(try store.load(), second.library)
        }
    }

    private enum Outcome: Sendable {
        case recovered(ProjectLibraryRecoveryResult), stale, unexpected(String)
    }

    private final class Outcomes: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [Outcome] = []
        func append(_ value: Outcome) {
            lock.lock()
            defer { lock.unlock() }
            values.append(value)
        }
        func snapshot() -> [Outcome] {
            lock.lock()
            defer { lock.unlock() }
            return values
        }
    }

    func testConcurrentRecoveryHasOneCommitAndOnePreservedArchive() throws {
        try withStore { store in
            try corrupt.write(to: store.url)
            let observed = try store.inspectUnreadableLibrary()
            let outcomes = Outcomes()
            let attempts = 8
            DispatchQueue.concurrentPerform(iterations: attempts) { index in
                do {
                    let candidate = try ProjectLibrary(name: "Recovery \(index)", scene: .portrait())
                    let result = try ProjectLibraryFileStore(directory: store.directory)
                        .recoverUnreadableLibrary(candidate, replacing: observed)
                    outcomes.append(.recovered(result))
                } catch ProjectLibraryError.staleSnapshot {
                    outcomes.append(.stale)
                } catch {
                    outcomes.append(.unexpected(String(describing: error)))
                }
            }
            let results = outcomes.snapshot()
            let winners = results.compactMap { outcome -> ProjectLibraryRecoveryResult? in
                if case let .recovered(result) = outcome { return result }
                return nil
            }
            XCTAssertEqual(results.count, attempts)
            XCTAssertEqual(winners.count, 1)
            XCTAssertEqual(results.filter { if case .stale = $0 { return true }; return false }.count, attempts - 1)
            let winner = try XCTUnwrap(winners.first)
            XCTAssertEqual(try store.load(), winner.library)
            XCTAssertEqual(try Data(contentsOf: winner.archiveDirectory.appendingPathComponent("projects.json")), corrupt)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: recoveryRoot(store).path).count, 1)
        }
    }
}
