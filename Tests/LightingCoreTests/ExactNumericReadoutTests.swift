import Foundation
import XCTest
@testable import LightingCore

final class ExactNumericReadoutTests: XCTestCase {
    func testAcceptedFineDecimalsRetainTheirActualReadout() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        for text in ["0.0000001", "-0.0000001", "1.23456789", "73.123456789"] {
            let value = try XCTUnwrap(StudioNumericInput.parse(text, in: -100...100))
            XCTAssertEqual(StudioNumericInput.formattedValue(value, unit: "m", locale: locale), text + " m")
        }
    }

    func testLocalizedDigitsRetainExactFiniteValuesAndSignedZero() throws {
        for identifier in ["en_US", "fr_FR", "fa_IR", "ar_EG"] {
            let locale = Locale(identifier: identifier)
            for value in [0.0, -0.0, 1e-7, -1e-7, 1.23456789, -73.123456789,
                          Double.leastNonzeroMagnitude, -Double.leastNonzeroMagnitude,
                          Double.greatestFiniteMagnitude] {
                let display = StudioNumericInput.formattedValue(value, locale: locale)
                let canonical = canonicalNumber(display, decimalSeparator: locale.decimalSeparator ?? ".")
                let parsed = try XCTUnwrap(Double(canonical), "\(identifier): \(display)")
                XCTAssertEqual(parsed.bitPattern, value.bitPattern, "\(identifier): \(display)")
                XCTAssertLessThanOrEqual(display.count, 40, "Bound the numeric label, including localized sign controls")
            }
        }
        XCTAssertTrue(StudioNumericInput.formattedValue(1e-7, locale: Locale(identifier: "fr_FR")).contains(","))
        XCTAssertTrue(StudioNumericInput.formattedValue(1e-7, locale: Locale(identifier: "ar_EG")).contains("١"))
    }

    func testExtremeFiniteReadoutsUseBoundedRoundTripNotation() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        for value in [Double.leastNonzeroMagnitude, -Double.leastNonzeroMagnitude,
                      Double.leastNormalMagnitude, -1e-100, 1e100,
                      Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude] {
            let display = StudioNumericInput.formattedValue(value, locale: locale)
            XCTAssertTrue(display.contains("e"), display)
            XCTAssertLessThanOrEqual(display.count, 32)
            XCTAssertEqual(try XCTUnwrap(Double(display)).bitPattern, value.bitPattern)
            XCTAssertNotEqual(display, "0")
            XCTAssertNotEqual(display, "-0")
        }
    }

    func testDeterministicFiniteBitPatternsRoundTripWithoutMutatingScene() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        var bits: UInt64 = 0x93f2_a4c5_b678_d10e
        for _ in 0..<512 {
            bits = bits &* 6364136223846793005 &+ 1442695040888963407
            let value = Double(bitPattern: bits)
            guard value.isFinite else { continue }
            let text = StudioNumericInput.formattedValue(value, locale: locale)
            XCTAssertLessThanOrEqual(text.count, 32)
            XCTAssertEqual(try XCTUnwrap(Double(text)).bitPattern, value.bitPattern)
        }
        var scene = LightingScene.portrait()
        scene.camera.x = -1e-7
        let before = try SceneCodec.encode(scene)
        _ = StudioNumericInput.formattedValue(scene.camera.x, unit: "m", locale: locale)
        XCTAssertEqual(try SceneCodec.encode(scene), before)
    }

    func testExactDecimalDraftsKeepParserBoundsAndLocale() throws {
        for separator in [".", ",", "٫"] {
            for value in [0.0, -0.0, 1e-7, -1e-7, 1.2345678901234567, 1e-29, -1e-29,
                          -1.2345678901234567e-14, 1e30] {
                let text = try XCTUnwrap(StudioNumericInput.editableText(value, decimalSeparator: separator))
                XCTAssertLessThanOrEqual(text.count, 32)
                XCTAssertFalse(text.contains("e"))
                let result = try XCTUnwrap(StudioNumericInput.parse(text, decimalSeparator: separator,
                    in: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude))
                XCTAssertEqual(result.bitPattern, value.bitPattern)
            }
        }
        XCTAssertTrue(try XCTUnwrap(StudioNumericInput.editableText(-1.2345678901234567e-14)).hasPrefix("-."))
    }

    func testUnrepresentableDraftIsExplicitWithoutBroadeningInputGrammar() {
        for value in [Double.leastNonzeroMagnitude, -Double.leastNonzeroMagnitude,
                      1e-100, Double.greatestFiniteMagnitude] {
            XCTAssertNil(StudioNumericInput.editableText(value))
        }
        XCTAssertNil(StudioNumericInput.editableText(.nan))
        XCTAssertNil(StudioNumericInput.editableText(.infinity))
        for text in ["1e-7", "-5e-324", "1,000", String(repeating: "0", count: 33)] {
            XCTAssertNil(StudioNumericInput.parse(text, in: -100_000...100_000))
        }
    }

    private func canonicalNumber(_ text: String, decimalSeparator: String) -> String {
        var result = ""
        for character in text {
            if String(character) == decimalSeparator { result.append(".") }
            else if character == "−" { result.append("-") }
            else if let digit = character.wholeNumberValue, (0...9).contains(digit) { result.append(String(digit)) }
            else if character.unicodeScalars.allSatisfy({ CharacterSet.controlCharacters.contains($0) }) { continue }
            else { result.append(character) }
        }
        return result
    }
}
