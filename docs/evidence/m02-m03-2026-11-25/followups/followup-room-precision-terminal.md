# Room/precision — terminal CI triage

**Passed: 5/5 methods, zero failures, zero skipped methods.** Terminal job success was observed at 2026-11-25 11:40:19 UTC. Tested revision: `b298b1333f3abb901c23a198187628fe94331427`, [run 45600372389 / job 139160177561](https://github.com/mirzotipi-wq/APP1/actions/runs/45600372389/job/139160177561).

| Method | Result | Seconds |
|---|---|---:|
| `testManualRoomReportsOutOfBoundsAndRecordsRoomEdit` | Passed | 111.537 |
| `testRoomResizeRequiresExplicitSubjectMoveAndPreservesSignedCoordinates` | Passed | 537.091 |
| `testExactCameraFocalLengthUndoRedoAndReopen` | Passed | 127.694 |
| `testExactLightIntensityValidationUndoRedoAndReopen` | Passed | 161.144 |
| `testExactModifierWidthAndRoomCrossingWithInsideCenters` | Passed | 238.321 |

The terminal log reports two ManualRoomPlacement and three PrecisionEditing passes; total suite duration was 1175.788 seconds. Both test build and test execution succeeded within the unchanged 32-minute test-step deadline. No actual failed assertion or test timeout requires a room/precision repair.

Environment recorded by the job: standard Intel/x86_64; image `20260824.0517.1`; macOS 26.6.1; Xcode 26.6 build 17F113; iPhone 17 Pro on iOS 26.5. The result belongs to the b298 run. `git diff` confirms no App/Sources/UITests/NativeTests differences between b298 and review-time main `f6f43dde19be7a554bc5c6924e3239c18b34d1be`; this is not execution of the new SDK wrapper repair. Intel/SceneKit evidence remains separate from ARM RealityKit and from the library accessibility audits.

Preserved terminal evidence, without compiler-command noise:

- `/var/tmp/keyfill-c0abc39c4f18/room-precision-triage/terminal-excerpts.log` — 42 exact raw lines covering environment, all test outcomes, suite totals, and uploads.
- `/var/tmp/keyfill-c0abc39c4f18/room-precision-triage/terminal-summary.json` — method results, source scope, environment, and artifact metadata.
- `/var/tmp/keyfill-c0abc39c4f18/room-precision-triage/terminal-job.json` — terminal connector job/step status.

Both artifacts finalized successfully: full evidence `15016594599` (5,787,984 bytes; SHA256 `46b31177562e8c87362b8fa3edd2a65d368a8b03a49b299846126ac01d25ef26`) and compact evidence `15018560045` (1,394,555 bytes; SHA256 `8fb4c5bd24acab26fca8b7df92106f1b224c3aac109ee27c10c09bcb892b81a0`). Archive download was unnecessary for this unambiguous terminal count; metadata and URLs are preserved in the summary.

This triage performed no source edits or reruns. Subsequent workflow changes, if assigned, are a separate packet. Existing worker a097 was reused; the distinct-worker count remains 100.
