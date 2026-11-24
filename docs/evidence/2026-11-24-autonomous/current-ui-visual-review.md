# Current library/reference UI visual review

## Exact evidence and scope

This review inspected the three genuine PNG attachments from the completed library/reference UI job for source **`ff8b683098a720b4c7abdddf212f85a79f3cfd39`**. All three images were opened with `view_image`; none was generated, reconstructed, edited or inferred from source.

- [Workflow 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829).
- [Library/reference job 138342789365](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/job/138342789365).
- [Compact attachment artifact 14908135270](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/artifacts/14908135270), `ui-library-reference-evidence-compact`, 705,079 bytes.
- ZIP SHA-256 **`db865b114b88e7a728e34589fe0a7b5a37895226e37cf79ccce9c702502f3d64`**, matching the GitHub artifact digest; archive CRC verification passed.
- Scratch directory: `/workspace/scratch/73dcd6a65726/verification/current-ui-artifact/`.

Only the compact artifact was downloaded. It contains three PNGs, two failure text attachments and a manifest. The manifest also references UI snapshots and a recording that are absent from this compact ZIP; those omitted resources were not inspected. The app/build artifact was not downloaded again.

The manifest identifies an **iPhone 17 Pro simulator**. Every PNG is **1206×2622 pixels**. This is one captured appearance and device size. No VoiceOver session, Dynamic Type variation, dark mode, increased-contrast setting or physical-device behavior was exercised by this reviewer.

## Images actually inspected

| Screenshot | Attachment file | Associated test | SHA-256 |
| --- | --- | --- | --- |
| Projects | `FA9B5BFF-C02F-4867-89AD-B422B48A4635.png` | `testCreateDuplicateRenameSwitchAndRelaunch` | `cf37ab71e18850f8e23c78e634901161557e595fa5f41197037dc49cf04366a7` |
| Guided rig basis | `0106C1CB-F010-4707-B2DF-BB39AFAD3739.png` | `testGuidedRigAbstainsThenAppliesAndUndoesWithoutSaving` | `5eebb0b919690d9156c60d78b1370344756b5f83acb4259a5f8f40dece00dce2` |
| Empty reference comparison | `414E56CA-3BA6-4A48-91B4-AA403DCB2AFA.png` | `testReferenceComparisonOpensWithRealStudyAndNoPhoto` | `cfd71307b36e380589ec987ff0c8b059c5ecfcadeaea50dd20725b621e79b3e0` |

### Projects

Campaign, Editorial and Portrait setup are visible. Editorial is marked open by both a checkmark and the explicit `Open` text, providing a non-color cue in this captured state. New project and Import editable project are visible; the import explanation says that an editable copy becomes a new project and existing saved projects are kept. Names and the import explanation are not truncated in this image.

**Confirmed P2 visual concern:** the light-count captions beneath the unopened projects are very pale blue on white. The exact source revision places `.foregroundStyle(.secondary)` metadata inside a tinted project-opening button; the captured color is consistent with inherited tint. The active row's caption is gray. A focused explicit semantic text color is appropriate for metadata, while the project action can retain its tint. The integration lead was notified immediately; this reviewer made no production change.

### Guided rig basis

The closer/farther options have visible radio-style selection markers. The selected closer option and the basis below it agree: 1.5 m key distance, −35° side, 25° elevation, 400 lx and 5600 K. The image visibly separates `Your observations`, `Assumed cues` and `Chosen starting values`, and explains that geometry, power and color remain starting assumptions. Apply selected rig is visible, followed by a statement that applying changes the editable arrangement without saving the project or retaining the reference image.

This image is scrolled partway through the form. Content continues below the viewport into the on-device comparison section; that viewport boundary alone is not evidence of layout clipping. The screenshot does not show photo import, a measured reconstruction, the complete form, or all alternative-rig states.

### Empty reference comparison

Choose photo, the empty reference placeholder, current light study and Done are visible. The neutral sphere/panel image is present with a `Metal compute` label and an explicit direct-light, uncalibrated-relative-preview caption. The sphere remains a visibly low-resolution diagnostic preview; this image does not establish calibrated rendering quality or real GPU timing. A displayed backend label by itself is not a numerical parity test.

No new overlapping, missing or unintelligible control was established within these three captured views. Actual picker authorization, replacing/cancelling a photo, empty-name cases, file export/reimport, room notes and the recovery confirmation were not captured as PNGs here.

## Measured captured contrast

The Projects PNG declares sRGB. Pixel samples used full glyph interiors rather than anti-aliased edge averages. In each caption region, the dominant nonwhite value was also the darkest observed glyph value. Background was `(255,255,255)`.

| Caption and exact pixel rectangle `(left, top, right, bottom)` | Darkest glyph RGB | Measured sRGB contrast against white |
| --- | --- | ---: |
| Campaign count, `(175,802,330,838)` | `(127,195,255)` | 1.8829946782589502:1 |
| Editorial count/open state, `(175,1025,500,1065)` | `(127,127,127)` | 4.0041069566148515:1 |
| Portrait setup count, `(175,1250,330,1285)` | `(127,195,255)` | 1.8829946782589502:1 |

Calculation: convert each sRGB channel `c/255` to linear light using `v/12.92` for `v <= 0.04045`, otherwise `((v+0.055)/1.055)^2.4`; calculate `Y = 0.2126 R + 0.7152 G + 0.0722 B`; then use `(Ylighter+0.05)/(Ydarker+0.05)`.

[W3C's contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), checked on 2026-11-24, uses 4.5:1 for ordinary text and 3:1 for large text, and cautions against treating antialiasing as the underlying text color. The measured 1.88:1 raster result is a concrete readability concern even without assigning a formal native-app compliance rating. This report does not replace the protected real-device accessibility gate; the corrected source needs new rendered evidence, including light/dark appearances and accessibility settings.

## Recovery test failure is separate evidence

The supplied actual test-log excerpt records **8 tests executed, 1 failure**: seven methods passed, while `testFullLibraryRecoveryRequiresConfirmationAndPersistsEditedSetup` failed at the confirmation tap. Both reference tests passed. This is not a green shard or a completed full-capacity recovery result.

The compact issue description states that a single-element query for `confirmRecoveryReplacement` matched two nested buttons. Its real accessibility hierarchy shows both at `{{57.0,495.0},{288.0,48.0}}`, both labelled `Replace and save setup`, inside the `Replace archived project?` alert. The explanatory alert text describes conditional archived removal and keeping exported files. This supports the specific ambiguous-selector diagnosis. It does not prove that a single tap successfully commits recovery, that VoiceOver duplicates the action, or that the confirmation is visually correct; there is no recovery PNG in this compact artifact.

| Other retained attachment | SHA-256 |
| --- | --- |
| `manifest.json` | `bfdb4cb862fe8d8398fbde6da68ccde645033fa50977071c215f8972fa4e17ed` |
| Issue description, `D1B9D781-40A2-4F71-803B-A668A0796C04.txt` | `e72fca31f8963211db385970a5a1f3f6d245c0656abe98350758bb8330e40437` |
| Failure hierarchy, `84E44C7D-924F-4E39-8A85-CC905EFD5D87.txt` | `af3153a550d14d695b0c8d7f99a6ace8aa60d62d36eb9a923f706a278519a591` |

No source edit, staging, commit, browser interaction or gate promotion was performed by this review. Revalidate the concrete recovery selection correction and metadata contrast change in the next exact native source; retain this failed shard and these original screenshots as evidence.
