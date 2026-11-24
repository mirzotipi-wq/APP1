import XCTest
import UIKit
import LightingCore
@testable import KeyAndFill

@MainActor
final class StudioTrackingSliderTests: XCTestCase {
    private let accessibility = StudioSliderAccessibility(
        label: "Width", value: { StudioNumericInput.formattedValue($0, unit: "m", locale: Locale(identifier: "en_US")) },
        identifier: "emitterWidth")

    func testProgrammaticConfigurationAndStrayValueEventNeverRoundTripDouble() {
        var value = 0.72345678912345, writes = 0, begins = 0
        let editing = StudioSliderEditing(read: { value }, write: { value = $0; writes += 1 },
                                          onEditingChanged: { if $0 { begins += 1 } })
        let slider = StudioTrackingSlider(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        let mapping = StudioSliderMapping(bounds: 0.05...4, step: 0.05)!
        slider.configure(editing: editing, mapping: mapping, accessibility: accessibility, isEnabled: true)
        slider.configure(editing: editing, mapping: mapping, accessibility: accessibility, isEnabled: true)
        slider.value = 0.9 // A stale native event outside a touch must restore the model's display.
        slider.sendActions(for: .valueChanged)
        XCTAssertEqual(value.bitPattern, 0.72345678912345.bitPattern)
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(begins, 0)
        XCTAssertTrue(slider.isContinuous)
        XCTAssertEqual(slider.value, mapping.normalized(value))
        XCTAssertEqual(slider.accessibilityLabel, accessibility.label)
        XCTAssertEqual(slider.accessibilityValue, accessibility.value(value))
        XCTAssertEqual(slider.accessibilityIdentifier, accessibility.identifier)
        XCTAssertGreaterThanOrEqual(slider.intrinsicContentSize.height, 44)
        value = 3.12345678912345
        XCTAssertEqual(slider.accessibilityValue, accessibility.value(value),
                       "The accessible readout must read the current Double before another configure")
        slider.configure(editing: editing, mapping: mapping, accessibility: accessibility, isEnabled: true)
        XCTAssertEqual(value.bitPattern, 3.12345678912345.bitPattern)
        XCTAssertEqual(slider.value, mapping.normalized(value))
        XCTAssertEqual(writes, 0)
    }

    func testNativeAccessibilityActionsUseExactDoubleStepsAndRespectDisabledState() {
        var value = 0.723456789, begins = 0, ends = 0
        let editing = StudioSliderEditing(read: { value }, write: { value = $0 }, onEditingChanged: {
            if $0 { begins += 1 } else { ends += 1 }
        })
        let slider = StudioTrackingSlider(frame: .zero)
        let mapping = StudioSliderMapping(bounds: 0.05...4, step: 0.05)!
        slider.configure(editing: editing, mapping: mapping, accessibility: accessibility, isEnabled: true)
        slider.accessibilityIncrement()
        XCTAssertEqual(value, 0.723456789 + 0.05)
        XCTAssertEqual(slider.accessibilityValue, accessibility.value(value))
        XCTAssertEqual(slider.accessibilityLabel, "Width")
        XCTAssertEqual(slider.accessibilityIdentifier, "emitterWidth")
        XCTAssertEqual(begins, 1)
        XCTAssertEqual(ends, 1)
        slider.configure(editing: editing, mapping: mapping, accessibility: accessibility, isEnabled: false)
        slider.accessibilityDecrement()
        XCTAssertEqual(value, 0.723456789 + 0.05)
        XCTAssertEqual(begins, 1)
        slider.configure(editing: editing, mapping: mapping, accessibility: accessibility, isEnabled: true)
        value = 4
        slider.accessibilityIncrement()
        XCTAssertEqual(value, 4)
        XCTAssertEqual(begins, 1)
        slider.invalidate()
        slider.accessibilityDecrement()
        slider.sendActions(for: .valueChanged)
        XCTAssertEqual(value, 4)
        XCTAssertFalse(slider.isEnabled)
    }

    func testInvalidRangeDisablesNativeControlWithoutWritingTheModel() {
        var value = 0.723456789, writes = 0
        let editing = StudioSliderEditing(read: { value }, write: { value = $0; writes += 1 },
                                          onEditingChanged: { _ in })
        let slider = StudioTrackingSlider(frame: .zero)
        slider.configure(editing: editing, mapping: nil, accessibility: accessibility, isEnabled: true)
        slider.accessibilityIncrement()
        slider.sendActions(for: .valueChanged)
        XCTAssertEqual(value, 0.723456789)
        XCTAssertEqual(writes, 0)
        XCTAssertFalse(slider.isEnabled)
    }
}
