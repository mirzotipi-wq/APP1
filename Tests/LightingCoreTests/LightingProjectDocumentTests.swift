import Foundation
import XCTest
@testable import LightingCore

final class LightingProjectDocumentTests: XCTestCase {
    private func payload(_ edit: (inout [String: Any]) throws -> Void) throws -> Data {
        let document = try LightingProjectDocument(name: "Portrait", scene: .portrait())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: document.encode()) as? [String: Any])
        try edit(&object)
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func testEditableRoundTripPreservesPreciseSettingsWithoutLibraryOrPhotoMetadata() throws {
        var scene = LightingScene.portrait()
        scene.cameraLens = .init(focalLengthMillimeters: 73.125)
        scene.camera.x = 0.004
        scene.lights[0].candela = 4321.5
        scene.lights[0].optics = .init(kind: .rectangle, widthMeters: 1.237, heightMeters: 0.875)
        scene.previewSettings = .init(whiteBalanceKelvin: 5600.125, exposureStops: -0.125)
        let document = try LightingProjectDocument(name: "  Location portrait  ", scene: scene)
        let data = try document.encode()
        XCTAssertEqual(try LightingProjectDocument.decode(data), document)
        XCTAssertEqual(document.name, "Location portrait")
        XCTAssertEqual(document.scene, scene)
        XCTAssertEqual(document.schemaVersion, 1)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["schemaVersion", "name", "scene"])
        XCTAssertNil(object["id"])
        XCTAssertNil(object["activeID"])
        XCTAssertNil(object["referencePhoto"])
        XCTAssertEqual(try document.encode(), data, "The same document has deterministic canonical JSON")
    }

    func testUnsupportedEnvelopeVersionsAreRejectedBeforeSceneInterpretation() throws {
        for version in [-1, 0, 2, 99] {
            let data = try payload { object in
                object["schemaVersion"] = version
                object["scene"] = "not a scene in this future format"
            }
            XCTAssertThrowsError(try LightingProjectDocument.decode(data)) {
                XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .unsupportedVersion)
            }
        }
    }

    func testMalformedMissingAndUnexpectedEnvelopeFieldsAreRejected() throws {
        for data in [Data(), Data("not JSON".utf8), Data("[]".utf8), Data("null".utf8)] {
            XCTAssertThrowsError(try LightingProjectDocument.decode(data)) {
                XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
            }
        }
        for key in ["schemaVersion", "name", "scene"] {
            let data = try payload { $0.removeValue(forKey: key) }
            XCTAssertThrowsError(try LightingProjectDocument.decode(data)) {
                XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
            }
        }
        for key in ["id", "activeID", "referencePhoto", "unexpected"] {
            let data = try payload { $0[key] = "discarding this silently would hide an unsupported envelope" }
            XCTAssertThrowsError(try LightingProjectDocument.decode(data)) {
                XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
            }
        }
        let booleanVersion = try payload { $0["schemaVersion"] = true }
        XCTAssertThrowsError(try LightingProjectDocument.decode(booleanVersion)) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
        }
    }

    func testOversizedDataRejectedBeforeDecodeAndEncodedSizeIsBounded() throws {
        XCTAssertThrowsError(try LightingProjectDocument.decode(Data(repeating: 32, count: LightingProjectDocument.maximumBytes + 1))) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .tooLarge)
        }
        // One legal grapheme can contain many combining marks. Storage-compatible
        // names remain readable, but the serialized file still has a byte bound.
        let oversizedName = "A" + String(repeating: "\u{301}", count: LightingProjectDocument.maximumBytes / 2)
        let document = try LightingProjectDocument(name: oversizedName, scene: .portrait())
        XCTAssertThrowsError(try document.encode()) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .tooLarge)
        }
    }

    func testExactReadLimitAcceptsValidJSONButOneAdditionalByteDoesNot() throws {
        let document = try LightingProjectDocument(name: "Boundary", scene: .portrait())
        var data = try document.encode()
        data.append(Data(repeating: 32, count: LightingProjectDocument.maximumBytes - data.count))
        XCTAssertEqual(data.count, LightingProjectDocument.maximumBytes)
        XCTAssertEqual(try LightingProjectDocument.decode(data), document)
        data.append(32)
        XCTAssertThrowsError(try LightingProjectDocument.decode(data)) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .tooLarge)
        }
    }

    func testInvalidNamesScenesDuplicateLightsAndFutureSceneSchemasCannotImport() throws {
        XCTAssertThrowsError(try LightingProjectDocument(name: " ", scene: .portrait())) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidName)
        }
        var invalid = LightingScene.portrait()
        invalid.camera.x = .infinity
        XCTAssertThrowsError(try LightingProjectDocument(name: "Invalid", scene: invalid)) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidScene)
        }
        for variant in 0..<3 {
            let data = try payload { object in
                var scene = try XCTUnwrap(object["scene"] as? [String: Any])
                if variant == 0 {
                    var lights = try XCTUnwrap(scene["lights"] as? [[String: Any]])
                    lights.append(lights[0])
                    scene["lights"] = lights
                } else if variant == 1 {
                    scene["schemaVersion"] = LightingScene.currentSchemaVersion + 1
                } else {
                    scene["camera"] = ["x": 101, "y": 1.5, "z": 3]
                }
                object["scene"] = scene
            }
            XCTAssertThrowsError(try LightingProjectDocument.decode(data)) {
                XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidScene)
            }
        }
    }

    func testOlderSceneMigratesAndLegacyNameRemainsComplete() throws {
        let legacyName = "A" + String(repeating: "\u{301}", count: 1000)
        let data = try payload { object in
            object["name"] = legacyName
            var scene = try XCTUnwrap(object["scene"] as? [String: Any])
            scene["schemaVersion"] = 1
            scene.removeValue(forKey: "cameraLens")
            scene.removeValue(forKey: "previewSettings")
            object["scene"] = scene
        }
        let imported = try LightingProjectDocument.decode(data)
        XCTAssertEqual(imported.scene.schemaVersion, LightingScene.currentSchemaVersion)
        XCTAssertEqual(imported.name, legacyName)
        XCTAssertEqual(try LightingProjectDocument.decode(imported.encode()), imported)
        var library = try ProjectLibrary(name: "Existing", scene: .portrait())
        let existingID = library.activeID
        try library.create(name: imported.name, scene: imported.scene)
        XCTAssertNotEqual(library.activeID, existingID)
        XCTAssertEqual(library.projects.count, 2)
        XCTAssertEqual(library.activeProject?.scene, imported.scene)
    }
}
