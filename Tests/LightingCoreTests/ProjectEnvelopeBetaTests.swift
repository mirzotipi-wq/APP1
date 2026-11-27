import Foundation
import XCTest
@testable import LightingCore

final class ProjectEnvelopeBetaTests: XCTestCase {
    private let scene = #"{"schemaVersion":5,"subject":{"x":0,"y":1.5,"z":0},"camera":{"x":0,"y":1.5,"z":3},"lights":[]}"#

    private func wire(metadata: String) -> Data {
        let body = String(scene.dropLast()) + #", "metadata":"# + metadata + "}"
        return Data((#"{"schemaVersion":1,"name":"Imported","scene":"# + body + "}").utf8)
    }

    func testMalformedIgnoredNumberGrammarCannotImport() {
        // Foundation can defer numeric conversion for ignored scene metadata.
        // These tokens must fail the JSON boundary even though no Double or Int
        // property asks the decoder to interpret them.
        for token in ["-", "--1", "00", "01", "-01", "1.", "-0.",
                      "1e", "1e+", "1e-", "1E", "1E+", "1E-", "1.e2",
                      "1e+-2", "1e--2", "0x1", "+1", ".1"] {
            for metadata in [token, #"{"value":"# + token + "}",
                             "[0," + token + ",2]", #"[{"nested":["# + token + "]}]"] {
                XCTAssertThrowsError(try LightingProjectDocument.decode(wire(metadata: metadata)), metadata) {
                    XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
                }
            }
        }
    }

    func testCompleteIgnoredNumbersRetainGrammarWithoutArtificialMagnitudeLimits() throws {
        let expected = try LightingProjectDocument.decode(wire(metadata: "null"))
        let tokens = ["0", "-0", "10", "-10", "0.0", "-0.125", "1e0", "1E+0",
                      "1e-9999", "-1e9999", "1e9999", "1.00e+0",
                      String(repeating: "9", count: 1_024)]
        for token in tokens {
            for metadata in [token, #"{"value":"# + token + "}",
                             "[" + token + ",0]", "[0," + token + "]",
                             "[ \n\t" + token + "\r\n ]"] {
                XCTAssertEqual(try LightingProjectDocument.decode(wire(metadata: metadata)), expected, metadata)
            }
        }
    }

    func testNumberLikeStringsAndEscapedDigitsRemainOrdinaryMetadata() throws {
        let expected = try LightingProjectDocument.decode(wire(metadata: "null"))
        let metadata = #"{"1e":"--1","01":["1.","-","1e+","\u0031e-",{"\u0030x1":"0x1"}]}"#
        XCTAssertEqual(try LightingProjectDocument.decode(wire(metadata: metadata)), expected)
    }

    func testNumberValidationCrossesSupportedUnicodeEncodings() throws {
        let valid = String(decoding: wire(metadata: #"[1e9999,{"value":-0.125e-99}]"#), as: UTF8.self)
        let invalid = String(decoding: wire(metadata: #"[0,{"value":1e+}]"#), as: UTF8.self)
        let expected = try LightingProjectDocument.decode(Data(valid.utf8))
        for encoding: String.Encoding in [.utf8, .utf16BigEndian, .utf16LittleEndian,
                                           .utf32BigEndian, .utf32LittleEndian] {
            XCTAssertEqual(try LightingProjectDocument.decode(XCTUnwrap(valid.data(using: encoding))), expected)
            XCTAssertThrowsError(try LightingProjectDocument.decode(XCTUnwrap(invalid.data(using: encoding)))) {
                XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
            }
        }
    }

    func testInvalidNumericSuffixesAndIncompleteLiteralsCannotBecomePadding() {
        for token in ["1false", "1null", "1true", "1x", "1_0", "1 2", "false1", "null1", "true1"] {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(metadata: token)), token) {
                XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
            }
        }
    }
}
