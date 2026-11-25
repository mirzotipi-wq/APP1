# cbf studio terminal timeout — 19 passes and one interrupted method

Run [45623581873](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873), job [139252380183](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873/job/139252380183), tested commit `cbf94cecb113c1f03b0b8c7287e763655c14ec11`: **terminal failure after the 40-minute selected-test deadline**. All 20 required methods started; 19 passed; no failed-method or skipped outcome was logged. The final `testStudySwitchesBetweenSphereAndMannequinWithoutEditingScene` started at 14:40:49.867207 UTC and was interrupted by the deadline reported at 14:41:07.226148 UTC. It has no terminal result and is not counted as a pass.

The first method started at 14:05:27.151565 UTC. Completed method durations sum to 2,122.875 seconds: ten optics workflows account for 1,099.740 seconds and the other nine completed methods for 1,023.135 seconds. There is no completed full-suite duration or finalized XCTest result bundle. The result supports preserving an incomplete shard; it does not establish a failed product assertion or a future completion time.

## All ten optics workflows passed

| Workflow | Seconds |
| --- | ---: |
| EditingUndoRedoAndRelaunch | 123.124 |
| Repeatability02 | 111.215 |
| Repeatability03 | 117.135 |
| Repeatability04 | 105.628 |
| Repeatability05 | 117.426 |
| Repeatability06 | 103.727 |
| Repeatability07 | 104.725 |
| Repeatability08 | 105.801 |
| Repeatability09 | 110.905 |
| Repeatability10 | 100.054 |

Both export methods, Camera, Meter, corrupt-library protection, recipe save/reopen, settings/AR simulator fallback, studio guide, and reference-frame rendering also passed. The untouched terminal-summary JSON preserves all 39 start/terminal events and exact method names. The 20-method expected list and source hashes were read from the tested cbf commit before the later class-split candidate.

## Timeout and diagnostic evidence remain distinct

The optional pre-test host-capture step also reported a one-minute timeout. Its continue-on-error setting allowed the required UI step to run. Both retained host logs nevertheless contain four command results marked successful within their five-second per-command bounds; this does not erase the outer step timeout. The after-test capture records GitHub outcome `failure`.

The studio trace status correctly separates `github_test_step_outcome=failure` from `observed_shell_exit_code=0`. Its trace window is 14:00:56–14:41:03 UTC; collection completed with code0. The observed shell value is not a test verdict. Full and compact copies of the trace status, stderr and 82,062-byte trace log match exactly. This is actual evidence that the outcome-label repair retained the authoritative failure.

Both snapshots report 14 GiB physical memory and zero swap used. Process output explicitly reports truncation; other command output is untruncated. These are bounded before/after observations, not a time series, proof of resource pressure, or a causal explanation for the timeout. No status-failure snapshot or finalized-result image attachment appears in these archives.

## Byte-verified evidence

The full artifact (ID15032788638) is exactly 71,415 bytes, SHA256 `d4dc79ce33d7e1fbcc2eb6a8a64a6c2e0cd7908e4d55cef30121c500ca8701df`; compact artifact (ID15032658884) is 4,789 bytes, SHA256 `3aba078774cef5f821b8f7a214bb13f6a2074339f862010eaa6129df779a2bd7`. Both match GitHub metadata bound to cbf and pass ZIP CRC verification. The full ZIP contains 13 text/JSON files; compact contains the three trace files. Neither contains a finalized xcresult or result-export attachments.

The initial archive request returned HTTP403 before saving bytes. That failed retrieval receipt is retained; refreshed authorized download links succeeded. No cause for the403 is asserted and no signed URL is retained in the packet.

The complete decoded connector log remains in scratch: 690,422 bytes, SHA256 `af0436e76bd820c854d693a89e6f39e451bbbdfe518d86569aee0a6534506464`. The compact packet retains 47 exact selected terminal lines (5,921 bytes), SHA256 `b977f506cbd626845d63ca0a553f705a7ba05e7b931206217de7f8f3c93214d1`; these are explicitly not the full log. Selected host excerpts similarly retain original lines and source hashes.

Stable packet: `docs/evidence/m02-m03-2026-11-25/validation/cbf-studio-terminal/`. Full originals and ZIPs remain outside the repository at `/var/tmp/keyfill-c0abc39c4f18/cbf-ui-terminal-triage/studio-export/`. No binary archive or unrelated build-command dump is copied into the compact packet. This is Intel simulator evidence, not ARM RealityKit, physical-device acceptance, either library audit, or execution of the later proposed split. No rerun or cancellation was performed by this reviewer.
