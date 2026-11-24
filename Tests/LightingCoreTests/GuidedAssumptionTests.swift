import Foundation
import XCTest
@testable import LightingCore

final class GuidedAssumptionTests: XCTestCase {
    func testUnknownCuesRemainUnknownInBothDifferentStartingRigs() throws {
        let observations = ReferenceObservations(direction: .right)
        let rigs = try GuidedLighting.candidates(from: observations, in: .portrait())

        XCTAssertEqual(rigs.count, 2)
        XCTAssertEqual(rigs.map(\.basis.keyDistanceMeters), [1.5, 2.25])
        XCTAssertEqual(rigs.map { $0.scene.lights[0].effectiveOptics.kind }, [.directional, .rectangle])
        XCTAssertNil(rigs[0].keyToFillRatio)
        XCTAssertEqual(rigs[1].keyToFillRatio, 4)
        for rig in rigs {
            XCTAssertEqual(rig.basis.observations, observations)
            XCTAssertEqual(rig.basis.provenance(for: .direction), .userObservation)
            XCTAssertEqual(rig.basis.unobservedCues, [.softness, .fill, .rim])
            XCTAssertEqual(rig.basis.observations.softness, .unknown)
            XCTAssertEqual(rig.basis.observations.fill, .unknown)
            XCTAssertEqual(rig.basis.observations.rim, .unknown)
        }
    }

    func testProvenanceRetainsEveryCategoricalAnswerWithoutPromotingDefaultsToObservations() throws {
        for direction in [ReferenceObservations.Direction.left, .center, .right] {
            for softness in ReferenceObservations.Softness.allCases {
                for fill in ReferenceObservations.Fill.allCases {
                    for rim in ReferenceObservations.Rim.allCases {
                        var observations = ReferenceObservations(direction: direction, softness: softness,
                                                                 fill: fill, rim: rim)
                        let original = observations
                        let rigs = try GuidedLighting.candidates(from: observations, in: .portrait())
                        observations = .init()
                        XCTAssertNotEqual(observations, original)
                        for rig in rigs {
                            XCTAssertEqual(rig.basis.observations, original)
                            let expected: [GuidedRigBasis.Cue: GuidedRigBasis.Provenance] = [
                                .direction: .userObservation,
                                .softness: softness == .unknown ? .startingAssumption : .userObservation,
                                .fill: fill == .unknown ? .startingAssumption : .userObservation,
                                .rim: rim == .unknown ? .startingAssumption : .userObservation
                            ]
                            for cue in GuidedRigBasis.Cue.allCases {
                                XCTAssertEqual(rig.basis.provenance(for: cue), expected[cue])
                                XCTAssertEqual(rig.basis.unobservedCues.contains(cue),
                                               expected[cue] == .startingAssumption)
                            }
                        }
                    }
                }
            }
        }
    }

    func testChosenNumericBasisMatchesActualCameraRelativeGeometryAndLighting() throws {
        for cameraPosition in [Position(x: 0, y: 1.5, z: 3), Position(x: 3, y: 2.4, z: -1)] {
            var scene = LightingScene.portrait()
            scene.camera = cameraPosition
            let camera = try XCTUnwrap(CameraFraming(scene: scene))
            for direction in [ReferenceObservations.Direction.left, .center, .right] {
                let observations = ReferenceObservations(direction: direction, softness: .soft,
                                                         fill: .balanced, rim: .visible)
                for rig in try GuidedLighting.candidates(from: observations, in: scene) {
                    let basis = rig.basis
                    let key = try XCTUnwrap(rig.scene.lights.first)
                    let delta = Position(x: key.position.x - scene.subject.x,
                                         y: key.position.y - scene.subject.y,
                                         z: key.position.z - scene.subject.z)
                    let distance = key.position.distance(to: scene.subject)
                    func dot(_ a: Position, _ b: UnitDirection) -> Double {
                        a.x * b.x + a.y * b.y + a.z * b.z
                    }
                    let right = dot(delta, camera.right)
                    let up = dot(delta, camera.up)
                    let towardCamera = -dot(delta, camera.forward)
                    XCTAssertEqual(distance, basis.keyDistanceMeters, accuracy: 1e-12)
                    XCTAssertEqual(atan2(right, towardCamera) * 180 / .pi,
                                   basis.keyAzimuthDegrees, accuracy: 1e-12)
                    XCTAssertEqual(asin(up / distance) * 180 / .pi,
                                   basis.keyElevationDegrees, accuracy: 1e-12)
                    XCTAssertEqual(basis.keyElevationDegrees, 25)
                    XCTAssertEqual(basis.keyIlluminanceLux, 400)
                    XCTAssertEqual(basis.keyIlluminanceLux, rig.keyLux)
                    XCTAssertEqual(try XCTUnwrap(StudioPhotometry.illuminance(for: key, in: rig.scene)),
                                   basis.keyIlluminanceLux, accuracy: 1e-8)
                    XCTAssertEqual(basis.lightKelvin, 5600)
                    XCTAssertTrue(rig.scene.lights.allSatisfy { $0.kelvin == basis.lightKelvin })
                    XCTAssertEqual(rig.basis.unobservedCues, [])
                    XCTAssertEqual(rig.scene.camera, scene.camera)
                    XCTAssertEqual(rig.scene.subject, scene.subject)
                }
            }
        }
    }

    func testExplicitMinimalFillAndNoVisibleRimRemainDifferentFromUnobservedCues() throws {
        let observed = try XCTUnwrap(GuidedLighting.candidates(
            from: .init(direction: .center, softness: .hard, fill: .none, rim: .absent),
            in: .portrait()).first)
        let unobserved = try XCTUnwrap(GuidedLighting.candidates(
            from: .init(direction: .center), in: .portrait()).first)

        // The near choices happen to use the same source count. Their basis
        // must still distinguish a person's explicit answers from defaults.
        XCTAssertEqual(observed.scene.lights.count, 1)
        XCTAssertEqual(unobserved.scene.lights.count, 1)
        XCTAssertNil(observed.keyToFillRatio)
        XCTAssertNil(unobserved.keyToFillRatio)
        XCTAssertEqual(observed.basis.provenance(for: .fill), .userObservation)
        XCTAssertEqual(observed.basis.provenance(for: .rim), .userObservation)
        XCTAssertEqual(unobserved.basis.provenance(for: .fill), .startingAssumption)
        XCTAssertEqual(unobserved.basis.provenance(for: .rim), .startingAssumption)
        XCTAssertEqual(observed.basis.unobservedCues, [])
        XCTAssertEqual(unobserved.basis.unobservedCues, [.softness, .fill, .rim])
    }
}
