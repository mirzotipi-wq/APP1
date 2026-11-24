# Automated accessibility audits — isolated author report

Status: **frozen candidate for independent review; no native execution, audit findings or accessibility acceptance claimed.**

Assigned base: `95e9c2446b7bb05e6df38d103063b4254bb07c92`. All work is inside `verification/accessibility-audit-candidate`. No live source, protected contracts, state, documentation, staging, commit or remote writes were performed.

## Scope

The integration patch contains exactly two paths:

- `UITests/AccessibilityAuditUITests.swift` — one new XCTestCase with two independent audit scenarios.
- `scripts/native_test_shards.py` — adds that class once to the existing library-reference shard.

There are no product-code changes, application hooks, new dependencies, Dynamic Type overrides, test-timeout changes, expected failures, issue filters or ignored audit categories. The existing six UI classes and all their methods remain intact.

## Two independent native scenarios

| Method | Screen established before the audit |
| --- | --- |
| `testInitialLoadedPlanStudioAccessibilityAudit` | Fresh scoped app; Recipes enabled after load; Plan selected; Portrait setup; Unsaved changes; three lights; Plan camera marker present. No scrolling or editing is performed. |
| `testExactLightIntensityEditorAccessibilityAudit` | Separate fresh scoped app with the same loaded-state checks; existing reachability helper reveals `lightIntensityExact`; the value is 900 cd; the Intensity sheet opens with `precisionValue` equal to 900 and usable Apply/Cancel controls. No draft is changed or applied. |

Each launch uses the existing `-ui-testing` mode and a new `KEYFILL_UI_TEST_ID` UUID. Language/locale arguments match the existing precision-editing test pattern. Readiness uses the shared `waitForEnabledStudioControl` helper; scrolling uses `revealStudioContent`. The actual identifiers were checked in StudioView, PrecisionValueButton and the existing precision tests.

The new test methods, launch helper and audit helper are `@MainActor`. The class's normal setup keeps `continueAfterFailure = false`, so navigation or state failures stop that scenario before an audit of the wrong screen.

## Audit behavior and evidence

The shared audit helper first attaches:

1. A genuine `app.screenshot()` of the established current screen.
2. A bounded accessibility hierarchy from `app.debugDescription`: a 32,768-byte UTF-8 prefix, with an explicit truncation notice when needed.

Both attachments use `.keepAlways` and distinct Plan/editor names. They are captured before the audit, so an audit failure cannot prevent this evidence from being attached. These are execution-time captures; no image or AX artifact has been fabricated or generated locally.

Only after capture does the helper save the previous continuation policy, set `continueAfterFailure = true`, and call:

```swift
try app.performAccessibilityAudit()
```

A `defer` restores the previous policy even when the call throws. The call supplies neither an audit-type restriction nor an issue handler. It uses Apple's default `.all` and leaves reported issues as real failures.

### Public Apple API checked

- [performAccessibilityAudit(for:_:) documentation](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit%28for%3A_%3A%29): the public method defaults to all audit categories and a nil issue handler; its documented iOS availability is 17.0+, matching the existing deployment target.
- [Performing accessibility audits for your app](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app): automated audits inspect the current screen and fail the test on reported issues.
- [WWDC23 session 10035](https://developer.apple.com/videos/play/wwdc2023/10035/): continued failure reporting allows multiple audit issues to be recorded. Automated audits do not replace testing with assistive technologies.

The candidate adds native audit infrastructure for two screens. It is not proof that a current accessibility defect exists, that either screen passes, or that the app satisfies manual or device accessibility acceptance.

## Sharding and preservation provenance

The existing three shard names and workflow matrix are unchanged. The library-reference selector now lists ProjectLibraryUITests, ReferenceComparisonUITests and AccessibilityAuditUITests. The validator confirms **seven classes assigned exactly once across three shards**.

Two source inventories are deliberately separate:

- `committed-context.json` describes the assigned source-11 commit. The verification-only projection preserves all seven existing UI source/helper files byte-for-byte: six classes and 23 methods. With this candidate it has seven classes and 25 methods.
- `live-existing-ui-before.json` and `live-existing-ui-after.json` describe the actual live working tree, which already contains the pending Guide method. All seven existing UI source/helper hashes match before and after; its 24 methods remain untouched. Those working-tree files were not substituted for the committed fixture.

The projection's original workflow file is copied solely so the unchanged shard validator can check the existing matrix. It is not an integration change and does not replace the pending CI-budget work.

## Actual local verification

At **2026-11-24 12:55:45 UTC**, on Linux with Swift 6.4.3:

```sh
/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc -frontend -parse -swift-version 5 UITests/AccessibilityAuditUITests.swift verification-projection/UITests/StudioContentReachability.swift
python3 verification-projection/scripts/native_test_shards.py check
python3 verification-projection/scripts/native_test_shards.py library-reference
```

All exited 0. Syntax parsing produced no diagnostics. The shard check reported seven classes assigned once; the selector includes the new class exactly once. Exact commands and outputs are in `native-parse.log` and `shard-verification.log`.

Source verification also passed:

- Every existing committed UI source/helper file matches its exact committed bytes in the projection.
- The preserved shard-script base matches source 11, and both proposed files match the verified projection.
- Every pre-existing live UI source/helper file, including the pending Guide method, matches its before hash.
- `git apply --check --whitespace=error candidate.patch` succeeds against live HEAD `95e9c2446b7bb05e6df38d103063b4254bb07c92`. It did not apply the patch.

See `source-verification.log` and `manifest.json` for source hashes and evidence. No full build cache, core suite, benchmark or native test was run. The host has no `xcodebuild`; syntax parsing does not type-check XCTest APIs against an Apple SDK.

## Integration and outstanding acceptance

Use `candidate.patch`, or the separate `accessibility-audits.patch` and `shard-assignment.patch`. Do not copy the verification projection into the live repository. The existing XcodeGen UITests source directory already includes a new Swift file automatically.

After independent review and integration, native follow-up must compile the exact source and execute both scenarios in library-reference. Inspect the genuine before-audit attachments and every reported audit issue. Failures remain failures; this packet introduces no suppression policy.

Native duration, audit results, actual screenshots, actual accessibility trees, VoiceOver behavior and device acceptance remain **unverified**. The integration lead owns later fixes, evidence and completion accounting.
