import Foundation
import XCTest
@testable import LightingCore

final class StudioAccessibleValueTests: XCTestCase {
    func testCurrentReadoutsPreservePrecisionBeyondSliderIncrements() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(StudioNumericInput.formattedValue(73.125, unit: "mm", locale: locale), "73.125 mm")
        XCTAssertEqual(StudioNumericInput.formattedValue(0.004, unit: "m", locale: locale), "0.004 m")
        XCTAssertEqual(StudioNumericInput.formattedValue(1.237, unit: "m", locale: locale), "1.237 m")
        XCTAssertEqual(StudioNumericInput.formattedValue(5600.125, unit: "K", locale: locale), "5600.125 K")
        XCTAssertEqual(StudioNumericInput.formattedValue(-0.125, unit: "stops", locale: locale), "-0.125 stops")
        XCTAssertEqual(StudioNumericInput.formattedValue(100_000, unit: "cd", locale: locale), "100000 cd")
    }

    func testFrenchDecimalSeparatorAndUngroupedLargeValue() {
        let locale = Locale(identifier: "fr_FR")
        XCTAssertEqual(StudioNumericInput.formattedValue(73.125, unit: "mm", locale: locale), "73,125 mm")
        XCTAssertEqual(StudioNumericInput.formattedValue(0.004, unit: "m", locale: locale), "0,004 m")
        XCTAssertEqual(StudioNumericInput.formattedValue(5600.125, unit: "K", locale: locale), "5600,125 K")
    }

    func testLocalizedReadoutsRetainTheSameNumericValue() throws {
        for identifier in ["en_US", "fr_FR", "fa_IR", "ar_EG"] {
            let locale = Locale(identifier: identifier)
            for value in [0.004, 73.125, 5600.125, -0.125, 100_000] {
                let formatted = StudioNumericInput.formattedValue(value, locale: locale)
                // ICU may include directional controls around localized signs.
                // Ignore only these presentation marks, not separators/digits.
                let scalars = formatted.unicodeScalars.filter {
                    !CharacterSet.controlCharacters.contains($0)
                }
                let decimal = String(String.UnicodeScalarView(scalars))
                let parsed = try XCTUnwrap(StudioNumericInput.parse(decimal,
                    decimalSeparator: locale.decimalSeparator ?? ".", in: -100_000...100_000),
                    "Unparseable numeric readout in \(identifier): \(formatted)")
                XCTAssertEqual(parsed, value, accuracy: 1e-9, identifier)
                XCTAssertEqual(StudioNumericInput.formattedValue(value, unit: "m", locale: locale),
                               formatted + " m")
            }
        }
    }

    func testFormattingDoesNotMutateStoredValuesOrAddGrouping() {
        let locale = Locale(identifier: "en_US_POSIX")
        let original = 73.123456789
        var scene = LightingScene.portrait()
        scene.cameraLens = .init(focalLengthMillimeters: original)
        XCTAssertEqual(StudioNumericInput.formattedValue(original, unit: "mm", locale: locale), "73.123456789 mm")
        XCTAssertEqual(scene.effectiveCameraLens.focalLengthMillimeters, original)
        XCTAssertEqual(StudioNumericInput.formattedValue(50, locale: locale), "50")
        XCTAssertEqual(StudioNumericInput.formattedValue(20_000.125, locale: locale), "20000.125")
    }
}
