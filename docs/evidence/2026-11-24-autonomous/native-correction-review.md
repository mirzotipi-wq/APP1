# Independent review of the frozen native correction candidate

## Decision and exact scope

**No new concrete regression or unjustified weakening of the corrected assertions was found.** The candidate is suitable for integration and a fresh native run. This is a source/evidence review, not a corrected native pass. The failed source-six runs remain failed.

Reviewer: actual specialist `w09_ios_critical_review`. An additional actual read-only specialist, `w09_ios_critical_review/spatial_assertion_review`, independently examined the complete SceneKit source/test pair and its native failure log. Neither reviewer changed production/test source, staged files, committed, or ran redundant tests. This reviewer wrote only this report outside the frozen candidate.

- Base source: `ff8b683098a720b4c7abdddf212f85a79f3cfd39`.
- Frozen candidate: tree `9ac414a06f5ffb61b9d243fbac0ec56a5697dbaf`, exported to `/workspace/scratch/73dcd6a65726/verification/cycle7-source` by the integration lead.
- Scope: five app files and the three corresponding native/UI test files listed below. Each exported file was compared byte-for-byte with its frozen index entry; all eight matched.
- Protected product, quality and persistence requirements remain unchanged. Corrected native execution, actual post-correction visual appearance and physical-device accessibility are still pending.

## Findings by correction

### SceneKit updates and synchronous projection assertions

The source adds balanced `SCNTransaction.begin()` and deferred `commit()` calls with zero animation duration and implicit actions disabled around the existing scene/camera update and viewport-axis change. No early return after beginning a transaction bypasses its deferred commit. The fit bounds, radius, distance, camera orientation, clipping calculations, fit-request conditions and ordinary-edit orbit-preservation branches are unchanged. There is no new application-side `flush()` or blocking render.

The projection test adds `SCNTransaction.flush()` after layout and before querying the rendered projection. All target checks and all seven finite/X/Y/depth assertions for each of the sixteen corner projections remain intact. No viewport, corner, visibility bound or failure path was removed. Synchronizing this standalone synchronous test is distinct from increasing the fitted distance until an incorrect projection passes.

The actual source-six native log records the expected FOV as `26.991466561591626` degrees and the native result as `26.991466522216797`, which the correction report identifies as the Float32 round trip. The replacement tolerance is one ULP of `Float(expectedFieldOfView)`. This is a representation-sized tolerance around the same domain target; the camera-position, disabled-orbit-control and vertical-projection assertions remain. It is justified by the observed discrepancy and does not relax a visual-quality threshold.

Both reviewers found no concrete source regression or weakened clipping assertion. A native rerun must still establish that the synchronization resolves the actual projection failures. The old log contains 32 failed projection assertions and one FOV assertion across two methods; those failures are not converted to passes by this diagnosis. See [spatial-native-correction.md](spatial-native-correction.md).

### Full-library recovery confirmation

The inspected completed library/reference log shows one alert with nested buttons carrying the same `confirmRecoveryReplacement` identifier and label. The tap failed because the query was ambiguous. The test had reached the second confirmation after exercising cancellation, but it had not reached the successful recovery or relaunch assertions.

The candidate removes only the custom identifier from the native destructive alert action. Its user-visible label, destructive role, confirmation message and `replace(project)` callback remain. The callback still calls the transactional recovery operation before dismissal and retains its failure handling. No capacity, candidate-comparison, deletion or persistence logic changed.

The revised query is scoped to the named alert and the exact `Replace and save setup` label. It requires **exactly one** matching button, captures a screenshot and hierarchy if uniqueness fails, waits for the action to be enabled and taps that unique element. It introduces no `firstMatch` or coordinate tap to hide ambiguity. Cancellation, retained unsaved light, recovered project title, saved status, four-light content and relaunch checks remain unchanged. `continueAfterFailure = false` remains in the scenario.

This correction is narrow and the test remains strict. Whether removing the identifier produces the intended native accessibility tree is explicitly pending; the review does not assume framework internals. See [recovery-ui-correction.md](recovery-ui-correction.md).

### Room-note content and accessibility diagnostics

The reviewer opened the actual extracted failure frame, `notes-at-failure.png`, whose SHA-256 is `0f797558c45ef35d2400d0efe1dcfa4b6cb6b402d24d8db25c75403d1c99ba29`. It visibly shows room width 6.00 m, depth 7.00 m, subject X 3.00 m/Z 2.00 m and zero outside centers. This supports the report's distinction between correct visible committed content and the failed accessibility-label assertion. The automatic snapshots did not expose the element's old label/value; this review does not invent that missing information.

The candidate adds an explicit `accessibilityLabel(Text(verbatim: text))` to the existing selectable notes text. The same immutable `text` value still supplies the visible preview and ShareLink. Notes generation, formatting, committed/draft separation, selection, sharing and dismissal are unchanged; no independent fixed label or duplicated test-only content was introduced.

The test retains its original ten-second content predicate and all committed-width, rejected-draft exclusion, signed-coordinate, reopened-sheet, retained-room and unchanged-studio checks. It now records actual element type, label, value and frame at each observation, plus a screenshot and hierarchy if the predicate fails. The `.firstMatch` used to locate the notes element already existed in the base; it was not added as a way to bypass this failure. No timeout was increased and no assertion was skipped.

This is a defensible accessibility-content contract and a useful diagnostic improvement. Native success still has to be observed. See [room-notes-native-correction.md](room-notes-native-correction.md).

### Project metadata captions

The complete source diff changes only the two metadata foreground expressions in `projectRowLabel`: the optional short project ID and the light-count/Open caption now use explicit `Color.primary`. Text, sizes, selected state, actions, IDs and accessibility labels/values are unchanged. The correction retains a semantic color rather than introducing a hardcoded light-mode color.

The historical screenshot measurements in [project-caption-correction.md](project-caption-correction.md) remain before-correction evidence. This reviewer did not measure a new rendering, and source inspection cannot supply a corrected contrast ratio. No source-derived interaction regression was found; light/dark and accessibility appearance checks remain required.

### Meter symbol

The actual native log records two missing-resource warnings for `light.metering.center.weighted`. The candidate changes exactly those two symbol names to `sun.max`; visible labels, action closures, minimum sizing, identifiers and editor/history behavior are unchanged. This is a resource-name correction to an observed warning, with no meter algorithm or exposure claim added. The new symbol's actual appearance remains a native visual check. See [meter-symbol-correction.md](meter-symbol-correction.md).

## Assertion and evidence integrity

| Boundary | What the candidate preserves | What it does not establish yet |
| --- | --- | --- |
| SceneKit fit | All 16 corner projections, clipping assertions, controller targets and ordinary-edit orbit checks | Corrected native projection output, physical camera calibration or device rendering performance |
| Physical FOV | Same `CameraFraming` target, camera position and vertical projection; tolerance tied to one observed Float ULP | Arbitrary optics, pixel framing or photographic lens calibration |
| Recovery | Explicit confirmation, uniqueness, cancellation, unsaved four-light state, saved status and relaunch content | The corrected native hierarchy and successful completion of that scenario |
| Room notes | Same immutable visible/accessibility/shared text; exact retained content predicates and timeout | Corrected native accessibility delivery, actual share destination or VoiceOver usability |
| Caption/symbol styling | Existing behavior and semantic UI meaning | New measured contrast or a post-correction screenshot |

No new P0/P1 issue was established by this review. It does not erase the existing source-six native failures or satisfy unresolved regression/device/accessibility gates.

## Execution evidence inspected

The reviewer inspected the preserved logs rather than treating test source as an executed result:

- `ff8b683-native-tests.log`: 42 native methods, 40 passed and two failed; 33 failed assertions. The ordinary-edit orbit-preservation method passed. SHA-256 `5cd4211c435000990bc7c520b2a94ad8266073a9064bcfff8ceee3ffe03ea3e3`.
- `ff8b683-library-reference.log`: eight UI methods, seven passed and one failed at the ambiguous recovery confirmation. SHA-256 `37a9a49ca3ecba3bde979e8902e6f0e3dfbe3c98a6c58971349a990750e23bc4`.
- `ff8b683-room-precision.log`: five UI methods, four passed and one failed at the room-note label predicate; all three precision scenarios passed. SHA-256 `b14f3bc632658a1a31b327a89619e217ed04ef31fc76399b547f65b5ac4a0624`.
- `/workspace/scratch/73dcd6a65726/verification/cycle7-debug.log`: the frozen candidate's existing portable run completed **245/245**, zero failures.
- `/workspace/scratch/73dcd6a65726/verification/cycle7-release.log`: the corresponding existing Release run subsequently completed **245/245**, zero failures.

The integration lead also reports 28 Python tests and native Swift syntax parsing passed; those are not Apple SDK execution. This reviewer ran a scoped staged whitespace check, which passed, and no additional test suite. The original native results and their per-suite limits remain in [native-results-ff8b683.md](native-results-ff8b683.md).

The next acceptance step is a fresh integrated Apple build and the complete affected native/UI scenarios, retaining genuine screenshots and accessibility diagnostics. Source-six build successes remain valid historical build evidence at their own revision; source-six test failures remain failures; corrected-candidate native status remains pending.

## Frozen reviewed source hashes

| File | SHA-256 |
| --- | --- |
| `App/SpatialPreview.swift` | `a05b413fd8502381d7f4c9493ae3ea017784c8e985d898ded879d714ee9ab279` |
| `App/RecoveryCapacityView.swift` | `b5d34cb5a6f2756a8d945f8f5bbaf6d95a2d1bdf46ba561f09bfbd8888ff1643` |
| `App/ManualRoomPlacementView.swift` | `482ab39b9831358e1f8f5752ac2b51238f3ddbc60d5acbda38bd82583c61b6b4` |
| `App/ProjectLibraryView.swift` | `5ab206ae414aa7e861944baf69a804a56ad05548755a3d6a7907b3b7a8016d6d` |
| `App/StudioView.swift` | `f2d1276c3870a1a3ce3e72ae810a21511862f6bf6474df1e0352995fe7511d83` |
| `NativeTests/SpatialPreviewTests.swift` | `c7d676da2763406998efc2491743c0185dd1c7f4767101eda2beb9fc2812895a` |
| `UITests/ManualRoomPlacementUITests.swift` | `4219598954145211dfbdaeb0326e3524d3db25056296cac802dbb4897e58c16e` |
| `UITests/ProjectLibraryUITests.swift` | `c2c9556fa5544f74a3a9de5221d57c0b4e4045b4454ca797fe9fc91af52f1c86` |
