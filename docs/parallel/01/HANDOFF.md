# Lane 01 handoff — live feature ownership checkpoint

## Status and integration boundary

Waves 1–8 are complete: **80 actual fresh contexts**, ten roles per wave. Two waves and 20 fresh contexts remain; wave9 has started. Final reports meet the 800-token tool-estimated cap after same-context condensation where necessary, with originals preserved. Working-token budgets are requested targets because the spawn API exposes no enforcement or actual usage measure. Counts use returned canonical agent IDs. Followups and the rejected capacity spawn count zero.

Only `finish/01-architecture-composition` is pushed. Last verified publication before this checkpoint is `bed58c338f9f53758c611b8642241c3ec7697505`, tree `2cf7ec0b1390cd2af42a5f18938f18cf9d17fb14`. It includes the Observation correction and eighty-worker ledger. Production remains equivalent to corrected `8b18366c1c718c2c81f6b275d66140f6dc9d49c9`; current test membership at `cdacffd3c6eb7bc178bf127187e2990adc4c676c` adds actual-store cancellation and native Observation regressions. Local test commits and GitHub publication commits have distinct IDs; complete source manifests establish equivalence.

Common inspected baseline remains `f150f98e35dd735927075aac4d2f8b02295c6a67`. Latest observed main remains `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`, including the later `UITests/StudioAppAccessibilityUITests.swift` correction that qualifies both `CGSize` bounds as `CGFloat.greatestFiniteMagnitude`, reserved for lane20 integration. Earlier coordinator brief shorthand calling this `Double` was inaccurate; the exact patch is retained under evidence/wave08. The observed origin advertises finish lanes01–05, with no lane20 branch or BASE_SHA at inspected paths. This is scoped observation, not a claim about every possible campaign location. CI belongs to lane19; canonical state and final main integration belong to lane20. Other feature-owner implementations remain unchanged.

## Implemented composition

`StudioEditorState` owns validated scene, live UUID selection, revision identity and bounded undo history. Invalid candidates are atomic. Full validation remains at arbitrary scene/update/replacement/adoption boundaries. A no-reset receipt cannot replace content beneath retained redo or an open edit. Typed `StudioFieldCommand` validates closed changed payloads without rescanning unchanged names/lights; optional default and optical-roll representation remain intact. No measured UI speedup is claimed.

`StudioSession` owns each window's editor, library, saved snapshot, project-operation reservation/task and cumulative Plan gesture. It reserves before ending edits and stages receipt adoption before publishing state. Cancelling a sheet observer does not abandon a committed write. Plan keeps a frozen origin/scale; a stale end cannot close a new generation's gesture. Ordinary control identity follows `workspaceResetID`, while callbacks separately check storage generation. Healthy repeated initial load is rejected before touching a dirty editor; failed-load retry remains available.

The session now owns one `StudioFeaturePresentation`: destination, immutable context and live receipt. Opening requires a loaded, writable, idle editor and valid target UUID. A currently presented draft cannot be replaced. Admission checks live owner, logical document identity and current revision; equal content after undo does not revive a result. First save retains the logical feature context. Successful document switch/reload/recovery clears it. Old teardown cannot close a newer owner.

Scene/lux results are one-shot, retiring callbacks synchronously after validation; valid unchanged results still report acceptance. Lux may change only the captured light's candela. Room/AR results can repeat, advance their own receipt, and share one owner undo group. Unrelated valid commands start their own undo change; invalid/no-op commands preserve the feature group. A successful changed feature result clears a frozen zero-motion Plan origin so a later drag cannot overwrite the new geometry. Rejected/no-op results retain that still-valid gesture.

`StudioFeatureSheets` now connects all five native scene-mutating routes to the live session presentation. It uses owner-matched retirement/teardown, captured inputs for one-shot proposals, and live scene input for room/AR. StudioView no longer carries seven duplicate route fields, equality/masked-room guards or blanket first-save dismissal. Both Study and 3D preview lifetimes follow `workspaceResetID`, preserving captured storage-generation and light-UUID mutation guards. Broad onDisappear retirement is intentionally absent because modal coverage can hide the root while work remains pending.

The internal StudioComposition package target compiles actual app orchestration and storage adapters. [INTERFACES.md](INTERFACES.md) contains live contract examples; [FEATURE_ADAPTERS.md](FEATURE_ADAPTERS.md) distinguishes current producer APIs from future acceptance proposals. Native wiring is implemented in source; Apple behavior remains unverified.

The protected-storage utility path now keeps Studio Tools → Settings → Purchase options available, while scene tools, export, Projects, Recipes and Save remain protected. The corresponding test is a new method in existing `StudioSmokeTests`; its shard registration is unchanged. [NAVIGATION.md](NAVIGATION.md) maps real callers, local versus outer dismissal, exports, purchase ownership and remaining native checks.

## Observation compilation correction

Apple Swift6.3.3 CI at `5ccfbaa` exposed an owned-source failure in the conditional `@ObservationIgnored` task properties. Both the macOS package build and a native UI build failed with unexpected getter/init-accessor diagnostics. Correction `8b18366c1c718c2c81f6b275d66140f6dc9d49c9` places each attribute directly on its complete Darwin declaration and keeps plain Linux declarations. Types, access and orchestration behavior are unchanged. A controlled actual-source Linux macro probe reproduces the original four errors and passes with the correction; it is not an Apple SDK check. Corrected source passes full431 Debug and431 per-file Release tests, with82 native syntax inputs parsed. Apple compilation/execution of the correction remains unverified pending CI. See [CONFIGURATION.md](CONFIGURATION.md) and [wave08-fixed evidence](evidence/wave08-fixed).

## Wave 9 lifecycle regressions

Two actual-store first-save tests now gate the receipt after `ProjectStore.perform`
commits to disk. Cancelling either the UI observer or the session-owned task at
that point must still adopt the committed receipt once, retain the room draft,
selection and undo history, and reject callbacks carrying the old storage generation.
Both methods passed at `c3ce487` on Swift 6.0.3 Linux. Three additional Darwin-only
Observation methods check edit/undo, presentation retirement/removal, and busy
notifications while task bookkeeping stays ignored. A controlled Linux forced-branch attempt compiled them but failed at link time
with unresolved `swift::threading::fatal` in the Observation library; no methods
executed. The log and exact transformation are retained. Apple execution remains
unverified; normal Linux discovery excludes these methods.

## Actual verification

| Exact local test revision | Check | Result |
|---|---|---|
| `cdacffd3c6eb7bc178bf127187e2990adc4c676c` | Forced-Darwin Linux Observation test probe | Compilation succeeded; link failed with unresolved runtime symbol; **zero tests executed** |
| `c3ce48761e2f927da82f1e86549aab77becf61a1` | Actual-store cancellation regressions | **2 passed**, fresh separate Debug scratch |
| `bed58c338f9f53758c611b8642241c3ec7697505` | Corrected production CI Swift6.4.2 default Debug + Release | **431 passed each**, corejob140058830854 success; predates newtests |
| `8b18366c1c718c2c81f6b275d66140f6dc9d49c9` | Corrected Swift6.0.3 Linux Debug + per-file Release |431 passed each; Release has explicit no-whole-module-optimization flag |
| Same corrected source | Forced Observation-branch macro typecheck / native syntax |Before4 errors → afterexit0;82native syntax inputs; no Apple SDK/runtime |
| `7bdea15c771d7dfeeb3f20d011b3c02e4bc5b34f` | Pre-correction default local Release |Compile interrupted by signal9 beforetests; notpassed, causeunproven |
| Same pre-correction source | CI Swift6.4.2 default Debug + Release |431passed each;corejob140036374958success |
| `5ccfbaae821a32d88c12ed8b3abf1600aef25753` | CI Swift6.4.2 Linux Debug + Release | **431 passed in each configuration, zero failures; full core job success** |
| Same published source | CI case/source reconciliation |431 unique started/passed cases per configuration;175 source hashes; complete raw log retained |
| `08e80c756cb7c8aa4eaf11f27932c8f701000be1` | Wave7 native syntax/shard inventory |82 Swift files parse;9 UI classes correctly assigned; native UI method not executed |
| `73a829dc5c3af0394b15f9103421d89a245edcf1` | Local compiler-literal correction |12 affected boundary tests passed on Swift6.0.3 |
| `785d4587287b4a44b1d9f8f6e3d941700b04d871` | Wave6 full Swift6.0.3 Linux Debug | **431 tests passed, zero failures** |
| Same source | Shared-storage feature regression | Two actual session/store owners: foreign callbacks, competing save, continued draft editing, successful recovery; no native windows instantiated |
| Same source | App/NativeTests/UITests syntax |82 Swift inputs parsed; syntax only |
| Same source | Source manifest |175 inputs independently matched to disk and Git blobs |
| `363a7149e4eb6f195f478b3ce0210e33e8ac7ed0` | Earlier wave5 full Debug |430 tests passed, zero failures |
| Wave5 source | Feature orchestration inventory |16 actual StudioFeatureSession methods passed, including failed save/reload/recover retention |
| Wave5 source | App/NativeTests/UITests syntax |80 Swift inputs parsed; syntax only |
| Wave5 source | Source manifest |173 inputs independently matched to disk and Git blobs |
| `721186e93d4f4a511823d4f3013414929e54a56d` | Earlier wave5 full Debug |429 passed; retained separately before the failure-path test |
| `2f8be604d403d02a7a8c3273ce82cb4e3f969545` | Wave4 full Debug |413 passed |
| `6fe2cfab49f1b087553f65341f4471f786b309f9` | Wave3 full Debug |400 passed, including real two-window save conflict/recovery |
| Apple SDK compilation, SwiftUI Observation/UI, focus/caret, AR, StoreKit/device behavior | Native validation |**Unverified** |

Wave7 syntax, shard, targeted correction and CI evidence: [evidence/wave07](evidence/wave07). The historical failed CI run45842239860 is preserved separately; corrected run45851159581 core job140017565927 succeeded. Native jobs were queued at the recorded observation. Wave6 complete local logs: [evidence/wave06](evidence/wave06). Wave5 final logs: [evidence/wave05-final](evidence/wave05-final). Initial429 run: [evidence/wave05](evidence/wave05). Earlier retained evidence: wave04, wave03-restored and revalidated. Official Swift6.0.3 restored-toolchain provenance and signature are under wave06-toolchain and earlier toolchain directories. Source-specific evidence is never transferred to changed inputs without revalidation.

Several early temporary environments reset. Exact recovered source/report hashes and original versus reconstructed provenance are retained under evidence/recovery and evidence/wave03-recovery. Earlier raw logs that were lost are identified as historical, not presented as recovered. Durable source/reports now use sparse workspace worktrees; disposable build/cache output uses separate temporary paths.

## Remaining integration work and limitations

Wave6 implements the live presentation host, matching teardown and first-save logical identity. Existing room/AR Bool callbacks receive current scene state without an identity reset of the AR controller. Their actual SwiftUI lifecycle, Observation and nested dismissal still require Apple execution.

ReferenceComparisonView clears its photo/candidate session before its Void callback. Arrangement and target-lux also mark completion and dismiss after Void callbacks. The parent can reject obsolete results but cannot retain already-consumed feature drafts through those APIs. An owner-provided acceptance callback is required; do not claim that core receipt tests solve this native boundary. Observed producer interfaces are unchanged across main and advertised lanes01–05.

The latest lane05 owner request at `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a` acknowledges implementation at5ccfbaa. Its exact document/receipt is retained under evidence/wave08/owner05-requests.*. The lane05 spatial-preview owner request is implemented at the composition wrapper: both preview identities follow workspaceResetID, and storage-generation/light-UUID guards remain. Renderer files are unchanged. Native first-save viewport retention still needs runtime verification.

Wave7 has implemented the protected-storage utility navigation fix and corresponding UI regression, with source reviews of reference/comparison, room/AR, export and purchase. All ten wave7 workers completed, with scoped source acceptance and source-specific evidence independently checked. Wave8 completed package/target source inventory, applicable local build checks and the owned Observation compiler correction; generated Apple targets remain unverified. Wave9 challenges duplicate state/lifecycle/undo and adds the actual-store postcommit cancellation regression. Wave10 delivers the final100-context ledger, current-source evidence and precise lane20 handoff. Only preserved work may be cleaned.
