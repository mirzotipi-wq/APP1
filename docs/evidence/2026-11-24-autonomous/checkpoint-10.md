# Asynchronous library and native evidence completion — checkpoint 10

Integrated main is **`5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`**, exact tested tree **`aaf52e62fff970cdc55f5908326523e58a1cf394`**, parent **`4d531e5dc669e4eab852b766cdb9739a5d70c67d`**. The integration lead pushed and read back the source; local Git has the same SHA and tree. Fourteen commits have been pushed since the session baseline `968e4bb1b3932c5140b735b404c9538d909bab23`: ten implementation sources and four evidence-only checkpoints. This report does not count a future documentation commit.

## Integrated scope and independent correction

| Task | Implemented change | Evidence and remaining acceptance |
| --- | --- | --- |
| **P20 / T38 — asynchronous library** | Move complete read, migration, command mutation/validation, compare-and-save, encoding and atomic replacement to a stable serial actor. Reserve each parent-owned operation before launching its task; capture expected library, scene, project identity and generation. | Focused actual worker/helper tests and independent review passed. Apple SDK/native worker execution subsequently passed; presented SwiftUI lifetime and native responsiveness remain pending. [Author report](async-library-correction.md), [independent review](async-library-review.md). |
| **P17 / T39 — room-status follow-up** | Give the static room status the same explicit visible and accessibility text; preserve bounded element observations in failure logs. Retain original values, expected counts and deadlines. | Source review and syntax checks passed. Historical source9 room tests later passed without this change, so their pass is not evidence that this follow-up fixed the earlier failure. [Review](room-status-native-followup.md). |
| **P08 / T40 — verification completion** | Preserve the active main workflow while the latest pending revision waits; retain superseded-run cancellation on other branches. | At the source10 push, source9 remained active and source10 became pending. This is an observed scheduler outcome, not a native test result. [Policy and bounds](ci-completion-policy.md). |

The library worker initializer performs no I/O. The complete expensive transaction moves off the UI actor, rather than only its final write. Core storage formats, process-wide transaction locking and expected-revision comparison remain unchanged. Busy and generation checks guard actual mutation paths as well as the UI. Ordinary saves preserve scene history, selection and mode; metadata edits preserve history; successful project switches and explicit reload/recovery adopt the intended replacement. Loading recovery candidates only lists choices and cannot replace the unsaved editor.

Provider reads remain cancellable before commit. Once the parent accepts an authoritative commit, a child sheet's cancellation or disappearance cannot suppress receipt reconciliation. Name submission awaits persistence and retains the entered name on failure. UI tests now wait for real saved/enabled state at asynchronous boundaries while retaining their original data, Undo, relaunch and timeout expectations.

Independent review found a real regression in the first actor candidate: missing or malformed UI-test UUIDs lost the `-ui-testing` launch intent and could load and overwrite a normal temporary user library. The unchanged independent probe produced **two violations, exit 1**. The corrected worker retains launch intent independently of UUID parsing, always selects the test directory for test launches, and keeps fixture injection valid-UUID-only. The same probe then produced **zero violations, exit 0**. A new DEBUG test verifies unchanged normal-library bytes. Original failed evidence and historical 14/12 focused logs remain preserved alongside the corrected results. [Before](async-library-isolation-before.log), [after](async-library-isolation-after.log), [unchanged probe](async-library-isolation-probe.swift).

## Exact local verification

The lead tested the immutable `cycle10-source` export with **Swift 6.4.3 on Debian 13 x86_64**, then matched that tested tree to the pushed source. Record maintenance in this checkpoint did not rerun those implementation suites.

| Verification | Actual result | Scope |
| --- | --- | --- |
| Complete portable Debug | **251/251**, zero failures; **30.075s** XCTest aggregate | Exact source10 LightingCore suite |
| Complete portable Release | **251/251**, zero failures; **9.169s** aggregate | Same source, optimized configuration |
| Python checks | **28/28**, **1.062s** | Evidence, CI and shard validation |
| Native Swift syntax; state, shards, source icon/privacy and YAML | Passed; syntax parse exited 0 without diagnostics | Structural/syntax verification; not Apple SDK type-checking |
| Focused actual actor/helper tests | **15/15 Debug, 12/12 Release** | Separate byte-identical app/test sources using real LightingCore; three DEBUG-only fixture/isolation methods explain the difference |
| Apple SDK build and native methods, later source10 result | **Both unsigned builds;65/65 native methods passed**, including15 actor cases | Complete Apple-runner logs now retained; see later observation below |
| Current native UI acceptance | **Unverified** | Library/room running and studio queued at11:54; no finalized complete UI result |

Other host work overlapped the complete suite runs. **Their elapsed times are not performance measurements** and cannot support a comparison with earlier cycles. The focused tests use controlled barriers to verify MainActor progress, duplicate reservation, cancellation ordering and exact-once receipt adoption, including a real atomic write before delayed receipt delivery. They also exercise real temporary-file CAS failures, corruption, recovery capacity, first-save/history policy and a supported valid file exceeding **8,000,000 bytes** within the 8 MiB limit.

Those checks are not a native latency benchmark. The prior Linux/tmpfs median load **319.649 ms** and save **669.938 ms** remain a motivating storage baseline; no pre-change native UI-blocking trace or before/after device speedup was measured for this packet. The [author report](async-library-correction.md) states those limits explicitly.

Static inventory at this exact source is **65 authored native XCTest methods** and **23 UI scenarios across six classes**. The65 native methods subsequently all passed in actual Apple execution; the23 UI scenarios remain an authored inventory while the shards run. The unchanged portable count is expected: the 15 new operation tests belong to the app's native target, with the new large-library scenario in the UI target.

## Current workflow and historical native evidence

[Current workflow 45383556829](https://github.com/mirzotipi-wq/APP1/actions/runs/45383556829), associated with exact source `5cd7eb4`, was **pending at 11:22:40 UTC on 2026-11-24**. Source9 workflow45377378521 remained active after this push. The completion policy therefore preserved the active main run in this observation; it does not guarantee the next suite will pass. At that initial observation, all source10 native gates remained unverified.

At the lead's fresh **approximately11:47 UTC** observation (clock read11:46:40 UTC before the query), source10 was **active**. Its core job138416296344 completed success, starting11:37:05 and ending11:39:05 UTC. **Remote core method counts have not yet been extracted**; the local251/251 per configuration and28 Python remain separate. Native job138417363792 was running unit tests; library138417363841 and room138417363881 were running selected UI; studio138417363754 was queued. These step/job states do not establish completed native counts or gate passes.

A single later jobs fetch during **11:54:07–11:54:14 UTC** found source10 core and simulator completed success. Complete retrieved logs establish **251/251 remote Debug8.561s,251/251 Release4.530s and28 Python0.283s**, both unsigned Debug/Release builds, and **65/65 native methods**, zero failures,24.121s aggregate. All **15 ProjectStoreOperationTests** actually passed, including the three DEBUG-only fixture/isolation cases. The simulator job completed11:54:08 UTC; `TEST SUCCEEDED` was logged11:53:20.732617 UTC. **The source10 native_build gate now passes; persistence_smoke and complete UI regression remain unverified.** Library/reference and room/precision were still running selected UI, and studio/export was queued. No further poll was made. [Actual source10 report and artifact metadata](native-result-5cd7eb4.md), [core log](5cd7eb4-core.log), [native log](5cd7eb4-native-job.log).

The native logs retain skipped AppIntents metadata extraction and artifact-action Node deprecations, plus expected diagnostics from explicit document cancellation/error fixtures; no Swift source compiler error or failed native method was found. This is Apple SDK/native worker evidence, not a device latency benchmark or proof of presented sheet/gesture behavior. Earlier pending observations remain dated records.

Historical source **`3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`** has its own finalized results:

| Source9 result | Actual outcome | Source-specific boundary |
| --- | --- | --- |
| Core job138388771652 | **251/251 Debug, 251/251 Release, 28 Python**, original six and strict eight host-kernel fixtures | Remote source9 counts; source10 core job succeeded but its counts were not yet extracted |
| Native job138390492865 | Both unsigned builds; **50/50 native methods**, zero failures, 8.582s aggregate; job success at11:01:56 UTC | Includes all eight adapter, three spatial-preview and seven renderer methods; simulator evidence |
| Library/reference job138390492888 | **8/8 UI scenarios**, zero failures, 629.600s aggregate; job success at11:14:42 UTC | Six library and two reference methods, including full-capacity confirmation/relaunch and stale-save recovery; previous synchronous library |
| Room/precision job138390492826 | **5/5 UI scenarios**, zero failures, 1211.802s aggregate; job success at11:23:14 UTC | Both room methods and all three precision methods passed; this source lacks the source10 explicit-status-label/diagnostic change |
| Studio/export job138390492855 | **8/9 scenarios passed; all9 completed**, one failure,700.048s aggregate | Original optics Undo expected0.6m, observed1.3m; both export scenarios and all other studio methods passed |

**Final source9 workflow result: failure**, updated_at `2026-11-24T11:37:03Z`. Across the three completed UI shards, **21/22 scenarios passed**. The sole failure is `StudioSmokeTests.testOpticsEditingUndoRedoAndRelaunch`: at line87, the original Undo assertion requires **0.6m**, while the actual readout was **1.3m**. The failed method completed in58.181s. `TEST EXECUTE FAILED` is recorded at11:35:57.425 UTC. This is a genuine completed assertion failure, separate from source6's timeout/intermediate-width result. All eight adapter unit methods passed at source9, demonstrating that their model coverage did not establish the real dragged-control contract. No internal callback trace or root cause is claimed. [Complete studio job log](3b2a4ce-studio-job.log).

Both export methods passed (76.167s and147.938s), along with camera, corrupt-storage, meter, recipe, actual study-frame and bust-switch methods. Full studio artifact14915129098 is119,983,659 bytes, reported SHA-256 `4ca435e9772f6d6fdc84044284d1bb44d30a23330420a4020ec87f11c6394a18`; compact artifact14914919665 is2,423,568 bytes, SHA-256 `3f592e8bd44c8adc81e7f7ce80adcbfc6eefad78b3c6a7ed7da97224c024b6e7`. The lead actually downloaded and verified the compact digest/CRC. Although that compact archive contains no optics PNG, later bounded full-artifact extraction recovered the original failure recording and synthesized-event archive. Root and a separate reviewer inspected sampled frames: one pointer drag, later1.3m and gray history arrows. The [limited studio visual report](source9-studio-visual-review.md) also records inspection of two genuine export screens. These observations motivate an unfinished-edit/ineffective-Undo hypothesis; they do not establish native internal callback ordering or that an Undo command executed.

The room log records the two methods at186.290s and454.246s, and the three precision methods at137.295s,198.907s and234.714s. `TEST EXECUTE SUCCEEDED` appears at11:21:48.842 UTC. These are actual completed method results, superseding the earlier observation of successful steps with an unavailable full log. Source8's initial room-status failure remains unexplained: source9's pass occurred **without** T39 and cannot be attributed to that later change. [Source9 report](native-result-3b2a4ce.md), [complete room log](3b2a4ce-room-job.log).

The frozen [source9 visual review](source9-library-visual-review.md) inspected four genuine retained simulator PNGs from verified artifact14913024949. It confirms the three Projects count/Open captions at **21:1** in that captured light appearance, replacing earlier approximately1.88:1/4.00:1 samples. The recovery image shows a saved four-light project. It also retains an unresolved **KF-036 / P2 diagram-legibility issue**: `Light 1` partly overlaps the nearby `Fill` marker. That observed label issue is separate from the passing recovery method; it is not evidence of a touch-target failure. This limited visual review is not whole-screen accessibility, VoiceOver, Dynamic Type, dark-mode, device or source10 approval.

Historical source8 `816e712` still has both unsigned builds and42/42 native methods alongside a real room-status failure and interrupted UI methods. Source6 `ff8b683` remains native40/42, library/reference7/8, room/precision4/5, and studio/export eight completed methods with four passes/four failures plus an interrupted bust-switch scenario. Their failed assertions, timeouts and incomplete result bundles are retained. No later pass rewrites an earlier failure or certifies a newer revision.

## Counts, open gates and next work

This completes **20 substantive packages, 40 actionable tasks, ten exact-source local integration cycles and 14 pushed commits**. Actual workforce remains **61 specialist agents plus the lead**: the original 60 scheduled workers and the already recorded SceneKit child reviewer. Reusing the history author and iOS reviewer created no additional agents. [Session ledger](session-ledger.md).

The separate **KF-025 candidate remains outside this source and these totals, on HOLD**. It corrects12 false zeros and passes259 optimized tests plus original six/strict eight host checks, but the independent continuity probe confirms a **4.43449% internal-cell Double linear-light jump across a2e-8 cut change** around0.6. Baseline and independent Simpson values vary smoothly across those same points. This is a numerical counterexample, not observed native flicker. Noisy paired host timing also fails to establish acceptable ordinary-path cost. The [report](grazing-study-report.md), [independent review](grazing-study-review.md), [held patch](grazing-study-candidate.patch) and [raw continuity probe](grazing-study-raw/grazing-study-continuity.log) preserve both positive and failed evidence. No production renderer or completed-task change is counted.

KF-036 plan marker/caption work is an **unintegrated isolated candidate** based on5cd7eb4. Its six focused methods passed in Debug and Release, and syntax parsing passed; independent review approved the candidate. The manifest and raw logs remain under `verification/plan-label-candidate` in the shared workspace. It is now independently approved and applied to the working tree, uncommitted for the next source packet. Native SDK compilation, actual crowded/large-label/narrow views and accessibility/selection behavior remain unverified. It adds no completed task, package, cycle or pushed commit.

M01 remains active with persistence_smoke outstanding after the source10 core/native_build passes. The existing **20 evidence-point floor** remains tied to its prior source/allocation; it is not a completion percentage, a new overall score or a release claim. Current native persistence/editing/regression, physical performance/thermal/accessibility, calibrated photographic scenes, actual provider/share behavior, reference inference, AR, StoreKit, customer validation, signed distribution and owner approval remain open. No protected contract was changed.

Next, inspect finalized source10 UI results when available, especially first-save callback refresh, large-library save/relaunch, provider cancellation versus commit adoption, full-capacity recovery and room status. Diagnose the actual source9 optics Undo failure with the original0.6m assertion retained. Keep KF-025 held and KF-036 separate until their own review/acceptance and integration.

## Raw-log identities

| Retained file | SHA-256 |
| --- | --- |
| [cycle10-debug.log](cycle10-debug.log) | `1e001fb53573f0bb7543488e1ccc57a98545c28bd9c2327defa8a55b3a845e5d` |
| [cycle10-release.log](cycle10-release.log) | `ca00e9989cca7bd7f8c2ffb95c4b185e5b95f4d8ff8e5fc99ae567bd9ce80762` |
| [cycle10-python.log](cycle10-python.log) | `9281327a67d592cb7a92122c4ead211ebb02959407ba5377e1e588ca054a11a2` |
| [cycle10-native-parse.log](cycle10-native-parse.log) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` — empty output, observed exit0 |
| [async-library-isolation-debug.log](async-library-isolation-debug.log) | `a67501c94af19a2cbf4d6550934598f49cf49b607500e1c100e43ae31fdc3ce3` |
| [async-library-isolation-release.log](async-library-isolation-release.log) | `2bb6855fd71a6d229fb4b82be7e2f2498533d477bebda78793ee6befdaa68cc2` |
| [5cd7eb4-core.log](5cd7eb4-core.log) | `e9d721b4b818936b39e7fb1f9857f27eb5ec7692396da4c19e707738a8d6ceba` |
| [5cd7eb4-native-job.log](5cd7eb4-native-job.log) | `d4c2f751f371b5c7305e43866c08dbfa85f54ec79f33324cac157f4431fea8a3` |
| [3b2a4ce-core.log](3b2a4ce-core.log) | `650e827547f46b5638f0d7717a71afdce56a6da0fac0937d27560813749b65ee` |
| [3b2a4ce-native-job.log](3b2a4ce-native-job.log) | `16a2996ef9bef2b0abaf053456f9d7cd9db66510ecd584c98cbd1831851c7911` |
| [3b2a4ce-library-job.log](3b2a4ce-library-job.log) | `b577e6d9d1c5c974d01727461342acd5b0d2c6adae36777d04f3f32a71a98c08` |
| [3b2a4ce-room-job.log](3b2a4ce-room-job.log) | `f2e8a9a91907fe7abbdaefb97386534ca986ea4ecf075a8bcded3472ff913e2a` |
| [3b2a4ce-studio-job.log](3b2a4ce-studio-job.log) | `83b475f36d0a12798f2af751e1b647c7a52c7773972838d6d48b458ba95b7a7b` |

The frozen visual report hash is `aac560da76595d1dbf37d729097866d21e5c77e43f18b392f9ca045ec8d19595`. Image and artifact identities remain in that report. Core/actor logs, simulator artifacts and screenshots have distinct scopes; none establishes a signed physical-device build or release readiness.
