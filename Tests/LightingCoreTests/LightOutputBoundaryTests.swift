import XCTest
@testable import LightingCore

final class LightOutputBoundaryTests: XCTestCase {
    private func fixture(kind: EmitterKind = .rectangle, width: Double = 0.1,
                         candela: Double = 400) -> (StudioLight, LightingScene) {
        let light = StudioLight(name: "Boundary source", position: .init(x: 0, y: 0, z: 3),
                                candela: candela, kelvin: 5600,
                                optics: .init(kind: kind, widthMeters: width, heightMeters: width))
        let scene = LightingScene(subject: .init(x: 0, y: 0, z: 0),
                                  camera: .init(x: 0, y: 0, z: 4), lights: [light])
        return (light, scene)
    }

    private func maximumLux(for source: StudioLight, in scene: LightingScene) throws -> Double {
        var maximum = source
        maximum.candela = 100_000
        XCTAssertTrue(maximum.isValid)
        return try XCTUnwrap(StudioPhotometry.illuminance(for: maximum, in: scene))
    }

    func testLowerOutputReachesExactlyAchievableMaximumDespiteInverseRounding() throws {
        let (source, scene) = fixture()
        let originalScene = scene
        let target = try maximumLux(for: source, in: scene)
        var unit = source
        unit.candela = 1
        let unitLux = try XCTUnwrap(StudioPhotometry.illuminance(for: unit, in: scene))
        XCTAssertGreaterThan(target / unitLux, 100_000, "Exercise the rounded-out inverse boundary")

        let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)

        var expected = source
        expected.candela = 100_000
        XCTAssertEqual(adjusted, expected, "Only candela may change; identity and geometry must survive")
        XCTAssertEqual(StudioPhotometry.illuminance(for: adjusted, in: scene), target)
        XCTAssertEqual(source.candela, 400)
        XCTAssertEqual(scene, originalScene)
    }

    func testTargetImmediatelyBelowMaximumRemainsAchievable() throws {
        let (source, scene) = fixture()
        let target = try maximumLux(for: source, in: scene).nextDown
        let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)
        let achieved = try XCTUnwrap(StudioPhotometry.illuminance(for: adjusted, in: scene))

        XCTAssertTrue(adjusted.isValid)
        XCTAssertGreaterThan(adjusted.candela, source.candela)
        XCTAssertLessThanOrEqual(abs(achieved / target - 1), 1e-9)
    }

    func testAnyLuxAboveActualMaximumIsRejectedAcrossEmitterKinds() throws {
        for kind in EmitterKind.allCases {
            for width in [0.1, 0.6, 1.2] {
                let (source, scene) = fixture(kind: kind, width: width)
                let maximum = try maximumLux(for: source, in: scene)
                for target in [maximum.nextUp, maximum * 1.01] {
                    XCTAssertThrowsError(try LightOutputAdjustment.light(source, targetingLux: target, in: scene),
                                         "\(kind), width \(width), target \(target)") { error in
                        XCTAssertEqual(error as? LightOutputAdjustmentError, .outputOutOfRange)
                    }
                }
            }
        }
    }

    func testAlreadyExactMaximumSettingIsPreserved() throws {
        let (source, scene) = fixture(candela: 100_000)
        let target = try maximumLux(for: source, in: scene)
        XCTAssertEqual(try LightOutputAdjustment.light(source, targetingLux: target, in: scene), source)
    }

    func testOffSourceCanReachMaximum() throws {
        let (source, scene) = fixture(candela: 0)
        let target = try maximumLux(for: source, in: scene)
        let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)
        XCTAssertEqual(adjusted.candela, 100_000)
        XCTAssertEqual(adjusted.id, source.id)
        XCTAssertEqual(scene.lights[0].candela, 0)
    }

    func testZeroStillTurnsOffSourceWithoutSupportedGeometry() throws {
        var (source, scene) = fixture()
        source.position = scene.subject
        scene.lights = [source]
        XCTAssertNil(StudioPhotometry.illuminance(for: source, in: scene))

        let adjusted = try LightOutputAdjustment.light(source, targetingLux: 0, in: scene)
        var expected = source
        expected.candela = 0
        XCTAssertEqual(adjusted, expected)
    }

    func testRepresentableSubnormalTargetNoLongerLostInIntegration() throws {
        let (source, scene) = fixture()
        let target = Double.leastNonzeroMagnitude
        let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)
        XCTAssertTrue(adjusted.isValid)
        XCTAssertGreaterThan(adjusted.candela, 0)
        XCTAssertEqual(StudioPhotometry.illuminance(for: adjusted, in: scene), target)
    }

    func testTrulyUnrepresentableSubnormalTargetStillRejectsOutputUnderflow() {
        var (source, scene) = fixture(kind: .point)
        source.position.z = 0.05
        scene.lights = [source]
        // At 5 cm the unit-source coefficient is 400. The required candela
        // for one lux ULP is below Double.leastNonzeroMagnitude.
        XCTAssertThrowsError(try LightOutputAdjustment.light(source, targetingLux: .leastNonzeroMagnitude,
                                                            in: scene)) { error in
            XCTAssertEqual(error as? LightOutputAdjustmentError, .outputOutOfRange)
        }
    }

    func testAlreadyAchievedSubnormalTargetPreservesExactSourceDespiteInverseRounding() throws {
        let (source, scene) = fixture(candela: 499 * 1e-320)
        let target = try XCTUnwrap(StudioPhotometry.illuminance(for: source, in: scene))
        XCTAssertGreaterThan(target, 0)
        XCTAssertLessThan(target, Double.leastNormalMagnitude)
        let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)
        XCTAssertEqual(adjusted, source)
        XCTAssertEqual(StudioPhotometry.illuminance(for: adjusted, in: scene), target)
        XCTAssertEqual(scene.lights, [source])
    }

    func testOrdinaryInteriorTargetRetainsRequiredAccuracy() throws {
        let (source, scene) = fixture()
        let target = 250.0
        let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)
        let achieved = try XCTUnwrap(StudioPhotometry.illuminance(for: adjusted, in: scene))
        XCTAssertTrue(adjusted.isValid)
        XCTAssertLessThanOrEqual(abs(achieved / target - 1), 1e-9)
    }
}
