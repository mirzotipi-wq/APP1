import XCTest
import LightingCore

final class SceneMirrorBoundaryTests: XCTestCase {
    private func scene(subject: Position = .init(x: 0, y: 1.5, z: 0),
                       camera: Position, position: Position,
                       optics: LightOptics? = nil) -> LightingScene {
        .init(subject: subject, camera: camera, lights: [
            .init(name: "Boundary light", position: position, candela: 900, kelvin: 5600,
                  optics: optics)
        ])
    }

    func testPositiveDiagonalSwapsBoundaryPositionsAndAimsWithoutCancellation() throws {
        for direction in [-1.0, 1.0] {
            let original = scene(camera: .init(x: direction, y: 8, z: direction),
                                 position: .init(x: -99.8, y: 2, z: 100),
                                 optics: .init(kind: .rectangle,
                                               aimTarget: .init(x: 100, y: 3, z: -99.8),
                                               widthMeters: 1.2, heightMeters: 0.8, rollDegrees: 37))
            var expected = original
            expected.lights[0].position = .init(x: 100, y: 2, z: -99.8)
            expected.lights[0].optics?.aimTarget = .init(x: -99.8, y: 3, z: 100)
            expected.lights[0].optics?.rollDegrees = -37
            let mirrored = try SceneTransform.mirroringLights(original)
            XCTAssertEqual(mirrored, expected)
            XCTAssertEqual(try SceneTransform.mirroringLights(mirrored), original)
        }
    }

    func testNegativeDiagonalReflectsBoundaryPositionsAndAimsWithoutCancellation() throws {
        for direction in [-1.0, 1.0] {
            let original = scene(camera: .init(x: direction, y: -3, z: -direction),
                                 position: .init(x: 99.8, y: 2, z: -100),
                                 optics: .init(kind: .rectangle,
                                               aimTarget: .init(x: -100, y: 3, z: 99.8),
                                               widthMeters: 1.2, heightMeters: 0.8, rollDegrees: -37))
            var expected = original
            expected.lights[0].position = .init(x: 100, y: 2, z: -99.8)
            expected.lights[0].optics?.aimTarget = .init(x: -99.8, y: 3, z: 100)
            expected.lights[0].optics?.rollDegrees = 37
            let mirrored = try SceneTransform.mirroringLights(original)
            XCTAssertEqual(mirrored, expected)
            XCTAssertEqual(try SceneTransform.mirroringLights(mirrored), original)
        }
    }

    func testDiagonalPreservesValuesImmediatelyInsideEitherBoundary() throws {
        for coordinate in [Double(-100).nextUp, Double(100).nextDown] {
            for slope in [-1.0, 1.0] {
                let original = scene(camera: .init(x: 1, y: 1.5, z: slope),
                                     position: .init(x: -0.1, y: 2, z: coordinate))
                let mirrored = try SceneTransform.mirroringLights(original)
                XCTAssertEqual(mirrored.lights[0].position,
                               .init(x: slope * coordinate, y: 2, z: slope * -0.1))
                XCTAssertEqual(try SceneTransform.mirroringLights(mirrored), original)
            }
        }
    }

    func testTranslatedDiagonalsAcceptBothExactBoundariesForPositionsAndAims() throws {
        let cases: [(x: Double, z: Double, slope: Double, lightZ: Double,
                     resultX: Double, resultZ: Double)] = [
            (7, 3, 1, 96, 100, -4),
            (3, 7, 1, -96, -100, 4),
            (7, 3, -1, -90, 100, 10),
            (-7, -3, -1, 90, -100, -10)
        ]
        for item in cases {
            let original = scene(subject: .init(x: item.x, y: 1.5, z: item.z),
                                 camera: .init(x: item.x + 1, y: 1.5, z: item.z + item.slope),
                                 position: .init(x: 0, y: 2, z: item.lightZ),
                                 optics: .init(kind: .point,
                                               aimTarget: .init(x: 0, y: 3, z: item.lightZ)))
            var expected = original
            expected.lights[0].position = .init(x: item.resultX, y: 2, z: item.resultZ)
            expected.lights[0].optics?.aimTarget = .init(x: item.resultX, y: 3, z: item.resultZ)
            XCTAssertEqual(try SceneTransform.mirroringLights(original), expected)
        }
    }

    func testTranslatedDiagonalPivotDoesNotAcquireRoundingFromItsWorldOffset() throws {
        // Naively forming the offset first computes 199.8 - 99.8 as
        // 100.00000000000001. A light above the subject must remain fixed.
        let cases: [(x: Double, z: Double, dx: Double, dz: Double)] = [
            (100, -99.8, -0.125, -0.125),
            (100, 99.8, -0.125, 0.125),
            (-100, 99.8, 0.125, 0.125),
            (-100, -99.8, 0.125, -0.125)
        ]
        for item in cases {
            let original = scene(subject: .init(x: item.x, y: 1.5, z: item.z),
                                 camera: .init(x: item.x + item.dx, y: 1.5, z: item.z + item.dz),
                                 position: .init(x: item.x, y: 2, z: item.z))
            XCTAssertEqual(try SceneTransform.mirroringLights(original), original)
        }
    }

    func testTranslatedDiagonalRejectsTinyTermBeyondBoundaryHalfULP() throws {
        let halfULP = 0x1p-47
        let tiny = 0x1p-100
        for sign in [-1.0, 1.0] {
            for slope in [-1.0, 1.0] {
                let subject = Position(x: sign * halfULP, y: 1.5, z: -sign * slope * tiny)
                let camera = Position(x: subject.x + 0.25, y: 1.5,
                                      z: subject.z + slope * 0.25)
                XCTAssertEqual(camera.x - subject.x, 0.25)
                XCTAssertEqual(camera.z - subject.z, slope * 0.25)
                for storedAim in [false, true] {
                    let point = Position(x: 0, y: 2, z: sign * slope * 100)
                    let original = scene(subject: subject, camera: camera,
                                         position: storedAim ? .init(x: 0, y: 2, z: 0) : point,
                                         optics: storedAim ? .init(kind: .point, aimTarget: point) : nil)
                    XCTAssertNoThrow(try original.validated())
                    // The exact x is ±(100 + 2^-47 + 2^-100), so it rounds
                    // one representable step outside even though 100 + 2^-47 ties to 100.
                    XCTAssertThrowsError(try SceneTransform.mirroringLights(original)) {
                        XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                    }
                }
            }
        }
    }

    func testTranslatedDiagonalRoundsBothSidesOfHalfULPForPositionsAndAims() throws {
        let halfULP = 0x1p-47
        let tiny = 0x1p-100
        let cases: [(input: Double, tail: Double, result: Double?)] = [
            (96, -tiny, 100),
            (96, 0, 100),
            (96, tiny, nil),
            (Double(96).nextDown, -tiny, Double(100).nextDown),
            (Double(96).nextDown, 0, 100),
            (Double(96).nextDown, tiny, 100)
        ]
        for sign in [-1.0, 1.0] {
            for slope in [-1.0, 1.0] {
                for item in cases {
                    let subject = Position(x: sign * (4 + halfULP), y: 1.5,
                                           z: -sign * slope * item.tail)
                    let original = scene(subject: subject,
                                         camera: .init(x: subject.x + 0.25, y: 1.5,
                                                       z: subject.z + slope * 0.25),
                                         position: .init(x: 0, y: 2, z: sign * slope * item.input),
                                         optics: .init(kind: .point,
                                                       aimTarget: .init(x: 0, y: 3,
                                                                        z: sign * slope * item.input)))
                    guard let result = item.result else {
                        XCTAssertThrowsError(try SceneTransform.mirroringLights(original)) {
                            XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                        }
                        continue
                    }
                    var expected = original
                    expected.lights[0].position = .init(x: sign * result, y: 2,
                                                        z: -slope * subject.x)
                    expected.lights[0].optics?.aimTarget = .init(x: sign * result, y: 3,
                                                                z: -slope * subject.x)
                    XCTAssertEqual(try SceneTransform.mirroringLights(original), expected)
                }
            }
        }
    }

    func testAxisReflectionPreservesTheUnchangedCoordinateExactly() throws {
        let cases: [(subject: Position, camera: Position, light: Position, result: Position)] = [
            (.init(x: 99.8, y: 1.5, z: 0), .init(x: 99, y: 1.5, z: 0),
             .init(x: 0.1, y: 2, z: -100), .init(x: 0.1, y: 2, z: 100)),
            (.init(x: 0, y: 1.5, z: 99.8), .init(x: 0, y: 1.5, z: 99),
             .init(x: -100, y: 2, z: 0.1), .init(x: 100, y: 2, z: 0.1))
        ]
        for item in cases {
            let original = scene(subject: item.subject, camera: item.camera, position: item.light)
            let mirrored = try SceneTransform.mirroringLights(original)
            XCTAssertEqual(mirrored.lights[0].position, item.result)
            XCTAssertEqual(try SceneTransform.mirroringLights(mirrored), original)
        }
    }

    func testTranslatedAxesAcceptBoundaryAndRejectTheNextOutsideValue() throws {
        for boundary in [-100.0, 100.0] {
            let center = boundary > 0 ? 7.0 : -7.0
            let input = 2 * center - boundary
            let outside = boundary > 0 ? input.nextDown : input.nextUp
            for alongX in [false, true] {
                let subject = Position(x: alongX ? 0 : center, y: 1.5,
                                       z: alongX ? center : 0)
                let camera = Position(x: subject.x + (alongX ? 1 : 0), y: 1.5,
                                      z: subject.z + (alongX ? 0 : 1))
                var original = scene(subject: subject, camera: camera,
                                     position: .init(x: alongX ? 0.1 : input, y: 2,
                                                     z: alongX ? input : 0.1))
                XCTAssertEqual(try SceneTransform.mirroringLights(original).lights[0].position,
                               .init(x: alongX ? 0.1 : boundary, y: 2,
                                     z: alongX ? boundary : 0.1))
                original.lights[0].position = .init(x: alongX ? 0.1 : outside, y: 2,
                                                    z: alongX ? outside : 0.1)
                XCTAssertThrowsError(try SceneTransform.mirroringLights(original)) {
                    XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                }
            }
        }
    }

    func testTranslatedDiagonalRejectsOneStepOutsideForPositionsAndStoredAimsAtomically() throws {
        let cases: [(x: Double, z: Double, slope: Double, outsideZ: Double)] = [
            (7, 3, 1, Double(96).nextUp),
            (3, 7, 1, Double(-96).nextDown),
            (7, 3, -1, Double(-90).nextDown),
            (-7, -3, -1, Double(90).nextUp)
        ]
        for item in cases {
            for storedAim in [false, true] {
                var original = scene(subject: .init(x: item.x, y: 1.5, z: item.z),
                                     camera: .init(x: item.x + 1, y: 1.5, z: item.z + item.slope),
                                     position: .init(x: item.x, y: 2, z: item.z))
                let outside = Position(x: 0, y: 3, z: item.outsideZ)
                original.lights.append(.init(name: "Outside after reflection",
                    position: storedAim ? original.lights[0].position : outside,
                    candela: 300, kelvin: 3200,
                    optics: storedAim ? .init(kind: .point, aimTarget: outside) : nil))
                let snapshot = original
                XCTAssertNoThrow(try original.validated())
                XCTAssertThrowsError(try SceneTransform.mirroringLights(original)) {
                    XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                }
                XCTAssertEqual(original, snapshot)
            }
        }
    }

    func testNearbyCameraDirectionsKeepStrictOutsideRejection() throws {
        let cases: [(camera: Position, light: Position)] = [
            (.init(x: 1, y: 1.5, z: Double(1).nextUp), .init(x: -99.8, y: 2, z: 100)),
            (.init(x: 1, y: 1.5, z: Double.ulpOfOne), .init(x: 100, y: 2, z: 100)),
            (.init(x: 2, y: 1.5, z: 1), .init(x: 60, y: 2, z: Double(80).nextUp))
        ]
        for item in cases {
            let original = scene(camera: item.camera, position: item.light)
            XCTAssertThrowsError(try SceneTransform.mirroringLights(original)) {
                XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
            }
        }
    }

    func testGenericReflectionAcceptsValidBoundaryPositionsAndStoredAims() throws {
        for sign in [-1.0, 1.0] {
            for storedAim in [false, true] {
                let subject = Position(x: sign, y: 1.5, z: 0)
                let point = Position(x: sign * -100, y: 2, z: sign * 48)
                let original = scene(subject: subject,
                                     camera: .init(x: sign * 2, y: 1.5, z: sign * 2),
                                     position: storedAim ? subject : point,
                                     optics: storedAim ? .init(kind: .point, aimTarget: point) : nil)
                XCTAssertNoThrow(try original.validated())
                // With the computed -0.6/0.8 coefficients, exact x is
                // sign * (100 - 2^-53). Forming (diagonal - 1) first instead
                // produces sign * 100.00000000000003 and rejects a valid point.
                let reflected = Position(x: sign * 100, y: point.y,
                                         z: sign * Double(-52).nextDown)
                var expected = original
                if storedAim { expected.lights[0].optics?.aimTarget = reflected }
                else { expected.lights[0].position = reflected }
                XCTAssertEqual(try SceneTransform.mirroringLights(original), expected)
                XCTAssertEqual(try SceneTransform.arranged(original, subjectAt: subject,
                                                          mirroringLights: true), expected)
            }
        }
    }

    func testGenericReflectionRejectsOutsidePositionsAndStoredAimsAtomically() throws {
        for sign in [-1.0, 1.0] {
            for storedAim in [false, true] {
                var original = scene(camera: .init(x: sign, y: 1.5, z: sign * 2),
                                     position: .init(x: 0, y: 2, z: 0))
                let point = Position(x: sign * -81, y: 3,
                                     z: sign * Double(64.25).nextUp)
                original.lights.append(.init(name: "Outside after reflection",
                    position: storedAim ? original.lights[0].position : point,
                    candela: 300, kelvin: 3200,
                    optics: storedAim ? .init(kind: .point, aimTarget: point) : nil))
                let snapshot = original
                XCTAssertNoThrow(try original.validated())
                // The exact computed-coefficient x rounds to sign * 100.nextUp.
                // Intermediate rounding used to lose that excess and accept 100.
                XCTAssertThrowsError(try SceneTransform.mirroringLights(original)) {
                    XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                }
                XCTAssertEqual(original, snapshot)
            }
        }
    }
}
