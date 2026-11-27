# Key & Fill beta tester guide

This guide is a checklist for an **engineering candidate** (27 November 2026), not evidence that these steps passed on a device. Record the version/build and **Source revision** under test. Native UI and physical-device acceptance remain unverified. The campaign has not supplied signing or owner distribution approval. An unsigned simulator build or device app ZIP does not establish an installable beta or beta acceptance; use an owner-authorized test build when one is provided. See the [current implementation status](evidence/beta-development-2026-11-27-16f31723/README.md), [earlier beta progress](evidence/beta-progress-2026-11-27-0eff52f/README.md), [distribution scope](BETA_DISTRIBUTION.md) and [release gates](QUALITY.md).

## 1. Create, edit and reopen a local project

Use a disposable setup for testing. Open **Studio tools** (the sliders icon) → **Settings** to check **Version**, **Source revision**, **Distance units** and **Appearance**. Record the complete 40-character source revision, or **Unavailable** if the build has none; version/build alone may identify more than one code revision. The **Studio guide** question-mark button remains available after dismissing the welcome card.

For the current development configuration, open **Purchase options** in Settings. Check that **Purchases unavailable** is shown, the **Purchase unavailable** and **Restore Purchases** buttons are disabled, and current features remain usable without a purchase. Choose **Done** to return to Settings. Record a differently configured owner-provided build separately; this disabled-state check is not a purchase or restore test.

1. On a fresh, untouched first-use setup, either choose **Save current setup** to keep the displayed portrait, or open **Projects** → **New project**, enter a **Name**, and choose **Save project name**. New project creates a named portrait setup.
2. To start from a backup instead, choose **Projects** → **Import editable project** and select one Key & Fill editable `.json` file. A valid import creates a separate project and keeps existing saved projects. An untouched first-use starter need not be saved first.
3. Select a light, change one setting, and try **Undo** and **Redo**. Choose **Save** and check that the project status becomes **Saved locally**. Close and relaunch the app, then verify the same project and setting reopen. Record what actually happens.
4. In **Projects**, try search, **Rename** and **Duplicate** through a project's options menu. Switch to another saved project before archiving the first; the current project cannot be archived. **Restore** returns an archived project. Permanent deletion requires its own confirmation and cannot be undone in the library.

After a successful **Save**, check the confirmation beside the persistent Save/Undo/Redo controls. Tap its info button (**Project message details** with VoiceOver) to read the complete **Project status** message, including at the largest text size. Selecting another light without editing should keep that confirmation. Changing a setting should remove the old success message; **Undo** or **Redo** must not revive that old confirmation. This message is separate from the **Saved locally** / **Unsaved changes** status. If a save fails, read the full error, check that your edits remain open, and do not count it as a successful save.

Set iOS to its largest accessibility text size, scroll through the light list and check that each light's name, type, distance, temperature, output and selection mark remain readable in its stacked row. Select a light and tap the value with the pencil for **Horizontal** (**Enter exact horizontal** with VoiceOver). Replace the value with a decimal within the displayed **Allowed** range, using your current decimal separator. Check the complete draft before choosing **Apply value**, then check the result, **Undo** and **Redo**. Reopen the editor, change the draft and choose **Cancel**; the accepted value should remain. With the keyboard open, check that the field, **Apply value** and **Cancel** remain reachable by scrolling. Record clipped text, missing digits or unreachable controls.

For a selected light, open **Light actions** → **Set ideal lux**. Enter a nonnegative target using your current decimal separator, then choose **Apply to light**. The calculation changes that light's modeled output while retaining its geometry. If the number format changes while the editor is open, the app keeps the text and asks you to edit it before Apply becomes available. If an Apply attempt is rejected, check that the entry remains in the open sheet with an error; retry as directed or choose **Cancel**. Try **Undo** and **Redo** after acceptance, then **Save** to retain the output. See the [target-lux editor](../App/LightTargetLuxView.swift).

Open **Studio tools** → **Arrange setup**, change a position or lighting rotation, then choose **Cancel** and confirm the studio did not change. Repeat and choose **Apply arrangement**; check the result and one-step **Undo**. If Apply is rejected, the sheet should retain your position, rotation and mirror choices with an error. Record rejection branches as unavailable if they do not occur; do not damage saved data to force them.

If **Unsaved lighting setup** appears in Projects, choose **Save current setup** before creating, importing, switching or organizing projects. Saving is explicit; leaving an editor or exporting a copy is not a project save. Save before relaunching; the saved-file recovery below does not promise recovery of unsaved edits after app termination. If **Saved library changed** appears, **Save setup as new project** preserves your open setup separately. **Reload latest saved library** asks before discarding this window's unsaved edits.

Source: [studio](../App/StudioView.swift), [exact-value editor](../App/PrecisionValueButton.swift), [arrangement](../App/SceneArrangementView.swift), [project library](../App/ProjectLibraryView.swift), [session and save feedback](../App/StudioSession.swift).

## 2. If the saved library cannot open

**Saved project unavailable** disables saving to protect existing data. Try **Retry loading saved project**; a newer authorized app version may be needed if the files came from a newer version.

If loading still fails, open **Review recovery options**. The **Recover saved library** screen checks the saved files without changing them. Read the file count and size, then choose **Review starting again** only if you want a fresh library. **Cancel** leaves that confirmation without starting recovery. **Keep files and start again** explicitly confirms the operation.

Recovery keeps copies of the original files on this device before creating a new library. **It does not repair the files or restore the old projects.** Wait for the displayed result. After **New library is ready**, choose **Done** → **Projects** → **Import editable project** to restore a project from your separate JSON backup. Preserved original files are not a substitute for that backup or an in-app restore feature.

If files changed after inspection, check them again before confirming. If checking or recovery fails, record the exact message; do not treat it as success or deliberately damage a real library to test recovery.

Source: [recovery screen](../App/ProjectLibraryRecoveryView.swift), [preservation implementation](../Sources/LightingCore/ProjectLibrary.swift).

## 3. Reference photos and manual lighting

Choose **Reference photo** → **Choose photo** and select a still image you are authorized to use. Review the on-device key-side check and its limitations. **Use suggested side** accepts only that tentative cue. You can choose **Key side**, **Shadow edges**, **Shadow fill** and **Rim highlight** yourself, then choose **Build starting rigs**. If a suggestion or starting rig is unavailable, continue editing lights manually in the studio.

With a photo open and a manual cue selected, choose **Replace photo**, then cancel the system picker. Check that the previous photo and guided choices remain. If **Preparing photo…** is visible during a replacement, try **Cancel replacement** and check the same retained state. If the selected provider denies access or cannot retrieve an image, record the displayed error and check that an existing photo and guided work remain available. Mark a failure or cancellation branch unavailable if you cannot exercise it. This implementation uses the selected-photo picker without requesting broad Photos access; record the permission/provider state actually observed rather than expecting a whole-library authorization prompt.

Select a candidate, review its assumptions, then choose **Apply selected rig** → **Apply rig**. An accepted application closes Reference and replaces lights while retaining camera and subject positions. **Undo** restores the previous lights; **Save** is still required. If the rig is rejected, check that Reference stays open with the photo, selected rig and error; rejection must not consume that work. Record this branch as unavailable if it does not occur.

Before applying a rig, try these photo-lifetime checks:

1. Choose **Compare a test shot**, add a test photograph, and try side-by-side/wipe comparison. Choose **Done**: the still-open Reference screen should retain its own photo and guided work. Reopen comparison: the reference is seeded again from that screen, but the previous test shot should be absent. **Clear both photos** clears the comparison's slots, not the parent Reference photo.
2. Close Reference with **Done** or a completed dismissal gesture, then reopen **Reference photo**. It should start without the previous photo or guided draft. A cancelled dismissal gesture, like temporarily opening and cancelling a photo picker, should retain the open session. Record gestures unavailable on your presentation/device as unavailable.
3. If an import remains in progress long enough, close Reference before it finishes, then reopen it. A late completion must not repopulate the new session. Record the branch as unavailable if the import finishes too quickly.

These are plausible starting arrangements, not exact photo reconstruction. Plan/3D/Camera views are illustrative; Study and lux values are idealized planning aids, not calibrated equipment, skin exposure or camera measurements. Check real results with your equipment, a light meter and test photographs.

Reduced, metadata-stripped photo copies stay in memory for open comparison views and are excluded from projects and exports. Closing a session or removing its photo discards that session's copy; a parent Reference screen that is still open retains its own photo. Originals in Photos are unchanged. Key & Fill does not upload photographs for analysis. Apple's picker may retrieve an iCloud original. These UI checks do not establish memory-release timing or physical-device privacy acceptance.

Source: [reference workflow](../App/ReferenceComparisonView.swift), [comparison and dismissal cleanup](../App/PhotoComparisonView.swift), [photo handling disclosure](../App/StudioSettingsView.swift).

## 4. Room placement and AR fallback

**Room placement** works without AR. Enter measured dimensions and subject floor offsets; press **Set** for each changed field. Use **Keep room with setup** if the displayed values already match your room, then **Save** in the studio to retain committed measurements. Unfinished field text is excluded. The room checks describe centers and ideal emitting faces; physically check stands, housings, cables and clearance.

For AR, open **Studio tools** → **Place in AR** → **Start AR camera** and respond to camera permission. On supported hardware, follow tracking guidance, aim at the physical floor, and choose **Place subject on this floor point** when available. Adjust **Setup direction** as needed. Test **Stop camera** and **Reset and scan again**; after tracking recovery, check the physical placement before choosing **I checked the recovered placement** when shown.

On a physical device, also try denying camera access when iOS asks, or turn off Key & Fill's camera access in iOS Settings. Return to **Place in AR** → **Start AR camera** and check the denial guidance and **Use manual room measurements**. If you open that manual-room sheet, choose **Done** to return to **AR placement** before choosing **Open Camera Settings**. Allow camera access, return and start again. If iOS restrictions or hardware prevent a branch, record it as unavailable.

Use **Use manual room measurements** when AR is unavailable, permission is denied, or tracking is unsuitable. The simulator cannot place a setup in a real room. AR distances come from the authored plan, not a measurement of equipment or tracking accuracy; no placement-accuracy result is established here. Camera frames/maps are not saved, and anchors clear when leaving or pausing the camera.

Source: [manual room controls](../App/ManualRoomPlacementView.swift), [AR controls](../App/ARPlacementView.swift), [capability guidance](../App/ARPlacementController.swift).

## 5. Export a plan and keep an editable backup

Choose **Export lighting plan** (the share icon beside Projects). Exports capture the current studio settings, including unsaved changes, when the export sheet opens.

| Choice | Tester check |
|---|---|
| **Lighting plan (PDF)** | Choose paper and units, inspect the preview, then **Share PDF** → **Save to Files**. Save to a local location and open that PDF in Files. Check every page for readable labels, equipment, distances and the selected units. Return to the app, open **Share PDF** again and dismiss system sharing without selecting a destination; check that the preview remains available. |
| **Editable project copy** | Choose **Save editable copy**, cancel the file picker once and check that no success is reported. Repeat, select a file location, and check the success message. Reimport the `.json` through Projects and compare its settings. |
| **Share text settings** | Review the text at your chosen destination for readable settings and units. |

Repeat the PDF check at the largest accessibility text size and in landscape or a short window where available. If paper, units or **Share PDF** do not fit, scroll the controls region; scroll the PDF preview separately to inspect its pages. Check that the pickers, sharing action and navigation **Done** remain reachable without clipping. Record actual failures or unavailable sizes; source changes do not establish a layout pass.

Export leaves the local project and undo history unchanged. Editable copies retain scene settings and committed room measurements; photographs and edit history are excluded. Keep a separate JSON copy of work you want to retain. A PDF is a plan, not an editable project backup.

Source: [export choices](../App/LightingPlanExportView.swift), [editable copy](../App/ProjectBackupView.swift).

## 6. Review and share feedback

Open **Studio tools** → **Settings** → **Beta feedback**. Enter **Problem or observation**, **Steps to reproduce** and **Expected result**; all three are optional. Choose **Review report** and read the complete preview. **Share report** opens system sharing: you choose a destination or cancel. Key & Fill does not select a recipient or send automatically.

Use brief disposable notes for these local checks:

1. Choose **Share report**, then dismiss system sharing without selecting a destination. Check that the same report preview remains available.
2. Choose **Share report** → **Copy**, paste into an unsent local note, and compare the complete copied text with the preview. Record a missing Copy action or a mismatch.
3. Use the navigation back control to return to **Beta feedback**. Check that your notes remain, edit one, then choose **Review report** again. Repeat **Copy** and check that the new preview and copied report contain the edit; the previously pasted copy should remain unchanged.
4. Compare the report's **Source revision** with Settings: it should contain the same complete 40-character value and a notice that the report includes the app's code revision. If Settings shows **Unavailable**, the report should omit that field and notice. Do not infer a revision from the version/build number.

The app adds version/build, OS version, device family and, when available, the recorded source revision. That revision identifies app code, not a user, account, device or session. The app adds no photographs, project/scene contents, account details, device/session identifiers or logs. Review notices about shortened or cleaned text. If a paste is rejected as too long, edit it or choose **Keep previous text** / **Keep field blank** before reviewing. Notes remain in memory only; **Close** asks to **Discard draft** or **Keep editing** when notes exist. A previously shared copy remains at its destination.

Report the exact screen/action, smallest repeatable steps, expected versus observed result, frequency, and whether it survived relaunch. Mention relevant units, appearance, text size, VoiceOver, permission state and physical device versus simulator. Prioritize missing/changed saved work, crashes, blocked workflows, misleading measurements, unreadable exports and inaccessible controls. Record failures and unavailable checks honestly.

**Do not attach or upload reference/test photographs with feedback.** Keep personal information and private project details out of notes; if sharing a screenshot separately, remove any private photo or identifying content first. Use only the feedback destination supplied for your authorized test; this guide does not specify a contact.

Source: [feedback editor and preview](../App/BetaFeedbackView.swift), [report contents](../Sources/LightingCore/BetaFeedbackReport.swift).
