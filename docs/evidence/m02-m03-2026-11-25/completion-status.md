# M02/M03 completion status — 25 November 2026

## Current outcome

**M02 is active and M03 remains dependent on M02; neither milestone is complete.** Full completion is blocked by unresolved CI failures and missing calibrated, physical-device and manual acceptance evidence. All 100 distinct workers completed their initial assignments, with actual reports retained in the [worker ledger](README.md). Three of those workers handled subsequent CI diagnosis and independent reviews. The work ran in batches with at most three workers plus the integration lead.

This report was reconciled at **2026-11-25T17:25:48.256055+00:00**. Published source at preparation is `a27916a1d0f9466a74079e1037d84c26c6621b8a`. The productive application run tests `8fa4399f50554836ce70ec2929a28534f70ba4b0`; Git proves that its application source, tests and primary workflow are unchanged at a279. The later commit changed only the isolated control and supporting records. [Exact source comparison](validation/8fa-terminal/application-source-equivalence.json).

The remaining automated failures and missing physical/calibrated acceptance are recorded below. Successful subsets do not establish a green full workflow or milestone completion. The [protected quality contract](../../QUALITY.md) remains unchanged.

## Engineering work delivered

- **Editing and history:** corrected the iOS 26 slider behavior, preserved edit ownership under reentrant interactions, strengthened exact numeric editing and Undo/Redo, and covered camera-relative additions, mirrored geometry and boundary transforms. Ten separately reported optics workflows retain the original editing/save/relaunch assertions.
- **Rendering and numerical correctness:** added bounded reuse of successful Study frames; aligned SceneKit housing fronts with authored emitter positions; corrected partially illuminated area sampling at grazing angles while retaining the sample budget; and made unsupported-pixel masks explicit in CPU/compute comparisons. Exact-boundary geometry and cancellation behavior have additional regression coverage.
- **Project library and persistence:** added bounded search and saved-rig thumbnails, made colliding project names unambiguous, and preserved full-snapshot recovery semantics. Actual host probes exercise write and rename failures plus interruption around rename. Write/rename failure and pre-rename interruption preserve the prior complete snapshot; post-rename interruption preserves the complete committed candidate. Active identity and unrelated records remain intact.
- **Accessibility:** implemented changes addressing concrete contrast, Dynamic Type and clipping findings from executed audits, including Save/Cancel/exact editing, the history bar, plan labels and grid title. The latest full audits still fail to complete, and manual device acceptance remains outstanding.
- **CI:** separated native build/setup from test execution; corrected the Darwin SDK selection for the host probe; retained required Metal execution; and separated ten optics methods from the remaining studio/export methods without deleting or weakening their actions and assertions. The keyboard-introduction guard was refined, but its latest runtime failure remains unresolved.

The [chronological engineering report](../m02-m03-main-2026-11-25.md) and individual worker reports retain implementation decisions, rejected experiments and earlier failures.

## Latest application execution

[Application run 45649843650](https://github.com/mirzotipi-wq/APP1/actions/runs/45649843650), exact source `8fa4399f50554836ce70ec2929a28534f70ba4b0`:

| Job | Actual result | Evidence scope |
| --- | --- | --- |
| Portable core | 319 Debug and 319 Release tests passed; 35 Python tests passed | Linux; six shared-kernel and eight strict precision fixtures also passed |
| Native simulator | 110 unique tests passed, zero failures/skips; all three required Metal tests passed | Unsigned Debug and Release builds; Intel simulator, Xcode 26.6, iOS 26.5 |
| Room/precision | 5/5 passed | Exact values, Undo/Redo, reopen and room boundaries |
| Studio/export | 10/10 passed | Two export and eight StudioSmoke methods, including sphere/mannequin Study switching |
| Library/reference | Failed and incomplete: uploaded raw log records 6 passes, 4 failures, 1 started without a terminal result | Both full audits timed out; keyboard readiness and active-project status waits failed |
| Studio/optics | 10/10 passed | All ten unchanged editing/Undo/Redo/save/relaunch workflows completed |

The application workflow completed with failure at 17:20:10 UTC. The final uploaded-log accounting is **31 UI passes, four failures and one unfinished method out of 36 started**. Its earlier console-only view is 30 passes, four failures, one unfinished and one unstarted. [Exact workflow accounting](validation/8fa-terminal/workflow-summary.json).

Optics' optional pre-test host capture exceeded its existing one-minute bound. The original workflow allowed that diagnostic to continue; the required ten tests, finalized result export and both uploads succeeded. No test or failure policy was changed.

The source-equivalent a279 application duplicate was intentionally cancelled after the productive run completed, during core and before any native/UI step. [Cancellation receipt](validation/duplicate-primary-a279.json). It supplies no passing CI result.

Current Apple verification uses the Intel simulator fallback. It does not establish current physical-device interaction, ARM RealityKit behavior, calibrated image agreement or device performance.

The library's four failures are both full `.all` accessibility audits (Code=-56), the archived-delete keyboard-introduction readiness check, and the active-project label check in the create/duplicate/rename/switch workflow. The keyboard snapshot contains an enabled q key with a normal frame and no Continue node; it does not record `isHittable` or prove that the original wait passed. The project-switch failure has no captured actual row label. Neither observation establishes data loss or a specific app-state defect.

The library command reached its 32-minute limit. Its terminal console shows ten starts, five passes, four failures and one unfinished method. The later uploaded native log records the guided-rig method passing and the final reference method starting after the timeout annotation, giving eleven starts, six passes, four failures and one unfinished method. Those views are preserved separately. The library result bundle did not finalize, so no complete XCTest summary or extracted failure screenshot is claimed.

The preceding [6f3 run](https://github.com/mirzotipi-wq/APP1/actions/runs/45641483928) completed all 36 UI methods with 33 passes and three failures. Its optics post-relaunch status failure, initial Plan audit timeout and keyboard readiness failure remain historical evidence. [Completed accounting](validation/6f3-terminal-workflow.json).

## Isolated accessibility control

The minimal control is a separate diagnostic app; its result cannot pass APP1's accessibility gate.

At 8fa, its full audit returned in 5.121 seconds with one genuine contrast finding on the Confirm control button. The test correctly failed. The two-color correction was committed in a279 with the same full audit, zero-issue requirement, runtime and time limits. [Original finding and review](validation/accessibility-control-8fa-contrast/original-run-receipt.json).

The repaired control remains unverified:

| Attempt at a279 | Actual outcome |
| --- | --- |
| 1 | Build and boot passed. One selected test started and failed during application launch; readiness and audit were never reached. |
| 2, one bounded repeat | Environment collection exceeded its two-minute limit before build, runtime selection or test execution. The expected test never started. Source checkout is recorded, but the before/after source-hash window was not completed. |

[Attempt 1 receipt](validation/accessibility-control-a279-attempt1/terminal-receipt.json) and [attempt 2 receipt](validation/accessibility-control-a279-attempt2/terminal-receipt.json) retain the distinct failures. No third attempt was requested. Neither the generic launch-denial chain nor the runtime-inventory setup stall establishes a specific code fix or a general platform outage.

## Mandatory acceptance still outstanding

| Gate | Current limit or missing evidence |
| --- | --- |
| M02 rendering | Twelve rights-cleared controlled real scenes, a calibrated comparison method and an actual independent photographer review. Current 3D adapters and ideal Study materials are not physically calibrated portrait rendering. |
| M02 performance | A physical iPhone 13 or agreed baseline, Release build, three-light standard portrait workload: 60 fps target; p95 frame time at most 20 ms over five minutes after warmup; fifteen-minute thermal test; peak resident memory at most 350 MB; no critical thermal state. |
| M03 editing | Complete current editing/library workflow revalidation. Failed readiness/status waits and interrupted coverage remain open. |
| M03 accessibility | Successful current-source automated audits plus manual VoiceOver, Dynamic Type, contrast, non-color cues, numeric editing and Reduce Motion tasks on a real device. |
| Full regression | A complete successful required native/UI run, with the current failures resolved and every required method accounted for. |

Portable analytic/numerical photometry and scoped persistence have passing evidence. The host persistence probes passed all eleven EFBIG checks and three strict interruption/rename-failure scenarios. Those results are not physical power-loss or broad device-matrix certification. Current M03 library workflow failures remain separate from these host probe passes; the broader physical low-storage and release device matrix belongs to M07 and is not added as a new M03 requirement.

One material performance risk is retained: a short paired host benchmark found approximately 17.56–35.10% higher median CPU time for area-light Study frames after the grazing correction. An attempted inlining optimization did not show consistent benefit and was discarded. This measures host Study computation, not presented iPhone frame time; the physical performance gate remains open.

The [external acceptance packet](../../acceptance/m02-m03-external-evidence.md) and [capture manifest](../../acceptance/m02-m03-capture-manifest.json) are prepared, with unrun observations left explicit. They provide the twelve-scene assignments, calibration records, device workload and manual accessibility tasks. Real comparisons may identify further required implementation changes; these are not paperwork-only gates.

## Next executable work

Preserve the exact failing library and control evidence, then reproduce the unresolved readiness/audit failures in a stable Apple test environment with actual state and timing observations. Apply a correction only when the captured failure supports it, retaining every required test and assertion. The current run is complete and its failures remain open; subsequent execution should preserve the same required coverage and source provenance.

Collect the required controlled captures and independent review, physical performance trace and manual accessibility results at the actual tested revision. Repair any measured failures and repeat those affected comparisons. Only then can the corresponding gates and dependent milestones be marked complete.
