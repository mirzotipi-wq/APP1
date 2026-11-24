# Manual room status: native follow-up review

Date: 2026-11-24 UTC. Independent reviewer: `/root/w09_ios_critical_review`.

## Decision and evidence boundary

No source-level blocker was found in the frozen two-file candidate. The change gives the existing static room status one explicit accessibility label, preserves its visible wording and geometry inputs, and adds failure observations to the raw UI-test log. Existing assertions, expected counts, timeouts and fixtures are unchanged.

This is a source, API and syntax review. It does not establish that the candidate fixes the native failure. The candidate is an unstaged follow-up after `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`; it has not been integrated or executed natively at this review checkpoint. No quality gate is promoted by this report.

The reviewer changed only this report, did not stage or commit, did not run a broad suite or benchmark, and did not spawn another agent. Concurrent asynchronous-persistence changes are outside this review.

## Revisions and immutable file identities

The failed room evidence was retrieved by root from artifact `14911432315`, associated with source `816e7123cafbf214bef47e09d3e14abd993a83c7`. Its preserved file is `816e712-room-partial.log` in this directory. The standalone partial test log does not itself include a checkout record; the artifact association is supplied by root. The separately retrieved native-unit job log does include checkout/revision output for the full `816e7123cafbf214bef47e09d3e14abd993a83c7` revision.

For both reviewed source files, the committed contents at `816e7123cafbf214bef47e09d3e14abd993a83c7` and current HEAD `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18` are byte-identical. The candidate diff therefore has the same two-file baseline at either revision.

| File | Committed baseline SHA-256 | Reviewed candidate SHA-256 |
| --- | --- | --- |
| `App/ManualRoomPlacementView.swift` | `482ab39b9831358e1f8f5752ac2b51238f3ddbc60d5acbda38bd82583c61b6b4` | `3f53720c6ce15c1c08ad324e41cb1deb3fc78968be1032f83b727fc99334d8e3` |
| `UITests/ManualRoomPlacementUITests.swift` | `4219598954145211dfbdaeb0326e3524d3db25056296cac802dbb4897e58c16e` | `637605b7ef3c85fd7a335143c9110ccacac086cc06e248348d2ff111848e11fb` |

| Preserved evidence file | SHA-256 |
| --- | --- |
| `816e712-room-partial.log` | `d0b42ff20cd11de8ce7e2438417c30275936a8f4b0e14ccf250a99729c975545` |
| `816e712-native-job.log` | `a81f03ea13d284e94642925ecc8e7598a73e8b6cf62dafb2a9e694cea46f8b66` |

## What the native evidence actually establishes

`testManualRoomReportsOutOfBoundsWithoutChangingStudio` failed in the source-816 partial room run after **96.714 seconds**. The sheet-open checks had completed. The failed assertion was the first status expectation at `ManualRoomPlacementUITests.swift:21`, requiring the element to exist and its label to contain `All 5 center positions inside room`. The waiter returned raw value 2 rather than completed/raw value 1. The log shows the predicate check at elapsed 67.34 seconds and an element lookup at 75.74 seconds, but does not print the actual label, value or resolved element attributes.

The log records creation of `Room-status-failure` and `Room-status-hierarchy` attachments at elapsed 83.14 and 89.39 seconds. Their contents are not available in the retrieved partial evidence and there is no finalized result bundle available for this review. It would be inaccurate to say that the test never created attachments, or that the hierarchy proves a particular accessibility defect.

The second method, `testRoomResizeRequiresExplicitSubjectMoveAndPreservesSignedCoordinates`, started at 10:37:16.707 UTC and progressed through later status/resize work. The captured tail reaches the second notes presentation and a `Room width: 2.00 m` label query at elapsed 349.85 seconds, followed by another lookup at 354.56 seconds. Root reports interruption by a subsequent push. The preserved log contains no completion result for this method; its partial progress is not a pass. This run also does not establish a completed result for the precision tests selected by the same command.

Separately, `816e712-native-job.log` records **42 native unit tests with zero failures**, including all three `SpatialPreviewTests`, and ends with `** TEST SUCCEEDED **`. Those actual source-816 unit results remain valid. They do not certify the room UI method or this later candidate. The older source-six/source-`ff8b683` failures likewise remain historical failures; this status failure is distinct from an earlier room-notes content assertion.

## Candidate hypothesis and source review

### Explicit room-status accessibility contract

`placementSummary` now computes `centerStatus` once and supplies that same string to the visible `Label` and `accessibilityLabel(Text(verbatim: centerStatus))`. Both the all-inside wording and the outside-count wording are identical to their committed forms. `plan.points.count`, `plan.outsideCount`, room validation, room transforms, signed coordinates and modifier-boundary calculations are untouched.

The added `accessibilityElement(children: .ignore)` is attached only to the static status `Label`. It does not wrap the containing `VStack`, the modifier warnings or the review/share action. Its children are the label's title and icon; the explicit replacement label contains the complete count and inside/outside meaning. The new local variable makes the helper a multi-statement function, and the reviewed candidate includes the necessary explicit `return` before the `VStack` expression.

Apple documents that [accessibilityElement(children:)](https://developer.apple.com/documentation/swiftui/view/accessibilityelement(children:)) creates or changes an accessibility element, and that [.ignore](https://developer.apple.com/documentation/swiftui/accessibilitychildbehavior/ignore) hides child accessibility elements and creates a new element whose properties must be supplied. The candidate supplies its full textual label and identifier explicitly. These APIs are available before the app's iOS 17 deployment target. This supports the source-level approach for a single static status; it does not predict the observed element type on the next simulator run.

The falsifiable hypothesis is that an explicitly represented status element will expose the complete status text consistently to accessibility consumers. The missing historical element attributes prevent attribution of the original failure to label composition, duplicate matches or another cause. No such root-cause claim is made here.

### Raw-log diagnostics and assertions

The failure helper now reports the actual status-query match count, followed by element type, label, value and frame for at most four matches. The label uses `String(reflecting:)`, retaining quoted/escaped content. Apple documents the used [`XCUIElementQuery`](https://developer.apple.com/documentation/xcuiautomation/xcuielementquery) operations: `matching(identifier:)`, `count` and `element(boundBy:)`. The count is the result of that query, not an added uniqueness assertion. The existing `.firstMatch` status lookup and test predicates are unchanged.

The room-notes helper additionally prints the same observed details already stored in its attachment, on both its successful and unsuccessful expectation paths. Existing screenshot, hierarchy and content attachments remain. The new status observations run after a status expectation has already failed; they do not replace, shorten or bypass the expectation. All original waiter timeouts and equality assertions remain intact, including the exact counts, width preservation, signed-coordinate, unsaved-project and disabled-undo checks.

Raw printing makes these observations available without relying solely on a finalized attachment bundle, provided the helper runs and its accessibility queries complete. It does not guarantee diagnostic output if the process is stopped or an accessibility query itself cannot finish. The bounded four-match loop limits result enumeration; it is not a claim about wall-clock execution time. No application telemetry or persistence path is added.

## Verification performed

On Linux, the reviewer executed:

```sh
/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc -frontend -parse App/ManualRoomPlacementView.swift UITests/ManualRoomPlacementUITests.swift
git diff --check -- App/ManualRoomPlacementView.swift UITests/ManualRoomPlacementUITests.swift
```

Both completed without diagnostics; the scoped command invocation exited 0. This establishes Swift syntax and whitespace checks only. The environment does not provide an Apple SDK, so SwiftUI/XCTest SDK type-checking, app compilation, actual accessibility hierarchy behavior, VoiceOver output and candidate native test execution were not performed by this review.

## Required follow-up

Run the unchanged two manual-room UI methods to completion on an identified native revision containing these exact changes, with the existing assertions and timeouts. Preserve finalized results when available and retain the raw log independently. If the initial status still fails, use the newly recorded count and attributes to narrow the next correction; do not infer the earlier hierarchy from this candidate's source. A successful completed run may establish the candidate's room UI result, while the unresolved cause of the original partial failure should remain accurately described.
