# Source 9 finalized native build, unit and library UI results

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

## Available artifacts

These identifiers, sizes and SHA-256 digests are from the actual workflow artifact response. This report does not claim a fresh download, ZIP inspection or visual review of these source-9 artifacts.

| Artifact | ID | Bytes | Reported SHA-256 |
| --- | ---: | ---: | --- |
| Native unit/build evidence, including finalized result bundle | 14912508980 | 64,872,936 | `23396695899fa10545b6750a54c910fe4b4e6f2a9ef0d307ece2b73200d00a01` |
| Compact native attachments | 14913411345 | 82,873 | `11d2dd188778bb12925da6222c2bec649898b4f52048ee9b95fd25cf4650195b` |
| Debug simulator application | 14912493011 | 1,961,449 | `cbbb96c5e68092333fdfde7e05c38bb7ed4e3145ecd30f4566cb7c9a706c3bcb` |
| Release simulator application | 14912472363 | 2,278,062 | `9258b8f915341dc564fc77eda5777c5adcbdd7067ca17b9b1b71d012eb963227` |
| Core test evidence | 14912756394 | 60,865 | `e11819713e5f247e0ecb830c856d6e9a9e05f4d5a7721000237e5aad0bc35620` |
| Library/reference UI evidence | 14914587558 | 3,960,517 | `d2fcec77d610e67fc28daeff95f3ea6531832678f138e3f4b16f405292b80900` |
| Compact library/reference UI attachments | 14913024949 | 1,048,699 | `00fa7f6dc980a47bd11953392e735efaa348c22f2b13585f167ecb8217c343c5` |

Simulator applications remain unsigned simulator builds, not signed physical-device builds, distribution archives or TestFlight/App Store releases. Complete all-UI acceptance, forthcoming-source persistence/UI, device performance, accessibility, calibrated scenes and all remaining protected gates stay open.
