# W07-06 resource lifetime source review

## Conclusion and scope

Reviewed clean detached HEAD `46a161cb01d0aee2e91940dbd06d82cfe2df5821`. No source changes or new commit. No new definite resource-ownership regression was established. The inspected Reference/comparison, room/AR, export, and host paths agree with `docs/parallel/01/NAVIGATION.md`. Native lifecycle acceptance remains unverified. The existing Void producer loss remains an actual limitation, not a fixed issue.

This packet is a read-only specialist review. Startup instructions and required project/lane documents were read. `python3 scripts/agent_cycle.py check` and `next` exited 0: state references are valid and M03 is selected. These commands do not verify runtime behavior. Canonical handoff/state still name an older checkpoint; this review uses the inspected source, not stale completion claims.

## Findings with source anchors

### Existing rejected-draft loss — confirmed, unchanged

`App/ReferenceComparisonView.swift:115–123` calls `closeSession()` before its Void `onApply`. The cleanup at lines 499–535 cancels import/analysis and clears the photo, observations, candidates and selected rig. `App/StudioFeatureSheets.swift:43–49,79–84` can reject the result and show an owner-scoped reopen message, but cannot recover that discarded state. The matching arrangement/lux limitation is explicitly retained in NAVIGATION/FEATURE_ADAPTERS; it is not repaired by admission checks or busy disabling.

### Reference/comparison closure — source-consistent; native teardown gap

Reference's local child sheet passes its reduced `UIImage` into a separate comparison session (`ReferenceComparisonView:128–149`). Comparison owns two slots, clears only those slots on Done, and has no parent scene callback (`PhotoComparisonView:12–26,90–108,332–345`). Sharing the initial UIImage does not make child Clear mutate the parent reference.

Replacement imports preserve the previous photo and guided draft until a replacement succeeds. Request IDs and cancellation guards block old completions (`ReferenceComparisonView:432–535`; `PhotoComparisonView:433–478`). Comparison task capture is weak and slot deinitialization cancels its task. Reference instead stores unstructured tasks capturing view state, so prompt cleanup depends on explicit close or the dismissal observer.

`PhotoComparisonView:348–398` detects ancestor dismissal through `viewWillDisappear/viewDidDisappear`; it supplies no explicit dismantle cleanup. This is a concrete path needing execution when the parent is already covered by a comparison/picker and its host is reset/removed. Source inspection alone cannot prove whether UIKit sends the necessary callbacks, whether a cancelled swipe preserves drafts, or whether all work is cancelled promptly. No leak is asserted without that evidence. The existing UI test checks manual observations and rig retention only; it imports no photo (`UITests/ReferenceComparisonUITests.swift:76–93`).

### AR/manual close — owner split is correct in source

Nested manual Done sets only matching `showingManual = false`; matching onDismiss clears `manualOwner`. Forwarded callbacks require both the visible flag and captured owner (`ARPlacementView:62–106`). Outer Done calls outer onClose, stops the controller and dismisses (54–57). Opening manual also stops camera work (243–247). Host outer close retires the Studio receipt (`StudioFeatureSheets:69–75`).

Controller stop invalidates permission/session generations, clears placement resources, pauses the session and removes the delegate (`ARPlacementController:234–274`). Dismantling the camera representable detaches it (`ARPlacementView:313–315`). The current simulator smoke opens one manual child and closes it without committing measurements (`UITests/StudioSmokeTests:97–114`); repeated edits after returning to AR remain unverified. Controller's initial immutable scene does not currently conflict with room-only edits: `ARPlacementLayout` does not consume `placementRoom`.

### Export and file ownership — no orphan app temp file found

One UUID snapshot owns the format flow (`LightingPlanExportView:15–97`). PDF sharing uses immutable DataRepresentation, not an app-created temporary URL (7–12). Backup uses immutable FileDocument Data and system export (ProjectDocumentIO:8–30; ProjectBackupView:75–90). The exporter result alone supplies saved feedback; cancellation does not mutate project state.

Backup view task cancellation cancels its detached worker and blocks stale publication while preserving a prepared document for the provider (`ProjectBackupView:95–121`). PDF checks current options and cancellation before/after synchronous main-actor rendering (`LightingPlanExportView:175–190`). It does not interrupt the renderer mid-call (`LightingPlanPDF:17–40`); responsiveness during maximum valid preparation remains a native measurement gap, not an established leak.

The photo importer consumes the provider's URL only inside the callback (`ReferencePhoto:30–52`). `BoundedFileReader:46–55` opens a descriptor with explicit deferred close. Analysis forwards cancellation to its detached worker and current Vision request (`ReferenceAnalysisService:59–74,125–137,284–311`). Project import scope and coordinator ownership are balanced by defer (`ProjectDocumentIO:72–109`). No ownership transfer to persistent project storage was found.

## Recommendation

Accept the route map as a source inventory. Retain the producer acceptance API owner request. Native follow-through should cover real photo replacement/cancellation, completed and cancelled interactive dismissal, parent reset while covered, repeated nested manual commits under one AR receipt, and actual PDF/share/open plus provider success/cancellation/error. Existing export UI tests prepare documents but do not select a system destination. These checks were not run here.

## Artifacts and limits

All 35 hashed inspected files match HEAD; the worktree remains clean. Full commands/results, including a corrected search that initially named nonexistent test files, are preserved in receipt/command artifacts. The empty source patch proves no source edit. No build, Swift parse, native test/runtime, camera, photo import, export transaction, purchase, push, or external communication occurred. Only the manager may remove the tree after artifact verification.

