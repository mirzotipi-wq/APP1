# Studio Guide — independent review of iteration 3

## Decision and scope

**The runtime candidate is suitable for a separate follow-on integration after source 11. No remaining concrete runtime source blocker was found after correcting the grid wording.** Root must independently inspect the four reviewer-authored test lines identified below before integration. Apple SDK compilation, the new UI scenario, actual layout and accessibility remain unverified. This is contextual help opened by the user; it does not complete first-launch onboarding or any release gate.

Reviewer: existing `/root/w09_ios_critical_review`. Original author: existing `/root/w01_native_design_audit`. No new agent was spawned. Runtime code was reviewed independently and was not edited by the reviewer. Root subsequently authorized two narrow assertions in the isolated new UI method; their authorship and separate review requirement are recorded explicitly. No live-tree edit, staging, commit, broad test suite or benchmark was performed by this review.

Assigned base: `6752f4dd0acea314b58d5a31b4d5e6f8c4f23bc7`. The three narrow patches were checked read-only against source 11, `95e9c2446b7bb05e6df38d103063b4254bb07c92`, which already contains the separate slider and plan corrections. The candidate's full copies of StudioView and StudioSmokeTests still derive from the assigned base and must not replace the live files.

## Frozen files

| Artifact | SHA-256 |
| --- | --- |
| [StudioGuideView.swift](App/StudioGuideView.swift) | `f4f2d187a336e5f7ace88028c8c22492e2ad67e0345ac34f33d9f0465f0b2b19` |
| [StudioView.swift](App/StudioView.swift), isolated full copy | `30df58032669269846c36e85bd1fb56c15dff0d24a5fd1fa8f3935ddd62bb35d` |
| [StudioSmokeTests.swift](UITests/StudioSmokeTests.swift), isolated full copy | `55aa126adde7c08de616f0b9478982465d85df1f81ed55505ee2c04e08073f06` |
| [Combined integration patch](candidate.patch), 20,352 bytes | `8916ee564cb7fecf72b2d88b2cb21bc525287d533db60d11b74520f390a50dca` |
| [Manifest](manifest.json) | `2ccf24c0e8ce5ad842080a88b3781cdf1d0b2b96bfcd7ec11f6f676204a6d3bd` |
| [Author report with attributed reviewer update](AUTHOR-REPORT.md) | `f34403cc029ca5a7a8c47ccdefd7c6c8521ec06ce96a65c3f6f423e571ca6f72` |
| [Reviewer-authored test delta](guide-toolbar-assertions.patch), four added lines | `d62189ac6e3681869b01e97d4b4d9d2b8c2830c9b16ab84a71b79a62d4e424d8` |

The original author packet remains under [iterations/initial](iterations/initial/manifest.json), and corrected iteration 2 remains under [iterations/iteration-2](iterations/iteration-2/manifest.json). Their manifest hashes are respectively `1a7fe8f666008a8f406ccc7d0c609bf250655b5e702361a8d61f064be812a0e4` and `f466199c79f7a891b2e825ecc97a6c1366afece0a300f945636bfcbff017655c`. All 24 entries in those two preserved manifests were checked and match. The current manifest records the final 14 source, base, patch, report and log hashes.

## Concrete finding corrected

The initial guide said Plan used a fixed one-metre grid. That is false for supported wide layouts: `StudioOverheadProjection.grid()` in `Sources/LightingCore/StudioSceneBounds.swift` chooses bounded 1/2/5-times-a-power-of-ten spacing, and StudioView displays the selected spacing in its caption. Existing `testGridStaysBoundedImmediatelyAbovePaddingThresholdAndInNarrowView` expressly checks spacing greater than one metre. This finding follows the actual source and existing assertions; the reviewer did not rerun that test or claim a new native reproduction.

The author changed only the incorrect opening sentence to: “Plan shows the overhead layout. Read its caption for the current grid spacing.” The [exact wording delta](guide-wording-correction.patch) and the original source remain available. Independent comparison confirmed that no other guide wording changed between initial and corrected iteration 2. Runtime source is unchanged between iterations 2 and 3.

## Workflow wording checked against implementation

| Topic | Actual source checked and conclusion |
| --- | --- |
| Recipes | `LightingRecipe` supplies the four named choices; StudioView replaces the scene through history and keeps saving separate. The guide describes these as starting arrangements. |
| Editing | Plan/list selection, both Add-light controls, exact-value pencil action, Apply/Cancel, units, emitter names and aim controls match StudioView, PrecisionValueButton and OpticsInspector. |
| Previews | The corrected grid caption, actual **Fit setup** action, **Sphere/Bust** choices, camera controls and neutral-card settings match the implemented views. The guide explicitly distinguishes illustrative shading and diagnostic direct-light models from calibration or person reconstruction. |
| Reference | The four manually entered cues, direction prerequisite, two alternatives, provenance text, confirmation and separate Save match ReferenceComparisonView and GuidedLighting. The candidate scenes preserve camera/subject and replace lights. The photo copy is session-only; automatic image inference is not promised. |
| Room | Width/depth/wall offsets use explicit Set actions. Rotation, center coordinates and emitting-face projections match ManualRoomPlacementView. The text preserves the manual-measurement and physical-clearance limitations, and separates room notes from saved projects/PDFs. |
| Save/export | The Saved locally receipt, project organization, PDF/editable-copy labels, import as a separate project, immutable export snapshot and photo/room/history exclusions match the actual project and export flows. Export is not described as saving the active project. |

No payment, AR scanning, reconstruction accuracy, calibrated exposure or other unimplemented capability is advertised. The guide's prose is product help; it does not claim the acceptance results that are still missing under `docs/QUALITY.md`.

## State, ownership and native API assessment

StudioView adds one presentation Boolean and a sheet. The guide receives no scene, selected-light, project-store, photo or room binding, and no mutation callback. It contains no task, file write, network operation, permission request or persistent preference. Navigation is local to its own NavigationStack. Opening the guide is disabled during an active continuous edit or library operation. The existing history, actor, generation guards, save operations and scene actions are untouched by the runtime patch.

The dismiss environment is declared in StudioGuideView, which is the sheet content. The root and topic close buttons therefore capture the sheet's dismiss action rather than reading a new destination-level action. This follows Apple's documented requirement that [DismissAction](https://developer.apple.com/documentation/SwiftUI/DismissAction) be obtained from the intended presentation's environment. Native Back remains a separate navigation action. Whether the actual Back and Done controls render and behave correctly still needs execution.

Root specifically questioned the two `.confirmationAction` declarations, one on each navigation page. They are attached to separate root/destination Lists, not both to their common stack. Apple's [navigation guidance](https://developer.apple.com/documentation/swiftui/navigation) describes page modifiers affecting the container while that page is shown, but the reviewed documentation does not establish the exact merge/replacement behavior of this pair of toolbar items. No duplicate has been observed. Moving the modifier outside NavigationStack would change its host scope without native evidence, so root chose to keep the current per-page pattern and make the concern an explicit native assertion.

With root's authorization, the reviewer added exactly two `count == 1` assertions for `closeStudioGuide`: one on the overview and one on the pushed saving page. The [four-line delta](guide-toolbar-assertions.patch) contains the entire reviewer-authored source change. It does not weaken another check or alter runtime behavior. Root provides its independent review; the reviewer does not count self-authorship as independent approval of those lines. Actual toolbar uniqueness and dismissal remain pending.

## Adaptive header and accessibility

The first header alternative gives both the project heading and complete action group their ideal horizontal sizes. If that row cannot fit, the title is placed above the actions. Accessibility text sizes take that vertical route directly. Within the actions, a second horizontal fit chooses a labeled Projects/Export/Guide row or Projects above the icon pair. There is no guessed screen-width threshold, font shrinking, new title truncation limit or hidden Projects label.

This use is consistent with Apple's [ViewThatFits](https://developer.apple.com/documentation/SwiftUI/ViewThatFits) selection rule and [fixedSize(horizontal:vertical:)](https://developer.apple.com/documentation/SwiftUI/View/fixedSize%28horizontal%3Avertical%3A%29) ideal-size behavior. That is a source rationale, not a prediction of exact native frames. Short and long titles, a 402-point phone, a narrower phone and large accessibility text sizes still need actual inspection. Existing export presentation is owned inside the adaptive header alternatives, so resizing while an export is open is also a useful native lifecycle check; no disappearing presentation has been observed.

The Guide action has an explicit accessible name, hint and identifier and requests a 44-by-44-point frame. Topic links have explicit titles/hints, decorative numbers are hidden from accessibility, body text uses semantic fonts and vertical wrapping, and Done requests at least 44 points. These provisions support the intended behavior. They do not establish measured hit bounds, native AX element counts, VoiceOver focus order, contrast across appearances or Dynamic Type acceptance. The new test measures the Guide frame and checks that Projects and Export remain hittable; it cannot replace the missing visual/manual audit.

## Regression quality and retained coverage

The new method creates a real unsaved five-light scene, undoes to four, selects Key and leaves both history directions available. It opens the guide, visits a topic, uses native Back, visits another topic and dismisses the sheet with Done. It then checks the project name, unsaved status, mode, selection and actual added-light membership, and executes Redo followed by two Undos to require five-, four- and three-light results. Those scene/history assertions are meaningfully stronger than only checking enabled arrows. They do not compare every numeric scene field; read-only ownership is established separately by source inspection.

Independent comparison confirmed the entire pre-existing class prefix, including all seven baseline test methods and helpers, remains byte-identical to the assigned base. Exactly one method is appended. The integration patch does not touch source 11's strengthened optics scenario. The new method remains in StudioSmokeTests, already assigned to the studio-export shard; no class, shard, timeout or existing assertion is removed or relaxed.

## Verification and next acceptance

The author retained the original and corrected syntax/source evidence. After the authorized four-line change, the reviewer ran only the same bounded syntax parse of the three current Swift files: Swift 6.4.3 on Linux, Swift 5 language mode, `-frontend -parse`, exit 0 with no diagnostics at **2026-11-24 12:42:15 UTC**. The [raw parse record](native-parse.log) explicitly excludes Apple type checking and XCTest execution.

The [source-verification log](source-verification.log) records the preserved hashes, exact four-line delta, unchanged runtime files, base-file comparison, seven-method preservation and successful `git apply --check --whitespace=error` against source 11. No patch was applied to the live tree. XcodeGen already includes App and UITests directories, so no project-generation change is required.

The integration decision should use the narrow patches and preserve source 11. Required follow-up is an Apple build at the eventual integrated revision, execution of the new UI method, inspection of its genuine screenshot, and native checks of the adaptive header and all six topics. Exactly one Done action must exist on both navigation levels, Back must return to the index, and topic Done must dismiss the whole guide without changing the scene/history. Current source-11 results cannot be credited to this unintegrated candidate. No native, visual, accessibility, onboarding-completion or release-readiness pass is asserted here.
