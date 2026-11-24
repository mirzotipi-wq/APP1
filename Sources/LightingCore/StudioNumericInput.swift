import Foundation

/// Strict decimal input for scene parameters. Values are never silently
/// clamped, rounded to a slider step, or interpreted as grouped numbers.
public enum StudioNumericInput {
    /// The shared current-value readout for numeric controls. Slider steps
    /// describe adjustment increments, not the precision of an imported or
    /// directly entered value. Round-trip digits preserve the stored Double;
    /// scientific notation bounds values that need more than 32 decimal
    /// characters. Localization changes symbols, never the numeric precision.
    public static func formattedValue(_ value: Double, unit: String = "",
                                      locale: Locale = .current) -> String {
        guard value.isFinite else { return unit.isEmpty ? "Unavailable" : "Unavailable " + unit }
        let source = decimalText(value, omitLeadingZeroWhenNeeded: false) ?? String(value)
        let integerStyle = IntegerFormatStyle<Int>.number.grouping(.never).locale(locale)
        let digits = (0...9).map { $0.formatted(integerStyle) }
        let minus = (-1).formatted(integerStyle).replacingOccurrences(of: digits[1], with: "")
        let number = source.map { character -> String in
            if let digit = character.wholeNumberValue { return digits[digit] }
            if character == "." { return locale.decimalSeparator ?? "." }
            if character == "-" { return minus }
            return String(character)
        }.joined()
        return unit.isEmpty ? number : number + " " + unit
    }

    /// An exact, bounded decimal draft using ASCII digits and the user's
    /// separator. nil means the editor must retain the value explicitly rather
    /// than seed its decimal field with rounded zero or scientific notation.
    public static func editableText(_ value: Double, decimalSeparator: String = ".") -> String? {
        guard let decimal = decimalText(value, omitLeadingZeroWhenNeeded: true) else { return nil }
        let text = decimal.replacingOccurrences(of: ".", with: decimalSeparator)
        guard let parsed = parse(text, decimalSeparator: decimalSeparator,
                                 in: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude),
              parsed.bitPattern == value.bitPattern else { return nil }
        return text
    }

    /// Expand Double's round-trip description only after checking the output
    /// length. No hundreds-of-digits intermediate is allocated for subnormals.
    private static func decimalText(_ value: Double, omitLeadingZeroWhenNeeded: Bool) -> String? {
        guard value.isFinite else { return nil }
        let parts = String(value).split(separator: "e")
        let exponent = parts.count == 2 ? Int(parts[1])! : 0
        var mantissa = String(parts[0])
        let negative = mantissa.first == "-"
        if negative { mantissa.removeFirst() }
        let components = mantissa.split(separator: ".")
        var point = components[0].count + exponent
        var digits = components.joined()
        while digits.last == "0", digits.count > 1 { digits.removeLast() }
        while digits.first == "0", digits.count > 1 { digits.removeFirst(); point -= 1 }
        let sign = negative ? "-" : ""
        let fullLength = sign.count + (point <= 0 ? 2 - point + digits.count :
            max(point, digits.count) + (point < digits.count ? 1 : 0))
        // The input grammar permits .125. Use that one-character saving only
        // when necessary to retain an otherwise 33-character exact draft.
        let omitZero = omitLeadingZeroWhenNeeded && point <= 0 && fullLength == 33
        guard fullLength - (omitZero ? 1 : 0) <= 32 else { return nil }
        if point <= 0 {
            return sign + (omitZero ? "." : "0.") + String(repeating: "0", count: -point) + digits
        }
        if point >= digits.count {
            return sign + digits + String(repeating: "0", count: point - digits.count)
        }
        let split = digits.index(digits.startIndex, offsetBy: point)
        return sign + digits[..<split] + "." + digits[split...]
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
