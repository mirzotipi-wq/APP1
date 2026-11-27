import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

fileprivate actor FeatureReceiptGate {
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

fileprivate actor FeatureLoadRetry {
    private var attempts = 0

    func load() throws -> ProjectLibrary? {
        attempts += 1
        if attempts == 1 { throw ProjectLibraryError.invalidLibrary }
        return nil
    }
}

@MainActor
final class StudioFeatureSessionTests: XCTestCase {
    fileprivate func loadedSession(execute: @escaping StudioSession.Executor = { _ in nil }) async throws -> StudioSession {
        let session = StudioSession(execute: execute)
        try await session.beginLibraryOperation(.load, from: session.generation).value
        return session
    }

    fileprivate func assertUnchanged(_ session: StudioSession, editor: StudioEditorState,
                                     context: StudioFeatureContext, acceptedRevision: UUID,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(session.editor, editor, file: file, line: line)
        XCTAssertEqual(session.feature?.context, context, file: file, line: line)
        XCTAssertEqual(session.feature?.id, context.id, file: file, line: line)
        XCTAssertEqual(session.feature?.acceptedRevision, acceptedRevision, file: file, line: line)
        XCTAssertEqual(session.feature?.isPresented, true, file: file, line: line)
    }

    func testOpenAdmissionPreservesGestureUntilLoadedCurrentValidDestination() async throws {
        let session = StudioSession(execute: { _ in nil })
        let unloaded = session.editor
        let oldGeneration = session.generation
        XCTAssertNil(session.openFeature(.reference, from: oldGeneration))
        XCTAssertEqual(session.editor, unloaded)
        try await session.beginLibraryOperation(.load, from: oldGeneration).value
        let original = session.scene
        let generation = session.generation
        let token = try XCTUnwrap(session.beginPlanDrag(original.lights[0].id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(original.lights[0].id, token: token, translationX: 20,
                                        translationZ: 0, scale: 100, from: generation))
        let editing = session.editor
        let drag = session.planDrag
        XCTAssertNil(session.openFeature(.reference, from: oldGeneration))
        XCTAssertNil(session.openFeature(.targetLux(lightID: UUID()), from: generation))
        XCTAssertEqual(session.editor, editing)
        XCTAssertEqual(session.planDrag, drag)
        XCTAssertNil(session.feature)

        let context = try XCTUnwrap(session.openFeature(.reference, from: generation))
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertEqual(context.scene, editing.scene)
        XCTAssertEqual(context.revision, editing.revision)
        XCTAssertEqual(context.generation, session.workspaceResetID)
        XCTAssertNotEqual(context.generation, generation)
        let opened = session.editor
        XCTAssertNil(session.openFeature(.room, from: generation))
        assertUnchanged(session, editor: opened, context: context, acceptedRevision: context.revision)
        session.finishFeature(context)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, original)
    }

    func testWrongRouteAndInvalidSceneAreAtomicEvenWithAnOpenControl() async throws {
        for destination in [StudioFeatureDestination.reference, .arrangement, .room, .ar] {
            let session = try await loadedSession()
            let context = try XCTUnwrap(session.openFeature(destination, from: session.generation))
            let owner = session.editOwner("camera.x")
            session.editChanged(true, owner: owner, from: session.generation)
            let editor = session.editor
            XCTAssertFalse(session.applyFeatureLight(session.scene.lights[0], from: context))
            if destination == .room || destination == .ar {
                XCTAssertFalse(session.applyFeatureScene(session.scene, from: context))
            } else {
                XCTAssertFalse(session.applyFeatureRoom(ManualRoom(), from: context))
                var invalid = session.scene
                invalid.lights[1].id = invalid.lights[0].id
                XCTAssertFalse(session.applyFeatureScene(invalid, from: context))
                invalid = session.scene
                invalid.camera.x = .nan
                XCTAssertFalse(session.applyFeatureScene(invalid, from: context))
            }
            assertUnchanged(session, editor: editor, context: context, acceptedRevision: context.revision)
            session.finishFeature(context)
            XCTAssertTrue(session.history.isEditing, "Feature teardown cannot close another control's group")
            session.editChanged(false, owner: owner, from: session.generation)
        }
    }

    func testSceneNoOpIsAcceptedOnceAndRetiresWithoutDiscardingRedo() async throws {
        for destination in [StudioFeatureDestination.reference, .arrangement] {
            let session = try await loadedSession()
            var edited = session.scene
            edited.camera.x += 0.25
            XCTAssertTrue(session.replace(edited, from: session.generation))
            XCTAssertTrue(session.undo(from: session.generation))
            let context = try XCTUnwrap(session.openFeature(destination, from: session.generation))
            let id = session.scene.lights[0].id
            let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: session.generation))
            XCTAssertFalse(session.dragLight(id, token: token, translationX: 0, translationZ: 0,
                                             scale: 100, from: session.generation))
            let drag = try XCTUnwrap(session.planDrag)
            let editor = session.editor
            XCTAssertTrue(session.applyFeatureScene(context.scene, from: context))
            XCTAssertEqual(session.editor, editor)
            XCTAssertEqual(session.planDrag, drag)
            XCTAssertEqual(session.feature?.isPresented, false)
            XCTAssertEqual(session.feature?.context, context)
            XCTAssertFalse(session.acceptsFeature(context))
            XCTAssertFalse(session.applyFeatureScene(edited, from: context))
            XCTAssertEqual(session.editor, editor)
            session.finishPlanDrag(token: token, lightID: id, generation: session.generation)
            XCTAssertTrue(session.redo(from: session.generation))
            XCTAssertEqual(session.scene, edited)
        }
    }

    func testTargetLuxUsesCapturedUUIDAndOnlyAcceptsOutputChanges() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let id = original.lights[0].id
        let context = try XCTUnwrap(session.openFeature(.targetLux(lightID: id), from: session.generation))
        XCTAssertTrue(session.select(original.lights[2].id, from: session.generation))
        let token = try XCTUnwrap(session.beginPlanDrag(original.lights[2].id, scale: 100,
                                                       from: session.generation))
        XCTAssertFalse(session.dragLight(original.lights[2].id, token: token, translationX: 0, translationZ: 0,
                                         scale: 100, from: session.generation))
        let drag = try XCTUnwrap(session.planDrag)
        let editor = session.editor
        XCTAssertFalse(session.applyFeatureScene(original, from: context))
        XCTAssertFalse(session.applyFeatureRoom(nil, from: context))
        XCTAssertFalse(session.applyFeatureLight(original.lights[1], from: context))
        var invalid = original.lights[0]
        invalid.position.x += 0.5
        XCTAssertFalse(session.applyFeatureLight(invalid, from: context))
        invalid = original.lights[0]
        invalid.name += " changed"
        XCTAssertFalse(session.applyFeatureLight(invalid, from: context))
        invalid = original.lights[0]
        invalid.candela = .infinity
        XCTAssertFalse(session.applyFeatureLight(invalid, from: context))
        assertUnchanged(session, editor: editor, context: context, acceptedRevision: context.revision)
        XCTAssertEqual(session.planDrag, drag)

        var adjusted = original.lights[0]
        adjusted.candela += 321
        XCTAssertTrue(session.applyFeatureLight(adjusted, from: context))
        var expected = original
        expected.lights[0] = adjusted
        XCTAssertEqual(session.scene, expected)
        XCTAssertEqual(session.selection, original.lights[2].id)
        XCTAssertEqual(session.feature?.isPresented, false)
        XCTAssertEqual(session.feature?.acceptedRevision, session.revision)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.applyFeatureLight(adjusted, from: context))
        let nextToken = try XCTUnwrap(session.beginPlanDrag(original.lights[2].id, scale: 200,
                                                           from: session.generation))
        XCTAssertTrue(session.dragLight(original.lights[2].id, token: nextToken, translationX: 20, translationZ: 0,
                                        scale: 200, from: session.generation))
        XCTAssertEqual(session.scene.lights[2].position.x,
                       expected.lights[2].position.x + 0.1, accuracy: 1e-12)
        session.finishPlanDrag(token: nextToken, lightID: original.lights[2].id, generation: session.generation)
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, expected)
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertFalse(session.history.canUndo)
    }

    func testTargetLuxNoOpRetiresWithoutChangingEditor() async throws {
        let session = try await loadedSession()
        let light = session.scene.lights[0]
        let context = try XCTUnwrap(session.openFeature(.targetLux(lightID: light.id), from: session.generation))
        let token = try XCTUnwrap(session.beginPlanDrag(light.id, scale: 100, from: session.generation))
        XCTAssertFalse(session.dragLight(light.id, token: token, translationX: 0, translationZ: 0,
                                         scale: 100, from: session.generation))
        let drag = try XCTUnwrap(session.planDrag)
        let editor = session.editor
        XCTAssertTrue(session.applyFeatureLight(light, from: context))
        XCTAssertEqual(session.editor, editor)
        XCTAssertEqual(session.planDrag, drag)
        XCTAssertEqual(session.feature?.isPresented, false)
        XCTAssertFalse(session.acceptsFeature(context))
    }

    func testRoomAndARAdvanceOwnReceiptAndUndoAllAcceptedMeasurementsTogether() async throws {
        for destination in [StudioFeatureDestination.room, .ar] {
            let session = try await loadedSession()
            let original = session.scene
            let context = try XCTUnwrap(session.openFeature(destination, from: session.generation))
            let opened = session.editor
            XCTAssertTrue(session.applyFeatureRoom(nil, from: context))
            XCTAssertEqual(session.editor, opened, "Accepted no-op cannot begin a history group")
            let first = ManualRoom(widthMeters: 8, depthMeters: 9, subjectX: 4, subjectZ: 3)
            XCTAssertTrue(session.applyFeatureRoom(first, from: context))
            XCTAssertTrue(session.history.isEditing)
            XCTAssertEqual(session.feature?.acceptedRevision, session.revision)
            XCTAssertNotEqual(session.revision, context.revision)
            XCTAssertEqual(session.feature?.context, context, "The opening snapshot stays immutable")
            let editing = session.editor
            XCTAssertTrue(session.applyFeatureRoom(first, from: context))
            var invalid = first
            invalid.widthMeters = 2 // Smaller than the preserved subject offset.
            XCTAssertFalse(session.applyFeatureRoom(invalid, from: context))
            assertUnchanged(session, editor: editing, context: context, acceptedRevision: editing.revision)
            var final = first
            final.yawDegrees = 37
            XCTAssertTrue(session.applyFeatureRoom(final, from: context))
            XCTAssertTrue(session.acceptsFeature(context))
            session.retireFeature(context)
            XCTAssertFalse(session.history.isEditing)
            XCTAssertFalse(session.applyFeatureRoom(first, from: context))
            XCTAssertTrue(session.undo(from: session.generation))
            XCTAssertEqual(session.scene, original)
            XCTAssertFalse(session.history.canUndo)
            XCTAssertTrue(session.redo(from: session.generation))
            XCTAssertEqual(session.scene.placementRoom, final)
        }
    }

    func testUnrelatedTypedOrSceneUpdateSeparatesRoomUndoButInvalidAndNoOpDoNot() async throws {
        for typed in [true, false] {
            let session = try await loadedSession()
            let original = session.scene
            let generation = session.generation
            let context = try XCTUnwrap(session.openFeature(.room, from: generation))
            XCTAssertTrue(session.applyFeatureRoom(ManualRoom(), from: context))
            let roomEditor = session.editor
            var invalid = session.scene
            invalid.camera.x = .nan
            if typed {
                XCTAssertFalse(session.apply(.cameraPosition(invalid.camera), from: generation))
                XCTAssertFalse(session.apply(.cameraPosition(session.scene.camera), from: generation))
            } else {
                XCTAssertFalse(session.update(invalid, from: generation))
                XCTAssertFalse(session.update(session.scene, from: generation))
            }
            assertUnchanged(session, editor: roomEditor, context: context, acceptedRevision: roomEditor.revision)
            var unrelated = session.scene
            unrelated.camera.x += 0.5
            if typed {
                XCTAssertTrue(session.apply(.cameraPosition(unrelated.camera), from: generation))
            } else {
                XCTAssertTrue(session.update(unrelated, from: generation))
            }
            XCTAssertFalse(session.history.isEditing)
            XCTAssertEqual(session.feature?.acceptedRevision, roomEditor.revision)
            let changed = session.editor
            XCTAssertFalse(session.applyFeatureRoom(nil, from: context))
            XCTAssertEqual(session.editor, changed)
            XCTAssertTrue(session.undo(from: generation))
            XCTAssertEqual(session.scene, roomEditor.scene)
            XCTAssertFalse(session.acceptsFeature(context), "Undo cannot revive an earlier receipt")
            XCTAssertTrue(session.undo(from: generation))
            XCTAssertEqual(session.scene, original)
            XCTAssertFalse(session.history.canUndo)
        }
    }

    func testEditAwayAndUndoBackCannotReviveSnapshotOrDiscardRedo() async throws {
        let session = try await loadedSession()
        let context = try XCTUnwrap(session.openFeature(.reference, from: session.generation))
        var changed = context.scene
        changed.camera.x += 0.75
        XCTAssertTrue(session.replace(changed, from: session.generation))
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, context.scene)
        XCTAssertNotEqual(session.revision, context.revision)
        let editor = session.editor
        XCTAssertFalse(session.acceptsFeature(context))
        XCTAssertFalse(session.applyFeatureScene(context.scene, from: context))
        XCTAssertFalse(session.applyFeatureScene(changed, from: context))
        assertUnchanged(session, editor: editor, context: context, acceptedRevision: context.revision)
        XCTAssertTrue(session.redo(from: session.generation))
        XCTAssertEqual(session.scene, changed)
    }

    func testRetiredOwnerCannotApplyOrFinishTheNextPresentedRoomGroup() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let first = try XCTUnwrap(session.openFeature(.room, from: session.generation))
        let firstRoom = ManualRoom()
        XCTAssertTrue(session.applyFeatureRoom(firstRoom, from: first))
        session.retireFeature(first)
        let second = try XCTUnwrap(session.openFeature(.ar, from: session.generation))
        XCTAssertNotEqual(first.id, second.id)
        var secondRoom = firstRoom
        secondRoom.yawDegrees = 45
        XCTAssertTrue(session.applyFeatureRoom(secondRoom, from: second))
        let editor = session.editor
        session.retireFeature(first)
        session.finishFeature(first)
        XCTAssertFalse(session.applyFeatureRoom(nil, from: first))
        assertUnchanged(session, editor: editor, context: second, acceptedRevision: editor.revision)
        XCTAssertTrue(session.history.isEditing)
        XCTAssertTrue(session.acceptsFeature(second))
        session.finishFeature(second)
        XCTAssertNil(session.feature)
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene.placementRoom, firstRoom)
        XCTAssertTrue(session.undo(from: session.generation))
        XCTAssertEqual(session.scene, original)
    }

    func testForeignPresentationWithEqualSnapshotCannotWriteOrCloseOwner() async throws {
        let session = try await loadedSession()
        let context = try XCTUnwrap(session.openFeature(.reference, from: session.generation))
        let foreign = StudioFeatureContext(generation: context.generation,
                                           revision: context.revision, scene: context.scene)
        let editor = session.editor
        XCTAssertFalse(session.acceptsFeature(foreign))
        XCTAssertFalse(session.applyFeatureScene(context.scene, from: foreign))
        session.retireFeature(foreign)
        session.finishFeature(foreign)
        assertUnchanged(session, editor: editor, context: context, acceptedRevision: context.revision)
        XCTAssertTrue(session.acceptsFeature(context))
    }

    func testBusyRejectionKeepsFeatureAndFirstSavePreservesLogicalContext() async throws {
        let gate = FeatureReceiptGate()
        let session = try await loadedSession { request in
            if case .load = request.operation { return nil }
            let receipt = try ProjectLibrary(name: "Saved", scene: request.scene)
            await gate.pause()
            return receipt
        }
        let storageGeneration = session.generation
        let context = try XCTUnwrap(session.openFeature(.reference, from: storageGeneration))
        let editor = session.editor
        let saving = try session.beginLibraryOperation(.save, from: storageGeneration)
        await gate.waitUntilEntered()
        XCTAssertTrue(session.isBusy)
        XCTAssertNil(session.openFeature(.room, from: storageGeneration))
        XCTAssertFalse(session.acceptsFeature(context))
        XCTAssertFalse(session.applyFeatureScene(context.scene, from: context))
        assertUnchanged(session, editor: editor, context: context, acceptedRevision: context.revision)
        await gate.open()
        try await saving.value
        XCTAssertNotEqual(session.generation, storageGeneration)
        XCTAssertEqual(session.workspaceResetID, context.generation)
        XCTAssertEqual(session.editor, editor)
        XCTAssertTrue(session.acceptsFeature(context))
        var changed = context.scene
        changed.camera.x += 0.25
        XCTAssertTrue(session.applyFeatureScene(changed, from: context))
        XCTAssertEqual(session.scene, changed)
        XCTAssertEqual(session.saved, context.scene)
    }

    func testReloadAndProjectSwitchClearFeatureAndRejectItsLateCallbacks() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = StudioSession(store: ProjectStore(applicationSupportDirectory: directory,
                                                       arguments: [], environment: [:]))
        try await session.beginLibraryOperation(.load, from: session.generation).value
        try await session.beginLibraryOperation(.save, from: session.generation).value
        for reload in [true, false] {
            let old = try XCTUnwrap(session.openFeature(.reference, from: session.generation))
            if reload {
                try await session.beginLibraryOperation(.reload, from: session.generation).value
            } else {
                try await session.applyLibrary(.create(name: "Next", scene: .portrait()),
                                               from: session.generation).value
            }
            XCTAssertNil(session.feature)
            XCTAssertNotEqual(session.workspaceResetID, old.generation)
            let next = try XCTUnwrap(session.openFeature(.room, from: session.generation))
            let editor = session.editor
            XCTAssertFalse(session.applyFeatureScene(old.scene, from: old))
            session.finishFeature(old)
            assertUnchanged(session, editor: editor, context: next, acceptedRevision: next.revision)
            session.finishFeature(next)
        }
    }

    func testFailedProjectOperationsKeepTheOpenFeatureUsable() async throws {
        let operations: [ProjectLibraryOperation] = [
            .save, .reload, .recover(name: "Recovery", replacing: nil)
        ]
        for operation in operations {
            let gate = FeatureReceiptGate()
            let session = try await loadedSession { request in
                if case .load = request.operation { return nil }
                await gate.pause()
                throw ProjectLibraryError.staleSnapshot
            }
            let context = try XCTUnwrap(session.openFeature(.reference, from: session.generation))
            let editor = session.editor
            let storageGeneration = session.generation
            let pending = try session.beginLibraryOperation(operation, from: storageGeneration)
            await gate.waitUntilEntered()
            XCTAssertFalse(session.applyFeatureScene(context.scene, from: context))
            await gate.open()
            do {
                try await pending.value
                XCTFail("The fixture operation must fail")
            } catch ProjectLibraryError.staleSnapshot { }
            assertUnchanged(session, editor: editor, context: context,
                            acceptedRevision: context.revision)
            XCTAssertEqual(session.generation, storageGeneration)
            XCTAssertFalse(session.isBusy)
            XCTAssertNil(session.operationTask)
            XCTAssertTrue(session.acceptsFeature(context))
            var proposed = context.scene
            proposed.subject.x += 0.25
            XCTAssertTrue(session.applyFeatureScene(proposed, from: context))
            XCTAssertEqual(session.scene, proposed)
        }
    }

    func testRepeatedHealthyLoadRejectsBeforeReservationOrEndingGesture() async throws {
        let session = try await loadedSession()
        let context = try XCTUnwrap(session.openFeature(.reference, from: session.generation))
        let token = try XCTUnwrap(session.beginPlanDrag(session.scene.lights[0].id, scale: 100,
                                                       from: session.generation))
        XCTAssertTrue(session.dragLight(session.scene.lights[0].id, token: token, translationX: 25,
                                        translationZ: 0, scale: 100, from: session.generation))
        let editor = session.editor
        let drag = session.planDrag
        let generation = session.generation
        XCTAssertThrowsError(try session.beginLibraryOperation(.load, from: generation)) {
            XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
        }
        assertUnchanged(session, editor: editor, context: context, acceptedRevision: context.revision)
        XCTAssertEqual(session.planDrag, drag)
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.workspaceResetID, context.generation)
        XCTAssertFalse(session.isBusy)
        XCTAssertNil(session.operationTask)
    }

    func testFailedInitialLoadBlocksFeatureButExplicitRetryCanRecover() async throws {
        let retry = FeatureLoadRetry()
        let session = StudioSession(execute: { _ in try await retry.load() })
        do {
            try await session.beginLibraryOperation(.load, from: session.generation).value
            XCTFail("The first fixture load must fail")
        } catch ProjectLibraryError.invalidLibrary { }
        XCTAssertTrue(session.loaded)
        XCTAssertTrue(session.saveBlocked)
        let blocked = session.editor
        XCTAssertNil(session.openFeature(.reference, from: session.generation))
        XCTAssertEqual(session.editor, blocked)
        XCTAssertNil(session.feature)
        try await session.beginLibraryOperation(.load, from: session.generation).value
        XCTAssertFalse(session.saveBlocked)
        XCTAssertFalse(session.isBusy)
        let context = try XCTUnwrap(session.openFeature(.reference, from: session.generation))
        XCTAssertTrue(session.applyFeatureScene(context.scene, from: context))
    }

    func testAcceptedFeatureMutationClearsZeroMotionPlanOriginBeforeNextDrag() async throws {
        for room in [false, true] {
            let session = try await loadedSession()
            let context = try XCTUnwrap(session.openFeature(room ? .room : .arrangement,
                                                           from: session.generation))
            let id = session.scene.lights[0].id
            let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: session.generation))
            XCTAssertFalse(session.dragLight(id, token: token, translationX: 0, translationZ: 0,
                                             scale: 100, from: session.generation))
            let idleDrag = try XCTUnwrap(session.planDrag)
            let editor = session.editor
            if room {
                XCTAssertTrue(session.applyFeatureRoom(nil, from: context))
                XCTAssertFalse(session.applyFeatureRoom(ManualRoom(widthMeters: .nan), from: context))
            } else {
                var invalid = context.scene
                invalid.camera.x = .nan
                XCTAssertFalse(session.applyFeatureScene(invalid, from: context))
            }
            XCTAssertEqual(session.editor, editor)
            XCTAssertEqual(session.planDrag, idleDrag)
            if room {
                XCTAssertTrue(session.applyFeatureRoom(ManualRoom(), from: context))
                session.retireFeature(context)
            } else {
                var changed = context.scene
                changed.lights[0].position.x += 2
                XCTAssertTrue(session.applyFeatureScene(changed, from: context))
            }
            XCTAssertNil(session.planDrag)
            let accepted = session.scene
            let nextToken = try XCTUnwrap(session.beginPlanDrag(id, scale: 200, from: session.generation))
            XCTAssertTrue(session.dragLight(id, token: nextToken, translationX: 20, translationZ: 0,
                                            scale: 200, from: session.generation))
            XCTAssertEqual(session.scene.lights[0].position.x,
                           accepted.lights[0].position.x + 0.1, accuracy: 1e-12)
            session.finishPlanDrag(token: nextToken, lightID: id, generation: session.generation)
            XCTAssertTrue(session.undo(from: session.generation))
            XCTAssertEqual(session.scene, accepted)
        }
    }
}
