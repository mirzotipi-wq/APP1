import XCTest
@testable import LightingCore

final class SceneLightCreationTests: XCTestCase {
    func testDefaultPortraitPlacementAndUniqueNamePreserveExistingRig() throws {
        var original = LightingScene.portrait()
        original.lights[0].name = "Light 1"
        let id = UUID()
        let result = try SceneLightCreation.addingLight(to: original, id: id)
        XCTAssertEqual(Array(result.lights.dropLast()), original.lights)
        XCTAssertEqual(result.subject, original.subject)
        XCTAssertEqual(result.camera, original.camera)
        XCTAssertEqual(result.lights.last?.id, id)
        XCTAssertEqual(result.lights.last?.name, "Light 2")
        XCTAssertEqual(result.lights.last?.position, Position(x: 1, y: 2, z: 1))
    }

    func testTranslatedRigCreatesLightBesideTranslatedSubject() throws {
        let original = LightingScene.portrait()
        let offset = Position(x: 35, y: 10, z: -42)
        let translated = try SceneTransform.translated(original, by: offset)
        let result = try SceneLightCreation.addingLight(to: translated)
        XCTAssertEqual(result.lights.last?.position, Position(x: 36, y: 12, z: -41))
        XCTAssertEqual(Array(result.lights.dropLast()), translated.lights)
    }

    func testCameraAzimuthDeterminesSubjectRelativePlacement() throws {
        var scene = LightingScene.portrait()
        scene.camera = Position(x: 3, y: 8, z: 0)
        XCTAssertEqual(try SceneLightCreation.addingLight(to: scene).lights.last?.position,
                       Position(x: 1, y: 2, z: -1))
        scene.camera = Position(x: -3, y: -1, z: 0)
        XCTAssertEqual(try SceneLightCreation.addingLight(to: scene).lights.last?.position,
                       Position(x: -1, y: 2, z: 1))
    }

    func testVerticalAndCoincidentCameraUseDefinedHorizontalFallback() throws {
        var scene = LightingScene.portrait()
        for height in [1.5, 4.0, -3.0] {
            scene.camera = Position(x: 0, y: height, z: 0)
            XCTAssertEqual(try SceneLightCreation.addingLight(to: scene).lights.last?.position,
                           Position(x: 1, y: 2, z: 1))
        }
    }

    func testBoundaryCapacityAndDuplicateIdentityFailWithoutChangingSource() throws {
        let original = LightingScene.portrait()
        var boundary = original
        boundary.subject.y = 100
        let snapshot = boundary
        XCTAssertThrowsError(try SceneLightCreation.addingLight(to: boundary)) {
            XCTAssertEqual($0 as? SceneLightCreationError, .outsideSupportedScene)
        }
        XCTAssertEqual(boundary, snapshot)
        var full = original
        while full.lights.count < 12 {
            full = try SceneLightCreation.addingLight(to: full)
        }
        XCTAssertThrowsError(try SceneLightCreation.addingLight(to: full)) {
            XCTAssertEqual($0 as? SceneLightCreationError, .capacityReached)
        }
        XCTAssertThrowsError(try SceneLightCreation.addingLight(to: original, id: original.lights[0].id)) {
            XCTAssertEqual($0 as? SceneError, .duplicateLight)
        }
        var invalid = original
        invalid.subject.x = .nan
        XCTAssertThrowsError(try SceneLightCreation.addingLight(to: invalid))
    }

    func testOneHistoryCommandRestoresCompleteSceneAndExactIdentity() throws {
        let original = LightingScene.portrait()
        let created = try SceneLightCreation.addingLight(to: original)
        var history = SceneEditHistory()
        history.record(previous: original)
        XCTAssertEqual(history.undo(current: created), original)
        XCTAssertEqual(history.redo(current: original), created)
        XCTAssertEqual(history.undo(current: created), original)
        XCTAssertNil(history.undo(current: original))
    }
}
