import Foundation
import XCTest
@testable import LightingCore

final class StudioFieldCommandTests: XCTestCase {
    func testScalarDomainsAndBoundariesMatchFullSceneValidation() throws {
        let fields: [(StudioLightField, WritableKeyPath<StudioLight, Double>, ClosedRange<Double>)] = [
            (.x, \.position.x, -100...100),
            (.y, \.position.y, -100...100),
            (.z, \.position.z, -100...100),
            (.candela, \.candela, 0...100_000),
            (.kelvin, \.kelvin, 1_000...20_000)
        ]
        XCTAssertEqual(StudioLightField.allCases.count, fields.count)
        let original = StudioEditorState()
        let light = original.scene.lights[1]
        for (field, keyPath, domain) in fields {
            XCTAssertTrue(StudioLightField.allCases.contains(field))
            XCTAssertEqual(field.domain, domain)
            XCTAssertEqual(field.value(in: light), light[keyPath: keyPath])
            let values = [domain.lowerBound, domain.upperBound, domain.lowerBound.nextDown,
                          domain.upperBound.nextUp, light[keyPath: keyPath],
                          Double.nan, Double.infinity, -Double.infinity]
            for value in values {
                var candidate = original.scene
                candidate.lights[1][keyPath: keyPath] = value
                assertMatchesValidation(.lightValue(id: light.id, field: field, value: value),
                                        candidate: candidate, startingAt: original)
            }
        }
    }

    func testCompletePositionsMatchValidationForEveryCoordinateAndTarget() throws {
        let original = StudioEditorState()
        let lightID = original.scene.lights[2].id
        let axes: [WritableKeyPath<Position, Double>] = [\.x, \.y, \.z]
        for axis in axes {
            for value in [-100.0, 100.0, (-100.0).nextDown, 100.0.nextUp,
                          Double.nan, Double.infinity, -Double.infinity] {
                var position = Position(x: 0.125, y: 1.625, z: -2.375)
                position[keyPath: axis] = value
                var lightCandidate = original.scene
                lightCandidate.lights[2].position = position
                assertMatchesValidation(.lightPosition(id: lightID, position: position),
                                        candidate: lightCandidate, startingAt: original)
                var cameraCandidate = original.scene
                cameraCandidate.camera = position
                assertMatchesValidation(.cameraPosition(position), candidate: cameraCandidate,
                                        startingAt: original)
                var subjectCandidate = original.scene
                subjectCandidate.subject = position
                assertMatchesValidation(.subjectPosition(position), candidate: subjectCandidate,
                                        startingAt: original)
            }
        }
    }

    func testCompleteOpticsPayloadMatchesFullSceneValidation() throws {
        var scene = LightingScene.portrait()
        scene.lights[0].optics = .init(kind: .directional, widthMeters: 1.25,
                                     heightMeters: 1.75, rollDegrees: 12)
        let original = try StudioEditorState(scene: scene)
        var payloads: [LightOptics] = [
            .init(kind: .point),
            .init(kind: .rectangle, aimTarget: scene.subject),
            .init(kind: .rectangle, widthMeters: 0.05, heightMeters: 4, rollDegrees: -180),
            .init(kind: .rectangle, widthMeters: 4, heightMeters: 0.05, rollDegrees: 180),
            .init(aimTarget: .init(x: 100, y: -100, z: 100)),
            .init(aimTarget: .init(x: 0, y: .nan, z: 0)),
            .init(aimTarget: .init(x: 0, y: 0, z: 100.0.nextUp))
        ]
        for value in [Double(0.05).nextDown, 4.0.nextUp, Double.nan, Double.infinity, -Double.infinity] {
            payloads.append(.init(kind: .point, widthMeters: value))
            payloads.append(.init(kind: .rectangle, heightMeters: value))
        }
        for value in [(-180.0).nextDown, 180.0.nextUp, Double.nan, Double.infinity] {
            payloads.append(.init(kind: .rectangle, rollDegrees: value))
        }
        for optics in payloads {
            var candidate = scene
            candidate.lights[0].optics = optics
            assertMatchesValidation(.lightOptics(id: scene.lights[0].id, optics: optics),
                                    candidate: candidate, startingAt: original)
        }
    }

    func testLensAndPreviewBoundariesMatchFullSceneValidation() throws {
        var scene = LightingScene.portrait()
        scene.cameraLens = .init(focalLengthMillimeters: 35)
        scene.previewSettings = .init(whiteBalanceKelvin: 5000, exposureStops: 1.5)
        let original = try StudioEditorState(scene: scene)
        for value in [14.0, 200.0, 14.0.nextDown, 200.0.nextUp,
                      Double.nan, Double.infinity, -Double.infinity] {
            let lens = CameraLens(focalLengthMillimeters: value)
            var candidate = scene
            candidate.cameraLens = lens
            assertMatchesValidation(.cameraLens(lens), candidate: candidate, startingAt: original)
        }
        let fields: [(WritableKeyPath<PreviewSettings, Double>, ClosedRange<Double>)] = [
            (\.whiteBalanceKelvin, 2000...10000), (\.exposureStops, -6...6)
        ]
        for (keyPath, domain) in fields {
            for value in [domain.lowerBound, domain.upperBound, domain.lowerBound.nextDown,
                          domain.upperBound.nextUp, Double.nan, Double.infinity, -Double.infinity] {
                var settings = scene.effectivePreviewSettings
                settings[keyPath: keyPath] = value
                var candidate = scene
                candidate.previewSettings = settings
                assertMatchesValidation(.previewSettings(settings), candidate: candidate,
                                        startingAt: original)
            }
        }
    }

    func testWholeRoomPayloadValidatesDimensionsOffsetsYawAndOptionalCeiling() throws {
        let original = StudioEditorState()
        let fields: [(WritableKeyPath<ManualRoom, Double>, [Double])] = [
            (\.widthMeters, [1, 30, 1.0.nextDown, 30.0.nextUp, 0, .nan, .infinity]),
            (\.depthMeters, [1, 30, 1.0.nextDown, 30.0.nextUp, 0, .nan, .infinity]),
            (\.subjectX, [0, 6, 0.0.nextDown, 6.0.nextUp, .nan, .infinity]),
            (\.subjectZ, [0, 7, 0.0.nextDown, 7.0.nextUp, .nan, .infinity]),
            (\.yawDegrees, [-360, 360, (-360.0).nextDown, 360.0.nextUp, .nan, .infinity])
        ]
        var payloads = [ManualRoom(widthMeters: 1, depthMeters: 1, subjectX: 0, subjectZ: 1),
                        ManualRoom(widthMeters: 30, depthMeters: 30, subjectX: 30, subjectZ: 0)]
        for (keyPath, values) in fields {
            for value in values {
                var room = ManualRoom()
                room[keyPath: keyPath] = value
                payloads.append(room)
            }
        }
        for ceiling in [nil, 1.0, 30.0, 1.0.nextDown, 30.0.nextUp, Double.nan, Double.infinity] as [Double?] {
            payloads.append(ManualRoom(ceilingHeightMeters: ceiling))
        }
        for room in payloads {
            var candidate = original.scene
            candidate.placementRoom = room
            assertMatchesValidation(.room(room), candidate: candidate, startingAt: original)
        }
        var withRoom = original.scene
        withRoom.placementRoom = ManualRoom()
        assertMatchesValidation(.room(nil), candidate: original.scene,
                                startingAt: try StudioEditorState(scene: withRoom))
    }

    func testEffectiveDefaultsAreNoOpsPreservingRepresentationRedoAndRevision() throws {
        for explicitDefaults in [false, true] {
            var scene = LightingScene.portrait()
            if explicitDefaults {
                scene.cameraLens = .init()
                scene.previewSettings = .init()
                scene.lights[0].optics = .init(rollDegrees: 0)
            }
            var editor = try editorWithRedo(scene: scene)
            let unchanged = editor
            let commands: [StudioFieldCommand] = [
                .cameraLens(.init()), .previewSettings(.init()),
                .lightOptics(id: scene.lights[0].id, optics: .init()),
                .lightOptics(id: scene.lights[0].id, optics: .init(rollDegrees: 0))
            ]
            for command in commands {
                XCTAssertFalse(try editor.apply(command))
                XCTAssertEqual(editor, unchanged)
            }
            var manualEditor = unchanged
            var manualOptics = scene.lights[0].effectiveOptics
            manualOptics.aimTarget = scene.subject
            XCTAssertTrue(try manualEditor.apply(.lightOptics(id: scene.lights[0].id, optics: manualOptics)))
            XCTAssertEqual(manualEditor.scene.lights[0].optics?.aimTarget, scene.subject)
            XCTAssertTrue(editor.redo())
            XCTAssertEqual(editor.scene.camera.x, scene.camera.x + 1)
        }
    }

    func testInvalidLightPayloadsAndMissingIDsAreAtomicDuringEditWithRedo() throws {
        var editor = try editorWithRedo(scene: .portrait())
        let beforeEdit = editor
        let liveID = editor.scene.lights[0].id
        let missingID = UUID()
        editor.beginEditing(owner: "intensity")
        XCTAssertTrue(try editor.apply(.lightValue(id: liveID, field: .candela, value: 1234)))
        let active = editor
        let commands: [StudioFieldCommand] = [
            .lightValue(id: liveID, field: .candela, value: .nan),
            .lightPosition(id: liveID, position: .init(x: 0, y: .infinity, z: 0)),
            .lightOptics(id: liveID, optics: .init(widthMeters: 0)),
            .lightValue(id: missingID, field: .x, value: 1),
            .lightValue(id: missingID, field: .kelvin, value: .nan),
            .lightPosition(id: missingID, position: .init(x: 1, y: 2, z: 3)),
            .lightOptics(id: missingID, optics: .init())
        ]
        for command in commands {
            XCTAssertThrowsError(try editor.apply(command)) {
                XCTAssertEqual($0 as? SceneError, .invalidLight)
            }
            XCTAssertEqual(editor, active)
        }
        XCTAssertTrue(editor.cancelEditing())
        XCTAssertEqual(editor.scene, beforeEdit.scene)
        XCTAssertEqual(editor.history, beforeEdit.history)
        XCTAssertTrue(editor.redo())
        XCTAssertEqual(editor.scene.camera.x, beforeEdit.scene.camera.x + 1)
    }

    func testInvalidNonLightPayloadsPreserveOpenOwnerRedoAndRevision() throws {
        var editor = try editorWithRedo(scene: .portrait())
        editor.beginEditing(owner: "camera")
        let active = editor
        let commands: [StudioFieldCommand] = [
            .cameraPosition(.init(x: .nan, y: 1, z: 2)),
            .subjectPosition(.init(x: 0, y: 1, z: -101)),
            .cameraLens(.init(focalLengthMillimeters: 0)),
            .previewSettings(.init(whiteBalanceKelvin: 1000)),
            .previewSettings(.init(exposureStops: .infinity)),
            .room(.init(ceilingHeightMeters: .nan)),
            .room(.init(widthMeters: 1, subjectX: 2))
        ]
        for command in commands {
            XCTAssertThrowsError(try editor.apply(command)) {
                XCTAssertEqual($0 as? SceneError, .invalidScene)
            }
            XCTAssertEqual(editor, active)
        }
        editor.endEditing(owner: "old-camera")
        XCTAssertEqual(editor, active)
        editor.endEditing(owner: "camera")
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertTrue(editor.redo())
    }

    func testLegacyCombiningMarkNamesAndUntouchedSceneContentSurviveScalarCommands() throws {
        let name = String(repeating: "a", count: 79) + "e" + String(repeating: "\u{0301}", count: 4096)
        XCTAssertEqual(name.count, 80)
        XCTAssertGreaterThan(name.utf8.count, 8000)
        var legacy = LightingScene.portrait()
        legacy.schemaVersion = 1
        legacy.lights = (0..<12).map { index in
            StudioLight(name: name, position: .init(x: Double(index) / 8, y: 1.625, z: -2.375),
                        candela: 900.125, kelvin: 5600.5)
        }
        var editor = try StudioEditorState(scene: legacy, selection: legacy.lights[11].id)
        let initial = editor.scene
        var expected = initial
        expected.lights[3].position.x = -0.3125
        expected.lights[7].kelvin = 3200.125
        XCTAssertTrue(try editor.apply(.lightValue(id: initial.lights[3].id, field: .x, value: -0.3125)))
        XCTAssertTrue(try editor.apply(.lightValue(id: initial.lights[7].id, field: .kelvin, value: 3200.125)))
        XCTAssertEqual(editor.scene, try expected.validated())
        XCTAssertEqual(editor.scene.schemaVersion, LightingScene.currentSchemaVersion)
        XCTAssertEqual(editor.scene.lights.map(\.id), initial.lights.map(\.id))
        XCTAssertEqual(editor.scene.lights.map { Array($0.name.utf8) },
                       initial.lights.map { Array($0.name.utf8) })
        XCTAssertEqual(editor.selection, initial.lights[11].id)
        XCTAssertEqual(editor.scene.camera, legacy.camera)
        XCTAssertEqual(editor.scene.subject, legacy.subject)
        XCTAssertNil(editor.scene.cameraLens)
        XCTAssertNil(editor.scene.previewSettings)
        XCTAssertNil(editor.scene.placementRoom)
    }

    func testAllCommandKindsJoinOneOwnedTransactionAndUndoRetainsCurrentSelection() throws {
        var editor = StudioEditorState()
        let initial = editor.scene
        let firstID = initial.lights[0].id
        let secondID = initial.lights[1].id
        let optics = LightOptics(kind: .rectangle, aimTarget: initial.subject, rollDegrees: 45)
        let room = ManualRoom(yawDegrees: 37, ceilingHeightMeters: 2.75)
        var expected = initial
        expected.lights[0].candela = 1200.125
        expected.lights[1].position = .init(x: 2.125, y: 1.875, z: -0.75)
        expected.lights[0].optics = optics
        expected.camera = .init(x: 0.25, y: 1.625, z: 4.125)
        expected.subject = .init(x: -0.125, y: 1.75, z: 0.375)
        expected.cameraLens = .init(focalLengthMillimeters: 85)
        expected.previewSettings = .init(whiteBalanceKelvin: 6500, exposureStops: 1.25)
        expected.placementRoom = room
        let commands: [StudioFieldCommand] = [
            .lightValue(id: firstID, field: .candela, value: expected.lights[0].candela),
            .lightPosition(id: secondID, position: expected.lights[1].position),
            .lightOptics(id: firstID, optics: optics),
            .cameraPosition(expected.camera), .subjectPosition(expected.subject),
            .cameraLens(expected.effectiveCameraLens), .previewSettings(expected.effectivePreviewSettings),
            .room(room)
        ]
        editor.beginEditing(owner: "rig")
        for command in commands {
            let revision = editor.revision
            XCTAssertTrue(try editor.apply(command))
            XCTAssertNotEqual(editor.revision, revision)
            editor.beginEditing(owner: "rig")
            XCTAssertFalse(editor.undo())
        }
        XCTAssertEqual(editor.scene, try expected.validated())
        editor.endEditing(owner: "previous-rig")
        XCTAssertTrue(editor.history.isEditing)
        editor.endEditing(owner: "rig")
        XCTAssertTrue(editor.select(secondID))
        let committedRevision = editor.revision
        XCTAssertTrue(editor.undo())
        XCTAssertEqual(editor.scene, initial)
        XCTAssertEqual(editor.selection, secondID)
        XCTAssertNotEqual(editor.revision, committedRevision)
        XCTAssertFalse(editor.history.canUndo)
        let undoRevision = editor.revision
        XCTAssertTrue(editor.redo())
        XCTAssertEqual(editor.scene, expected)
        XCTAssertEqual(editor.selection, secondID)
        XCTAssertNotEqual(editor.revision, undoRevision)
        XCTAssertNotEqual(editor.revision, committedRevision)
    }

    func testOutAndBackRestoresExactOptionalAndRollRepresentationsWithoutDiscardingRedo() throws {
        let opticalBaselines: [LightOptics?] = [nil, .init(kind: .rectangle),
                                               .init(kind: .rectangle, rollDegrees: 0)]
        for baseline in opticalBaselines {
            for explicitDefaults in [false, true] {
                var scene = LightingScene.portrait()
                scene.lights[0].optics = baseline
                if explicitDefaults {
                    scene.cameraLens = .init()
                    scene.previewSettings = .init()
                }
                var editor = try editorWithRedo(scene: scene)
                let initial = editor
                let id = scene.lights[0].id
                var away = scene.lights[0].effectiveOptics
                away.rollDegrees = 45
                var returned = scene.lights[0].effectiveOptics
                returned.rollDegrees = baseline?.rollDegrees == nil ? 0 : nil
                editor.beginEditing(owner: "settings")
                let commands: [StudioFieldCommand] = [
                    .cameraLens(.init(focalLengthMillimeters: 85)),
                    .previewSettings(.init(whiteBalanceKelvin: 6500, exposureStops: 2)),
                    .lightOptics(id: id, optics: away),
                    .lightValue(id: id, field: .candela, value: 1200),
                    .cameraLens(.init()), .previewSettings(.init()),
                    .lightOptics(id: id, optics: returned),
                    .lightValue(id: id, field: .candela, value: scene.lights[0].candela)
                ]
                for command in commands { XCTAssertTrue(try editor.apply(command)) }
                editor.endEditing(owner: "settings")
                XCTAssertEqual(editor.scene, initial.scene)
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                XCTAssertEqual(try encoder.encode(editor.scene), try encoder.encode(initial.scene))
                XCTAssertEqual(editor.history, initial.history)
                XCTAssertNotEqual(editor.revision, initial.revision)
                XCTAssertTrue(editor.redo())
                XCTAssertEqual(editor.scene.camera.x, scene.camera.x + 1)
            }
        }
    }

    func testArbitrarySceneEntryPointsKeepFullValidationAfterTypedCommands() throws {
        var editor = try editorWithRedo(scene: .portrait())
        XCTAssertTrue(try editor.apply(.lightValue(id: editor.scene.lights[0].id, field: .x, value: -2)))
        editor.beginEditing(owner: "inspector")
        let unchanged = editor
        var badName = editor.scene
        badName.lights[1].name = String(repeating: "x", count: 81)
        var duplicate = editor.scene
        duplicate.lights[1].id = duplicate.lights[0].id
        var unsupported = editor.scene
        unsupported.schemaVersion = LightingScene.currentSchemaVersion + 1
        var tooMany = editor.scene
        tooMany.lights = (0..<13).map { index in
            StudioLight(name: "Light \(index)", position: editor.scene.subject, candela: 1, kelvin: 5600)
        }
        for candidate in [badName, duplicate, unsupported, tooMany] {
            XCTAssertThrowsError(try candidate.validated())
            XCTAssertThrowsError(try StudioEditorState(scene: candidate))
            XCTAssertThrowsError(try editor.update(with: candidate))
            XCTAssertEqual(editor, unchanged)
            XCTAssertThrowsError(try editor.replace(with: candidate))
            XCTAssertEqual(editor, unchanged)
            XCTAssertThrowsError(try editor.adopt(candidate, resettingHistory: true))
            XCTAssertEqual(editor, unchanged)
            XCTAssertThrowsError(try editor.adopt(candidate, resettingHistory: false))
            XCTAssertEqual(editor, unchanged)
        }
    }

    /// Only the established whole-scene validator decides payload acceptance.
    /// The fixture changes a candidate independently of the typed command path.
    private func assertMatchesValidation(_ command: StudioFieldCommand, candidate: LightingScene,
                                         startingAt original: StudioEditorState,
                                         file: StaticString = #filePath, line: UInt = #line) {
        var editor = original
        switch Result(catching: { try candidate.validated() }) {
        case .success(let expected):
            XCTAssertEqual(try editor.apply(command), expected != original.scene, file: file, line: line)
            XCTAssertEqual(editor.scene, expected, file: file, line: line)
            XCTAssertEqual(editor.selection, original.selection, file: file, line: line)
            if expected == original.scene {
                XCTAssertEqual(editor, original, file: file, line: line)
            } else {
                XCTAssertNotEqual(editor.revision, original.revision, file: file, line: line)
                XCTAssertTrue(editor.undo(), file: file, line: line)
                XCTAssertEqual(editor.scene, original.scene, file: file, line: line)
                XCTAssertFalse(editor.history.canUndo, file: file, line: line)
                XCTAssertTrue(editor.redo(), file: file, line: line)
                XCTAssertEqual(editor.scene, expected, file: file, line: line)
            }
        case .failure(let oracleError):
            XCTAssertThrowsError(try editor.apply(command), file: file, line: line) {
                XCTAssertEqual($0 as? SceneError, oracleError as? SceneError, file: file, line: line)
            }
            XCTAssertEqual(editor, original, file: file, line: line)
        }
    }

    private func editorWithRedo(scene: LightingScene) throws -> StudioEditorState {
        var editor = try StudioEditorState(scene: scene)
        var changed = editor.scene
        changed.camera.x += 1
        XCTAssertTrue(try editor.update(with: changed))
        XCTAssertTrue(editor.undo())
        XCTAssertTrue(editor.history.canRedo)
        XCTAssertFalse(editor.history.canUndo)
        return editor
    }
}
