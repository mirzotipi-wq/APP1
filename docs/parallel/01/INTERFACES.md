# Composition contracts

These narrow contracts describe lane 01's composition seam. They do not change
the scene schema or grant ownership over another lane's feature algorithms.

Status: core contracts and the document session are implemented. Native feature
route admission is pending; these rules are not a claim that the current sheets
already use the new feature sessions.

## Scene invariants

`StudioEditorState` owns a validated `LightingScene`, selection, revision and
`SceneEditHistory`. All candidate changes validate before mutating any of them.
Supported schemas 1–5 migrate through `LightingScene.validated()`; identity,
SI values and the difference between absent optional defaults and stored values
remain intact. An invalid candidate changes neither history nor revision.

Selection follows a live light UUID. Removing the selected light falls back to
the first remaining light; an empty rig has no selection. Undoing a deletion
does not steal an existing valid selection. A continuous edit uses a stable
control owner; a late end from a different owner cannot close it. Ordinary
control identity must not include the per-change revision.

```swift
var editor = try StudioEditorState(scene: loadedScene)
editor.beginEditing(owner: controlID)
var candidate = editor.scene
candidate.lights[0].candela = 1200 // cd; geometry remains in meters
try editor.update(with: candidate)
editor.endEditing(owner: controlID)
editor.undo() // restores the complete pre-gesture scene
```

`replace(with:)` is a discrete command; `update(with:)` joins the current
continuous edit, or records a discrete change when none is active. Receipt
adoption uses the explicit `resettingHistory` policy. First save may establish a
new project identity without resetting history, selection or presentation mode.
A no-reset adoption must contain the same validated live scene; differing content
throws `StudioEditorState.AdoptionError.changesSceneWithoutReset` before mutation.

## Feature result identity

`StudioFeatureContext` contains a unique presentation ID, project generation,
scene revision and snapshot. Revisions are UUID identity tokens, not ordered
counters. Every actual scene mutation and undo/redo changes the token, so equal scene
content after undo does not revive an older asynchronous result.

`StudioFeatureSession.accepts` requires the active presentation owner, current
generation/revision, a presented session and no pending library operation.
`dismiss()` retires callbacks immediately. Consult the live parent-owned session,
not a captured value copy. Retiring does not release its stored scene; clear the
matching optional payload on teardown/reset, checking owner identity so an old
dismissal cannot clear a newer presentation. An adapter that accepts multiple room
or AR changes updates `acceptedRevision` only after its own successful validated
mutation. It must not advance that receipt after unrelated edits.

```swift
let context = StudioFeatureContext(generation: generation,
                                   revision: editor.revision, scene: editor.scene)
var feature = StudioFeatureSession(context: context)
if feature.accepts(context, generation: generation,
                   revision: editor.revision, isBusy: false) {
    try editor.replace(with: proposedScene)
    feature.didApply(revision: editor.revision)
}
feature.dismiss()
```

Reference/arrangement producers keep their current snapshot + callback API.
Room/AR keep synchronous Bool acceptance, enabling the feature to retain a draft
when the parent rejects it. Target-lux additionally checks the exact light UUID
and snapshot. No new upload, permission request or purchase is implied by opening
a route. Export consumes a captured validated scene and committed settings.

## Project work

Keep the existing `ProjectStore` actor and `ProjectLibraryOperationState` API.
Reserve synchronously before a task starts **and before changing current edit
state**. A stale/busy reservation is side-effect free. The parent session owns
the task; cancelling a sheet observer cannot abandon a committed receipt.
Never test cancellation after an atomic write to suppress its adoption.

Project-library callbacks remain synchronous throwing factories returning
`Task<Void, Error>`. A change operation requires the current scene to be saved.
Adoption uses request ID and generation and must never overwrite a newer scene
or clear another request's busy state. Metadata-only changes preserve undo;
switch/reload/recovery use their declared reset policies.

## Ownership and verification

Feature owners may call the adapter interfaces; they retain their own editing,
inference, rendering, AR, export and StoreKit implementations. Composition tests
must cover actual orchestration, not merely reconstruct the desired algorithm
in a test. Portable results do not establish Apple UI, AR or StoreKit behavior.
Contract revisions and exact tested inputs are recorded in this lane's handoff.

Room/AR callbacks report acceptance, not whether a mutation occurred. A valid
unchanged proposal returns true after admission, while the editor's mutation Bool
can be false. Selection-only changes and valid no-ops do not retire a scene
revision. Check, validate/apply and advance a receipt synchronously on the owner.
