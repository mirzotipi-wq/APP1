# f6 simulator/native CI: terminal success

**110/110 native tests passed, zero failures and zero skips. All three required Metal tests actually passed.** [Simulator job 139182923426](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523/job/139182923426) in run **45604744523** was observed terminal `completed/success` at **2026-11-25 12:06:41 UTC**. Tested revision: `f6f43dde19be7a554bc5c6924e3239c18b34d1be`.

## Actual test outcomes

The terminal log contains **110 unique native method outcomes across 13 classes, all `passed`**. The set matches all 110 methods declared in `NativeTests`, with no omission, duplicate, failure, or XCTest skip. XCTest reports **30.128 seconds** of test execution (**31.491 seconds** suite wall time); `** TEST EXECUTE SUCCEEDED **` appears at `12:05:17.4578650Z`. Messages about skipped attachment exports concern tests with no attachments, not skipped test execution.

| Required Metal method | Actual outcome | Duration |
|---|---|---:|
| `testMetalMatchesCPUOnAvailableDevice` | Passed | 4.466 seconds |
| `testNearFieldRoutingDoesNotPermanentlyDowngradeValidatedMetal` | Passed | 1.302 seconds |
| `testCancelledInitialParityValidationCanRetryMetalOnSameEngine` | Passed | 1.329 seconds |

The parity test printed all six fixture results: hard, soft, warm-rotated, dark, near-field, and translated. Every invalid-count comparison is true and every outlier fraction is zero. Maximum channel error is zero or one; the highest mean channel error is `5.425347222222222e-05`. Another engine test prints `Validated engine selected Metal compute`.

## Toolchain and build evidence

The log records exact f6 checkout, Intel `x86_64`, Xcode **26.6 (17F113)**, and the configured iPhone 17 Pro/iOS 26.5 simulator. Actual xcodebuild invocations retain `CODE_SIGNING_ALLOWED=NO` and the same selected simulator UDID for Debug build-for-testing, Release build, and native test-without-building.

- Debug app/native test-bundle build: `** TEST BUILD SUCCEEDED **` at **11:53:57 UTC**; simulator application uploaded.
- Release app build: `** BUILD SUCCEEDED **` at **11:56:17 UTC**; unsigned Release simulator application uploaded.
- Metal compiler check, simulator boot, native execution, result export, and both evidence uploads completed successfully.
- The macOS portable package also passed **319 tests**, zero failures, **27.132 seconds** (27.231 wall). The separately verified host SDK/EFBIG artifact remains covered by `followup-macos-sdk-actual-ci.md`.

## Preserved artifacts

| Artifact | ID | ZIP bytes |
|---|---:|---:|
| Debug simulator app | 15019556025 | 10,316,556 |
| Release simulator app | 15018488342 | 4,162,840 |
| Full native/build evidence | 15020325329 | 70,917,304 |
| Compact native attachments | 15018623781 | 332,378 |

Artifact metadata records f6 for all four. The compact ZIP was downloaded and independently verified against GitHub's SHA256 `ee272f9073e53d14dbba6617f26440f5517c4203c4d5a1df3012f574e5d7cdf5`; ZIP CRC validation passed. Its XCTest manifest maps six genuine PDF attachments to two passing PDF tests on iPhone 17 Pro, none marked associated with failure. The compact archive contains attachments, not an independent native test-count summary. Full evidence and application archives were inventoried by metadata, not downloaded or independently rehashed in this review.

Owned receipts: `/var/tmp/keyfill-c0abc39c4f18/f6-native-terminal-triage/`. `terminal-excerpts.log` preserves 151 exact lines including every native outcome, Metal metrics, selected build invocations and success markers; JSON preserves the complete method list, artifact metadata, terminal job/steps, source comparisons, compact ZIP integrity, and receipt hashes.

## Scope

Read-only Git comparisons confirm `App`, `Sources`, `NativeTests`, `UITests`, and `project.yml` are unchanged from b298 to f6 and from f6 to current `a1ef72fef6b10b6a11f5d62cf1a9410499c92e9a`. This remains an **f6 workflow receipt**; execution of the replacement workflow is separate. These Intel simulator results do not establish ARM RealityKit, physical-device, or UI accessibility acceptance. No source edits, commits, pushes, reruns, cancellations, test waivers, or new workers were performed.
