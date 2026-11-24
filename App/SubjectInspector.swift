import SwiftUI
import LightingCore

/// The shared subject-center position used by framing and subject-tracking lights.
struct SubjectInspector: View {
    @Binding var position: Position
    let onEditingChanged: (Bool, String) -> Void
    @Environment(\.locale) private var locale
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRawValue = PlanUnits.metric.rawValue

    private var units: PlanUnits { StudioPreferences.units(from: unitsRawValue) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUBJECT POSITION").font(.caption2.weight(.semibold)).tracking(1.4)
                .foregroundStyle(.secondary)
            Text("Place the subject center").font(.subheadline.weight(.medium))
            Text("The camera and lights using Aim at subject follow this point. Coordinates are in \(units == .metric ? "meters" : "feet") from the scene origin.")
                .font(.caption).foregroundStyle(.secondary)
            slider("Subject horizontal", value: $position.x, range: -4...4,
                   step: 0.05, id: "subjectX")
            slider("Subject height", value: $position.y, range: 0...4,
                   step: 0.05, id: "subjectY")
            HStack(spacing: 8) {
                heightPreset("Standing", height: 1.5, id: "subjectStandingHeight")
                heightPreset("Seated", height: 1.1, id: "subjectSeatedHeight")
            }
            Text("Starting heights for the subject center above the ground plane. Adjust to your measured setup.")
                .font(.caption).foregroundStyle(.secondary)
            slider("Subject depth", value: $position.z, range: -6...6,
                   step: 0.05, id: "subjectZ")
        }
    }

    private func heightPreset(_ title: String, height: Double, id: String) -> some View {
        let selected = position.y == height
        let display = DistanceValueButton.formattedValue(height, units: units, locale: locale)
        return Button {
            position.y = height
        } label: {
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Text(title)
                    if selected {
                        Image(systemName: "checkmark").accessibilityHidden(true)
                    }
                }
                Text(display).monospacedDigit()
            }
            .font(.caption.weight(.medium))
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(selected ? Color.accentColor.opacity(0.16) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel("\(title) subject center height")
            .accessibilityValue(display)
            .accessibilityHint("Sets the subject height and keeps its horizontal and depth positions")
            .accessibilityIdentifier(id)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        step: Double, id: String) -> some View {
        // Preserve valid imported positions even outside the initial editing range.
        let bounds = StudioNumericInput.sliderBounds(usual: range, current: value.wrappedValue)
        let units = self.units
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(title) (\(units.symbol))").font(.subheadline.weight(.medium))
                Spacer()
                DistanceValueButton(title: title, id: id, value: value, range: Position.coordinateRange)
            }
            StudioSlider(value: value, in: bounds, step: step,
                         accessibility: .init(label: title + " in " + (units == .metric ? "meters" : "feet"),
                                              value: { [locale] in DistanceValueButton.formattedValue($0, units: units, locale: locale) },
                                              identifier: id)) { editing in
                onEditingChanged(editing, id)
            }
        }
    }
}
