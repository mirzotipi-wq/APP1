import Foundation
import UIKit
import XCTest
@testable import KeyAndFill

@MainActor
final class StudioPaletteTests: XCTestCase {
    func testActionAndSecondaryTextContrastOnResolvedSystemSurfaces() throws {
        // Studio root/recipes, cards/Save bar, unselected light rows, and the
        // precision, project-library, name and recovery sheets use these real
        // UIKit backgrounds. Elevated traits
        // cover their presentation in sheets rather than assuming white/black.
        let surfaces: [(String, UIColor)] = [
            ("systemBackground", .systemBackground),
            ("systemGroupedBackground", .systemGroupedBackground),
            ("secondarySystemGroupedBackground", .secondarySystemGroupedBackground),
            ("tertiarySystemGroupedBackground", .tertiarySystemGroupedBackground)
        ]
        for (appearance, traits) in appearances {
            for (surfaceName, surface) in surfaces {
                let background = try components(surface, traits: traits)
                for (name, color) in [("action", StudioPalette.actionUIColor),
                                      ("secondaryText", StudioPalette.secondaryTextUIColor),
                                      ("roomWarning", StudioPalette.warningUIColor),
                                      ("projectNameError", StudioPalette.destructiveUIColor)] {
                    try assertContrast(color, on: background, minimum: 4.5, traits: traits,
                                       pair: "\(appearance) \(name) / \(surfaceName)")
                }
            }
        }
    }

    func testProjectSheetControlsContrastOnTheirProductionSurfaces() throws {
        for (appearance, traits) in appearances {
            let row = try components(.secondarySystemGroupedBackground, traits: traits)
            try assertContrast(StudioPalette.selectionUIColor, on: row, minimum: 3, traits: traits,
                               pair: "\(appearance) current-project checkmark / library row")
            try assertContrast(StudioPalette.destructiveUIColor, on: row, minimum: 3, traits: traits,
                               pair: "\(appearance) archived-project trash icon / library row")
            try assertContrast(StudioPalette.prominentActionTextUIColor,
                               on: components(StudioPalette.actionUIColor, traits: traits),
                               minimum: 4.5, traits: traits,
                               pair: "\(appearance) Save project name and Share measurement notes / explicit action fill")
            try assertContrast(StudioPalette.secondaryTextUIColor,
                               on: components(.tertiarySystemGroupedBackground, traits: traits),
                               minimum: 4.5, traits: traits,
                               pair: "\(appearance) disabled Save project name / explicit disabled fill")
        }
    }

    func testSecondaryTextAndSelectionCuesContrastOnLayeredLightRows() throws {
        for (appearance, traits) in appearances {
            let selection = try components(StudioPalette.selectionUIColor, traits: traits)
            let card = try components(.secondarySystemGroupedBackground, traits: traits)
            let unselectedRow = try components(.tertiarySystemGroupedBackground, traits: traits)
            // StudioView.lightList, the ideal-lux panel and the neutral-card
            // selected preset apply this 12% tint over their enclosing
            // secondary grouped card, not a flat swatch.
            let selectedRow = composite(selection, opacity: 0.12, over: card)
            try assertContrast(StudioPalette.secondaryTextUIColor, on: selectedRow,
                               minimum: 4.5, traits: traits,
                               pair: "\(appearance) secondaryText / selected row and ideal-lux panel")
            try assertContrast(StudioPalette.selectionUIColor, on: selectedRow,
                               minimum: 3, traits: traits,
                               pair: "\(appearance) selected checkmark / light row and white-balance preset")
            // The equipment icon has a second 13% tint inside either row.
            for (rowName, row) in [("selected", selectedRow), ("unselected", unselectedRow)] {
                let iconBackground = composite(selection, opacity: 0.13, over: row)
                try assertContrast(StudioPalette.selectionUIColor, on: iconBackground,
                                   minimum: 3, traits: traits,
                                   pair: "\(appearance) equipment icon / \(rowName) nested icon fill")
            }
        }
    }

    func testFixedPlanTextAndLightControlsContrastInBothAppearances() throws {
        for (appearance, traits) in appearances {
            let background = try components(StudioPalette.planBackgroundUIColor, traits: traits)
            let light = try components(StudioPalette.planLightUIColor, traits: traits)
            try assertContrast(.white, on: background, minimum: 4.5, traits: traits,
                               pair: "\(appearance) Plan title / fixed Plan")
            try assertContrast(StudioPalette.planLightUIColor, on: background,
                               minimum: 3, traits: traits,
                               pair: "\(appearance) Plan light outline / fixed Plan")
            // StudioPlanMarkerControl uses a 25% light-color fill when selected
            // and a 65% black fill otherwise; both sit on the fixed dark Plan.
            let selectedFill = composite(light, opacity: 0.25, over: background)
            try assertContrast(StudioPalette.planLightUIColor, on: selectedFill,
                               minimum: 3, traits: traits,
                               pair: "\(appearance) selected Plan light icon / selected marker fill")
            let unselectedFill = composite(try components(.black, traits: traits),
                                           opacity: 0.65, over: background)
            try assertContrast(StudioPalette.planLightUIColor, on: unselectedFill,
                               minimum: 3, traits: traits,
                               pair: "\(appearance) unselected Plan and room light icon / dark marker fill")
            try assertContrast(.white, on: unselectedFill,
                               minimum: 3, traits: traits,
                               pair: "\(appearance) room subject and camera icons / dark marker fill")
        }
    }

    func testPlanColorsStayFixedWhenInterfaceAppearanceChanges() throws {
        let baselineTraits = try XCTUnwrap(appearances.first?.1)
        for color in [StudioPalette.planBackgroundUIColor, StudioPalette.planLightUIColor] {
            let baseline = try components(color, traits: baselineTraits)
            for (_, traits) in appearances {
                XCTAssertEqual(try components(color, traits: traits), baseline,
                               "Plan colors must not switch to the light grouped-surface palette")
            }
        }
    }

    private var appearances: [(String, UITraitCollection)] {
        let styles: [(String, UIUserInterfaceStyle)] = [("light", .light), ("dark", .dark)]
        let levels: [(String, UIUserInterfaceLevel)] = [("base", .base), ("elevated", .elevated)]
        return styles.flatMap { styleName, style in
            levels.map { levelName, level in
                ("\(styleName)/\(levelName)", UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: style),
                    UITraitCollection(userInterfaceLevel: level),
                    UITraitCollection(accessibilityContrast: .normal)
                ]))
            }
        }
    }

    // This independent oracle reads production UIColors, then converts their
    // resolved components to standard sRGB. No duplicated palette values or
    // fallback colors can conceal a UIKit-resolution failure.
    private func components(_ color: UIColor, traits: UITraitCollection,
                            file: StaticString = #filePath, line: UInt = #line) throws -> [Double] {
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB), file: file, line: line)
        let converted = try XCTUnwrap(color.resolvedColor(with: traits).cgColor.converted(
            to: space, intent: .relativeColorimetric, options: nil), file: file, line: line)
        let values = try XCTUnwrap(converted.components, file: file, line: line).map { Double($0) }
        XCTAssertEqual(values.count, 4, "Expected standard sRGB RGBA", file: file, line: line)
        guard values.count == 4 else { throw ColorError.invalidComponents }
        XCTAssertTrue(values.allSatisfy { $0.isFinite && (0...1).contains($0) },
                      "Contrast requires finite sRGB components", file: file, line: line)
        XCTAssertEqual(values[3], 1, accuracy: 0.000001,
                       "The declared source colors and surfaces must be opaque", file: file, line: line)
        return Array(values.prefix(3))
    }

    private func composite(_ foreground: [Double], opacity: Double, over background: [Double]) -> [Double] {
        zip(foreground, background).map { opacity * $0 + (1 - opacity) * $1 }
    }

    private func assertContrast(_ foreground: UIColor, on background: [Double], minimum: Double,
                                traits: UITraitCollection, pair: String,
                                file: StaticString = #filePath, line: UInt = #line) throws {
        let foregroundRGB = try components(foreground, traits: traits, file: file, line: line)
        func luminance(_ rgb: [Double]) -> Double {
            let linear = rgb.map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
            return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
        }
        let first = luminance(foregroundRGB), second = luminance(background)
        let ratio = (max(first, second) + 0.05) / (min(first, second) + 0.05)
        let observation = "\(pair): \(ratio):1; foreground=\(foregroundRGB), background=\(background)"
        print("StudioPalette contrast: " + observation)
        XCTAssertGreaterThanOrEqual(ratio, minimum, observation, file: file, line: line)
    }

    private enum ColorError: Error { case invalidComponents }
}
