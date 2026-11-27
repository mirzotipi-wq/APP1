import XCTest
import LightingCore

final class DirectionalDoubleCosineTests: XCTestCase {
    func testIndependentEmitterAndReceiverCosinesMultiply() throws {
        // Translated geometry avoids accidentally treating world positions as rays.
        // Source-to-subject distance is 5 m. Source-to-aim = (4, 0, -3),
        // so the emission cosine against (0, 0, -1) is 3/5. Subject-to-camera
        // = (0, 3, 4), so incidence against (0, 0, 1) is independently 4/5.
        let light = StudioLight(
            name: "Double cosine", position: .init(x: 1, y: 1, z: 3),
            candela: 1250, kelvin: 5600,
            optics: .init(kind: .directional, aimTarget: .init(x: 5, y: 1, z: 0)))
        let scene = try LightingScene(
            subject: .init(x: 1, y: 1, z: -2),
            camera: .init(x: 1, y: 4, z: 2), lights: [light]).validated()

        // Independent analytic value: (1250 cd / 25 m²) × (3/5) × (4/5) = 24 lx.
        // No production frame, normal, point-photometry or Study helper supplies
        // this oracle. Omitting the emission or incidence factor gives 40 or 30 lx.
        let expectedLux = 24.0
        let actualLux = try XCTUnwrap(StudioPhotometry.illuminance(for: light, in: scene))
        print("SCALAR expected_lux=\(expectedLux) actual_lux=\(actualLux) absolute_error=\(abs(actualLux - expectedLux)) relative_error=\(abs(actualLux - expectedLux) / expectedLux)")
        XCTAssertEqual(actualLux, expectedLux, accuracy: 1e-10)
    }
}

XCTMain([testCase([
    ("testIndependentEmitterAndReceiverCosinesMultiply",
     DirectionalDoubleCosineTests.testIndependentEmitterAndReceiverCosinesMultiply)
])])
