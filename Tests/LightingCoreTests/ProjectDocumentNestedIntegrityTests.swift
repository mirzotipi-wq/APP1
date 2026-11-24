import Foundation
import XCTest
@testable import LightingCore

final class ProjectDocumentNestedIntegrityTests: XCTestCase {
    private let scene = #"{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},"camera":{"x":0,"y":1.5,"z":3},"cameraLens":{"focalLengthMillimeters":50},"lights":[{"id":"00000000-0000-4000-8000-000000000001","name":"Key","position":{"x":-1.5,"y":2.1,"z":1.2},"candela":900,"kelvin":5600,"optics":{"kind":"rectangle","widthMeters":0.6,"heightMeters":0.9,"aimTarget":{"x":0,"y":1.5,"z":0}}}],"previewSettings":{"whiteBalanceKelvin":5600,"exposureStops":0}}"#

    private func wire(_ scene: String) -> Data {
        Data((#"{"schemaVersion":1,"name":"Imported","scene":"# + scene + "}").utf8)
    }

    private func withMetadata(_ metadata: String) -> String {
        String(scene.dropLast()) + #", "metadata":"# + metadata + "}"
    }

    func testAmbiguousSceneLightPositionAndOpticsFieldsCannotImport() {
        let variants = [
            (#""schemaVersion":4"#, #""schemaVersion":4,"schemaVersion":3"#),
            (#""x":0"#, #""x":0,"x":5"#),
            (#""name":"Key""#, #""name":"Key","name":"Fill""#),
            (#""candela":900"#, #""candela":900,"candela":200"#),
            (#""kind":"rectangle""#, #""kind":"rectangle","kind":"point""#),
            (#""widthMeters":0.6"#, #""widthMeters":0.6,"widthMeters":1.2"#),
            (#""focalLengthMillimeters":50"#, #""focalLengthMillimeters":50,"focalLengthMillimeters":85"#),
            (#""whiteBalanceKelvin":5600"#, #""whiteBalanceKelvin":5600,"whiteBalanceKelvin":6500"#)
        ]
        for (field, replacement) in variants {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(scene.replacingOccurrences(of: field, with: replacement))), field)
        }
    }

    func testEscapedEquivalentNestedKeysAndUnknownObjectsCannotHideDuplicates() {
        let variants = [
            (#""x":0"#, #""x":0,"\u0078":5"#),
            (#""name":"Key""#, #""name":"Key","na\u006de":"Fill""#),
            (#""candela":900"#, #""candela":900,"\u0063andela":200"#),
            (#""widthMeters":0.6"#, #""widthMeters":0.6,"width\u004deters":1.2"#)
        ]
        for (field, replacement) in variants {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(scene.replacingOccurrences(of: field, with: replacement))), field)
        }
        for metadata in [#"{"value":1,"value":2}"#,
                         #"[{"value":1,"\u0076alue":2}]"#,
                         #"["name", [{"inside":{"name":"First","name":"Second"}}]]"#] {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(withMetadata(metadata))))
        }
    }

    func testSiblingObjectsArraysAndQuotedStructuralCharactersRemainValid() throws {
        let metadata = #"[{"name":"first","nested":[{"name":"child"},"name",[],{}]},{"name":"second","nested":{"name":"other","value":"quote: \"name\": [},] \\ slash"}},["name","name"],{"name":"third"}]"#
        let expected = try LightingProjectDocument.decode(wire(scene))
        XCTAssertEqual(try LightingProjectDocument.decode(wire(withMetadata(metadata))), expected)
        var multipleLights = LightingScene.portrait()
        for index in multipleLights.lights.indices {
            multipleLights.lights[index].name = #""name": ["nested", "]}"] \ "# + "\(index)"
            multipleLights.lights[index].optics = .init(kind: .rectangle, aimTarget: .init(x: 0, y: 1.5, z: 0))
        }
        let document = try LightingProjectDocument(name: "Repeated field names", scene: multipleLights)
        let canonical = try document.encode()
        XCTAssertEqual(try LightingProjectDocument.decode(canonical), document)
        XCTAssertEqual(try document.encode(), canonical)
    }

    func testDecodedKeyBytesPreserveUnicodeDistinctionAndEscapeEquivalence() throws {
        let expected = try LightingProjectDocument.decode(wire(scene))
        // JSON names compare decoded sequences, not Swift String's canonical
        // equivalence: these two names have different scalar sequences.
        let distinct = #"{"é":1,"e\u0301":2,"💡":3,"💡\uFE0F":4}"#
        XCTAssertEqual(try LightingProjectDocument.decode(wire(withMetadata(distinct))), expected)
        for duplicates in [#"{"é":1,"\u00E9":2}"#,
                           #"{"💡":1,"\uD83D\uDCA1":2}"#,
                           #"{"\\":1,"\u005C":2}"#,
                           #"{"\"":1,"\u0022":2}"#] {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(withMetadata(duplicates))))
        }
    }

    func testNestedDuplicatesAreRejectedAcrossSupportedUnicodeEncodings() throws {
        let expected = try LightingProjectDocument.decode(wire(scene))
        let unique = String(decoding: wire(withMetadata(#"{"value":1}"#)), as: UTF8.self)
        let duplicate = String(decoding: wire(withMetadata(#"{"value":1,"\u0076alue":2}"#)), as: UTF8.self)
        for encoding: String.Encoding in [.utf8, .utf16, .utf16BigEndian, .utf16LittleEndian,
                                           .utf32BigEndian, .utf32LittleEndian] {
            XCTAssertEqual(try LightingProjectDocument.decode(XCTUnwrap(unique.data(using: encoding))), expected)
            XCTAssertThrowsError(try LightingProjectDocument.decode(XCTUnwrap(duplicate.data(using: encoding))),
                                 "encoding \(encoding.rawValue)")
        }
    }

    func testIterativeStateHandlesDeepAndWideUnknownObjects() throws {
        let expected = try LightingProjectDocument.decode(wire(scene))
        func nested(_ leaf: String) -> String {
            (0..<64).reduce(leaf) { value, index in index.isMultiple(of: 2) ? "[" + value + "]" : #"{"value":"# + value + "}" }
        }
        XCTAssertEqual(try LightingProjectDocument.decode(wire(withMetadata(nested(#"{"name":"leaf"}"#)))), expected)
        XCTAssertThrowsError(try LightingProjectDocument.decode(wire(withMetadata(nested(#"{"name":"leaf","name":"other"}"#)))))

        let members = (0..<5_000).map { #""field"# + "\($0)" + #"":0"# }.joined(separator: ",")
        XCTAssertEqual(try LightingProjectDocument.decode(wire(withMetadata("{" + members + "}"))), expected)
        XCTAssertThrowsError(try LightingProjectDocument.decode(wire(withMetadata("{" + members + #", "field4999":1}"#))))
    }
}
