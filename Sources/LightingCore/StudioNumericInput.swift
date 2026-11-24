import Foundation

/// Strict decimal input for scene parameters. Values are never silently
/// clamped, rounded to a slider step, or interpreted as grouped numbers.
public enum StudioNumericInput {
    /// The shared current-value readout for numeric controls. Slider steps
    /// describe adjustment increments, not the precision of an imported or
    /// directly entered value. Formatting never changes the stored number.
    public static func formattedValue(_ value: Double, unit: String = "",
                                      locale: Locale = .current) -> String {
        let number = value.formatted(.number.precision(.fractionLength(0...6))
            .grouping(.never).locale(locale))
        return unit.isEmpty ? number : number + " " + unit
    }

    public static func parse(_ text: String, decimalSeparator: String = ".",
                             in range: ClosedRange<Double>) -> Double? {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, input.utf8.count <= 96, input.count <= 32,
              decimalSeparator.count == 1, let separator = decimalSeparator.first,
              separator != "+", separator != "-", separator != "−",
              separator.wholeNumberValue == nil else { return nil }
        var canonical = ""
        var seenSeparator = false
        var digits = 0
        for (index, character) in input.enumerated() {
            if index == 0 && (character == "-" || character == "−" || character == "+") {
                if character != "+" { canonical.append("-") }
            } else if character == separator && !seenSeparator {
                canonical.append("."); seenSeparator = true
            } else if character.unicodeScalars.count == 1,
                      character.unicodeScalars.first?.properties.numericType == .decimal,
                      let digit = character.wholeNumberValue, (0...9).contains(digit) {
                canonical.append(String(digit)); digits += 1
            } else {
                return nil
            }
        }
        guard digits > 0, let value = Double(canonical), value.isFinite,
              range.contains(value) else { return nil }
        return value
    }

    /// A valid imported or directly entered value must remain representable
    /// even when it falls outside the quick-adjustment slider's usual span.
    public static func sliderBounds(usual: ClosedRange<Double>, current: Double) -> ClosedRange<Double> {
        guard current.isFinite else { return usual }
        return min(usual.lowerBound, current)...max(usual.upperBound, current)
    }
}
