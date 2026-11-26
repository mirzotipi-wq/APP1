import SwiftUI
import LightingCore

/// Ideal full-frame perspective; no depth-of-field or lens distortion simulation.
struct CameraInspector: View {
    @Binding var position: Position
    @Binding var lens: CameraLens
    let subject: Position
    let onEditingChanged: (Bool, String) -> Void
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRawValue = PlanUnits.metric.rawValue

    private var units: PlanUnits { StudioPreferences.units(from: unitsRawValue) }

    private var fieldLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
    }

    private var framing: CameraFraming? {
        CameraFraming(scene: LightingScene(subject: subject, camera: position, lights: [], cameraLens: lens))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CAMERA FRAMING").font(.caption2.weight(.semibold)).tracking(1.4)
                .foregroundStyle(StudioPalette.secondaryText)
            Text("Full frame · 36 × 24 mm").font(.subheadline.weight(.medium))
            if let framing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(coverageNumber(framing.subjectPlaneWidthMeters)) × \(coverageNumber(framing.subjectPlaneHeightMeters)) \(units.symbol)")
                        .font(.title3.monospacedDigit().weight(.semibold))
                    Text("Coverage at subject · \(coverageNumber(framing.subjectDistanceMeters)) \(units.symbol) distance")
                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    Text("Field of view: \(framing.horizontalFieldOfViewDegrees, specifier: "%.1f")° H / \(framing.verticalFieldOfViewDegrees, specifier: "%.1f")° V")
                        .font(.caption.monospacedDigit()).foregroundStyle(StudioPalette.secondaryText)
                }.accessibilityElement(children: .combine).accessibilityIdentifier("cameraCoverage")
            } else {
                Label("Move camera away from subject", systemImage: "exclamationmark.triangle")
                    .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
            }
            slider("Focal length", value: $lens.focalLengthMillimeters,
                   range: CameraLens.focalLengthRange, domain: CameraLens.focalLengthRange,
                   step: 1, unit: "mm", id: "cameraFocalLength")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0),
                                     count: dynamicTypeSize.isAccessibilitySize ? 2 : 5), spacing: 8) {
                ForEach([24.0, 35.0, 50.0, 85.0, 135.0], id: \.self) { mm in
                    Button {
                        guard lens.focalLengthMillimeters != mm else { return }
                        let id = "cameraFocalLengthPreset-\(Int(mm))"
                        onEditingChanged(true, id)
                        lens.focalLengthMillimeters = mm
                        onEditingChanged(false, id)
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(Int(mm))")
                                .fixedSize(horizontal: false, vertical: true)
                            Image(systemName: lens.focalLengthMillimeters == mm ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(lens.focalLengthMillimeters == mm
                                                 ? StudioPalette.selection : StudioPalette.secondaryText)
                        }
                        .font(.caption.monospacedDigit().weight(.medium))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(lens.focalLengthMillimeters == mm ? StudioPalette.selection.opacity(0.12) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityLabel("\(Int(mm)) millimeter lens")
                        .accessibilityIdentifier("cameraFocalLengthPreset-\(Int(mm))")
                        .accessibilityAddTraits(lens.focalLengthMillimeters == mm ? .isSelected : [])
                }
            }
            distanceSlider("Camera horizontal", value: $position.x, range: -4...4, step: 0.05, id: "cameraX")
            distanceSlider("Camera height", value: $position.y, range: 0...4, step: 0.05, id: "cameraY")
            distanceSlider("Camera depth", value: $position.z, range: -6...6, step: 0.05, id: "cameraZ")
            Text("Ideal perspective aimed at the subject center. No optical distortion, depth of field or calibrated image exposure.")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
        }
        .tint(StudioPalette.action)
    }

    private func coverageNumber(_ meters: Double) -> String {
        units.fromMeters(meters).formatted(.number.precision(.fractionLength(2)).locale(locale))
    }

    private func distanceSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                                step: Double, id: String) -> some View {
        let bounds = StudioNumericInput.sliderBounds(usual: range, current: value.wrappedValue)
        let units = self.units
        return VStack(alignment: .leading, spacing: 4) {
            fieldLayout {
                Text("\(title) (\(units.symbol))").font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, domain: ClosedRange<Double>,
                        step: Double, unit: String, id: String) -> some View {
        // Preserve valid imported positions even outside the initial editing range.
        let bounds = StudioNumericInput.sliderBounds(usual: range, current: value.wrappedValue)
        return VStack(alignment: .leading, spacing: 4) {
            fieldLayout {
                Text(title).font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                PrecisionValueButton(title: title, unit: unit, id: id, value: value, range: domain)
            }
            StudioSlider(value: value, in: bounds, step: step,
                         accessibility: .init(label: title,
                                              value: { [locale] in StudioNumericInput.formattedValue($0, unit: unit, locale: locale) },
                                              identifier: id)) { editing in
                onEditingChanged(editing, id)
            }
        }
    }
}
