# Studio Guide — isolated author report

Status: **corrected iteration 2 frozen for independent review completion; not integrated, native-built, visually accepted or counted complete.**

Base: committed main `6752f4dd0acea314b58d5a31b4d5e6f8c4f23bc7`, as assigned. Work is confined to this candidate directory. No live source, protected documentation, state, ledger, staging, commit or remote write was performed. The separate slider/plan packet remains under the integration lead's control.

## Confirmed product gap and layout evidence

The current App, core and UI-test searches for onboarding, tutorial, walkthrough, help and guide implementations found reference-specific guided alternatives, but no reachable end-to-end Studio usage guide. The proposed addition is contextual help that a user explicitly opens. It does not claim to deliver comprehensive first-launch onboarding.

I viewed the actual source-nine native capture at `APP1/docs/evidence/2026-11-24-autonomous/source9-library-visual/recovery.png`. It shows the existing Projects/Export action area, a long recovery-project title, and the Studio content. This is existing-layout evidence, not a rendering of this candidate or proof of its layout at the new revision.

## Independent correction — iteration 2

The independent reviewer found one factual error in the initial guide: it described the Plan grid as always 1 meter. I confirmed that `StudioOverheadProjection.grid()` in `Sources/LightingCore/StudioSceneBounds.swift` selects adaptive 1/2/5-times-a-power-of-ten spacing, and that `testGridStaysBoundedImmediatelyAbovePaddingThresholdAndInNarrowView` explicitly covers spacing greater than 1 meter. StudioView renders the selected spacing in the Plan caption.

The corrected copy is: **“Plan shows the overhead layout. Read its caption for the current grid spacing.”** The remainder of the step and all other guide copy stay unchanged. The initial author packet, original hashes, report and raw logs are preserved under `iterations/initial`. The exact one-sentence delta is in `guide-wording-correction.patch`.

The assigned base remains `6752f4d`. Neither existing-source copy nor its integration patch was rebased or changed. The corrected combined patch was checked read-only against source 11, `95e9c2446b7bb05e6df38d103063b4254bb07c92`. The reviewer reported the remaining source review clear so far; final independent review is still the reviewer's responsibility.

## Candidate changes

| File | Scope |
| --- | --- |
| `App/StudioGuideView.swift` | New read-only native sheet with a workflow index and six topic pages. |
| `App/StudioView.swift` | One presentation Boolean, one direct sheet, a compact Guide action, and adaptive layout for the existing header actions. |
| `UITests/StudioSmokeTests.swift` | One regression method appended after the existing corrupt-project scenario. All seven prior methods are byte-for-byte unchanged. |

The Guide action has a 44 × 44 point target, a question-mark-circle symbol, the explicit accessibility label **Studio guide**, a useful hint and identifier `openStudioGuide`. Projects retains its visible label and original disabling conditions; Export retains its action, identifier and scene-snapshot behavior. The Guide is disabled during a library operation or active continuous edit. It otherwise changes only its own presentation Boolean.

The root-owned dismiss action is available as **Done** on both the index and pushed topic pages. Native navigation supplies Back. No scene, selection, project-store, reference-image or room binding is passed to the sheet. The guide has no persistence, tasks, network requests, permission prompts, generated imagery, automatic presentation or editor mutation callbacks.

### Header width correction

The integration lead identified a concrete risk: appending another icon to a normal 402-point phone header could compress the title or Projects label. The candidate addresses it explicitly:

1. The compact header candidate measures both the project heading and complete action group at their ideal horizontal sizes.
2. If both do not fit, the existing native `ViewThatFits` fallback puts the heading above the actions.
3. Within the actions, a second `ViewThatFits` keeps labeled Projects, Export and Guide together when their full widths fit. Otherwise Projects appears above the two 44-point icon actions.

No font shrinking, guessed width threshold, title-line-limit change or hidden Projects label is introduced. All help text uses semantic native fonts and can wrap vertically. Actual phone-width and Dynamic Type behavior still requires Apple-native visual verification.

Apple's primary API documentation was consulted for this decision: [ViewThatFits](https://developer.apple.com/documentation/SwiftUI/ViewThatFits) selects the first child's ideal size that fits the constrained axes; [fixedSize](https://developer.apple.com/documentation/swiftui/view/fixedsize()) explains preserving ideal size. The code uses that behavior as a layout choice, not as a substitute for a screenshot.

### Guide coverage

| Topic | Implemented workflow and truthful boundary |
| --- | --- |
| Start with a recipe | Recipes; Three-point portrait, Rembrandt, Butterfly and Silhouette; replacement of the current setup; Undo and Save. |
| Edit the lighting | Plan or Lights selection; Add light; exact values and Apply value/Cancel; meters, candela and kelvin; Emitter choices, softbox dimensions and aim; Undo/Redo. |
| Read the previews | Plan grid-spacing caption; 3D orbit and **Fit setup**; camera position/lens; Study **Sphere/Bust**; Meter, white balance and relative exposure; diagnostic/illustrative scope. |
| Explore a reference | Choose photo; manually supplied cues; Build two starting rigs; observed versus assumed values; compare current setup; confirmed rig application; camera/subject preservation and separate saving; ephemeral photo copy. |
| Measure the room | Measured wall distances; explicit Set for drafts; relative rotation; equipment-center and emitting-face projections; physical clearance checks; session-only room measurements and separate notes. |
| Save and share | Save and Saved locally; Projects; PDF as a readable plan; editable copy for reimport into a separate project; unsaved export snapshot; photo/room/history exclusions. |

Control names and limitations were checked against `StudioView`, `OpticsInspector`, `NeutralCardInspector`, `ReferenceComparisonView`, `ManualRoomPlacementView`, `LightingPlanExportView`, `ProjectBackupView`, `ProjectLibraryView`, `StudySubject` and `GuidedLighting`. In particular, the actual labels are **Fit setup** and **Bust**.

## The single native regression

Added method:

`StudioSmokeTests/testStudioGuideKeepsUnsavedSetupSelectionAndHistory`

It is written to:

1. Launch a uniquely isolated unsaved three-light Studio, add two lights, then Undo once to leave four lights and both history branches available.
2. Select Key in Plan and record the project name, unsaved status, selection and actual light membership.
3. Check the Guide target is at least 44 points in both dimensions and the existing Projects/Export actions remain hittable.
4. Open the guide, attach an actual `Studio-guide-overview` screenshot when executed, navigate to the reference topic and back, then dismiss the entire sheet with Done from the saving topic.
5. Verify the same project name, unsaved status, Plan mode, selected Key and four-light scene after dismissal.
6. Exercise the retained Redo and two Undo entries, asserting actual five-, four- and three-light results and the expected added-light membership. Checking enabled arrows alone would not prove history preservation.

It remains in the existing StudioSmokeTests class and studio-export shard. No scenario or assertion was removed or weakened.

**This XCTest has not run. No screenshot of the candidate has been captured.**

## Actual local verification

At **2026-11-24 12:35:12 UTC**, Swift 6.4.3 on Linux parsed all three corrected candidate Swift files in Swift 5 language mode with exit 0 and no diagnostics:

```sh
/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc -frontend -parse -swift-version 5 App/StudioGuideView.swift App/StudioView.swift UITests/StudioSmokeTests.swift
```

Working directory was this candidate directory. Raw output is in `native-parse.log`. There is no `xcodebuild` on the host. This establishes syntax only, not SwiftUI type checking, native target compilation or behavior.

At **2026-11-24 12:35:12 UTC**, source verification confirmed:

- The preserved initial packet matches all original source, base, patch and log hashes.
- The guide source differs from that packet by exactly the requested grid sentence; StudioView, StudioSmokeTests and their narrow patches remain byte-for-byte unchanged.
- Both preserved base files exactly match committed `6752f4d`.
- The previous seven StudioSmokeTests methods are byte-for-byte intact; exactly one method is appended in the same class.
- The unchanged shard validator assigns all six UI classes once, including StudioSmokeTests in studio-export.
- `git apply --check --whitespace=error candidate.patch` passes against source 11 at HEAD `95e9c2446b7bb05e6df38d103063b4254bb07c92`. The patch was not applied.

See `source-verification.log` and `manifest.json` for exact output and SHA-256 values. No Swift build cache, full portable build, native execution or benchmark was created for this static-help change.

## Merge guidance

Use the narrow patches, not replacement copies of StudioView or StudioSmokeTests: their full candidate copies were intentionally derived from the assigned committed base, before the integration lead's live plan and slider changes.

- `studio-guide-view.patch`: adds the new App file.
- `studio-view.patch`: state, sheet and header/action-layout hunks only. It does not touch the plan, actor, generation, scene-action or history implementations.
- `studio-smoke-tests.patch`: appends one method at the end of the existing class, after `testCorruptProjectBlocksSavingAcrossRelaunch`. It does not overlap the optics/slider scenario.
- `candidate.patch`: combined form of those three patches.
- `guide-wording-correction.patch`: review-only delta from the preserved initial guide. The correction is already included in the new-file and combined integration patches.

The XcodeGen project already includes the App and UITests directories. No project, shard or workflow configuration change is required.

## Outstanding acceptance

The integration lead must choose whether to integrate this independent follow-on packet after review. It is deliberately separate from the higher-priority slider/plan source packet.

Required native follow-up:

- Compile the exact integrated source with an Apple SDK.
- Run the new focused XCTest and inspect its real screenshot and state assertions.
- Inspect the short **Portrait setup** title and a long saved-project title at the actual 402-point phone width, a narrower phone width and large accessibility text sizes. Confirm title/actions reflow without overlap or unintended compression, all primary labels and 44-point targets remain usable, and guide pages wrap and scroll naturally.
- Confirm native Back and Done behavior from topic pages and read all six topics on the live build.

No native or visual pass, independent review, integration, completed-task count or first-launch-onboarding claim is made by this report.
