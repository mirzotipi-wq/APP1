# Independent full accessibility-audit control

This separate native SwiftUI app has system text and one standard button. The
button changes only an in-memory label when tapped; the audit leaves it untouched.
There is no project library, custom renderer, network activity, imported reference,
persistent storage, repeating animation, or dependency on the production app.

The single UI test launches in English, verifies the initial label and enabled,
hittable button, preserves one before-audit screenshot, and calls
`performAccessibilityAudit(for: .all)` exactly once. Every issue
handler invocation returns false. Navigation remains fail-fast; during the audit,
XCTest may report every issue. An audit that returns with issues remains a failed
test. A thrown error is logged and rethrown unchanged. No sleeps, retries, idle
overrides, issue waivers, or alternate audit types are used.

## Evidence and limits

Each `AX_CONTROL` line is plain JSON with a monotonic uptime marker. The log
distinguishes launch, screen readiness, audit begin, audit return with the issue
count, and audit throw with the complete NSError domain/code and a bounded
description. Each description is at most 4,096 UTF-8 bytes, without splitting a
scalar; a separate field states whether it was truncated. At most 32 issue detail
records are printed, followed by one explicit limit marker. All issues still
reach XCTest unchanged and contribute to the final issue count. No issue-element
query or snapshot is added.

The workflow requires the exact selected test to start once and finish once with
a pass, the audit to return once with zero reported issues, and both xcodebuild
and log capture to succeed. It retains raw logs, pre/post source hashes, exact
source copies, native XCTest summary/counts, the result bundle, and genuine
attachments. A timeout can prevent result finalization; the raw log and any
partial result are still uploaded. Missing or contradictory evidence fails the
diagnostic rather than establishing a pass. Artifact/export failures are
separate from the preserved original xcodebuild return code and audit markers.
The source manifest maps each original path to its retained copy. The workflow
copy uses a visible filename so artifact upload does not omit a hidden directory.

The fixed environment is standard `macos-26-intel`, explicit Xcode 26.6
(build 17F113), iOS 26.5 simulator SDK, iOS 26.4.1 runtime, and iPhone 17 Pro. The
runtime identifier is `com.apple.CoreSimulator.SimRuntime.iOS-26-4`; selection
also requires the recorded runtime version to equal `26.4.1`. Build precedes
explicit boot. Its 10-minute boot limit matches the primary workflow and covers
previously observed multi-minute hosted-simulator startup. The workflow has a
36-minute job limit; individual step bounds total 34 minutes, leaving setup/cleanup
margin. There is no alternate-version matrix.

The original runtime-only experiment followed [run 45632330705](https://github.com/mirzotipi-wq/APP1/actions/runs/45632330705),
whose iOS 26.5 simulator exceeded the boot-step limit before any test started.
Its retained boot log later reached Finished at elapsed 11:35. That run's own
runtime inventory reports iOS 26.4.1 (build 23E254a) and an iPhone 17 Pro as
available. That runtime-only comparison kept the host label, Xcode, build SDK,
app, test, assertions, and all time bounds unchanged. It added no runtime
preparation or download. Hosted-machine variation remains uncontrolled, so a different outcome
would be evidence for that invocation, not proof of a runtime-specific cause.
The primary APP1 workflow continues to require iOS 26.5.

In the subsequent [run 45641484079](https://github.com/mirzotipi-wq/APP1/actions/runs/45641484079)
at source `6f3da3341f350084eac4a05b35a5bfd408d50193`, the control built and its
26.4.1 simulator booted, but no test method or audit marker was recorded. XCTest began
loading Accessibility at 15:19:20.602 UTC with a logged 70-second wait budget,
then reported `XCTDaemonErrorDomain Code=18`, "Timed out waiting for AX loaded
notification", at 15:20:27.826. The test step began at 15:14:24; GitHub reported
its six-minute timeout at 15:20:38.096. The first termination signal was not
recorded. The error falls after the nominal 15:20:24 deadline and before that
annotation, so an intrinsic initialization failure cannot be distinguished from
interference by the outer deadline. This is not an audit Code=-56 result.

The subsequent budget experiment changed only the diagnostic test-step budget from six to ten
minutes and the diagnostic job budget from 32 to 36 minutes, retaining two
minutes beyond the sum of individual step bounds for setup/finalization. It
preserved the runtime, app/test source, readiness assertions, full audit and all
other step bounds. The extra observation time does not promise completion or
establish a cause; the preceding six-minute failure remains part of the evidence.

In [run 45649843132](https://github.com/mirzotipi-wq/APP1/actions/runs/45649843132)
at source `8fa4399f50554836ce70ec2929a28534f70ba4b0`, the single selected test
started and failed, and the full audit returned in 5.121 seconds with one real
contrast issue. The exported element screenshot identifies the white-text,
default-blue **Confirm control** button. The native summary records one failed
test and zero passes or skips. Summary and attachment export succeeded; the
export step then correctly failed its zero-failure count requirement. There was
no Code=18, Code=-56, or outer timeout. The test command finished in 4 minutes
21 seconds, so this invocation does not show that the larger budget caused its
faster startup.

The current repair changes only that button's colors: its tint uses the adaptive
system label color and its foreground uses the adaptive system background color.
The bordered-prominent style, large control size, text, identifier and action
remain the same. Workflow, runtime, test, full audit, zero-issue requirement and
time bounds are unchanged. This addresses the identified control contrast issue;
Apple compilation and the full audit on the repaired source remain pending.
The preceding failed test and its genuine issue attachments remain evidence.

A timeout after `audit_begin` records an independent unfinished control audit;
a captured `audit_threw` with Code=-56 additionally establishes that exact error.
A build, boot, launch, or readiness timeout does not establish an audit timeout.
Neither result establishes a universal platform defect or its cause. A successful
control does not establish that APP1 is accessible; an audit
that completes and reports issues is also different from a timeout. APP1's full
audits, regression tests, and physical/manual gates remain required.

## Invocation

`Accessibility Audit Control` runs on pushes touching this directory or its
own workflow and supports workflow_dispatch. Its concurrency group is separate
from iOS Prototype and it neither waits for nor cancels that workflow. A push
still triggers the existing general iOS Prototype workflow according to that
workflow's unchanged triggers; hosted-runner availability is not guaranteed.

The project is generated with the same XcodeGen utility used elsewhere in the
repository. It includes only these two Swift files. Linux syntax/structure checks
are not Apple typechecking or simulator execution.

Apple documents the native result-summary and attachment commands in the
[Xcode 16.3 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes).
The executed xcresulttool help and unmodified summary JSON are retained alongside
normalized counts, so the actual tool's output remains reviewable.

