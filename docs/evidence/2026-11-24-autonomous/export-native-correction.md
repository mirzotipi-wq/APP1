# Export presentation native failure diagnosis and correction

## Observed failure

The `studio-export` UI shard for source `ff8b683098a720b4c7abdddf212f85a79f3cfd39` failed both methods in `LightingPlanExportUITests`. These are actual failures, not a passing baseline. The raw evidence is `/workspace/scratch/73dcd6a65726/verification/ff8b683-studio-export-native-tests.log` from [GitHub Actions run 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829).

| Scenario | Last successful interaction | Observed stall |
| --- | --- | --- |
| PDF preview from the unsaved default studio | `prepareLightingPlanPDF` was found and tapped at 78.62 seconds | The event loop did not report idle for 60 seconds. Querying `lightingPlanPDFPages` subsequently timed out; the method failed after 356.692 seconds. |
| Editable copy from a full project library | Saved project identity, the added fourth light, unsaved status and undo availability were all observed before `prepareEditableProjectCopy` was tapped at 40.75 seconds | The event loop did not report idle for 60 seconds and animations did not report completion. Even the static `editableCopyProjectName` label could not be observed; the method failed after 120.329 seconds. |

The following camera test could not terminate the previous app process. That failure is consistent with contamination from the preceding stall, but does not establish a camera implementation defect or prove a particular presentation framework bug.

## Diagnosis and limits of the evidence

Both export actions were buttons in a transient SwiftUI `Menu`. The menu owned two sibling sheet modifiers, one Boolean-driven for PDF and one item-driven for the editable copy. A menu action immediately changed presentation state while the menu itself was dismissing. This created a shared presentation lifecycle risk: the app requested a new modal from a control whose own presentation was being torn down, with separate state and presenters for the two destinations.

The editable-copy screen creates its name and light-count labels independently of document preparation. Its JSON preparation already runs in a detached task. Failure to observe that immediate screen, at the same action boundary as the PDF case, supports removing the shared presentation transition first. It does not support solving this only by moving PDF work to another executor or increasing waits.

There is also direct native evidence that the PDF generator can complete: the separate `ff8b683` native test log records all three `LightingPlanPDFTests` passing. The 12-light/both-paper-sizes method took 0.143 seconds and the precision method took 0.166 seconds. The first empty-scene method took 29.315 seconds, so these results are not a claim that cold preparation is instantaneous or a device performance benchmark. The renderer is explicitly `@MainActor` and uses UIKit; this correction does not bypass that isolation.

No process stack, hang report or view-hierarchy capture is included in the downloaded UI artifact; its six entries are build/environment/test logs and simulator metadata. The evidence therefore supports a concrete lifecycle correction and a native regression test, not a conclusive attribution of the hang to a specific UIKit or SwiftUI internal defect. Native execution of the corrected candidate is required to establish whether this resolves the observed stall.

## Minimal presentation correction

`App/LightingPlanExportView.swift` now has one export button and one item-driven sheet. Tapping Export captures the current project name, complete scene value and text settings in a fresh immutable snapshot. The sheet initially shows the snapshot's name and light count with the existing PDF, editable-copy and text-sharing choices.

Selecting PDF or editable copy changes local content inside that existing sheet. It does not dismiss a menu, replace the sheet item or request another sheet. Each screen's existing Done action dismisses the same sheet. Cancelling the format chooser also dismisses it. A new snapshot identity on every subsequent open resets the format choice and prepared screen state.

The correction retains the existing export button and format-action accessibility identifiers. It adds identifiers for the format chooser's snapshot labels and Cancel action, plus an unambiguous PDF Done action.

The resulting behavior preserves these contracts:

- Unsaved scene changes are captured, including when all 64 project slots are occupied. The flow does not depend on library mutation permission or available capacity.
- PDF, editable copy and text settings all use the same snapshot captured when Export opens. A later export captures the then-current scene, including changes made by undo or redo.
- Opening, preparing, cancelling and dismissing export do not save or switch projects and do not add, consume or clear edit-history commands.
- Existing PDF generation, page-count checks, PDF sharing, JSON validation and the real system `fileExporter` remain intact.
- The editable-copy screen continues to exclude reference photos, room measurements and edit history. It continues to claim a saved copy only after the real exporter reports success; preparing a document or cancelling does not produce success text.

No `StudioView`, `ProjectBackupView`, renderer, persistence or history implementation change is needed for this correction. There are no fixed delays, test-specific presentation branches or increased preparation timeouts.

## Native regression coverage

`UITests/LightingPlanExportUITests.swift` keeps the existing PDF page/share assertions, editable-copy preparation and scope assertions, full-library fixture checks, unsaved fourth-light checks, undo/redo checks and relaunch verification.

The updated tests additionally:

1. Observe the interactive format chooser and exact snapshot identity/light count before selecting a format. They also require that neither document screen has already appeared.
2. Cancel the chooser, verify the unchanged unsaved status and empty history, then reopen and prepare the PDF.
3. In the full-library scenario, prepare the four-light copy, dismiss, reopen the same export control for a PDF, dismiss, undo the fourth light, and reopen for a three-light copy. This exercises alternating destinations and fresh state after dismissal while preserving the original redo and relaunch checks.
4. Require the PDF's specifically identified Done button to dismiss its screen and restore the interactive studio export button.

All original 15-second document-preparation limits remain. The label fallback for the old PDF menu item was replaced with a required stable-identifier assertion. No system save destination is selected by these tests, so they do not claim that a file was written successfully.

## Verification of this correction

The correction was made against working-tree base `816e712` and left unstaged for parent integration.

Executed successfully on Linux with Swift 6.4.3:

```sh
/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc -frontend -parse App/LightingPlanExportView.swift UITests/LightingPlanExportUITests.swift
git diff --check -- App/LightingPlanExportView.swift UITests/LightingPlanExportUITests.swift
```

These checks establish syntax and patch whitespace only. Apple SDK compilation, corrected simulator UI execution, visual inspection, real-device behavior and actual system save/cancel/error interaction remain unverified. The failed `ff8b683` UI run must remain recorded as failed.

## Primary platform references

- [Apple: sheet(item:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)) documents the item as the sheet's data source and explains that changing it can dismiss and replace the sheet. The new flow keeps that item unchanged while selecting its internal destination.
- [Apple: DismissAction](https://developer.apple.com/documentation/swiftui/dismissaction) documents dismissal through the presented view's environment. Both existing document screens and the chooser obtain the dismissal action inside the sheet's content.

These references describe the API contracts used by the correction; they do not document or prove the observed hang.
