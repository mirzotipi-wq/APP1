# Source 10 studio/export deadline: read-only diagnosis

The completed job `138417363754` in workflow `45383556829` exhausted its 32-minute UI step. The retained native log records **nine methods started, eight completed: seven passed and optics failed**. The last bust/sphere method is incomplete, not passed. Result export explicitly failed because XCTest had not finalized its bundle; uploading the six text/JSON evidence files did not change that result.

## Evidence and timeline

The full job log is `/workspace/scratch/73dcd6a65726/verification/source10-studio-final/5cd7eb4-studio-job.log` (SHA-256 `bb6337e6b0b2a556a48175b01a8de93c5d526b42df19479bd2433090bc7a99fc`). The artifact's `native-tests.log` has SHA-256 `1c52a61d5a5c9b9a1f79d06bcc240850c8d4732256926f3f77296ff2dde330ac`. Exact per-method extraction, comparison hashes and source identities are in `source10-comparison.json`. The source-9 comparison log has SHA-256 `83b475f36d0a12798f2af751e1b647c7a52c7773972838d6d48b458ba95b7a7b`.

| Observed boundary | Source 10 UTC |
| --- | --- |
| UI-step command group, including simulator boot | 12:03:59.479 |
| First test starts | 12:14:20.297 |
| Ninth method starts | 12:35:33.434 |
| Last streamed test action: tap Sphere at test time 39.09 s | 12:36:12.591 |
| Explicit 32-minute timeout | 12:36:12.631 |
| Explicit missing-finalized-bundle error | 12:36:13.023 |
| Orphaned xcodebuild terminated during cleanup | 12:37:08.401 |

The interval between the command-group timestamp and first test start is approximately **620.8 seconds**, versus **322.9 seconds** for source 9. These are recorded log intervals, not calibrated performance timings. Simulator boot and runner/test startup are inside the same UI-step allowance.

The first eight completed methods sum to **1,273.123 seconds** in source 10, versus **656.477 seconds** for the same methods at source 9. Both export tests passed but consumed approximately **591 seconds** together, versus **224 seconds** previously. The first PDF transition logged a 60-second missing app-idle notification followed by slow accessibility snapshot retries before the method eventually passed. Several other methods also ran more slowly.

Only approximately **39.2 seconds** remained when the final bust/sphere method began. That same method completed in **43.555 seconds** at source 9. In source 10 it rendered Bust, attached the rendered view, returned to Sphere, matched the sphere label and reached the final Undo-enabled query at test time **43.64 seconds** in the artifact log. There is no method or suite completion footer.

The artifact contains a few later actions than the streamed job output because the test process continued after the step timeout until cleanup. Those trailing actions cannot establish a completed or accepted method. No finalized xcresult or screenshot is present in the recovered 29 KB artifact.

## What the comparison supports

This is a concrete **verification-budget shortfall**, with cumulative startup and slower UI automation consuming the allowance before the final method and bundle finalization. The final recorded method was progressing near its previous ordinary completion time; the ending does not establish a prolonged renderer stall.

Ten relevant renderer, preview and export implementation files are byte-identical across `3b2a4ce`, `5cd7eb4` and current source 11 `95e9c24`. The bust/sphere test body is also identical. Source 10 added asynchronous library operations and disabled-state ownership in Studio, but selecting Study or switching its subject does not itself invoke the project store. These facts do not prove that the host or automation caused every delay; they do rule out attributing the cutoff to a newly changed rendering algorithm without further evidence.

The actual optics failure remains separate: source 10 read **2.25 m instead of 0.6 m** at line 87. Source 11 contains the reviewed explicit-tracking correction and must receive its own native execution. No native success is inferred from that source change.

## Authorized follow-up

Prepare a future workflow-only correction with studio/export at **40 minutes for the UI step and 93 minutes for the entire job**. Keep room/precision and library/reference at **32/85**. This adds eight minutes only to the affected shard and preserves the existing 16-minute margin beyond the bounded Metal, build and UI steps. All selectors, tests, assertions, per-method waits, other job/step budgets, permissions and concurrency behavior stay unchanged.

The correction is for CI completion. It is not a product speed improvement, an explanation of the app-idle warning, or a guarantee that a future runner will finish. It does not alter, cancel or rerun source 11's already-running workflow.
