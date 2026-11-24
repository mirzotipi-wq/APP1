# Source 9 finalized build, native unit and UI evidence

Exact executed revision: `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`, tree `0ff9fa32a412534af0e11629e442f0a46a1176a0`. [Workflow 45377378521](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521). This later observation supplements the timestamped pending state in checkpoint 9; it does not rewrite that historical observation.

## Actual results

The [simulator job 138390492865](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521/job/138390492865) completed **success** at `2026-11-24T11:01:56Z`. The complete retrieved job log is retained as [3b2a4ce-native-job.log](3b2a4ce-native-job.log), SHA-256 `16a2996ef9bef2b0abaf053456f9d7cd9db66510ecd584c98cbd1831851c7911`.

Both unsigned Debug and Release simulator builds succeeded. The Metal compile/link preflight passed. Native XCTest completed **50/50 methods, zero failures**, with an 8.582-second aggregate for the final all-tests line. `TEST SUCCEEDED` is recorded at `11:00:00.926978Z`.

| Native suite | Executed | Failures |
| --- | ---: | ---: |
| BoundedFileReaderTests | 13 | 0 |
| LightingPlanPDFTests | 3 | 0 |
| ProjectDocumentIOTests | 9 | 0 |
| ReferencePhotoTests | 7 | 0 |
| SpatialPreviewTests | 3 | 0 |
| StudioSliderEditingTests | 8 | 0 |
| StudyRendererTests | 7 | 0 |
| **Total** | **50** | **0** |

All eight new slider adapter methods actually executed on the Apple runner. All three spatial-preview methods passed again. The renderer suite includes actual Metal parity, cancellation/retry and near-field fallback/re-entry checks. This proves those tested paths at this revision; it does not establish the exact callback ordering of a real dragged SwiftUI Slider, complete export UI behavior, physical-device rendering accuracy or release readiness.

The [core job 138388771652](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521/job/138388771652) completed success at `10:49:01Z`: **251/251 Debug, 251/251 Release and 28 Python checks**, plus the original six shared-kernel fixtures and eight strict Float32 boundary fixtures. Its full retrieved log is [3b2a4ce-core.log](3b2a4ce-core.log).

The [library/reference UI job 138390492888](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521/job/138390492888) subsequently completed **success** at `11:14:42Z`. Its retrieved log actually records **8/8 scenarios, zero failures**, with a 629.600-second all-tests aggregate: six project-library scenarios and two reference scenarios. Full-capacity recovery confirmation/relaunch, stale-save recovery/reload, archived deletion, create/duplicate/rename/switch/relaunch and the unsaved-setup boundary all passed. The two reference scenarios passed guided abstention/apply/undo and the initial comparison without a photo. [Complete library job log](3b2a4ce-library-job.log), SHA-256 `b577e6d9d1c5c974d01727461342acd5b0d2c6adae36777d04f3f32a71a98c08`.

At the direct **11:18:05 UTC** observation on 2026-11-24, room/precision and studio/export UI shards remained in progress. No complete all-UI result is inferred from the unit or library pass. The forthcoming asynchronous persistence, room-status and concurrency-policy changes are outside this executed source and need their own acceptance; in particular, these six synchronous-library passes do not certify the new actor implementation.

The [room/precision job 138390492826](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521/job/138390492826) subsequently completed **success** at `11:23:14Z`. The full retrieved [3b2a4ce-room-job.log](3b2a4ce-room-job.log), SHA-256 `f2e8a9a91907fe7abbdaefb97386534ca986ea4ecf075a8bcded3472ff913e2a`, records **5/5 scenarios, zero failures**, 1211.802-second all-tests aggregate, and `TEST EXECUTE SUCCEEDED` at `11:21:48.842203Z`. Both room methods passed, including the complete resize/signed-coordinate/notes workflow. All three exact camera, light-intensity and modifier-width/room-crossing scenarios passed.

This room pass predates the explicit status-label and diagnostic changes in source 10. It cannot be attributed to those later changes, and it does not explain or erase the real source-8 initial-status failure. The source-9 studio/export shard remained in progress at the subsequent direct observation. Thus **13 of 22 source-9 UI scenarios have complete passing evidence**, with the remaining nine still pending at this checkpoint, rather than an all-UI pass.

## Final studio/export result and remaining defect

The [studio/export job 138390492855](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521/job/138390492855) subsequently finalized with **failure**: all nine scenarios completed, **eight passed and one failed**, with a 700.048-second all-tests aggregate. `TEST EXECUTE FAILED` is recorded at `11:35:57.425208Z`. The direct workflow response now records the entire run as `completed/failure`, updated at `2026-11-24T11:37:03Z`. The full retrieved [3b2a4ce-studio-job.log](3b2a4ce-studio-job.log) has SHA-256 `83b475f36d0a12798f2af751e1b647c7a52c7773972838d6d48b458ba95b7a7b`.

Both export scenarios passed: preview without saving or changing the scene, and an unsaved editable copy at the full 64-project limit. Camera focal-length undo/relaunch, corruption protection, meter balance, recipe editing, the actual study frame and sphere/mannequin switching also passed. The remaining failure is `StudioSmokeTests.testOpticsEditingUndoRedoAndRelaunch`: after a normalized width-slider adjustment and one Undo, line 87 observes **1.3 m instead of the original 0.6 m**. The rectangular emitter-kind assertion passed. The original width assertion remains intact.

Thus the final source-9 UI result is **21/22 passed, one failed**: library/reference 8/8, room/precision 5/5, and studio/export 8/9. All 50 native unit methods passed, including the eight slider-helper methods, but those unit results do not certify the actual slider gesture. The UI log records a synthesized adjustment; it contains no internal binding/edit-begin/edit-end trace that establishes why the gesture split. Callback ordering or accessibility behavior must not be asserted as the demonstrated root cause. Source 10 retains the same slider adapter and requires separate native evidence for its new persistence actor.

## Available artifacts

These identifiers, sizes and SHA-256 digests are from the actual workflow artifact response. Separate [library](source9-library-visual-review.md) and [room](source9-room-visual-review.md) reviews record verified compact downloads, CRC checks and actual visual observations; the other table entries are artifact metadata, not a claim of fresh local inspection.

| Artifact | ID | Bytes | Reported SHA-256 |
| --- | ---: | ---: | --- |
| Native unit/build evidence, including finalized result bundle | 14912508980 | 64,872,936 | `23396695899fa10545b6750a54c910fe4b4e6f2a9ef0d307ece2b73200d00a01` |
| Compact native attachments | 14913411345 | 82,873 | `11d2dd188778bb12925da6222c2bec649898b4f52048ee9b95fd25cf4650195b` |
| Debug simulator application | 14912493011 | 1,961,449 | `cbbb96c5e68092333fdfde7e05c38bb7ed4e3145ecd30f4566cb7c9a706c3bcb` |
| Release simulator application | 14912472363 | 2,278,062 | `9258b8f915341dc564fc77eda5777c5adcbdd7067ca17b9b1b71d012eb963227` |
| Core test evidence | 14912756394 | 60,865 | `e11819713e5f247e0ecb830c856d6e9a9e05f4d5a7721000237e5aad0bc35620` |
| Library/reference UI evidence | 14914587558 | 3,960,517 | `d2fcec77d610e67fc28daeff95f3ea6531832678f138e3f4b16f405292b80900` |
| Compact library/reference UI attachments | 14913024949 | 1,048,699 | `00fa7f6dc980a47bd11953392e735efaa348c22f2b13585f167ecb8217c343c5` |
| Room/precision UI evidence | 14914713623 | 7,420,061 | `7313f9fb4ffbf88307fc22d9c813007210c1a2b6e2e3f20b36e7074c0a6a39ac` |
| Compact room/precision UI attachments | 14914553792 | 1,616,532 | `fb64d2ec9d8f3a23a95218425e3f3e246410dc7e08ab6e8300121c2f2f4a4b3f` |
| Studio/export UI evidence, including finalized result bundle | 14915129098 | 119,983,659 | `4ca435e9772f6d6fdc84044284d1bb44d30a23330420a4020ec87f11c6394a18` |
| Compact studio/export UI attachments | 14914919665 | 2,423,568 | `3f592e8bd44c8adc81e7f7ce80adcbfc6eefad78b3c6a7ed7da97224c024b6e7` |

Simulator applications remain unsigned simulator builds, not signed physical-device builds, distribution archives or TestFlight/App Store releases. Complete all-UI acceptance, forthcoming-source persistence/UI, device performance, accessibility, calibrated scenes and all remaining protected gates stay open.
