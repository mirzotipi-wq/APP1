# Earlier UI results — worker 081

Run [46019722045](https://github.com/mirzotipi-wq/APP1/actions/runs/46019722045), attempt 1, executed source `2fc7647314d3ae6fa22d95284e778c6c5badbe4a`. This review fetched original decoded job logs and independently enumerated the historical Git source methods. It executed no application tests and makes no acceptance claim for current candidate `135d3b4`.

| Group | Expected | Started | Passed | Failed | Incomplete | Unstarted | Job |
|---|---:|---:|---:|---:|---:|---:|---|
| room-precision | 5 | 5 | 5 | 0 | 0 | 0 | success |
| studio-export | 11 | 11 | 11 | 0 | 0 | 0 | success |
| beta-workflows | 8 | 8 | 6 | 2 | 0 | 0 | failure |
| studio-optics | 10 | 0 | 0 | 0 | 0 | 10 | cancelled |

All started methods have exactly one start and one terminal result. No selected method was skipped, no unexpected target/method event was found, and no `Test Case` line was unrecognized. `receipt.json` retains every expected identity, original event line and API step conclusion. The four excerpt files retain source timestamps and original decoded-job line numbers.

## Passed groups

Room/precision and studio/export both reached `TEST EXECUTE SUCCEEDED`, passed exact method accounting, and completed the finalized xcresult check, attachment export and archive upload. Their diagnostic simulator warm-up steps had logged failures, but the required later commands completed successfully; those diagnostic failures are retained rather than erased. The studio/export successes include corrupt-project protection across relaunch. Original xcresult bundles and their visual attachments were not opened by this reviewer.

## Beta failures

The command completed with exit 65, method accounting failed, and finalized result export succeeded. All three `PlanGestureUITests` passed, as did project naming, unreadable-library recovery/relaunch, and welcome-dismissal persistence. The two failures were:

- `BetaAccessibilityUITests.testBetaSurfacesAtLargestAccessibilityTextSize`: at `BetaAccessibilityUITests.swift:41`, `studioWelcomeTitle` was not visibly reachable.
- `BetaWorkflowUITests.testFeedbackExactReviewBackAndDiscardExcludePrivateProjectData`: at `BetaWorkflowUITests.swift:259`, `openBetaFeedback` was not visibly reachable.

The preceding diagnostic host-capture step explicitly timed out after one minute, but required tests still started and all eight terminated. These observations do not establish the causes of either UI failure. Compact artifact `15214266531` is reported as 621,894 bytes; the full artifact is `15214391318`, 183,880,419 bytes. The archive digests in the receipt are reported upload metadata, not independently downloaded hashes. No artifact was downloaded in this task.

## Optics cancellation

The job built its UI bundle, then logged `The operation was canceled` at 15:11:29 UTC during the diagnostic host-capture step. The required test step was skipped, `native-tests.log` was absent, method accounting failed, and no finalized xcresult existed. The step has a one-minute timeout, but neither the retained log nor API metadata explicitly establishes the cancellation trigger. Do not label this as ten test failures or successful skipped tests.

This cancellation predates the later candidate publication at 16:06 UTC. Source supersession by that later publication is not its cause. The overall historical run conclusion is cancelled, while the beta-workflows job itself finished as failure at 16:00 UTC.

## Validation limits

This review establishes historical test accounting and observed command/step completion. It does not establish current-source regression acceptance, native image quality, PDF visual clearance, physical-device behavior, or cancellation/UI root cause. Repository source, gates, workflows and tests were unchanged.
