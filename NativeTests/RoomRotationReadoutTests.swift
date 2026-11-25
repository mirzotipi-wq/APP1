import Foundation
import XCTest
import LightingCore
@testable import KeyAndFill

final class RoomRotationReadoutTests: XCTestCase {
    func testFractionalYawReadoutsPreservePositiveAndNegativePrecision() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        for (value, expected) in [(12.75, "12.75"), (-12.75, "-12.75"),
                                  (73.12345678912345, "73.12345678912345"),
                                  (-1e-7, "-0.0000001")] {
            try assertReadout(value, expected: expected, locale: locale)
        }
    }

    func testLocalizedYawReadoutsUseExactFrenchAndArabicNumbers() throws {
        let french = Locale(identifier: "fr_FR")
        try assertReadout(12.75, expected: "12,75", locale: french)
        try assertReadout(-12.75, expected: "-12,75", locale: french)
        try assertReadout(-1e-7, expected: "-0,0000001", locale: french)
        let arabic = Locale(identifier: "ar_EG")
        try assertReadout(12.75, expected: "١٢٫٧٥", locale: arabic)
        try assertReadout(0.125, expected: "٠٫١٢٥", locale: arabic)
    }

    func testYawEndpointsAndSignedZeroReadoutsPreserveSourceBits() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        for (value, expected) in [(-360.0, "-360"), (-180.0, "-180"),
                                  (-0.0, "-0"), (0.0, "0"),
                                  (180.0, "180"), (360.0, "360")] {
            try assertReadout(value, expected: expected, locale: locale)
        }
    }

    private func assertReadout(_ value: Double, expected: String, locale: Locale,
                               file: StaticString = #filePath, line: UInt = #line) throws {
        let room = ManualRoom(yawDegrees: value)
        let originalBits = room.yawDegrees.bitPattern
        XCTAssertTrue(room.isValid, file: file, line: line)
        let readout = RoomRotationReadout(degrees: room.yawDegrees, locale: locale)
        XCTAssertEqual(readout.text, expected + "°", file: file, line: line)
        XCTAssertEqual(readout.accessibilityValue, expected + " degrees", file: file, line: line)

        // Parse both production strings independently of the formatter.
        for numericText in [String(readout.text.dropLast()),
                            String(readout.accessibilityValue.dropLast(" degrees".count))] {
            let parsed = try XCTUnwrap(StudioNumericInput.parse(numericText,
                decimalSeparator: locale.decimalSeparator ?? ".", in: -360...360),
                file: file, line: line)
            XCTAssertEqual(parsed.bitPattern, originalBits, file: file, line: line)
        }
        XCTAssertEqual(room.yawDegrees.bitPattern, originalBits, file: file, line: line)
    }
}
