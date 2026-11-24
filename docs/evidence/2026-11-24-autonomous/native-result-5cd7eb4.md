# Source 10 finalized core, native build and unit results

Exact executed revision: **`5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`**, tree **`aaf52e62fff970cdc55f5908326523e58a1cf394`**. [Workflow45383556829](https://github.com/mirzotipi-wq/APP1/actions/runs/45383556829). This later observation supplements the approximately11:47 UTC pending-native record in checkpoint10; it does not rewrite that earlier observation or transfer source9 results.

## Observation and provenance

The evidence worker fetched the current job list **once**, during **11:54:07–11:54:14 UTC on2026-11-24**. All five returned jobs identify the exact source SHA above. The simulator job had completed success at11:54:08 UTC, so the worker retrieved its complete decoded log and the already completed core log. There was no second job poll, test rerun or workflow mutation. Artifact metadata was retrieved once after completion; no artifact ZIP was downloaded for this report.

| Job | Actual state in that observation | Times / limits |
| --- | --- | --- |
| Core138416296344 | **Completed / success** | Started11:37:05, completed11:39:05 UTC; complete log retained |
| Simulator138417363792 | **Completed / success** | Started11:39:10, completed11:54:08 UTC; complete log retained |
| Library/reference138417363841 | **In progress**, selected UI step running | No completed UI method count inferred |
| Room/precision138417363881 | **In progress**, selected UI step running | No completed UI method count inferred |
| Studio/export138417363754 | **Queued** | No execution or result inferred |

The UI result is still outstanding. In particular, source9's actual optics Undo failure has not been shown fixed by the source10 unit pass.

## Complete remote core results

[Core job138416296344](https://github.com/mirzotipi-wq/APP1/actions/runs/45383556829/job/138416296344) ran on Ubuntu24.04.5 with Swift6.4.2. The full [5cd7eb4-core.log](5cd7eb4-core.log) includes exact checkout identity and records:

| Check | Actual result |
| --- | --- |
| Portable Debug | **251/251**, zero failures; **8.561s** aggregate |
| Portable Release | **251/251**, zero failures; **4.530s** aggregate |
| Python evidence/CI checks | **28/28**, **0.283s** |
| Native source syntax and source assets/manifest checks | Successful job step |
| Original shared Float32 host fixtures | **6/6**, maximum channel difference at most1; unsupported masks match |
| Strict far-camera/translation host controls | **8/8**, zero channel difference in these cases; unsupported masks match |

These are actual remote results for source10, distinct from its prior immutable local251/251 per configuration and28 Python run. Host suite elapsed times are not device latency, frame-time, thermal or responsiveness measurements. Host shared-header checks are not Metal execution; the separate native renderer suite below provides simulator Metal evidence.

## Actual unsigned builds and native methods

[Simulator job138417363792](https://github.com/mirzotipi-wq/APP1/actions/runs/45383556829/job/138417363792) used the macos26-intel runner, Xcode26.6 build17F113, Apple Swift6.3.3 and iPhoneSimulator SDK26.5, targeting iOS17. The native commands compile the app in Swift5 language mode. The Metal compiler preflight succeeded; no claim is made about whether that run installed or reused the component.

The full [5cd7eb4-native-job.log](5cd7eb4-native-job.log) records both **unsigned Debug and Release build successes** at11:43:05.226043 and11:44:16.340722 UTC. The job also ran the portable package on macOS:251 methods, zero failures,17.783s final all-tests aggregate. That is additional source-specific execution, not another set of unique domain methods.

Native XCTest completed **65/65 methods, zero failures**, with the final all-tests aggregate **24.121s** (23.739s reported test execution). `TEST SUCCEEDED` appears at **11:53:20.732617 UTC**. The finalized result export and evidence-upload steps completed successfully in the job response.

| Native suite | Actual methods | Failures |
| --- | ---: | ---: |
| BoundedFileReaderTests |13|0|
| LightingPlanPDFTests |3|0|
| ProjectDocumentIOTests |9|0|
| **ProjectStoreOperationTests** |**15**|**0**|
| ReferencePhotoTests |7|0|
| SpatialPreviewTests |3|0|
| StudioSliderEditingTests |8|0|
| StudyRendererTests |7|0|
| **Total** |**65**|**0**|

The 15 operation tests actually executed on the Apple runner, including all three DEBUG-only fixture/isolation cases. Their suite aggregate was7.812s. The complete method-result lines are retained in the raw log:

| ProjectStoreOperationTests method | Result / recorded seconds |
| --- | --- |
| `testActorSerializesCompetingSavesWhileMainActorRemainsAvailable` | Pass /0.024 |
| `testCancellationAfterCommitStillDeliversAndAdoptsTheReceiptExactlyOnce` | Pass /0.010 |
| `testCorruptLoadAndSaveKeepProtectedBytesAndDoNotProduceAnAdoption` | Pass /0.009 |
| `testFailedCommandDoesNotAdoptOrChangeBytesAndCanBeRetried` | Pass /0.012 |
| `testFirstSavePreservesHistoryAndPresentationWhileInvalidatingDraftCallbacks` | Pass /0.004 |
| `testInitializerDoesNoFileWorkAndQueuedCancellationCannotCreateAFile` | Pass /0.005 |
| `testLargeLaunchFixtureUsesRealBoundedBytesAndRetainsSavedEditsOnRelaunch` | Pass /7.275 |
| `testMetadataSwitchAndConfirmedReloadHaveDistinctAdoptionPolicies` | Pass /0.004 |
| `testRealStaleSaveRetainsLocalSceneHistoryAndCompetingBytes` | Pass /0.012 |
| `testRecoveryCandidateReadNeverAdoptsLatestLibraryOrUnsavedEditor` | Pass /0.011 |
| `testRecoveryRechecksFullCandidateThenUsesNewlyAvailableCapacity` | Pass /0.085 |
| `testReservationRejectsDuplicateCommandsAndSceneCallbacksUntilItSettles` | Pass /0.035 |
| `testSaveReceiptKeepsAnyNewerSceneDirtyInsteadOfMarkingItSaved` | Pass /0.002 |
| `testScopedLaunchFixtureIsDeferredAndRelaunchKeepsRecoveryResult` | Pass /0.210 |
| `testUITestingWithoutValidIDNeverLoadsOrChangesNormalSavedProjects` | Pass /0.025 |

This establishes actual Apple execution of the worker/helper contracts, including real storage, cancellation/receipt ordering and test-directory isolation. It does not establish the presented SwiftUI sheet's lifetime, refreshed child callbacks after a first save, provider UI transitions, native progress responsiveness or complete large-library UI save/relaunch. The7.275s large-fixture test duration includes its complete fixture/storage sequence and is not an interactive latency benchmark. Those UI acceptance paths remain in the unfinished shards.

## Warnings and material findings

No Swift source compiler error or native method failure appears in the complete retrieved logs. The build logs retain these warnings rather than implying warning-free output:

- `appintentsmetadataprocessor` skips metadata extraction because there is no AppIntents.framework dependency. The Debug/Release/test builds continue successfully.
- The artifact-upload action's Node runtime reports DEP0040 (`punycode`) and DEP0169 (`url.parse()`) deprecations. These are tooling dependency warnings, not a reported application compiler failure.
- During the explicit document-coordination failure/cancellation tests, Foundation logs NSCocoaErrorDomain3072 cancellation and the injected `ProjectDocumentIOTests.presenter` code17 error. The immediately associated methods pass. These are exercised failure paths, not unaccounted native test failures.

The unchanged actual optics UI assertion and all remaining UI/device gates stay open. Passing all eight slider helper methods again does not establish the full dragged-control contract that failed at source9. No source correction was made during this evidence collection.

## Artifact metadata

These values are from the actual source10 workflow artifact response. Every artifact below identifies source5cd7eb4. **No ZIP download, CRC check, application inspection or visual review is claimed for these artifacts in this packet.** The full64MB native artifact was not needed to establish the completed log results.

| Artifact | ID | Bytes | Reported SHA-256 |
| --- | ---: | ---: | --- |
| Core test evidence |14917155083|60,666|`09477b0c444359468177382b7c7cb227f104d78561a4682405e12e948b9ed317`|
| Unsigned Debug simulator application |14916232068|2,097,953|`632676e6209144bd82c53c59cd8b885566ef28b954423c76f031c02a63ce0a37`|
| Unsigned Release simulator application |14917045997|2,422,094|`e50d5397a50b6dc19b84c46c31e92d1e082785860a558ec3f0fb7cc0c234d489`|
| Native unit/build evidence |14916957578|64,328,248|`b443bafffb56ec804c41b7e9590f7460ea970c55726f454909a76ef7b9642661`|
| Compact native attachments |14915779848|82,871|`d69c49a94893cb2fa1c278e066b32a19593910479668c971ead316c084e63db6`|

These are unsigned simulator builds, not signed physical-device applications, distribution archives, TestFlight or App Store releases. Complete persistence smoke/regression, physical performance/thermal/accessibility, calibrated photographic rendering and the other protected release gates remain open.

## Retained raw-log identity

The tool-returned complete decoded logs were saved as UTF-8, retaining their initial byte-order mark and text. These are complete job logs, not filtered excerpts.

| File | UTF-8 bytes | SHA-256 |
| --- | ---: | --- |
| [5cd7eb4-core.log](5cd7eb4-core.log) |197,272|`e9d721b4b818936b39e7fb1f9857f27eb5ec7692396da4c19e707738a8d6ceba`|
| [5cd7eb4-native-job.log](5cd7eb4-native-job.log) |754,457|`d4c2f751f371b5c7305e43866c08dbfa85f54ec79f33324cac157f4431fea8a3`|

The prior approximately11:47 UTC observation remains a valid dated record of unfinished native work. This report supplies the later finalized source10 build/unit results; it does not reinterpret source9's21/22 UI failure or certify any newer candidate.
