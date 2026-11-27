import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

/// Holds an inspection or transaction boundary without sleeping or blocking an
/// executor thread. Deferred release also lets failing tests drain their tasks.
private final class LibraryRecoveryGate: @unchecked Sendable {
    let entered = XCTestExpectation(description: "Library recovery reached its gate")
    private let lock = NSLock()
    private var released = false
    private var hasEntered = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func pause() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            let firstEntry = !hasEntered
            hasEntered = true
            let alreadyReleased = released
            if !alreadyReleased { continuations.append(continuation) }
            lock.unlock()
            if firstEntry { entered.fulfill() }
            if alreadyReleased { continuation.resume() }
        }
    }

    func open() {
        lock.lock()
        released = true
        let waiting = continuations
        continuations.removeAll()
        lock.unlock()
        waiting.forEach { $0.resume() }
    }
}

@MainActor
final class StudioLibraryRecoveryTests: XCTestCase {
    private enum FixtureError: Error { case timedOut }
    private let originalLibrary = Data("unreadable saved library".utf8)
    private let originalLegacy = Data("unreadable legacy setup".utf8)

    private func directory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func worker(_ base: URL) -> ProjectStore {
        ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:])
    }

    private func backingStore(_ base: URL) -> ProjectLibraryFileStore {
        ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill", isDirectory: true))
    }

    private func makeUnreadable(_ base: URL) throws -> ProjectLibraryFileStore {
        let disk = backingStore(base)
        try FileManager.default.createDirectory(at: disk.directory, withIntermediateDirectories: true)
        try originalLibrary.write(to: disk.url, options: .withoutOverwriting)
        try originalLegacy.write(to: disk.legacyURL, options: .withoutOverwriting)
        return disk
    }

    private func open(_ session: StudioSession) async throws {
        try await session.beginLibraryOperation(.load, from: session.generation).value
    }

    private func openBlocked(_ session: StudioSession) async {
        do {
            try await open(session)
            XCTFail("Unreadable storage must block the editor")
        } catch { }
        XCTAssertTrue(session.loaded)
        XCTAssertTrue(session.saveBlocked)
        XCTAssertFalse(session.isBusy)
    }

    private func archives(_ disk: ProjectLibraryFileStore) throws -> [URL] {
        let root = disk.directory.appendingPathComponent("Recovery", isDirectory: true)
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
    }

    private func assertOriginals(_ disk: ProjectLibraryFileStore,
                                 archivedLibrary: Data? = nil) throws {
        let directories = try archives(disk)
        XCTAssertEqual(directories.count, 1)
        let archive = try XCTUnwrap(directories.first)
        XCTAssertEqual(try Data(contentsOf: archive.appendingPathComponent("projects.json")),
                       archivedLibrary ?? originalLibrary)
        XCTAssertEqual(try Data(contentsOf: archive.appendingPathComponent("portrait.json")), originalLegacy)
        XCTAssertEqual(try Data(contentsOf: disk.legacyURL), originalLegacy)
    }

    private func assertStillBlocked(_ session: StudioSession, editor: StudioEditorState,
                                    generation: UUID, workspace: UUID) {
        XCTAssertEqual(session.editor, editor)
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, workspace)
        XCTAssertTrue(session.loaded)
        XCTAssertTrue(session.saveBlocked)
        XCTAssertFalse(session.saveConflict)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertNil(session.library)
        XCTAssertNil(session.saved)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
    }

    private func assertRecoveryRejected(_ session: StudioSession, snapshot: ProjectLibraryRecoverySnapshot,
                                        generation: UUID? = nil) async {
        let capturedGeneration = generation ?? session.generation
        let editor = session.editor
        let currentGeneration = session.generation
        let library = session.library
        let saved = session.saved
        let workspace = session.workspaceResetID
        let blocked = session.saveBlocked
        do {
            _ = try await session.inspectUnreadableLibrary(from: capturedGeneration)
            XCTFail("This editor must not return a recovery confirmation")
        } catch { }
        XCTAssertThrowsError(try session.recoverUnreadableLibrary(snapshot, from: capturedGeneration))
        XCTAssertThrowsError(try session.beginLibraryOperation(.recoverUnreadable(snapshot: snapshot),
                                                              from: capturedGeneration))
        XCTAssertEqual(session.editor, editor)
        XCTAssertEqual(session.generation, currentGeneration)
        XCTAssertEqual(session.library, library)
        XCTAssertEqual(session.saved, saved)
        XCTAssertEqual(session.workspaceResetID, workspace)
        XCTAssertEqual(session.saveBlocked, blocked)
    }

    private func waitFor(_ expectation: XCTestExpectation) async throws {
        guard await XCTWaiter.fulfillment(of: [expectation], timeout: 5) == .completed else {
            throw FixtureError.timedOut
        }
    }

    private func settle(_ task: Task<Void, Error>) async throws {
        let finished = XCTestExpectation(description: "Library recovery settled")
        let witness = Task { @MainActor in
            let result = await task.result
            finished.fulfill()
            return result
        }
        defer { witness.cancel() }
        try await waitFor(finished)
        try await witness.value.get()
    }

    func testBlockedRecoveryPreservesOriginalsAndAdoptsCommittedDefault() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let session = StudioSession(store: worker(base))
        await openBlocked(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        let snapshot = try await session.inspectUnreadableLibrary(from: generation)
        XCTAssertEqual(snapshot.fileCount, 2)
        XCTAssertEqual(snapshot.byteCount, originalLibrary.count + originalLegacy.count)
        XCTAssertEqual(session.editor, original)
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        XCTAssertTrue(try archives(disk).isEmpty)

        let recovering = try session.recoverUnreadableLibrary(snapshot, from: generation)
        XCTAssertTrue(session.isBusy, "Confirmation must reserve before returning a task")
        XCTAssertTrue(session.saveBlocked)
        XCTAssertFalse(session.allowsMutation(from: generation))
        XCTAssertThrowsError(try session.recoverUnreadableLibrary(snapshot, from: generation)) {
            XCTAssertEqual($0 as? ProjectLibraryOperationState.OperationError, .busy)
        }
        XCTAssertThrowsError(try session.beginLibraryOperation(.load, from: generation))
        try await recovering.value

        let committed = try XCTUnwrap(disk.load())
        XCTAssertEqual(committed.projects.count, 1)
        XCTAssertEqual(committed.activeProject?.name, "Portrait setup")
        XCTAssertEqual(try committed.validated(), committed)
        XCTAssertEqual(session.library, committed)
        XCTAssertEqual(session.scene, committed.activeProject?.scene)
        XCTAssertEqual(session.saved, session.scene)
        XCTAssertNotEqual(session.scene.lights.first?.id, original.scene.lights.first?.id)
        XCTAssertEqual(session.selection, session.scene.lights.first?.id)
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertNotEqual(session.workspaceResetID, workspace)
        XCTAssertFalse(session.saveBlocked)
        XCTAssertFalse(session.history.canUndo)
        XCTAssertFalse(session.history.canRedo)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertNil(session.feature)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.showRecoveryCapacity)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
        try assertOriginals(disk)

        var edited = session.scene
        edited.camera.x = 0.75
        XCTAssertTrue(session.replace(edited, from: session.generation))
        try await session.beginLibraryOperation(.save, from: session.generation).value
        let reopened = StudioSession(store: worker(base))
        try await open(reopened)
        XCTAssertEqual(reopened.scene, edited)
        XCTAssertEqual(reopened.library, session.library)
        try assertOriginals(disk)
    }

    func testUnloadedHealthyEmptyAndUnsavedEditorsCannotResetLibrary() async throws {
        let base = directory()
        let healthyBase = directory()
        defer {
            try? FileManager.default.removeItem(at: base)
            try? FileManager.default.removeItem(at: healthyBase)
        }
        let disk = try makeUnreadable(base)
        let snapshot = try disk.inspectUnreadableLibrary()
        let session = StudioSession(store: worker(healthyBase))
        await assertRecoveryRejected(session, snapshot: snapshot)
        XCTAssertFalse(session.loaded)
        try await open(session)
        await assertRecoveryRejected(session, snapshot: snapshot)
        XCTAssertTrue(session.canCreateInitialProject)
        var draft = session.scene
        draft.camera.x = 1.25
        XCTAssertTrue(session.replace(draft, from: session.generation))
        await assertRecoveryRejected(session, snapshot: snapshot)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertTrue(session.history.canUndo)
        XCTAssertNil(try backingStore(healthyBase).load())
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        XCTAssertTrue(try archives(disk).isEmpty)
    }

    func testUnreadableLegacyOnlyRecoveryPreservesLegacyAndReopensNewLibrary() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = backingStore(base)
        try FileManager.default.createDirectory(at: disk.directory, withIntermediateDirectories: true)
        try originalLegacy.write(to: disk.legacyURL, options: .withoutOverwriting)
        let session = StudioSession(store: worker(base))
        await openBlocked(session)
        let snapshot = try await session.inspectUnreadableLibrary(from: session.generation)
        XCTAssertEqual(snapshot.fileCount, 1)
        XCTAssertEqual(snapshot.byteCount, originalLegacy.count)
        XCTAssertFalse(FileManager.default.fileExists(atPath: disk.url.path))
        try await session.beginLibraryOperation(.recoverUnreadable(snapshot: snapshot),
                                                from: session.generation).value
        XCTAssertFalse(session.saveBlocked)
        XCTAssertEqual(try disk.load(), session.library)
        XCTAssertEqual(session.saved, session.scene)
        let directories = try archives(disk)
        XCTAssertEqual(directories.count, 1)
        let archive = try XCTUnwrap(directories.first)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: archive.path), ["portrait.json"])
        XCTAssertEqual(try Data(contentsOf: archive.appendingPathComponent("portrait.json")), originalLegacy)
        XCTAssertEqual(try Data(contentsOf: disk.legacyURL), originalLegacy)
        let reopened = StudioSession(store: worker(base))
        try await open(reopened)
        XCTAssertEqual(reopened.library, session.library)
        XCTAssertEqual(reopened.scene, session.scene)
    }

    func testHealthySavedAndDirtyEditorsCannotResetLibrary() async throws {
        let base = directory()
        let healthyBase = directory()
        defer {
            try? FileManager.default.removeItem(at: base)
            try? FileManager.default.removeItem(at: healthyBase)
        }
        let disk = try makeUnreadable(base)
        let snapshot = try disk.inspectUnreadableLibrary()
        let session = StudioSession(store: worker(healthyBase))
        try await open(session)
        try await session.beginLibraryOperation(.save, from: session.generation).value
        let bytes = try Data(contentsOf: backingStore(healthyBase).url)
        await assertRecoveryRejected(session, snapshot: snapshot)
        var edited = session.scene
        edited.camera.x = 1
        XCTAssertTrue(session.replace(edited, from: session.generation))
        session.editChanged(true, owner: "dirty control", from: session.generation)
        await assertRecoveryRejected(session, snapshot: snapshot)
        XCTAssertTrue(session.history.isEditing)
        XCTAssertEqual(try Data(contentsOf: backingStore(healthyBase).url), bytes)
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
    }

    func testCallerSuppliedDraftRemainsProtectedEvenAfterLoadFailure() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        var draft = LightingScene.portrait()
        draft.camera.x = 1.5
        let session = StudioSession(editor: try .init(scene: draft), store: worker(base))
        await openBlocked(session)
        await assertRecoveryRejected(session, snapshot: try disk.inspectUnreadableLibrary())
        XCTAssertEqual(session.scene, draft)
        XCTAssertTrue(session.saveBlocked)
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        XCTAssertTrue(try archives(disk).isEmpty)
    }

    func testStaleEditorCannotInspectOrConfirmRecovery() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let session = StudioSession(store: worker(base))
        await openBlocked(session)
        let snapshot = try await session.inspectUnreadableLibrary(from: session.generation)
        await assertRecoveryRejected(session, snapshot: snapshot, generation: UUID())
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        XCTAssertTrue(try archives(disk).isEmpty)
    }

    func testChangedFilesRejectConfirmationAndFreshInspectionCanRetry() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let session = StudioSession(store: worker(base))
        await openBlocked(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        let snapshot = try await session.inspectUnreadableLibrary(from: generation)
        let changedBytes = Data("another unreadable saved library".utf8)
        try changedBytes.write(to: disk.url, options: .atomic)
        do {
            try await session.recoverUnreadableLibrary(snapshot, from: generation).value
            XCTFail("An old confirmation cannot replace changed bytes")
        } catch ProjectLibraryError.staleSnapshot { }
        assertStillBlocked(session, editor: original, generation: generation, workspace: workspace)
        XCTAssertEqual(try Data(contentsOf: disk.url), changedBytes)
        XCTAssertTrue(try archives(disk).isEmpty)
        let fresh = try await session.inspectUnreadableLibrary(from: generation)
        XCTAssertNotEqual(fresh, snapshot)
        try await session.recoverUnreadableLibrary(fresh, from: generation).value
        XCTAssertEqual(try disk.load(), session.library)
        try assertOriginals(disk, archivedLibrary: changedBytes)
    }

    func testArchiveFailureLeavesBlockedEditorAndOriginalBytesThenRetrySucceeds() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let session = StudioSession(store: worker(base))
        await openBlocked(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        let snapshot = try await session.inspectUnreadableLibrary(from: generation)
        let archiveRoot = disk.directory.appendingPathComponent("Recovery")
        let obstruction = Data("existing file must remain untouched".utf8)
        try obstruction.write(to: archiveRoot, options: .withoutOverwriting)
        do {
            try await session.recoverUnreadableLibrary(snapshot, from: generation).value
            XCTFail("The original files must be preserved before any replacement")
        } catch ProjectLibraryError.recoveryArchiveFailed { }
        assertStillBlocked(session, editor: original, generation: generation, workspace: workspace)
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        XCTAssertEqual(try Data(contentsOf: disk.legacyURL), originalLegacy)
        XCTAssertEqual(try Data(contentsOf: archiveRoot), obstruction)
        try FileManager.default.removeItem(at: archiveRoot)
        let fresh = try await session.inspectUnreadableLibrary(from: generation)
        try await session.recoverUnreadableLibrary(fresh, from: generation).value
        XCTAssertFalse(session.saveBlocked)
        XCTAssertEqual(try disk.load(), session.library)
        try assertOriginals(disk)
    }

    func testCancellationBeforeStorageLeavesBytesUntouchedAndCanRetry() async throws {
        let base = directory()
        let gate = LibraryRecoveryGate()
        defer { gate.open(); try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let store = worker(base)
        let session = StudioSession(store: store, execute: { request in
            if case .recoverUnreadable = request.operation { await gate.pause() }
            return try await store.perform(request)
        })
        await openBlocked(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        let snapshot = try await session.inspectUnreadableLibrary(from: generation)
        let recovering = try session.recoverUnreadableLibrary(snapshot, from: generation)
        defer { recovering.cancel() }
        try await waitFor(gate.entered)
        recovering.cancel()
        gate.open()
        do {
            try await settle(recovering)
            XCTFail("Cancellation before storage begins must skip recovery")
        } catch is CancellationError { }
        assertStillBlocked(session, editor: original, generation: generation, workspace: workspace)
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        XCTAssertTrue(try archives(disk).isEmpty)
        let fresh = try await session.inspectUnreadableLibrary(from: generation)
        try await session.recoverUnreadableLibrary(fresh, from: generation).value
        XCTAssertEqual(try disk.load(), session.library)
        try assertOriginals(disk)
    }

    func testCancelledObserverAfterCommitStillAdoptsRecoveryExactlyOnce() async throws {
        try await verifyCommittedRecovery(cancelSession: false)
    }

    func testCancelledSessionTaskAfterCommitStillAdoptsRecoveryExactlyOnce() async throws {
        try await verifyCommittedRecovery(cancelSession: true)
    }

    private func verifyCommittedRecovery(cancelSession: Bool) async throws {
        let base = directory()
        let gate = LibraryRecoveryGate()
        defer { gate.open(); try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let store = worker(base)
        let session = StudioSession(store: store, execute: { request in
            let receipt = try await store.perform(request)
            if case .recoverUnreadable = request.operation { await gate.pause() }
            return receipt
        })
        await openBlocked(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        let snapshot = try await session.inspectUnreadableLibrary(from: generation)
        let recovering = try session.recoverUnreadableLibrary(snapshot, from: generation)
        let observer = Task { try await recovering.value }
        defer { recovering.cancel(); observer.cancel() }
        try await waitFor(gate.entered)
        let committed = try XCTUnwrap(disk.load())
        let bytes = try Data(contentsOf: disk.url)
        XCTAssertEqual(session.editor, original)
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, workspace)
        XCTAssertTrue(session.saveBlocked, "A disk commit must not unblock before receipt adoption")
        XCTAssertTrue(session.isBusy)
        await assertRecoveryRejected(session, snapshot: snapshot)
        try assertOriginals(disk)
        if cancelSession { recovering.cancel() } else { observer.cancel() }
        gate.open()
        try await settle(recovering)
        try await settle(observer)
        XCTAssertEqual(session.library, committed)
        XCTAssertEqual(session.scene, committed.activeProject?.scene)
        XCTAssertEqual(session.saved, session.scene)
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertNotEqual(session.workspaceResetID, workspace)
        XCTAssertFalse(session.saveBlocked)
        XCTAssertFalse(session.history.canUndo)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
        let adopted = session.editor
        let adoptedGeneration = session.generation
        try await recovering.value
        try await observer.value
        XCTAssertEqual(session.editor, adopted)
        XCTAssertEqual(session.generation, adoptedGeneration)
        await assertRecoveryRejected(session, snapshot: snapshot, generation: generation)
        XCTAssertEqual(try Data(contentsOf: disk.url), bytes)
        try assertOriginals(disk)
    }

    func testCompetingWindowConfirmationsProduceOnlyOneCommit() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let sessions = [StudioSession(store: worker(base)), StudioSession(store: worker(base))]
        for session in sessions { await openBlocked(session) }
        let first = try await sessions[0].inspectUnreadableLibrary(from: sessions[0].generation)
        let second = try await sessions[1].inspectUnreadableLibrary(from: sessions[1].generation)
        XCTAssertEqual(first, second)
        let originalEditors = sessions.map(\.editor)
        let originalGenerations = sessions.map(\.generation)
        let tasks = [try sessions[0].recoverUnreadableLibrary(first, from: sessions[0].generation),
                     try sessions[1].recoverUnreadableLibrary(second, from: sessions[1].generation)]
        var winners = 0
        var loser: StudioSession?
        for (index, task) in tasks.enumerated() {
            do {
                try await task.value
                winners += 1
                XCTAssertFalse(sessions[index].saveBlocked)
            } catch ProjectLibraryError.staleSnapshot {
                loser = sessions[index]
                XCTAssertTrue(sessions[index].saveBlocked)
                XCTAssertEqual(sessions[index].editor, originalEditors[index])
                XCTAssertEqual(sessions[index].generation, originalGenerations[index])
                XCTAssertNil(sessions[index].library)
            }
            XCTAssertFalse(sessions[index].isBusy)
            XCTAssertNil(sessions[index].operationTask)
        }
        XCTAssertEqual(winners, 1)
        let committed = try XCTUnwrap(disk.load())
        try assertOriginals(disk)
        let blocked = try XCTUnwrap(loser)
        do {
            _ = try await blocked.inspectUnreadableLibrary(from: blocked.generation)
            XCTFail("A still-blocked window must recognize another window's readable replacement")
        } catch ProjectLibraryError.recoveryNotNeeded { }
        XCTAssertTrue(blocked.saveBlocked, "Read-only inspection must not adopt the other window's library")
        XCTAssertNil(blocked.library)
        XCTAssertEqual(try disk.load(), committed)
        try await open(blocked)
        XCTAssertFalse(blocked.saveBlocked)
        XCTAssertEqual(blocked.library, committed)
        XCTAssertEqual(sessions[0].library, sessions[1].library)
        try assertOriginals(disk)
    }

    func testDelayedInspectionRejectsReceiptAfterEditorRecoveryChangesGeneration() async throws {
        let base = directory()
        let gate = LibraryRecoveryGate()
        defer { gate.open(); try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let store = worker(base)
        let session = StudioSession(store: store, inspectUnreadable: {
            let snapshot = try await store.inspectUnreadableLibrary()
            await gate.pause()
            return snapshot
        })
        await openBlocked(session)
        let generation = session.generation
        let inspection = Task { try await session.inspectUnreadableLibrary(from: generation) }
        defer { inspection.cancel() }
        try await waitFor(gate.entered)
        let confirmation = try disk.inspectUnreadableLibrary()
        try await session.recoverUnreadableLibrary(confirmation, from: generation).value
        let editor = session.editor
        gate.open()
        do {
            _ = try await inspection.value
            XCTFail("An inspection cannot return a token for an editor that has changed")
        } catch ProjectLibraryOperationState.OperationError.staleEditor { }
        XCTAssertEqual(session.editor, editor)
        XCTAssertFalse(session.saveBlocked)
        XCTAssertEqual(try disk.load(), session.library)
        try assertOriginals(disk)
    }

    func testDelayedInspectionRejectsReceiptWhileAnotherOperationIsReserved() async throws {
        let base = directory()
        let inspectionGate = LibraryRecoveryGate()
        let recoveryGate = LibraryRecoveryGate()
        defer {
            inspectionGate.open()
            recoveryGate.open()
            try? FileManager.default.removeItem(at: base)
        }
        let disk = try makeUnreadable(base)
        let store = worker(base)
        let session = StudioSession(store: store, execute: { request in
            if case .recoverUnreadable = request.operation { await recoveryGate.pause() }
            return try await store.perform(request)
        }, inspectUnreadable: {
            let snapshot = try await store.inspectUnreadableLibrary()
            await inspectionGate.pause()
            return snapshot
        })
        await openBlocked(session)
        let generation = session.generation
        let inspection = Task { try await session.inspectUnreadableLibrary(from: generation) }
        defer { inspection.cancel() }
        try await waitFor(inspectionGate.entered)
        let recovering = try session.recoverUnreadableLibrary(disk.inspectUnreadableLibrary(), from: generation)
        defer { recovering.cancel() }
        try await waitFor(recoveryGate.entered)
        inspectionGate.open()
        do {
            _ = try await inspection.value
            XCTFail("An inspection must recheck the operation reservation after suspension")
        } catch ProjectLibraryOperationState.OperationError.busy { }
        XCTAssertTrue(session.saveBlocked)
        XCTAssertTrue(session.isBusy)
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        recoveryGate.open()
        try await settle(recovering)
        XCTAssertEqual(try disk.load(), session.library)
        try assertOriginals(disk)
    }

    func testCancelledInspectionCannotReturnConfirmationOrChangeFiles() async throws {
        let base = directory()
        let gate = LibraryRecoveryGate()
        defer { gate.open(); try? FileManager.default.removeItem(at: base) }
        let disk = try makeUnreadable(base)
        let store = worker(base)
        let session = StudioSession(store: store, inspectUnreadable: {
            let snapshot = try await store.inspectUnreadableLibrary()
            await gate.pause()
            return snapshot
        })
        await openBlocked(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        let inspection = Task { try await session.inspectUnreadableLibrary(from: generation) }
        defer { inspection.cancel() }
        try await waitFor(gate.entered)
        inspection.cancel()
        gate.open()
        do {
            _ = try await inspection.value
            XCTFail("A cancelled check must not supply a confirmation")
        } catch is CancellationError { }
        assertStillBlocked(session, editor: original, generation: generation, workspace: workspace)
        XCTAssertEqual(try Data(contentsOf: disk.url), originalLibrary)
        XCTAssertEqual(try Data(contentsOf: disk.legacyURL), originalLegacy)
        XCTAssertTrue(try archives(disk).isEmpty)
    }
}
