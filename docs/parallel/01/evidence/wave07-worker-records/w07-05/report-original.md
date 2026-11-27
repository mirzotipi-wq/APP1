# W07-05 concurrency review — original

## Conclusion and scope

Reviewed detached base `08e80c756cb7c8aa4eaf11f27932c8f701000be1`. No additional concrete late-callback scene overwrite or document-transition defect was found in the inspected source paths. This is a source-review conclusion, not native acceptance. No repository edits or new commit were made. No builds, tests, syntax parses, camera/photo actions, purchases/restores, uploads, or external communications ran.

## Project work and feature admission

`App/StudioSession.swift:288` checks load/protection preconditions and reserves synchronously at line 298 before ending edits or clearing Plan drag. `App/ProjectLibraryOperation.swift:85` rejects stale generation and busy reservations without mutation. The session owns the task; request IDs gate cleanup at `StudioSession.swift:303`, while matching pending ID, generation, and project identity gate adoption at `ProjectLibraryOperation.swift:103`. Prospective operation/editor/saved state is staged before publishing at `StudioSession.swift:312`. Scene mutation is blocked while the reservation exists.

Cancellation before queued storage work can skip it (`App/ProjectStore.swift:40`). Once synchronous store work begins there is no suspension or post-write cancellation check. Session receipt adoption has no cancellation check after `execute` returns (`StudioSession.swift:309`). Cancelling a child observer therefore does not suppress a committed receipt. Project-import reads check cancellation, presentation acceptance and request identity before synchronously handing ownership to `onApply` (`App/ProjectLibraryView.swift:403`). Its cancellation path deliberately stops cancelling after the commit handoff at line 429.

`StudioSession.swift:140` checks the live parent and `StudioFeatureContext.swift:34` checks presentation ID, logical generation, accepted revision and pending-work admission. Successful first save preserves workspace identity and the feature receipt; project switch, reload and recovery reset it (`ProjectLibraryOperation.swift:115`, `StudioSession.swift:331`). Failure settles only the matching request and preserves the feature. `StudioFeatureSheets.swift:26` synchronously retires a matching owner on dismissal; old teardown cannot clear a newer presentation (`StudioSession.swift:204`). Reference result admission and mode change have no intervening suspension (`StudioFeatureSheets.swift:43`).

## Export ownership

`App/LightingPlanExportView.swift:23` captures name, scene and text settings in one immutable snapshot, with flow identity at line 32. PDF preparation checks cancellation and option identity before clearing state and before publishing at lines 175–189. `App/ProjectBackupView.swift:95` captures value inputs and cancels its detached preparation worker through a cancellation handler. File-export completion only changes export-local status. These paths have no scene-adoption callback; a finished export of the opening snapshot does not require a StudioFeatureContext. No request was made to alter that product behavior.

## Purchase ownership

`App/KeyAndFillApp.swift:6` owns one EntitlementStore shared by windows. `App/ProFeaturesView.swift:266` reserves its requested action synchronously; the main-actor store separately fences purchase/restore activity (`App/EntitlementStore.swift:101`, `:140`). Verified transaction handling deliberately runs in an independent finite task through refresh and finish (`EntitlementStore.swift:231`). Project or scene-feature teardown must not be used to invalidate these app-owned entitlement results. No StoreKit transaction or native behavior was exercised.

## Confirmed retained limitation

Reference closes and clears its session before the Void callback (`App/ReferenceComparisonView.swift:116`, `:530`). Arrangement and target lux set completion flags before their Void callbacks (`App/SceneArrangementView.swift:97`, `App/LightTargetLuxView.swift:108`). A parent rejection can therefore protect the scene while consuming the feature draft. This is the known unresolved producer API gap; the host's owner-scoped message at `StudioFeatureSheets.swift:79` does not repair it.

## Checks and recommendation

Actual commands and outputs are in `receipt.json`: HEAD/branch/status/log, `python3 scripts/agent_cycle.py check`, `python3 scripts/agent_cycle.py next`, `git diff --check`, and `git diff --stat`. State validation reported valid structure/references only; next selected M03 with editing/accessibility/persistence outstanding. All inspected input bytes were hashed and independently matched to HEAD Git blobs. The final tree is clean and `source.patch` is empty.

Read the source of existing cancellation, first-save, pending-rejection, reset and two-session recovery regressions (`NativeTests/StudioSessionTests.swift:190`, `StudioFeatureSessionTests.swift:343`, `StudioFeatureWindowTests.swift:12`, `ProjectStoreOperationTests.swift:204`); did not execute them or transfer prior-source passes to this revision. Startup state documents are historical and lag the wave6/wave7 brief. Keep the present ownership boundaries, retain the Void limitation, and require exact-source Apple sheet/Observation/export/StoreKit execution before claiming native behavior. Root alone integrates and pushes.
