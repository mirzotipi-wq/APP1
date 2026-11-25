# f6 studio/export: partial test results, assertion failure and deadline

**Terminal job failure; the required 20/20 result was not obtained.** [Job 139182923449](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523/job/139182923449), run **45604744523**, tested `f6f43dde19be7a554bc5c6924e3239c18b34d1be` on Intel x86_64/Xcode 26.6/iPhone 17 Pro/iOS 26.5.

## Actual coverage and failure

The complete decoded GitHub log and downloaded `native-tests.log` agree exactly on the method event sequence: **16 started; 14 passed; one failed; one was interrupted; four never started.** No skipped outcome was logged. These are partial counts, not a completed-suite summary.

`StudioSmokeTests.testOpticsRepeatability10` failed at `StudioSmokeTests.swift:235`, the `assertStatus("Saved locally")` check **after terminate/relaunch**. Its wait returned `XCTWaiterResult(rawValue: 2)` rather than completed (`rawValue: 1`) at **12:50:49 UTC**; the method finished failed in **145.377 seconds**. The initial save predicate had already matched before termination. An early chat message mistakenly described line 235 as the initial save wait; that interpretation was corrected after reading the exact source and surrounding log.

`testRecipeEditSaveAndReopen` started next. At **12:51:06 UTC**, GitHub reported that the selected-shard action had exceeded its unchanged **40-minute deadline**. The recipe method has no terminal outcome. The four unstarted methods are Settings/3D/simulator AR fallback, studio-guide history preservation, reference-study rendering, and sphere/mannequin switching. The finalized XCTest export then failed because there was no finalized result bundle.

## All ten optics attempts

| Optics workflow | Outcome | Seconds |
|---|---|---:|
| Editing/undo/redo/relaunch | Passed | 152.703 |
| Repeat 02 | Passed | 156.321 |
| Repeat 03 | Passed | 133.304 |
| Repeat 04 | Passed | 144.902 |
| Repeat 05 | Passed | 153.897 |
| Repeat 06 | Passed | 163.887 |
| Repeat 07 | Passed | 246.309 |
| Repeat 08 | Passed | 195.732 |
| Repeat 09 | Passed | 190.834 |
| Repeat 10 | Failed after relaunch | 145.377 |

The two export methods and the camera, corrupt-project, and meter methods also passed. Debug UI build succeeded at **12:10:51 UTC**. No `TEST EXECUTE SUCCEEDED` marker or complete 20-test suite result is available.

## Retained trace and limits of diagnosis

The final optics process, PID **92899**, logged `emitterWidth end` with `model=2.1 tracking=false` at **12:49:28.124574 UTC**. After termination and relaunch, PID **94905** logged `emitterWidth configured` with `model=2.1 tracking=false` at **12:50:24.758182 UTC**. This corroborates the edited width in the relaunched process; it does not prove complete library correctness or explain why the status predicate failed. No disk-save failure or data loss is established by this log.

Slider-log collection completed successfully, and full/compact trace copies are byte-identical. Its stderr contains `getpwuid_r did not find a match for uid 501`. The collection status also records `test_exit_code=0`; **that diagnostic field is not an authoritative successful test result after the external timeout**. The actual assertion failure, GitHub deadline error, absent finalized bundle, and job failure govern this receipt.

The compact artifact contains only three slider-trace text files. No finalized xcresult, screenshot, UI hierarchy attachment, or saved library snapshot is retained in these archives, limiting root-cause classification. The separate build-before-boot candidate is source-reviewed as an ordering-only change; these results do not prove it repairs timing, accessibility, or this post-relaunch failure.

## Artifact integrity and retained files

- Full artifact **15022378061**, **49,026 bytes**, SHA256 `a8a023a346df374b5dc7cb5833d6a5331437e4d569dfa2064f9f7c9d3b5881db`.
- Compact artifact **15022567668**, **4,626 bytes**, SHA256 `f76494c9ee892000b9c53862d5ffde33c81d55ac801da5121e53cefaa80bdbcf`.

Both were downloaded, matched independently computed hashes against GitHub metadata, and passed ZIP CRC validation. Raw archives, extracted files, complete decoded log, **84 exact selected log lines**, focused final-optics trace rows, all method outcomes, source expectations/hashes, terminal job metadata, and receipts are retained outside the repository at `/var/tmp/keyfill-c0abc39c4f18/f6-ui-terminal-triage/studio-export/`.

No repository edit, rerun, cancellation, deadline change, skip, retry or new worker was introduced by this reviewer. The newer `214ca90` run is monitored separately; its eventual outcomes are not inferred from this f6 evidence.
