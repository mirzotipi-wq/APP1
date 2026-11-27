import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

/// Holds a transaction boundary without sleeps or blocked executor threads.
/// Opening before entry also lets failing tests release every continuation.
private final class InitialProjectGate: @unchecked Sendable {
    let entered = XCTestExpectation(description: "Initial project transaction reached its gate")
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
final class StudioInitialProjectTests: XCTestCase {
    private enum FixtureError: Error { case timedOut }

    private func directory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func worker(_ base: URL) -> ProjectStore {
        ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:])
    }

    private func backingStore(_ base: URL) -> ProjectLibraryFileStore {
        ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill", isDirectory: true))
    }

    private func open(_ session: StudioSession) async throws {
        try await session.beginLibraryOperation(.load, from: session.generation).value
    }

    private func waitFor(_ expectation: XCTestExpectation) async throws {
        guard await XCTWaiter.fulfillment(of: [expectation], timeout: 5) == .completed else {
            throw FixtureError.timedOut
        }
    }

    private func settle(_ task: Task<Void, Error>) async throws {
        let finished = XCTestExpectation(description: "Initial project operation settled")
        let witness = Task { @MainActor in
            let result = await task.result
            finished.fulfill()
            return result
        }
        defer { witness.cancel() }
        try await waitFor(finished)
        try await witness.value.get()
    }

    func testFirstCreateRequiresHealthyEmptyLoadAndSavesOnlyRequestedProject() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: worker(base))
        let next = LightingScene.portrait()
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "First project", scene: next),
                                                      from: session.generation))
        try await open(session)
        XCTAssertTrue(session.canCreateInitialProject)
        XCTAssertNil(try backingStore(base).load())
        let starter = session.scene
        let generation = session.generation
        let workspace = session.workspaceResetID

        let creating = try session.applyLibrary(.create(name: "First project", scene: next), from: generation)
        let request = try XCTUnwrap(session.libraryOperation.pending)
        XCTAssertNil(request.expected)
        XCTAssertNil(request.projectID)
        XCTAssertEqual(request.scene, starter)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertFalse(session.replace(next, from: generation))
        try await creating.value

        XCTAssertEqual(session.library?.projects.count, 1)
        XCTAssertEqual(session.library?.activeProject?.name, "First project")
        XCTAssertEqual(session.scene, next)
        XCTAssertEqual(session.saved, next)
        XCTAssertEqual(try backingStore(base).load(), session.library)
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertNotEqual(session.workspaceResetID, workspace)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertFalse(session.history.canUndo)
        XCTAssertFalse(session.history.canRedo)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
    }

    func testValidatedFirstImportKeepsExactBackupSceneWithoutPlaceholder() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: worker(base))
        try await open(session)
        var importedScene = LightingScene.portrait()
        importedScene.camera.x = 1.25
        importedScene.lights[0].candela = 1234
        importedScene.placementRoom = ManualRoom(widthMeters: 7, depthMeters: 8, subjectX: 3, subjectZ: 4)
        let encoded = try LightingProjectDocument(name: "Restored backup", scene: importedScene).encode()
        let document = try LightingProjectDocument.decode(encoded)

        try await session.applyLibrary(.create(name: document.name, scene: document.scene),
                                       from: session.generation).value
        let library = try XCTUnwrap(session.library)
        XCTAssertEqual(library.projects.count, 1)
        XCTAssertEqual(library.activeProject?.name, document.name)
        XCTAssertEqual(library.activeProject?.scene, importedScene)
        XCTAssertEqual(session.scene, importedScene)
        XCTAssertEqual(session.saved, importedScene)
        let reopened = StudioSession(store: worker(base))
        try await open(reopened)
        XCTAssertEqual(reopened.library, library)
        XCTAssertEqual(reopened.scene, importedScene)
        XCTAssertFalse(reopened.canCreateInitialProject)
    }

    func testEditedAndUndoneStarterCannotUseInitialCreateException() async throws {
        let session = StudioSession(execute: { _ in nil })
        try await open(session)
        let original = session.scene
        var edited = original
        edited.camera.x += 0.5
        XCTAssertTrue(session.replace(edited, from: session.generation))
        XCTAssertFalse(session.canCreateInitialProject)
        let editedState = session.editor
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "Replace draft", scene: .portrait()),
                                                      from: session.generation))
        XCTAssertEqual(session.editor, editedState)
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertTrue(session.history.canRedo)
        XCTAssertFalse(session.canCreateInitialProject)
        let undoneState = session.editor
        XCTAssertThrowsError(try session.beginLibraryOperation(.change(.create(name: "Replace draft", scene: .portrait())),
                                                              from: session.generation))
        XCTAssertEqual(session.editor, undoneState)
        XCTAssertNil(session.libraryOperation.pending)
    }

    func testOutAndBackEditStaysProtectedEvenWithNoHistoryOrContentDifference() async throws {
        let session = StudioSession(execute: { _ in nil })
        try await open(session)
        let original = session.scene
        let initialRevision = session.revision
        let owner = session.editOwner("camera.position.x")
        session.editChanged(true, owner: owner, from: session.generation)
        var edited = original
        edited.camera.x += 0.5
        XCTAssertTrue(session.update(edited, from: session.generation))
        XCTAssertTrue(session.update(original, from: session.generation))
        session.editChanged(false, owner: owner, from: session.generation)
        XCTAssertEqual(session.scene, original)
        XCTAssertFalse(session.history.canUndo)
        XCTAssertFalse(session.history.canRedo)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertNotEqual(session.revision, initialRevision)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "Late import", scene: .portrait()),
                                                      from: session.generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertNil(session.library)
    }

    func testUnchangedEditAndFeatureMustCloseBeforeInitialCreate() async throws {
        let session = StudioSession(execute: { _ in nil })
        try await open(session)
        let owner = session.editOwner("camera.position.x")
        session.editChanged(true, owner: owner, from: session.generation)
        let editing = session.editor
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "First", scene: .portrait()),
                                                      from: session.generation))
        XCTAssertEqual(session.editor, editing, "Rejected create must not commit an active edit")
        session.editChanged(false, owner: owner, from: session.generation)
        XCTAssertTrue(session.canCreateInitialProject)

        let context = try XCTUnwrap(session.openFeature(.reference, from: session.generation))
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "First", scene: .portrait()),
                                                      from: session.generation))
        session.retireFeature(context)
        XCTAssertFalse(session.canCreateInitialProject, "A dismissing feature still owns its pending callbacks")
        session.finishFeature(context)
        XCTAssertTrue(session.canCreateInitialProject)

        let id = try XCTUnwrap(session.selection)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: session.generation))
        XCTAssertFalse(session.dragLight(id, token: token, translationX: 0, translationZ: 0,
                                         scale: 100, from: session.generation))
        XCTAssertNotNil(session.planDrag)
        XCTAssertFalse(session.canCreateInitialProject)
        session.finishPlanDrag()
        XCTAssertTrue(session.canCreateInitialProject)
    }

    func testCallerSuppliedDraftNeverReceivesStarterPermission() async throws {
        var scene = LightingScene.portrait()
        scene.camera.x = 2
        let session = StudioSession(editor: try .init(scene: scene), execute: { _ in nil })
        try await open(session)
        XCTAssertFalse(session.history.canUndo)
        XCTAssertFalse(session.history.canRedo)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "Replace supplied draft", scene: .portrait()),
                                                      from: session.generation))
        XCTAssertEqual(session.scene, scene)
        XCTAssertNil(session.saved)
    }

    func testOnlyCreateCommandAcceptsNilLibraryInSessionAndStore() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        let session = StudioSession(store: store)
        try await open(session)
        let original = session.editor
        let id = UUID()
        let commands: [ProjectLibraryCommand] = [
            .rename(id, name: "Rename"), .duplicate(id, name: "Duplicate"),
            .select(id), .archive(id), .restore(id), .deleteArchived(id)
        ]
        for command in commands {
            XCTAssertThrowsError(try session.applyLibrary(command, from: session.generation))
            XCTAssertThrowsError(try session.beginLibraryOperation(.change(command), from: session.generation))
            var operation = ProjectLibraryOperationState()
            let request = try operation.reserve(.change(command), library: nil, scene: session.scene,
                                                from: operation.generation)
            do {
                _ = try await store.perform(request)
                XCTFail("Only create may initialize an empty library")
            } catch ProjectLibraryError.invalidLibrary { }
            XCTAssertEqual(session.editor, original)
            XCTAssertNil(session.libraryOperation.pending)
            XCTAssertTrue(session.canCreateInitialProject)
            XCTAssertNil(try backingStore(base).load())
        }
    }

    func testInvalidFirstProjectKeepsStarterAndCanBeRetried() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: worker(base))
        try await open(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        do {
            try await session.applyLibrary(.create(name: "", scene: .portrait()), from: generation).value
            XCTFail("An invalid first name must not create a placeholder")
        } catch ProjectLibraryError.invalidName { }
        var invalid = LightingScene.portrait()
        invalid.camera.x = .nan
        do {
            try await session.applyLibrary(.create(name: "Invalid backup", scene: invalid), from: generation).value
            XCTFail("An invalid scene must not replace the starter")
        } catch SceneError.invalidScene { }
        XCTAssertEqual(session.editor, original)
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, workspace)
        XCTAssertTrue(session.canCreateInitialProject)
        XCTAssertNil(session.library)
        XCTAssertNil(session.saved)
        XCTAssertNil(try backingStore(base).load())
        XCTAssertNil(session.operationTask)
        XCTAssertFalse(session.isBusy)
        try await session.applyLibrary(.create(name: "Retried", scene: .portrait()), from: generation).value
        XCTAssertEqual(session.library?.projects.count, 1)
        XCTAssertEqual(session.library?.activeProject?.name, "Retried")
    }

    func testStorageFailureBeforeFirstCommitKeepsStarterAndCanBeRetried() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: worker(base))
        let disk = backingStore(base)
        try await open(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let obstruction = Data("storage directory unavailable".utf8)
        try obstruction.write(to: disk.directory, options: .withoutOverwriting)
        do {
            try await session.applyLibrary(.create(name: "First", scene: .portrait()), from: generation).value
            XCTFail("The storage path is obstructed")
        } catch { }
        XCTAssertEqual(try Data(contentsOf: disk.directory), obstruction)
        XCTAssertEqual(session.editor, original)
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, workspace)
        XCTAssertNil(session.library)
        XCTAssertNil(session.saved)
        XCTAssertTrue(session.canCreateInitialProject)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
        try FileManager.default.removeItem(at: disk.directory)
        try await session.applyLibrary(.create(name: "Retried", scene: .portrait()), from: generation).value
        XCTAssertEqual(session.library?.projects.count, 1)
        XCTAssertEqual(try disk.load(), session.library)
    }

    func testCancelledFirstCreateBeforeStoreWorkDoesNotAdoptAndCanRetry() async throws {
        let base = directory()
        let gate = InitialProjectGate()
        defer { gate.open(); try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        let session = StudioSession(store: store, execute: { request in
            if case .change = request.operation { await gate.pause() }
            return try await store.perform(request)
        })
        try await open(session)
        let original = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        let creating = try session.applyLibrary(.create(name: "Cancelled", scene: .portrait()), from: generation)
        defer { creating.cancel() }
        try await waitFor(gate.entered)
        XCTAssertFalse(session.canCreateInitialProject)
        creating.cancel()
        gate.open()
        do {
            try await settle(creating)
            XCTFail("Cancellation before the synchronous store transaction must prevent the write")
        } catch is CancellationError { }
        XCTAssertEqual(session.editor, original)
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, workspace)
        XCTAssertNil(session.library)
        XCTAssertNil(session.saved)
        XCTAssertNil(try backingStore(base).load())
        XCTAssertTrue(session.canCreateInitialProject)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
        try await session.applyLibrary(.create(name: "Retried", scene: .portrait()), from: generation).value
        XCTAssertEqual(session.library?.projects.count, 1)
        XCTAssertEqual(session.library?.activeProject?.name, "Retried")
    }

    func testCancelledObserverAfterFirstCreateCommitStillAdoptsOnce() async throws {
        try await verifyCommittedCreate(cancelSession: false)
    }

    func testCancelledSessionAfterFirstCreateCommitStillAdoptsOnce() async throws {
        try await verifyCommittedCreate(cancelSession: true)
    }

    private func verifyCommittedCreate(cancelSession: Bool) async throws {
        let base = directory()
        let gate = InitialProjectGate()
        defer { gate.open(); try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        let disk = backingStore(base)
        let session = StudioSession(store: store, execute: { request in
            let receipt = try await store.perform(request)
            if case .change = request.operation { await gate.pause() }
            return receipt
        })
        try await open(session)
        let starter = session.editor
        let generation = session.generation
        let workspace = session.workspaceResetID
        var imported = LightingScene.portrait()
        imported.camera.x = 1.5
        let creating = try session.applyLibrary(.create(name: "Committed import", scene: imported), from: generation)
        let observer = Task { try await creating.value }
        defer { creating.cancel(); observer.cancel() }
        try await waitFor(gate.entered)
        let committed = try XCTUnwrap(disk.load())
        let bytes = try Data(contentsOf: disk.url)
        XCTAssertEqual(committed.projects.count, 1)
        XCTAssertEqual(committed.activeProject?.scene, imported)
        XCTAssertEqual(session.editor, starter)
        XCTAssertNil(session.library)
        XCTAssertNil(session.saved)
        XCTAssertTrue(session.isBusy)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "Second", scene: .portrait()), from: generation))
        if cancelSession { creating.cancel() } else { observer.cancel() }
        gate.open()
        try await settle(creating)
        try await settle(observer)

        XCTAssertEqual(session.library, committed)
        XCTAssertEqual(session.scene, imported)
        XCTAssertEqual(session.saved, imported)
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertNotEqual(session.workspaceResetID, workspace)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertFalse(session.history.canUndo)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
        let settledEditor = session.editor
        let settledGeneration = session.generation
        try await creating.value
        try await observer.value
        XCTAssertEqual(session.editor, settledEditor)
        XCTAssertEqual(session.generation, settledGeneration)
        XCTAssertEqual(try Data(contentsOf: disk.url), bytes)
        XCTAssertEqual(try disk.load(), committed)
    }

    func testTwoEmptyWindowsRaceFirstCreateAgainstFirstSaveWithoutOverwrite() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let creatingSession = StudioSession(store: worker(base))
        let savingSession = StudioSession(store: worker(base))
        try await open(creatingSession)
        try await open(savingSession)
        let initialEditors = [creatingSession.editor, savingSession.editor]
        XCTAssertTrue(creatingSession.canCreateInitialProject)
        XCTAssertTrue(savingSession.canCreateInitialProject)
        let creating = try creatingSession.applyLibrary(.create(name: "Imported first", scene: .portrait()),
                                                         from: creatingSession.generation)
        let saving = try savingSession.beginLibraryOperation(.save, from: savingSession.generation)
        let sessions = [creatingSession, savingSession]
        var successes = 0
        var conflicts = 0
        for (index, operation) in [creating, saving].enumerated() {
            do {
                try await operation.value
                successes += 1
                XCTAssertEqual(sessions[index].library, try backingStore(base).load())
            } catch ProjectLibraryError.staleSnapshot {
                conflicts += 1
                XCTAssertEqual(sessions[index].editor, initialEditors[index])
                XCTAssertNil(sessions[index].library)
                XCTAssertNil(sessions[index].saved)
                XCTAssertTrue(sessions[index].saveConflict)
            }
            XCTAssertFalse(sessions[index].canCreateInitialProject)
            XCTAssertFalse(sessions[index].isBusy)
            XCTAssertNil(sessions[index].operationTask)
        }
        XCTAssertEqual(successes, 1)
        XCTAssertEqual(conflicts, 1)
        XCTAssertEqual(try backingStore(base).load()?.projects.count, 1)
    }

    func testFailedInitialLoadNeverAuthorizesCreateOrChangesCorruptBytes() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let disk = backingStore(base)
        try FileManager.default.createDirectory(at: disk.directory, withIntermediateDirectories: true)
        let corrupt = Data("invalid library".utf8)
        try corrupt.write(to: disk.url)
        let session = StudioSession(store: worker(base))
        do { try await open(session); XCTFail("The initial library is corrupt") }
        catch { }
        XCTAssertTrue(session.saveBlocked)
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "First", scene: .portrait()),
                                                      from: session.generation))
        XCTAssertThrowsError(try session.beginLibraryOperation(.change(.create(name: "First", scene: .portrait())),
                                                              from: session.generation))
        XCTAssertEqual(try Data(contentsOf: disk.url), corrupt)
    }

    func testDirtySavedProjectStillRequiresSaveBeforeCreatingAnotherProject() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: worker(base))
        let disk = backingStore(base)
        try await open(session)
        try await session.beginLibraryOperation(.save, from: session.generation).value
        let firstID = try XCTUnwrap(session.library?.activeID)
        let bytes = try Data(contentsOf: disk.url)
        var edited = session.scene
        edited.camera.x = 0.5
        XCTAssertTrue(session.replace(edited, from: session.generation))
        let editor = session.editor
        XCTAssertFalse(session.canCreateInitialProject)
        XCTAssertThrowsError(try session.applyLibrary(.create(name: "Second", scene: .portrait()),
                                                      from: session.generation))
        XCTAssertThrowsError(try session.beginLibraryOperation(.change(.create(name: "Second", scene: .portrait())),
                                                              from: session.generation))
        XCTAssertEqual(session.editor, editor)
        XCTAssertEqual(try Data(contentsOf: disk.url), bytes)
        try await session.beginLibraryOperation(.save, from: session.generation).value
        try await session.applyLibrary(.create(name: "Second", scene: .portrait()),
                                       from: session.generation).value
        XCTAssertEqual(session.library?.projects.count, 2)
        XCTAssertEqual(session.library?.projects.first { $0.id == firstID }?.scene, edited)
    }
}
