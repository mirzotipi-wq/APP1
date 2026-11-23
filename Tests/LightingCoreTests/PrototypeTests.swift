import XCTest
import Foundation
@testable import LightingCore

final class PrototypeTests: XCTestCase {
    func testRecipesAreValidAndRoundTrip() throws {
        for recipe in LightingRecipe.allCases {
            let scene = recipe.makeScene()
            XCTAssertFalse(scene.lights.isEmpty)
            XCTAssertEqual(try SceneCodec.decode(SceneCodec.encode(scene)), scene)
        }
        XCTAssertEqual(LightingRecipe.silhouette.makeScene().lights.count, 1)
        XCTAssertEqual(LightingRecipe.threePoint.makeScene().lights.count, 3)
    }
    func testSaveEditReopenAndCorruptionProtection() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("scene.json")
        let store = SceneFileStore(url: url)
        XCTAssertNil(try store.load())
        var scene = LightingRecipe.rembrandt.makeScene()
        try store.save(scene)
        scene.lights[0].candela = 1250
        try store.save(scene)
        XCTAssertEqual(try SceneFileStore(url: url).load(), scene)
        let corrupted = Data("broken data".utf8)
        try corrupted.write(to: url)
        XCTAssertThrowsError(try store.load())
        XCTAssertThrowsError(try store.save(scene))
        XCTAssertEqual(try Data(contentsOf: url), corrupted)
    }
    func testInvalidEditPreservesSavedData() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SceneFileStore(url: folder.appendingPathComponent("scene.json"))
        let original = LightingScene.portrait()
        try store.save(original)
        var invalid = original
        invalid.lights[0].candela = -1
        XCTAssertThrowsError(try store.save(invalid))
        XCTAssertEqual(try store.load(), original)
    }
}
