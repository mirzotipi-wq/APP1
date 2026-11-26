import XCTest
import LightingCore

final class IndependentRolledRectangleReferenceTests: XCTestCase {
    func testRolledObliquePartialFaceMatchesIndependentCosineIntegral() throws {
        let center = Position(x: 0.4, y: 1.5, z: -0.3)
        let frame = try XCTUnwrap(EmitterFrame(
            source: center, target: .init(x: 2.4, y: 4.5, z: 5.7), rollDegrees: 37))
        let emitter = try XCTUnwrap(LambertianRectangle(
            center: center, right: frame.right, up: frame.up,
            widthMeters: 1.2, heightMeters: 0.6, onAxisCandela: 1000))
        // Fixed world-space inputs preserve independence from production frame changes.
        let receiver = Position(
            x: 0.754342288931758, y: 1.752115732184385, z: 0.1558280375972214)
        let receiverNormal = try XCTUnwrap(UnitDirection(
            x: 0.4557804691331652, y: 0.8127556480146011, z: -0.362894503371321))
        let actual = try XCTUnwrap(Photometry.rectangularIlluminance(
            emitter: emitter, receiver: receiver, receiverNormal: receiverNormal))

        // W01R04 roll_area_probe.json / independent Simpson section of roll_area_probe.py.
        // E = (1000 / 0.72) integral(cosEmitter * cosReceiver / distance^2) dA.
        // At depth 0.6 m the contributing local face is x + 0.35y > 0.216.
        // Direct world-space cosines on analytic y slices avoid production clipping,
        // triangle mapping and Gaussian quadrature. Simpson N=160 gives this value.
        // Independent N=320 refinement: 133.78670187718623 lx (2.50e-10 relative delta).
        let expectedLux = 133.78670191052524
        let relativeError = abs(actual - expectedLux) / expectedLux
        XCTAssertLessThanOrEqual(relativeError, 0.05, "Unchanged area-model contract")
        // This well-resolved fixture has a tighter regression bound; no global gate changes.
        XCTAssertLessThanOrEqual(relativeError, 1e-6, "Rolled partial-face reference")
    }
}
