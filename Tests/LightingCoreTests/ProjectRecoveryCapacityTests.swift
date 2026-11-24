import Dispatch
import Foundation
import XCTest
@testable import LightingCore

final class ProjectRecoveryCapacityTests: XCTestCase {
    private func withStore(_ body: (ProjectLibraryFileStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(ProjectLibraryFileStore(directory: directory))
    }

    private func fullLibrary() throws -> (ProjectLibrary, LightingProject) {
        var library = try ProjectLibrary(name: "Archived setup", scene: .portrait())
        let archivedID = library.activeID
        for index in 1..<ProjectLibrary.maximumProjects {
            try library.create(name: "Project \(index)", scene: .portrait())
        }
        try library.archive(archivedID)
        return (library, try XCTUnwrap(library.projects.first { $0.id == archivedID }))
    }

    func testConfirmedArchiveReplacementRecoversFullLibraryAndPreservesNewerUnrelatedEdits() throws {
        try withStore { store in
            let (baseline, candidate) = try fullLibrary()
            try store.save(baseline, replacing: nil)
            var newer = baseline
            var remoteScene = try XCTUnwrap(newer.activeProject?.scene)
            remoteScene.lights[0].candela = 2222
            try newer.updateActiveScene(remoteScene)
            try newer.rename(newer.activeID, to: "Other window edit")
            try store.save(newer, replacing: baseline)
            var local = LightingScene.portrait()
            local.lights[0].candela = 1111

            let recovered = try store.saveRecoveryCopy(name: "  Local recovery  ", scene: local,
                                                       replacingArchived: candidate)
            XCTAssertEqual(recovered.projects.count, ProjectLibrary.maximumProjects)
            XCTAssertFalse(newer.projects.contains { $0.id == recovered.activeID })
            XCTAssertFalse(recovered.projects.contains { $0.id == candidate.id })
            XCTAssertEqual(recovered.activeProject?.name, "Local recovery")
            XCTAssertEqual(recovered.activeProject?.scene, local)
            XCTAssertEqual(recovered.activeProject?.isArchived, false)
            XCTAssertEqual(recovered.projects.filter { $0.id != recovered.activeID },
                           newer.projects.filter { $0.id != candidate.id })
            XCTAssertEqual(try store.load(), recovered)
        }
    }

    func testChangedRestoredAndRemovedCandidatesLeaveSavedBytesUnchanged() throws {
        for change in 0..<4 {
            try withStore { store in
                let (baseline, candidate) = try fullLibrary()
                try store.save(baseline, replacing: nil)
                var newer = baseline
                if change == 3 {
                    try newer.deleteArchived(candidate.id)
                    // Keep the library full: a newly free slot should instead
                    // permit a nondestructive append, covered separately below.
                    try newer.create(name: "Replacement saved elsewhere", scene: .portrait())
                } else {
                    try newer.restore(candidate.id)
                    if change == 0 {
                        try newer.rename(candidate.id, to: "Updated archived name")
                        try newer.archive(candidate.id)
                    } else if change == 1 {
                        let activeID = newer.activeID
                        try newer.select(candidate.id)
                        var changedScene = candidate.scene
                        changedScene.lights[0].candela = 777
                        try newer.updateActiveScene(changedScene)
                        try newer.select(activeID)
                        try newer.archive(candidate.id)
                    }
                    // change == 2 deliberately leaves the candidate restored.
                }
                try store.save(newer, replacing: baseline)
                let bytes = try Data(contentsOf: store.url)
                XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Recovery", scene: .portrait(),
                                                                replacingArchived: candidate)) {
                    XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
                }
                XCTAssertEqual(try Data(contentsOf: store.url), bytes)
                XCTAssertEqual(try store.load(), newer)
            }
        }
    }

    func testActiveAndUnarchivedRecordsCannotBeUsedAsReplacement() throws {
        try withStore { store in
            let (baseline, _) = try fullLibrary()
            try store.save(baseline, replacing: nil)
            let bytes = try Data(contentsOf: store.url)
            let active = try XCTUnwrap(baseline.activeProject)
            let inactive = try XCTUnwrap(baseline.projects.first { !$0.isArchived && $0.id != baseline.activeID })
            for candidate in [active, inactive] {
                XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Recovery", scene: .portrait(),
                                                                replacingArchived: candidate)) {
                    XCTAssertEqual($0 as? ProjectLibraryError, .mustArchiveBeforeDeletion)
                }
                XCTAssertEqual(try Data(contentsOf: store.url), bytes)
            }
            XCTAssertEqual(try store.load(), baseline)
        }
    }

    func testCapacityFreedAfterSelectionKeepsConfirmedArchiveAndEveryLatestRecord() throws {
        try withStore { store in
            let (baseline, candidate) = try fullLibrary()
            try store.save(baseline, replacing: nil)
            var newer = baseline
            let removedID = try XCTUnwrap(newer.projects.first {
                $0.id != newer.activeID && $0.id != candidate.id
            }?.id)
            try newer.archive(removedID)
            try newer.deleteArchived(removedID)
            try newer.rename(newer.activeID, to: "Latest saved name")
            try store.save(newer, replacing: baseline)
            var local = LightingScene.portrait()
            local.lights[0].candela = 1234

            let recovered = try store.saveRecoveryCopy(name: "Local recovery", scene: local,
                                                       replacingArchived: candidate)
            XCTAssertEqual(recovered.projects.count, ProjectLibrary.maximumProjects)
            XCTAssertEqual(recovered.projects.first { $0.id == candidate.id }, candidate)
            XCTAssertEqual(recovered.projects.filter { $0.id != recovered.activeID }, newer.projects)
            XCTAssertEqual(recovered.activeProject?.scene, local)
            XCTAssertEqual(try store.load(), recovered)
        }
    }

    func testAvailableCapacityNeverRemovesEvenAnActiveSelectedRecord() throws {
        try withStore { store in
            let baseline = try ProjectLibrary(name: "Current project", scene: .portrait())
            let candidate = try XCTUnwrap(baseline.activeProject)
            try store.save(baseline, replacing: nil)
            let recovered = try store.saveRecoveryCopy(name: "Recovery", scene: .portrait(),
                                                       replacingArchived: candidate)
            XCTAssertEqual(recovered.projects.count, 2)
            XCTAssertEqual(recovered.projects.first { $0.id == candidate.id }, candidate)
            XCTAssertNotEqual(recovered.activeID, candidate.id)
            XCTAssertEqual(try store.load(), recovered)
        }
    }

    func testOversizedRecoveryEncodingDoesNotRemoveArchiveOrChangeSavedBytes() throws {
        try withStore { store in
            let (baseline, candidate) = try fullLibrary()
            try store.save(baseline, replacing: nil)
            let bytes = try Data(contentsOf: store.url)
            var oversized = LightingScene.portrait()
            // The legacy scene contract permits a long combining sequence as
            // one grapheme. Exercise the real encoded-library size guard after
            // the local archive removal, without injecting a fake write error.
            oversized.lights[0].name = "A" + String(repeating: "\u{0301}",
                count: ProjectLibraryFileStore.maximumBytes / 2 + 1)
            XCTAssertEqual(oversized.lights[0].name.count, 1)
            XCTAssertNoThrow(try oversized.validated())
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Recovery", scene: oversized,
                                                            replacingArchived: candidate)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .tooLarge)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), bytes)
            XCTAssertEqual(try store.load(), baseline)
            XCTAssertEqual(try store.load()?.projects.first { $0.id == candidate.id }, candidate)
        }
    }

    func testInvalidRecoveryInputPreservesCandidateAndSavedBytes() throws {
        try withStore { store in
            let (baseline, candidate) = try fullLibrary()
            try store.save(baseline, replacing: nil)
            let bytes = try Data(contentsOf: store.url)
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "", scene: .portrait(),
                                                            replacingArchived: candidate)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .invalidName)
            }
            var invalid = LightingScene.portrait()
            invalid.subject.x = .infinity
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Recovery", scene: invalid,
                                                            replacingArchived: candidate)) {
                XCTAssertEqual($0 as? SceneError, .invalidScene)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), bytes)
            XCTAssertEqual(try store.load(), baseline)
        }
    }

    func testMissingOrCorruptLibraryCannotTriggerReplacementOrLegacyMigration() throws {
        try withStore { store in
            let (_, candidate) = try fullLibrary()
            try SceneFileStore(url: store.legacyURL).save(.portrait())
            let legacyBytes = try Data(contentsOf: store.legacyURL)
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Recovery", scene: .portrait(),
                                                            replacingArchived: candidate)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .invalidLibrary)
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.url.path))
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacyBytes)
            let corrupt = Data("invalid library".utf8)
            try corrupt.write(to: store.url)
            XCTAssertThrowsError(try store.saveRecoveryCopy(name: "Recovery", scene: .portrait(),
                                                            replacingArchived: candidate))
            XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacyBytes)
        }
    }

    private final class Outcomes: @unchecked Sendable {
        private let lock = NSLock()
        private var results: [Result<UUID, ProjectLibraryError>] = []
        func append(_ result: Result<UUID, ProjectLibraryError>) {
            lock.lock()
            defer { lock.unlock() }
            results.append(result)
        }
        func snapshot() -> [Result<UUID, ProjectLibraryError>] {
            lock.lock()
            defer { lock.unlock() }
            return results
        }
    }

    func testConcurrentConfirmedReplacementsAllowOneWinnerWithoutDeletingOtherProjects() throws {
        try withStore { store in
            let (baseline, candidate) = try fullLibrary()
            try store.save(baseline, replacing: nil)
            let outcomes = Outcomes()
            let directory = store.directory
            let attempts = 8
            DispatchQueue.concurrentPerform(iterations: attempts) { index in
                do {
                    let recovered = try ProjectLibraryFileStore(directory: directory)
                        .saveRecoveryCopy(name: "Recovery \(index)", scene: .portrait(),
                                          replacingArchived: candidate)
                    outcomes.append(.success(recovered.activeID))
                } catch let error as ProjectLibraryError {
                    outcomes.append(.failure(error))
                } catch {
                    outcomes.append(.failure(.invalidLibrary))
                }
            }
            let results = outcomes.snapshot()
            let winners = results.compactMap { try? $0.get() }
            let staleCount = results.filter {
                if case .failure(.staleSnapshot) = $0 { return true }
                return false
            }.count
            let latest = try XCTUnwrap(store.load())
            XCTAssertEqual(results.count, attempts)
            XCTAssertEqual(winners.count, 1)
            XCTAssertEqual(staleCount, attempts - 1)
            XCTAssertEqual(latest.activeID, try XCTUnwrap(winners.first))
            XCTAssertEqual(latest.projects.count, ProjectLibrary.maximumProjects)
            XCTAssertEqual(latest.projects.filter { $0.id != latest.activeID },
                           baseline.projects.filter { $0.id != candidate.id })
        }
    }
}
