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
32-minute job limit; individual step bounds total 30 minutes, leaving setup/cleanup
margin. There is no alternate-version matrix.

This runtime-only experiment follows [run 45632330705](https://github.com/mirzotipi-wq/APP1/actions/runs/45632330705),
whose iOS 26.5 simulator exceeded the boot-step limit before any test started.
Its retained boot log later reached Finished at elapsed 11:35. That run's own
runtime inventory reports iOS 26.4.1 (build 23E254a) and an iPhone 17 Pro as
available. The experiment keeps the host label, Xcode, build SDK, app, test,
assertions, and all time bounds unchanged. It adds no runtime preparation or
download. Hosted-machine variation remains uncontrolled, so a different outcome
would be evidence for that invocation, not proof of a runtime-specific cause.
The primary APP1 workflow continues to require iOS 26.5.

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

