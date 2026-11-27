import Foundation
import XCTest
@testable import LightingCore

final class ProjectDocumentIgnoredUnicodeTests: XCTestCase {
    private let scene = #"{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},"camera":{"x":0,"y":1.5,"z":3},"lights":[]}"#
    private let marker = "__UNICODE_VALUE__"

    private func wire(metadata: String? = nil, name: String = #""Imported""#) -> Data {
        let sceneJSON = metadata.map { String(scene.dropLast()) + #", "metadata":"# + $0 + "}" } ?? scene
        return Data((#"{"schemaVersion":1,"name":"# + name + #", "scene":"# + sceneJSON + "}").utf8)
    }

    private func replacingMarker(in data: Data, with bytes: [UInt8]) throws -> Data {
        var result = data
        let range = try XCTUnwrap(result.range(of: Data(marker.utf8)))
        result.replaceSubrange(range, with: bytes)
        return result
    }

    private func assertInvalidDocument(_ data: Data, _ context: String,
                                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try LightingProjectDocument.decode(data), context, file: file, line: line) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument,
                           context, file: file, line: line)
        }
    }

    func testMalformedUTF8IsRejectedInConsumedAndIgnoredStrings() throws {
        let malformed: [[UInt8]] = [
            [0xc3, 0x28], // Invalid continuation.
            [0x80], // Continuation without a leading byte.
            [0xc0, 0xaf], // Overlong ASCII encoding.
            [0xed, 0xa0, 0x80], // UTF-8 cannot encode a surrogate.
            [0xf4, 0x90, 0x80, 0x80], // Above U+10FFFF.
            [0xf0, 0x9f, 0x92] // Truncated scalar before the closing quote.
        ]
        let locations = [
            wire(name: "\"" + marker + "\""),
            wire(metadata: "\"" + marker + "\""),
            wire(metadata: #"{"nested":{"value":"__UNICODE_VALUE__"}}"#),
            wire(metadata: #"[0,["before","__UNICODE_VALUE__","after"]]"#),
            wire(metadata: #"[{"nested":[{"value":"__UNICODE_VALUE__"}]}]"#)
        ]
        for (index, bytes) in malformed.enumerated() {
            for (location, data) in locations.enumerated() {
                assertInvalidDocument(try replacingMarker(in: data, with: bytes),
                                      "Malformed UTF-8 variant \(index), location \(location)")
            }
        }
    }

    func testUnpairedEscapedSurrogatesAreRejectedInIgnoredObjectsAndArrays() {
        for value in [#""\uD800""#, #""\uDC00""#, #""\uD800A""#,
                      #""\uD800\u0041""#, #""\uD800\uD800""#,
                      #""\uDC00\uD800""#] {
            assertInvalidDocument(wire(name: value), "Consumed name: \(value)")
            for metadata in [value, #"{"nested":{"value":"# + value + "}}",
                             #"["before",["# + value + #"],{"after":true}]"#] {
                assertInvalidDocument(wire(metadata: metadata), "Ignored metadata: \(metadata)")
            }
        }
    }

    func testValidUnicodeAndEscapesInIgnoredMetadataRemainAccepted() throws {
        let expected = try LightingProjectDocument.decode(wire())
        let metadata = #"{"é":"e\u0301","e\u0301":"é","nested":["💡","\uD83D\uDCA1","\uDBFF\uDFFF","\u0000\b\f\n\r\t","quote: \" } ] , \\ \/",{"value":"\uFFFD"}]}"#
        XCTAssertEqual(try LightingProjectDocument.decode(wire(metadata: metadata)), expected)
        XCTAssertEqual(try LightingProjectDocument.decode(Data([0xef, 0xbb, 0xbf]) + wire(metadata: metadata)), expected)
    }

    func testIgnoredUnicodeValidationPreservesSupportedUTF16AndUTF32Inputs() throws {
        let expected = try LightingProjectDocument.decode(wire())
        let valid = String(decoding: wire(metadata: #"{"nested":["💡","\uD83D\uDCA1","\u0000",{"é":"e\u0301"}]}"#), as: UTF8.self)
        let invalid = String(decoding: wire(metadata: #"{"nested":[{"value":"\uD800"}]}"#), as: UTF8.self)
        for encoding: String.Encoding in [.utf16, .utf16BigEndian, .utf16LittleEndian,
                                           .utf32, .utf32BigEndian, .utf32LittleEndian] {
            let validData = try XCTUnwrap(valid.data(using: encoding))
            struct FoundationEnvelope: Decodable {
                let schemaVersion: Int
                let name: String
                let scene: LightingScene
            }
            // Keep Foundation's supported input encodings without introducing
            // a promise for BOM variants the current platform cannot decode.
            if (try? JSONDecoder().decode(FoundationEnvelope.self, from: validData)) != nil {
                XCTAssertEqual(try LightingProjectDocument.decode(validData), expected,
                               "Encoding \(encoding.rawValue)")
            } else {
                assertInvalidDocument(validData, "Unsupported encoding \(encoding.rawValue)")
            }
            assertInvalidDocument(try XCTUnwrap(invalid.data(using: encoding)),
                                  "Unpaired surrogate, encoding \(encoding.rawValue)")
        }
    }
}
