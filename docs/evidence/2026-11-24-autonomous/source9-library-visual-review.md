# Source 9 library/reference: actual native visual review

Date: 2026-11-24 UTC. Independent reviewer: `/root/w09_ios_critical_review`.

## Findings

The earlier project-caption correction is visibly present in the genuine source-9 Projects capture. The three light-count/Open captions now have black glyph interiors on white, measured at **21:1** in the captured raster. The corresponding source-`ff8b683` values were approximately **1.88:1** for the two unopened projects and **4.00:1** for the active project. This resolves the previously observed pale-caption issue in this captured appearance; it is not whole-screen accessibility approval.

The guided-rig and empty-reference captures retain the earlier visible content and layout. Their image pixels below the status bar match the corresponding actual `ff8b683` captures. A new full-library recovery screenshot shows the recovery project saved with four lights, and the associated native method now completes successfully.

**Remaining P2 visual concern:** in the lower-right portion of the recovery screenshot's overhead plan, the `Light 1` label sits against and partly over the neighboring `Fill` light marker. This is an observed diagram-legibility deficiency. It is separate from recovery persistence and does not turn the passing recovery method into a failure. No cause, hit-testing failure or correction is inferred from this image, and no source edit was made.

These observations apply to **`3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`**, not the later source-10 asynchronous-storage candidate. The other source-9 room/studio UI shards are outside this review. No VoiceOver, Dynamic Type, dark-mode, increased-contrast or physical-device approval follows from these screenshots.

## Evidence provenance and bounds

- [Workflow 45377378521](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521).
- [Library/reference job 138390492888](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521/job/138390492888).
- [Compact artifact 14913024949](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521/artifacts/14913024949), named `ui-library-reference-evidence-compact`.
- Artifact size **1,048,699 bytes**; downloaded ZIP SHA-256 **`00fa7f6dc980a47bd11953392e735efaa348c22f2b13585f167ecb8217c343c5`**, matching the independently retrieved GitHub artifact digest. ZIP CRC validation passed.
- Retrieved [artifact metadata](source9-library-visual/artifact-metadata.json) binds that artifact to the exact source-9 SHA and workflow. The [manifest](source9-library-visual/manifest.json) associates every PNG with its named test, capture timestamp and **iPhone 17 Pro simulator**, device ID `12FCFD0F-7FCF-463F-A605-132A7E18B5D5`.
- All four images are original **1206×2622 RGB PNGs** with an sRGB declaration. They were extracted byte-for-byte, given descriptive local filenames and opened using `view_image`. No screenshot was generated, reconstructed, retouched or pixel-modified.

The compact artifact contains all four PNGs and their manifest, sufficient for this bounded review. The larger full artifact was not downloaded. The raw ZIP, extracted images, manifest, retrieved metadata and pixel-sample record occupy **2,219,948 bytes** in `source9-library-visual/` at this checkpoint.

The existing [source-9 raw job log](3b2a4ce-library-job.log) was independently hashed as `b577e6d9d1c5c974d01727461342acd5b0d2c6adae36777d04f3f32a71a98c08`. It includes checkout output for the full source-9 SHA, reports **8 tests, zero failures**, selected-suite elapsed **629.600 seconds**, and `TEST EXECUTE SUCCEEDED`. This is a completed library/reference shard; it is not a result for the entire workflow or source 10.

## Images actually inspected

| Local image | Original exported attachment | Associated test | SHA-256 |
| --- | --- | --- | --- |
| [projects.png](source9-library-visual/projects.png) | `2E7A40DD-71F4-4737-AF39-B1E01F4A729E.png` | `ProjectLibraryUITests/testCreateDuplicateRenameSwitchAndRelaunch()` | `fd54d1446ade09dceac48f736572c7bdf3305598e789ec4eca5ee3f03b19410f` |
| [recovery.png](source9-library-visual/recovery.png) | `26341169-12CB-46D4-85BA-D5D5F2390ED0.png` | `ProjectLibraryUITests/testFullLibraryRecoveryRequiresConfirmationAndPersistsEditedSetup()` | `4b92de7bad25d72a9322b14911d1dccfa0a084c4e3cff154da96de14355e0919` |
| [guided-basis.png](source9-library-visual/guided-basis.png) | `3780A02E-C91C-4D84-94C7-3E857951C1A5.png` | `ReferenceComparisonUITests/testGuidedRigAbstainsThenAppliesAndUndoesWithoutSaving()` | `e49f14f8bd1f589983bda366d6656b4d3200d04497358f3ef3d962e7a3bebfdb` |
| [reference-empty.png](source9-library-visual/reference-empty.png) | `2E5952F0-EAF0-4BA2-A2D3-6AA110B4F9BE.png` | `ReferenceComparisonUITests/testReferenceComparisonOpensWithRealStudyAndNoPhoto()` | `b7552e4612db883df354689cc8861de7f88e5d080bccdf127df182fbb6ff8db7` |

### Projects and caption correction

Campaign, Editorial and Portrait setup are visible in the same layout as the earlier capture. Editorial has both a checkmark and explicit `Open` text. New project, Import editable project and the explanation that existing saved projects are kept remain visible. The ordinary project names are not truncated in this screenshot.

All three count/Open captions are now black. Unopened project titles and options remain blue, retaining their action treatment. Source inspection at the actual committed source-9 revision confirms the earlier narrow `Color.primary` changes in `projectRowLabel`. The conditional short project-ID caption does not appear in this fixture, so this image does not visually verify that branch or legacy-name layouts.

The reviewer reopened the original Projects PNG from the earlier [actual UI review](current-ui-visual-review.md), verified its SHA-256 `cf37ab71e18850f8e23c78e634901161557e595fa5f41197037dc49cf04366a7`, and measured the same pixel rectangles in both images. The darkest glyph color was also the dominant nonwhite color in each sampled region; these measurements use hundreds of glyph-interior pixels rather than a single antialiased edge.

| Caption | Pixel rectangle `(left, top, right, bottom)` | Earlier glyph RGB | Earlier contrast on white | Source-9 glyph RGB | Source-9 contrast on white |
| --- | --- | --- | ---: | --- | ---: |
| Campaign count | `(175,802,330,838)` | `(127,195,255)` | 1.8829946783:1 | `(0,0,0)` | 21:1 |
| Editorial count/Open | `(175,1025,500,1065)` | `(127,127,127)` | 4.0041069566:1 | `(0,0,0)` | 21:1 |
| Portrait setup count | `(175,1250,330,1285)` | `(127,195,255)` | 1.8829946783:1 | `(0,0,0)` | 21:1 |

The captured background is `(255,255,255)`. Calculation converts sRGB channels to linear light with `v/12.92` for `v <= 0.04045`, otherwise `((v+0.055)/1.055)^2.4`, computes luminance using weights `0.2126`, `0.7152`, `0.0722`, then uses `(lighter+0.05)/(darker+0.05)`. Exact values and sample counts are retained in [contrast-samples.json](source9-library-visual/contrast-samples.json).

This is a measured correction to three specific captions in one captured light appearance. Other secondary text was not comprehensively contrast-audited. No broader accessibility gate or dark-appearance result is implied.

### Guided reference state

The selected closer rig and the basis text agree: image-left key observation, 1.5 m key distance, −35° side, 25° elevation, 400 lx and 5600 K. The farther option remains visibly unselected. The form distinguishes observations, assumed cues and chosen starting values, and explicitly describes geometry, power and color as starting assumptions. Preview current setup and Apply selected rig are visible, with the explanation that applying changes the editable arrangement without saving the project or retaining the reference image.

The image is partway through a scrollable form. Content continues below the captured viewport into the on-device comparison section; that viewport boundary is not evidence of a newly clipped layout. The original `ff8b683` guided image was reopened and its SHA verified as `5eebb0b919690d9156c60d78b1370344756b5f83acb4259a5f8f40dece00dce2`. The pixel difference is empty within rectangle `(0,186,1206,2622)`, excluding the changing status bar. Thus the visible guided state has no pixel change within that comparison region.

The completed native guided method supplies separate execution evidence for its asserted abstain/apply/undo workflow. The screenshot alone does not demonstrate those transitions, photograph import, every rig alternative or reconstruction accuracy.

### Empty reference comparison

Choose photo, the empty reference placeholder, current light study and Done are present. A rendered sphere/panel study appears with the `Metal compute` label and the direct-light, uncalibrated-relative-preview caption. The image remains a low-resolution diagnostic preview; neither the backend label nor visual similarity establishes numerical Metal parity, performance or calibrated exposure.

The original empty-reference PNG was reopened and verified as SHA-256 `cfd71307b36e380589ec987ff0c8b059c5ecfcadeaea50dd20725b621e79b3e0`. The same below-status-bar rectangle `(0,186,1206,2622)` has an empty pixel difference against source 9. The screenshot supports the preserved empty state and visible study. Picker permission, selecting/replacing/cancelling a photo and retained-photo lifecycle are outside the captured evidence.

### Recovery result and remaining plan legibility

The new recovery screenshot shows `Portrait setup recovery`, `Saved locally`, Plan mode and four lights including `Light 1`. Reference photo, Room placement, Meter and Projects actions are visible. The history icons are muted. The screenshot is the post-recovery Studio state; it does not depict the confirmation alert itself.

The lower-right plan cluster contains the remaining concern described above: the `Light 1` label partly overlays the neighboring Fill marker. Record this as a visual deficiency for a later focused diagram review. The image does not establish which touch target would receive an interaction there, and this review made no geometry or layout change.

The associated full-capacity native test passed in **73.992 seconds**, so source 9 provides completed execution evidence beyond the former source-`ff8b683` ambiguous-confirmation failure. The earlier failure remains a failure at its original revision. This successful result does not establish source-10 async recovery behavior.

## Completed native methods

The raw job log records these eight successful methods, including the six library and two reference methods:

| Method | Recorded duration |
| --- | ---: |
| `testArchivedDeleteRequiresConfirmationAndPersistsOnlyThatRemoval` | 147.048 s |
| `testCreateDuplicateRenameSwitchAndRelaunch` | 150.166 s |
| `testFullLibraryRecoveryRequiresConfirmationAndPersistsEditedSetup` | 73.992 s |
| `testStaleSaveRecoveryPreservesBothProjectsAcrossRelaunch` | 76.947 s |
| `testStaleSaveReloadRequiresConfirmation` | 40.058 s |
| `testUnsavedSetupMustBeSavedBeforeLibraryChanges` | 19.165 s |
| `testGuidedRigAbstainsThenAppliesAndUndoesWithoutSaving` | 89.959 s |
| `testReferenceComparisonOpensWithRealStudyAndNoPhoto` | 32.245 s |

The source-10 extensions to first-save callback refresh and the large-library UI scenario are not part of this source-9 eight-method result. No source-10 async behavior is inferred from these passes.

## Retained metadata and review limits

| Small retained metadata file | SHA-256 |
| --- | --- |
| `source9-library-visual/artifact-metadata.json` | `3c01378450ed2852ef7dd064221e6945b3362a7c2cfb108291c8611de92b00c3` |
| `source9-library-visual/manifest.json` | `4bab0dd7698395632430df9001e0769f97334e1dc874c6fb2ae9a0b2c321160f` |
| `source9-library-visual/contrast-samples.json` | `3097bacf4bc0e589093d3e12a31cfe4fa9c6d474a135095e638a50f06f46ccf5` |

The useful current image directory is `/workspace/scratch/73dcd6a65726/APP1/docs/evidence/2026-11-24-autonomous/source9-library-visual/`. The three original comparison PNGs remain in `/workspace/scratch/73dcd6a65726/verification/current-ui-artifact/`, with exact attachment names and hashes recorded in the earlier visual review.

This review inspected genuine screenshots and existing completed test evidence; it did not run another native test, use a browser, edit source, stage, commit or spawn an agent. The retained simulator images cover one appearance and device size. Whole-screen accessibility, VoiceOver, Dynamic Type variants, dark/increased-contrast appearances, physical-device behavior and source-10 async verification remain open requirements.
