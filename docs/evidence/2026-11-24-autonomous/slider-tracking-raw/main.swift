import XCTest

XCTMain([
    testCase([
        ("testFirstValueBeforeBeginUndoesWholeWidthGestureAndKeepsEmitterCommand", StudioSliderEditingTests.testFirstValueBeforeBeginUndoesWholeWidthGestureAndKeepsEmitterCommand),
        ("testBeginBeforeFirstValueAndRepeatedBeginsPreserveOriginalScene", StudioSliderEditingTests.testBeginBeforeFirstValueAndRepeatedBeginsPreserveOriginalScene),
        ("testAccessibilityAdjustmentsFinishAndRemainSeparateAtBothBounds", StudioSliderEditingTests.testAccessibilityAdjustmentsFinishAndRemainSeparateAtBothBounds),
        ("testAccessibilityRetainsOutOfQuickRangeCoordinatesWithoutReversingDirection", StudioSliderEditingTests.testAccessibilityRetainsOutOfQuickRangeCoordinatesWithoutReversingDirection),
        ("testCancellationAfterEarlyValueRestoresStartAndRetainsRedo", StudioSliderEditingTests.testCancellationAfterEarlyValueRestoresStartAndRetainsRedo),
        ("testLateOtherOwnerEndDoesNotSplitEditBegunByFirstValue", StudioSliderEditingTests.testLateOtherOwnerEndDoesNotSplitEditBegunByFirstValue),
        ("testPrecisionCommandAfterGestureRemainsSeparateAndKeepsExactValue", StudioSliderEditingTests.testPrecisionCommandAfterGestureRemainsSeparateAndKeepsExactValue),
        ("testInvalidAndUnchangedValuesDoNotOpenAnEditOrDiscardRedo", StudioSliderEditingTests.testInvalidAndUnchangedValuesDoNotOpenAnEditOrDiscardRedo)
    ]),
    testCase([
        ("testContinuousChangesMakeOneUndoEntryAndRepeatedBeginKeepsOriginal", SceneEditHistoryTests.testContinuousChangesMakeOneUndoEntryAndRepeatedBeginKeepsOriginal),
        ("testUnchangedAndCancelledGesturesPreserveRedo", SceneEditHistoryTests.testUnchangedAndCancelledGesturesPreserveRedo),
        ("testUndoDuringGestureAndLateEndDoNotDestroyRedo", SceneEditHistoryTests.testUndoDuringGestureAndLateEndDoNotDestroyRedo),
        ("testUndoDuringFirstGestureWorksWithoutPriorCommands", SceneEditHistoryTests.testUndoDuringFirstGestureWorksWithoutPriorCommands),
        ("testRedoClosesGestureAndDropsOldBranchOnlyIfSceneChanged", SceneEditHistoryTests.testRedoClosesGestureAndDropsOldBranchOnlyIfSceneChanged),
        ("testDiscreteCommandDuringGesturePreservesBothUndoSteps", SceneEditHistoryTests.testDiscreteCommandDuringGesturePreservesBothUndoSteps),
        ("testHistoryRetainsOnlySixtyNewestEntriesAndSupportsSmallerLimits", SceneEditHistoryTests.testHistoryRetainsOnlySixtyNewestEntriesAndSupportsSmallerLimits),
        ("testResetClearsBothDirectionsAndPendingTransaction", SceneEditHistoryTests.testResetClearsBothDirectionsAndPendingTransaction),
        ("testLateEndFromAnotherControlDoesNotCloseNewGesture", SceneEditHistoryTests.testLateEndFromAnotherControlDoesNotCloseNewGesture),
        ("testDifferentLightOwnersCommitSeparateStepsWithoutExplicitClose", SceneEditHistoryTests.testDifferentLightOwnersCommitSeparateStepsWithoutExplicitClose),
        ("testRepeatedBeginFromSameOwnerKeepsTheOriginalScene", SceneEditHistoryTests.testRepeatedBeginFromSameOwnerKeepsTheOriginalScene),
        ("testPreviousProjectEndCannotCloseSameLightFieldInAnotherProject", SceneEditHistoryTests.testPreviousProjectEndCannotCloseSameLightFieldInAnotherProject),
        ("testUnmatchedEndPreservesNewOwnerRollbackAndRedo", SceneEditHistoryTests.testUnmatchedEndPreservesNewOwnerRollbackAndRedo),
        ("testOwnedAndLegacyEditsKeepExplicitForceCloseSemantics", SceneEditHistoryTests.testOwnedAndLegacyEditsKeepExplicitForceCloseSemantics),
        ("testOwnerChangesRespectHistoryLimitAndLateEndsKeepRedo", SceneEditHistoryTests.testOwnerChangesRespectHistoryLimitAndLateEndsKeepRedo)
    ]),
    testCase([
        ("testFinalSampleBeforeEndRestoresWholeGestureAndKeepsEmitterCommand", StudioSliderTrackingTests.testFinalSampleBeforeEndRestoresWholeGestureAndKeepsEmitterCommand),
        ("testValueAfterEndCannotReopenHistoryOrDisableUndo", StudioSliderTrackingTests.testValueAfterEndCannotReopenHistoryOrDisableUndo),
        ("testUnchangedThumbPreservesExactImportedDoubleAndRedo", StudioSliderTrackingTests.testUnchangedThumbPreservesExactImportedDoubleAndRedo),
        ("testReturnToStartingThumbRestoresExactOffGridValueWithoutHistory", StudioSliderTrackingTests.testReturnToStartingThumbRestoresExactOffGridValueWithoutHistory),
        ("testNewSessionRetiresOldTokenAndKeepsGesturesSeparate", StudioSliderTrackingTests.testNewSessionRetiresOldTokenAndKeepsGesturesSeparate),
        ("testSessionRetainsOriginalWriterAndRange", StudioSliderTrackingTests.testSessionRetainsOriginalWriterAndRange),
        ("testCapturedGenerationCannotWriteOrCloseNewProjectEdit", StudioSliderTrackingTests.testCapturedGenerationCannotWriteOrCloseNewProjectEdit),
        ("testParentForceCloseKeepsSubsequentActiveValuesInOneOwnedEdit", StudioSliderTrackingTests.testParentForceCloseKeepsSubsequentActiveValuesInOneOwnedEdit),
        ("testAnotherOwnerCannotAbsorbAnActiveTokenValue", StudioSliderTrackingTests.testAnotherOwnerCannotAbsorbAnActiveTokenValue),
        ("testCancellationCommitsLastPublishedValueWithoutFloatRewrite", StudioSliderTrackingTests.testCancellationCommitsLastPublishedValueWithoutFloatRewrite),
        ("testInvalidSamplesDoNotWriteOrLeaveEditingOpen", StudioSliderTrackingTests.testInvalidSamplesDoNotWriteOrLeaveEditingOpen),
        ("testReentrantFinishDuringFinalWriteClosesOnlyOnce", StudioSliderTrackingTests.testReentrantFinishDuringFinalWriteClosesOnlyOnce),
        ("testOwnerReassertionCannotWriteAfterReentrantCancellation", StudioSliderTrackingTests.testOwnerReassertionCannotWriteAfterReentrantCancellation),
        ("testReentrantInvalidationAtBeginRejectsSubsequentValues", StudioSliderTrackingTests.testReentrantInvalidationAtBeginRejectsSubsequentValues),
        ("testMappingRejectsInvalidConfigurationAndKeepsEndpointsAndSteps", StudioSliderTrackingTests.testMappingRejectsInvalidConfigurationAndKeepsEndpointsAndSteps)
    ])
])
