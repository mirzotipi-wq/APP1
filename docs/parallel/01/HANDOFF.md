# Lane 01 handoff — live feature ownership checkpoint

## Status and integration boundary

Waves1–4 are complete: **40 actual fresh contexts**, ten roles per wave. Wave5 implementation and its final430-test run are complete; remaining independent reviews are in progress. Counts are based on returned canonical agent IDs, never planned tasks. WORKER_LEDGER.json and wave ledgers preserve completed counts, reports and hashes; followups and the rejected capacity spawn count zero.

Only `finish/01-architecture-composition` is pushed. Last verified publication is `ea83fa165916aaa2f55ddb88f6430b8a59ce5565`, tree `83bd4af88e6224abb828a6cf1cb0b286145931da`. Current wave5 local tested source is `363a7149e4eb6f195f478b3ce0210e33e8ac7ed0`. The next publication will preserve its exact source hashes; local test commits and GitHub publication commits have distinct IDs.

Common inspected baseline remains `f150f98e35dd735927075aac4d2f8b02295c6a67`. Latest observed main remains `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`, including a later native-test correction reserved for integration. The observed origin advertises finish lanes01–05, with no lane20 branch or BASE_SHA at inspected paths. This is scoped observation, not a claim about every possible campaign location. CI belongs to lane19; canonical state and final main integration belong to lane20. Other feature-owner implementations remain unchanged.

## Implemented composition

`StudioEditorState` owns validated scene, live UUID selection, revision identity and bounded undo history. Invalid candidates are atomic. Full validation remains at arbitrary scene/update/replacement/adoption boundaries. A no-reset receipt cannot replace content beneath retained redo or an open edit. Typed `StudioFieldCommand` validates closed changed payloads without rescanning unchanged names/lights; optional default and optical-roll representation remain intact. No measured UI speedup is claimed.

`StudioSession` owns each window's editor, library, saved snapshot, project-operation reservation/task and cumulative Plan gesture. It reserves before ending edits and stages receipt adoption before publishing state. Cancelling a sheet observer does not abandon a committed write. Plan keeps a frozen origin/scale; a stale end cannot close a new generation's gesture. Ordinary control identity follows `workspaceResetID`, while callbacks separately check storage generation. Healthy repeated initial load is rejected before touching a dirty editor; failed-load retry remains available.

The session now owns one `StudioFeaturePresentation`: destination, immutable context and live receipt. Opening requires a loaded, writable, idle editor and valid target UUID. A currently presented draft cannot be replaced. Admission checks live owner, logical document identity and current revision; equal content after undo does not revive a result. First save retains the logical feature context. Successful document switch/reload/recovery clears it. Old teardown cannot close a newer owner.

Scene/lux results are one-shot, retiring callbacks synchronously after validation; valid unchanged results still report acceptance. Lux may change only the captured light's candela. Room/AR results can repeat, advance their own receipt, and share one owner undo group. Unrelated valid commands start their own undo change; invalid/no-op commands preserve the feature group. A successful changed feature result clears a frozen zero-motion Plan origin so a later drag cannot overwrite the new geometry. Rejected/no-op results retain that still-valid gesture.

The internal StudioComposition package target compiles the actual app orchestration and storage adapters. [INTERFACES.md](INTERFACES.md) contains contract examples. **Native feature route wiring remains the next step:** StudioView still uses legacy equality guards and storage-generation dismissal until wave6.

## Actual verification

| Exact local test revision | Check | Result |
|---|---|---|
| `363a7149e4eb6f195f478b3ce0210e33e8ac7ed0` | Full Swift6.0.3 Linux Debug | **430 tests passed, zero failures** |
| Same source | Feature orchestration inventory |16 actual StudioFeatureSession methods passed, including failed save/reload/recover retention |
| Same source | App/NativeTests/UITests syntax |80 Swift inputs parsed; syntax only |
| Same source | Source manifest |173 inputs independently matched to disk and Git blobs |
| `721186e93d4f4a511823d4f3013414929e54a56d` | Earlier wave5 full Debug |429 passed; retained separately before the failure-path test |
| `2f8be604d403d02a7a8c3273ce82cb4e3f969545` | Wave4 full Debug |413 passed |
| `6fe2cfab49f1b087553f65341f4471f786b309f9` | Wave3 full Debug |400 passed, including real two-window save conflict/recovery |
| Apple SDK compilation, SwiftUI Observation/UI, focus/caret, AR, StoreKit/device behavior | Native validation |**Unverified** |

Complete current logs, commands and manifests: [evidence/wave05-final](evidence/wave05-final). Initial429 run: [evidence/wave05](evidence/wave05). Earlier retained evidence: wave04, wave03-restored and revalidated. Official Swift6.0.3 restored-toolchain provenance and signature are under wave04-toolchain. Source-specific evidence is never transferred to changed inputs without revalidation.

Several early temporary environments reset. Exact recovered source/report hashes and original versus reconstructed provenance are retained under evidence/recovery and evidence/wave03-recovery. Earlier raw logs that were lost are identified as historical, not presented as recovered. Durable source/reports now use sparse workspace worktrees; disposable build/cache output uses separate temporary paths.

## Remaining integration work and limitations

Wave6 must replace native route state/equality checks with the live session presentation and owner-matched teardown. Storage-generation changes must no longer tear down feature drafts on first save. Existing room/AR Bool callbacks support this directly. Live room values must reach nested AR/manual room views without resetting the AR controller.

ReferenceComparisonView clears its photo/candidate session before its Void callback. Arrangement and target-lux also mark completion and dismiss after Void callbacks. The parent can reject obsolete results but cannot retain already-consumed feature drafts through those APIs. An owner-provided acceptance callback is required; do not claim that core receipt tests solve this native boundary. Observed producer interfaces are unchanged across main and advertised lanes01–05.

The published spatial-preview owner request also asks composition to key preview lifetime by workspaceResetID while retaining captured storage-generation/light-UUID mutation guards. Address that in wave6 without editing renderer implementations.

Wave7 completes navigation and concrete native acceptance scenarios for reference/comparison, room/AR, export and purchase. Wave8 verifies package/generated targets and applicable build configurations. Wave9 challenges duplicate state/lifecycle/undo. Wave10 delivers the final100-context ledger, current-source evidence and precise lane20 handoff. Only preserved work may be cleaned.
