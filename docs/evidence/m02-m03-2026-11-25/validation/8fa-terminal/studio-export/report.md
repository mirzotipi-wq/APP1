# 8fa studio-export terminal verification

Exact source `8fa4399f50554836ce70ec2929a28534f70ba4b0`, primary run 45649843650, job 139341046265: **success**. The complete terminal log contains **10 unique starts and 10 unique passes**, matching the exact-source inventory: two LightingPlanExportUITests methods and eight StudioSmokeTests methods. There are zero failures, skipped methods, duplicate starts/outcomes, missing or unexpected methods, and no interrupted method. This shard contains no StudioOpticsUITests methods.

XCTest reports 822.399 seconds of test time (822.421 wall). The two export methods account for 356.507 seconds; the eight StudioSmoke methods account for 465.892 seconds.

| Required method | Actual pass duration (seconds) |
| --- | ---: |
| LightingPlanExportUITests.testExportPreviewOpensWithoutSavingOrChangingScene | 158.554 |
| LightingPlanExportUITests.testFullLibraryCanPrepareUnsavedEditableCopyWithoutSavingOrChangingHistory | 197.953 |
| StudioSmokeTests.testCameraFocalLengthUndoAndRelaunch | 69.291 |
| StudioSmokeTests.testCorruptProjectBlocksSavingAcrossRelaunch | 21.138 |
| StudioSmokeTests.testMeterBalanceSaveUndoAndRelaunch | 72.396 |
| StudioSmokeTests.testRecipeEditSaveAndReopen | 59.291 |
| StudioSmokeTests.testSettingsFeet3DFitAndSimulatorARManualFallback | 109.646 |
| StudioSmokeTests.testStudioGuideKeepsUnsavedSetupSelectionAndHistory | 70.449 |
| StudioSmokeTests.testStudyRendersActualReferenceFrame | 27.038 |
| StudioSmokeTests.testStudySwitchesBetweenSphereAndMannequinWithoutEditingScene | 36.644 |

The UI bundle build succeeded at 16:27:26.997237 UTC. The first method starts at 16:36:45.295179 and the last sphere/mannequin method passes at 16:50:26.930085. TEST EXECUTE SUCCEEDED appears at 16:50:28.533372. Terminal job metadata records success for the pre/post host-condition captures, slider unified-log export, finalized xcresult/attachment export, and both full/compact uploads. There are no GitHub error annotations or failed test assertions in the terminal log. No failure-only keyboard/status diagnostic was emitted.

The checkout log and both artifact records bind to the exact 8fa revision. The source inventory was read from that revision and rechecked against the parsed outcomes. The environment is the selected Intel iPhone 17 Pro simulator, iOS 26.5, Xcode 26.6 build 17F113. This is evidence for these ten methods on this simulator; it does not certify the separate optics/library/room shards, physical devices, or ARM RealityKit execution.

The packet retains the complete decoded log, selected exact lines, every method event, source inventory, terminal metadata and artifact metadata. Artifact ZIPs were not downloaded in this review: their sizes and digests are API metadata, not fresh archive-byte verification. `receipt-sha256.json` records actual local receipt hashes and validation of the exact source/method set.

No test, workflow, deadline, assertion, retry, or production source was changed for this verification. The earlier failed/interrupted invocations remain separate historical evidence.
