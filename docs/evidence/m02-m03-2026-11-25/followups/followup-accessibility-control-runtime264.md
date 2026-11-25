# Bounded control experiment: iOS 26.4.1 runtime

The preceding [9ed control](followup-accessibility-control-9ed-terminal.md) failed before testing because its iOS 26.5 simulator exceeded the existing boot bound. Its actual runtime/device inventory identifies **available iOS 26.4.1, build 23E254a**, identifier `com.apple.CoreSimulator.SimRuntime.iOS-26-4`, with an available iPhone 17 Pro.

This candidate changes only that isolated control's runtime selection: two identifier occurrences, the exact runtime-version guard and its failure message. The README records the experiment and limits. The host remains standard macOS 26 Intel, with Xcode 26.6/17F113 and SDK 26.5. App, UI test, project, full `.all` audit, false-returning issue handler, result checks, primary workflow and every step/job bound are byte-for-byte unchanged. No preparation command, download, retry or extra wait is added.

This is a bounded alternative worth executing because the runtime is already available and the single changed configuration value is independently logged. A different result would describe that invocation; VM variation remains uncontrolled and the previous run never reached an audit. It cannot establish a runtime-specific cause, repair APP1's audits, or substitute for the required iOS 26.5 suite.

Local validation: workflow YAML, seven shell blocks and six inline Python blocks parse; reversing the four runtime lines reproduces the prior workflow exactly. The pure selection block, run against the retained actual inventory, selects the intended 26.4.1 device. No simulator execution or new Apple typecheck was performed locally. An initial local inspection command assumed every step had a name; that inspection was corrected without changing workflow code.

The [candidate packet](../validation/accessibility-control-runtime264/) preserves the exact diff, source hashes, structural checks and runtime provenance separately from the failed 9ed evidence. The candidate remains unrun pending publication/CI. Independent review is recorded separately.
