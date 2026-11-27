import XCTest
@testable import LightingCore

final class StudioEditorStateTests: XCTestCase {
    func testInvalidReplacementIsAtomicIncludingHistorySelectionAndRevision() throws {
        var editor = StudioEditorState()
        let original = editor
        var invalid = editor.scene
        invalid.lights[0].candela = .nan
        XCTAssertThrowsError(try editor.replace(with: invalid))
        XCTAssertEqual(editor, original)
    }

    func testSchemaMigrationKeepsIDsUnitsAndOptionalRepresentations() throws {
        var legacy = LightingScene.portrait()
        legacy.schemaVersion = 1
        let editor = try StudioEditorState(scene: legacy, selection: legacy.lights[1].id)
        XCTAssertEqual(editor.scene.schemaVersion, 5)
        XCTAssertEqual(editor.scene.lights, legacy.lights)
        XCTAssertEqual(editor.scene.camera, legacy.camera)
        XCTAssertNil(editor.scene.cameraLens)
        XCTAssertNil(editor.scene.previewSettings)
        XCTAssertNil(editor.scene.placementRoom)
        XCTAssertEqual(editor.selection, legacy.lights[1].id)
    }

    func testUndoRestoringDeletedLightRetainsValidCurrentSelection() throws {
        var editor = StudioEditorState()
        let initial = editor.scene
        XCTAssertTrue(editor.select(initial.lights[1].id))
        var next = initial
        next.lights.remove(at: 1)
        try editor.replace(with: next)
        XCTAssertEqual(editor.selection, initial.lights[0].id)
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, initial)
        XCTAssertEqual(editor.selection, initial.lights[0].id)
    }

    func testEmptyRigAndInvalidSelectionNeverLeaveDanglingID() throws {
        var editor = StudioEditorState()
        let selected = editor.selection
        XCTAssertFalse(editor.select(UUID()))
        XCTAssertEqual(editor.selection, selected)
        var empty = editor.scene
        empty.lights = []
        try editor.replace(with: empty)
        XCTAssertNil(editor.selection)
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.selection, editor.scene.lights.first?.id)
    }

    func testContinuousEditIsOneUndoAndLateEndCannotCloseNewOwner() throws {
        var editor = StudioEditorState()
        let original = editor.scene
        editor.beginEditing(owner: "intensity")
        for value in [1000.0, 1100.0, 1200.0] {
            var next = editor.scene
            next.lights[0].candela = value
            try editor.update(with: next)
        }
        XCTAssertFalse(editor.undo())
        editor.beginEditing(owner: "height")
        editor.endEditing(owner: "intensity")
        XCTAssertTrue(editor.history.isEditing)
        editor.endEditing(owner: "height")
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, original)
        XCTAssertFalse(editor.history.canUndo)
    }

    func testOutAndBackOptionalEditPreservesNilAndRedoButRetiresRevision() throws {
        var editor = StudioEditorState()
        var next = editor.scene
        next.camera.x = 2
        try editor.replace(with: next)
        XCTAssertTrue(editor.undo())
        let capturedRevision = editor.revision
        editor.beginEditing(owner: "lens")
        next = editor.scene
        next.cameraLens = CameraLens(focalLengthMillimeters: 85)
        try editor.update(with: next)
        next.cameraLens = CameraLens()
        try editor.update(with: next)
        editor.endEditing(owner: "lens")
        XCTAssertNil(editor.scene.cameraLens)
        XCTAssertTrue(editor.history.canRedo)
        XCTAssertFalse(editor.history.canUndo)
        XCTAssertNotEqual(editor.revision, capturedRevision)
    }

    func testSaveAdoptionKeepsHistorySelectionAndRevisionButReloadRetiresThem() throws {
        var editor = StudioEditorState()
        let original = editor.scene
        XCTAssertTrue(editor.select(original.lights[2].id))
        var next = original
        next.camera.x = 1
        try editor.replace(with: next)
        let revision = editor.revision
        try editor.adopt(next, resettingHistory: false)
        XCTAssertEqual(editor.selection, original.lights[2].id)
        XCTAssertEqual(editor.revision, revision)
        XCTAssertTrue(editor.history.canUndo)
        try editor.adopt(next, resettingHistory: true)
        XCTAssertNotEqual(editor.revision, revision)
        XCTAssertEqual(editor.selection, next.lights[0].id)
        XCTAssertFalse(editor.history.canUndo)
    }

    func testFeatureRejectsEditUndoABAAndDismissedOrReplacedPresentation() throws {
        var editor = StudioEditorState()
        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        var feature = StudioFeatureSession(context: captured)
        XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        var next = editor.scene
        next.subject.x = 1
        try editor.replace(with: next)
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, captured.scene)
        XCTAssertFalse(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        feature.didApply(revision: editor.revision)
        feature.dismiss()
        XCTAssertFalse(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        let newer = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        feature = StudioFeatureSession(context: newer)
        XCTAssertFalse(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
        XCTAssertFalse(feature.accepts(newer, generation: UUID(), revision: editor.revision, isBusy: false))
        XCTAssertFalse(feature.accepts(newer, generation: generation, revision: editor.revision, isBusy: true))
    }

    func testOwnedFeatureCanAdvanceAfterEachAcceptedChange() throws {
        var editor = StudioEditorState()
        let generation = UUID()
        let captured = StudioFeatureContext(generation: generation, revision: editor.revision, scene: editor.scene)
        var feature = StudioFeatureSession(context: captured)
        editor.beginEditing(owner: captured.owner)
        for value in [1.0, 2.0] {
            XCTAssertTrue(feature.accepts(captured, generation: generation, revision: editor.revision, isBusy: false))
            var next = editor.scene
            next.subject.x = value
            try editor.update(with: next)
            feature.didApply(revision: editor.revision)
        }
        editor.endEditing(owner: captured.owner)
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, captured.scene)
    }
}
