import SwiftUI
import LightingCore

/// Scene distances stay in meters; only the editor and its readout use the
/// selected display units. Reading or changing units never writes the binding.
struct DistanceValueButton: View {
    let title: String
    let id: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var compactReadout = false
    @Environment(\.locale) private var locale
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRawValue = PlanUnits.metric.rawValue

    var body: some View {
        let units = StudioPreferences.units(from: unitsRawValue)
        let displayRange = Self.convertedRange(range, units: units)
        PrecisionValueButton(title: title, unit: units.symbol, id: id,
                             value: displayedValue(units: units, range: displayRange),
                             range: displayRange ?? (0...0),
                             underlyingValue: $value,
                             visualReadout: compactReadout
                                ? PlacementMeasurementDisplay.distance(value, units: units, locale: locale)
                                : nil)
            .disabled(displayRange == nil || !units.fromMeters(value).isFinite)
            // A preference change cancels an open draft instead of reinterpreting
            // its existing digits in another unit.
            .id(units.rawValue)
    }

    /// Use the same localized precision for distance readouts and slider values.
    static func formattedValue(_ meters: Double, units: PlanUnits,
                               locale: Locale = .current) -> String {
        StudioNumericInput.formattedValue(units.fromMeters(meters), unit: units.symbol, locale: locale)
    }

    private static func convertedRange(_ meters: ClosedRange<Double>,
                                       units: PlanUnits) -> ClosedRange<Double>? {
        let lower = units.fromMeters(meters.lowerBound)
        let upper = units.fromMeters(meters.upperBound)
        guard meters.lowerBound.isFinite, meters.upperBound.isFinite,
              lower.isFinite, upper.isFinite, lower <= upper,
              units.toMeters(lower).isFinite, units.toMeters(upper).isFinite else { return nil }
        return lower...upper
    }

    private func displayedValue(units: PlanUnits, range displayRange: ClosedRange<Double>?) -> Binding<Double> {
        Binding {
            units.fromMeters(value)
        } set: { entered in
            // Reject a late Apply from a sheet whose unit identity has changed.
            guard units == StudioPreferences.units(from: unitsRawValue) else { return }
            guard let displayRange, entered.isFinite, displayRange.contains(entered) else { return }
            // A numerically unchanged edit must preserve the exact original SI
            // value, including signed zero and feet -> meters round-trip drift.
            guard entered != units.fromMeters(value) else { return }
            let meters: Double
            if entered == displayRange.lowerBound {
                meters = range.lowerBound
            } else if entered == displayRange.upperBound {
                meters = range.upperBound
            } else {
                meters = units.toMeters(entered)
            }
            // Preserve exact SI endpoints when their converted Double would
            // otherwise round just outside the domain. Other input is validated,
            // never clamped or snapped to a slider increment.
            guard meters.isFinite, range.contains(meters),
                  units.fromMeters(meters).isFinite else { return }
            value = meters
        }
    }
}
