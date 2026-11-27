import XCTest
@testable import LightingCore

final class LightOutputAttainableRoundTripTests: XCTestCase {
    func testObliqueInteriorTargetsRoundTripAcrossEmitterKinds() throws {
        // This checks solver/forward-model consistency, not independent photometric accuracy.
        // Each reference intensity is strictly inside the supported candela range.
        let fixtures: [(source: StudioLight, referenceCandela: Double)] = [
            (.init(name: "Oblique point", position: .init(x: -1.65, y: 2.7, z: 2.4),
                   candela: 860, kelvin: 4700,
                   optics: .init(kind: .point)), 37.25),
            (.init(name: "Manually aimed directional", position: .init(x: 2.4, y: 2.05, z: 3.2),
                   candela: 0, kelvin: 5200,
                   optics: .init(kind: .directional,
                                 aimTarget: .init(x: -0.45, y: 1.7, z: -0.2))), 1875.5),
            (.init(name: "Rolled nonsquare rectangle", position: .init(x: -0.85, y: 2.8, z: 1.95),
                   candela: 400, kelvin: 6100,
                   optics: .init(kind: .rectangle,
                                 aimTarget: .init(x: -0.25, y: 0.95, z: -0.15),
                                 widthMeters: 0.85, heightMeters: 1.35,
                                 rollDegrees: 37)), 12345.75)
        ]

        for (source, referenceCandela) in fixtures {
            let scene = LightingScene(subject: .init(x: 0.35, y: 1.25, z: -0.45),
                                      camera: .init(x: 1.1, y: 1.8, z: 4.2),
                                      lights: [source])
            var reference = source
            reference.candela = referenceCandela
            let target = try XCTUnwrap(StudioPhotometry.illuminance(for: reference, in: scene),
                                       source.name)
            XCTAssertTrue(target.isFinite, source.name)
            XCTAssertGreaterThan(target, 0, source.name)
            var maximum = source
            maximum.candela = 100_000
            let maximumLux = try XCTUnwrap(StudioPhotometry.illuminance(for: maximum, in: scene),
                                           source.name)
            XCTAssertLessThan(target, maximumLux, "Interior target: \(source.name)")

            let adjusted = try LightOutputAdjustment.light(source, targetingLux: target, in: scene)
            let achieved = try XCTUnwrap(StudioPhotometry.illuminance(for: adjusted, in: scene),
                                         source.name)

            XCTAssertTrue(adjusted.isValid, source.name)
            XCTAssertLessThanOrEqual(abs(adjusted.candela / referenceCandela - 1), 1e-9,
                                     "Recovered reference intensity: \(source.name)")
            XCTAssertLessThanOrEqual(abs(achieved / target - 1), 1e-9,
                                     "Forward target round trip: \(source.name)")
        }
    }
}
