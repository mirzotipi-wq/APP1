import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

@MainActor
final class StudioPlanSessionTests: XCTestCase {
    private func loadedSession() async throws -> StudioSession {
        let session = StudioSession(execute: { request in
            guard case .load = request.operation else {
                throw ProjectLibraryError.invalidLibrary
            }
            return nil
        })
        try await session.beginLibraryOperation(.load, from: session.generation).value
        return session
    }

    private func assertUnchanged(_ session: StudioSession, editor: StudioEditorState,
                                 drag: StudioSession.PlanDrag?,
                                 file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(session.scene, editor.scene, file: file, line: line)
        XCTAssertEqual(session.selection, editor.selection, file: file, line: line)
        XCTAssertEqual(session.revision, editor.revision, file: file, line: line)
        XCTAssertEqual(session.history, editor.history, file: file, line: line)
        XCTAssertEqual(session.planDrag, drag, file: file, line: line)
    }

    func testMissingOrUnselectedLightAndStaleGenerationLeavePlanStateUnchanged() async throws {
        let session = try await loadedSession()
        let generation = session.generation
        let selected = try XCTUnwrap(session.selection)
        let unselected = session.scene.lights[1].id
        let missing = UUID()
        XCTAssertFalse(session.scene.lights.contains { $0.id == missing })
        let rejected = [(missing, generation), (unselected, generation), (selected, UUID())]
        let idle = session.editor

        for (id, callbackGeneration) in rejected {
            XCTAssertFalse(session.dragLight(id, translationX: 20, translationZ: -10,
                                             scale: 100, from: callbackGeneration))
            assertUnchanged(session, editor: idle, drag: nil)
        }

        XCTAssertTrue(session.dragLight(selected, translationX: 20, translationZ: -10,
                                        scale: 100, from: generation))
        let editing = session.editor
        let drag = try XCTUnwrap(session.planDrag)
        XCTAssertTrue(session.history.isEditing)
        for (id, callbackGeneration) in rejected {
            XCTAssertFalse(session.dragLight(id, translationX: 80, translationZ: 60,
                                             scale: 50, from: callbackGeneration))
            assertUnchanged(session, editor: editing, drag: drag)
        }

        session.finishPlanDrag(lightID: selected, generation: generation)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, idle.scene)
        XCTAssertFalse(session.undo(from: generation))
    }

    func testInvalidScaleOrTranslationPreservesIdleRedoAndActiveDrag() async throws {
        let session = try await loadedSession()
        let generation = session.generation
        let original = session.scene
        let id = try XCTUnwrap(session.selection)
        var earlierEdit = original
        earlierEdit.lights[0].candela += 100
        XCTAssertTrue(session.replace(earlierEdit, from: generation))
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertTrue(session.history.canRedo)
        let idle = session.editor
        let invalid: [(x: Double, z: Double, scale: Double)] = [
            (20, -10, 0), (20, -10, -100),
            (20, -10, .nan), (20, -10, .infinity), (20, -10, -.infinity),
            (.nan, -10, 100), (.infinity, -10, 100), (-.infinity, -10, 100),
            (20, .nan, 100), (20, .infinity, 100), (20, -.infinity, 100)
        ]
        for input in invalid {
            XCTAssertFalse(session.dragLight(id, translationX: input.x, translationZ: input.z,
                                             scale: input.scale, from: generation))
            assertUnchanged(session, editor: idle, drag: nil)
        }

        XCTAssertTrue(session.dragLight(id, translationX: 20, translationZ: -10,
                                        scale: 100, from: generation))
        let editing = session.editor
        let drag = try XCTUnwrap(session.planDrag)
        XCTAssertTrue(session.history.isEditing)
        XCTAssertTrue(session.history.canRedo)
        for input in invalid {
            XCTAssertFalse(session.dragLight(id, translationX: input.x, translationZ: input.z,
                                             scale: input.scale, from: generation))
            assertUnchanged(session, editor: editing, drag: drag)
        }

        XCTAssertTrue(session.dragLight(id, translationX: 40, translationZ: -20,
                                        scale: 999, from: generation))
        XCTAssertEqual(session.scene.lights[0].position.x,
                       original.lights[0].position.x + 0.4, accuracy: 1e-12)
        XCTAssertEqual(session.scene.lights[0].position.z,
                       original.lights[0].position.z - 0.2, accuracy: 1e-12)
        XCTAssertEqual(session.planDrag, drag, "Rejected inputs preserve the frozen origin and scale")
        XCTAssertNotEqual(session.revision, editing.revision)
        session.finishPlanDrag(lightID: id, generation: generation)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertFalse(session.history.canRedo)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertFalse(session.undo(from: generation))
    }

    func testSelectionChangeCommitsPlanExactlyOnceWithoutChangingSceneRevision() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let nextID = original.lights[1].id
        XCTAssertTrue(session.dragLight(id, translationX: 10, translationZ: 0,
                                        scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, translationX: 30, translationZ: -20,
                                        scale: 100, from: generation))
        let editing = session.editor
        let drag = try XCTUnwrap(session.planDrag)
        XCTAssertFalse(session.select(id, from: generation))
        assertUnchanged(session, editor: editing, drag: drag)

        XCTAssertTrue(session.select(nextID, from: generation))
        XCTAssertEqual(session.selection, nextID)
        XCTAssertEqual(session.scene, editing.scene)
        XCTAssertEqual(session.revision, editing.revision)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertTrue(session.history.canUndo)
        let committed = session.editor
        XCTAssertFalse(session.select(nextID, from: generation))
        session.finishPlanDrag(lightID: id, generation: generation)
        assertUnchanged(session, editor: committed, drag: nil)

        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertEqual(session.selection, nextID)
        XCTAssertNotEqual(session.revision, editing.revision)
        XCTAssertFalse(session.undo(from: generation), "Selection and delayed end add no duplicate entry")
        XCTAssertTrue(session.redo(from: generation))
        XCTAssertEqual(session.scene, editing.scene)
        XCTAssertEqual(session.selection, nextID)
        XCTAssertFalse(session.redo(from: generation))
    }

    func testStalePlanEndCannotFinishNewLightDrag() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let firstID = original.lights[0].id
        let secondID = original.lights[1].id
        XCTAssertTrue(session.dragLight(firstID, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let firstResult = session.scene
        XCTAssertTrue(session.select(secondID, from: generation))
        XCTAssertTrue(session.dragLight(secondID, translationX: 0, translationZ: 30,
                                        scale: 100, from: generation))
        let editing = session.editor
        let drag = try XCTUnwrap(session.planDrag)
        XCTAssertEqual(drag.lightID, secondID)
        XCTAssertTrue(session.history.isEditing)

        session.finishPlanDrag(lightID: firstID, generation: generation)
        assertUnchanged(session, editor: editing, drag: drag)
        session.finishPlanDrag(lightID: secondID, generation: UUID())
        assertUnchanged(session, editor: editing, drag: drag)

        session.finishPlanDrag(lightID: secondID, generation: generation)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertEqual(session.revision, editing.revision)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, firstResult)
        XCTAssertEqual(session.selection, secondID)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertFalse(session.undo(from: generation))
    }

    func testDiscreteReplacementDuringPlanDragKeepsSeparateUndoSteps() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        XCTAssertTrue(session.dragLight(id, translationX: 25, translationZ: -10,
                                        scale: 100, from: generation))
        let dragged = session.scene
        let dragRevision = session.revision
        XCTAssertNotNil(session.planDrag)
        XCTAssertTrue(session.history.isEditing)
        var replacement = dragged
        replacement.lights[0].candela += 200

        XCTAssertTrue(session.replace(replacement, from: generation))
        XCTAssertEqual(session.scene, replacement)
        XCTAssertEqual(session.selection, id)
        XCTAssertNotEqual(session.revision, dragRevision)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        let replaced = session.editor
        session.finishPlanDrag(lightID: id, generation: generation)
        assertUnchanged(session, editor: replaced, drag: nil)

        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, dragged)
        XCTAssertNotEqual(session.revision, replaced.revision)
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertFalse(session.undo(from: generation))
        XCTAssertTrue(session.redo(from: generation))
        XCTAssertEqual(session.scene, dragged)
        XCTAssertTrue(session.redo(from: generation))
        XCTAssertEqual(session.scene, replacement)
        XCTAssertFalse(session.redo(from: generation))
    }

    func testDifferentControlCommitsPlanAndRejectsItsDelayedEnd() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        XCTAssertTrue(session.dragLight(id, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let drag = try XCTUnwrap(session.planDrag)
        let dragged = session.scene
        let dragRevision = session.revision
        let owner = session.editOwner("intensity.\(id.uuidString)")
        XCTAssertNotEqual(owner, drag.owner)

        session.editChanged(true, owner: owner, from: generation)
        XCTAssertNil(session.planDrag)
        XCTAssertTrue(session.history.isEditing)
        XCTAssertEqual(session.scene, dragged)
        XCTAssertEqual(session.revision, dragRevision)
        var firstUpdate = dragged
        firstUpdate.lights[0].candela += 100
        XCTAssertTrue(session.update(firstUpdate, from: generation))
        let editing = session.editor
        XCTAssertNotEqual(editing.revision, dragRevision)

        session.finishPlanDrag(lightID: id, generation: generation)
        session.editChanged(false, owner: drag.owner, from: generation)
        assertUnchanged(session, editor: editing, drag: nil)
        XCTAssertTrue(session.history.isEditing, "The intensity control still owns the active edit")
        var finalUpdate = firstUpdate
        finalUpdate.lights[0].candela += 100
        XCTAssertTrue(session.update(finalUpdate, from: generation))
        let finalRevision = session.revision
        session.editChanged(false, owner: owner, from: generation)
        XCTAssertFalse(session.history.isEditing)
        XCTAssertNil(session.planDrag)
        XCTAssertEqual(session.revision, finalRevision)

        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, dragged, "Both intensity updates form one separate edit")
        XCTAssertTrue(session.undo(from: generation))
        XCTAssertEqual(session.scene, original)
        XCTAssertFalse(session.undo(from: generation))
        XCTAssertTrue(session.redo(from: generation))
        XCTAssertEqual(session.scene, dragged)
        XCTAssertTrue(session.redo(from: generation))
        XCTAssertEqual(session.scene, finalUpdate)
        XCTAssertFalse(session.redo(from: generation))
    }
}
