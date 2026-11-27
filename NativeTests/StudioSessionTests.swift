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

    func testSavedFeedbackFollowsRevisionButKeepsSelectionAndNoOpFeedback() async throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let session = StudioSession(store: ProjectStore(applicationSupportDirectory: base,
                                                        arguments: [], environment: [:]))
        try await open(session)
        try await session.beginLibraryOperation(.save, from: session.generation).value
        let savedRevision = session.revision
        let savedMessage = try XCTUnwrap(session.message)
        let id = session.scene.lights[0].id
        let intensity = session.scene.lights[0].candela

        XCTAssertTrue(session.select(session.scene.lights[1].id, from: session.generation))
        XCTAssertFalse(session.apply(.lightValue(id: id, field: .candela, value: intensity),
                                     from: session.generation))
        XCTAssertFalse(session.replace(session.scene, from: session.generation))
        XCTAssertFalse(session.update(session.scene, from: session.generation))
        XCTAssertFalse(session.undo(from: session.generation))
        XCTAssertFalse(session.redo(from: session.generation))
        XCTAssertEqual(session.revision, savedRevision)
        XCTAssertEqual(session.message, savedMessage)

        XCTAssertTrue(session.apply(.lightValue(id: id, field: .candela, value: intensity + 1),
                                    from: session.generation))
        XCTAssertNil(session.message, "A receipt must not claim later edits are saved")
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, session.saved)
        XCTAssertNil(session.message, "Returning to equal content must not revive an old receipt")

        try await session.beginLibraryOperation(.save, from: session.generation).value
        XCTAssertEqual(session.message, savedMessage)
        XCTAssertTrue(session.redo(from: session.generation))
        XCTAssertNil(session.message, "Redo after saving is a new unsaved revision")
    }

    func testSaveFailureFeedbackSurvivesLaterEdits() async throws {
        let session = StudioSession(execute: { request in
            if case .load = request.operation { return nil }
            throw CocoaError(.fileWriteOutOfSpace)
        })
        try await open(session)
        do {
            try await session.beginLibraryOperation(.save, from: session.generation).value
            XCTFail("The injected write failure must propagate")
        } catch {
            XCTAssertEqual((error as NSError).code, CocoaError.Code.fileWriteOutOfSpace.rawValue)
        }
        let failure = try XCTUnwrap(session.message)
        XCTAssertNil(session.saved)
        var changed = session.scene
        changed.camera.x += 0.5
        XCTAssertTrue(session.update(changed, from: session.generation))
        XCTAssertEqual(session.message, failure, "Editing must not hide a failed disk write")
    }

    func testSavedFeedbackDoesNotDescribeADifferentCurrentScene() async throws {
        let original = LightingScene.portrait()
        var earlier = original
        earlier.camera.x += 0.5
        let receipt = try ProjectLibrary(name: "Earlier saved scene", scene: earlier)
        let session = StudioSession(editor: try .init(scene: original), execute: { request in
            if case .load = request.operation { return nil }
            return receipt
        })
        try await open(session)
        try await session.beginLibraryOperation(.save, from: session.generation).value
        XCTAssertEqual(session.saved, earlier)
        XCTAssertEqual(session.scene, original)
        XCTAssertNil(session.message, "Receipt adoption may keep newer edits dirty")
    }

    func testTypedCommandsRequireCurrentLoadedEditorAndUseTheAddressedLight() async throws {
        let session = StudioSession(execute: { _ in nil })
        let initial = session.editor
        let beforeLoad = session.generation
        let id = initial.scene.lights[0].id
        let command = StudioFieldCommand.lightValue(id: id, field: .candela, value: 1234)
        XCTAssertFalse(session.apply(command, from: beforeLoad))
        XCTAssertEqual(session.editor, initial)
        try await open(session)
        let loaded = session.editor
        XCTAssertNotEqual(session.generation, beforeLoad)
        XCTAssertFalse(session.apply(command, from: beforeLoad))
        XCTAssertEqual(session.editor, loaded)
        let selected = initial.scene.lights[2].id
        XCTAssertTrue(session.select(selected, from: session.generation))
        XCTAssertTrue(session.apply(command, from: session.generation))
        XCTAssertEqual(session.scene.lights[0].candela, 1234)
        XCTAssertEqual(session.scene.lights[2], initial.scene.lights[2])
        XCTAssertEqual(session.selection, selected, "A queued field command keeps its captured light UUID")
        let changed = session.editor
        XCTAssertFalse(session.apply(.lightValue(id: UUID(), field: .x, value: 2),
                                     from: session.generation))
        XCTAssertEqual(session.editor, changed)
        XCTAssertFalse(session.apply(command, from: session.generation))
        XCTAssertEqual(session.editor, changed)
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
        let lightID = scene.lights[0].id
        let token = try XCTUnwrap(session.beginPlanDrag(lightID, scale: 100, from: current))
        XCTAssertTrue(session.dragLight(lightID, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: current))
        let editor = session.editor
        let drag = session.planDrag
        XCTAssertThrowsError(try session.beginLibraryOperation(.save, from: stale)) {
            XCTAssertEqual($0 as? ProjectLibraryOperationState.OperationError, .staleEditor)
        }
        XCTAssertEqual(session.editor, editor)
        XCTAssertEqual(session.planDrag, drag)
        XCTAssertTrue(session.history.isEditing)
        XCTAssertTrue(session.dragLight(lightID, token: token, translationX: 40, translationZ: 0,
                                        scale: 999, from: current))
        XCTAssertEqual(session.scene.lights[0].position.x,
                       scene.lights[0].position.x + 0.4, accuracy: 1e-12,
                       "Cumulative translation keeps its original origin and scale")
        session.finishPlanDrag(token: token, lightID: lightID, generation: current)
        XCTAssertNil(session.planDrag)
        XCTAssertTrue(session.undo(from: current))
        XCTAssertEqual(session.scene, scene)
    }

    func testAcceptedSaveEndsPlanGestureAndLateEndCannotCloseNewGeneration() async throws {
        let session = StudioSession(execute: { request in
            if case .load = request.operation { return nil }
            return try ProjectLibrary(name: "Saved", scene: request.scene)
        })
        try await open(session)
        let original = session.scene
        let id = original.lights[0].id
        let oldGeneration = session.generation
        let oldToken = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: oldGeneration))
        XCTAssertTrue(session.dragLight(id, token: oldToken, translationX: 20, translationZ: -10,
                                        scale: 100, from: oldGeneration))
        let savedScene = session.scene
        let save = try session.beginLibraryOperation(.save, from: oldGeneration)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        try await save.value
        XCTAssertEqual(session.saved, savedScene)
        let generation = session.generation
        XCTAssertNotEqual(generation, oldGeneration)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 10, translationZ: 0,
                                        scale: 100, from: generation))
        let currentDrag = session.planDrag
        session.finishPlanDrag(token: oldToken, lightID: id, generation: oldGeneration)
        XCTAssertEqual(session.planDrag, currentDrag)
        XCTAssertTrue(session.history.isEditing)
        session.finishPlanDrag(token: token, lightID: id, generation: generation)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, savedScene)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, original)
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
        let controlOwner = session.editOwner("camera.position")
        let generation = session.generation
        try await session.beginLibraryOperation(.save, from: generation).value
        XCTAssertEqual(session.saved, edited)
        XCTAssertEqual(session.selection, original.lights[2].id)
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, reset)
        XCTAssertEqual(session.editOwner("camera.position"), controlOwner)
        XCTAssertNil(session.operationTask)
        XCTAssertFalse(session.isBusy)
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertEqual(session.editOwner("camera.position"), controlOwner)
        XCTAssertNotEqual(session.saved, session.scene)
    }

    func testStaleControlEndCannotCloseSameControlAfterFirstSave() async throws {
        let session = StudioSession(execute: { request in
            if case .load = request.operation { return nil }
            return try ProjectLibrary(name: "Saved", scene: request.scene)
        })
        try await open(session)
        let original = session.scene
        let previousGeneration = session.generation
        let owner = session.editOwner("camera.position.x")
        session.editChanged(true, owner: owner, from: previousGeneration)
        try await session.beginLibraryOperation(.save, from: previousGeneration).value
        let currentGeneration = session.generation
        XCTAssertNotEqual(currentGeneration, previousGeneration)
        XCTAssertEqual(session.editOwner("camera.position.x"), owner)

        session.editChanged(true, owner: owner, from: currentGeneration)
        var changed = session.scene
        changed.camera.x += 0.1
        XCTAssertTrue(session.update(changed, from: currentGeneration))
        let editing = session.editor
        session.editChanged(false, owner: owner, from: previousGeneration)
        XCTAssertEqual(session.editor, editing)
        XCTAssertTrue(session.history.isEditing)
        changed.camera.x += 0.1
        XCTAssertTrue(session.update(changed, from: currentGeneration))
        session.editChanged(false, owner: owner, from: currentGeneration)
        XCTAssertTrue(session.undo(from: currentGeneration))
        XCTAssertEqual(session.scene, original)
        XCTAssertFalse(session.history.canUndo, "The old callback must not split the new edit")
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
        XCTAssertFalse(session.apply(.cameraPosition(changed.camera), from: generation))
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
        XCTAssertFalse(session.apply(.cameraPosition(next.camera), from: session.generation))
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

    func testTwoWindowsKeepIndependentEditorsAndRecoverCompetingSave() async throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let first = StudioSession(store: ProjectStore(applicationSupportDirectory: base,
                                                       arguments: [], environment: [:]))
        let second = StudioSession(store: ProjectStore(applicationSupportDirectory: base,
                                                        arguments: [], environment: [:]))
        try await open(first)
        try await first.beginLibraryOperation(.save, from: first.generation).value
        try await open(second)
        let original = first.scene
        XCTAssertEqual(second.scene, original, "Windows open the same stored light UUIDs")
        XCTAssertNotEqual(first.generation, second.generation)
        XCTAssertNotEqual(first.workspaceResetID, second.workspaceResetID)
        XCTAssertTrue(second.select(original.lights[1].id, from: second.generation))
        XCTAssertEqual(first.selection, original.lights[0].id)

        var firstEdit = original
        firstEdit.lights[0].candela += 100
        XCTAssertTrue(first.replace(firstEdit, from: first.generation))
        try await first.beginLibraryOperation(.save, from: first.generation).value
        let firstEditor = first.editor
        let firstLibrary = first.library
        let firstScope = first.workspaceResetID
        var secondEdit = original
        secondEdit.lights[1].position.x += 0.2
        XCTAssertFalse(second.replace(secondEdit, from: first.generation))
        XCTAssertTrue(second.replace(secondEdit, from: second.generation))
        let secondEditor = second.editor
        do {
            try await second.beginLibraryOperation(.save, from: second.generation).value
            XCTFail("The second window must not overwrite the first window's save")
        } catch ProjectLibraryError.staleSnapshot { }
        XCTAssertEqual(second.editor, secondEditor)
        XCTAssertEqual(second.saved, original)
        XCTAssertTrue(second.saveConflict)
        XCTAssertEqual(first.editor, firstEditor)
        XCTAssertEqual(first.library, firstLibrary)

        try await second.beginLibraryOperation(.recover(name: "Second window recovery", replacing: nil),
                                                from: second.generation).value
        XCTAssertEqual(second.scene, secondEdit)
        XCTAssertEqual(second.saved, secondEdit)
        XCTAssertFalse(second.saveConflict)
        XCTAssertFalse(second.history.canUndo, "Recovery explicitly starts another document scope")
        XCTAssertEqual(first.editor, firstEditor)
        XCTAssertEqual(first.library, firstLibrary)
        XCTAssertEqual(first.workspaceResetID, firstScope)
        let disk = ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill"))
        let stored = try XCTUnwrap(disk.load())
        XCTAssertEqual(stored.projects.count, 2)
        XCTAssertTrue(stored.projects.contains { $0.scene == firstEdit })
        XCTAssertTrue(stored.projects.contains { $0.scene == secondEdit })
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
        let controlOwner = session.editOwner("camera.position")
        let id = try XCTUnwrap(session.library?.activeID)
        try await session.applyLibrary(.rename(id, name: "Renamed"), from: generation).value
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, reset)
        XCTAssertEqual(session.editOwner("camera.position"), controlOwner)
        XCTAssertTrue(session.history.canUndo)
        try await session.applyLibrary(.create(name: "Next", scene: .portrait()), from: generation).value
        XCTAssertNotEqual(session.generation, generation)
        XCTAssertNotEqual(session.workspaceResetID, reset)
        XCTAssertNotEqual(session.editOwner("camera.position"), controlOwner)
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
