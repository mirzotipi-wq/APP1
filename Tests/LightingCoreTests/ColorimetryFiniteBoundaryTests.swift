import XCTest
@testable import LightingCore

final class ColorimetryFiniteBoundaryTests: XCTestCase {
    func testChromaticitySurvivesOverflowingFiniteSum() throws {
        let maximum = Double.greatestFiniteMagnitude
        let equal = try XCTUnwrap(RelativeXYZ(x: maximum, y: maximum, z: maximum).chromaticity)
        XCTAssertEqual(equal.x, 1 / 3, accuracy: 1e-15)
        XCTAssertEqual(equal.y, 1 / 3, accuracy: 1e-15)
        let unequal = try XCTUnwrap(RelativeXYZ(x: maximum, y: maximum / 2, z: maximum / 4).chromaticity)
        XCTAssertEqual(unequal.x, 4 / 7, accuracy: 1e-15)
        XCTAssertEqual(unequal.y, 2 / 7, accuracy: 1e-15)
    }

    func testFiniteExtremeSignalsToneMapWithoutIntermediateOverflow() throws {
        for kelvin in [2000.0, 5600, 10000] {
            for stops in [-6.0, 0, 6] {
                let display = try XCTUnwrap(PreviewColorimetry.display(
                    .init(x: .greatestFiniteMagnitude, y: .greatestFiniteMagnitude,
                          z: .greatestFiniteMagnitude),
                    settings: .init(whiteBalanceKelvin: kelvin, exposureStops: stops)))
                for component in [display.red, display.green, display.blue] {
                    XCTAssertTrue(component.isFinite)
                    XCTAssertEqual(component, 1, accuracy: 1e-12)
                }
            }
        }
    }

    func testInvalidXYZAndBlackRetainDistinctOutcomes() throws {
        for value in [Double.nan, .infinity, -.infinity, -1] {
            let xyz = RelativeXYZ(x: value, y: 1, z: 1)
            XCTAssertNil(xyz.chromaticity)
            XCTAssertNil(PreviewColorimetry.display(xyz, settings: .init()))
        }
        let black = RelativeXYZ(x: 0, y: 0, z: 0)
        XCTAssertNil(black.chromaticity)
        let display = try XCTUnwrap(PreviewColorimetry.display(black, settings: .init()))
        XCTAssertEqual(display.red, 0)
        XCTAssertEqual(display.green, 0)
        XCTAssertEqual(display.blue, 0)
    }
}
