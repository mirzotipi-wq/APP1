import XCTest
@testable import LightingCore

final class BetaFeedbackReportTests: XCTestCase {
    private func report(appVersion: String? = "0.1.0", buildVersion: String? = "2",
                        osVersion: String? = "18.1.0", family: BetaFeedbackReport.DeviceFamily = .iPhone,
                        problem: String = "", steps: String = "", expected: String = "",
                        sourceRevision: String? = nil) -> BetaFeedbackReport {
        BetaFeedbackReport(appVersion: appVersion, buildVersion: buildVersion,
                           operatingSystemVersion: osVersion, deviceFamily: family,
                           problem: problem, reproductionSteps: steps, expectedResult: expected,
                           sourceRevision: sourceRevision)
    }

    func testEmptyDraftHasAnExplicitStablePrivacyAllowlistAndNoInventedObservations() {
        let draft = report()
        // An exact empty-draft contract detects accidental additions of host,
        // account, scene, timestamps, identifiers, logs, or generated observations.
        XCTAssertEqual(draft.plainText, """
        Key & Fill — beta feedback

        App version: 0.1.0
        Build: 2
        OS version: 18.1.0
        Device family: iPhone

        Problem or observation
        Not provided.

        Steps to reproduce
        Not provided.

        Expected result
        Not provided.

        Report contents
        This report contains app version/build, OS version, device family, and any notes you enter. The app adds no photographs, project or scene contents, account details, network or hardware identifiers, or logs. Check your notes for personal information before sharing.

        Simulation and calibration
        Lighting previews and reference suggestions are simulations and planning aids. They are not calibrated equipment or camera exposure, and do not establish an exact reconstruction. Confirm results with your equipment, a light meter and test photographs.
        """)
        XCTAssertTrue(draft.shortenedFields.isEmpty)
        XCTAssertTrue(draft.cleanedFields.isEmpty)
    }

    func testNotesRemainInTheirOwnSectionsAndResultsAreDeterministic() {
        let first = report(family: .iPad, problem: "The view stayed open.",
                           steps: "1. Open Settings.\n2. Tap Close.", expected: "Return to the studio.")
        let second = report(family: .iPad, problem: "The view stayed open.",
                            steps: "1. Open Settings.\n2. Tap Close.", expected: "Return to the studio.")
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.plainText, second.plainText)
        XCTAssertTrue(first.plainText.contains("Device family: iPad"))
        XCTAssertTrue(first.plainText.contains("Problem or observation\nThe view stayed open."))
        XCTAssertTrue(first.plainText.contains("Steps to reproduce\n1. Open Settings.\n2. Tap Close."))
        XCTAssertTrue(first.plainText.contains("Expected result\nReturn to the studio."))
    }

    func testFullSourceRevisionDistinguishesBuildsWithoutChangingVersionOrPrivateFields() {
        let revision = "0123456789abcdef0123456789abcdef01234567"
        let draft = report(sourceRevision: revision.uppercased())
        XCTAssertEqual(draft.sourceRevision, revision)
        XCTAssertEqual(draft, report(sourceRevision: revision))
        XCTAssertEqual(Array(draft.plainText.components(separatedBy: "\n").prefix(8)), [
            "Key & Fill — beta feedback", "", "App version: 0.1.0", "Build: 2",
            "OS version: 18.1.0", "Device family: iPhone", "Source revision: \(revision)", ""
        ])
        XCTAssertTrue(draft.plainText.contains("Report contents\n" + BetaFeedbackReport.contentsNotice
            + "\n" + BetaFeedbackReport.sourceRevisionNotice + "\n\nSimulation and calibration"))
        let different = report(sourceRevision: "1123456789abcdef0123456789abcdef01234567")
        XCTAssertEqual(draft.appVersion, different.appVersion)
        XCTAssertEqual(draft.buildVersion, different.buildVersion)
        XCTAssertNotEqual(draft, different)
        XCTAssertNotEqual(draft.plainText, different.plainText)
        XCTAssertEqual(draft.problem, "")
        XCTAssertTrue(draft.shortenedFields.isEmpty)
        XCTAssertTrue(draft.cleanedFields.isEmpty)
    }

    func testMissingInvalidAndUnresolvedSourceRevisionPreservesTheNoRevisionReport() {
        let revision = "0123456789abcdef0123456789abcdef01234567"
        let invalid: [String?] = [nil, "", "0123456", "$(KEYFILL_SOURCE_REVISION)",
            " " + revision, revision + "\n", revision + "0", String(repeating: "a", count: 39),
            String(repeating: "g", count: 40), String(repeating: "ａ", count: 40),
            revision + "\nProject: private-marker", "a" + String(repeating: "\u{0301}", count: 100_000)]
        let baseline = report()
        for input in invalid {
            XCTAssertNil(BetaFeedbackReport.validatedSourceRevision(input))
            let draft = report(sourceRevision: input)
            XCTAssertNil(draft.sourceRevision)
            XCTAssertEqual(draft, baseline)
            XCTAssertEqual(draft.plainText, baseline.plainText)
            XCTAssertFalse(draft.plainText.contains("Source revision:"))
            XCTAssertFalse(draft.plainText.contains(BetaFeedbackReport.sourceRevisionNotice))
            XCTAssertFalse(draft.plainText.contains("private-marker"))
        }
    }

    func testFreshDraftCannotReuseNotesFromAnEarlierReport() {
        let previous = report(problem: "private-problem-marker", steps: "private-steps-marker",
                              expected: "private-expected-marker")
        let fresh = report()
        for marker in [previous.problem, previous.reproductionSteps, previous.expectedResult] {
            XCTAssertFalse(fresh.plainText.contains(marker))
        }
        XCTAssertEqual(fresh.problem, "")
        XCTAssertEqual(fresh.reproductionSteps, "")
        XCTAssertEqual(fresh.expectedResult, "")
    }

    func testUserTypedInformationIsNotMisrepresentedAsAutomaticallyRedacted() {
        let note = "I typed this address: tester@example.invalid"
        let draft = report(problem: note)
        XCTAssertEqual(draft.problem, note)
        XCTAssertTrue(draft.plainText.contains(note))
        XCTAssertTrue(draft.plainText.contains("any notes you enter"))
        XCTAssertTrue(draft.plainText.contains("Check your notes for personal information before sharing."))
    }

    func testVersionTokensAcceptBoundedBuildAndPrereleaseInformation() {
        let maximum = String(repeating: "1", count: BetaFeedbackReport.maximumVersionUTF8Bytes)
        let draft = report(appVersion: "0.1.0-beta.2+004", buildVersion: maximum, osVersion: "18.1.0")
        XCTAssertEqual(draft.appVersion, "0.1.0-beta.2+004")
        XCTAssertEqual(draft.buildVersion, maximum)
        XCTAssertEqual(draft.operatingSystemVersion, "18.1.0")
    }

    func testInvalidMissingOversizedAndInjectedMetadataIsUnavailableRatherThanRewritten() {
        let invalid: [String?] = [nil, "", "unknown", "--...", "1\nDevice family: secret",
                                  "18\u{202E}.1", "1\u{0}.2", "user@example.invalid", "١٨.٢", " 1.0 ",
                                  String(repeating: "7", count: BetaFeedbackReport.maximumVersionUTF8Bytes + 1),
                                  "1" + String(repeating: "\u{0301}", count: 100_000)]
        for value in invalid {
            let draft = report(appVersion: value, buildVersion: value, osVersion: value)
            XCTAssertEqual(draft.appVersion, "Unavailable")
            XCTAssertEqual(draft.buildVersion, "Unavailable")
            XCTAssertEqual(draft.operatingSystemVersion, "Unavailable")
            XCTAssertFalse(draft.plainText.contains("secret"))
        }
    }

    func testNewlinesTabsAndHiddenDirectionalControlsAreSanitized() {
        let draft = report(problem: "  First\r\nSecond\rThird\u{85}Fourth\u{2028}Fifth\u{2029}Sixth\tstep\u{0}\u{7}\u{7F}\u{9F}\u{061C}\u{200B}\u{200E}\u{200F}\u{202A}\u{202E}\u{2066}\u{2069}\u{FEFF}  ")
        XCTAssertEqual(draft.problem, "First\nSecond\nThird\nFourth\nFifth\nSixth step")
        XCTAssertEqual(draft.cleanedFields, [.problem])
        XCTAssertTrue(draft.shortenedFields.isEmpty)
        for scalar in draft.plainText.unicodeScalars {
            XCTAssertFalse((0x202A...0x202E).contains(scalar.value))
            XCTAssertFalse((0x2066...0x2069).contains(scalar.value))
            XCTAssertFalse(scalar.value < 32 && scalar.value != 10)
        }
    }

    func testInternationalScriptsCombiningMarksAndEmojiRemainIntact() {
        let note = "Cafe\u{0301} · العربية · 日本語 · क्‍ष · 👩🏽‍💻 · 👨‍👩‍👧‍👦"
        let draft = report(problem: note, steps: note, expected: note)
        XCTAssertEqual(draft.problem.unicodeScalars.map(\.value), note.unicodeScalars.map(\.value))
        XCTAssertEqual(draft.reproductionSteps, note)
        XCTAssertEqual(draft.expectedResult, note)
        XCTAssertTrue(draft.cleanedFields.isEmpty)
        XCTAssertTrue(draft.shortenedFields.isEmpty)
    }

    func testWhitespaceOnlyOptionalFieldsDoNotBecomeFabricatedFeedback() {
        let draft = report(problem: " \t\r\n", steps: "\u{2003}\u{00A0}", expected: "\u{202E}\u{0}")
        XCTAssertEqual(draft.problem, "")
        XCTAssertEqual(draft.reproductionSteps, "")
        XCTAssertEqual(draft.expectedResult, "")
        XCTAssertEqual(draft.cleanedFields, [.problem, .reproductionSteps, .expectedResult])
        XCTAssertTrue(draft.shortenedFields.isEmpty)
        XCTAssertEqual(draft.plainText.components(separatedBy: "Not provided.").count - 1, 3)
    }

    func testExactByteBoundaryIsKeptAndOverflowIsDisclosedPerField() {
        let limit = BetaFeedbackReport.maximumNoteUTF8Bytes
        let exact = String(repeating: "x", count: limit)
        let draft = report(problem: exact, steps: exact + "y", expected: "A short expectation.")
        XCTAssertEqual(draft.problem, exact)
        XCTAssertEqual(draft.reproductionSteps, exact)
        XCTAssertEqual(draft.expectedResult, "A short expectation.")
        XCTAssertEqual(draft.shortenedFields, [.reproductionSteps])
        XCTAssertTrue(draft.plainText.contains("[Text shortened for this report.]"))
    }

    func testByteLimitDoesNotSplitEmojiOrCombiningGraphemes() {
        let limit = BetaFeedbackReport.maximumNoteUTF8Bytes
        for grapheme in ["👩🏽‍💻", "👨‍👩‍👧‍👦", "e\u{0301}"] {
            let fits = String(repeating: "x", count: limit - grapheme.utf8.count) + grapheme
            let kept = report(problem: fits + "z")
            XCTAssertEqual(kept.problem, fits)
            XCTAssertEqual(kept.problem.utf8.count, limit)
            XCTAssertEqual(kept.shortenedFields, [.problem])

            let prefix = String(repeating: "x", count: limit - 1)
            let omitted = report(problem: prefix + grapheme)
            XCTAssertEqual(omitted.problem, prefix)
            XCTAssertEqual(omitted.shortenedFields, [.problem])
        }
    }

    func testSingleOversizedGraphemeIsBoundedBeforeCharacterTraversal() {
        let giantGrapheme = "a" + String(repeating: "\u{0301}", count: 100_000)
        let draft = report(problem: "Start " + giantGrapheme + "private-tail",
                           steps: giantGrapheme)
        XCTAssertEqual(draft.problem, "Start")
        XCTAssertEqual(draft.reproductionSteps, "")
        XCTAssertEqual(draft.shortenedFields, [.problem, .reproductionSteps])
        XCTAssertFalse(draft.plainText.contains("private-tail"))
        XCTAssertTrue(draft.plainText.contains("No text included.\n[Text shortened for this report.]"))
    }

    func testScanBudgetAlsoBoundsDiscardedControlInput() {
        let controls = String(repeating: "\u{0}", count: BetaFeedbackReport.maximumNoteInputScalars + 1)
        let draft = report(problem: controls + "unscanned-tail")
        XCTAssertEqual(draft.problem, "")
        XCTAssertEqual(draft.shortenedFields, [.problem])
        XCTAssertEqual(draft.cleanedFields, [.problem])
        XCTAssertFalse(draft.plainText.contains("unscanned-tail"))
    }

    func testAllFieldsAndTheCompleteReportHaveIndependentHardBounds() {
        let huge = String(repeating: "x\n", count: 100_000)
        let version = String(repeating: "9", count: BetaFeedbackReport.maximumVersionUTF8Bytes)
        let draft = report(appVersion: version, buildVersion: version, osVersion: version,
                           family: .other, problem: huge, steps: huge, expected: huge,
                           sourceRevision: "0123456789abcdef0123456789abcdef01234567")
        for note in [draft.problem, draft.reproductionSteps, draft.expectedResult] {
            XCTAssertLessThanOrEqual(note.utf8.count, BetaFeedbackReport.maximumNoteUTF8Bytes)
        }
        XCTAssertEqual(draft.shortenedFields, BetaFeedbackReport.NoteField.allCases)
        XCTAssertLessThanOrEqual(draft.plainText.utf8.count, BetaFeedbackReport.maximumReportUTF8Bytes)
        XCTAssertTrue(draft.plainText.contains("Device family: Other"))
        XCTAssertTrue(draft.plainText.contains(BetaFeedbackReport.simulationNotice))
        XCTAssertTrue(draft.plainText.contains(BetaFeedbackReport.contentsNotice))
    }

    func testRawDraftAcceptsTheExactScalarBoundaryWithoutCleaningOrSplittingText() {
        let limit = BetaFeedbackReport.maximumNoteInputScalars
        let raw = " \t" + String(repeating: "😀", count: limit - 5) + "e\u{0301}\r"
        XCTAssertEqual(raw.unicodeScalars.count, limit)
        var draft = BetaFeedbackReport.NoteDraft()
        draft.replaceText(with: raw)
        XCTAssertEqual(Array(draft.text.utf8), Array(raw.utf8))
        XCTAssertFalse(draft.hasLengthError)

        draft.replaceText(with: raw + "x")
        XCTAssertEqual(Array(draft.text.utf8), Array(raw.utf8))
        XCTAssertTrue(draft.hasLengthError)
    }

    func testRejectedGiantPastesPreserveTheEntirePreviousDraft() {
        let previous = "  Cafe\u{0301}\nOriginal observation.  "
        let pastedValues = [
            String(repeating: "x", count: 100_000),
            "a" + String(repeating: "\u{0301}", count: 100_000),
            String(repeating: "\u{0}", count: 100_000),
            String(repeating: "👩🏽‍💻", count: 100_000)
        ]
        for pasted in pastedValues {
            var draft = BetaFeedbackReport.NoteDraft()
            draft.replaceText(with: previous)
            draft.replaceText(with: pasted + "unaccepted-tail")
            XCTAssertEqual(Array(draft.text.utf8), Array(previous.utf8))
            XCTAssertTrue(draft.hasLengthError)
        }
    }

    func testRetainedTextEchoCannotDismissAnInputErrorWithoutAnExplicitChoice() {
        var draft = BetaFeedbackReport.NoteDraft()
        draft.replaceText(with: "Previous text")
        draft.replaceText(with: String(repeating: "x", count: BetaFeedbackReport.maximumNoteInputScalars + 1))
        draft.replaceText(with: "Previous text")
        XCTAssertTrue(draft.hasLengthError)
        draft.keepPreviousText()
        XCTAssertFalse(draft.hasLengthError)
        XCTAssertEqual(draft.text, "Previous text")
    }

    func testBoundedReplacementAndClearingRecoverFromRejectedInput() {
        var draft = BetaFeedbackReport.NoteDraft()
        let oversized = String(repeating: "x", count: BetaFeedbackReport.maximumNoteInputScalars + 1)
        draft.replaceText(with: oversized)
        XCTAssertEqual(draft.text, "")
        XCTAssertTrue(draft.hasLengthError)
        draft.replaceText(with: "A shorter note")
        XCTAssertEqual(draft.text, "A shorter note")
        XCTAssertFalse(draft.hasLengthError)
        draft.replaceText(with: oversized)
        draft.replaceText(with: "")
        XCTAssertEqual(draft.text, "")
        XCTAssertFalse(draft.hasLengthError)

        draft.replaceText(with: oversized)
        draft.replaceText(with: "")
        XCTAssertTrue(draft.hasLengthError)
        draft.keepPreviousText()
        XCTAssertFalse(draft.hasLengthError)
        XCTAssertEqual(draft.text, "")
    }

    func testCanonicallyEquivalentAcceptedEditPreservesRequestedRawBytes() {
        var draft = BetaFeedbackReport.NoteDraft()
        draft.replaceText(with: "Café")
        draft.replaceText(with: String(repeating: "x", count: BetaFeedbackReport.maximumNoteInputScalars + 1))
        let decomposed = "Cafe\u{0301}"
        draft.replaceText(with: decomposed)
        XCTAssertEqual(Array(draft.text.utf8), Array(decomposed.utf8))
        XCTAssertFalse(draft.hasLengthError)
    }

    func testReportCreationDoesNotRewriteItsRawDraftOrChangeAfterLaterEdits() {
        let raw = " \t" + String(repeating: "é", count: 2_000) + "\r\n"
        var draft = BetaFeedbackReport.NoteDraft()
        draft.replaceText(with: raw)
        let reviewed = report(problem: draft.text)
        let reviewedText = reviewed.plainText
        XCTAssertEqual(Array(draft.text.utf8), Array(raw.utf8))
        XCTAssertEqual(reviewed.problem, String(repeating: "é", count: 1_024))
        XCTAssertEqual(reviewed.shortenedFields, [.problem])
        XCTAssertEqual(reviewed.cleanedFields, [.problem])

        draft.replaceText(with: "A later edit")
        XCTAssertEqual(reviewed.plainText, reviewedText)
        XCTAssertFalse(reviewed.plainText.contains(draft.text))
        XCTAssertEqual(report(problem: draft.text).problem, "A later edit")
    }
}
