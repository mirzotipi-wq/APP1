import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

@MainActor
final class StudioPlanGestureLifetimeTests: XCTestCase {
    private func loadedSession() async throws -> StudioSession {
        let session = StudioSession(execute: { request in
            if case .load = request.operation { return nil }
            var library = try request.expected ?? ProjectLibrary(name: "Saved", scene: request.scene)
            try library.updateActiveScene(request.scene)
            return library
        })
        try await session.beginLibraryOperation(.load, from: session.generation).value
        return session
    }

    private func assertRejectedCallbacks(_ session: StudioSession, token: UUID, id: UUID,
                                         generation: UUID, translation: Double = 20,
                                         file: StaticString = #filePath, line: UInt = #line) {
        let editor = session.editor
        let drag = session.planDrag
        XCTAssertFalse(session.dragLight(id, token: token, translationX: translation, translationZ: 0,
                                         scale: 100, from: generation), file: file, line: line)
        XCTAssertEqual(session.editor, editor, file: file, line: line)
        XCTAssertEqual(session.planDrag, drag, file: file, line: line)
        session.finishPlanDrag(token: token, lightID: id, generation: generation)
        XCTAssertEqual(session.editor, editor, file: file, line: line)
        XCTAssertEqual(session.planDrag, drag, file: file, line: line)
    }

    /// Every accepted command remains independently reachable in both directions.
    private func assertHistory(_ session: StudioSession, scenes: [LightingScene],
                               file: StaticString = #filePath, line: UInt = #line) {
        let generation = session.generation
        let selected = session.selection
        XCTAssertEqual(session.scene, scenes.last, file: file, line: line)
        XCTAssertFalse(session.history.isEditing, file: file, line: line)
        for scene in scenes.dropLast().reversed() {
            XCTAssertTrue(session.undo(from: generation), file: file, line: line)
            XCTAssertEqual(session.scene, scene, file: file, line: line)
            XCTAssertEqual(session.selection, selected, file: file, line: line)
        }
        XCTAssertFalse(session.undo(from: generation), file: file, line: line)
        for scene in scenes.dropFirst() {
            XCTAssertTrue(session.redo(from: generation), file: file, line: line)
            XCTAssertEqual(session.scene, scene, file: file, line: line)
            XCTAssertEqual(session.selection, selected, file: file, line: line)
        }
        XCTAssertFalse(session.redo(from: generation), file: file, line: line)
    }

    func testFinishedGestureRejectsLateChangesAndEndWithoutRestarting() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        assertRejectedCallbacks(session, token: UUID(), id: id, generation: generation)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let dragged = session.scene

        session.finishPlanDrag()
        XCTAssertNil(session.planDrag)
        assertRejectedCallbacks(session, token: token, id: id, generation: generation)
        assertRejectedCallbacks(session, token: token, id: id, generation: generation, translation: 30)
        assertHistory(session, scenes: [original, dragged])
    }

    func testRetiredTokenCannotMutateOrEndNewSameLightGesture() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let oldToken = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        let oldOwner = try XCTUnwrap(session.planDrag?.owner)
        XCTAssertTrue(session.dragLight(id, token: oldToken, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let first = session.scene
        session.finishPlanDrag(token: oldToken, lightID: id, generation: generation)

        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 200, from: generation))
        XCTAssertNotEqual(token, oldToken)
        XCTAssertNotEqual(session.planDrag?.owner, oldOwner)
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 10, translationZ: 0,
                                        scale: 200, from: generation))
        let editing = session.editor
        let drag = session.planDrag
        XCTAssertNil(session.beginPlanDrag(id, scale: 999, from: generation))
        XCTAssertEqual(session.editor, editing)
        XCTAssertEqual(session.planDrag, drag)
        assertRejectedCallbacks(session, token: oldToken, id: id, generation: generation)
        assertRejectedCallbacks(session, token: UUID(), id: id, generation: generation)
        session.endEditing(owner: oldOwner)
        session.editChanged(false, owner: oldOwner, from: generation)
        XCTAssertEqual(session.editor, editing)
        XCTAssertEqual(session.planDrag, drag)
        XCTAssertTrue(session.history.isEditing)

        XCTAssertTrue(session.dragLight(id, token: token, translationX: 30, translationZ: 0,
                                        scale: 999, from: generation))
        XCTAssertEqual(session.scene.lights[0].position.x,
                       first.lights[0].position.x + 0.15, accuracy: 1e-12)
        let second = session.scene
        session.finishPlanDrag(token: token, lightID: id, generation: generation)
        assertHistory(session, scenes: [original, first, second])
    }

    func testRenameReplacementRetiresCumulativeCallbacksAndKeepsBothUndoSteps() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let dragged = session.scene
        var renamed = dragged
        renamed.lights[0].name = "Renamed during drag"
        XCTAssertTrue(session.replace(renamed, from: generation))
        XCTAssertEqual(session.generation, generation)
        XCTAssertNil(session.planDrag)

        assertRejectedCallbacks(session, token: token, id: id, generation: generation)
        XCTAssertEqual(session.scene.lights[0].position, dragged.lights[0].position)
        assertHistory(session, scenes: [original, dragged, renamed])
    }

    func testForeignControlRetiresPlanCallbacksWithoutSplittingItsOwnEdit() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let dragged = session.scene
        let owner = session.editOwner("height")
        session.editChanged(true, owner: owner, from: generation)
        XCTAssertNil(session.planDrag)
        XCTAssertTrue(session.apply(.lightValue(id: id, field: .y, value: 3), from: generation))
        assertRejectedCallbacks(session, token: token, id: id, generation: generation)
        XCTAssertTrue(session.history.isEditing)
        XCTAssertTrue(session.apply(.lightValue(id: id, field: .y, value: 4), from: generation))
        let heightChanged = session.scene
        session.editChanged(false, owner: owner, from: generation)

        XCTAssertEqual(heightChanged.lights[0].position.x, dragged.lights[0].position.x)
        XCTAssertEqual(heightChanged.lights[0].position.y, 4)
        assertHistory(session, scenes: [original, dragged, heightChanged])
    }

    func testExistingProjectSaveRetiresCallbacksEvenWhenGenerationDoesNotChange() async throws {
        let session = try await loadedSession()
        try await session.beginLibraryOperation(.save, from: session.generation).value
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let dragged = session.scene
        let save = try session.beginLibraryOperation(.save, from: generation)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        let reserved = session.editor
        XCTAssertNil(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertEqual(session.editor, reserved)
        assertRejectedCallbacks(session, token: token, id: id, generation: generation)
        try await save.value
        XCTAssertEqual(session.generation, generation)
        XCTAssertEqual(session.saved, dragged)

        assertRejectedCallbacks(session, token: token, id: id, generation: generation)
        XCTAssertEqual(session.scene, session.saved, "A late final sample cannot dirty the just-saved scene")
        assertHistory(session, scenes: [original, dragged])
    }

    func testDiscreteHeightSurvivesLatePlanSampleAndCompleteUndoRedo() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let dragged = session.scene
        XCTAssertTrue(session.apply(.lightValue(id: id, field: .y, value: 4), from: generation))
        let heightChanged = session.scene
        XCTAssertEqual(heightChanged.lights[0].position.y, 4)
        XCTAssertNil(session.planDrag)
        XCTAssertFalse(session.history.isEditing)
        assertRejectedCallbacks(session, token: token, id: id, generation: generation, translation: 30)
        XCTAssertEqual(session.scene.lights[0].position.y, 4)

        let nextToken = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: nextToken, translationX: 30, translationZ: -10,
                                        scale: 100, from: generation))
        let movedAtNewHeight = session.scene
        XCTAssertEqual(movedAtNewHeight.lights[0].position.y, 4)
        XCTAssertEqual(movedAtNewHeight.lights[0].position.x,
                       heightChanged.lights[0].position.x + 0.3, accuracy: 1e-12)
        session.finishPlanDrag(token: nextToken, lightID: id, generation: generation)
        assertHistory(session, scenes: [original, dragged, heightChanged, movedAtNewHeight])
    }

    func testForeignSceneUpdateRetiresPlanAndRecordsSeparateUndoStep() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let dragged = session.scene
        var updated = dragged
        updated.subject.x += 0.4
        XCTAssertTrue(session.update(updated, from: generation))
        XCTAssertNil(session.planDrag)
        assertRejectedCallbacks(session, token: token, id: id, generation: generation)
        assertHistory(session, scenes: [original, dragged, updated])
    }

    func testInvalidAndNoOpForeignCommandsPreserveActivePlanAndRedo() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        var earlier = original
        earlier.lights[0].candela += 100
        XCTAssertTrue(session.replace(earlier, from: generation))
        XCTAssertTrue(session.undo(from: generation))
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let editing = session.editor
        let drag = session.planDrag
        XCTAssertTrue(session.history.canRedo)
        XCTAssertFalse(session.apply(.lightValue(id: id, field: .y, value: .nan), from: generation))
        XCTAssertFalse(session.apply(.lightValue(id: id, field: .y,
                                                 value: session.scene.lights[0].position.y), from: generation))
        XCTAssertFalse(session.apply(.lightValue(id: UUID(), field: .y, value: 4), from: generation))
        var invalid = session.scene
        invalid.subject.x = .nan
        XCTAssertFalse(session.update(invalid, from: generation))
        XCTAssertFalse(session.update(session.scene, from: generation))
        XCTAssertEqual(session.editor, editing)
        XCTAssertEqual(session.planDrag, drag)
        XCTAssertTrue(session.history.canRedo)
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 40, translationZ: 0,
                                        scale: 999, from: generation))
        XCTAssertEqual(session.scene.lights[0].position.x,
                       original.lights[0].position.x + 0.4, accuracy: 1e-12)
        let dragged = session.scene
        session.finishPlanDrag(token: token, lightID: id, generation: generation)
        XCTAssertFalse(session.history.canRedo)
        assertHistory(session, scenes: [original, dragged])
    }

    func testEditingEndsRetireOnlyTheirMatchingPlanOwner() async throws {
        for boundary in ["lifecycle", "owner", "control"] {
            let session = try await loadedSession()
            let original = session.scene
            let generation = session.generation
            let id = try XCTUnwrap(session.selection)
            let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
            let owner = try XCTUnwrap(session.planDrag?.owner)
            XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                            scale: 100, from: generation))
            let editing = session.editor
            let drag = session.planDrag
            session.endEditing(owner: "other control")
            XCTAssertEqual(session.editor, editing)
            XCTAssertEqual(session.planDrag, drag)
            switch boundary {
            case "lifecycle": session.endEditing()
            case "owner": session.endEditing(owner: owner)
            default: session.editChanged(false, owner: owner, from: generation)
            }
            XCTAssertNil(session.planDrag)
            XCTAssertFalse(session.history.isEditing)
            assertRejectedCallbacks(session, token: token, id: id, generation: generation)
            assertHistory(session, scenes: [original, editing.scene])
        }
    }

    func testSelectionRoundTripCannotReviveSameLightGesture() async throws {
        let session = try await loadedSession()
        let original = session.scene
        let generation = session.generation
        let id = try XCTUnwrap(session.selection)
        let token = try XCTUnwrap(session.beginPlanDrag(id, scale: 100, from: generation))
        XCTAssertTrue(session.dragLight(id, token: token, translationX: 20, translationZ: 0,
                                        scale: 100, from: generation))
        let dragged = session.scene
        XCTAssertTrue(session.select(original.lights[1].id, from: generation))
        XCTAssertTrue(session.select(id, from: generation))
        XCTAssertEqual(session.generation, generation)
        XCTAssertNil(session.planDrag)
        assertRejectedCallbacks(session, token: token, id: id, generation: generation)
        assertHistory(session, scenes: [original, dragged])
    }
}
