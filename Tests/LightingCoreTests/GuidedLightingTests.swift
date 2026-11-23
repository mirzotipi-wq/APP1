import Foundation
import XCTest
@testable import LightingCore

final class GuidedLightingTests: XCTestCase {
    func testUnknownDirectionAbstains() {
        XCTAssertThrowsError(try GuidedLighting.candidates(from: .init(), in: .portrait())) {
            XCTAssertEqual($0 as? GuidedRigError, .insufficientDirection)
        }
    }

    func testAllObservationCombinationsAreValidAndPreserveCameraAndSubject() throws {
        var original = LightingScene.portrait()
        original.cameraLens = .init(focalLengthMillimeters: 85)
        original.previewSettings = .init(whiteBalanceKelvin: 4300, exposureStops: -1)
        for direction in [ReferenceObservations.Direction.left, .center, .right] {
            for softness in ReferenceObservations.Softness.allCases {
                for fill in ReferenceObservations.Fill.allCases {
                    for rim in ReferenceObservations.Rim.allCases {
                        let rigs = try GuidedLighting.candidates(from: .init(direction: direction, softness: softness, fill: fill, rim: rim), in: original)
                        XCTAssertEqual(rigs.map(\.id), ["near", "far"])
                        for rig in rigs {
                            XCTAssertEqual(try rig.scene.validated(), rig.scene)
                            XCTAssertEqual(rig.scene.subject, original.subject)
                            XCTAssertEqual(rig.scene.camera, original.camera)
                            XCTAssertEqual(rig.scene.cameraLens, original.cameraLens)
                            XCTAssertEqual(rig.scene.previewSettings, original.previewSettings)
                            XCTAssertTrue((1...3).contains(rig.scene.lights.count))
                            XCTAssertEqual(try SceneCodec.decode(SceneCodec.encode(rig.scene)), rig.scene)
                            XCTAssertEqual(rig.scene.lights.contains(where: { $0.name == "Rim" }), rim == .visible)
                        }
                    }
                }
            }
        }
        XCTAssertEqual(original.lights.count, 3)
    }

    func testCameraRelativeDirectionWithRotatedCamera() throws {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 3, y: 1.5, z: 0)
        let camera = try XCTUnwrap(CameraFraming(scene: scene))
        for direction in [ReferenceObservations.Direction.left, .center, .right] {
            let rigs = try GuidedLighting.candidates(from: .init(direction: direction, softness: .hard, fill: .none), in: scene)
            for rig in rigs {
                let p = try XCTUnwrap(rig.scene.lights.first?.position)
                let delta = Position(x: p.x - scene.subject.x, y: p.y - scene.subject.y, z: p.z - scene.subject.z)
                let side = delta.x * camera.right.x + delta.y * camera.right.y + delta.z * camera.right.z
                switch direction {
                case .left: XCTAssertLessThan(side, -0.1)
                case .center: XCTAssertEqual(side, 0, accuracy: 1e-9)
                case .right: XCTAssertGreaterThan(side, 0.1)
                case .unknown: XCTFail("Unknown was not requested")
                }
            }
        }
    }

    func testSoftAlternativesMatchAssumedLuxAndAngularSize() throws {
        let rigs = try GuidedLighting.candidates(from: .init(direction: .left, softness: .soft, fill: .restrained), in: .portrait())
        var ratios: [Double] = []
        for rig in rigs {
            let key = rig.scene.lights[0], fill = rig.scene.lights[1]
            XCTAssertEqual(key.effectiveOptics.kind, .rectangle)
            let keyLux = try XCTUnwrap(StudioPhotometry.illuminance(for: key, in: rig.scene))
            let fillLux = try XCTUnwrap(StudioPhotometry.illuminance(for: fill, in: rig.scene))
            XCTAssertEqual(keyLux, 400, accuracy: 0.0001)
            XCTAssertEqual(keyLux / fillLux, 4, accuracy: 0.0001)
            ratios.append(key.effectiveOptics.widthMeters / key.position.distance(to: rig.scene.subject))
        }
        XCTAssertEqual(ratios[0], ratios[1], accuracy: 1e-12)
        XCTAssertGreaterThan(rigs[1].scene.lights[0].candela, rigs[0].scene.lights[0].candela)
    }

    func testUncertainSoftnessAndFillProduceDifferentExplicitAlternatives() throws {
        let rigs = try GuidedLighting.candidates(from: .init(direction: .right), in: .portrait())
        XCTAssertEqual(rigs[0].scene.lights.count, 1)
        XCTAssertEqual(rigs[0].scene.lights[0].effectiveOptics.kind, .directional)
        XCTAssertNil(rigs[0].keyToFillRatio)
        XCTAssertEqual(rigs[1].scene.lights.count, 2)
        XCTAssertEqual(rigs[1].scene.lights[0].effectiveOptics.kind, .rectangle)
        XCTAssertEqual(rigs[1].keyToFillRatio, 4)
    }

    func testDegenerateAndOutOfBoundsGeometryAbstain() {
        var scene = LightingScene.portrait()
        scene.camera = scene.subject
        XCTAssertThrowsError(try GuidedLighting.candidates(from: .init(direction: .center), in: scene)) {
            XCTAssertEqual($0 as? GuidedRigError, .unsupportedGeometry)
        }
        scene.subject = .init(x: 0, y: 1.5, z: 99)
        scene.camera = .init(x: 0, y: 1.5, z: 100)
        XCTAssertThrowsError(try GuidedLighting.candidates(from: .init(direction: .center), in: scene)) {
            XCTAssertEqual($0 as? GuidedRigError, .unsupportedGeometry)
        }
    }
}
