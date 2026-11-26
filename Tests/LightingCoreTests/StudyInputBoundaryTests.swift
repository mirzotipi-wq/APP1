import Foundation
import XCTest
@testable import LightingCore

final class StudyInputBoundaryTests: XCTestCase {
    private enum EntryPoint: String, CaseIterable {
        case sphereInteractive, sphereReference, portrait, compute

        func prepare(scene: LightingScene, width: Int) throws {
            switch self {
            case .sphereInteractive:
                _ = try ReferenceStudyRenderer.render(scene: scene, width: width, quality: .interactive)
            case .sphereReference:
                _ = try ReferenceStudyRenderer.render(scene: scene, width: width, quality: .reference)
            case .portrait:
                _ = try PortraitStudyRenderer.render(scene: scene, width: width)
            case .compute:
                _ = try StudyComputeInput(scene: scene, width: width)
            }
        }
    }

    private func inactiveLights(count: Int) -> [StudioLight] {
        (0..<count).map { index in
            StudioLight(name: "Inactive \(index)", position: .init(x: -1, y: 2, z: 1),
                        candela: 0, kelvin: 5600)
        }
    }

    private func assertRejected(_ scene: LightingScene, as expected: StudyError,
                                width: Int = 24, context: String,
                                file: StaticString = #filePath, line: UInt = #line) {
        for entry in EntryPoint.allCases {
            let message = "\(entry.rawValue): \(context)"
            XCTAssertThrowsError(try entry.prepare(scene: scene, width: width), message, file: file, line: line) {
                XCTAssertEqual($0 as? StudyError, expected, message, file: file, line: line)
            }
        }
    }

    func testMalformedSchemasAndLightCollectionsAreRejectedByEveryStudyEntryPoint() {
        let cases: [(String, (inout LightingScene) -> Void)] = [
            ("schema zero", { $0.schemaVersion = 0 }),
            ("future schema", { $0.schemaVersion = LightingScene.currentSchemaVersion + 1 }),
            ("v1 with optics", {
                $0.schemaVersion = 1
                $0.lights[0].optics = .init(kind: .point)
            }),
            ("v2 with camera lens", {
                $0.schemaVersion = 2
                $0.cameraLens = .init(focalLengthMillimeters: 50)
            }),
            ("v3 with preview settings", {
                $0.schemaVersion = 3
                $0.previewSettings = .init()
            }),
            ("v4 with measured room", {
                $0.schemaVersion = 4
                $0.placementRoom = .init()
            }),
            ("v4 with emitter roll", {
                $0.schemaVersion = 4
                $0.lights[0].optics = .init(kind: .rectangle, rollDegrees: 0)
            }),
            ("thirteen lights", { $0.lights = self.inactiveLights(count: 13) }),
            ("duplicate light IDs", { $0.lights[1].id = $0.lights[0].id })
        ]
        for (name, mutate) in cases {
            // Keep geometry valid so its earlier checks cannot mask scene validation.
            var scene = LightingScene.portrait()
            mutate(&scene)
            assertRejected(scene, as: .invalidScene, context: name)
        }
    }

    func testInactiveLightDataIsValidatedBeforeSamplesAreSkipped() {
        let cases: [(String, (inout StudioLight) -> Void)] = [
            ("empty name", { $0.name = " " }),
            ("nonfinite position", { $0.position.x = .infinity }),
            ("out-of-range temperature", { $0.kelvin = 999 }),
            ("nonfinite temperature", { $0.kelvin = .nan }),
            ("invalid rectangle size", { $0.optics = .init(kind: .rectangle, widthMeters: 0) }),
            ("nonfinite aim", { $0.optics = .init(kind: .directional, aimTarget: .init(x: .nan, y: 0, z: 0)) }),
            ("nonfinite roll", { $0.optics = .init(kind: .rectangle, rollDegrees: .infinity) })
        ]
        for (name, mutate) in cases {
            var scene = LightingScene.portrait()
            scene.lights = inactiveLights(count: 1)
            mutate(&scene.lights[0])
            XCTAssertEqual(scene.lights[0].candela, 0, name)
            assertRejected(scene, as: .invalidScene, context: "inactive light: \(name)")
        }
    }

    func testResolutionThenCameraErrorsPrecedeMalformedSceneErrors() {
        var scene = LightingScene.portrait()
        let validCamera = scene.camera
        scene.schemaVersion = LightingScene.currentSchemaVersion + 1
        scene.camera = scene.subject
        assertRejected(scene, as: .invalidResolution, width: 23,
                       context: "invalid resolution, camera and schema")
        assertRejected(scene, as: .invalidCamera, context: "invalid camera and schema")
        scene.camera = validCamera
        assertRejected(scene, as: .invalidScene, context: "invalid schema with valid camera")
    }

    func testSceneValidationPrecedesActiveEmitterPreparation() {
        var scene = LightingScene.portrait()
        let emitterPosition = scene.lights[0].position
        scene.lights[0].optics = .init(kind: .rectangle, aimTarget: emitterPosition)
        scene.lights[1].candela = 0
        scene.lights[1].kelvin = .nan
        assertRejected(scene, as: .invalidScene, context: "malformed inactive data and degenerate active aim")
        scene.lights[1].kelvin = 5600
        assertRejected(scene, as: .invalidEmitter, context: "valid scene data with degenerate active aim")
    }

    func testTwelveValidInactiveLightsAndInactiveDegenerateAimAreAccepted() {
        var scene = LightingScene.portrait()
        scene.lights = inactiveLights(count: 12)
        for entry in EntryPoint.allCases {
            XCTAssertNoThrow(try entry.prepare(scene: scene, width: 24), "\(entry.rawValue): twelve valid lights")
        }
        // A zero-output emitter needs valid stored data, but no usable emitting frame.
        let emitterPosition = scene.lights[0].position
        scene.lights[0].optics = .init(kind: .rectangle, aimTarget: emitterPosition)
        for entry in EntryPoint.allCases {
            XCTAssertNoThrow(try entry.prepare(scene: scene, width: 24), "\(entry.rawValue): inactive degenerate aim")
        }
    }
}
