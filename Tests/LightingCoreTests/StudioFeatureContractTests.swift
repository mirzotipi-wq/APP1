import XCTest
@testable import LightingCore

final class StudioFeatureContractTests: XCTestCase {
    func testNoOpCandidatesPreserveOpenEditRedoAndFeatureReceipt() throws {
        var editor = StudioEditorState()
        var future = editor.scene
        future.camera.x = 2
        XCTAssertTrue(try editor.replace(with: future))
        XCTAssertTrue(editor.undo())

        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        let feature = StudioFeatureSession(context: captured)
        editor.beginEditing(owner: captured.owner)
        let before = editor

        XCTAssertFalse(try editor.update(with: before.scene))
        XCTAssertFalse(try editor.replace(with: before.scene))
        var legacy = before.scene
        legacy.schemaVersion = 1
        XCTAssertFalse(try editor.update(with: legacy))
        XCTAssertFalse(try editor.replace(with: legacy))
        XCTAssertEqual(editor, before)
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))

        editor.endEditing(owner: captured.owner)
        XCTAssertEqual(editor.revision, captured.revision)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertFalse(editor.history.canUndo)
        XCTAssertTrue(editor.history.canRedo)
        XCTAssertTrue(editor.redo())
        XCTAssertEqual(editor.scene, future)
    }

    func testSelectionOnlyClosesEmptyEditWithoutInvalidatingFeatureOrRedo() throws {
        var editor = StudioEditorState()
        var future = editor.scene
        future.lights[0].candela = 1_200
        XCTAssertTrue(try editor.replace(with: future))
        XCTAssertTrue(editor.undo())

        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        let feature = StudioFeatureSession(context: captured)
        let selected = editor.scene.lights[1].id
        editor.beginEditing(owner: "intensity")
        XCTAssertTrue(editor.select(selected))

        XCTAssertEqual(editor.scene, captured.scene)
        XCTAssertEqual(editor.revision, captured.revision)
        XCTAssertEqual(editor.selection, selected)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertFalse(editor.history.canUndo)
        XCTAssertTrue(editor.history.canRedo)
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))

        XCTAssertTrue(editor.redo())
        XCTAssertEqual(editor.scene, future)
        XCTAssertEqual(editor.selection, selected)
        XCTAssertFalse(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
    }

    func testRejectedSelectionsDoNotCloseAnOwnedEdit() throws {
        var editor = StudioEditorState()
        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        var feature = StudioFeatureSession(context: captured)
        editor.beginEditing(owner: captured.owner)
        var owned = editor.scene
        owned.camera.x = 1
        XCTAssertTrue(try editor.update(with: owned))
        feature.didApply(revision: editor.revision)
        let before = editor

        XCTAssertFalse(editor.select(nil))
        XCTAssertFalse(editor.select(before.selection))
        XCTAssertFalse(editor.select(UUID()))
        XCTAssertEqual(editor, before)
        XCTAssertTrue(editor.history.isEditing)
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))

        editor.endEditing(owner: captured.owner)
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, captured.scene)
        XCTAssertFalse(editor.history.canUndo)
    }

    func testInvalidOwnedUpdateIsAtomicAndCorrectionRemainsOneUndo() throws {
        var editor = StudioEditorState()
        var future = editor.scene
        future.camera.x = 2
        XCTAssertTrue(try editor.replace(with: future))
        XCTAssertTrue(editor.undo())
        let selected = editor.scene.lights[2].id
        XCTAssertTrue(editor.select(selected))

        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        var feature = StudioFeatureSession(context: captured)
        editor.beginEditing(owner: captured.owner)
        var owned = editor.scene
        owned.lights[0].candela = 1_000
        XCTAssertTrue(try editor.update(with: owned))
        feature.didApply(revision: editor.revision)
        let before = editor

        var invalid = editor.scene
        invalid.lights.remove(at: 2)
        invalid.subject.y = .infinity
        XCTAssertThrowsError(try editor.update(with: invalid)) { error in
            XCTAssertEqual(error as? SceneError, .invalidScene)
        }
        XCTAssertEqual(editor, before)
        XCTAssertTrue(editor.history.isEditing)
        XCTAssertTrue(editor.history.canRedo)
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))

        var corrected = editor.scene
        corrected.subject.x = 1.5
        XCTAssertTrue(try editor.update(with: corrected))
        feature.didApply(revision: editor.revision)
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        editor.endEditing(owner: captured.owner)
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, captured.scene)
        XCTAssertEqual(editor.selection, selected)
        XCTAssertFalse(editor.history.canUndo)
        XCTAssertTrue(editor.redo())
        XCTAssertEqual(editor.scene, corrected)
    }

    func testDuplicateOwnedResultPreservesReceiptAndAllowsLaterOwnedChange() throws {
        var editor = StudioEditorState()
        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        var feature = StudioFeatureSession(context: captured)
        var first = editor.scene
        first.subject.x = 0.5
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        XCTAssertTrue(try editor.replace(with: first))
        feature.didApply(revision: editor.revision)
        let afterFirst = editor
        let receiptAfterFirst = feature

        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        XCTAssertFalse(try editor.replace(with: first))
        // An accepted identical result can acknowledge the unchanged receipt.
        feature.didApply(revision: editor.revision)
        XCTAssertEqual(editor, afterFirst)
        XCTAssertEqual(feature, receiptAfterFirst)

        var second = editor.scene
        second.subject.x = 1.5
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        XCTAssertTrue(try editor.replace(with: second))
        feature.didApply(revision: editor.revision)
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))

        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, first)
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, captured.scene)
        XCTAssertFalse(editor.undo())
    }

    func testNoOpResultCannotReviveReceiptAfterUnrelatedEditAndUndo() throws {
        var editor = StudioEditorState()
        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        var feature = StudioFeatureSession(context: captured)
        var owned = editor.scene
        owned.subject.x = 1
        XCTAssertTrue(try editor.update(with: owned))
        feature.didApply(revision: editor.revision)

        var unrelated = editor.scene
        unrelated.camera.x = 2
        XCTAssertTrue(try editor.replace(with: unrelated))
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, owned)
        XCTAssertFalse(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))

        let before = editor
        XCTAssertFalse(try editor.update(with: owned))
        XCTAssertEqual(editor, before)
        XCTAssertFalse(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
    }

    func testCancellingOwnedChangesRestoresRedoButRetiresFeatureReceipt() throws {
        var editor = StudioEditorState()
        var future = editor.scene
        future.camera.x = 2
        XCTAssertTrue(try editor.replace(with: future))
        XCTAssertTrue(editor.undo())

        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        var feature = StudioFeatureSession(context: captured)
        editor.beginEditing(owner: captured.owner)
        var owned = editor.scene
        owned.subject.x = 1
        XCTAssertTrue(try editor.update(with: owned))
        feature.didApply(revision: editor.revision)

        XCTAssertTrue(editor.cancelEditing())
        XCTAssertEqual(editor.scene, captured.scene)
        XCTAssertNotEqual(editor.revision, captured.revision)
        XCTAssertNotEqual(editor.revision, feature.acceptedRevision)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertFalse(editor.history.canUndo)
        XCTAssertTrue(editor.history.canRedo)
        XCTAssertFalse(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        XCTAssertTrue(editor.redo())
        XCTAssertEqual(editor.scene, future)
    }

    func testChangedNoResetAdoptionRejectsWithoutChangingOpenEditOrRedo() throws {
        var editor = StudioEditorState()
        var future = editor.scene
        future.camera.x = 2
        XCTAssertTrue(try editor.replace(with: future))
        XCTAssertTrue(editor.undo())
        XCTAssertTrue(editor.select(editor.scene.lights[2].id))
        editor.beginEditing(owner: "intensity")
        var edited = editor.scene
        edited.lights[0].candela = 1_000
        XCTAssertTrue(try editor.update(with: edited))
        let before = editor

        var changedReceipt = editor.scene
        changedReceipt.camera.x = 5
        XCTAssertThrowsError(try editor.adopt(changedReceipt, resettingHistory: false))
        XCTAssertEqual(editor, before)
        XCTAssertTrue(editor.history.isEditing)
        XCTAssertTrue(editor.history.canRedo)

        XCTAssertTrue(editor.cancelEditing())
        XCTAssertTrue(editor.redo())
        XCTAssertEqual(editor.scene, future)
    }
}
