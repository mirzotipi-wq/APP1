# Studio navigation and feature ownership

## Source and scope

This map was reviewed against `08e80c756cb7c8aa4eaf11f27932c8f701000be1`.
That source includes the Studio tools admission change (`5decbb0`) and
`StudioSmokeTests.testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable`
(`08e80c7`). The regression is a method in the existing `StudioSmokeTests` class;
there is no new navigation test class. This document changes no implementation,
test, CI configuration or canonical milestone state. Root owns integration and
publication. Native behavior remains unverified at this reviewed revision.

The callers below are the existing source paths. Product workflow descriptions
do not establish additional navigation routes. See [INTERFACES.md](INTERFACES.md)
for mutation contracts and [FEATURE_ADAPTERS.md](FEATURE_ADAPTERS.md) for current
producer signatures and the explicitly unimplemented acceptance proposal.

## Existing entry points

| Entry and caller | Destination and input | Completion and close |
|---|---|---|
| `StudioView.workflowActions`: **Reference photo**, `openReference` | `featureAction(.reference)` reserves a session presentation; `StudioFeatureSheets` constructs `ReferenceComparisonView(scene: context.scene, onApply:)` from its opening snapshot. | Confirmed **Apply rig** calls `applyFeatureScene`; only acceptance switches Studio to Study. Reference **Done**, `closeReference`, closes its local session. Host dismissal retires/releases its matching receipt. The current Void limitation is below. |
| Reference: **Compare a test shot**, `openPhotoComparison` | Reference's local `showPhotoComparison` sheet constructs `PhotoComparisonView(initialReference: reference)`; the optional seed is the reduced image already open in Reference. This child has no scene-result callback or separate Studio feature receipt. | **Done**, `closePhotoComparison`, clears only the comparison session and dismisses the child. Parent observations and selected rig are intended to remain available. |
| `StudioView.workflowActions`: **Room placement**, `openRoomPlacement` | `featureAction(.room)`; host constructs `ManualRoomPlacementView` from live `session.scene`. `onChange` and `onRemove` call `applyFeatureRoom(room/nil, from: context)`. | Valid committed field changes and **Keep room with setup** submit synchronously; accepted changes remain open. Confirmed removal submits `nil`. **Done**, `closeRoomPlacement`, calls the matching `onClose` before dismissal. Closing does not undo accepted room edits or save the project. |
| Manual room: **Review and share notes**, `reviewRoomNotes` | Local item sheet captures `plan.textSummary(locale:)` into immutable `notesSnapshot.text`; `RoomPlacementNotesView` displays and shares that same text in meters. It uses committed local measurement values, excluding unfinished field text. | **Done**, `closeRoomNotes`, dismisses notes only. `shareRoomNotes` invokes system sharing explicitly. No scene mutation or outer feature retirement occurs. |
| Studio tools, `studioTools`: **Place in AR** | `featureAction(.ar)`; host constructs `ARPlacementView` from live `session.scene`, forwarding room change/removal Bools. AR creates its `StateObject` controller from the initial scene. | Outer **Done**, `closeARPlacement`, calls matching `onClose`, then `controller.disappeared()`, then dismisses. Camera activation is a separate **Start AR camera**, `startARCamera`, action. |
| AR: **Use manual room measurements**, `arManualMeasurements` | Stops the AR controller, allocates `manualOwner`, then presents `ManualRoomPlacementView(scene: scene)` under AR's local Boolean binding. Forwarded changes/removals require `showingManual` and the captured owner to match. | Nested manual **Done** clears only that owner's `showingManual`; matching teardown clears `manualOwner`. It does not call outer AR `onClose`. The Studio AR receipt remains available for later room edits. |
| Studio tools: **Arrange setup** | `featureAction(.arrangement)`; host constructs `SceneArrangementView(scene: context.scene, onApply:)`. Destination, yaw and mirror are local proposals against the opening snapshot. | **Apply arrangement**, `applyArrangement`, computes a whole-scene proposal for `applyFeatureScene`. **Cancel**, `cancelArrangement`, marks the local view finished and dismisses without applying. |
| Selected light inspector, `lightActions`: **Set ideal lux** | A generation-captured `sceneAction` first checks the captured light is still present with its captured value, then opens `.targetLux(lightID:)`. Host resolves that UUID from `context.scene` and supplies both captured light and scene to `LightTargetLuxView`. | **Apply to light**, `applyTargetLux`, submits to `applyFeatureLight`. Only the captured light's candela may change; its UUID and all other fields must match. Navigation **Cancel** dismisses; keyboard **Done** only ends field focus. |
| Studio tools: **Subject position**; Plan subject marker, `editSubject` | Both set `showSubject`; the sheet contains `SubjectInspector(position: subjectPositionBinding, onEditingChanged:)`. This is a live typed binding, not a `StudioFeaturePresentation`. | Binding writes use `.subjectPosition` and a captured storage generation; editing uses the stable subject control owner. **Done** clears `showSubject`. Changes already accepted remain undoable; there is no deferred Apply or automatic save. |
| Studio header: export button, `exportLightingPlan` | `LightingPlanExportMenu` captures current scene, project name and optional generated text into a UUID-keyed `LightingPlanExportSnapshot`. One sheet starts at formats; `prepareLightingPlanPDF` replaces its content with `LightingPlanExportView`; `prepareEditableProjectCopy` selects `ProjectBackupView`. **Share text settings** shares the captured text. | Formats **Cancel**, `closeLightingPlanExportFormats`; PDF **Done**, `closeLightingPlanPDF`; copy **Done**, `closeEditableProjectCopy`, dismiss the export sheet. There is no Studio mutation receipt and no save prerequisite. Reopening takes a new snapshot. |
| Studio tools: **Settings** → Settings **Purchase options** / **Lifetime purchase**, `openPurchaseOptions` | `StudioView.showSettings` presents `StudioSettingsView(store: entitlements)`; its local `showPurchase` sheet presents `ProFeaturesView(store: store)`. The shared store is owned by `KeyAndFillApp`. | Pro **Done**, `closeProFeatures`, returns to Settings; Settings **Done** returns to Studio. Opening either sheet does not invoke purchase, restore or refresh. Pro exposes explicit guarded action buttons; current feature availability is not gated by this view. |

Caller and presentation sources: [StudioView](../../../App/StudioView.swift),
[StudioFeatureSheets](../../../App/StudioFeatureSheets.swift),
[ReferenceComparisonView](../../../App/ReferenceComparisonView.swift),
[PhotoComparisonView](../../../App/PhotoComparisonView.swift),
[ManualRoomPlacementView](../../../App/ManualRoomPlacementView.swift),
[ARPlacementView](../../../App/ARPlacementView.swift),
[SceneArrangementView](../../../App/SceneArrangementView.swift),
[LightTargetLuxView](../../../App/LightTargetLuxView.swift),
[LightingPlanExportView](../../../App/LightingPlanExportView.swift),
[ProjectBackupView](../../../App/ProjectBackupView.swift),
[StudioSettingsView](../../../App/StudioSettingsView.swift) and
[ProFeaturesView](../../../App/ProFeaturesView.swift).

## Admission, receipt and pending-work policy

### Scene features and document operations

[StudioSession](../../../App/StudioSession.swift) owns one active feature.
Opening requires a loaded, writable, idle session, current storage generation,
no currently presented feature, and a live target UUID for lux. Rejection leaves
the current edit/Plan gesture intact; successful admission finishes them before
capturing the context. `featureAction` captures storage generation when the
action is rendered, so a queued tap cannot open against a switched document.

The context contains presentation ID, `workspaceResetID`, scene revision and
opening scene. Results consult the live parent owner and accepted revision;
undoing to equal content does not revive an older result. Reference/arrangement
and lux accept valid unchanged proposals, then retire their receipt exactly once.
Room/AR can accept multiple changes and advance their own receipt, grouping
accepted measurements into one owner edit. A valid unchanged room returns true
without changing history. Unrelated changed commands separate the undo group;
invalid/no-op commands do not. These acceptance Bools differ from ordinary
editor mutation Bools.

The host disables its destination while `session.isBusy`. Its owner-keyed sheet
binding retires callbacks synchronously on a false write and ignores true writes;
`onDismiss` releases only the matching payload. Old teardown cannot close a new
feature. Root disappearance ends ordinary editing/Plan gestures, but does not
retire the feature because modal coverage can also hide Studio.

Project operations reserve synchronously before ending edits and before launching
the session-owned task. Pending work rejects mutation and competing reservation.
Cancelling a sheet observer cannot abandon a committed storage receipt. First
save can change storage generation while preserving logical feature identity;
successful document switch/reload/recovery resets it and clears the feature.
Failed save/reload/recovery retains the open feature. These are orchestration
contracts, not proof of native sheet or window behavior.

### Protected storage and utility navigation

At this source, `studioTools` is disabled only while `editHistory.isEditing`.
Its Subject/Arrange/AR items separately disable when not loaded, save-blocked or
busy. Subject additionally guards live mutation admission and edit state in its
action. Settings has no storage/busy disable. The Plan subject marker sets its
local sheet flag directly; scene bindings still enforce mutation admission.

When saved data is protected, the scene workspace is replaced by the unavailable
panel. Save, Projects, export and Recipes remain disabled. Reference and room
workflow controls are absent with the workspace. Settings and its privacy text
and purchase navigation remain reachable through the menu. This utility access
does not authorize scene changes or storage replacement. Active continuous-edit
menu protection remains in place.

### Work owned by child features

- **Reference/comparison:** import and analysis requests carry cancellation tokens.
  Closing Reference cancels its work and clears its photo, tones, observations,
  candidates and selection. Cancelling a replacement import keeps the previous
  photo and guided work. Comparison has independent photo slots; clearing/closing
  cancels their imports and releases their images. Both use
  `ComparisonSessionDismissalObserver` to distinguish completed dismissal from
  nested picker/sheet coverage; actual interactive UIKit behavior needs execution.
- **Room/AR:** manual room retains displayed measurements and its prior `keptRoom`
  when a Bool callback rejects, and sets `roomCommitRejected`. Removal changes
  `keptRoom` only after acceptance; neither removal nor Keep closes the editor.
  Room notes can describe the local committed layout without proving the parent
  accepted it. AR responds to scene phase/disappearance through its controller;
  opening its manual fallback stops camera work. Nested owner checks reject late
  callbacks without retiring outer AR.
- **Export:** opening captures unsaved accepted scene edits, including committed
  scene room measurements, but excludes unfinished control text, photographs and
  undo history. PDF preparation is keyed by paper/units/retry and checks cancellation
  plus current options before publishing results. PDF units initialize from Studio
  preferences and then remain local. Editable-copy preparation cancels its detached
  worker with the view task and preserves an already prepared immutable document.
  Preparation does not claim a file was saved: only a successful system exporter
  completion produces that message. System sharing/export requires a further tap.
- **Purchase:** the app-owned [EntitlementStore](../../../App/EntitlementStore.swift)
  survives Pro dismissal. Explicit actions reserve before launching a task and
  obey configuration/busy/pending guards. Done remains available while a purchase
  is pending; closing the sheet does not cancel transaction updates. Verified
  transaction handling uses a finite task that publishes entitlement before
  finishing the transaction. An absent/unexpanded product ID disables sales;
  prices come from StoreKit. Navigation evidence establishes none of these
  transaction outcomes.

## Unchanged Void producer limitation

The three current producers do not return parent acceptance:

| Producer | Actual local order on Apply |
|---|---|
| Reference | `closeSession()` clears the photo/candidates and cancels work **before** `onApply(rig.scene)`, then dismisses. |
| Arrangement | Calculates the proposal, sets `didFinish = true`, invokes Void `onApply(next)`, then dismisses. |
| Target lux | Calculates the adjusted light, sets `didApply = true`, invokes Void `onApply(adjusted)`, then dismisses. |

The host can reject stale or invalid scene/light mutation, but cannot restore
these consumed drafts through the existing API. Its owner-matched message asks
the user to reopen and does not promise retention. Busy disabling and portable
receipt tests do not repair this boundary. The synchronous `onAccept: (...) -> Bool`
examples in [FEATURE_ADAPTERS.md](FEATURE_ADAPTERS.md) are future owner work;
none is an implemented route or callback in this revision.

## Existing test mapping

These are source inventories, not claims that UI methods ran at this revision.

| Existing file/class | Exact method and covered route |
|---|---|
| [ReferenceComparisonUITests](../../../UITests/ReferenceComparisonUITests.swift) | `testReferenceComparisonOpensWithRealStudyAndNoPhoto`: empty Reference open/close/reopen. `testGuidedRigAbstainsThenAppliesAndUndoesWithoutSaving`: manual guided choice; nested comparison open/close preserves observations and selected rig; confirmed Apply and Undo. Neither imports an actual photo. |
| [ManualRoomPlacementUITests](../../../UITests/ManualRoomPlacementUITests.swift) | `testManualRoomReportsOutOfBoundsAndRecordsRoomEdit`: primary room route, rotation status, close and undo availability. `testRoomResizeRequiresExplicitSubjectMoveAndPreservesSignedCoordinates`: committed fields, signed notes snapshots, notes close/reopen and parent room continuity. |
| [PrecisionEditingUITests](../../../UITests/PrecisionEditingUITests.swift) | `testExactModifierWidthAndRoomCrossingWithInsideCenters`: exact modifier edit and room footprint/status route. |
| [StudioSmokeTests](../../../UITests/StudioSmokeTests.swift) | `testSettingsFeet3DFitAndSimulatorARManualFallback` (simulator only): Settings units/reopen, 3D Fit, unsupported AR with no camera, nested manual room close back to AR, outer close, arrangement presentation and Cancel preserving 3D mode. It does not apply an arrangement or start a camera. |
| Same existing `StudioSmokeTests` class | `testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable`: UUID-scoped corrupt fixture, explicit English locale, completed protected status; Save/Projects/export/Recipes disabled; scene/reference absent; Subject/Arrange/AR disabled; Settings → actual Pro → existing Settings → protected Studio; relaunch without recreating the corrupt fixture. It never invokes purchase, restore or refresh. `testCorruptProjectBlocksSavingAcrossRelaunch` retains the earlier persistence-only case. |
| [LightingPlanExportUITests](../../../UITests/LightingPlanExportUITests.swift) | `testExportPreviewOpensWithoutSavingOrChangingScene`: format Cancel/reopen, PDF preparation and close, unchanged history/status. `testFullLibraryCanPrepareUnsavedEditableCopyWithoutSavingOrChangingHistory`: 64-record fixture, unsaved copy and PDF preparation, close/reopen with fresh snapshot after Undo, retained Redo and saved state after relaunch. Neither selects a system destination. |

Session coverage is separately located in
[StudioFeatureSessionTests](../../../NativeTests/StudioFeatureSessionTests.swift):
`testOpenAdmissionPreservesGestureUntilLoadedCurrentValidDestination`,
`testSceneNoOpIsAcceptedOnceAndRetiresWithoutDiscardingRedo`,
`testTargetLuxUsesCapturedUUIDAndOnlyAcceptsOutputChanges`,
`testTargetLuxNoOpRetiresWithoutChangingEditor`,
`testRoomAndARAdvanceOwnReceiptAndUndoAllAcceptedMeasurementsTogether`,
`testEditAwayAndUndoBackCannotReviveSnapshotOrDiscardRedo`,
`testRetiredOwnerCannotApplyOrFinishTheNextPresentedRoomGroup`,
`testBusyRejectionKeepsFeatureAndFirstSavePreservesLogicalContext`,
`testReloadAndProjectSwitchClearFeatureAndRejectItsLateCallbacks`,
`testFailedProjectOperationsKeepTheOpenFeatureUsable` and
`testFailedInitialLoadBlocksFeatureButExplicitRetryCanRecover`.

[StudioSessionTests](../../../NativeTests/StudioSessionTests.swift) supplies
`testCancellingSheetObserverStillReconcilesCommittedSaveExactlyOnce`,
`testPendingOperationRejectsMutationAndSecondReservation` and
`testLoadFailureProtectsDataAndRejectsEditingAndSave`.
[StudioFeatureWindowTests](../../../NativeTests/StudioFeatureWindowTests.swift)
contains `testTwoWindowsKeepRoomOwnersThroughCompetingSaveAndRetireOnlyRecoveredWindow`.
These actual session/store tests can execute in the portable composition target;
their names do not imply instantiated native sheets or windows.

## Evidence boundary and required native follow-through

Root-retained [wave07 evidence](evidence/wave07) was inspected separately from this
worker's source-only checks:

| Source and artifact | Recorded result and limit |
|---|---|
| `08e80c756cb7c8aa4eaf11f27932c8f701000be1`; `native-syntax.json` / `.log` | 82 Swift inputs, parser exit 0. Syntax only; no Apple typecheck or UI execution. |
| Same source; `shard-check.json` / `.log` | Nine UI classes assigned once across five required and one opt-in diagnostic shards; native unit target separate. The added method is inside the existing StudioSmoke class. Static inventory only. |
| Same source; `source-manifest.json` | 175 recorded source/build inputs. A manifest establishes input identity, not native behavior. |
| `73a829dc5c3af0394b15f9103421d89a245edcf1`; `boundary-command.json`, `boundary-debug.log` | Root ran 12 `StudioFieldCommandTests` with Swift 6.0.3: zero failures. This precedes the UI changes and does not validate their navigation. |

The retained Swift 6.4.2 failure in workflow `45842239860` remains a failure;
`ci-compatibility.json` records the explicit `Double(0.05).nextDown` correction
and its separate local revalidation. This document does not reinterpret that
run or infer a later CI outcome. This worker ran `agent_cycle.py check` and
`next` successfully; those checks validate state references/select work, not UI.
No build, Swift parse, simulator, native test or transaction ran in this worker.

Native acceptance still needs the mapped UI methods at the integrated source,
including the protected-storage round trip. Additional gaps are actual host
Observation and sheet ownership during swipe/cancelled dismissal, busy work,
first save and document reset; repeated nested manual changes after returning
to AR; real photo import/cancellation and parent draft retention under nested
picker coverage; subject editing/Done and arrangement/lux Apply/Cancel integration; and
producer rejection retention once an acceptance API exists. Portable owner
tests do not cover those native lifecycles.

AR camera authorization, pause/tracking recovery and physical placement remain
separate device gaps. Export still needs actual share/open and file-provider
success/cancellation/error checks. Purchase still needs configured StoreKit
sandbox purchase, restore, cancellation, pending, revocation and offline checks.
The documented navigation paths do not establish device accuracy, accessibility
acceptance, commerce acceptance or release readiness.


## Stable header presenter ownership (wave 10)

The header and project actions now each declare one child set inside
`StudioAdaptiveLayout`. Switching available width or Dynamic Type changes native
stack geometry instead of choosing another export-menu declaration. The outer
header retains its accessibility column policy; the inner action row still uses
width to choose its axis. Export's snapshot and format flow remain owned by the
unchanged `LightingPlanExportMenu`/`LightingPlanExportFlow` implementation.

A hosted native test tracks actual child State UUIDs and live view bounds through
eight layout/environment transitions. That source regression does not establish
actual export-sheet retention, device rotation, or the cause of the older owner
CI failure until Apple execution/reproduction succeeds.
