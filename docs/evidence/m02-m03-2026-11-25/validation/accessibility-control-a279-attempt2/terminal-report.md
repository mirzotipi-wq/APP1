# a279 control attempt 2: setup timeout, no test execution

Run 45652784901, attempt 2, job 139355398057, source `a27916a1d0f9466a74079e1037d84c26c6621b8a`. This was the single explicitly authorized additional attempt on a new hosted runner, 1000000831. Attempt 1 remains preserved separately and unchanged.

The environment/source-recording step ran from 16:42:24 to 16:44:37 UTC and exceeded its two-minute limit. Project generation, build, simulator boot and test execution were skipped. There are zero selected-test starts, terminal methods or audit markers. The one expected method never ran; the CI step's skipped outcome is not an observed XCTest skip. No finalized XCTest count summary exists.

The original execution summary correctly records `testStepOutcome: skipped`, `auditOutcome: not_started`, no native log and missing command-exit/source-before files. The after-manifest contains a null head, no file hashes and stable=false. This is not an intact before/after source-provenance window, and no claim of repaired contrast verification is made.

Checkout binding is available independently: job metadata names a279, the checkout log records the same full SHA at 16:42:23.271713, and environment.log ends with the same SHA, received at 16:42:37.744691. The complete environment log includes macOS 26.6.1/25G76, x86_64, Xcode 26.6/17F113, Swift 6.3.3, SDK 26.5 listings and xcrun paths. These completed outputs supersede the earlier preliminary excerpt that stopped at the Xcode version.

The artifact contains an empty runtimes.json. The exact workflow opens it for `xcrun simctl list runtimes -j` after version guards and before source copying. The failure is therefore narrowed to runtime inventory or the subsequent transition into source capture; no per-command completion trace establishes the deeper cause. Runtime selection and boot never occurred. No specific app-code or configuration repair is supported by this setup failure.

The 1,763-byte artifact 15042607353 verifies SHA256 `cd97c1bd979df3859d79f935706bd410bf379cd4a18d7c4d1b08230fce863d7d`. Original environment, failed execution summary, empty inventory, after-manifest and export-status files remain under evidence/. terminal-receipt.json and selected-setup-excerpts.log preserve the job/checkout/timing/absence evidence. No test or source gate was waived, and no third attempt was requested or performed by worker 100.

The repaired control audit remains unverified. Its first attempt's successful build and failed app launch, and the previous 8fa control's completed audit with one contrast finding, remain distinct historical results. Productive 8fa library testing continues independently.
