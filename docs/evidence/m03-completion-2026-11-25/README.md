# M02/M03 completion pass

**Scope:** M02, then M03, under [m02-m03-code-v2](../../acceptance/m02-m03-code.md).
**Baseline:** `916ecb9284747e91cb3840c4776c634d798f1a51` on `main`.
**Current status:** M02 remains complete at the retained75e checkpoint. M03 remains active. Current cd5 native execution failed135/137; completed UI groups passed33/34, and app accessibility plus24 original captures remain pending. No failed or unrun requirement is promoted.

## Current source and actual runtime findings

[Source `cd5b461`](https://github.com/mirzotipi-wq/APP1/commit/cd5b461e9b1e534911ead986bed0a79188e20add) contains the four reviewed intrinsic Text-layout files. [Full CI run45761900201](https://github.com/mirzotipi-wq/APP1/actions/runs/45761900201) retains the complete137-native/35-UI requirement and24 original Default/AXXXL captures. The [repair note](text-layout-repair.md), [source review](workers/w100-text-layout-source-review.json) and [192-input manifest](validation/source-cd5b461/source-manifest.json) remain source-specific records.

The current cd5 portable job has completed successfully. Its [source-specific receipt](validation/source-cd5b461/ci-core/summary.json), [raw job log](validation/source-cd5b461/ci-core/core-job.log), [benchmark payload](validation/source-cd5b461/ci-core/benchmark-from-ci.json) and [persistence reports](validation/source-cd5b461/ci-core/persistence-reports-from-ci.json) record 359 Debug and 359 Release tests, 92 tooling tests, twelve exact image matches, six parity and eight precision fixtures, the complete 8/12/4 benchmark inventory, and actual ext4 EFBIG/interruption/rename-EIO checks. This run used an AMD EPYC 9V74 host; earlier Xeon timings are not reused. [Worker 058](workers/w058-cd5-core-counts-images.json) independently reconciled all 359 started/pass pairs per configuration and the twelve original image hashes. [Worker 059](workers/w059-cd5-core-numerics-probes.json) independently reconciled all numerical, benchmark and real persistence output. The [method ledger](validation/source-cd5b461/ci-core/method-accounting.json) and [decoded-log hash receipt](validation/source-cd5b461/ci-core/log-receipt.json) retain root's separate reconciliation. The separate Apple/UI findings are recorded below.

| Current cd5 check | Actual result |
|---|---|
| Unsigned Debug/test bundle and Release app builds | Passed |
| macOS portable package |359 methods started and passed |
| Required native methods |135 passed,2 failed;137 distinct starts and terminal events;7 assertions in the two failed methods |
| Actual Metal methods |All3 passed; inline post-command checker unrun after xcodebuild exit65 |
| Resolved palette contrast |116 distinct pairs passed and independently recomputed |
| Actual APFS persistence probe |Passed EFBIG/control/exact-byte/fresh-process checks |
| Studio/export UI |10/10 passed |
| Library/reference UI |9/9 passed |
| Studio/optics UI |10/10 passed |
| Room/precision UI |4/5 passed; first room-status check failed |
| App accessibility and24 original captures |Pending |

The [native receipt](validation/source-cd5b461/native-execution-summary.json), [raw native log](validation/source-cd5b461/native-job.log), [exact method ledger](validation/source-cd5b461/native-method-accounting.json) and [worker100 independent runtime review](workers/w100-cd5-native-runtime-review.json) preserve the failed result. All previous134 native methods passed again. New codec/gating passed; the two hosted methods failed with callback-time native frames were still at zero origin and in-process public accessibility traversal returned no elements. The first positive Default iteration threw before AXXXL, growth or the8-point negative fixture: those later substages were unrun. The diagnostic warm-up also actually failed despite its continued wrapper conclusion.

The [UI progress receipt](validation/source-cd5b461/ui-execution-progress.json) and four original logs retain33 passes and one failure among34 completed methods. Every previous75e library/studio-export failed method now passes freshly; no causal product fix is claimed. The room failure occurred after exact modifier editing, Undo, Redo and Save passed, at the first status predicate after opening the sheet. Later room/crossing checks were not reached. [Worker039's review](workers/w039-cd5-room-status-review.json) and the [original attachment receipt](validation/source-cd5b461/room-status-original/receipt.json) retain the distinction: the224-byte TXT contains only the query chain, not an actual label or hierarchy. Cause is unresolved.

## Focused native harness correction

Diagnostic [source03cfd3c](https://github.com/mirzotipi-wq/APP1/commit/03cfd3c90d2a45e96ee03ad71234363dfc899be7) is executing [run45768421649](https://github.com/mirzotipi-wq/APP1/actions/runs/45768421649). All187 build inputs match cd5 except two reviewed test files. Native observation now retains actual UIView references until layout finishes and preserves strict physical-pixel equality, actual font sizing, Default/AXXXL growth and the undersized8-point negative fixture. Ordinary Save/Cancel/Done leaf Button semantics are checked through external immutable UI snapshots in the existing complete library flow. No production or app-accessibility source changed.

[Implementation](workers/w038-native-harness-correction.json), [normal-value refinement](workers/w038-normal-action-value-correction.json) and [independent review](workers/w100-native-harness-source-review.json) are retained. The [initial workflow review](workers/w097-probe-harness-workflow-initial-review.json) identified a working-file mode/type gap; the [corrected review](workers/w097-probe-harness-workflow-corrected-review.json) verifies all190 admitted files and exact copies of the normal native and library job steps. Both workflow versions and the concrete request are retained under diagnostic-sources. Source review establishes no runtime pass. Full main validation remains required.

The conditional [repeat-stall plan](workers/w050-repeat-stall-diagnostic-plan.json) was not executed because the earlier large-library and AR failures now passed. The updated100-context ledger clarifies that017/018 returned real JSON while their attempted local-file creation was failed/unconfirmed. No additional worker contexts were counted.

The completed-source sections below describe the preceding75e run and retain its failures. Results are not transferred to changed App/test files.

## Completed 75e core verification

| Check | Actual result |
|---|---|
| Swift Debug package tests | 359 passed, zero failures |
| Swift Release package tests | 359 passed, zero failures |
| Python tooling tests | 92 passed |
| Native/UI Swift syntax, shard inventory, app icon and privacy manifest | Passed |
| Synthetic image matrix | All 12 images generated with zero unsupported pixels; every SHA-256 matches the retained reviewed 5d8 image |
| CPU/shared Float32 kernel fixtures | All 6 passed; maximum channel difference 1, largest mean 0.0000542535, no invalid-mask mismatch |
| Strict precision fixtures | All 8 passed; maximum channel difference 0 and exact invalid masks |
| Optimized benchmark | All 8 frame workloads, 12 observed cancellation probes and 4 visibility workloads; 7 measured samples per frame/visibility workload |
| Linux persistence fault probes | EFBIG, before-rename interruption, after-rename interruption and rename-EIO checks passed with fresh-process reopening |

The source-specific [core summary](validation/source-75e827f/ci-core/summary.json), [original job log](validation/source-75e827f/ci-core/core-job.log), [raw benchmark payload](validation/source-75e827f/ci-core/benchmark-from-ci.json), and [atomic-write/interruption reports](validation/source-75e827f/ci-core/persistence-reports-from-ci.json) retain exact details. Numeric records were copied from actual CI output; no test or timing result was inferred from source review.

This run used Ubuntu 24.04.5, Swift 6.4.2, Python 3.12.3, x86_64 Intel Xeon 6975P-C, and ext4. Timings are short host diagnostics. The six parity cases include the deliberately unsupported near-field case; it is separate from the twelve fully supported image fixtures. Actual Apple/Metal results are tracked separately.

## Previous75e native checks and UI outcome

[M02 revalidation](m02-revalidation.md) is complete at the current source. [The native receipt](validation/source-75e827f/native/verification.json) records **134/134 native methods passed**, both new slider reentrancy regressions, all three actual Metal methods, 359 macOS package tests, both unsigned simulator builds and finalized XCTest export. All 116 contrast pairs passed: 80 text pairs have a minimum 5.41294844133131:1 and 36 non-text pairs a minimum 4.272705279813226:1. The actual macOS APFS EFBIG/control/reopen probe also passed.

The native simulator warm-up itself reported a recovery-preflight timeout. That preparatory diagnostic remains failed in the raw log; the subsequent native test command, exact accounting and finalized export independently succeeded.

| Current UI shard | Result at this checkpoint |
|---|---|
| Room and precision | All 5 passed, including the formerly failed resize workflow |
| Studio optics | All 10 passed |
| Library and reference | 8 of 9 passed; large-library relaunch readiness failed |
| Studio and export | 6 of 10 passed; four failures retained |
| App accessibility | Failed at Default Save child-text lookup; AXXXL not reached |

The current [library log](validation/source-75e827f/library-reference/job.log) proves that create/duplicate/rename/switch/relaunch now passed. Its different large-library method loaded, edited, saved and browsed successfully, then failed at relaunch readiness. The [original screenshot, hierarchy and receipt](validation/source-75e827f/library-reference/original-capture-review.json) show the new process still displaying Opening projects with disabled actions. No source root cause has been demonstrated; this failure is not renamed a successful workflow. Remaining required checks continue.

The [studio/export receipt](validation/source-75e827f/studio-export/verification.json) records all ten methods started: six passed and four failed. The failed boundaries were initial export-control readiness, the PDF Close control's AX query, the AR status AX query after successful Settings/3D work, and the following app launch failing to terminate the prior process. The [five original diagnostic captures](validation/source-75e827f/studio-export/original-capture-review.json) were independently byte/hash checked; root viewed both PNGs. The three text files contain query chains only and establish no product cause. The warm-up and pre-UI host diagnostic also failed; those observations do not turn failed required tests into passes.

The [original host diagnostics](validation/source-75e827f/studio-export/host-diagnostics/receipt.json) also show delayed host commands before UI execution: `vm_stat` took 54.692 seconds and `ps` timed out after 7.53 seconds; the diagnostic step itself timed out. The later host sample completed normally. The host-step API conclusion is success because `continue-on-error: true` allowed execution to continue; its raw log still records the timeout. These are observed host delays, not proof of the cause of the app's later failures.

Both full/compact failure archives were SHA-256 verified and preserved in independent Actions runs before any retry: [library receipt](validation/source-75e827f/archive-preservation/library.json) and [studio/export receipt](validation/source-75e827f/archive-preservation/studio-export.json). The original failed results remain intact. The preservation workflow uses a cooperative 480-second transfer check and a hard 12-minute job timeout; it does not promise a strict 480-second overall deadline.

## Current accessibility failure and measurement repair

The [complete UI summary](validation/source-75e827f/ui-execution-summary.json) and [original-image/hierarchy receipt](validation/source-75e827f/app-accessibility/original-review.json) retain the terminal result. Worker 100 independently reconciled all 35 methods and actually viewed all 11 captured PNGs: nine required Default states plus two failure diagnostics. Three remaining Default states and all twelve AXXXL states were not reached.

Save is visibly above the keyboard and passed the parent control's exact label, enabled, hittable, 44-point target and containment assertions. The full original hierarchy proves Save, Cancel and Done are leaf accessibility Buttons, without child StaticText nodes. The next query assumed such a child existed. The integrated measurement repair uses actual intrinsic Text layout with explicitly identified test instrumentation; the existing font-size, text-growth, control and original-image requirements remain. No corrected test execution is claimed yet.

## First repaired-source run: retained failures

[Run 45745699007](https://github.com/mirzotipi-wq/APP1/actions/runs/45745699007), at source `7b91c1a`, completed with a failed workflow conclusion. All 132 native methods and all ten optics workflows passed. The complete UI inventory started: 29 of 35 methods passed and six failed.

| UI shard | Passed / required | Remaining failure in that run |
|---|---:|---|
| Studio optics | 10 / 10 | None |
| Room and precision | 4 / 5 | First room-width draft remained the placeholder after typing |
| Studio and export | 7 / 10 | Screenshot RPC timeout; initial status wait; AR-sheet accessibility-query timeout |
| Library and reference | 8 / 9 | Duplicate-name sheet accessibility-query timeout after successful creation |
| App accessibility | 0 / 1 | Default-size project-name heading was rejected by the test's covered-navigation boundary |

The [execution summary](validation/source-7b91c1a/execution-summary.json) and full job logs retain each actual started/passed/failed event. The native run includes the three real Metal methods; a host kernel harness is not counted as Metal execution.

The [original accessibility captures and review](validation/source-7b91c1a/app-accessibility/original-capture-review.json) prove the heading was visible: its frame was y203.8...224.1, below its own New project navigation bar ending at y142. The test instead used the covered Projects large-title bar ending at y229.5. The actual keyboard input/assistant surface began at y539, above the keyboard key-frame boundary at y583. Both original PNGs and both original text hierarchies were retained after independent byte-length and SHA-256 verification.

## Implemented corrections awaiting full rerun completion

The initial repair replaced the measured 36-point library Done action with an adaptive action owning at least 44 points, verified its child text and growth, removed an invented eight-point scroll margin, separated initial library launch readiness from normal interactions, and budgeted complete optics and two-size execution without dropping required methods.

The current repair scopes navigation boundaries to ancestors of the target content, scopes fixed bars to that navigation owner, and excludes the actual keyboard input surface. Full-frame containment, actual text metrics, hittability, disabled-state assertions, the 44-point minimum and all twelve required captures at each text size remain.

Room input now waits for a usable numeric keyboard and reveals the actual field after the keyboard transition. It types once and retains the exact draft equality, Set, geometry and keyboard-dismissal assertions. Failure-only screenshot/hierarchy and bounded geometry output preserve a future failure. This is a synchronization candidate, not proof of the earlier placeholder's cause.

The [original Duplicate failure diagnostic](validation/source-7b91c1a/library-reference/original-hierarchy-review.json) was also recovered by its exact exported attachment identity. It reports an unusable infinite-origin/zero-size ancestor chain and an old name; it does not establish a visible sheet or product cause. The original bytes and independent SHA-256 check are retained.

Status polling uses one immutable snapshot per attempt, with the existing exact label and deadline. Export captures use the original screen image after the existing document/share assertions. The AR and duplicate-sheet query failures remain historical failures until their full workflows pass; source review has not established a product cause.

Two production edge cases found by independent workers were corrected:

- A binding read that synchronously retires or replaces a slider session cannot reopen the retired history owner. Two native regression methods were added.
- U+2800 alone does not count as visible name content. Embedded Braille spacing remains intact; legacy stored names and identities are preserved while labels use a readable fallback. Two core methods and existing native presentation fixtures cover this policy.

The required current inventories remain **134 native methods and 35 UI methods**. All 134 native methods have passed. All 35 UI methods completed: 29 passed and six failed. Only nine of 24 required captures were reached. Original Default/AXXXL coverage remains incomplete.

## Review and provenance

The owner requested 100 distinct agents. All 100 have been created in available batches: six initial specialist workers, one coordinator and its 93 unique children. The [initial six reports](workers/initial-six-reports.json), [93-child checkpoint ledger](workers/checkpoint-93-ledger.json) and [matching report aggregate](workers/checkpoint-93-reports.json) preserve actual assignments and returned work. All 99 specialist initial assignments are complete; the coordinator remains active. Worker 100's native and current UI/image evidence reviews are complete; its UI review confirms the failed/incomplete outcomes. Followups reuse the same context and never increase the count. Source-only reviews do not establish runtime passes.

The local executor became unavailable during an additional local Swift check. That unfinished check has no claimed result. Integration continued through authenticated GitHub Git operations and actual CI. A bounded, read-only [evidence review workflow](../../../.github/workflows/review-xctest-evidence.yml) verifies original run/artifact source before exposing selected original screenshot/hierarchy bytes. A temporary diagnostic branch kept the previous main run intact; the normal iOS source-push trigger was restored before publishing the current source.

Earlier unsuccessful results, including the preceding `5d8b065` run, remain preserved. M04–M07 stay pending. These milestones make no physical calibration, device-performance, manual VoiceOver, platform-audit, release-candidate or App Store publication claim.
