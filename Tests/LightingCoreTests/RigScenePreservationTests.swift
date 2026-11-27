import Foundation
import XCTest
@testable import LightingCore

final class RigScenePreservationTests: XCTestCase {
    func testEveryRecipePreservesCommittedSceneThroughEditorApplyUndoAndRedo() throws {
        let source = try editorWithCommittedRoom()

        for recipe in LightingRecipe.allCases {
            let candidate = try recipe.scene(applyingTo: source.scene)
            let authored = recipe.makeScene().lights
            XCTAssertEqual(candidate.lights.count, recipe.lightCount, recipe.rawValue)
            XCTAssertEqual(candidate.lights.map(\.name), authored.map(\.name), recipe.rawValue)
            XCTAssertEqual(candidate.lights.map(\.candela), authored.map(\.candela), recipe.rawValue)
            XCTAssertEqual(candidate.lights.map(\.kelvin), authored.map(\.kelvin), recipe.rawValue)
            XCTAssertEqual(candidate.lights.map(\.optics), authored.map(\.optics), recipe.rawValue)
            try assertAdoptionPreservesScene(candidate, from: source)
        }
    }

    func testBothGuidedAlternativesPreserveCommittedSceneThroughEditorApplyUndoAndRedo() throws {
        let source = try editorWithCommittedRoom()
        let candidates = try GuidedLighting.candidates(
            from: .init(direction: .left, softness: .soft, fill: .balanced, rim: .visible),
            in: source.scene)

        XCTAssertEqual(candidates.map(\.id), ["near", "far"])
        for candidate in candidates {
            XCTAssertEqual(candidate.scene.lights.map(\.name), ["Key", "Fill", "Rim"])
            XCTAssertEqual(candidate.scene.lights.map { $0.effectiveOptics.kind },
                           [.rectangle, .rectangle, .directional])
            try assertAdoptionPreservesScene(candidate.scene, from: source)
        }
    }

    func testNearGuidedCandidateSurvivesFarWorldBoundaryFailureAndRemainsUndoable() throws {
        let source = try editorWithCommittedRoom(
            subject: .init(x: 98.5, y: 1.85, z: -3.75),
            camera: .init(x: 100, y: 1.85, z: -3.75))

        // The camera faces -X. At the assumed 25-degree elevation, the near
        // key fits below x = 100 while the far key crosses that world boundary.
        // Hard light with no fill or rim isolates the alternative's key position.
        let nearX = 98.5 + 1.5 * cos(25 * .pi / 180)
        let farX = 98.5 + 2.25 * cos(25 * .pi / 180)
        XCTAssertLessThan(nearX, Position.coordinateRange.upperBound)
        XCTAssertGreaterThan(farX, Position.coordinateRange.upperBound)

        let candidates = try GuidedLighting.candidates(
            from: .init(direction: .center, softness: .hard, fill: .none, rim: .absent),
            in: source.scene)
        XCTAssertEqual(candidates.map(\.id), ["near"])
        let candidate = try XCTUnwrap(candidates.first)
        XCTAssertEqual(candidate.scene.lights.count, 1)
        let key = try XCTUnwrap(candidate.scene.lights.first)
        XCTAssertEqual(key.position.x, nearX, accuracy: 1e-12)
        XCTAssertEqual(key.effectiveOptics.kind, .directional)
        try assertAdoptionPreservesScene(candidate.scene, from: source)
    }

    private func editorWithCommittedRoom(
        subject: Position = .init(x: 4.25, y: 1.85, z: -3.75),
        camera: Position = .init(x: 8.25, y: 2.7, z: -3.75)
    ) throws -> StudioEditorState {
        // Translated subject, 90-degree camera yaw and nonzero tilt ensure
        // preservation cannot pass by returning the default portrait settings.
        let scene = LightingScene(subject: subject, camera: camera, lights: [
            .init(name: "Saved soft key",
                  position: .init(x: subject.x - 1, y: subject.y + 0.9, z: subject.z + 1.2),
                  candela: 736.5, kelvin: 4230,
                  optics: .init(kind: .rectangle,
                                aimTarget: .init(x: subject.x - 0.1, y: subject.y - 0.2,
                                                 z: subject.z + 0.3),
                                widthMeters: 1.2, heightMeters: 0.65, rollDegrees: 37)),
            .init(name: "Saved practical",
                  position: .init(x: subject.x - 1.7, y: subject.y - 0.3, z: subject.z - 1.5),
                  candela: 128.25, kelvin: 2875)
        ], cameraLens: .init(focalLengthMillimeters: 85),
           previewSettings: .init(whiteBalanceKelvin: 4100, exposureStops: 1.25))
        var editor = try StudioEditorState(scene: scene, selection: scene.lights.last?.id)
        XCTAssertTrue(try editor.apply(.room(.init(
            widthMeters: 8.4, depthMeters: 11.2, subjectX: 3.4, subjectZ: 6.5,
            yawDegrees: -37, ceilingHeightMeters: 4.2))))
        return editor
    }

    private func assertAdoptionPreservesScene(
        _ candidate: LightingScene, from source: StudioEditorState,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        // Full equality includes the exact stored lens/preview/room values,
        // camera, subject and schema. Only the proposed lights may differ.
        var expected = source.scene
        expected.lights = candidate.lights
        XCTAssertEqual(candidate, expected, file: file, line: line)
        XCTAssertFalse(candidate.lights.isEmpty, file: file, line: line)
        XCTAssertTrue(Set(candidate.lights.map(\.id)).isDisjoint(with: source.scene.lights.map(\.id)),
                      "A replacement rig must not reuse the old light identities", file: file, line: line)

        var editor = source
        XCTAssertTrue(try editor.replace(with: candidate), file: file, line: line)
        XCTAssertEqual(editor.scene, candidate, file: file, line: line)
        XCTAssertEqual(editor.selection, candidate.lights.first?.id, file: file, line: line)

        XCTAssertTrue(editor.undo(), file: file, line: line)
        XCTAssertEqual(editor.scene, source.scene, file: file, line: line)
        XCTAssertEqual(editor.selection, source.scene.lights.first?.id, file: file, line: line)

        // Room commitment and rig replacement remain separate undo commands.
        var beforeRoom = source.scene
        beforeRoom.placementRoom = nil
        XCTAssertTrue(editor.undo(), file: file, line: line)
        XCTAssertEqual(editor.scene, beforeRoom, file: file, line: line)
        XCTAssertFalse(editor.history.canUndo, file: file, line: line)

        XCTAssertTrue(editor.redo(), file: file, line: line)
        XCTAssertEqual(editor.scene, source.scene, file: file, line: line)
        XCTAssertTrue(editor.redo(), file: file, line: line)
        XCTAssertEqual(editor.scene, candidate, file: file, line: line)
        XCTAssertEqual(editor.selection, candidate.lights.first?.id, file: file, line: line)
        XCTAssertFalse(editor.history.canRedo, file: file, line: line)
    }
}
