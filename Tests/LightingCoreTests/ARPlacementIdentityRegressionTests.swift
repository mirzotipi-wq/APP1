import XCTest
import LightingCore

final class ARPlacementIdentityRegressionTests: XCTestCase {
    private func scene(subject: Position, camera: Position, light: Position,
                       optics: LightOptics? = nil) -> LightingScene {
        .init(subject: subject, camera: camera, lights: [
            .init(name: "Key", position: light, candela: 900, kelvin: 5600, optics: optics)
        ])
    }

    func testIdentityPreservesSubjectCameraAndLightCoordinatesExactly() {
        for sign in [-1.0, 1.0] {
            let endpoint = sign * 100
            let anchor = -sign * 99.8
            for (subjectXZ, markerXZ) in [(anchor, endpoint), (endpoint, anchor)] {
                let rig = scene(subject: .init(x: subjectXZ, y: 1.5, z: subjectXZ),
                                camera: .init(x: markerXZ, y: 1.5, z: markerXZ),
                                light: .init(x: markerXZ, y: 2, z: markerXZ))
                for yaw in [0.0, 360, -360] {
                    let context = "subject \(subjectXZ), markers \(markerXZ), yaw \(yaw)"
                    do {
                        let layout = try ARPlacementLayout(scene: rig,
                            origin: .init(x: subjectXZ, y: 0, z: subjectXZ), yawDegrees: yaw)
                        XCTAssertEqual(layout.yawDegrees, 0, context)
                        XCTAssertEqual(layout.items.map(\.position),
                                       [rig.subject, rig.camera, rig.lights[0].position], context)
                    } catch {
                        XCTFail("Valid identity placement rejected (\(context)): \(error)")
                    }
                }
            }
        }
    }

    func testIdentityTransformsEndpointPointsExactly() throws {
        for sign in [-1.0, 1.0] {
            let subject = Position(x: -sign * 99.8, y: 1.5, z: -sign * 99.8)
            let rig = LightingScene(subject: subject, camera: subject, lights: [])
            let layout = try ARPlacementLayout(scene: rig,
                origin: .init(x: subject.x, y: 0, z: subject.z))
            let endpoint = Position(x: sign * 100, y: sign * 100, z: sign * 100)
            XCTAssertEqual(layout.transform(position: endpoint), endpoint)
        }
    }

    func testUnchangedAxisStaysExactWhileOtherAxisAndHeightTranslate() {
        for sign in [-1.0, 1.0] {
            let anchor = -sign * 99.8
            let subject = Position(x: anchor, y: 1.5, z: anchor)
            for preserveX in [true, false] {
                let camera = Position(x: preserveX ? sign * 100 : anchor, y: 2,
                                      z: preserveX ? anchor : sign * 100)
                let origin = Position(x: preserveX ? anchor : 4, y: 0.25,
                                      z: preserveX ? 4 : anchor)
                let rig = LightingScene(subject: subject, camera: camera, lights: [])
                do {
                    let layout = try ARPlacementLayout(scene: rig, origin: origin)
                    XCTAssertEqual(layout.items[0].position,
                                   .init(x: origin.x, y: 1.75, z: origin.z))
                    XCTAssertEqual(layout.items[1].position,
                                   .init(x: preserveX ? sign * 100 : 4, y: 2.25,
                                         z: preserveX ? 4 : sign * 100))
                    XCTAssertEqual(layout.items[1].floorPosition.y, 0.25)
                    XCTAssertEqual(layout.items[1].heightAboveFloorMeters, 2)
                } catch {
                    XCTFail("Unchanged \(preserveX ? "X" : "Z") endpoint \(sign * 100) rejected: \(error)")
                }
            }
        }
    }

    func testIdentityPreservesBoundaryAimTargetsAndModifierCorners() {
        for sign in [-1.0, 1.0] {
            let subject = Position(x: -sign * 99.8, y: 1.5, z: 0)
            let camera = Position(x: subject.x, y: 1.5, z: 3)
            let light = Position(x: sign * 99.5, y: 2, z: 0)
            let origin = Position(x: subject.x, y: 0, z: 0)
            let target = Position(x: sign * 100, y: 2, z: 0)
            let pointRig = scene(subject: subject, camera: camera, light: light,
                                 optics: .init(kind: .point, aimTarget: target))
            XCTAssertNoThrow(try ARPlacementLayout(scene: pointRig, origin: origin))

            let rectangleRig = scene(subject: subject, camera: camera, light: light,
                optics: .init(kind: .rectangle, aimTarget: .init(x: light.x, y: 2, z: -1),
                              widthMeters: 1, heightMeters: 1))
            do {
                let layout = try ARPlacementLayout(scene: rectangleRig, origin: origin)
                let face = try XCTUnwrap(layout.modifierFaces.first)
                XCTAssertEqual(face.corners.map(\.x).sorted(),
                               [sign * 99, sign * 99, sign * 100, sign * 100].sorted())
                XCTAssertEqual(face.corners.map(\.y).sorted(), [1.5, 1.5, 2.5, 2.5])
            } catch {
                XCTFail("Identity modifier touching \(sign * 100) rejected: \(error)")
            }
        }
    }

    func testTranslationKeepsExactContactAndRejectsOneStepOfOverhang() throws {
        for sign in [-1.0, 1.0] {
            let contact = Position(x: sign * 99.75, y: sign * 99.75, z: sign * 99.75)
            let rig = scene(subject: .init(x: 0, y: 1.5, z: 0),
                            camera: .init(x: 1, y: 1.5, z: 3), light: contact)
            let origin = Position(x: sign * 0.25, y: sign * 0.25, z: sign * 0.25)
            let layout = try ARPlacementLayout(scene: rig, origin: origin)
            XCTAssertEqual(layout.items[0].position,
                           .init(x: origin.x, y: 1.5 + origin.y, z: origin.z))
            XCTAssertEqual(layout.items[2].position,
                           .init(x: sign * 100, y: sign * 100, z: sign * 100))
            for axis in [\Position.x, \Position.y, \Position.z] {
                var outside = contact
                outside[keyPath: axis] = sign > 0 ? contact[keyPath: axis].nextUp
                                                 : contact[keyPath: axis].nextDown
                XCTAssertNil(layout.transform(position: outside))
                var outsideRig = rig
                outsideRig.lights[0].position = outside
                XCTAssertThrowsError(try ARPlacementLayout(scene: outsideRig, origin: origin)) {
                    XCTAssertEqual($0 as? ARPlacementError, .outsideSupportedScene)
                }
            }
        }
    }

    func testNonzeroYawStillRotatesAndRejectsOutOfBounds() throws {
        let rig = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                camera: .init(x: 0, y: 1.5, z: 3), lights: [])
        let origin = Position(x: 0, y: 0.25, z: 0)
        let oblique = try ARPlacementLayout(scene: rig, origin: origin, yawDegrees: 45)
        let point = try XCTUnwrap(oblique.transform(position: .init(x: 1, y: 2, z: 1)))
        XCTAssertEqual(point.x, sqrt(2), accuracy: 1e-12)
        XCTAssertEqual(point.y, 2.25)
        XCTAssertEqual(point.z, 0, accuracy: 1e-12)
        XCTAssertNil(oblique.transform(position: .init(x: 100, y: 2, z: 100)))

        // A cosine rounded to one must not erase the nonzero sine of a small yaw.
        let smallYaw = try ARPlacementLayout(scene: rig, origin: origin, yawDegrees: 1e-9)
        let shifted = try XCTUnwrap(smallYaw.transform(position: .init(x: 1, y: 2, z: 1)))
        XCTAssertGreaterThan(shifted.x, 1)
        XCTAssertLessThan(shifted.z, 1)
        XCTAssertNil(smallYaw.transform(position: .init(x: 100, y: 2, z: 1)))
    }

    func testIdentityStillRejectsInvalidSourceCoordinatesAndModifierOverhang() throws {
        let subject = Position(x: -99.8, y: 1.5, z: 0)
        let origin = Position(x: subject.x, y: 0, z: subject.z)
        let rig = LightingScene(subject: subject, camera: subject, lights: [])
        let layout = try ARPlacementLayout(scene: rig, origin: origin)
        for outsideValue in [Double(100).nextUp, Double(-100).nextDown] {
            for axis in [\Position.x, \Position.y, \Position.z] {
                var outside = Position(x: 0, y: 0, z: 0)
                outside[keyPath: axis] = outsideValue
                XCTAssertNil(layout.transform(position: outside))
            }
        }

        let outsideFace = scene(subject: subject, camera: subject,
            light: .init(x: Double(99.5).nextUp, y: 2, z: 0),
            optics: .init(kind: .rectangle,
                          aimTarget: .init(x: Double(99.5).nextUp, y: 2, z: -1),
                          widthMeters: 1, heightMeters: 1))
        XCTAssertThrowsError(try ARPlacementLayout(scene: outsideFace, origin: origin)) {
            XCTAssertEqual($0 as? ARPlacementError, .outsideSupportedScene)
        }
    }
}
