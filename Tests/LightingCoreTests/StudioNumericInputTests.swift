import XCTest
@testable import LightingCore

final class StudioNumericInputTests: XCTestCase {
    func testSignedExactValuesDoNotSnapToSliderSteps() {
        XCTAssertEqual(StudioNumericInput.parse("-1.237", in: -100...100), -1.237)
        XCTAssertEqual(StudioNumericInput.parse("+4321.5", in: 0...100_000), 4321.5)
        XCTAssertEqual(StudioNumericInput.parse("  .125  ", in: 0...1), 0.125)
        XCTAssertEqual(StudioNumericInput.parse("−0.75", in: -6...6), -0.75)
    }

    func testLocaleDecimalSeparatorsAndDecimalDigits() {
        XCTAssertEqual(StudioNumericInput.parse("-1,25", decimalSeparator: ",", in: -4...4), -1.25)
        XCTAssertEqual(StudioNumericInput.parse("١٢٫٥", decimalSeparator: "٫", in: 0...100), 12.5)
        XCTAssertEqual(StudioNumericInput.parse("۱۲,۵", decimalSeparator: ",", in: 0...100), 12.5)
        XCTAssertNil(StudioNumericInput.parse("1.25", decimalSeparator: ",", in: 0...4))
    }

    func testMalformedAndNonfiniteInputRejected() {
        for input in ["", " ", "+", "-", ".", "-.", "NaN", "inf", "1e2", "0x1", "1 000", "1,000", "1.2.3", "--1", "1-", "²", "Ⅲ", "1\n2", String(repeating: "0", count: 33)] {
            XCTAssertNil(StudioNumericInput.parse(input, in: -100_000...100_000), input)
        }
        XCTAssertNil(StudioNumericInput.parse("1,2,3", decimalSeparator: ",", in: 0...100))
    }

    func testDomainBoundariesAreRejectedNotClamped() {
        XCTAssertEqual(StudioNumericInput.parse("100000", in: 0...100_000), 100_000)
        XCTAssertNil(StudioNumericInput.parse("100000.01", in: 0...100_000))
        XCTAssertNil(StudioNumericInput.parse("-0.01", in: 0...100_000))
        XCTAssertEqual(StudioNumericInput.parse("1000", in: 1000...20_000), 1000)
        XCTAssertNil(StudioNumericInput.parse("999", in: 1000...20_000))
        XCTAssertNil(StudioNumericInput.parse("-100.001", in: -100...100))
    }

    func testSliderBoundsPreserveValidImportedValues() {
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 0...3000, current: 4321.5), 0...4321.5)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 0...4, current: -0.5), -0.5...4)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: -4...4, current: 1.237), -4...4)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 2000...9000, current: 1000), 1000...9000)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 0...1, current: .nan), 0...1)
    }
}
