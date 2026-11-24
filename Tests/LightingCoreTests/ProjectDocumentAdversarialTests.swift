import Foundation
import XCTest
@testable import LightingCore

final class ProjectDocumentAdversarialTests: XCTestCase {
    private func sceneJSON(cameraX: String = "0") -> String {
        """
        {"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},
         "camera":{"x":\(cameraX),"y":1.5,"z":3},"lights":[]}
        """
    }

    private func wire(version: String = "1", name: String = "\"Imported\"",
                      cameraX: String = "0") -> Data {
        Data("{\"schemaVersion\":\(version),\"name\":\(name),\"scene\":\(sceneJSON(cameraX: cameraX))}".utf8)
    }

    func testRawNumericOverflowAndNonFiniteTokensCannotBecomeSceneValues() {
        // JSONSerialization cannot construct these wire representations. Check
        // the decoder boundary, including finite values outside the scene range.
        for token in ["1e309", "-1e309", "NaN", "Infinity", "-Infinity",
                      "\"NaN\"", "\"Infinity\"", "1e308", "-1e308"] {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(cameraX: token)), token)
        }
    }

    func testSchemaRequiresAnIntegerValueWithoutInventingAnIntegerSpellingRule() throws {
        for token in ["1.25", "1e99", "-1e99", "\"1\"", "+1", "01", "null"] {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(version: token)), token)
        }
        let expected = try LightingProjectDocument.decode(wire())
        // These valid JSON numbers all represent the same integer. Hand-edited
        // copies should not fail merely because their number spelling differs.
        for token in ["1.0", "1e0", "1.00e+0"] {
            XCTAssertEqual(try LightingProjectDocument.decode(wire(version: token)), expected)
        }
    }

    func testInvalidEncodingUnpairedSurrogatesAndExtraRootsCannotImport() throws {
        for name in ["\"\\uD800\"", "\"\\uDC00\"", "\"\\u0000\""] {
            XCTAssertThrowsError(try LightingProjectDocument.decode(wire(name: name)), name)
        }
        var invalidUTF8 = Data("{\"schemaVersion\":1,\"name\":\"".utf8)
        invalidUTF8.append(contentsOf: [0xC3, 0x28])
        invalidUTF8.append(Data("\",\"scene\":\(sceneJSON())}".utf8))
        XCTAssertThrowsError(try LightingProjectDocument.decode(invalidUTF8))

        var extraRoot = wire()
        extraRoot.append(Data("\n{}".utf8))
        XCTAssertThrowsError(try LightingProjectDocument.decode(extraRoot))

        // A valid escaped surrogate pair must retain its intended character.
        let valid = try LightingProjectDocument.decode(wire(name: "\"\\uD83D\\uDCA1\""))
        XCTAssertEqual(valid.name, "💡")
    }

    func testDecodedCopyCannotOverwriteConcurrentChangesAndCanBeImportedAfterReload() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let firstWindow = ProjectLibraryFileStore(directory: directory)
        let secondWindow = ProjectLibraryFileStore(directory: directory)
        let initial = try ProjectLibrary(name: "Original", scene: .portrait())
        try firstWindow.save(initial, replacing: nil)
        let loaded = try XCTUnwrap(firstWindow.load())

        var importedScene = LightingScene.portrait()
        importedScene.lights[0].candela = 2345.6789
        let sourceBytes = try LightingProjectDocument(name: "Portable copy", scene: importedScene).encode()
        let document = try LightingProjectDocument.decode(sourceBytes)
        var proposed = loaded
        try proposed.create(name: document.name, scene: document.scene)
        let rejectedID = proposed.activeID

        var competing = loaded
        try competing.rename(competing.activeID, to: "Another window's saved name")
        try secondWindow.save(competing, replacing: loaded)
        let latestBytes = try Data(contentsOf: firstWindow.url)
        XCTAssertThrowsError(try firstWindow.save(proposed, replacing: loaded)) {
            XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
        }
        XCTAssertEqual(try Data(contentsOf: firstWindow.url), latestBytes)
        XCTAssertEqual(try firstWindow.load(), competing)
        XCTAssertEqual(loaded, initial, "The editor's loaded value is not changed by a rejected transaction")

        let refreshed = try XCTUnwrap(firstWindow.load())
        var retried = refreshed
        try retried.create(name: document.name, scene: document.scene)
        XCTAssertNotEqual(retried.activeID, rejectedID)
        XCTAssertNotEqual(retried.activeID, refreshed.activeID)
        try firstWindow.save(retried, replacing: refreshed)
        let reopened = try XCTUnwrap(firstWindow.load())
        XCTAssertEqual(reopened.projects.count, 2)
        XCTAssertEqual(reopened.activeProject?.scene, importedScene)
        XCTAssertEqual(reopened.projects.first { $0.id == competing.activeID }, competing.activeProject)
        XCTAssertEqual(try LightingProjectDocument.decode(sourceBytes), document)
    }

    func testFullLibraryRejectsDecodedCopyWithoutChangingMemoryOrSavedBytes() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ProjectLibraryFileStore(directory: directory)
        let document = try LightingProjectDocument.decode(wire())
        var full = try ProjectLibrary(name: "Existing 0", scene: document.scene)
        for index in 1..<ProjectLibrary.maximumProjects {
            try full.create(name: "Existing \(index)", scene: document.scene)
        }
        try full.archive(full.projects.last!.id)
        try store.save(full, replacing: nil)
        let before = try Data(contentsOf: store.url)
        var proposed = full
        XCTAssertThrowsError(try proposed.create(name: document.name, scene: document.scene)) {
            XCTAssertEqual($0 as? ProjectLibraryError, .capacity)
        }
        XCTAssertEqual(proposed, full)
        XCTAssertEqual(try Data(contentsOf: store.url), before)
        XCTAssertEqual(try store.load(), full)
    }

    func testIndividuallyValidCopyCannotGrowLibraryPastItsSeparateByteLimit() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ProjectLibraryFileStore(directory: directory)
        let scene = try LightingProjectDocument.decode(wire()).scene
        // Both names satisfy legacy grapheme bounds and each single document
        // fits. Together they exceed the library's independent storage limit.
        let marks = String(repeating: "\u{0301}", count: 2_100_000)
        let initial = try ProjectLibrary(name: "Existing" + marks, scene: scene)
        try store.save(initial, replacing: nil)
        let before = try Data(contentsOf: store.url)
        let source = try LightingProjectDocument(name: "Imported" + marks, scene: scene).encode()
        XCTAssertLessThan(source.count, LightingProjectDocument.maximumBytes)
        let document = try LightingProjectDocument.decode(source)
        var proposed = initial
        try proposed.create(name: document.name, scene: document.scene)
        XCTAssertThrowsError(try store.save(proposed, replacing: initial)) {
            XCTAssertEqual($0 as? ProjectLibraryError, .tooLarge)
        }
        // Avoid printing multi-megabyte fixtures if the preservation check fails.
        XCTAssertTrue(try Data(contentsOf: store.url) == before,
                      "A valid copy that makes the library too large must not alter saved bytes")
        XCTAssertTrue(try store.load() == initial)
        XCTAssertEqual(initial.projects.count, 1)
    }
}
