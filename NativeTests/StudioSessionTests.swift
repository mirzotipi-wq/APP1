import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

/// A suspension point after a receipt exists, without sleeps or blocked threads.
private actor StudioReceiptGate {
    private var release: CheckedContinuation<Void, Never>?
    private var observer: CheckedContinuation<Void, Never>?
    private var entered = false

    func pause() async {
        await withCheckedContinuation { continuation in
            release = continuation
            entered = true
            observer?.resume()
            observer = nil
        }
    }

    func waitUntilEntered() async {
        if entered { return }
        await withCheckedContinuation { observer = $0 }
    }

    func open() { release?.resume(); release = nil }
}

@MainActor
final class StudioSessionTests: XCTestCase {
    private func open(_ session: StudioSession) async throws {
        try await session.beginLibraryOperation(.load, from: session.generation).value
    }

    func testStaleReservationDoesNotEndCurrentContinuousEdit() async throws {
        let scene = LightingScene.portrait()
        let receipt = try ProjectLibrary(name: "Saved", scene: scene)
        let session = StudioSession(editor: try .init(scene: scene), execute: { request in
            if case .load = request.operation { return nil }
            return receipt
        })
        try await open(session)
        let stale = session.generation
        try await session.beginLibraryOperation(.save, from: stale).value
        let current = session.generation
        XCTAssertNotEqual(current, stale)
        session.editChanged(true, owner: "current-drag", from: current)
        var moved = session.scene
        moved.lights[0].position.x += 0.1
        XCTAssertTrue(session.update(moved, from: current))
        let editor = session.editor
        XCTAssertThrowsError(try session.beginLibraryOperation(.save, from: stale)) {
            XCTAssertEqual($0 as? ProjectLibraryOperationState.OperationError, .staleEditor)
        }
        XCTAssertEqual(session.editor, editor)
        XCTAssertTrue(session.history.isEditing)
        moved.lights[0].position.x += 0.1
        XCTAssertTrue(session.update(moved, from: current))
        session.endEditing(owner: "current-drag")
        XCTAssertTrue(session.undo(from: current))
        XCTAssertEqual(session.scene, scene)
    }

    func testFirstSaveKeepsSelectionAndHistoryAndReleasesTask() async throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:]))
        try await open(session)
        let original = session.scene
        session.select(original.lights[2].id, from: session.generation)
        var edited = original
        edited.lights[0].candela = 1500
        session.replace(edited, from: session.generation)
        let reset = session.workspaceResetID
        let generation = session.generation
        try await session.beginLibraryOperation(.save, from: generation).value
        XCTAssertEqual(session.saved, edited)
        XCTAssertEqual(session.selection, original.lights[2].id)
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, reset)
        XCTAssertNil(session.operationTask)
        XCTAssertFalse(session.isBusy)
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertNotEqual(session.saved, session.scene)
    }

    func testCancellingSheetObserverStillReconcilesCommittedSaveExactlyOnce() async throws {
        let gate = StudioReceiptGate()
        let original = LightingScene.portrait()
        let receipt = try ProjectLibrary(name: "Committed", scene: original)
        let session = StudioSession(editor: try .init(scene: original), execute: { request in
            if case .load = request.operation { return nil }
            await gate.pause()
            return receipt
        })
        try await open(session)
        let saving = try session.beginLibraryOperation(.save, from: session.generation)
        let observer = Task { try await saving.value }
        await gate.waitUntilEntered()
        observer.cancel()
        XCTAssertTrue(session.isBusy)
        XCTAssertNotNil(session.operationTask)
        await gate.open()
        try await saving.value
        try await observer.value
        let settledGeneration = session.generation
        try await saving.value
        XCTAssertEqual(session.generation, settledGeneration)
        XCTAssertEqual(session.library, receipt)
        XCTAssertEqual(session.saved, original)
        XCTAssertNil(session.operationTask)
        XCTAssertFalse(session.isBusy)
    }

    func testPendingOperationRejectsMutationAndSecondReservation() async throws {
        let gate = StudioReceiptGate()
        let scene = LightingScene.portrait()
        let receipt = try ProjectLibrary(name: "Saved", scene: scene)
        let session = StudioSession(editor: try .init(scene: scene), execute: { request in
            if case .load = request.operation { return nil }
            await gate.pause()
            return receipt
        })
        try await open(session)
        let generation = session.generation
        let saving = try session.beginLibraryOperation(.save, from: generation)
        await gate.waitUntilEntered()
        var changed = scene
        changed.camera.x = 2
        XCTAssertFalse(session.replace(changed, from: generation))
        XCTAssertFalse(session.update(changed, from: generation))
        XCTAssertFalse(session.select(scene.lights[2].id, from: generation))
        XCTAssertThrowsError(try session.beginLibraryOperation(.save, from: generation)) {
            XCTAssertEqual($0 as? ProjectLibraryOperationState.OperationError, .busy)
        }
        XCTAssertEqual(session.scene, scene)
        await gate.open()
        try await saving.value
    }

    func testLoadFailureProtectsDataAndRejectsEditingAndSave() async throws {
        let session = StudioSession(execute: { _ in throw ProjectLibraryError.invalidLibrary })
        let original = session.editor
        do { try await open(session); XCTFail("Expected load failure") }
        catch ProjectLibraryError.invalidLibrary { }
        XCTAssertTrue(session.loaded)
        XCTAssertTrue(session.saveBlocked)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
        var next = session.scene
        next.camera.x = 1
        XCTAssertFalse(session.replace(next, from: session.generation))
        XCTAssertThrowsError(try session.beginLibraryOperation(.save, from: session.generation))
        XCTAssertEqual(session.editor, original)
    }

    func testRealCompetingSavePreservesUnsavedSceneAndHistory() async throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let worker = ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:])
        let session = StudioSession(store: worker)
        try await open(session)
        try await session.beginLibraryOperation(.save, from: session.generation).value
        let expected = try XCTUnwrap(session.library)
        var remote = expected
        try remote.rename(remote.activeID, to: "Other window")
        let disk = ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill"))
        try disk.save(remote, replacing: expected)
        var local = session.scene
        local.lights[0].candela = 1555
        session.replace(local, from: session.generation)
        let editor = session.editor
        do {
            try await session.beginLibraryOperation(.save, from: session.generation).value
            XCTFail("Expected competing-snapshot failure")
        } catch ProjectLibraryError.staleSnapshot { }
        XCTAssertEqual(session.editor, editor)
        XCTAssertTrue(session.saveConflict)
        XCTAssertEqual(try disk.load(), remote)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
    }

    func testProjectSwitchResetsHistoryAndPresentationButMetadataDoesNot() async throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:]))
        try await open(session)
        var changed = session.scene
        changed.camera.x = 1
        session.replace(changed, from: session.generation)
        try await session.beginLibraryOperation(.save, from: session.generation).value
        let generation = session.generation
        let reset = session.workspaceResetID
        let id = try XCTUnwrap(session.library?.activeID)
        try await session.applyLibrary(.rename(id, name: "Renamed"), from: generation).value
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, reset)
        XCTAssertTrue(session.history.canUndo)
        try await session.applyLibrary(.create(name: "Next", scene: .portrait()), from: generation).value
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertNotEqual(session.workspaceResetID, reset)
        XCTAssertFalse(session.history.canUndo)
        XCTAssertEqual(session.selection, session.scene.lights.first?.id)
        XCTAssertEqual(session.saved, session.scene)
    }

    func testSessionAndStoreSurviveObserverReleaseUntilReceiptSettles() async throws {
        let gate = StudioReceiptGate()
        let receipt = try ProjectLibrary(name: "Saved", scene: .portrait())
        var session: StudioSession? = StudioSession(execute: { request in
            if case .load = request.operation { return nil }
            await gate.pause()
            return receipt
        })
        try await open(try XCTUnwrap(session))
        weak var weakSession = session
        var task: Task<Void, Error>? = try session!.beginLibraryOperation(.save, from: session!.generation)
        await gate.waitUntilEntered()
        session = nil
        XCTAssertNotNil(weakSession, "The in-flight receipt owns its session")
        await gate.open()
        try await task?.value
        task = nil
        XCTAssertNil(weakSession, "Settling the task must break the ownership cycle")
    }
}
