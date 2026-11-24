# Source 10 final studio/export result

**Actual result: failed and incomplete.** At source `5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`, all nine studio/export scenarios started; eight completed, with **seven passes and one optics failure**. Sphere/bust switching was interrupted by the existing 32-minute test-step deadline. Its log continued to record actions at the deadline; this evidence does not establish a hang or deadlock.

Workflow [45383556829](https://github.com/mirzotipi-wq/APP1/actions/runs/45383556829) and studio/export [job 138417363754](https://github.com/mirzotipi-wq/APP1/actions/runs/45383556829/job/138417363754) finalized **failure at 12:38:51 UTC on 2026-11-24**. The direct final observation was at **12:39:52 UTC**. The exact source tree is `aaf52e62fff970cdc55f5908326523e58a1cf394`. These are historical source-10 results, not acceptance of source 11.

## Completed methods

| Method | Actual result | Reported seconds |
| --- | --- | ---: |
| `testExportPreviewOpensWithoutSavingOrChangingScene` | Passed | 284.006 |
| `testFullLibraryCanPrepareUnsavedEditableCopyWithoutSavingOrChangingHistory` | Passed | 306.864 |
| `testCameraFocalLengthUndoAndRelaunch` | Passed | 186.019 |
| `testCorruptProjectBlocksSavingAcrossRelaunch` | Passed | 50.271 |
| `testMeterBalanceSaveUndoAndRelaunch` | Passed | 251.235 |
| `testOpticsEditingUndoRedoAndRelaunch` | **Failed** | 65.601 |
| `testRecipeEditSaveAndReopen` | Passed | 87.470 |
| `testStudyRendersActualReferenceFrame` | Passed | 41.657 |
| `testStudySwitchesBetweenSphereAndMannequinWithoutEditingScene` | **Started; interrupted, no method result** | No completed duration |

The eight completed method durations sum to **1,273.123 seconds**. This is a calculated sum, not an XCTest final suite aggregate. The two export methods have their own completed suite aggregate of **590.870 seconds**. These runner observations are not application latency or device performance measurements.

The only completed assertion failure is the original `StudioSmokeTests.swift:87` width comparison: **observed `2.25 m`, expected `0.6 m`**. It appears in the streamed log at `12:33:19.797547Z`; the method failed after 65.601 seconds. The expectation was retained. No native callback trace or control-enabled observation establishes the internal cause or proves which history action executed. Source 9's earlier `1.3 m` failure remains a separate observation.

## Deadline and final observable actions

The UI bundle build succeeded. The selected UI step began at `12:03:59Z`; the first test's own start timestamp is `12:14:20.297`. These timestamps show substantial setup before the first scenario, without attributing that delay to a particular application operation. The complete decoded job log explicitly reports at `12:36:12.630748Z` that the selected UI action timed out after **32 minutes**. The step metadata records completion at `12:36:12Z`.

The last completed method was `testStudyRendersActualReferenceFrame` (41.657 seconds). The last started method was sphere/bust switching at `12:35:33.434`. Its streamed actions show a rendered-bust check, the named `Studio-mannequin-study` attachment, Undo and unsaved-status lookups, and then **Tap Sphere at test time 39.09 seconds**, logged at `12:36:12.591496Z` immediately before the timeout message.

The separately retained `native-tests.log` continues beyond streamed stdout: it records Sphere event synthesis, the `Rendered neutral sphere and panel` predicate and image lookup, then **Find the Undo button at test time 43.64 seconds**. There is no completed method, teardown, final `StudioSmokeTests` aggregate or successful test-run footer. Do not treat those intermediate actions as a complete bust-switch pass. Do not infer an actor, renderer or gesture deadlock from the job deadline.

## Result bundle and artifact integrity

At `12:36:13.023263Z`, export explicitly failed with **“No finalized XCTest result bundle; see native-tests.log.”** The complete-job cleanup later terminated the orphaned `xcodebuild` and `tee` processes. The compact-attachment upload step reported success but warned that no matching files existed; no compact studio artifact was present in the retrieved artifact list.

The actual small studio artifact **14920422892** was downloaded once. Its **29,629-byte** size, complete archive SHA-256 and every ZIP-entry CRC were verified. It contains exactly six files, all retained unchanged under [artifact/](artifact/): `macos-environment.log`, `metal-toolchain.log`, `xcodegen-version.log`, `simulators.json`, `native-tests.log` and `native-ui-build.log`. There is **no finalized xcresult, attachment manifest, screenshot or recording** in this archive. A logged attachment name alone does not supply an inspectable image.

| Retained evidence | Bytes | SHA-256 |
| --- | ---: | --- |
| [Complete decoded job log](5cd7eb4-studio-job.log) | 474,504 | `bb6337e6b0b2a556a48175b01a8de93c5d526b42df19479bd2433090bc7a99fc` |
| [Original artifact ZIP](source10-studio-evidence.zip) | 29,629 | `4df1c88d4b41f0c993c1e06eb0962012cba4c6fad4dda5fb818110761146e156` |
| [Artifact test log](artifact/native-tests.log) | 76,503 | `1c52a61d5a5c9b9a1f79d06bcc240850c8d4732256926f3f77296ff2dde330ac` |

The [metadata response](metadata.json) retains the exact run/job/step identity, artifact metadata and source-11 transition. The [retention manifest](manifest.json) lists every retained file's size and SHA-256. The decoded full log retains its original UTF-8 byte-order mark. Earlier retrieval while the job finalized returned `BlobNotFound`; the later complete log above was saved without filtering or replacing the artifact log.

The build reports AppIntents metadata extraction skipped because the dependency is absent. The test runner also logs launch-measurement and LLDB version diagnostics. These are retained observations, not demonstrated causes of the optics assertion or timeout. Artifact actions report Node runtime deprecation. No source/compiler correction is claimed by collecting this evidence.

## Source-specific total and successor

Source 10's other finalized shards are **library/reference 8/9** (first Projects-readiness failure before delete work) and **room/precision 5/5**. Together with this studio shard, **23 scenarios started, 22 completed: 20 passed, two failed and one remained interrupted**. Its two unsigned builds and 65/65 native methods, including 15 project-operation methods, remain actual passes at source 10; they do not erase the UI failures or supply a complete regression/persistence acceptance result.

At the final **12:39:52 UTC** observation, source-11 workflow **45394444997** had moved from pending to **in progress**, updated at `12:38:55Z`, for exact source `95e9c2446b7bb05e6df38d103063b4254bb07c92`. No source-11 method/build result was fetched or inferred. This observes the intended active-main completion policy across the two runs. No workflow was rerun, cancelled or modified; no test, timeout or assertion was changed during collection.
