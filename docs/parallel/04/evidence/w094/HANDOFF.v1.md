# Lane 04 handoff — wave 10 evidence candidate

## Current decision and source boundary

Lane04's engine, eligibility and shared-kernel corrections have source-specific portable and native evidence. The final product/test source is `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`. Its four appended native cache methods remain unexecuted in the retained receipts. Consumer integration with owner03 also remains open. This handoff supplies lane evidence; it does not promote a global milestone, establish a whole-workflow pass, or authorize release.

This candidate was prepared from immutable documentation input `0fa824307da13934a289a825fd6d9d4a1939241f`, under [the wave10 task packet](evidence/w094/originals/task-packet.json). Root owns integration and publication to `finish/04-metal-cache`. No future commit SHA is asserted. The worker-count and CI observations below are the known preparation snapshot; root must append any later terminal evidence and seal actual counts after the final independent review.

| Revision | Meaning and retained boundary |
|---|---|
| `f150f98e35dd735927075aac4d2f8b02295c6a67` | Fixed campaign baseline. Its native test-bundle build failed before native/UI execution; it has no native pass to carry forward. |
| `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318` | Main observed at startup. Its four post-f150 commits include historical evidence/status and the existing native build correction. |
| `b0d25eece01a3edb4c46e89cd487105d4d5a8cdd` | Imported upstream correction in `UITests/StudioAppAccessibilityUITests.swift`: explicit `CGFloat` bounds disambiguation. This is an ownership exception inherited unchanged, not a lane04 UI edit. |
| `5bf9da747f947e9f5ed2e0836abb3ba726800307` | Recorded upstream merge, with parents `3d0e20616d0e771ad72161592c59105f591951c9` and startup main `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`. This is the executed post-build-fix baseline. |
| `240000fd3f8cb75273eb279be9dcc7f204a5b29f` | Source6: completed portable, app-build and 174-method Debug native evidence, including 25 cache methods and actual simulator Metal6/8. |
| `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014` | Source7: preserves production and the 25 native cache methods; appends four methods, bringing that class to 29. Its portable job passed; native remains queued. |
| `0fa824307da13934a289a825fd6d9d4a1939241f` | Two documentation-only descendants after source7. The exact compare reports 193 changed paths, all under `docs/parallel/04/`. No new product/test execution is implied. |

The source6→source7 compare has one non-lane-document path: 208 appended lines in `NativeTests/StudyRenderCacheTests.swift`. The f150→input compare is capped at 300 files and is not exhaustive scope proof. [The recovery record](ENVIRONMENT_RECOVERY.md#upstream-dependency), [source manifest](evidence/root/final-source-hashes.json), and [w094 input/compare receipt](evidence/w094/inputs.json) preserve ancestry and these limitations. Imported global documents retain their original project history; lane04 did not author a global milestone promotion.

## Corrected behavior and unchanged authority

The shipped Swift Double CPU renderer remains the numerical reference. Lane04 does not change its equations, color/sample meanings, canonical fixtures, acceptance thresholds or packed row layout. The layout remains six float4 parameter rows and three rows per sample and per area, each row 16 bytes. [Source identities](evidence/root/final-source-hashes.json) pin the engine (`8c1acd852d85cd99671feaba883db1808bbb5e68`), guarded header (`f60258402a96f58b62607d5cefec5e41c7ec4137`), width-aware eligibility (`e9764da10eabbffbad6ceee8999977cf31deb197`), unchanged lane04 oracle (`0ca920b1332e1042d2e3ddfe0d0fe69ccc5b46ad`) and unchanged core cache (`0731ab93a924572ccacd3dd66e334a85dc7c06e7`).

Production eligibility uses the requested pixel width; the compatible `supports(scene)` overload forwards width192. Valid but precision-ineligible sphere requests use CPU without disabling later eligible Metal work. Guards cover silhouette-sensitive grids, near-field/panel bounds, exact camera-clearance validity and the narrow nonaxial near-vertical cone. Relative camera and active-light distances are bounded at 20m; zero-candela lights are exempt from that production light-distance check. Packing subtracts the subject in Double before Float conversion. The mannequin remains CPU-only, clamped to width144. Invalid input preserves its constructor error rather than becoming a successful fallback frame.

The shared header rejects invalid dimensions, pixel coordinates, nonfinite/nonintegral/out-of-range counts and area tags before unsafe integer conversion or indexing. This preserves valid-input arithmetic and ABI. The conservative eligibility margins are engineering guards, not universal proved Float32 error bounds.

[The frozen fallback contract](FALLBACK_CONTRACT.md) gives the full ordered table. Its essential state distinctions are:

| Event | Required engine behavior |
|---|---|
| First eligible uncached sphere request | The default actor-owned factory creates the real Metal renderer, validates all six canonical fixtures at width48 against CPU, then stores the backend only after the cancellation check. |
| Typed scene/input errors or `StudyError.cancelled` during startup | Propagate without admission; remain unchecked and retryable. |
| Startup `precisionDomain` | CPU for this request; preserve cache and unchecked state for a later eligible uncached retry. |
| Ordinary cancellation or typed scene/input error after validation | Propagate; preserve the validated backend and old completed entries. |
| Steady-state `precisionDomain` | CPU for this request; retain validated backend and compatible cache. |
| Confirmed command/allocation/parity/invalid-compute-output or other backend failure | Permanently select CPU and purge engine-cached Metal frames before the next cancellation check. A concurrent cancellation may be returned while the permanent downgrade remains effective. |
| Successful completed frame | Admit only after the final cooperative check; cache hits promote only after their own cancellation check. |

A generic Swift `CancellationError` from an injected backend currently takes the catch-all failure route; the backend cancellation contract uses `StudyError.cancelled`. An armed but unexecuted scripted failure proves no downgrade. The injected factory is opt-in and requires exclusive backend ownership; synchronous methods alone do not enforce exclusivity.

The actor serializes its synchronous render method. Cancellation remains cooperative: an external flag can change after the last false observation. After GPU submission, the code waits for completion, checks command status, checks cancellation, copies output and constructs the image within the autorelease-pool scope. These are program-order facts, not GPU preemption, latency or driver-lifetime measurements. CPU cancellation retains the acceptance bound of at most eight further pixel evaluations after an external cancellation immediately following a false poll.

Cache identity validates the scene before omitting display names and otherwise uses exact scene/effective-width/subject equality. Failed or cancelled attempts do not enter the cache; separately successful CPU fallbacks may. Limits are per engine: **4 completed frames, 262144 RGBA bytes and 65536 mask bytes**. Selective downgrade preserves CPU entries and their order; it cannot revoke images retained by UI or other callers.

## Numerical evidence and exact CI scope

Acceptance remains exact invalid-mask equality, mean RGB-channel error≤1 and fraction of channels with error>4≤0.005. Strict8 additionally requires maximum channel error≤1. Canonical maximum error is descriptive. Matching nonzero unsupported counts are allowed; mask bytes are not unsupported-pixel counts.

[PARITY_TABLES.md](PARITY_TABLES.md) retains every baseline/current host and simulator row, raw blob, emitted precision and assertion basis. [PRECISION_REPRODUCIBILITY.md](PRECISION_REPRODUCIBILITY.md) and [precision-fixtures.json](precision-fixtures.json) bind exact constructors and commands. Canonical6 is hard, soft, warm-rotated, dark, near-field and translated, at 96×64 for host/native comparison. Strict8 is six 19.0/19.999999/20.0m × 85/200mm cases plus two world translations, at 192×128. The generator emits 33 probes; CI selects eight, so the other 25 have no inferred pass.

Native `renderValidationFixture` bypasses production eligibility while retaining input/relative-distance validation and actual Metal dispatch. These parity methods cannot pass by returning CPU fallback; their results do not assert ordinary production eligibility for every case. No-device skips are unverified, never passes. Native unsupported and mismatch counts are not printed; exact masks are established by the retained passing assertions, not invented numeric counts.

| Exact source / run | Job and evidence | Observed outcome |
|---|---|---|
| Post-fix baseline `5bf9da7`; [45820657102](https://github.com/mirzotipi-wq/APP1/actions/runs/45820657102) | Core139911733805; native139913885039; [baseline metadata](evidence/ci/baseline-native-139913885039.json) | 366 Debug/366 Release portable; 154 native passed. Canonical host and actual simulator Metal results match the later printed values. Native strict8 did not exist yet. |
| Historical source `88279ba`; [45837392344](https://github.com/mirzotipi-wq/APP1/actions/runs/45837392344) | Native139973865345; [receipt](evidence/ci/wave04-native-139973865345.json) | 160 native passed, no skips; actual simulator Metal6/8. Kept separately from later renderer execution. |
| Source6 `240000fd`; [45848953002](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002) | Core140009926092; [log](evidence/ci/wave06-core-140009926092.log), [metadata](evidence/ci/wave06-core-140009926092.json) | 379 Debug/379 Release; canonical host6 and selected strict8 passed with zero mask mismatches. |
| Same source6/run | Native140012314020; [log](evidence/ci/wave06-native-140012314020.log), [metadata](evidence/ci/wave06-native-140012314020.json) | 174 unique Debug native methods, zero failures/skips, including all 25 cache methods. Both unsigned app builds, required method accounting and finalized XCTest export passed. Actual simulator Metal6 maximum≤1/outlier fractions0; strict8 mean/max/outlier fractions0; exact masks asserted. |
| Source7 `69eb9c5`; [45854806270](https://github.com/mirzotipi-wq/APP1/actions/runs/45854806270) | Core140031989526; [log](evidence/ci/wave07-core-140031989526.log), [metadata](evidence/ci/wave07-core-140031989526.json) | 379 Debug/379 Release and host6/8 passed; not Apple execution of the four appended cache methods. |
| Same source7/run | Native140034909086; [queue receipt](evidence/ci/wave07-native-140034909086-queue.json), observed16:47:38 UTC | Queued on macos-26-intel, runnerId0, no pending deployment approvals. Cause/ETA unknown. Four additions unexecuted; no source7 native pass. Root alone monitors. |

The source7 additions cover startup failure plus cancellation preserving CPU cache, cancelled validation preserving CPU cache and retry, concurrent eligible requests validating once, and steady-state scene errors preserving validated backend/cache. Source presence is not compile/runtime acceptance.

**CI6 warm-up failed separately:** attempt-1 bootstatus and recovery-preflight timed out; the preparatory command exited1 in raw lines4714–4735. The subsequent required native test command, exact accounting and finalized export succeeded. Preserve both observations. Native runtime was Debug only; Release built the application but did not run native methods. No assertion that every step or the whole workflow passed follows from these job results. Cancelled native5 remains cancelled.

Source6 host reported Swift6.4.3 on Ubuntu24.04.5; simulator evidence used Xcode26.6/17F113, Apple Swift6.3.3, hosted Intel macOS26.6.1 and iOS simulator SDK26.5. Exact retained commands include:

~~~sh
swift test --jobs 2 2>&1 | tee core-tests.log
swift test --configuration release --jobs 2 2>&1 | tee core-release-tests.log
/Applications/Xcode_26.6.app/Contents/Developer/usr/bin/xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug -destination id=12FCFD0F-7FCF-463F-A605-132A7E18B5D5 -derivedDataPath /Users/runner/work/_temp/keyfill-build -parallel-testing-enabled NO -resultBundlePath NativeTests.xcresult CODE_SIGNING_ALLOWED=NO "-only-testing:KeyAndFillTests" test-without-building
~~~

The reproducibility note retains build-for-testing, Swift fixture preparation, clang++ -O2 canonical comparison and `--maximum-channel-error 1` strict selection verbatim. These commands were not run by w094. Source6 core artifact15132856675, native full15135391983/compact15136500149, and source7 core15135792348 have retained upload identities/digests in the corresponding evidence. Artifact upload success alone does not supply a test result.

The original f150 silhouette probe remains a failing **host C++ Float32 versus independent C++ Double transcription**, not shipped Swift or Metal execution: 24×16, two differing pixels, mean0.1076388888888889, maximum24 and >4 fraction0.005208333333333333. Exit0 means successful reproduction. The retained command is -O2; `invalid=0` counts only candidate invalid pixels and proves no two-mask comparison. Later Swift reference-pixel assertions do not create a whole-frame Swift/Metal metric.

## Observed resources and lifetime boundaries

Source6 native emitted all **19 real CPU cache payload rows**, comprising 15 request observations and four summaries. [The complete resource table](evidence/w076/CACHE_RESOURCES.md), [raw emissions](evidence/w076/observed-resource-lines.log) and [machine-readable receipt](evidence/w076/cache-resources.json) retain every value and method.

| Final population | Entries | RGBA bytes | Mask bytes |
|---|---:|---:|---:|
| Four 24×16 bust frames | 4 | 6144 | 1536 |
| Four 144×96 bust frames | 4 | 221184 | 55296 |
| Three 192×128 sphere requests, two retained | 2 | 196608 | 49152 |
| Three maximum busts then one maximum sphere, two busts plus sphere retained | 3 | 208896 | 52224 |

All observations satisfy the fixed per-engine bounds. Dimensions come from retained returned-image arrays cross-checked against actor counters; they are not direct cache-entry enumeration. Subsequent hit/cold-render checks establish retained identities. The fixture arrays still hold returned images, so these counters do not establish image-allocation release or process RSS.

All16 portable cache methods passed Debug and Release. Their weak-reference tests measure pure Swift ownership. The native weak scripted-backend test observes release after callback unwinding while the engine stays usable; synthetic Metal-tagged images prove state handling, not GPU work. Requested Metal buffer arithmetic is separately `96 + 16×max(3S,1) + 16×max(3A,1) + 4WH` bytes. The eight-byte dimension argument uses setBytes; mask construction occurs on CPU. Neither arithmetic nor ownership tests measure allocator capacity, driver memory, peak RSS, physical-device memory or GPU cancellation latency.

## Owner routes and the remaining consumer integration

The latest retained owner refresh is16:35:58 UTC, with [exact comparison](evidence/w083/source-review.v1.json), blob `55bb057aecbca8210673c3f2ae85b8323bff86fb`. Owner02 is `b5c1f008446f8b33f3ee97f8fefe6675058ef347`; owner03 is `92dc7a69c0032141ee49de0b96940fccab83a33e`. No direct acknowledgment, merged result or runtime approval is inferred.

Frozen lane04 still permits the UI-held A/Metal→B permanent downgrade plus cancellation→returnA shortcut without reconsulting the engine. That is a consumer current-status/adoption gap, not demonstrated corrupt pixels or engine-cache leakage. Owner03 now has request-and-ticket currentness, removes the successful-frame shortcut, reconsults the engine on activation, and adopts a single Frame pairing image/backend/warning/error. Its new hosted `testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade` uses a controlled synthetic producer. Retained receipts leave Apple typechecking, hosted execution and hook-only before/fail unrun. The w057 patch remains historical and unapplied/uncompiled; it must not obscure the newer source remedy.

Hosted assertions inspect accessibility/status/backend/warning state. Existing pipeline tests inspect converted bytes; the single Frame assignment supports paired storage. Independent inspection of displayed CGImage bytes is a bounded coverage recommendation, not a demonstrated defect or additional mandatory gate.

Owner03 also changes tiny-output CPU integration/packing construction and adds an early cancellation check. Its unit-intensity accumulation restores original intensity before packing; the 6/3/3 float4 layout and sample-intensity meaning remain unchanged. That arithmetic change is not covered by lane04's older-oracle results.

| Owner | Concrete next responsibility |
|---|---|
| 02 — photometry/color | Preserve canonical/strict definitions, CPU authority and packed semantics; reconcile color/photometry changes and rerun combined numerical checks. |
| 03 — CPU/preview | Supply current oracle/consumer/hosted-test source and complete Apple compile, hosted execution and retained hook-only before/fail comparison; keep generation/cancellation and paired adoption checks. |
| 01 — composition/build | Preserve the imported native build-fix ancestry and default real-backend construction. Keep test injection opt-in and owner changes reviewable. |
| 19 — harness/CI | Retain complete native discovery/accounting and skip rejection. Separately reproduce/harden parser metadata validation, including float-to-integer and contiguous area-group inputs, without weakening parity. |
| 20 — integration | Retain lane04 engine, width-aware eligibility and guarded header while combining owner02/03 oracle/consumer/test work. Owner02/03 contain older header/engine versions; do not overwrite lane04 corrections wholesale. Rerun combined CPU Debug/Release, host6/8, actual Metal6/8, lifecycle/cache and adoption checks. Own global milestone decisions. |

[OWNER_REQUESTS.md](OWNER_REQUESTS.md), [OWNER_INTEGRATION.md](OWNER_INTEGRATION.md) and the fallback contract contain detailed routes and pinned owner links. Current lane04 engine evidence is not completed consumer integration.

## Worker ledger, recovery and final integration

At this candidate's preparation, the exact-input [worker ledger](worker-ledger.json) records **90 actual completed contexts/reports in nine waves**. The wave10 lead separately confirmed three created contexts: w091, w094 and w099; seven additional contexts were still to be created. Thus the known creation snapshot is93, with90 prior completions. This document does not claim100 created or completed. Root must use actual returned IDs/statuses, create w100 last after artifacts freeze, and final-seal after all ten wave10 contexts finish. Follow-ups, retries and workspaces never increase the count.

Per-wave ledgers and artifact maps preserve original reports, changed candidates and same-ID follow-ups. The four-slot limit allowed root plus lead plus at most two children; budget targets were advisory because exact context counters were unavailable. w094 spawned no children.

[ENVIRONMENT_RECOVERY.md](ENVIRONMENT_RECOVERY.md) preserves the low-disk sparse checkout, this lane's own temporary-tree move, interrupted signal9 Swift compile, linker failures, repeated resets, recovered original host executable and verified preservation before removal of completed worktrees. The failed local generator was never observed executing. A zero watchdog RSS field meant no process sample, not a measured zero peak. A later reset occurred without a root Swift build, so compiler/memory causation is unproved.

The fourth interruption during wave5 left the executor unavailable. This worker used immutable Git snapshots, in-memory inspection and UTF-8 Git blobs only. No shell, SDK install/probe, build/test, physical-worktree inspection, cleanup, CI polling/rerun or ref mutation occurred. Planned `/tmp/keyfill04-2987b1ee980d/workers/w094` and `/tmp/keyfill04-2987b1ee980d/results/w094` remain **UNCREATED**. Exact-input README/HANDOFF reads returned404 and are retained in the input receipt; this handoff is newly authored, with its first candidate preserved under evidence/w094.

Root's next step is to integrate only reviewed lane documentation/evidence, retain original candidates and raw outcomes, reconcile the final worker ledger, and publish the authorized branch. Root alone may update the queued native receipt when terminal evidence arrives; no duplicate build or workflow change is justified by an unknown queue ETA. Lane20 then performs the owner integration and source-specific gates above. Physical calibration, device behavior, thermals, process/driver memory, manual accessibility and release readiness remain unperformed claims, not inferred results.
