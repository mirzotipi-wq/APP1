# Lane 01 handoff — recovered checkpoint; campaign resuming

## Status

**Implementation is preserved; the requested ten-wave campaign is incomplete.** Work is confined to `finish/01-architecture-composition`. Exactly 17 actual fresh worker contexts have been created: ten in completed wave 1 and seven in partial wave 2. The remaining 83 have not yet started. Do not report 100 workers or ten completed waves.

The execution environment became unavailable after the session extraction was committed and tested locally, but before its publication completed. Source was reconstructed from recorded edits and the last published tree, then preserved through the connected GitHub API. The worker 04 test file was matched exactly against its pre-outage SHA-256. The execution environment has returned with a fresh filesystem; the old temporary worktrees and toolchain are gone. The campaign is resuming from this preserved checkpoint. Fresh execution of the recovered source is **unverified** until revalidation completes.

## Baseline and ownership

- Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`, used pending lane 20's BASE_SHA. No lane 20 baseline was published at the last branch inspection.
- Initial main: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`. Later main changes, including its native accessibility-test correction, remain for lane 20 integration.
- Earlier verified remote checkpoints: `db6de5841e2810fce48299fb7c00a68d284f00d6` (campaign), `30e52b8c277cfd15d5edeb872ff7a53d274f9b16` (editor/contracts), `ef71165d52e513d46176f37d22ec472b19124c6b` (wave 1 evidence).
- Lane19 owns CI; lane 20 owns canonical state and integration. This lane has not changed canonical agents/state.json, CI, feature algorithms or main.

## Implemented

1. **Portable editor owner:** `StudioEditorState` owns validated scene, live selection, revision identity and bounded undo. Invalid candidates are atomic; schema migration preserves UUIDs/SI values/optional representations; undo keeps a valid current selection.
2. **History-safe receipt adoption:** no-reset adoption requires the same validated scene. It cannot splice different content into retained redo or an active gesture. Reset policy remains explicit, including first-save preservation.
3. **Per-window StudioSession:** project/library state, scene/history/selection and asynchronous receipt reconciliation moved out of StudioView. The existing ProjectStore actor and ProjectLibraryOperationState source are unchanged. Operation and editor adoption are staged before publishing either.
4. **Stale reservation ordering:** reservation now succeeds before history/Plan-drag finalization. A rejected prior-generation Save cannot split a current cumulative drag.
5. **Task lifetime:** the session retains in-flight work through receipt adoption, including observer cancellation, and clears its task handle after settlement.
6. **Feature contracts:** `StudioFeatureContext`/`StudioFeatureSession` define generation/revision/owner admission and retirement. **They are not yet wired into native feature routes.** Existing equality-only reference/arrangement/lux guards remain an integration gap.
7. **Actual app orchestration tests:** Package.swift adds an internal StudioComposition target that compiles the existing storage adapters and new session. NativeTests/StudioSessionTests.swift also remains included by the existing generated native target. Native Observation is Darwin-only; portable tests validate orchestration, not SwiftUI observation.
8. **Regressions:** nine editor tests, eight actual session tests and eight additional worker-authored contract tests.

## Verification

See [verification.json](evidence/recovery/verification.json) and [retained terminal outcomes](evidence/recovery/retained-tool-outcomes.md).

| Execution before the outage | Actual outcome |
|---|---|
| Baseline Swift 6.0.3 package suite | 366 passed |
| Initial new editor suite | 9 passed |
| Clean Swift 6.2.1 Debug suite at local 7c6f1c0 | 383 passed, 0 failed |
| Additional worker contract suite at local 538d45d | 8 passed, 0 failed |
| All App/NativeTests/UITests Swift parsing |Passed syntax only |
| Recovered-tree Debug/Release and Apple checks |Unverified |

The 383-test run preceded adding the last eight tests; these are separate runs. Full raw logs were present in local `f851500` but are currently inaccessible. Do not imply they were recovered. The new recovery manifest records all recovered source hashes and the observed failed host attempts. Earlier published wave 1 reports remain intact.

Initial main CI run 45807031966 had portable/native/studio-optics successes and a light-Fill reachability failure in app-accessibility; other UI shards were running at inspection. That is source-specific baseline evidence, not acceptance of this branch.

## Worker ledger

[WORKER_LEDGER.json](WORKER_LEDGER.json) records real IDs, scopes, input revisions and outcomes. [wave-01.json](wave-01.json) preserves all ten original reports/hashes. [wave-02.json](wave-02.json) records the seven created workers and three uncreated roles; recovered reports identify their provenance.

Worker 04's exact source file hash is `e47dfc0e576edb5b8837872aab561209ccd8438ef4aad7a49331306acd08b406`; local worker commit was `e359c773865f3e1f237cb59e356dc28a2879b832`. Local integration prefixes 7c6f1c0/538d45d/f851500 are historical local references, not promised reachable GitHub commits.

## Next executable work

1. In the restored execution environment, fetch this branch into an isolated checkout, verify its source hashes and run Debug/Release package tests plus native syntax. Inspect current main/CI and lane 20 BASE_SHA. Preserve later main changes.
2. Finish wave 2 with **three new contexts**: roles07 feature integration,08 accessibility/privacy,09 platform/performance. Retain the seven existing IDs; followups do not count as new workers.
3. Run all ten fresh workers in each of waves3–10 (80 additional contexts). Review this already implemented session extraction in wave 3; do not pretend its implementation means that review wave completed.
4. Extract typed field commands so scalar updates avoid whole-scene imported-name scans. Keep external candidate validation complete. Move cumulative Plan-drag state into the session if needed for a direct source-level regression of the stale-Save sequence.
5. Wire feature admission against the **live stored session**, checking owner/generation/revision before synchronous validated application. An editor mutation Bool differs from room/AR acceptance: valid no-op acceptance returns true. Advance a receipt only for its own accepted changes.
6. Retire presentation ownership synchronously on dismissal; late callbacks/dismissals must not affect a newer owner. Clear matching payloads on teardown. Preserve nested AR-room history, pending drafts and stable control IDs.
7. Complete reference/room/comparison/AR/export/purchase navigation through existing owner interfaces; preserve permissions, pricing and feature implementations.
8. Verify generated targets and the eight new native test methods; obtain source-specific native evidence. Challenge lifecycle/undo/duplicate state and deliver final lane 20 integration handoff.

Native API typechecking, actual UI/AR/StoreKit behavior and release acceptance remain unverified. The environment interruption is recorded above. Restoring a toolchain and revalidating the recovered source are the next steps; no user approval is required.
