# Independent review — two current-screen accessibility audits

**Decision: approve this frozen two-file candidate for root integration. No blocking source correction found.** This approves adding the two automated checks and their shard assignment. Apple SDK compilation, execution of either audit, actual screenshots and accessibility acceptance remain **unverified**.

Reviewer: `/root/w09_ios_critical_review`. Review date: 2026-11-24 UTC. Author: `/root/w01_native_design_audit`. No additional agents were created. The reviewer changed no candidate source, live source, test assertions, staging or commits, and ran no compiler, core suite, native test or benchmark.

## Exact packet and verification

Assigned base and observed live HEAD during independent verification: `95e9c2446b7bb05e6df38d103063b4254bb07c92`. The live tree also contains the already accepted Guide and workflow-budget work. This candidate does not replace either change.

| Reviewed artifact | SHA-256 |
| --- | --- |
| [AccessibilityAuditUITests.swift](UITests/AccessibilityAuditUITests.swift) | `6fcb87af1a3c9a60613e0c38659a5223efc2d8ad4849fe0738027b7ff1b0cddf` |
| [native_test_shards.py](scripts/native_test_shards.py) | `e58d63cc3fedcb452277f154895b0422afae548deaf30713274366b8a92208d4` |
| [candidate.patch](candidate.patch) | `dacf6d6af9789128a17aaa4fef0e2703baedc3965477c9202dd46ff4ba82d03a` |
| [manifest.json](manifest.json) | `2b4f0edc238bb69dfa07e42e81a0d5e8307ad0e31344676759c1ee71696fb726` |
| [AUTHOR-REPORT.md](AUTHOR-REPORT.md) | `cdef0ba92e5d9ba41ee6e6db44872bcf47f4faecafe5d3077ba23dc51544ce5e` |
| [Independent source verification](INDEPENDENT-SOURCE-VERIFICATION.log) | `87c2812594b2199242c8c3069566110956d486c2ba62009d6a6018fd2c802e88` |

At **12:58:44 UTC**, independent read-only verification matched all 13 author-manifest entries; compared the seven committed UI source/helper files and the projection workflow with `git show` at the exact base; compared all seven current live UI source/helper hashes with both author inventories; verified the shard script differs only by the new class in the existing tuple; and checked the actual proposed class/method inventory. `git apply --check --whitespace=error candidate.patch` exited 0 against the live tree without applying the patch. The linked independent log preserves those results.

The author’s [syntax log](native-parse.log), [shard log](shard-verification.log) and [source verification](source-verification.log) were read, not represented as new reviewer executions. The author parsed the new Swift file and existing helper in Swift 5 mode with Linux Swift 6.4.3, and ran the shard validator/selector; those commands exited 0. Syntax parsing does not resolve XCTest APIs against an Apple SDK. No native run or screenshot exists in this packet.

## Source review

### The intended screens are established before auditing

Both methods create a separate `XCUIApplication`, use the existing `-ui-testing` mode, supply a fresh valid UUID, and pin English / `en_US` exactly as the existing precision tests do. They add no application hook or fixture behavior.

The common launch helper waits for **Recipes to exist and be enabled** using the existing 15-second helper. This is a meaningful load boundary: current `App/StudioView.swift` disables Recipes while `!loaded`, `saveBlocked` or `libraryOperation.isBusy`. Merely finding its toolbar label would not establish readiness. The helper then asserts Plan selection, the draft project name and unsaved status, three lights, and the existing camera marker. These checks reject a different preview, unavailable library or unexpected persisted project before an audit begins.

The initial-Plan method performs no scrolling or editing after launch. Its scope is the actual initial screen at the native run’s viewport and environment; it does not claim to inspect every offscreen inspector row.

The precise-editor method uses the existing edge-scroll reachability helper to reveal the actual `lightIntensityExact` control, waits for it to be enabled, and verifies `900 cd` before tapping. The expected value is grounded in `LightingScene.portrait()` in `Sources/LightingCore/Scene.swift`: the first Key light has candela 900. It then checks the actual Intensity navigation title, `precisionValue` equal to `900`, field hittability, and enabled/hittable Apply and Cancel controls. These identifiers and the title match `App/PrecisionValueButton.swift` and the existing precision scenario. The test does not change a draft or apply a value.

The exact screen predicates are useful rejection checks. Their runtime resolution, presentation timing and accessibility element types still require Apple execution. A failure in launch, reveal or an assertion is a navigation/readiness failure; it is not evidence that an accessibility audit ran or found a particular defect.

### Public API and failure handling are appropriate

Apple documents `performAccessibilityAudit(for:_:)` as iOS 17+, with `.all` and a nil issue handler as defaults. The project’s `project.yml` already sets iOS 17.0 and automatically includes the UITests source directory. The two test methods and both relevant helpers are `@MainActor`, matching the API’s documented actor isolation. The no-argument `try app.performAccessibilityAudit()` therefore requests all available audit categories without supplying a filter. A literal `for: .all` is not necessary to obtain that behavior. See [Apple’s API declaration and availability metadata](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit%28for%3A_%3A%29.md).

`setUpWithError()` makes ordinary navigation and assertions fail-fast. Only the audit helper saves the previous continuation setting, sets `continueAfterFailure = true`, and restores it with `defer`. There is no catch that discards the error, `try?`, expected failure, skip, issue handler, category restriction or custom success override. Each test propagates the audit call with `try`. Continued reporting enables collection of multiple issues; it does not turn a failing test into a passing one. This use matches [Apple’s WWDC23 audit guidance](https://developer.apple.com/videos/play/wwdc2023/10035/).

Apple explains that this API audits the current screen and reported issues automatically fail the UI test. It also explicitly distinguishes automated checks from testing with assistive technologies. This candidate’s author report preserves that distinction. See [Performing accessibility audits for your app](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app.md).

No Apple SDK type checking was available to the reviewer. Documented availability and source inspection support integration; they are not a substitute for compiling the new XCTest class on the selected native toolchain.

### Evidence is genuine and bounded within its stated scope

Before changing continuation policy or invoking the audit, the helper attaches `app.screenshot()` and an excerpt of `app.debugDescription`. Both are `.keepAlways`, with distinct names for Plan and the precise editor. They are actual execution-time captures, not fixture images or generated accessibility trees.

The hierarchy excerpt takes a 32,768-byte prefix of the original UTF-8 representation and appends an explicit notice if truncated. Decoding can replace a cut partial scalar; the small notice is additional to the prefix. This is a bounded diagnostic excerpt, not a claim that the full tree was retained. The prefix does not cap the time required to obtain `app.debugDescription`, and `.keepAlways` does not guarantee recovery from an interrupted runner before a result bundle is finalized.

The attachments document the screen immediately before the audit. They are not per-issue highlights, screenshots at every text size, or proof that the audit completed. XCTest’s actual issue records and native run outcome must supply that evidence. Because the helper is reached only after readiness assertions, it does not promise these attachments for every earlier navigation failure.

## Test and shard preservation

The patch adds only `UITests/AccessibilityAuditUITests.swift` and one class name to `scripts/native_test_shards.py`. The validator, existing selectors, workflow matrix and timeouts remain unchanged. No existing test source or helper is part of this patch.

The source inventories correctly distinguish two bases:

- The exact committed source-11 projection preserves six classes and 23 methods byte-for-byte; adding the two methods yields seven classes and 25 methods.
- The current live tree includes the accepted Guide method, so its six existing classes contain 24 methods. All seven live source/helper hashes match both author inventories and the reviewer’s independent read. This integration would contain **seven classes and 26 methods**.

| Shard | Classes after this candidate | Proposed methods with the current live Guide test |
| --- | --- | ---: |
| room-precision | ManualRoomPlacementUITests; PrecisionEditingUITests | 5 |
| library-reference | ProjectLibraryUITests; ReferenceComparisonUITests; AccessibilityAuditUITests | 11 |
| studio-export | StudioSmokeTests; LightingPlanExportUITests | 10 |

These are source/discovery counts, not passing test counts. The independent check confirms each class is assigned exactly once and the library-reference tuple contains the new class once. All prior assertions, including the existing precise-edit/history tests and new Guide assertions, remain intact. The author’s committed projection is verification material only and must not be copied over current live tests or the separately approved workflow-budget changes.

## Integration and remaining acceptance

Root may integrate the exact two-file patch. No additional source correction is required by this review. The following native evidence is still required before claiming the new checks pass:

1. Compile the exact integrated source with the selected Apple SDK, recording revision, Xcode/SDK and simulator configuration.
2. Execute both new methods in library-reference and distinguish readiness/navigation failures from reported audit issues. Preserve every issue as a failure; do not add suppression or weaken checks to produce a green result.
3. Inspect the real before-audit captures and issue records for the actual Plan viewport and Intensity sheet. Record completion and duration; this packet provides no timing or shard-budget measurement.

A successful pair of automated audits would establish results only for these two current screens under the recorded run conditions. It would not establish physical VoiceOver use, full Dynamic Type or device-size coverage, reduced-motion behavior, every workflow, or the repository’s manual real-device accessibility gate. `docs/QUALITY.md` remains controlling: unrun is unverified, and CI alone does not satisfy release acceptance.

**Review frozen without source changes. Native execution and accessibility gates remain pending.**
