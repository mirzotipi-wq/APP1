# Bounded primary-source research: accessibility-audit platform diagnosis

Observed 2026-11-25 UTC. Existing worker a100; read-only research. Current published candidate is cbf94cecb113c1f03b0b8c7287e763655c14ec11, run 45623581873. No source, workflow, runner, SDK, audit, assertion or deadline change is proposed as already validated.

## Finding

The searched primary sources do not establish an Apple or GitHub-confirmed defect or fix for APP1's exact `performAccessibilityAudit` Code=-56 failure on Xcode 26.6 / iOS 26.5 / Intel. An installed, close version comparator exists: Xcode 26.5 with the same iOS 26.5 runtime on the same standard Intel image. If the current fresh-boot candidate still cannot complete the audits, a separate minimal audit control on the current environment would distinguish platform/harness behavior from dependence on APP1's UI more directly than changing several versions together.

## Documented installed inventory

GitHub's [standard runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) lists `macos-26-intel` and `macos-15-intel` as standard x64 runners (4 CPUs, 14 GB RAM). The unqualified `macos-15` and `macos-26` labels are ARM64. These are current manifests, not proof of binaries executed by any future job.

### Standard macos-26-intel

[Official Intel26 image manifest](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md): image **20260824.0517.1**, macOS **26.6.1 (25G76)**.

| Installed Xcode | Build | Bundled iOS simulator SDK |
| --- | --- | --- |
| 26.6, default | 17F113 | 26.5 |
| 26.5 | 17F42 | 26.5 |
| 26.4.1 | 17E202 | 26.4 |
| 26.3 | 17C529 | 26.2 |
| 26.2 | 17C52 | 26.2 |
| 26.1.1 | 17B100 | 26.1 |
| 26.0.1 | 17A400 | 26.0 |

Versioned bundles use `/Applications/Xcode_<version>.app`. The separately listed **installed iOS runtimes** are **26.2, 26.4.1, and 26.5**; each has an iPhone 17 Pro device. The manifest's runtime heading “iOS 26.4” has OS value 26.4.1. SDK26.0/26.1 availability does not establish installed runtimes of those versions.

### Standard macos-15-intel

[Official Intel15 image manifest](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md): image **20260824.0482.1**, macOS **15.7.9 (24G830)**.

Installed Xcodes: **26.3 (17C529), 26.2 (17C52), 26.1.1 (17B100), 26.0.1 (17A400), 16.4 (16F6, default), 16.3 (16E140), 16.2 (16C5032a), 16.1 (16B40), 16.0 (16A242d)**. Installed iOS runtimes: **18.5, 18.6, 26.0.1, 26.1, 26.2**. iPhone17Pro is available with the three26.x runtimes;18.x uses older device inventory. Xcode26.3/26.2 has SDK26.2; Xcode16.4 has SDK18.5. This manifest does not offer26.6/26.5/26.4.1.

A matched Xcode26.3/iOS26.2/iPhone17Pro comparison across the two Intel pools could isolate more host-image effects, but changes both toolchain and runtime relative to current acceptance. It is a secondary diagnostic, not the smallest first experiment.

## What the relevant primary reports do and do not show

- Apple's [Xcode26.6 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_6-release-notes.md) confirm SDK26.5 and macOS26.2-or-later requirements. The retrieved notes contain no accessibility-audit timeout or XCTest idle/snapshot fix.
- Apple's [Xcode26.4 Simulator release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_4-release-notes.md), issue170836966, describe restored automatic simulator dyld-cache creation and degraded performance while runtime scans/caches are built. Apple documents `simctl runtime dyld_shared_cache update --all` to ensure completion. This is a related documented mechanism, not evidence that APP1's current26.6 run is performing those operations or that they caused Code=-56. No cache command was executed.
- [Runner-images issue14773](https://github.com/actions/runner-images/issues/14773) is a **user-authored report in the official tracker**, on the same Intel image20260824.0517.1, about host `iconservicesagent`/Metal crashes and blocked macOS XCTest attach. It is a different path from an iOS simulator audit. The author's follow-up says cache purging did not fix their problem; the author later closed the issue. Its visible history does not establish an Apple/GitHub fix or APP1 causality. Do not adopt its speculative service/cache workarounds.
- [Official default-Xcode announcement14344](https://github.com/actions/runner-images/issues/14344) documents26.5→26.6 rollout and explicit version selection. It does not identify an audit regression or say26.5 fixes it.

The bounded search covered eight Apple/runner-images-focused web queries, the complete retrieved26.6 notes, relevant26.4 notes, and two GitHub issue searches. `repo:actions/runner-images is:issue "performAccessibilityAudit"` returned **0**, `incomplete_results=false`; `XCTest Intel` returned5, with only the above host-hang report close to the current image. Several results involved older ARM, input or rendering failures and were not treated as matches. No exact confirming report was found; this does not prove none exists or exclude private Apple Feedback reports.

## Smallest useful next diagnostic, only if current candidate still fails

Use one **separate static native SwiftUI control app** with a plainly labelled standard button and text, no rendering engine, persistence work, network or repeating animation. On the exact current Intel26 / Xcode26.6 / iOS26.5 / iPhone17Pro configuration, establish its visible screen, then run the same full `.all` audit with a return-false issue handler and a fixed finite deadline. Keep the actual APP1 audit and all existing acceptance gates unchanged.

Record exact image, architecture, Xcode/SDK/runtime/device identifiers, immutable control-source hash, screen readiness, monotonic markers immediately before/after the audit, complete errors, raw log and finalized xcresult. Apple's [audit documentation](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app.md) says the API audits the current screen using the Inspector audit mechanism and discovered issues fail the UI test. A tiny fixture can still have real issues, so “completed with reported issues” must be distinguished from timeout or clean completion.

If the control also produces Code=-56, the failure can occur independently of APP1's complex screen; that supports a platform/harness investigation without identifying a root cause. If it completes while APP1 fails, inspect APP1's captured state and framework/UI interaction; neither result proves data loss or universal platform failure.

If a version comparison is then needed, **Xcode26.5 (17F42) + the same installed iOS26.5 runtime** is the closest documented option. Explicitly verify actual `xcodebuild -version`, selected SDK, and available `simctl` runtimes/devices in the diagnostic job; installed inventories do not prove every cross-version destination works. A26.5 result would be comparative evidence, not a reason to waive a failing26.6 acceptance gate. No reproduction, alternate-toolchain execution, downgrade, or code change was implemented by this research.

