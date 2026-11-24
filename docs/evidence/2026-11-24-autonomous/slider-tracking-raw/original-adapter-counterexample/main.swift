import Foundation

final class Editor {
    var scene = LightingScene.portrait()
    var history = SceneEditHistory()
    init() {
        scene.lights[0].optics = .init(kind: .rectangle, widthMeters: 0.6)
        var point = scene
        point.lights[0].optics?.kind = .point
        history.record(previous: point)
    }
    var width: Double { scene.lights[0].effectiveOptics.widthMeters }
    var undoEnabled: Bool { history.canUndo && !history.isEditing }
    func write(_ width: Double) {
        var optics = scene.lights[0].effectiveOptics
        optics.widthMeters = width
        guard optics.isValid, optics != scene.lights[0].effectiveOptics else { return }
        if !history.isEditing { history.record(previous: scene) }
        scene.lights[0].optics = optics
    }
    func slider() -> StudioSliderEditing {
        StudioSliderEditing(read: { self.width }, write: write) { editing in
            if editing { self.history.begin(scene: self.scene, owner: "draft.light.optics.emitterWidth") }
            else { self.history.end(scene: self.scene, owner: "draft.light.optics.emitterWidth") }
        }
    }
    func tapUndoIfEnabled() {
        guard undoEnabled, let previous = history.undo(current: scene) else { return }
        scene = previous
    }
}

print("Counterexamples exercise the real unmodified StudioSliderEditing and SceneEditHistory sources.")
print("These are controlled callback sequences, not a trace of the native failing run.")

let reopened = Editor(), a = reopened.slider()
a.onEditingChanged(true)
a.setValue(1.85)
a.onEditingChanged(false)
a.setValue(1.3)
print("end-before-last-write: width=\(reopened.width) isEditing=\(reopened.history.isEditing) canUndo=\(reopened.history.canUndo) canRedo=\(reopened.history.canRedo) undoEnabled=\(reopened.undoEnabled)")
precondition(reopened.width == 1.3 && reopened.history.isEditing && !reopened.undoEnabled)
reopened.tapUndoIfEnabled()
print("disabled-Undo action: width=\(reopened.width) (unchanged)")
precondition(reopened.width == 1.3)
let bypass = reopened.history.undo(current: reopened.scene)!
print("bypassing disabled UI would restore width=\(bypass.lights[0].effectiveOptics.widthMeters), not the initial 0.6")
precondition(bypass.lights[0].effectiveOptics.widthMeters == 1.85)

let split = Editor(), b = split.slider()
b.onEditingChanged(true)
b.setValue(1.3)
b.onEditingChanged(false)
b.setValue(2)
b.onEditingChanged(false)
print("end-between-writes plus final-end: width=\(split.width) isEditing=\(split.history.isEditing) undoEnabled=\(split.undoEnabled)")
precondition(split.undoEnabled)
split.tapUndoIfEnabled()
print("split-history Undo: width=\(split.width)")
precondition(split.width == 1.3)

let ordered = Editor(), c = ordered.slider()
let start = ordered.scene
c.onEditingChanged(true)
c.setValue(1.85)
c.setValue(1.3)
c.onEditingChanged(false)
let final = ordered.scene
print("final-write-before-end: width=\(ordered.width) isEditing=\(ordered.history.isEditing) undoEnabled=\(ordered.undoEnabled)")
precondition(ordered.undoEnabled)
ordered.tapUndoIfEnabled()
print("ordered Undo: width=\(ordered.width)")
precondition(ordered.scene == start)
ordered.scene = ordered.history.redo(current: ordered.scene)!
print("ordered Redo: width=\(ordered.width)")
precondition(ordered.scene == final)
print("All counterexample and ordered-control assertions verified.")
