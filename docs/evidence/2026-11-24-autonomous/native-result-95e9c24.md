# Source 11 completed native build and unit results

**Both unsigned simulator builds and all 83 native methods passed at exact source `95e9c2446b7bb05e6df38d103063b4254bb07c92`.** This supplies source-11 `native_build` evidence. The actual optics gesture, complete persistence smoke, all UI shards and native plan/accessibility acceptance remain outstanding.

Tested source tree: **`c35f501c41a6741a5cc90c012135b8d041d005ad`**. [Workflow 45394444997](https://github.com/mirzotipi-wq/APP1/actions/runs/45394444997), [simulator job 138451564691](https://github.com/mirzotipi-wq/APP1/actions/runs/45394444997/job/138451564691). The job completed **success at 12:56:49 UTC on 2026-11-24**. The lead retrieved the complete decoded log and artifact metadata at **12:57:49 UTC**. The records specialist then independently parsed all completed method lines, suite totals, build/bundle checks and diagnostics from that unchanged log. No CI poll, artifact download or implementation suite was run by the specialist for this update.

The earlier pending observations in [checkpoint 11](checkpoint-11.md), state and evidence remain dated records. This is a later result, not a retroactive claim that native success was known at 12:42 UTC. At the lead's approximately **12:57 UTC** jobs observation, library/reference **138451564785** and room/precision **138451564904** were still running; studio/export **138451564680** was queued. No finalized source-11 UI count or optics result is inferred.

## Actual build and test environment

The full log identifies the exact checkout, **macos-26-intel**, **Xcode 26.6 build 17F113**, **Apple Swift 6.3.3**, and **iPhoneSimulator SDK 26.5**, with an iOS 17 deployment target and Swift 5 application language mode. This is an unsigned simulator build, not a signed physical-device application, TestFlight or distribution archive.

| Check | Actual result |
| --- | --- |
| macOS portable package | **257/257**, zero failures; 22.331s execution / **22.403s all-tests aggregate** |
| Unsigned Debug build | **BUILD SUCCEEDED**, `12:45:34.028320Z` |
| Debug icon/privacy bundle checks | Passed; AppIcon metadata and Assets.car present, bundle privacy manifest verified |
| Unsigned Release build | **BUILD SUCCEEDED**, `12:47:26.070016Z` |
| Release icon/privacy bundle checks | Passed with the same declared simulator/iOS 17 scope |
| Native XCTest | **83/83**, zero failures; **22.210s execution / 23.241s all-tests aggregate** |
| Final test command | **TEST SUCCEEDED**, `12:55:21.154430Z` |
| Finalized result export/uploads | Completed; log records exported PDF attachments and both native evidence uploads |

The macOS package run includes all **15 SceneEditHistoryTests**. Those methods belong to the 257 portable tests and are not another fifteen native methods inside, or added to, the 83-method native total. Host/simulator test duration is not a device latency or performance benchmark.

## Independently counted native suites

All 83 distinct completed native method lines report `passed`; no failed method or assertion was found.

| Suite | Executed / passed | Failures |
| --- | ---: | ---: |
| BoundedFileReaderTests | 13 / 13 | 0 |
| LightingPlanPDFTests | 3 / 3 | 0 |
| ProjectDocumentIOTests | 9 / 9 | 0 |
| ProjectStoreOperationTests | 15 / 15 | 0 |
| ReferencePhotoTests | 7 / 7 | 0 |
| SpatialPreviewTests | 3 / 3 | 0 |
| StudioSliderEditingTests | 8 / 8 | 0 |
| **StudioSliderTrackingTests** | **15 / 15** | **0** |
| **StudioTrackingSliderTests** | **3 / 3** | **0** |
| StudyRendererTests | 7 / 7 | 0 |
| **Total** | **83 / 83** | **0** |

The new fifteen tracking/mapping methods exercise controlled session boundaries, captured generations and writers, other-owner and parent-force-close behavior, final-value ordering, post-end rejection, reentrant cancellation/invalidation, exact unchanged/imported values, and mapping/input validity. Their native suite reports 0.030s execution / 0.249s aggregate. This is actual Apple execution of the helper's contracts; those controlled callbacks are not a trace of a user's touch.

The three native UIKit methods actually passed:

| Method | Result / seconds |
| --- | --- |
| `testInvalidRangeDisablesNativeControlWithoutWritingTheModel` | Pass / 0.009 |
| `testNativeAccessibilityActionsUseExactDoubleStepsAndRespectDisabledState` | Pass / 0.006 |
| `testProgrammaticConfigurationAndStrayValueEventNeverRoundTripDouble` | Pass / 0.005 |

These methods instantiate the real `StudioTrackingSlider`, configure it, call its accessibility actions and send a stray value event. They establish those programmatic UIKit paths, immediate exact accessibility values, disabled/boundary handling and no unintended Double write. They do **not** synthesize a touch drag, establish SwiftUI control lifetime during presentation, verify interruption/cancellation on a real device, or constitute a VoiceOver/layout audit. The unchanged eight adapter methods and all fifteen actor/operation methods also passed; the actor suite aggregate is 10.112s.

The original optics Undo expectation is still **0.6m**. Source 10's observed **2.25m** and source 9's **1.3m** failures remain historical failures. This native unit success cannot mark that UI regression repaired before its actual source-11 scenario completes.

## Retained warnings and exercised failure paths

No Swift compiler error, native assertion failure or actual `##[error]` marker appears in the complete log. The result-bundle guard's shell text contains a potential error message, but that branch was not an executed error: result export and uploads completed. The log is not warning-free:

- AppIntents extraction was skipped because no AppIntents.framework dependency was present. Builds continued successfully.
- Artifact tooling reported Node `punycode`/`url.parse()` deprecations and the forced Node 20-to-24 runtime transition.
- Startup output contains launch-measurement, IOSurface notification and missing cache/data-file diagnostics. All native methods subsequently passed; these messages are retained without assigning an unobserved application cause or declaring them a product failure.
- NSCocoa error 3072 occurs inside the passing file-presenter cancellation test; the injected presenter error 17 occurs inside the passing coordination-error propagation test. The malformed-JPEG diagnostic appears inside the passing malformed/oversized-reference rejection method. Their immediately associated method results distinguish exercised rejection paths from an unaccounted failure.

The raw log remains the authoritative full output. None of these diagnostics was removed or relabeled to manufacture a pass.

## Artifact metadata and raw identity

The [artifact metadata](95e9c24-native-artifacts.json) identifies source 95e9c24 for every entry. The following sizes/digests are **GitHub-reported metadata only**. No archive was downloaded, CRC-checked or visually inspected for this observation.

| Artifact | ID | Bytes | Reported SHA-256 |
| --- | ---: | ---: | --- |
| Unsigned Debug simulator app | 14922116432 | 2,170,452 | `66181e76c00fcb68ca9dc9efd0dace803502165f204ff0a6af45b89dbb633c13` |
| Unsigned Release simulator app | 14921651235 | 2,503,789 | `3d7a2a9b7aff79e2ddcf74d963e536061da773edef9e5ffebdf08e4f2683b69b` |
| Native unit/build evidence | 14921917570 | 65,532,463 | `ecb5c7b6d2e1c2266895e456da5ac469f10a04358d5b096891718a1c17cc3a3a` |
| Compact native evidence | 14921647800 | 82,877 | `a87794206c8530e125ae7ac3de8fb5d2e3a61dad72c71b5a33598d2ee9e8b450` |
| Core test evidence | 14921880114 | 61,132 | `a3aec724a29c18d0603dd09cb3f759d4e17c467c14bffe4cfd0683b81c4b9baf` |

The unchanged complete [95e9c24-native-job.log](95e9c24-native-job.log) is **774,676 UTF-8 bytes** / 774,625 decoded characters, SHA-256 **`bf4eedabe5693ee1866271ce63ea3ba028ab73d98013f6aabfec44a09b046d56`**. The 4,291-byte metadata JSON has SHA-256 **`a572e73e2251fde25656fa641efc28473bce0231a2bb1eb552f390bab17bd7a6`**. The specialist independently recomputed both hashes.

## Gate and source boundary

At exact source 95e9c24, core and native build evidence now pass; **M01 remains active because persistence smoke and coherent UI acceptance are outstanding**. Actual optics touch/Undo/Redo/relaunch, crowded-plan text/selection, native accessibility and physical-device requirements are not inferred from these 83 units.

Counts remain **21 integrated packages, 42 actionable tasks, eleven full local cycles, sixteen pushed commits and 61 specialists** through source 11. The guide and CI-budget changes are later working changes; a separate two-screen native accessibility-audit candidate is under review. None ran in this source or gains acceptance or a completed-count increment from this result. No source-12, score, milestone, protected threshold or release promotion is made.
