# Independent export and slider correction review

## Decision and scope

**No concrete new blocker, snapshot-lifetime defect, owner regression, direction-reversing accessibility adjustment or source-level SwiftUI API mismatch was found.** The corrections are suitable for integration and a fresh native build/test run. The historical export stalls and optics undo failure remain failures; this review does not establish that either native correction has passed.

Reviewer: the existing `w09_ios_critical_review` specialist, reused for this follow-up. No additional agent was spawned. Base revision: `816e7123cafbf214bef47e09d3e14abd993a83c7`. The review covers the unstaged export flow/UI tests, new `StudioSliderEditing` and `StudioSlider`, their four inspector/studio call sites, and `NativeTests/StudioSliderEditingTests.swift`, identified by the hashes below. Only this report was written. No production/test source, index, commit or protected contract was changed, and no additional suite was run.

## Native failures actually inspected

The reviewer read `/workspace/scratch/73dcd6a65726/verification/ff8b683-studio-export-native-tests.log`, SHA-256 `0f60b9bf4d694cbbc022e3c74dc44a7b61372bdcd73f40e58a8f9f6d725983d3`, plus the job log's 32-minute interruption. These are observations at `ff8b683`, not corrected-candidate results:

- The PDF format action was found and tapped. After the application failed to report idle for 60 seconds, the page-count query timed out. That method failed after 356.692 seconds.
- The full-library test reached the real saved fixture, added the fourth light and observed unsaved status/undo before tapping editable copy. It then failed to observe even the immediate project-name label after an idle/animation stall; the method failed after 120.329 seconds.
- The following camera method failed to terminate the prior application process. This is a launch/termination failure after the export stalls; it is not evidence that a camera edit or undo assertion failed.
- The optics test performed a width drag and one Undo. The original assertion expected `0.6 m` but observed `0.8500000000000001 m`. That is a real failure to restore the pre-drag value in one command.
- The job later reached its 32-minute UI-step limit. A partly executed shard and its individual successes do not constitute a passing studio/export suite.

The logs do not contain a process stack proving a particular SwiftUI internal hang, or a trace of every slider setter/editing callback. The export lifecycle diagnosis and the modeled early-value ordering are supported hypotheses with focused corrections; the next native run must confirm their effect. See also [export-native-correction.md](export-native-correction.md).

## Export lifetime, immutability and cancellation

The previous transient Menu with two sibling sheet states is replaced by one ordinary export button and one item-driven sheet. Pressing the button creates a fresh UUID and copies the name, `LightingScene` value and text settings into immutable properties. The presented flow reads that snapshot; it holds no binding to the live scene, project library or history.

Format selection mutates only the flow's local destination. It does not change the sheet item, dismiss the chooser to launch another app sheet, or capture a second scene from a later editor state. The PDF and editable-copy branches receive the same name/scene snapshot, and text sharing receives its captured string. A new sheet identity on subsequent opening resets the local destination and prepared child state. This addresses the shared observed transition boundary without adding arbitrary delays or moving UIKit PDF work across its existing main-actor boundary.

The chooser declares its dismiss action inside the presented flow; the existing PDF and backup screens declare theirs inside their own presented content. Their Done actions therefore use the presented environment rather than a dismiss action captured from the studio. Apple documents both the item-driven sheet data-source behavior and the importance of obtaining dismissal in the correct environment. These are API checks, not proof that the prior stall had a specific framework cause. [Sheet API](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)); [DismissAction](https://developer.apple.com/documentation/swiftui/dismissaction).

The correction does not alter document preparation or persistence:

- PDF preparation retains its option identity and cancellation checks. It still uses the existing main-actor PDF renderer; the review makes no new responsiveness claim for its synchronous work.
- Editable preparation retains its immutable captured values, detached encoding worker and cancellation-before-publication checks. The real file exporter remains inside the child screen, and only its success callback reports a saved destination.
- Chooser cancellation, opening, preparation and dismissal do not call a store operation or manipulate history. Full project capacity does not disable export. No Photos reference, room session or edit history is added to either document path.

Actual sheet cancellation, child dismissal, nested system sharing/export and provider outcomes remain native acceptance work. The source supplies appropriate ownership boundaries; it cannot substitute for that execution.

## Export assertion strength

The revised tests keep the existing PDF page/share checks, full-library setup, editable-copy scope, unsaved fourth-light checks, history checks and relaunch assertions. They add an interactive chooser check with exact name/light count, cancellation before preparation, alternate PDF/copy destinations through the same presenter and fresh three-light capture after undo. The specific PDF Done identifier replaces an ambiguous generic Done query.

Original 15-second document-preparation limits are unchanged. The old menu-label fallback is replaced by a required stable-identifier assertion. No test-only presentation path, forced delay, hidden duplicate control or relaxed document result was added. The tests still do not select a system file destination; they cannot claim that an editable copy was saved or reimported.

## Slider ordering and lifetime

`StudioSliderEditing` contains closures rather than independent mutable gesture state. Recreating a SwiftUI body therefore does not replace the transaction's original scene: the existing external `SceneEditHistory` remains its owner.

For a finite changed slider value, `setValue` now calls the captured editing-began callback **before** invoking the original binding setter. That ensures the original validated setter sees an active transaction even when the first native value arrives before the native began callback. Subsequent begins for the same owner retain the transaction's original scene under the existing history contract. End callbacks still use the captured callback and its owner-qualified history end.

All four call sites retain their previous values, bounds, step, accessibility labels/values/identifiers and editing callbacks. The studio's project/light/field owner capture and `.id(owner)` remain. Camera, optics and neutral-card owners still come from their existing project-scoped inspector integration. Exact-value controls retain their original bindings and remain discrete commands; the wrapper applies only to slider-origin writes. There is no new asynchronous suspension between reading, beginning and writing within the adapter.

The original `UITests/StudioSmokeTests.swift`, including the failed one-Undo optics expectation, was compared with base `816e7123` and is byte-for-byte unchanged. The correction does not make the native regression easier by accepting the intermediate width.

This does not expand the history model's documented event-generation guarantee. An owner still identifies a control, not an arbitrarily overlapping generation from that same control. The evidence covers the modeled early-write and normal begin/end sequences; it does not prove every possible native gesture delivery sequence. No unobserved callback pattern was labeled a newly demonstrated defect.

## Accessibility closure, bounds and direction

The `StudioSlider` wrapper keeps the standard Slider binding/step initializer and adds an explicit adjustable action. Its increment/decrement invokes the same adapter with positive/negative step, then ends a successful adjustment as a complete history command. It does not await a drag-end callback for that accessibility action.

The adapter re-reads the current value when the action fires. Its effective interval uses `min(oldLower, current)` and `max(oldUpper, current)`, so the interval contains the current value even if the closure's usual bounds predate a valid imported value. For the finite positive steps used by every reviewed caller, clamping `current + step` cannot move below current, and clamping `current - step` cannot move above it. At an expanded endpoint, an outward action is a no-op instead of jumping back into the usual range. Inward adjustments remain small changes to the actual value. Unchanged/nonfinite values and zero/nonfinite adjustment deltas return without opening a new transaction.

The original validated binding remains responsible for scene/domain validity. The actual call-site ranges and positive steps were inspected; no unvalidated write path or narrower hardcoded coordinate range was introduced. The wrapper's read/write closures continue to use those bindings, rather than storing an obsolete numeric value.

Apple's retrieved documentation confirms the employed Slider initializer and adjustable-action signatures and their availability from iOS 13, below this app's iOS 17 minimum. `DismissAction` is available from iOS 15. The documentation describes began/ended callbacks but does not promise the setter ordering needed to dismiss the observed failure. No obvious type/signature or deployment-target mismatch was found; Linux syntax/model checks still do not establish Apple SDK compilation or actual VoiceOver adjustment behavior. [Slider initializer](https://developer.apple.com/documentation/swiftui/slider/init(value:in:step:oneditingchanged:)); [Adjustable action](https://developer.apple.com/documentation/swiftui/view/accessibilityadjustableaction(_:)).

`project.yml` includes the App and NativeTests directories, so the new helper/wrapper and test file fall within the existing target source declarations. No new package, runtime dependency, actor or unchecked sendability declaration is introduced.

## Existing focused execution evidence

The reviewer compared the isolated package's files with the proposed source: `StudioSliderEditing.swift`, all eight `StudioSliderEditingTests` and the fifteen existing history tests are exact byte matches. That package compiles the UI-independent adapter against LightingCore on Linux; it does **not** compile `StudioSlider` or execute SwiftUI/Apple frameworks.

| Inspected artifact | Actual result | Scope |
| --- | --- | --- |
| `slider-history-before.log` | Four of eight methods failed, eleven failed assertions | Baseline-equivalent setter reproduction of early-value history failures |
| `slider-history-after-debug.log` | 23/23 passed | Eight adapter tests plus fifteen existing history tests, unchanged isolated source, Linux Debug |
| `slider-history-after-release.log` | 23/23 passed | The same targeted suite in Linux Release |
| `StudioSmokeTests.swift` comparison | Unchanged from base | Original native optics Undo regression is retained |
| Scoped `git diff --check` | Passed | Patch whitespace only |

The adapter cases cover early value before begin, normal/repeated begin, whole-gesture undo/redo, a preceding emitter command, a following exact-value command, cancellation/redo retention, late other-owner end, separate accessibility adjustments, both bounds and stale usual bounds around large imported coordinates. These are meaningful modeled regressions; native control delivery remains a separate test.

Raw log hashes: before `5fb28207371123c61beac7ca67f1c4959379b542b21b5a90c428dbe9af92c8e4`; Debug `b7b13d92d00b0a7d5839438233c56e9ce4a006743e8e65aef13a6102cfb458f9`; Release `dc4fc29b2cae32c36421170741e4bfeb34ad88b072d23f22222a2aca81e959e2`.

The integration lead's existing 251/251 core Debug/Release results identify base `816e7123`. They must not be presented as a current native build or as execution of the newly edited SwiftUI wrapper/export flow. The next acceptance run must compile those files with the Apple SDK and execute the retained optics, camera and export scenarios, plus actual accessible adjustment/dismissal behavior. Existing failures and the interrupted shard remain failed/incomplete evidence until that occurs.

## Reviewed working-source hashes

| File | SHA-256 |
| --- | --- |
| `App/LightingPlanExportView.swift` | `3d1dc11075de730dd69aff69b86f3b887665cbb5a4ad2ced8da34e74d32fc75e` |
| `UITests/LightingPlanExportUITests.swift` | `cb0ae59a292d58e490dcf8389ff9cf81c39b95bb62e6eea73180d92635eb55e7` |
| `App/StudioSliderEditing.swift` | `b3dc9f5c002f9d68a29034b357cf3514e79f7bca29eb50a073dfab01ab952115` |
| `App/StudioSlider.swift` | `a144109d5137e414da17da1c437dbed5dfe7cd71b3b53a0890df5b95e5f24cff` |
| `App/StudioView.swift` | `2bf6e57bb53e2549493251047bc17ec7bb9fdb23ee8a2770b6756c61907be221` |
| `App/CameraInspector.swift` | `39c5cef83e1cd6b0a958a7adb982feac689c1b948608e69267f48f77a00b220e` |
| `App/OpticsInspector.swift` | `905b03832c3374085c0f520abcc9d56c40536f252d5f2814f4a6271477b2f512` |
| `App/NeutralCardInspector.swift` | `689e6992473463d1a69b8c748038c9397e0a9c108cd5b2d34d21aab2eef8a36a` |
| `NativeTests/StudioSliderEditingTests.swift` | `1b1edc611bd2ddd918b555c675d5c898025ffab765dc67b6baf961f49d36f4e9` |
