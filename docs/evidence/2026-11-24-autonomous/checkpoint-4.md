# Room notes and selected-file integrity — checkpoint 4

Source `0fce248b4e61bace88002b40f6c56fddedb19c8a`, tree `7d5ab33f4ac790d7589d3131e316dcd5d87427b0`, integrated and remotely verified on main.

## Implemented and locally verified

The manual room view now offers a reviewable, immutable text export containing the actual committed dimensions, subject offset and yaw, numbered equipment coordinates and heights, and explicit center/footprint warnings. Invalid room drafts do not leak into the notes. Five portable tests cover geometry, tiny signed values, localized formatting, bounds and Unicode. The native changed/cancelled room-note scenario is implemented but still awaits execution.

Selected photo and project reads share a bounded descriptor reader. It opens with no-follow, nonblocking and close-on-exec flags; fstat checks the actual opened descriptor before bounded reads. It rejects nonregular files and honors cancellation. Project imports retain security scope and file coordination. Nine real-file tests passed through a scratch Linux adaptation from Darwin to Glibc; this is POSIX evidence, not an Apple SDK test.

Six new document regressions exercise malformed numeric and encoding data, closed roots, stale import retry, the full 64-project library, and a valid large document whose combined library would exceed 8 MiB. Failure preserves saved bytes. Duplicate JSON envelope keys remain a documented residual issue (KF-031); canonical exports do not contain duplicates. The native photo test suite now covers all eight EXIF orientations using asymmetric colored corners and verifies alpha retention versus opaque-only tonal statistics. These Apple tests have not yet completed.

The exact isolated source passed **212/212 Debug and 212/212 Release tests**, zero failures, using Swift 6.4.3 on Debian 13 x86_64. Python validation passed **24/24**. Agent-state validation, recursive native shard coverage and native Swift syntax parsing passed. Commands and raw logs are retained below; syntax parsing does not establish Apple API type checking.

## Actual GitHub status

[Run 45355893140](https://github.com/mirzotipi-wq/APP1/actions/runs/45355893140), observed after the local integration:

| Job | Actual observed status |
| --- | --- |
| Core, 138313492701 | Completed successfully, including Debug/Release, rendering and the established shared-kernel checks. |
| Simulator, 138314533584 | Unsigned Debug and Release build/upload steps completed successfully; native unit step running. Full job and native test results pending. |
| Library/reference UI, 138314534013 | Native test bundle built; UI test step running. |
| Room/precision UI, 138314533755 | Failed before tests because the selected runner lacked the optional Metal toolchain. The UI test step was skipped. |
| Studio/export UI, 138314533685 | Queued. |

The retained failure log records `cannot execute tool 'metal' due to missing Metal Toolchain` and exit 65. No test or Swift-source assertion failure is inferred from it. A subsequent source packet adds a real compiler/linker probe, one component-download attempt and a required successful reprobe to both native job families. Four mocked control-flow tests verify that script on Linux; actual Xcode component installation still requires CI. The failure remains in the record.

Earlier grouped native jobs for `5ac2d1e` were cancelled when this newer source arrived; their core job passed. Cancellation is not a native pass. Existing historical screenshots and earlier unit/UI successes remain scoped to their own revisions.

## Limits and next work

M01 remains active while current persistence smoke and complete native evidence are unresolved. The pending performance packet reduces cancellation work, corrects history ownership, hardens invisible legacy labels, and addresses Float32 boundary routing. No calibrated rendering, physical-device performance/accessibility, AR, StoreKit, customer validation, signed distribution or owner approval is established.

## Raw logs

- `cycle4-debug.log` SHA-256 `79d4729dbe6dad4d3098760ae4a0d5624a204aa91a9e022ed823a629d207f75e`.
- `cycle4-release.log` SHA-256 `c72f44e9b3f3846005535e4d69578b03ef43771daa111a10522ba9694a776ab4`.
- `0fce248-room-precision-failure.log` SHA-256 `93cbb6bbb64b2e2c5af41ea215d1359513d04e67b2a99107b96b3ddaf71b1de7`.
