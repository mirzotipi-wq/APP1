import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

/// A nonblocking latch after the actual store transaction. Opening before entry
/// is safe, so failure cleanup cannot strand a later-arriving continuation.
private final class CommittedSaveGate: @unchecked Sendable {
    let entered = XCTestExpectation(description: "Real save committed before receipt delivery")
    private let lock = NSLock()
    private var released = false
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var entries = 0

    func pause() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            entries += 1
            let alreadyReleased = released
            if !alreadyReleased { continuations.append(continuation) }
            lock.unlock()
            entered.fulfill()
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

    var entryCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }
}

@MainActor
final class StudioCommittedSaveTests: XCTestCase {
    private enum CancellationTarget { case observer, sessionTask }
    private enum FixtureError: Error { case timedOut(String) }

    /// A failing implementation must fail this test instead of hanging its suite.
    private func waitFor(_ expectations: [XCTestExpectation], named name: String) async throws {
        guard await XCTWaiter.fulfillment(of: expectations, timeout: 5) == .completed else {
            throw FixtureError.timedOut(name)
        }
    }

    private func settle(_ task: Task<Void, Error>, named name: String) async throws {
        let finished = XCTestExpectation(description: name)
        let witness = Task { @MainActor in
            let result = await task.result
            finished.fulfill()
            return result
        }
        defer { witness.cancel() }
        try await waitFor([finished], named: name)
        try await witness.value.get()
    }

    func testCancellingObserverAfterRealFirstSaveCommitPreservesRoomAndUndo() async throws {
        try await verifyCommittedFirstSave(cancelling: .observer)
    }

    func testCancellingSessionTaskAfterRealFirstSaveCommitStillAdoptsReceipt() async throws {
        try await verifyCommittedFirstSave(cancelling: .sessionTask)
    }

    private func verifyCommittedFirstSave(cancelling target: CancellationTarget) async throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString,
                                                                                isDirectory: true)
        let gate = CommittedSaveGate()
        defer {
            gate.open()
            try? FileManager.default.removeItem(at: base)
        }
        let store = ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:])
        let disk = ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill",
                                                                                isDirectory: true))
        let session = StudioSession(store: store, execute: { request in
            let receipt = try await store.perform(request)
            if case .save = request.operation { await gate.pause() }
            return receipt
        })
        let loading = try session.beginLibraryOperation(.load, from: session.generation)
        defer { loading.cancel() }
        try await settle(loading, named: "Ungated initial load settled")
        XCTAssertTrue(session.loaded)
        XCTAssertNil(session.library)
        XCTAssertNil(session.saved)
        XCTAssertNil(try disk.load(), "This is the first save, not a saved-project overwrite")
        XCTAssertEqual(gate.entryCount, 0, "Loads do not pass through the commit gate")

        let original = session.scene
        let storageGeneration = session.generation
        let workspace = session.workspaceResetID
        let controlOwner = session.editOwner("camera.position.x")
        let context = try XCTUnwrap(session.openFeature(.room, from: storageGeneration))
        let room = ManualRoom(widthMeters: 8, depthMeters: 9, subjectX: 4, subjectZ: 3)
        XCTAssertTrue(session.applyFeatureRoom(room, from: context))
        let selectedID = try XCTUnwrap(original.lights.dropFirst().first?.id)
        XCTAssertTrue(session.select(selectedID, from: storageGeneration))
        let committedScene = session.scene
        let presentation = try XCTUnwrap(session.feature)

        let saving = try session.beginLibraryOperation(.save, from: storageGeneration)
        // Reservation intentionally ends editing. Compare receipt adoption with
        // this boundary, rather than with an open room-edit transaction.
        let reservedEditor = session.editor
        let reservedHistory = session.history
        let observerStarted = XCTestExpectation(description: "Sheet observer awaiting session save")
        let observer = Task { @MainActor in
            observerStarted.fulfill()
            try await saving.value
        }
        defer { observer.cancel(); saving.cancel() }

        do {
            let request = try XCTUnwrap(session.libraryOperation.pending)
            try await waitFor([gate.entered, observerStarted], named: "Commit and observer entry")
            let committed = try XCTUnwrap(disk.load())
            let committedBytes = try Data(contentsOf: disk.url)
            XCTAssertEqual(committed.projects.count, 1)
            XCTAssertEqual(committed.activeProject?.scene, committedScene)
            XCTAssertNil(request.expected)
            XCTAssertNil(request.projectID)
            XCTAssertEqual(request.scene, committedScene)
            XCTAssertTrue(session.isBusy, "Disk commit precedes session receipt adoption")
            XCTAssertNotNil(session.operationTask)
            XCTAssertEqual(session.libraryOperation.pending?.id, request.id)
            XCTAssertNil(session.library)
            XCTAssertNil(session.saved)
            XCTAssertEqual(session.generation, storageGeneration)
            XCTAssertEqual(session.editor, reservedEditor)
            XCTAssertEqual(session.feature, presentation)
            XCTAssertFalse(session.acceptsFeature(context))
            XCTAssertFalse(session.applyFeatureRoom(nil, from: context))
            XCTAssertEqual(session.editor, reservedEditor)

            switch target {
            case .observer:
                observer.cancel()
                XCTAssertTrue(observer.isCancelled)
                XCTAssertFalse(saving.isCancelled, "Observer cancellation must not cancel its owner")
            case .sessionTask:
                saving.cancel()
                XCTAssertTrue(saving.isCancelled)
                XCTAssertFalse(observer.isCancelled)
            }
            XCTAssertTrue(session.isBusy)
            XCTAssertNil(session.saved, "Cancellation alone cannot deliver the held receipt")
            gate.open()
            try await settle(saving, named: "Committed save settled after cancellation")
            try await settle(observer, named: "Sheet observer received committed result")

            let settledGeneration = session.generation
            XCTAssertNotEqual(settledGeneration, storageGeneration)
            XCTAssertNil(session.operationTask)
            XCTAssertNil(session.libraryOperation.pending)
            XCTAssertFalse(session.isBusy)
            XCTAssertFalse(session.saveBlocked)
            XCTAssertFalse(session.saveConflict)
            XCTAssertEqual(session.library, committed)
            XCTAssertEqual(session.saved, committedScene)
            XCTAssertEqual(session.scene, committedScene)
            XCTAssertEqual(try disk.load(), session.library)
            XCTAssertEqual(session.editor, reservedEditor)
            XCTAssertEqual(session.history, reservedHistory)
            XCTAssertTrue(session.history.canUndo)
            XCTAssertFalse(session.history.isEditing)
            XCTAssertEqual(session.selection, selectedID)
            XCTAssertEqual(session.workspaceResetID, workspace)
            XCTAssertEqual(session.editOwner("camera.position.x"), controlOwner)
            XCTAssertEqual(session.feature, presentation)
            XCTAssertEqual(session.feature?.context, context)
            XCTAssertTrue(session.acceptsFeature(context))

            // These tasks are already complete. Reading their result again must
            // neither adopt another receipt nor repeat the physical transaction.
            try await saving.value
            try await observer.value
            XCTAssertEqual(gate.entryCount, 1)
            XCTAssertEqual(session.generation, settledGeneration)
            XCTAssertEqual(session.editor, reservedEditor)
            XCTAssertEqual(session.feature, presentation)
            XCTAssertEqual(session.library, committed)
            XCTAssertEqual(try Data(contentsOf: disk.url), committedBytes)

            var staleCamera = session.scene.camera
            staleCamera.x += 0.25
            XCTAssertFalse(session.apply(.cameraPosition(staleCamera), from: storageGeneration))
            XCTAssertEqual(session.editor, reservedEditor)
            XCTAssertEqual(session.feature, presentation)

            var continuedRoom = room
            continuedRoom.yawDegrees = 37
            XCTAssertTrue(session.applyFeatureRoom(continuedRoom, from: context))
            continuedRoom.yawDegrees = 42
            XCTAssertTrue(session.applyFeatureRoom(continuedRoom, from: context))
            XCTAssertEqual(session.feature?.context, context)
            XCTAssertEqual(session.feature?.acceptedRevision, session.revision)
            XCTAssertTrue(session.acceptsFeature(context))
            XCTAssertEqual(session.selection, selectedID)
            XCTAssertEqual(session.saved, committedScene)
            XCTAssertNotEqual(session.scene, session.saved)
            session.finishFeature(context)
            XCTAssertTrue(session.undo(from: settledGeneration))
            XCTAssertEqual(session.scene, committedScene, "Continued room edits form one new undo group")
            XCTAssertTrue(session.undo(from: settledGeneration))
            XCTAssertEqual(session.scene, original, "First-save history still reaches the original scene")
            XCTAssertFalse(session.history.canUndo)
            XCTAssertTrue(session.redo(from: settledGeneration))
            XCTAssertEqual(session.scene, committedScene)
            XCTAssertTrue(session.redo(from: settledGeneration))
            XCTAssertEqual(session.scene.placementRoom, continuedRoom)
            XCTAssertFalse(session.history.canRedo)
            XCTAssertEqual(session.selection, selectedID)
            XCTAssertEqual(session.generation, settledGeneration)
            XCTAssertEqual(session.workspaceResetID, workspace)
            XCTAssertEqual(session.saved, committedScene)
            XCTAssertEqual(session.library, committed)
            XCTAssertEqual(try disk.load(), committed)
            XCTAssertEqual(try Data(contentsOf: disk.url), committedBytes)
        } catch {
            gate.open()
            saving.cancel()
            observer.cancel()
            // Both joins are bounded, including when the tested implementation
            // fails before entering the gate or while adopting its receipt.
            try? await settle(saving, named: "Save failure cleanup")
            try? await settle(observer, named: "Observer failure cleanup")
            throw error
        }
    }
}
