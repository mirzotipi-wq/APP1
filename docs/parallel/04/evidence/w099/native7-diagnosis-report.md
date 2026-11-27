# Worker099 — native7 command and result diagnosis

**Observed outcome:** source7 completed all 178 native methods, but its native job failed the command and result-finalization gates. The clearest timing difference from CI6 is before the first method. A simulator launcher or process hang is not established.

Source: `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`; run 45854806270, attempt 1, job 140034909086. Raw Git blob: `a09efa3eff982e9e4b4e22927053f6cd5c94e2d6`. The [machine-readable timeline](native7-diagnosis-timeline.v1.json) preserves exact timestamps, source6 provenance, workflow identity, intervals and qualifications. D7/D6 below mean their respective complete raw logs; W means workflow blob 55e68ee8.

## Timing and execution

| Observed event | UTC outer-log time | D7 line |
|---|---|---:|
| Native step Run group | 17:58:40.519 | 4757 |
| xcodebuild invocation | 18:00:02.565 | 4798 |
| First native method starts | 18:12:15.325 | 4825 |
| Last native method passes | 18:15:21.433 | 5655 |
| 18-minute timeout reported | 18:16:53.067 | 5670 |
| Standalone 178-method accounting passes | 18:17:02.029 | 5679 |
| Finalized-result check fails | 18:17:05.140 | 5704 |

The first method event arrives **814.806 seconds after the Run-group marker**, or 732.761 seconds after the invocation line. Within that latter interval, invocation→first package-graph message is 138.455 seconds; first graph→resolved-packages is 191.729 seconds; resolved-packages→first method is 402.576 seconds (D7:4798,4803,4806,4825).

These are logged intervals, not measured process states. Output is buffered: XCTest's embedded suite timestamps are 18:12:11.854→18:15:21.365, matching its reported **189.511 seconds wall time**; summed test execution is 163.155 seconds (D7:4822,5660–5661). Outer prefixes give a different 187.283-second suite interval. The unchanged workflow timeout is 18 minutes (W:253–254); API step timestamps and log emission are separate clocks.

The last pass precedes timeout by 91.634 seconds. Four `Resolve Package Graph` messages follow suite completion (D7:5662–5668). There is no normal `TEST EXECUTE SUCCEEDED` or completion-observer event before the outer timeout. The inline Python Metal guard follows the xcodebuild pipeline (W:267–289); its D7:4787 text is echoed source, not execution. Standalone accounting runs separately with `if: always()` and passed (W:290–294).

## What the comparator rules out

CI6's identical command first emits a method after 259.925 seconds from its Run-group marker, or 168.064 seconds from invocation (D6:4736,4777,4804). Its reported 174-method suite wall time is 87.176 seconds. Yet last-pass→normal success takes 146.740 seconds, and last-pass→executed inline guard takes 186.501 seconds (D6:5641,5697,5700): both exceed source7's available 91.634-second tail. This does not predict retry duration; it shows that the tail alone is insufficient evidence of a hang.

Both runs retain failed simulator warm-up, repeated post-suite package-graph messages, IOSurface/fopen/profile warnings and a UIKit keyboard-queue timeout. The keyboard diagnostic prints “No stack!” inside a hosted name-draft method that subsequently passes in both runs (D7:5393–5408; D6:5387–5401). No retained native-step output identifies a launcher deadlock, app crash or process ownership failure causing finalization loss. Host/toolchain preparation or scheduling remains a hypothesis, not a diagnosed cause.

## Result and artifact distinction

The export checks `NativeTests.xcresult/Info.plist` before attachment export; that check fails (W:303–316; D7:5704). GitHub successfully uploads 28 reported files as artifact 15143453127, 610055 bytes, SHA256 `7e986090bbeab88c62bb5b1a2b3827242c9822284d54aca24f2241d7098f4697` (D7:5740–5749). “Artifact finalized” describes the evidence ZIP upload, not a finalized XCTest result.

The workflow conditionally creates `native-results.zip`; this log does not enumerate archive members or prove that file exists. No ZIP was inspected. Compact upload found no matching attachments and produced no artifact despite an API success conclusion (D7:5770–5774).

## Owner routes

**19 — harness/results:** inspect the existing artifact inventory, native log and accounting report; establish whether a partial result archive exists and correlate result aggregation/teardown evidence. Preserve 178 method passes alongside failed command/finalization.

**01 — Apple runner/Simulator:** inspect retained startup report, preflight/bootstatus/recovery outputs and environment logs. Prioritize the pre-method interval and any already captured launcher/process state; compare the existing retry when root supplies its outcome.

No gate weakening, extra rerun or configuration/source change is proposed. This same-ID review used immutable reads and in-memory timing arithmetic only. Primary report stays frozen; root alone monitors the already-running unchanged retry.
