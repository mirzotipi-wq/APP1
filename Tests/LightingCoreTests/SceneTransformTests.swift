import XCTest
import LightingCore

final class SceneTransformTests: XCTestCase {
    func testQuarterTurnAtTranslatedBoundaryPreservesPositionsAndAims() throws {
        for sign in [-1.0, 1.0] {
            for swapAxes in [false, true] {
                func position(_ x: Double, _ y: Double, _ z: Double) -> Position {
                    .init(x: sign * (swapAxes ? z : x), y: y,
                          z: sign * (swapAxes ? x : z))
                }
                let original = LightingScene(
                    subject: position(-99.8, -0.0, -99.8),
                    camera: position(0, -0.0, 0), lights: [
                        .init(name: "Boundary", position: position(-99.8, -0.0, 100),
                              candela: 900, kelvin: 5600,
                              optics: .init(kind: .point, aimTarget: position(-99.8, -0.0, 100)))
                    ], cameraLens: .init(focalLengthMillimeters: 85),
                    previewSettings: .init(whiteBalanceKelvin: 4100, exposureStops: 1.25),
                    placementRoom: .init(widthMeters: 6, depthMeters: 9, subjectX: 2,
                                         subjectZ: 3, yawDegrees: 37, ceilingHeightMeters: 4))
                XCTAssertNoThrow(try original.validated())
                var expected = original
                expected.lights[0].position = position(100, -0.0, -99.8)
                expected.lights[0].optics?.aimTarget = position(100, -0.0, -99.8)

                // Rounding the displacement first yields 100.00000000000001
                // from -99.8 + (100 - -99.8), although the exact result is 100.
                let rotated = try SceneTransform.rotatingLights(original,
                    byDegrees: swapAxes ? -90 : 90)
                XCTAssertEqual(rotated, expected)
                assertPositionBits(rotated.subject, original.subject)
                assertPositionBits(rotated.camera, original.camera)
                assertPositionBits(rotated.lights[0].position, expected.lights[0].position)
                assertPositionBits(try XCTUnwrap(rotated.lights[0].optics?.aimTarget),
                                   try XCTUnwrap(expected.lights[0].optics?.aimTarget))
            }
        }
    }

    func testQuarterTurnRejectsTheNextOutsidePositionOrAimAtomically() throws {
        for sign in [-1.0, 1.0] {
            for swapAxes in [false, true] {
                func position(_ x: Double, _ y: Double, _ z: Double) -> Position {
                    .init(x: sign * (swapAxes ? z : x), y: y,
                          z: sign * (swapAxes ? x : z))
                }
                let centerX = Double(-99.8).nextUp
                let subject = position(centerX, 1.5, -99.8)
                let outsideAfterRotation = position(centerX, 2, 100)
                for storedAim in [false, true] {
                    let original = LightingScene(subject: subject,
                        camera: position(0, 1.5, 0), lights: [
                            .init(name: "Unchanged", position: subject, candela: 300, kelvin: 4300),
                            .init(name: "Outside after rotation",
                                  position: storedAim ? subject : outsideAfterRotation,
                                  candela: 900, kelvin: 5600,
                                  optics: storedAim ? .init(kind: .point, aimTarget: outsideAfterRotation) : nil)
                        ])
                    XCTAssertNoThrow(try original.validated())
                    var current = original
                    // Shifting the pivot by one ULP makes the exact final
                    // coordinate 100.nextUp; accepting it would widen bounds.
                    XCTAssertThrowsError(try {
                        current = try SceneTransform.rotatingLights(current,
                            byDegrees: swapAxes ? -90 : 90)
                    }()) {
                        XCTAssertEqual($0 as? SceneTransformError, .outsideSupportedScene)
                    }
                    XCTAssertEqual(current, original)
                }
            }
        }
    }

    func testZeroAndFullTurnsPreserveAllPositionBits() throws {
        let tiny = Double.leastNonzeroMagnitude
        let original = LightingScene(subject: .init(x: -0.0, y: 1.5, z: 0.0),
            camera: .init(x: tiny, y: -0.0, z: 3), lights: [
                .init(name: "Raw bits", position: .init(x: -0.0, y: -0.0, z: tiny),
                      candela: 900, kelvin: 5600,
                      optics: .init(kind: .point, aimTarget: .init(x: 0.0, y: -0.0, z: -tiny),
                                    rollDegrees: -0.0))
            ])
        for angle in [0.0, -0.0, 360, -360, 720, -720] {
            let rotated = try SceneTransform.rotatingLights(original, byDegrees: angle)
            XCTAssertEqual(rotated, original)
            assertPositionBits(rotated.subject, original.subject)
            assertPositionBits(rotated.camera, original.camera)
            assertPositionBits(rotated.lights[0].position, original.lights[0].position)
            assertPositionBits(try XCTUnwrap(rotated.lights[0].optics?.aimTarget),
                               try XCTUnwrap(original.lights[0].optics?.aimTarget))
            XCTAssertEqual(try XCTUnwrap(rotated.lights[0].optics?.rollDegrees).bitPattern,
                           try XCTUnwrap(original.lights[0].optics?.rollDegrees).bitPattern)
        }
    }

    private func assertPositionBits(_ actual: Position, _ expected: Position,
                                    file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.x.bitPattern, expected.x.bitPattern, file: file, line: line)
        XCTAssertEqual(actual.y.bitPattern, expected.y.bitPattern, file: file, line: line)
        XCTAssertEqual(actual.z.bitPattern, expected.z.bitPattern, file: file, line: line)
    }
}
