# Full-library recovery native UI correction

## Observed failure

Exact source `ff8b683098a720b4c7abdddf212f85a79f3cfd39`, [run 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829), [library/reference UI job 138342789365](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/job/138342789365), completed eight UI methods with **seven passing and one failing**. The runner used Xcode 26.6 (17F113), iOS Simulator SDK 26.5 and an iPhone 17 Pro simulator.

`testFullLibraryRecoveryRequiresConfirmationAndPersistsEditedSetup` failed at `ProjectLibraryUITests.swift:253`, during the destructive confirmation tap. Its preceding assertions reached the real full library, added the fourth light, triggered a competing saved-library transaction, opened recovery, cancelled the confirmation and sheet, verified the unsaved light remained, and reopened the same archived choice. The tap did not execute; the recovery save and subsequent relaunch assertions were not reached.

The completed job log reports:

```text
Failed to tap "confirmRecoveryReplacement" Button:
Find single matching element. Multiple matching elements found.
```

The sparse accessibility tree contains a single alert and a nested pair of matching buttons:

```text
Alert, label: 'Replace archived project?'
  ...
  Button, identifier: 'confirmRecoveryReplacement', label: 'Replace and save setup'
    Button, identifier: 'confirmRecoveryReplacement', label: 'Replace and save setup'
```

This establishes duplicate accessibility exposure within one action's hierarchy; it does not show two independent destructive controls or duplicate store writes. The ordinary `Cancel` action in this same dialog was found and tapped successfully. Other unmodified system-alert actions also passed in this shard.

## Correction

- Remove the custom `accessibilityIdentifier` modifier from the destructive action inside SwiftUI's system alert. Retain its visible and accessible “Replace and save setup” label, destructive role, confirmation message and existing transactional callback. This follows the plain native-action pattern already used by the passing cancellation and archived-deletion dialogs. The nested nodes are consistent with identifier propagation through the alert's accessibility wrapper; exact framework internals are not claimed.
- Query the action by its exact user-visible label, scoped to the named confirmation alert. Require **exactly one** matching button before tapping, and retain a hierarchy plus screenshot if uniqueness fails. No `firstMatch`, coordinate tap, hidden duplicate control, or relaxed result assertion is used.
- Preserve cancellation, four-light content, saved-state and relaunch assertions. Preserve the existing separate stale-save scenario that reopens “Other window” and verifies its original lighting scene.
- Make no changes to persistence, capacity limits, archived-record identity checks or recovery semantics.

## Verification

- Swift frontend parsing of `App/RecoveryCapacityView.swift` and `UITests/ProjectLibraryUITests.swift`: passed on Linux Swift 6.4.3.
- Native shard coverage validation: passed; all six UI classes remain assigned exactly once across three shards.
- Scoped diff whitespace validation: passed.
- Corrected Apple SDK build and native UI execution: **pending**. The previous failed run remains failed. Removal of the identifier is a source correction awaiting confirmation that the native accessibility tree now contains one action.
- Physical-device accessibility, data-integrity release gates and overall M01 closure are not established by this correction.
