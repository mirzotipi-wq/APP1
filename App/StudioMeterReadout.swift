import Foundation

/// Compact readouts keep sub-resolution light distinct from an exact zero.
enum StudioMeterReadout {
    static func candela(_ value: Double, locale: Locale) -> String {
        formattedValue(value, unit: "cd", fractionDigits: 0, quantum: 1, locale: locale)
    }

    static func lux(_ value: Double, locale: Locale) -> String {
        formattedValue(value, unit: "lx", fractionDigits: 1, quantum: 0.1, locale: locale)
    }

    private static func formattedValue(_ value: Double, unit: String, fractionDigits: Int,
                                       quantum: Double, locale: Locale) -> String {
        guard value.isFinite, value >= 0 else {
            return String(localized: "Unavailable", locale: locale)
        }
        let style = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(fractionDigits))
            .grouping(.never)
            .locale(locale)
        if value > 0, value < quantum {
            return "<\(quantum.formatted(style)) \(unit)"
        }
        // Normalize negative zero so the zero readout has no misleading sign.
        let displayValue = value == 0 ? 0.0 : value
        return "\(displayValue.formatted(style)) \(unit)"
    }
}
