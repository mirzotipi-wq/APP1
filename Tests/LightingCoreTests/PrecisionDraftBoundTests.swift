import XCTest
@testable import LightingCore

final class PrecisionDraftBoundTests: XCTestCase {
    func testRawByteBoundaryPreservesExistingPaddedDecimalAllowance() throws {
        let limit = StudioNumericInput.maximumDraftUTF8Bytes
        XCTAssertEqual(limit, 256)
        let boundary = String(repeating: " ", count: limit - 4) + "1.25"
        XCTAssertEqual(boundary.utf8.count, limit)
        XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(boundary))
        XCTAssertEqual(try XCTUnwrap(StudioNumericInput.parse(boundary, in: 0...2)), 1.25)

        let oversized = " " + boundary
        XCTAssertFalse(StudioNumericInput.isWithinDraftLimit(oversized))
        XCTAssertNil(StudioNumericInput.parse(oversized, in: 0...2))
    }

    func testLocalizedDigitsUseUTF8BytesRatherThanCharacterCount() throws {
        for draft in ["١٢٫٥", "−۱۲,۵", "+１２.５", "\u{1D7D9}\u{1D7DA}.\u{1D7DD}"] {
            XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(draft), draft)
        }
        XCTAssertEqual(try XCTUnwrap(StudioNumericInput.parse("١٢٫٥", decimalSeparator: "٫", in: 0...20)), 12.5)
        XCTAssertEqual(try XCTUnwrap(StudioNumericInput.parse("−۱۲,۵", decimalSeparator: ",", in: -20...0)), -12.5)

        let boundary = String(repeating: "١", count: 128)
        XCTAssertEqual(boundary.utf8.count, 256)
        XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(boundary))
        XCTAssertFalse(StudioNumericInput.isWithinDraftLimit(boundary + "١"))
        // Draft admission does not expand the parser's numeric-length grammar.
        XCTAssertNil(StudioNumericInput.parse(boundary, in: 0...100))
    }

    func testCombiningScalarPasteCannotBypassByteLimitAsOneCharacter() {
        let boundary = "12" + String(repeating: "\u{0301}", count: 127)
        XCTAssertEqual(boundary.utf8.count, 256)
        XCTAssertEqual(boundary.count, 2)
        XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(boundary))
        XCTAssertFalse(StudioNumericInput.isWithinDraftLimit(boundary + "\u{0301}"))

        let oversized = "1" + String(repeating: "\u{0301}", count: 100_000)
        XCTAssertFalse(StudioNumericInput.isWithinDraftLimit(oversized))
        XCTAssertNil(StudioNumericInput.parse(oversized, in: 0...100))
    }

    func testEmptyAndIntermediateEditsStayEditableWithoutRelaxingParsing() {
        for draft in ["", "-", "−", "+", ".", "-.", "−٫", "  ", "١٢٫", "12.5", "1.25"] {
            XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(draft), draft)
        }
        for incomplete in ["", "-", "−", "+", ".", "-.", "  "] {
            XCTAssertNil(StudioNumericInput.parse(incomplete, in: -100...100), incomplete)
        }
    }

    func testAllInitialEditableFormatsFitWithoutChangingTheirExactValue() throws {
        let values = [0.0, -0.0, 1e-7, -1e-7, 1.2345678901234567, 1e-29, -1e-29,
                      -1.2345678901234567e-14, 1e30]
        for separator in [".", ",", "٫", "\u{1F4A7}"] {
            for value in values {
                let draft = try XCTUnwrap(StudioNumericInput.editableText(value, decimalSeparator: separator))
                XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(draft), draft)
                let parsed = try XCTUnwrap(StudioNumericInput.parse(draft, decimalSeparator: separator,
                    in: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude))
                XCTAssertEqual(parsed.bitPattern, value.bitPattern, draft)
            }
        }
    }

    func testExistingParserLimitsStillApplyAfterBoundedDraftAdmission() {
        for draft in [String(repeating: "0", count: 33), "1e2", "1,000", "1.2.3", "NaN", "inf"] {
            XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(draft), draft)
            XCTAssertNil(StudioNumericInput.parse(draft, in: -100_000...100_000), draft)
        }
        // The existing 96-byte numeric-content cap is independent of the
        // 256-byte allowance for the full padded editing draft.
        let fourByteDigits = String(repeating: "\u{1D7D9}", count: 25)
        XCTAssertTrue(StudioNumericInput.isWithinDraftLimit(fourByteDigits))
        XCTAssertNil(StudioNumericInput.parse(fourByteDigits, in: 0...Double.greatestFiniteMagnitude))
    }
}
