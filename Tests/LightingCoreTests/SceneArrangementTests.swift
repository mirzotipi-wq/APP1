import Foundation
import XCTest
import LightingCore

final class SceneArrangementTests: XCTestCase {
    private func scene(subject: Position = .init(x: 0, y: 1.5, z: 0),
                       camera: Position? = nil, light: Position,
                       optics: LightOptics? = nil) -> LightingScene {
        .init(subject: subject,
              camera: camera ?? .init(x: subject.x, y: subject.y, z: subject.z + 3),
              lights: [.init(name: "Key", position: light, candela: 900, kelvin: 5600,
                             optics: optics)])
    }

    func testRotationCanLeaveBoundsBeforeMovingToTheFinalSubject() throws {
        for sign in [-1.0, 1.0] {
            let original = scene(subject: .init(x: sign * 99, y: 1.5, z: 0),
                                 light: .init(x: sign * 90, y: 2, z: 0))
            XCTAssertThrowsError(try SceneTransform.rotatingLights(original, byDegrees: 180)) {
                XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
            }

            let arranged = try SceneTransform.arranged(original,
                subjectAt: .init(x: 0, y: 1.5, z: 0), rotatingLightsByDegrees: 180)
            var expected = original
            expected.subject = .init(x: 0, y: 1.5, z: 0)
            expected.camera = .init(x: 0, y: 1.5, z: 3)
            expected.lights[0].position = .init(x: sign * 9, y: 2, z: 0)
            XCTAssertEqual(arranged, expected)
        }
    }

    func testTranslatingFirstWouldAlsoRejectAValidFinalArrangement() throws {
        for sign in [-1.0, 1.0] {
            let original = scene(light: .init(x: sign * 9, y: 2, z: 0))
            XCTAssertThrowsError(try SceneTransform.translated(original,
                by: .init(x: sign * 99, y: 0, z: 0))) {
                XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
            }

            let arranged = try SceneTransform.arranged(original,
                subjectAt: .init(x: sign * 99, y: 1.5, z: 0), rotatingLightsByDegrees: 180)
            XCTAssertEqual(arranged.subject, .init(x: sign * 99, y: 1.5, z: 0))
            XCTAssertEqual(arranged.camera, .init(x: sign * 99, y: 1.5, z: 3))
            XCTAssertEqual(arranged.lights[0].position, .init(x: sign * 90, y: 2, z: 0))
        }
    }

    func testFractionalCardinalAndMirrorArrangementsRespectTheFinalBoundary() throws {
        typealias HorizontalPoint = (x: Double, z: Double)
        let cases: [(center: HorizontalPoint, camera: HorizontalPoint,
                     light: HorizontalPoint, degrees: Double, mirror: Bool)] = [
            ((0.3, 0), (0.3, 1), (99.7, 0), 0, false),
            ((0, 0.3), (1, 0.3), (0, 99.7), 90, false),
            ((99.7, 0), (99.7, 1), (0.3, 0), 180, false),
            ((0, 99.7), (1, 99.7), (0, 0.3), 270, false),
            ((99.7, 0), (99.7, 1), (0.3, 0), 0, true),
            ((0, 99.7), (0, 98.7), (0, 0.3), 90, true),
            ((0.3, 0), (0.3, 1), (99.7, 0), 180, true),
            ((0, 0.3), (0, 1.3), (0, 99.7), 270, true),
            ((0.3, 0.3), (1.3, 1.3), (0.3, 99.7), 0, true),
            ((99.7, 99.7), (98.7, 98.7), (0.3, 99.7), 90, true),
            ((99.7, 99.7), (98.7, 98.7), (99.7, 0.3), 180, true),
            ((0.3, 0.3), (1.3, 1.3), (99.7, 0.3), 270, true),
            ((-99.7, 99.7), (-98.7, 98.7), (-99.7, 0.3), 0, true),
            ((0.3, -0.3), (1.3, -1.3), (99.7, -0.3), 90, true),
            ((-0.3, 0.3), (-1.3, 1.3), (-0.3, 99.7), 180, true),
            ((99.7, -99.7), (98.7, -98.7), (0.3, -99.7), 270, true)
        ]
        // Every row reduces algebraically to destination + 99.7 - 0.3.
        // For these binary Double inputs, the inside sum is exactly
        // 100 - 129 * 2^-54, just below the halfway point 100 - 128 * 2^-54.
        // The outside sum is 100 + 231 * 2^-54, which rounds to 100.nextUp.
        let inside = 0.59999999999999
        let outside = 0.60000000000001
        for sign in [-1.0, 1.0] {
            for swapAxes in [false, true] {
                func position(_ point: HorizontalPoint, y: Double) -> Position {
                    .init(x: sign * (swapAxes ? point.z : point.x), y: y,
                          z: sign * (swapAxes ? point.x : point.z))
                }
                for (index, item) in cases.enumerated() {
                    let context = "case \(index), sign \(sign), swapped axes \(swapAxes)"
                    let original = scene(subject: position(item.center, y: 1.5),
                        camera: position(item.camera, y: 1.5),
                        light: position(item.light, y: 2),
                        optics: .init(kind: .point, aimTarget: position(item.light, y: 1)))
                    let degrees = swapAxes ? -item.degrees : item.degrees
                    let destination = position((inside, 0), y: 1.5)
                    let arranged = try SceneTransform.arranged(original, subjectAt: destination,
                        rotatingLightsByDegrees: degrees, mirroringLights: item.mirror)
                    XCTAssertEqual(arranged.subject, destination, context)
                    XCTAssertEqual(arranged.lights[0].position,
                                   position((Double(100).nextDown, 0), y: 2), context)
                    XCTAssertEqual(arranged.lights[0].optics?.aimTarget,
                                   position((Double(100).nextDown, 0), y: 1), context)

                    let outsideDestination = position((outside, 0), y: 1.5)
                    for aimOnly in [false, true] {
                        var candidate = original
                        if aimOnly { candidate.lights[0].position = position(item.center, y: 2) }
                        XCTAssertThrowsError(try SceneTransform.arranged(candidate,
                            subjectAt: outsideDestination, rotatingLightsByDegrees: degrees,
                            mirroringLights: item.mirror), context) {
                            XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene, context)
                        }
                    }
                }
            }
        }
    }

    func testCameraHeightAndStoredAimTranslationRoundFromOriginalCoordinates() throws {
        for sign in [-1.0, 1.0] {
            func position(_ coordinate: Double) -> Position {
                .init(x: sign * coordinate, y: sign * coordinate, z: sign * coordinate)
            }
            let original = scene(subject: position(0.3), camera: position(99.7),
                light: position(99.7), optics: .init(kind: .point, aimTarget: position(99.7)))
            let destination = position(0.59999999999999)
            let arranged = try SceneTransform.arranged(original, subjectAt: destination)
            let expected = position(Double(100).nextDown)
            XCTAssertEqual(arranged.subject, destination)
            XCTAssertEqual(arranged.camera, expected)
            XCTAssertEqual(arranged.lights[0].position, expected)
            XCTAssertEqual(arranged.lights[0].optics?.aimTarget, expected)

            // Isolate camera validity from light and aim validity at each boundary.
            var cameraOnly = original
            cameraOnly.lights[0].position = original.subject
            cameraOnly.lights[0].optics?.aimTarget = original.subject
            let overhang = sign * 0.60000000000001
            for outsideDestination in [Position(x: overhang, y: destination.y, z: destination.z),
                                       Position(x: destination.x, y: overhang, z: destination.z),
                                       Position(x: destination.x, y: destination.y, z: overhang)] {
                XCTAssertThrowsError(try SceneTransform.arranged(cameraOnly,
                    subjectAt: outsideDestination)) {
                    XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                }
            }
        }
    }

    func testArrangementRetainsTinyTermsOnBothSidesOfBoundaryHalfULP() throws {
        let halfULP = 0x1p-47
        let tiny = 0x1p-100
        let cases: [(input: Double, tail: Double, result: Double?)] = [
            (100, -tiny, 100), (100, 0, 100), (100, tiny, nil),
            (Double(100).nextDown, -tiny, Double(100).nextDown),
            (Double(100).nextDown, 0, 100), (Double(100).nextDown, tiny, 100)
        ]
        for sign in [-1.0, 1.0] {
            for degrees in [0.0, 180.0] {
                let direction = degrees == 0 ? 1.0 : -1.0
                for item in cases {
                    let center = Position(x: -sign * direction * item.tail, y: 1.5, z: 0)
                    let point = Position(x: sign * direction * item.input, y: 2, z: 0)
                    for aimOnly in [false, true] {
                        let original = scene(subject: center,
                            light: aimOnly ? center : point,
                            optics: aimOnly ? .init(kind: .point, aimTarget: point) : nil)
                        let destination = Position(x: sign * halfULP, y: 1.5, z: 0)
                        // Exact final x is sign * (input + 2^-47 + tail).
                        // The +/-2^-100 term must survive until final rounding.
                        guard let result = item.result else {
                            XCTAssertThrowsError(try SceneTransform.arranged(original,
                                subjectAt: destination, rotatingLightsByDegrees: degrees)) {
                                XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                            }
                            continue
                        }
                        let arranged = try SceneTransform.arranged(original,
                            subjectAt: destination, rotatingLightsByDegrees: degrees)
                        let actual = aimOnly ? arranged.lights[0].optics?.aimTarget : arranged.lights[0].position
                        XCTAssertEqual(actual, .init(x: sign * result, y: 2, z: 0))
                    }
                }
            }
        }
    }

    func testUnderflowedProductTailChoosesTheCorrectSideOfTheSceneBoundary() throws {
        let tiny = Double.leastNonzeroMagnitude
        let cases: [(tail: Double, lightX: Double, isOutside: Bool)] = [
            (-1, 64, false), (0, 64, false), (1, 64, true),
            (-1, Double(64).nextUp, true)
        ]
        // At 45 degrees the computed coefficients are
        // c = 0x1.6a09e667f3bcdp-1 and s = 0x1.6a09e667f3bccp-1.
        // For lightX = 64, exact x = 100 + 2^-47 + tail * 2^-1127.
        // The positive tail lies outside even though each FMA residual
        // underflows to zero. The negative tail and exact tie round to 100.
        for sign in [-1.0, 1.0] {
            for swapAxes in [false, true] {
                func position(_ x: Double, _ z: Double, y: Double) -> Position {
                    .init(x: sign * (swapAxes ? z : x), y: y,
                          z: sign * (swapAxes ? x : z))
                }
                for item in cases {
                    let center = position(-item.tail * tiny, item.tail * tiny, y: 1.5)
                    let camera = position(-item.tail * tiny, 3, y: 1.5)
                    for aimOnly in [false, true] {
                        let original = scene(subject: center, camera: camera,
                            light: aimOnly ? center : position(item.lightX, -64, y: 2),
                            optics: aimOnly ? .init(kind: .point,
                                aimTarget: position(item.lightX, -64, y: 1)) : nil)
                        let destination = position(100, 0, y: 1.5)
                        if item.isOutside {
                            XCTAssertThrowsError(try SceneTransform.arranged(original,
                                subjectAt: destination, rotatingLightsByDegrees: swapAxes ? -45 : 45)) {
                                XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                            }
                        } else {
                            let arranged = try SceneTransform.arranged(original,
                                subjectAt: destination, rotatingLightsByDegrees: swapAxes ? -45 : 45)
                            let actual = aimOnly ? try XCTUnwrap(arranged.lights[0].optics?.aimTarget)
                                : arranged.lights[0].position
                            XCTAssertEqual(swapAxes ? actual.z : actual.x, sign * 100)
                            XCTAssertEqual(arranged.subject, destination)
                        }
                    }
                }
            }
        }
    }

    func testSubnormalProductsRoundOnceThroughRotationAndGeneralMirror() throws {
        let tiny = Double.leastNonzeroMagnitude
        let cases: [(x: Double, z: Double, rotatedX: Double, rotatedZ: Double,
                     mirroredX: Double, mirroredZ: Double)] = [
            (1, 1, 1, 0, -0.0, 1), (1, -1, 0, -1, -1, -0.0),
            (0, 1, 1, 1, 0, 1), (1, 0, 1, -1, -1, 0),
            (2, 0, 1, -1, -2, 1), (3, 0, 2, -2, -3, 1), (4, 0, 3, -3, -4, 2)
        ]
        // Entries are integer multiples of the smallest subnormal, obtained
        // from exact binary products of the 45-degree coefficients and, when
        // mirrored, diagonal = Double(-7/25), cross = Double(24/25).
        // For (1, 1), rounding each product early incorrectly gives 2 instead
        // of 1. A mirror also exercises products with three binary64 factors.
        for sign in [-1.0, 1.0] {
            for mirror in [false, true] {
                for item in cases {
                    let point = Position(x: sign * item.x * tiny, y: 2, z: sign * item.z * tiny)
                    let original = scene(camera: .init(x: 3, y: 1.5, z: 4), light: point,
                        optics: .init(kind: .point,
                            aimTarget: .init(x: point.x, y: 1, z: point.z)))
                    let arranged = try SceneTransform.arranged(original, subjectAt: original.subject,
                        rotatingLightsByDegrees: 45, mirroringLights: mirror)
                    let expectedX = sign * (mirror ? item.mirroredX : item.rotatedX) * tiny
                    let expectedZ = sign * (mirror ? item.mirroredZ : item.rotatedZ) * tiny
                    for actual in [arranged.lights[0].position,
                                   try XCTUnwrap(arranged.lights[0].optics?.aimTarget)] {
                        XCTAssertEqual(actual.x.bitPattern, expectedX.bitPattern)
                        XCTAssertEqual(actual.z.bitPattern, expectedZ.bitPattern)
                    }
                }
            }
        }
    }

    func testUnderflowFallbackRoundsSubnormalTiesAndCarriesIntoTheNormalRange() throws {
        let tiny = Double.leastNonzeroMagnitude
        let normal = Double.leastNormalMagnitude
        let cases: [(destination: Double, multiple: Double, tail: Double, expected: Double)] = [
            (0, 1, -1, 0), (0, 1, 0, 0), (0, 1, 1, tiny),
            (0, 3, -1, tiny), (0, 3, 0, 2 * tiny), (0, 3, 1, 2 * tiny),
            (0, 5, -1, 2 * tiny), (0, 5, 0, 2 * tiny), (0, 5, 1, 3 * tiny),
            (normal, 1, -1, normal), (normal, 1, 0, normal), (normal, 1, 1, normal.nextUp),
            (normal.nextDown, 1, -1, normal.nextDown),
            (normal.nextDown, 1, 0, normal), (normal.nextDown, 1, 1, normal)
        ]
        // Since c - s = 2^-53, exact x is destination + multiple * 2^-1075
        // + tail * 2^-1127. These include even/odd subnormal ties, their two
        // neighboring sides, and rounding up from the largest subnormal.
        for sign in [-1.0, 1.0] {
            for item in cases {
                let center = Position(x: -sign * item.tail * tiny, y: 1.5, z: sign * item.tail * tiny)
                let point = Position(x: sign * item.multiple * normal, y: 2,
                                     z: -sign * item.multiple * normal)
                let original = scene(subject: center, light: point,
                    optics: .init(kind: .point, aimTarget: .init(x: point.x, y: 1, z: point.z)))
                let arranged = try SceneTransform.arranged(original,
                    subjectAt: .init(x: sign * item.destination, y: 1.5, z: 0), rotatingLightsByDegrees: 45)
                let expected = sign * item.expected
                XCTAssertEqual(arranged.lights[0].position.x.bitPattern, expected.bitPattern)
                XCTAssertEqual(try XCTUnwrap(arranged.lights[0].optics?.aimTarget).x.bitPattern,
                               expected.bitPattern)
            }
        }
    }

    func testUnderflowFallbackBoundsTheFullFiniteDestinationRange() throws {
        let tiny = Double.leastNonzeroMagnitude
        let original = scene(camera: .init(x: tiny, y: 1.5, z: 1),
                             light: .init(x: tiny, y: 2, z: tiny))
        // The computed sine is tiny and mirror cross is 2 * tiny, so the
        // expanded polynomial contains 2^-3221. A greatest-finite destination
        // exercises the full 67-limb span before ordinary scene validation.
        let arranged = try SceneTransform.arranged(original, subjectAt: original.subject,
            rotatingLightsByDegrees: 0x1p-1068, mirroringLights: true)
        XCTAssertEqual(arranged.lights[0].position, .init(x: -tiny, y: 2, z: tiny))
        for sign in [-1.0, 1.0] {
            for destination in [Position(x: sign * Double.greatestFiniteMagnitude, y: 1.5, z: 0),
                                Position(x: 0, y: 1.5, z: sign * Double.greatestFiniteMagnitude)] {
                XCTAssertThrowsError(try SceneTransform.arranged(original, subjectAt: destination,
                    rotatingLightsByDegrees: 0x1p-1068, mirroringLights: true)) {
                    XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                }
            }
        }
    }

    func testMirrorCanBringAnIntermediateRotationBackInsideWithoutTranslation() throws {
        let original = scene(subject: .init(x: 99, y: 1.5, z: 0),
                             light: .init(x: 90, y: 2, z: 0))
        let arranged = try SceneTransform.arranged(original, subjectAt: original.subject,
            rotatingLightsByDegrees: 180, mirroringLights: true)
        XCTAssertEqual(arranged, original)
    }

    func testRotationThenMirrorPreservesCameraAimsIdentityAndRoomContext() throws {
        let original = LightingScene(subject: .init(x: 2, y: 1.5, z: -3),
            camera: .init(x: 2, y: 2.5, z: 0), lights: [
                .init(name: "Manual aim", position: .init(x: 3, y: 3, z: -1),
                      candela: 1234, kelvin: 4300,
                      optics: .init(kind: .rectangle, aimTarget: .init(x: 1, y: 1, z: -2),
                                    widthMeters: 1.2, heightMeters: 0.7, rollDegrees: 37)),
                .init(name: "Subject aim", position: .init(x: 0, y: 2, z: -4),
                      candela: 345, kelvin: 6100, optics: .init(kind: .directional)),
                .init(name: "Legacy point", position: .init(x: 2, y: 2, z: 0),
                      candela: 0, kelvin: 3200)
            ], cameraLens: .init(focalLengthMillimeters: 85),
            previewSettings: .init(whiteBalanceKelvin: 4100, exposureStops: 1.25),
            placementRoom: .init(widthMeters: 6, depthMeters: 9, subjectX: 2, subjectZ: 3,
                                 yawDegrees: 37, ceilingHeightMeters: 4))

        let arranged = try SceneTransform.arranged(original,
            subjectAt: .init(x: 10, y: 2.5, z: 5),
            rotatingLightsByDegrees: 90, mirroringLights: true)
        var expected = original
        expected.subject = .init(x: 10, y: 2.5, z: 5)
        expected.camera = .init(x: 10, y: 3.5, z: 8)
        expected.lights[0].position = .init(x: 8, y: 4, z: 4)
        expected.lights[0].optics?.aimTarget = .init(x: 9, y: 2, z: 6)
        expected.lights[0].optics?.rollDegrees = -37
        expected.lights[1].position = .init(x: 11, y: 3, z: 7)
        expected.lights[2].position = .init(x: 7, y: 3, z: 5)
        XCTAssertEqual(arranged, expected)
        XCTAssertEqual(arranged.lights.map(\.id), original.lights.map(\.id))
        XCTAssertEqual(arranged.lights[1].target(subject: arranged.subject), arranged.subject)
        XCTAssertNil(arranged.lights[1].optics?.aimTarget)
        XCTAssertNil(arranged.lights[2].optics)
        XCTAssertEqual(try XCTUnwrap(CameraFraming(scene: arranged)).forward,
                       try XCTUnwrap(CameraFraming(scene: original)).forward)
    }

    func testInvalidFinalLightCameraAimOrSubjectRejectsTheWholeArrangement() throws {
        let cases: [(source: LightingScene, destination: Position, rotation: Double)] = [
            (scene(subject: .init(x: 99, y: 1.5, z: 0), light: .init(x: 90, y: 2, z: 0)),
             .init(x: 95, y: 1.5, z: 0), 180),
            (scene(camera: .init(x: 3, y: 1.5, z: 0), light: .init(x: 0, y: 2, z: 0)),
             .init(x: 99, y: 1.5, z: 0), 90),
            (scene(light: .init(x: 1, y: 2, z: 0),
                   optics: .init(kind: .point, aimTarget: .init(x: 10, y: 1, z: 0))),
             .init(x: 99, y: 1.5, z: 0), 0),
            (scene(light: .init(x: 0, y: 2, z: 0)), .init(x: 101, y: 1.5, z: 0), 0)
        ]
        for item in cases {
            var current = item.source
            XCTAssertNoThrow(try current.validated())
            XCTAssertThrowsError(try {
                current = try SceneTransform.arranged(current, subjectAt: item.destination,
                                                      rotatingLightsByDegrees: item.rotation)
            }()) {
                XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
            }
            XCTAssertEqual(current, item.source)
        }
    }

    func testInvalidSourceCannotBeRepairedByAnArrangement() throws {
        let invalid = scene(light: .init(x: 101, y: 2, z: 0))
        // Moving left would bring every resulting coordinate into range, but
        // the input must still be validated before any geometry is transformed.
        XCTAssertThrowsError(try SceneTransform.arranged(invalid,
            subjectAt: .init(x: -2, y: 1.5, z: 0))) {
            XCTAssertEqual($0 as? SceneError, .invalidLight)
        }
        var unsupported = scene(light: .init(x: 1, y: 2, z: 0))
        unsupported.schemaVersion = LightingScene.currentSchemaVersion + 1
        XCTAssertThrowsError(try SceneTransform.arranged(unsupported,
            subjectAt: unsupported.subject)) {
            XCTAssertEqual($0 as? SceneError, .unsupportedVersion)
        }
    }

    func testNonfiniteTransformInputsAreRejected() throws {
        let original = scene(light: .init(x: 1, y: 2, z: 0))
        for value in [Double.nan, .infinity, -.infinity] {
            XCTAssertThrowsError(try SceneTransform.arranged(original,
                subjectAt: original.subject, rotatingLightsByDegrees: value)) {
                XCTAssertEqual($0 as? SceneTransformError, .invalidTransform)
            }
            for destination in [Position(x: value, y: 1.5, z: 0),
                                Position(x: 0, y: value, z: 0),
                                Position(x: 0, y: 1.5, z: value)] {
                XCTAssertThrowsError(try SceneTransform.arranged(original, subjectAt: destination)) {
                    XCTAssertEqual($0 as? SceneTransformError, .invalidTransform)
                }
            }
        }
    }

    func testMirroringStillRequiresAHorizontalCameraDirection() throws {
        let original = scene(camera: .init(x: 0, y: 5, z: 0), light: .init(x: 1, y: 2, z: 0))
        let destination = Position(x: 4, y: 2.5, z: 3)
        XCTAssertNoThrow(try SceneTransform.arranged(original, subjectAt: destination,
            rotatingLightsByDegrees: 90))
        XCTAssertThrowsError(try SceneTransform.arranged(original, subjectAt: destination,
            rotatingLightsByDegrees: 90, mirroringLights: true)) {
            XCTAssertEqual($0 as? SceneTransformError, .undefinedCameraDirection)
        }
    }

    func testQuarterTurnsAndDiagonalMirrorsKeepExactBoundaryCoordinates() throws {
        let original = scene(light: .init(x: 100, y: 2, z: 1),
                             optics: .init(kind: .point, aimTarget: .init(x: -100, y: 1, z: -1)))
        let turns: [(degrees: Double, x: Double, z: Double)] = [
            (0, 100, 1), (360, 100, 1), (90, 1, -100), (-270, 1, -100),
            (180, -100, -1), (-180, -100, -1), (270, -1, 100), (-90, -1, 100)
        ]
        for turn in turns {
            let arranged = try SceneTransform.arranged(original, subjectAt: original.subject,
                rotatingLightsByDegrees: turn.degrees)
            XCTAssertEqual(arranged.lights[0].position, .init(x: turn.x, y: 2, z: turn.z))
            XCTAssertEqual(arranged.lights[0].optics?.aimTarget,
                           .init(x: -turn.x, y: 1, z: -turn.z))
        }

        let diagonal = scene(camera: .init(x: 1, y: 1.5, z: 1),
                             light: .init(x: -99.8, y: 2, z: 100),
                             optics: .init(kind: .point, aimTarget: .init(x: 100, y: 1, z: -99.8)))
        let mirrored = try SceneTransform.arranged(diagonal, subjectAt: diagonal.subject,
                                                   mirroringLights: true)
        XCTAssertEqual(mirrored.lights[0].position, .init(x: 100, y: 2, z: -99.8))
        XCTAssertEqual(mirrored.lights[0].optics?.aimTarget, .init(x: -99.8, y: 1, z: 100))
    }

    func testOverheadRectangleKeepsItsFaceWhenIntermediateFramesAreOutsideBounds() throws {
        let original = scene(subject: .init(x: 99, y: 1.5, z: 0),
            light: .init(x: 90, y: 3, z: 9),
            optics: .init(kind: .rectangle, aimTarget: .init(x: 90, y: 1, z: 9),
                          widthMeters: 2, heightMeters: 1, rollDegrees: 37))
        let originalCorners = try corners(of: original.lights[0], subject: original.subject)
        for mirror in [false, true] {
            // The rotated light and aim both have x = 108 before the remaining
            // operations, so neither intermediate frame can use world bounds.
            let arranged = try SceneTransform.arranged(original,
                subjectAt: .init(x: 0, y: 2.5, z: 5),
                rotatingLightsByDegrees: 90, mirroringLights: mirror)
            XCTAssertEqual(arranged.lights[0].position, .init(x: mirror ? -9 : 9, y: 4, z: 14))
            XCTAssertEqual(arranged.lights[0].optics?.aimTarget,
                           .init(x: mirror ? -9 : 9, y: 2, z: 14))
            let actualCorners = try corners(of: arranged.lights[0], subject: arranged.subject)
            for corner in originalCorners {
                let expected = Position(x: mirror ? -corner.z : corner.z,
                                        y: corner.y + 1, z: 104 - corner.x)
                XCTAssertEqual(actualCorners.filter { $0.distance(to: expected) < 1e-12 }.count, 1)
            }
        }
    }

    func testGeneralRotationAndMirrorPreserveOverheadRectangleCorners() throws {
        var original = scene(subject: .init(x: 2, y: 1.5, z: -3),
            camera: .init(x: 5, y: 2.5, z: 1), light: .init(x: 5, y: 3, z: -1),
            optics: .init(kind: .rectangle, aimTarget: .init(x: 5, y: 1, z: -1),
                          widthMeters: 2, heightMeters: 1, rollDegrees: 37))
        original.lights.append(.init(name: "Subject aim", position: .init(x: 2, y: 3, z: -3),
            candela: 300, kelvin: 4300,
            optics: .init(kind: .rectangle, widthMeters: 1.5, heightMeters: 0.5, rollDegrees: -23)))
        let originalCorners = try original.lights.map { try corners(of: $0, subject: original.subject) }
        let destination = Position(x: 10, y: 2.5, z: 5)
        for mirror in [false, true] {
            // A 3-4-5 rotation has cos = 4/5 and sin = 3/5. Reflecting across
            // this camera's (3, 4) direction then gives rows (-4/5, 3/5), (3/5, 4/5).
            func expected(_ p: Position) -> Position {
                let x = p.x - 2, z = p.z + 3
                return .init(x: 10 + (mirror ? -0.8 : 0.8) * x + 0.6 * z,
                             y: p.y + 1, z: 5 + (mirror ? 0.6 : -0.6) * x + 0.8 * z)
            }
            let arranged = try SceneTransform.arranged(original, subjectAt: destination,
                rotatingLightsByDegrees: 36.86989764584402, mirroringLights: mirror)
            XCTAssertEqual(arranged.subject, destination)
            XCTAssertEqual(arranged.camera, .init(x: 13, y: 3.5, z: 9))
            for index in original.lights.indices {
                let light = arranged.lights[index]
                XCTAssertLessThan(light.position.distance(to: expected(original.lights[index].position)), 1e-12)
                if let originalAim = original.lights[index].optics?.aimTarget {
                    let aim = try XCTUnwrap(light.optics?.aimTarget)
                    XCTAssertLessThan(aim.distance(to: expected(originalAim)), 1e-12)
                } else {
                    XCTAssertNil(light.optics?.aimTarget)
                    XCTAssertEqual(light.target(subject: destination), destination)
                }
                let actualCorners = try corners(of: light, subject: destination)
                for corner in originalCorners[index] {
                    XCTAssertEqual(actualCorners.filter { $0.distance(to: expected(corner)) < 1e-12 }.count, 1)
                }
            }
        }
    }

    private func corners(of light: StudioLight, subject: Position) throws -> [Position] {
        let frame = try XCTUnwrap(StudioPhotometry.frame(for: light, subject: subject))
        let halfWidth = light.effectiveOptics.widthMeters / 2
        let halfHeight = light.effectiveOptics.heightMeters / 2
        return [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)].map { width, height in
            .init(x: light.position.x + width * halfWidth * frame.right.x + height * halfHeight * frame.up.x,
                  y: light.position.y + width * halfWidth * frame.right.y + height * halfHeight * frame.up.y,
                  z: light.position.z + width * halfWidth * frame.right.z + height * halfHeight * frame.up.z)
        }
    }
}
