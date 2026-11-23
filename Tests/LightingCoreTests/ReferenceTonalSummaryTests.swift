import XCTest
@testable import LightingCore

final class ReferenceTonalSummaryTests: XCTestCase {
    func testNeutralGrayAndOpaqueOnly() throws {
        let tone = try XCTUnwrap(ReferenceTonalSummary(rgba: [128,128,128,255, 255,255,255,0, 0,0,0,128]))
        XCTAssertEqual(tone.sampleCount, 1)
        XCTAssertEqual(tone.lowGray, 128.0 / 255, accuracy: 1e-12)
        XCTAssertEqual(tone.medianGray, tone.lowGray)
        XCTAssertEqual(tone.highGray, tone.lowGray)
        XCTAssertEqual(tone.deepShadowFraction, 0)
        XCTAssertEqual(tone.brightHighlightFraction, 0)
    }

    func testLinearLightInterpolationAndThresholds() throws {
        let tone = try XCTUnwrap(ReferenceTonalSummary(rgba: [0,0,0,255, 255,255,255,255]))
        XCTAssertEqual(tone.sampleCount, 2)
        // Equal black and white samples: median interpolates in linear light.
        XCTAssertEqual(tone.medianGray, 0.7353569830524495, accuracy: 1e-12)
        XCTAssertEqual(tone.deepShadowFraction, 0.5)
        XCTAssertEqual(tone.brightHighlightFraction, 0.5)
        XCTAssertLessThan(tone.lowGray, tone.medianGray)
        XCTAssertGreaterThan(tone.highGray, tone.medianGray)
    }

    func testPrimaryColorsUseLinearRec709LuminanceNotRGBMean() throws {
        let r = try XCTUnwrap(ReferenceTonalSummary(rgba: [255,0,0,255]))
        let g = try XCTUnwrap(ReferenceTonalSummary(rgba: [0,255,0,255]))
        let b = try XCTUnwrap(ReferenceTonalSummary(rgba: [0,0,255,255]))
        XCTAssertGreaterThan(g.medianGray, r.medianGray)
        XCTAssertGreaterThan(r.medianGray, b.medianGray)
        XCTAssertEqual(r.medianGray, 0.4984399235922749, accuracy: 1e-12)
    }

    func testMalformedOversizedAndAllTransparentSamplesAbstain() {
        XCTAssertNil(ReferenceTonalSummary(rgba: []))
        XCTAssertNil(ReferenceTonalSummary(rgba: [0,0,0]))
        XCTAssertNil(ReferenceTonalSummary(rgba: [0,0,0,0]))
        XCTAssertNil(ReferenceTonalSummary(rgba: Array(repeating: 255, count: 4 * (ReferenceTonalSummary.maximumPixels + 1))))
    }

    func testOrderInvariantAndBounded() throws {
        let a: [UInt8] = [0,0,0,255, 25,25,25,255, 128,128,128,255, 243,243,243,255, 255,255,255,255]
        let b = Array(stride(from: 16, through: 0, by: -4).flatMap { Array(a[$0..<$0+4]) })
        let tone = try XCTUnwrap(ReferenceTonalSummary(rgba: a))
        XCTAssertEqual(tone, ReferenceTonalSummary(rgba: b))
        XCTAssertEqual(tone.deepShadowFraction, 0.4)
        XCTAssertEqual(tone.brightHighlightFraction, 0.4)
        XCTAssertGreaterThanOrEqual(tone.lowGray, 0)
        XCTAssertLessThanOrEqual(tone.highGray, 1)
    }
}
