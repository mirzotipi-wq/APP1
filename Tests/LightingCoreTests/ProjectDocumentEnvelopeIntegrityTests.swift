import Foundation
import XCTest
@testable import LightingCore

final class ProjectDocumentEnvelopeIntegrityTests: XCTestCase {
    private let scene = #"{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},"camera":{"x":0,"y":1.5,"z":3},"lights":[]}"#

    private func wire(_ members: String) -> Data { Data(("{" + members + "}").utf8) }

    func testDuplicateEnvelopeValuesAreRejectedInEitherOrder() {
        let pairs = [
            #""schemaVersion":1,"schemaVersion":2,"name":"Copy","scene":"# + scene,
            #""schemaVersion":2,"schemaVersion":1,"name":"Copy","scene":"# + scene,
            #""schemaVersion":1,"name":"First","name":"Last","scene":"# + scene,
            #""schemaVersion":1,"name":"Last","name":"First","scene":"# + scene,
            #""schemaVersion":1,"name":"Copy","scene":"# + scene + #", "scene":"# + scene,
            #""schemaVersion":1,"name":"Copy","scene":"# + scene + #", "schemaVersion":1"#
        ]
        for members in pairs {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(members)), members)
        }
    }

    func testEscapedEquivalentKeysCannotHideDuplicates() {
        let pairs = [
            #""schemaVersion":1,"\u0073chemaVersion":1,"name":"Copy","scene":"# + scene,
            #""schemaVersion":1,"name":"First","\u006eame":"Last","scene":"# + scene,
            #""schemaVersion":1,"\u006E\u0061\u006D\u0065":"First","name":"Last","scene":"# + scene,
            #""schemaVersion":1,"name":"Copy","scene":"# + scene + #", "sc\u0065ne":"# + scene
        ]
        for members in pairs {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(members)), members)
        }
    }

    func testEscapedUniqueKeysAndStructuralCharactersInValuesStayReadable() throws {
        let original = #"copy: "name", [brackets] {braces} \\ slash / 💡"#
        let name = String(decoding: try JSONEncoder().encode(original), as: UTF8.self)
        let data = wire(#""sc\u0068emaVersion":1.0,"\u006Eame":"# + name + #", "scen\u0065":"# + scene)
        let document = try LightingProjectDocument.decode(data)
        XCTAssertEqual(document.name, original)
        XCTAssertEqual(document.scene.lights.count, 0)
        XCTAssertEqual(try LightingProjectDocument.decode(document.encode()), document)

        var nested = LightingScene.portrait()
        nested.lights[0].name = #""scene":{}, "name": ["schemaVersion", "]}"]"#
        let expected = try LightingProjectDocument(name: original, scene: nested)
        let canonical = try expected.encode()
        XCTAssertEqual(try LightingProjectDocument.decode(canonical), expected)
        XCTAssertEqual(try expected.encode(), canonical)
    }

    func testExistingUnicodeEncodingsKeepUniqueKeysAndRejectDuplicateKeys() throws {
        let unique = " \r\n" + String(decoding: wire(#""schemaVersion":1,"name":"Portrait 💡","scene":"# + scene), as: UTF8.self)
        let duplicate = " \r\n" + String(decoding: wire(#""schemaVersion":1,"name":"Portrait 💡","\u006eame":"Second","scene":"# + scene), as: UTF8.self)
        let expected = try LightingProjectDocument.decode(Data(unique.utf8))
        let encodings: [String.Encoding] = [.utf8, .utf16, .utf16BigEndian, .utf16LittleEndian,
                                             .utf32, .utf32BigEndian, .utf32LittleEndian]
        struct FoundationEnvelope: Decodable {
            let schemaVersion: Int
            let name: String
            let scene: LightingScene
        }
        for encoding in encodings {
            let encoded = try XCTUnwrap(unique.data(using: encoding))
            // Preserve the exact Foundation decoder's accepted valid encodings,
            // including its BOM handling. This test does not turn an unsupported
            // encoding into a new format promise.
            if (try? JSONDecoder().decode(FoundationEnvelope.self, from: encoded)) != nil {
                XCTAssertEqual(try LightingProjectDocument.decode(encoded), expected, "encoding \(encoding.rawValue)")
            } else {
                XCTAssertThrowsError(try LightingProjectDocument.decode(encoded), "encoding \(encoding.rawValue)")
            }
            XCTAssertThrowsError(try LightingProjectDocument.decode(XCTUnwrap(duplicate.data(using: encoding))),
                                 "encoding \(encoding.rawValue)")
        }
        let utf8BOM = Data([0xef, 0xbb, 0xbf]) + Data(unique.utf8)
        XCTAssertEqual(try LightingProjectDocument.decode(utf8BOM), expected)
        XCTAssertThrowsError(try LightingProjectDocument.decode(Data([0xef, 0xbb, 0xbf]) + Data(duplicate.utf8)))
    }

    func testLargeValidNameAndBoundaryWhitespaceDoNotProduceFalseKeys() throws {
        let name = "Portrait" + String(repeating: "\u{0301}", count: 250_000)
        let expected = try LightingProjectDocument(name: name, scene: .portrait())
        var data = try expected.encode()
        data.append(Data(repeating: 32, count: LightingProjectDocument.maximumBytes - data.count))
        XCTAssertEqual(data.count, LightingProjectDocument.maximumBytes)
        let actual = try LightingProjectDocument.decode(data)
        XCTAssertTrue(actual == expected, "A large valid legacy name must remain intact")
        data.append(32)
        XCTAssertThrowsError(try LightingProjectDocument.decode(data)) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .tooLarge)
        }
    }
}
