import XCTest
@testable import LightingCore

final class SceneEditHistoryTests: XCTestCase {
    private let initial = LightingScene.portrait()

    private func scene(_ exposure: Double) -> LightingScene {
        var result = initial
        result.previewSettings = .init(whiteBalanceKelvin: 5600, exposureStops: exposure)
        return result
    }

    func testContinuousChangesMakeOneUndoEntryAndRepeatedBeginKeepsOriginal() {
        let a = scene(0), b = scene(1), c = scene(2)
        var history = SceneEditHistory()
        history.begin(scene: a)
        history.begin(scene: b)
        XCTAssertTrue(history.isEditing)
        history.end(scene: c)
        XCTAssertFalse(history.isEditing)
        XCTAssertEqual(history.undo(current: c), a)
        XCTAssertNil(history.undo(current: a))
        XCTAssertEqual(history.redo(current: a), c)
        XCTAssertFalse(history.canRedo)
    }

    func testUnchangedAndCancelledGesturesPreserveRedo() {
        let a = scene(0), b = scene(1), c = scene(2)
        var history = SceneEditHistory()
        history.record(previous: a)
        XCTAssertEqual(history.undo(current: b), a)
        history.begin(scene: a)
        history.end(scene: a)
        XCTAssertFalse(history.canUndo)
        XCTAssertTrue(history.canRedo)
        history.begin(scene: a)
        // A caller may have displayed c; cancellation explicitly restores a.
        XCTAssertEqual(history.cancel(), a)
        history.end(scene: c) // Late callback cannot commit the cancelled edit.
        XCTAssertFalse(history.canUndo)
        XCTAssertTrue(history.canRedo)
        XCTAssertEqual(history.redo(current: a), b)
        XCTAssertNil(history.cancel())
    }

    func testUndoDuringGestureAndLateEndDoNotDestroyRedo() {
        let a = scene(0), b = scene(1), c = scene(2)
        var history = SceneEditHistory()
        history.record(previous: a)
        history.begin(scene: b)
        XCTAssertEqual(history.undo(current: c), b)
        XCTAssertFalse(history.isEditing)
        history.end(scene: b)
        XCTAssertTrue(history.canRedo)
        XCTAssertEqual(history.redo(current: b), c)
        XCTAssertEqual(history.undo(current: c), b)
        XCTAssertEqual(history.undo(current: b), a)
    }

    func testUndoDuringFirstGestureWorksWithoutPriorCommands() {
        let a = scene(0), b = scene(1)
        var history = SceneEditHistory()
        history.begin(scene: a)
        XCTAssertTrue(history.canUndo)
        XCTAssertEqual(history.undo(current: b), a)
        XCTAssertEqual(history.redo(current: a), b)
    }

    func testRedoClosesGestureAndDropsOldBranchOnlyIfSceneChanged() {
        let a = scene(0), b = scene(1), c = scene(2)
        var history = SceneEditHistory()
        history.record(previous: a)
        XCTAssertEqual(history.undo(current: b), a)
        history.begin(scene: a)
        XCTAssertEqual(history.redo(current: a), b)
        XCTAssertFalse(history.isEditing)
        XCTAssertEqual(history.undo(current: b), a)
        history.begin(scene: a)
        XCTAssertNil(history.redo(current: c))
        XCTAssertFalse(history.isEditing)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.undo(current: c), a)
        XCTAssertEqual(history.redo(current: a), c)
    }

    func testDiscreteCommandDuringGesturePreservesBothUndoSteps() {
        let a = scene(0), b = scene(1), c = scene(2), d = scene(3)
        var history = SceneEditHistory()
        history.record(previous: a)
        history.begin(scene: b)
        history.record(previous: c) // Separate command changes c to d.
        history.end(scene: d)
        XCTAssertEqual(history.undo(current: d), c)
        XCTAssertEqual(history.undo(current: c), b)
        XCTAssertEqual(history.undo(current: b), a)
        XCTAssertEqual(history.redo(current: a), b)
        XCTAssertEqual(history.redo(current: b), c)
        XCTAssertEqual(history.redo(current: c), d)
    }

    func testHistoryRetainsOnlySixtyNewestEntriesAndSupportsSmallerLimits() {
        var history = SceneEditHistory(limit: .max)
        // Use a valid coordinate for a long sequence without exceeding exposure bounds.
        func positioned(_ x: Int) -> LightingScene {
            var result = initial
            result.camera.x = Double(x)
            return result
        }
        for index in 0..<75 { history.record(previous: positioned(index)) }
        var current = positioned(75)
        for expected in stride(from: 74, through: 15, by: -1) {
            let previous = history.undo(current: current)
            XCTAssertEqual(previous, positioned(expected))
            current = previous ?? current
        }
        XCTAssertNil(history.undo(current: current))
        for expected in 16...75 {
            let next = history.redo(current: current)
            XCTAssertEqual(next, positioned(expected))
            current = next ?? current
        }
        XCTAssertNil(history.redo(current: current))

        var small = SceneEditHistory(limit: 2)
        for index in 0..<4 { small.record(previous: positioned(index)) }
        XCTAssertEqual(small.undo(current: positioned(4)), positioned(3))
        XCTAssertEqual(small.undo(current: positioned(3)), positioned(2))
        XCTAssertNil(small.undo(current: positioned(2)))
    }

    func testResetClearsBothDirectionsAndPendingTransaction() {
        let a = scene(0), b = scene(1)
        var history = SceneEditHistory()
        history.record(previous: a)
        _ = history.undo(current: b)
        history.begin(scene: a)
        history.reset()
        XCTAssertFalse(history.isEditing)
        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)
        history.end(scene: b)
        XCTAssertNil(history.undo(current: b))
        XCTAssertNil(history.redo(current: a))
    }

    func testLateEndFromAnotherControlDoesNotCloseNewGesture() {
        let a = scene(0), b = scene(1), c = scene(2), d = scene(3)
        var history = SceneEditHistory()
        history.begin(scene: a, owner: "light-A.intensity")
        history.end(scene: b) // Save or selection change closes A explicitly.
        history.begin(scene: b, owner: "camera.focalLength")
        history.end(scene: c, owner: "light-A.intensity") // A's delayed end.
        XCTAssertTrue(history.isEditing, "A delayed end must not close another control's edit")
        // Model the binding's real fallback for changes outside a transaction.
        if !history.isEditing { history.record(previous: c) }
        history.end(scene: d, owner: "camera.focalLength")
        XCTAssertEqual(history.undo(current: d), b, "B should remain one complete undo step")
        XCTAssertEqual(history.undo(current: b), a)
        XCTAssertNil(history.undo(current: a))
    }

    func testDifferentLightOwnersCommitSeparateStepsWithoutExplicitClose() {
        let a = scene(0), b = scene(1), c = scene(2), d = scene(3)
        var history = SceneEditHistory()
        history.begin(scene: a, owner: "light-A.width")
        history.begin(scene: b, owner: "light-B.width")
        history.end(scene: c, owner: "light-A.width")
        XCTAssertTrue(history.isEditing)
        history.end(scene: d, owner: "light-B.width")
        XCTAssertEqual(history.undo(current: d), b)
        XCTAssertEqual(history.undo(current: b), a)
        XCTAssertNil(history.undo(current: a))
        XCTAssertEqual(history.redo(current: a), b)
        XCTAssertEqual(history.redo(current: b), d)
    }

    func testRepeatedBeginFromSameOwnerKeepsTheOriginalScene() {
        let a = scene(0), b = scene(1), c = scene(2)
        var history = SceneEditHistory()
        history.begin(scene: a, owner: "preview.exposure")
        history.begin(scene: b, owner: "preview.exposure")
        history.end(scene: c, owner: "preview.exposure")
        XCTAssertEqual(history.undo(current: c), a)
        XCTAssertNil(history.undo(current: a))
        XCTAssertEqual(history.redo(current: a), c)
    }

    func testPreviousProjectEndCannotCloseSameLightFieldInAnotherProject() {
        let old = scene(0), opened = scene(2), changed = scene(3)
        var history = SceneEditHistory()
        history.begin(scene: old, owner: "project-A.shared-light.width")
        history.reset() // Switching projects must remove the old undo graph.
        history.begin(scene: opened, owner: "project-B.shared-light.width")
        history.end(scene: changed, owner: "project-A.shared-light.width")
        XCTAssertTrue(history.isEditing)
        history.end(scene: changed, owner: "project-B.shared-light.width")
        XCTAssertEqual(history.undo(current: changed), opened)
        XCTAssertNil(history.undo(current: opened))
        XCTAssertEqual(history.redo(current: opened), changed)
    }

    func testUnmatchedEndPreservesNewOwnerRollbackAndRedo() {
        let a = scene(0), b = scene(1), c = scene(2)
        var history = SceneEditHistory()
        history.record(previous: a)
        XCTAssertEqual(history.undo(current: b), a)
        history.begin(scene: a, owner: "old")
        history.end(scene: a) // Unchanged forced close keeps the redo branch.
        history.begin(scene: a, owner: "new")
        history.end(scene: c, owner: "old")
        XCTAssertTrue(history.isEditing)
        XCTAssertTrue(history.canRedo)
        XCTAssertEqual(history.cancel(), a)
        history.end(scene: c, owner: "new") // End after rollback cannot commit.
        XCTAssertEqual(history.redo(current: a), b)
        history.begin(scene: b, owner: "new")
        history.reset()
        XCTAssertEqual(history, SceneEditHistory())
        history.end(scene: c, owner: "new")
        XCTAssertNil(history.undo(current: c))
    }

    func testOwnedAndLegacyEditsKeepExplicitForceCloseSemantics() {
        let a = scene(0), b = scene(1), c = scene(2), d = scene(3)
        var history = SceneEditHistory()
        history.begin(scene: a)
        history.begin(scene: b, owner: "camera")
        history.begin(scene: c) // Legacy owner is distinct from camera.
        history.end(scene: d, owner: "camera")
        XCTAssertTrue(history.isEditing)
        history.end(scene: d) // Explicitly closes the legacy edit.
        XCTAssertFalse(history.isEditing)
        XCTAssertEqual(history.undo(current: d), c)
        XCTAssertEqual(history.undo(current: c), b)
        XCTAssertEqual(history.undo(current: b), a)
        XCTAssertNil(history.undo(current: a))
    }

    func testOwnerChangesRespectHistoryLimitAndLateEndsKeepRedo() {
        let a = scene(0), b = scene(1), c = scene(2), d = scene(3), e = scene(4)
        var history = SceneEditHistory(limit: 2)
        history.begin(scene: a, owner: "first")
        history.begin(scene: b, owner: "second")
        history.begin(scene: c, owner: "third")
        history.begin(scene: d, owner: "fourth")
        history.end(scene: e)
        XCTAssertEqual(history.undo(current: e), d)
        XCTAssertEqual(history.undo(current: d), c)
        XCTAssertNil(history.undo(current: c))
        history.end(scene: c, owner: "first")
        history.end(scene: c, owner: "fourth")
        XCTAssertEqual(history.redo(current: c), d)
        XCTAssertEqual(history.redo(current: d), e)
    }
}
