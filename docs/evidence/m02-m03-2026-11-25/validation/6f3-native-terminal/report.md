# 6f3 native simulator terminal receipt

[Run 45641483928, native job 139303177414](https://github.com/mirzotipi-wq/APP1/actions/runs/45641483928/job/139303177414) completed successfully on source `6f3da3341f350084eac4a05b35a5bfd408d50193`.

## Actual results

The complete terminal log contains **110 unique native methods started and 110 passed**, with zero failed, skipped, missing, unexpected, or duplicate terminal outcomes. Their identities exactly match the source-bound inventory in `expected-source-methods.json`. XCTest reports **75.021 seconds of tests, 76.853 seconds wall time**. The macOS portable-package run separately reports **319 tests, zero failures, 23.644 seconds (23.728 wall)**.

All three required Metal methods actually passed:

| Native method | Seconds |
|---|---:|
| `testMetalMatchesCPUOnAvailableDevice` | 7.477 |
| `testNearFieldRoutingDoesNotPermanentlyDowngradeValidatedMetal` | 2.650 |
| `testCancelledInitialParityValidationCanRetryMetalOnSameEngine` | 4.705 |

The six logged Metal fixtures each report matching invalid-pixel classification and zero outliers; maximum channel error is 0 or 1. The workflow's required-Metal/no-skips verifier also succeeded.

Unsigned Debug/test-bundle build succeeded at **15:15:43.752575 UTC**, unsigned Release build at **15:18:52.370381 UTC**, and test execution completed successfully at **15:34:34.526336 UTC**. Finalized-result export and both evidence uploads succeeded. The native method interval was 15:28:57.508178–15:30:14.013882 UTC; it is distinct from the longer workflow test step and export interval.

## Source and evidence scope

The log records the exact revision, Intel `x86_64`, Xcode 26.6 build 17F113, and the iOS 26.5 simulator SDK. Artifact metadata binds the Debug app (15036850488), Release app (15035638817), full native evidence (15036913273), and compact native evidence (15037093175) to the same run and source. **These are metadata receipts; their archive bytes were not downloaded in this review.**

`complete-terminal-decoded.log` is the complete decoded UTF-8 GitHub job log, **860,950 bytes**, SHA256 `80dd0629a2db568a28ba350349568a69e0884583c171a93b1df6b477217798ef`. `terminal-excerpts.log` contains **129 selected exact lines**, **20,091 bytes**, SHA256 `79483bb88ea1e3dca631428bc887eb76e1978229949e55cdebf84b10a7ac4693`. Every selected line was checked against the complete log. The per-file manifest is `receipt-sha256.json`; structured outcomes, source hashes, job metadata, and summary remain beside it.

This is actual Intel simulator/native evidence. It does not certify the ARM RealityKit branch, real-device gates, or the separate UI shards. No source edits, reruns, cancellations, or repository writes were performed for this receipt.
