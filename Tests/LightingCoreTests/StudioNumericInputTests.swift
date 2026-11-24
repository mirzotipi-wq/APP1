import XCTest
@testable import LightingCore

final class StudioNumericInputTests: XCTestCase {
    func testSignedExactValuesDoNotSnapToSliderSteps() {
        XCTAssertEqual(StudioNumericInput.parse("-1.237", in: -100...100), -1.237)
        XCTAssertEqual(StudioNumericInput.parse("+4321.5", in: 0...100_000), 4321.5)
        XCTAssertEqual(StudioNumericInput.parse("  .125  ", in: 0...1), 0.125)
        XCTAssertEqual(StudioNumericInput.parse("−0.75", in: -6...6), -0.75)
    }

    func testLocaleDecimalSeparatorsAndDecimalDigits() {
        XCTAssertEqual(StudioNumericInput.parse("-1,25", decimalSeparator: ",", in: -4...4), -1.25)
        XCTAssertEqual(StudioNumericInput.parse("١٢٫٥", decimalSeparator: "٫", in: 0...100), 12.5)
        XCTAssertEqual(StudioNumericInput.parse("۱۲,۵", decimalSeparator: ",", in: 0...100), 12.5)
        XCTAssertNil(StudioNumericInput.parse("1.25", decimalSeparator: ",", in: 0...4))
    }

    func testMalformedAndNonfiniteInputRejected() {
        for input in ["", " ", "+", "-", ".", "-.", "NaN", "inf", "1e2", "0x1", "1 000", "1,000", "1.2.3", "--1", "1-", "²", "Ⅲ", "1\n2", String(repeating: "0", count: 33)] {
            XCTAssertNil(StudioNumericInput.parse(input, in: -100_000...100_000), input)
        }
        XCTAssertNil(StudioNumericInput.parse("1,2,3", decimalSeparator: ",", in: 0...100))
    }

    func testDomainBoundariesAreRejectedNotClamped() {
        XCTAssertEqual(StudioNumericInput.parse("100000", in: 0...100_000), 100_000)
        XCTAssertNil(StudioNumericInput.parse("100000.01", in: 0...100_000))
        XCTAssertNil(StudioNumericInput.parse("-0.01", in: 0...100_000))
        XCTAssertEqual(StudioNumericInput.parse("1000", in: 1000...20_000), 1000)
        XCTAssertNil(StudioNumericInput.parse("999", in: 1000...20_000))
        XCTAssertNil(StudioNumericInput.parse("-100.001", in: -100...100))
    }

    func testSliderBoundsPreserveValidImportedValues() {
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 0...3000, current: 4321.5), 0...4321.5)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 0...4, current: -0.5), -0.5...4)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: -4...4, current: 1.237), -4...4)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 2000...9000, current: 1000), 1000...9000)
        XCTAssertEqual(StudioNumericInput.sliderBounds(usual: 0...1, current: .nan), 0...1)
    }

    func testExactCameraOpticsAndMeterValuesSurviveSceneRoundTrip() throws {
        var scene = LightingScene.portrait()
        scene.camera.x = try XCTUnwrap(StudioNumericInput.parse("-5.137", in: Position.coordinateRange))
        scene.camera.y = try XCTUnwrap(StudioNumericInput.parse("-0.125", in: Position.coordinateRange))
        scene.cameraLens = .init(focalLengthMillimeters:
            try XCTUnwrap(StudioNumericInput.parse("73.125", in: CameraLens.focalLengthRange)))
        scene.lights[0].optics = .init(kind: .rectangle,
            aimTarget: .init(x: try XCTUnwrap(StudioNumericInput.parse("4.125", in: Position.coordinateRange)), y: 1.5, z: 0),
            widthMeters: try XCTUnwrap(StudioNumericInput.parse("1.237", in: LightOptics.dimensionRange)),
            heightMeters: try XCTUnwrap(StudioNumericInput.parse("0.053", in: LightOptics.dimensionRange)))
        scene.previewSettings = .init(
            whiteBalanceKelvin: try XCTUnwrap(StudioNumericInput.parse("4321.5", in: PreviewSettings.whiteBalanceRange)),
            exposureStops: try XCTUnwrap(StudioNumericInput.parse("-0.375", in: PreviewSettings.exposureRange)))
        XCTAssertEqual(try SceneCodec.decode(SceneCodec.encode(scene)), scene)
        XCTAssertEqual(scene.effectiveCameraLens.focalLengthMillimeters, 73.125)
        XCTAssertEqual(scene.lights[0].effectiveOptics.widthMeters, 1.237)
        XCTAssertEqual(scene.effectivePreviewSettings.exposureStops, -0.375)
    }

    func testInspectorDomainMatchesModelAtBoundsAndRejectsOutside() {
        XCTAssertTrue(Position(x: -100, y: 100, z: 0).isValid)
        XCTAssertFalse(Position(x: -100.001, y: 0, z: 0).isValid)
        XCTAssertNil(StudioNumericInput.parse("-100.001", in: Position.coordinateRange))
        XCTAssertTrue(LightOptics(kind: .rectangle, widthMeters: 0.05, heightMeters: 4).isValid)
        XCTAssertFalse(LightOptics(kind: .rectangle, widthMeters: 0.049, heightMeters: 4).isValid)
        XCTAssertNil(StudioNumericInput.parse("0.049", in: LightOptics.dimensionRange))
        XCTAssertNil(StudioNumericInput.parse("200.001", in: CameraLens.focalLengthRange))
        XCTAssertNil(StudioNumericInput.parse("10000.001", in: PreviewSettings.whiteBalanceRange))
        XCTAssertNil(StudioNumericInput.parse("-6.001", in: PreviewSettings.exposureRange))
    }
}
