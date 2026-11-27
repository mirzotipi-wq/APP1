import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

final class LightTargetLuxDraftTests: XCTestCase {
    private let english = LightTargetLuxDraft.LocaleContext(locale: Locale(identifier: "en_US"))
    private let french = LightTargetLuxDraft.LocaleContext(locale: Locale(identifier: "fr_FR"))

    func testInvalidEnglishGroupingCannotBecomeFrenchTargetWithoutAnEdit() {
        var draft = LightTargetLuxDraft()
        draft.initialize(value: nil, in: english)
        XCTAssertTrue(draft.replaceText(with: "1,000", in: english))
        XCTAssertNil(draft.target(in: english))

        // This check occurs before the view's locale-change observer runs.
        XCTAssertNil(draft.target(in: french))
        XCTAssertTrue(draft.requiresLocaleEdit(in: french))
        draft.invalidate(ifChangedTo: french)
        XCTAssertEqual(draft.text, "1,000")
        XCTAssertFalse(draft.replaceText(with: "1,000", in: french),
                       "A focus/binding echo is not permission to adopt a new locale")
        XCTAssertNil(draft.target(in: french))

        XCTAssertTrue(draft.replaceText(with: "", in: french))
        XCTAssertTrue(draft.replaceText(with: "1,000", in: french))
        XCTAssertEqual(draft.target(in: french), 1,
                       "An explicit new French edit may use the French decimal separator")
        XCTAssertFalse(draft.requiresLocaleEdit(in: french))
    }

    func testValidDecimalIsBlockedUntilEditedForTheNewLocale() {
        var draft = LightTargetLuxDraft()
        draft.initialize(value: nil, in: english)
        XCTAssertTrue(draft.replaceText(with: "12.5", in: english))
        XCTAssertEqual(draft.target(in: english), 12.5)
        XCTAssertNil(draft.target(in: french))
        draft.invalidate(ifChangedTo: french)
        XCTAssertFalse(draft.replaceText(with: "12.5", in: french))
        XCTAssertNil(draft.target(in: french))
        XCTAssertTrue(draft.replaceText(with: "12,5", in: french))
        XCTAssertEqual(draft.target(in: french), 12.5)
        XCTAssertNil(draft.target(in: english))
    }

    func testLocaleRoundTripDoesNotReviveAnInvalidatedDraft() {
        var draft = LightTargetLuxDraft()
        draft.initialize(value: 250, in: english)
        draft.invalidate(ifChangedTo: french)
        draft.invalidate(ifChangedTo: english)
        XCTAssertEqual(draft.text, "250")
        XCTAssertTrue(draft.requiresLocaleEdit(in: english))
        XCTAssertNil(draft.target(in: english))
        XCTAssertFalse(draft.replaceText(with: "250", in: english))
        XCTAssertNil(draft.target(in: english))
        XCTAssertTrue(draft.replaceText(with: "251", in: english))
        XCTAssertEqual(draft.target(in: english), 251)
    }

    func testUnchangedContextAndTextKeepTheSameAcceptedInterpretation() {
        var draft = LightTargetLuxDraft()
        draft.initialize(value: 12.5, in: english)
        draft.invalidate(ifChangedTo: english)
        XCTAssertFalse(draft.replaceText(with: "12.5", in: english))
        XCTAssertFalse(draft.requiresLocaleEdit(in: english))
        XCTAssertEqual(draft.target(in: english), 12.5)
        XCTAssertEqual(english.identifier, "en_US")
        XCTAssertEqual(english.decimalSeparator, ".")
        XCTAssertEqual(french.decimalSeparator, ",")
    }

    func testLocaleIdentifierChangeIsGuardedEvenWhenTheSeparatorMatches() {
        let british = LightTargetLuxDraft.LocaleContext(locale: Locale(identifier: "en_GB"))
        XCTAssertEqual(english.decimalSeparator, british.decimalSeparator)
        var draft = LightTargetLuxDraft()
        draft.initialize(value: 12.5, in: english)
        XCTAssertNil(draft.target(in: british))
        XCTAssertTrue(draft.requiresLocaleEdit(in: british))
        XCTAssertFalse(draft.replaceText(with: "12.5", in: british))
        XCTAssertNil(draft.target(in: british))
    }

    func testInitializationUsesCapturedSeparatorAndDoesNotReseedAnExistingDraft() {
        var draft = LightTargetLuxDraft()
        XCTAssertNil(draft.target(in: french))
        draft.initialize(value: 12.5, in: french)
        XCTAssertEqual(draft.text, "12,5")
        XCTAssertEqual(draft.target(in: french), 12.5)
        draft.initialize(value: 100, in: english)
        XCTAssertEqual(draft.text, "12,5")
        XCTAssertNil(draft.target(in: english))
        XCTAssertTrue(draft.replaceText(with: "", in: french))
        draft.initialize(value: 100, in: french)
        XCTAssertEqual(draft.text, "")
        XCTAssertNil(draft.target(in: french))
    }

    func testOversizeRejectionSurvivesLocaleChangeAndUnchangedTextEchoes() {
        var draft = LightTargetLuxDraft()
        draft.initialize(value: 250, in: english)
        let oversized = String(repeating: "1", count: StudioNumericInput.maximumDraftUTF8Bytes + 1)
        XCTAssertFalse(draft.replaceText(with: oversized, in: english))
        XCTAssertEqual(draft.text, "250")
        XCTAssertTrue(draft.rejectedOversizedDraft)
        XCTAssertFalse(draft.replaceText(with: "250", in: english))
        XCTAssertTrue(draft.rejectedOversizedDraft)

        draft.invalidate(ifChangedTo: french)
        XCTAssertFalse(draft.replaceText(with: oversized, in: french))
        XCTAssertFalse(draft.replaceText(with: "250", in: french))
        XCTAssertTrue(draft.rejectedOversizedDraft)
        XCTAssertTrue(draft.requiresLocaleEdit(in: french))
        XCTAssertNil(draft.target(in: french))
        XCTAssertEqual(draft.text, "250")

        XCTAssertTrue(draft.replaceText(with: "250,5", in: french))
        XCTAssertFalse(draft.rejectedOversizedDraft)
        XCTAssertFalse(draft.requiresLocaleEdit(in: french))
        XCTAssertEqual(draft.target(in: french), 250.5)
    }

    func testRawByteAndDecimalGrammarBoundsRemainIndependentOfDraftAdmission() {
        var draft = LightTargetLuxDraft()
        draft.initialize(value: nil, in: english)
        XCTAssertTrue(draft.replaceText(with: String(repeating: " ", count: 95) + "1", in: english))
        XCTAssertEqual(draft.target(in: english), 1)
        XCTAssertTrue(draft.replaceText(with: String(repeating: " ", count: 96) + "1", in: english))
        XCTAssertNil(draft.target(in: english), "The target field retains its 96-byte raw bound")
        XCTAssertTrue(draft.replaceText(with: String(repeating: "1", count: 33), in: english))
        XCTAssertNil(draft.target(in: english), "Draft admission does not weaken the 32-character parser")
        XCTAssertFalse(draft.replaceText(with: "1" + String(repeating: "\u{301}", count: 10_000), in: english))
        XCTAssertEqual(draft.text, String(repeating: "1", count: 33))
        XCTAssertTrue(draft.rejectedOversizedDraft)
    }

    func testWrongGroupingAndNegativeTargetsRemainRejectedInTheirCapturedLocale() {
        for (context, rejected) in [(english, ["1,000", "-1", "1e3"]),
                                    (french, ["1.000", "1\u{202F}000", "-1", "1e3"])] {
            var draft = LightTargetLuxDraft()
            draft.initialize(value: nil, in: context)
            for text in rejected {
                XCTAssertTrue(draft.replaceText(with: text, in: context))
                XCTAssertNil(draft.target(in: context), text)
            }
            XCTAssertTrue(draft.replaceText(with: "0", in: context))
            XCTAssertEqual(draft.target(in: context), 0)
        }
    }
}
