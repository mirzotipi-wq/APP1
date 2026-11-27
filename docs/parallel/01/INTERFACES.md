# Composition contracts

These narrow contracts describe lane 01's composition seam. They do not change
the scene schema or grant ownership over another lane's feature algorithms.

Status: core contracts, the document session and native feature-host wiring are
implemented. Portable orchestration is tested; native Observation and sheet
behavior still require Apple runtime validation.

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
try editor.apply(.lightValue(id: lightID, field: .candela, value: 1200))
// cd; geometry remains in meters and UUIDs are not editable fields.
editor.endEditing(owner: controlID)
editor.undo() // restores the complete pre-gesture scene
```

`replace(with:)` is a discrete command; `update(with:)` joins the current
continuous edit, or records a discrete change when none is active. Receipt
adoption uses the explicit `resettingHistory` policy. First save may establish a
new project identity without resetting history, selection or presentation mode.
A no-reset adoption must contain the same validated live scene; differing content
throws `StudioEditorState.AdoptionError.changesSceneWithoutReset` before mutation.

`StudioFieldCommand` is the closed control interface for light scalars/position/
optics, camera and subject position, lens, preview and room. Each command validates
its complete changed payload and resolves a live light UUID before committing.
It cannot change names, UUIDs, schema or light count. Full candidate validation
still runs for arbitrary scene updates, replacement and receipt adoption. A
rejected command preserves revision, selection, redo and any open edit owner.
Valid effective no-ops preserve optional default representation, including nil
versus zero optical roll. A manual aim at the subject remains distinct from
automatic nil aim. Room validation includes coupled dimensions and ceiling.

Native controls call `session.apply(command, from: capturedGeneration)`. Admission
requires a loaded, writable, idle session and the current storage generation.
The Bool means a scene mutation occurred; feature adapters must independently
report accepted valid no-ops. Typed mutation avoids scanning unchanged imported
names and complete lights. Equality, history normalization, array copying and
preview rendering still have costs; no measured UI performance claim is made.

## Feature result identity

`StudioFeatureContext` contains a unique presentation ID, logical document generation,
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
// StudioSession is the live per-window parent. Capture the context for work.
guard let context = session.openFeature(.room, from: session.generation) else { return }
let accepted = session.applyFeatureRoom(measuredRoom, from: context)
// Keep the feature draft when accepted == false; valid unchanged rooms are true.
session.retireFeature(context) // synchronously rejects any later callbacks
session.finishFeature(context) // matching teardown releases the payload
```

`StudioFeaturePresentation` combines destination and receipt. `StudioSession`
owns one active presentation, rejects replacement while it is presented, and
permits a new owner after retirement. An old teardown cannot clear the new owner.
The logical generation is `workspaceResetID`; storage generation still fences
project/control callbacks. First save preserves the feature; successful document
switch/reload/recovery clears it. Healthy repeated initial load is rejected before
reservation, while failed initial-load retry remains allowed.

Scene and target-lux results are one-shot: successful validation retires their
callbacks immediately, even for accepted no-ops. Lux may change only the captured
light's candela, retaining its exact UUID and other fields. Room/AR results may
repeat and share an owner undo group. A valid unrelated command closes that group
before making its own change; invalid/no-op commands preserve it. Accepted changed
feature results also clear any frozen Plan origin, including a zero-motion drag
that did not advance the revision. No-op results retain that still-valid origin.
These session policies are wired through `StudioFeatureSheets`. Its owner-keyed
Boolean sheet binding retires immediately on dismissal and clears only the
matching payload on teardown. Root `onDisappear` does not retire features because
modal/adaptive coverage can also trigger it.

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

## Control and gesture lifetime

`StudioSession.editOwner` derives ordinary control identity from the document's
workspace reset token and the stable field/light identifier. First save and scene
revisions do not remount controls. Project switch/reload does; mutation callbacks
still capture and check their own storage generation. Plan translation is
cumulative against a session-owned frozen scene/scale. Reservation failure leaves
that state and its undo group intact; accepted reservation closes them together.

Reference's current Void Apply callback consumes its local session before parent
admission. A future owner-provided acceptance callback must preserve the draft on
rejection. Until available, native reference draft preservation remains a stated
integration limitation, distinct from scene-result rejection.

## Native composition and preview lifetime

`StudioView` opens features through actions that capture storage generation when
rendered. The session reserves the presentation only after admission. The shared
host sends immutable opening snapshots to reference/arrangement/lux, and live
scene values to room/AR so their own accepted changes remain visible. Nested
manual-room closure stays within AR's local owner; it does not retire outer AR.

Both Study and 3D wrappers use `workspaceResetID` for identity. The 3D selection
callback independently checks its captured storage generation and live light UUID.
First save does not remount a preview; intentional document reset changes identity.
That satisfies the published lane05 composition request at source level; orbit,
focus, Observation and camera/controller retention still need native execution.

The current three Void producers can consume rejected drafts. The host's rejection
message is scoped to the current active owner and does not claim retention.
[FEATURE_ADAPTERS.md](FEATURE_ADAPTERS.md) records exact current signatures and
future explicitly labeled Bool callbacks with acceptance before cleanup. No
producer implementation was changed by this lane.
