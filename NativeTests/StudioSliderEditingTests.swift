import XCTest
import LightingCore
@testable import KeyAndFill

final class StudioSliderEditingTests: XCTestCase {
    /// The same validated binding used by the optics inspector: writes outside
    /// a continuous edit are discrete commands; the adapter must begin first.
    private final class Editor {
        var scene = LightingScene.portrait()
        var history = SceneEditHistory()

        init(width: Double = 0.6) {
            scene.lights[0].optics = .init(kind: .rectangle, widthMeters: width)
        }

        var width: Double { scene.lights[0].effectiveOptics.widthMeters }

        func writeWidth(_ width: Double) {
            var optics = scene.lights[0].effectiveOptics
            optics.widthMeters = width
            guard optics.isValid, optics != scene.lights[0].effectiveOptics else { return }
            if !history.isEditing { history.record(previous: scene) }
            scene.lights[0].optics = optics
        }

        func slider(owner: String = "draft.light-A.optics.emitterWidth") -> StudioSliderEditing {
            StudioSliderEditing(read: { self.width }, write: writeWidth) { editing in
                if editing { self.history.begin(scene: self.scene, owner: owner) }
                else { self.history.end(scene: self.scene, owner: owner) }
            }
        }
    }

    func testFirstValueBeforeBeginUndoesWholeWidthGestureAndKeepsEmitterCommand() throws {
        let editor = Editor()
        var point = editor.scene
        point.lights[0].optics?.kind = .point
        editor.history.record(previous: point) // The preceding emitter selection.
        let rectangle = editor.scene
        let slider = editor.slider()

        slider.setValue(0.8500000000000001) // The first write can precede begin.
        slider.onEditingChanged(true)
        slider.setValue(1.4)
        slider.setValue(2)
        slider.onEditingChanged(false)
        let edited = editor.scene

        XCTAssertFalse(editor.history.isEditing)
        let undone = try XCTUnwrap(editor.history.undo(current: edited))
        XCTAssertEqual(undone, rectangle, "One undo must restore the pre-drag 0.6 m, not an intermediate value")
        XCTAssertEqual(editor.history.undo(current: undone), point, "Emitter selection remains a separate command")
        XCTAssertNil(editor.history.undo(current: point))
        XCTAssertEqual(editor.history.redo(current: point), rectangle)
        XCTAssertEqual(editor.history.redo(current: rectangle), edited)
    }

    func testBeginBeforeFirstValueAndRepeatedBeginsPreserveOriginalScene() throws {
        let editor = Editor()
        let initial = editor.scene
        let slider = editor.slider()
        slider.onEditingChanged(true)
        slider.setValue(0.85)
        slider.onEditingChanged(true)
        slider.setValue(2)
        slider.onEditingChanged(false)
        let edited = editor.scene
        editor.scene = try XCTUnwrap(editor.history.undo(current: edited))
        XCTAssertEqual(editor.scene, initial)

        slider.onEditingChanged(true)
        slider.setValue(editor.width) // An unchanged gesture retains redo.
        slider.onEditingChanged(false)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.history.redo(current: initial), edited)
    }

    func testAccessibilityAdjustmentsFinishAndRemainSeparateAtBothBounds() throws {
        for (start, delta) in [(4.0, -0.05), (0.05, 0.05)] {
            let editor = Editor(width: start)
            let initial = editor.scene
            let slider = editor.slider()
            slider.adjust(by: -delta, in: 0.05...4) // Outward at the bound is a no-op.
            XCTAssertEqual(editor.scene, initial)
            XCTAssertFalse(editor.history.isEditing)
            XCTAssertFalse(editor.history.canUndo)

            slider.adjust(by: delta, in: 0.05...4)
            let first = editor.scene
            XCTAssertEqual(editor.width, start + delta)
            XCTAssertFalse(editor.history.isEditing, "Accessibility has no drag-end callback to await")
            slider.adjust(by: delta, in: 0.05...4)
            let second = editor.scene
            XCTAssertEqual(editor.width, start + delta + delta)
            XCTAssertFalse(editor.history.isEditing)
            XCTAssertEqual(editor.history.undo(current: second), first)
            XCTAssertEqual(editor.history.undo(current: first), initial)
            XCTAssertNil(editor.history.undo(current: initial))
            XCTAssertEqual(editor.history.redo(current: initial), first)
            XCTAssertEqual(editor.history.redo(current: first), second)
        }
    }

    func testAccessibilityRetainsOutOfQuickRangeCoordinatesWithoutReversingDirection() throws {
        for (start, inward) in [(80.123456789, -0.05), (-80.123456789, 0.05)] {
            var scene = LightingScene.portrait()
            scene.camera.x = start
            let initial = scene
            var history = SceneEditHistory()
            let slider = StudioSliderEditing(read: { scene.camera.x }, write: { next in
                if !history.isEditing { history.record(previous: scene) }
                scene.camera.x = next
            }, onEditingChanged: { editing in
                if editing { history.begin(scene: scene, owner: "draft.camera.x") }
                else { history.end(scene: scene, owner: "draft.camera.x") }
            })
            slider.adjust(by: -inward, in: -4...4)
            XCTAssertEqual(scene, initial, "An outward action at the retained endpoint must not jump backward into the usual range")
            XCTAssertFalse(history.isEditing)
            XCTAssertFalse(history.canUndo)
            slider.adjust(by: inward, in: -4...4)
            XCTAssertEqual(scene.camera.x, start + inward)
            XCTAssertFalse(history.isEditing)
            XCTAssertEqual(history.undo(current: scene), initial)
        }
    }

    func testCancellationAfterEarlyValueRestoresStartAndRetainsRedo() throws {
        let editor = Editor()
        let initial = editor.scene
        editor.writeWidth(2)
        let previousEdit = editor.scene
        editor.scene = try XCTUnwrap(editor.history.undo(current: previousEdit))
        let slider = editor.slider()
        slider.setValue(0.85)
        slider.onEditingChanged(true)
        slider.setValue(1.4)
        editor.scene = try XCTUnwrap(editor.history.cancel())
        slider.onEditingChanged(false)
        XCTAssertEqual(editor.scene, initial)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.history.redo(current: initial), previousEdit)
    }

    func testLateOtherOwnerEndDoesNotSplitEditBegunByFirstValue() throws {
        let editor = Editor()
        let initial = editor.scene
        let old = editor.slider(owner: "project-A.light.width")
        old.setValue(0.85)
        editor.history.end(scene: editor.scene) // Save or selection force-close.
        let first = editor.scene
        let next = editor.slider(owner: "project-A.other-light.width")
        next.setValue(1.2) // B begins before its native begin callback.
        old.onEditingChanged(false)
        XCTAssertTrue(editor.history.isEditing)
        next.onEditingChanged(true)
        next.setValue(2)
        next.onEditingChanged(false)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.history.undo(current: editor.scene), first)
        XCTAssertEqual(editor.history.undo(current: first), initial)
    }

    func testPrecisionCommandAfterGestureRemainsSeparateAndKeepsExactValue() throws {
        let editor = Editor()
        let initial = editor.scene
        let slider = editor.slider()
        slider.setValue(0.85)
        slider.onEditingChanged(true)
        slider.setValue(2)
        slider.onEditingChanged(false)
        let dragged = editor.scene
        editor.writeWidth(0.723456789) // The precision field uses its original binding.
        let typed = editor.scene
        XCTAssertEqual(editor.width, 0.723456789)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.history.undo(current: typed), dragged)
        XCTAssertEqual(editor.history.undo(current: dragged), initial)
        XCTAssertEqual(editor.history.redo(current: initial), dragged)
        XCTAssertEqual(editor.history.redo(current: dragged), typed)
    }

    func testInvalidAndUnchangedValuesDoNotOpenAnEditOrDiscardRedo() throws {
        let editor = Editor()
        let initial = editor.scene
        editor.writeWidth(2)
        let edited = editor.scene
        editor.scene = try XCTUnwrap(editor.history.undo(current: edited))
        let slider = editor.slider()
        for value in [Double.nan, .infinity, -.infinity, editor.width] { slider.setValue(value) }
        slider.adjust(by: .nan, in: 0.05...4)
        slider.adjust(by: 0, in: 0.05...4)
        XCTAssertEqual(editor.scene, initial)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.history.redo(current: initial), edited)
    }
}
