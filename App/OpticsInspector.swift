import SwiftUI
import LightingCore

/// Optical controls share the scene's undo transaction, not a second edit state.
struct OpticsInspector: View {
    @Binding var optics: LightOptics
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EMITTER & AIM").font(.caption2.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
            Menu {
                ForEach(EmitterKind.allCases, id: \.self) { kind in
                    Button {
                        guard optics.kind != kind else { return }
                        onEditingChanged(true, "emitterKind")
                        var next = optics; next.kind = kind; optics = next
                        onEditingChanged(false, "emitterKind")
                    } label: {
                        if kind == optics.kind { Label(kind.title, systemImage: "checkmark") }
                        else { Text(kind.title) }
                    }
                }
            } label: {
                fieldLayout {
                    Text("Emitter").foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(alignment: .firstTextBaseline) {
                        Text(optics.kind.title).fontWeight(.medium)
                        Image(systemName: "chevron.up.chevron.down").font(.caption)
                    }
                }.frame(minHeight: 44)
            }
            .accessibilityLabel("Emitter type")
            .accessibilityValue(Text(optics.kind.title))
            .accessibilityIdentifier("emitterKind")
            Text(explanation).font(.caption).foregroundStyle(.secondary)

            if optics.kind.isAimed {
                Toggle("Aim at subject", isOn: Binding(
                    get: { optics.aimTarget == nil },
                    set: { follows in
                        guard follows != (optics.aimTarget == nil) else { return }
                        onEditingChanged(true, "aimAtSubject")
                        var next = optics; next.aimTarget = follows ? nil : subject; optics = next
                        onEditingChanged(false, "aimAtSubject")
                    }
                )).accessibilityIdentifier("aimAtSubject")
                if optics.aimTarget != nil {
                    Text("Target position · world \(units == .metric ? "meters" : "feet")")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    slider("Aim X", value: aimCoordinate(\.x), range: -4...4, domain: Position.coordinateRange, step: 0.05, id: "aimX")
                    slider("Aim Y", value: aimCoordinate(\.y), range: 0...4, domain: Position.coordinateRange, step: 0.05, id: "aimY")
                    slider("Aim Z", value: aimCoordinate(\.z), range: -4...4, domain: Position.coordinateRange, step: 0.05, id: "aimZ")
                }
            }
            if optics.kind == .rectangle {
                Divider()
                Text("Diffusion surface").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                slider("Width", value: dimension(\.widthMeters), range: 0.05...4, domain: LightOptics.dimensionRange, step: 0.05, id: "emitterWidth")
                slider("Height", value: dimension(\.heightMeters), range: 0.05...4, domain: LightOptics.dimensionRange, step: 0.05, id: "emitterHeight")
                slider("Roll", value: roll, range: LightOptics.rollRange, domain: LightOptics.rollRange,
                       step: 1, measurement: .angle, id: "emitterRoll")
            }
        }
    }

    private var explanation: String {
        switch optics.kind {
        case .point: return "Equal intensity in every direction; aiming is not applicable."
        case .directional: return "Ideal cosine falloff from the aiming direction, not a calibrated beam profile."
        case .rectangle: return "Uniform rectangular diffuser. Width, height and roll define the diffusion surface; the 3D shading remains illustrative."
        }
    }

    private func dimension(_ key: WritableKeyPath<LightOptics, Double>) -> Binding<Double> {
        Binding(get: { optics[keyPath: key] }, set: { value in
            var next = optics; next[keyPath: key] = value; optics = next
        })
    }

    private var roll: Binding<Double> {
        Binding(get: { optics.effectiveRollDegrees }, set: { value in
            var next = optics; next.rollDegrees = value; optics = next
        })
    }

    private func aimCoordinate(_ key: WritableKeyPath<Position, Double>) -> Binding<Double> {
        Binding(get: { (optics.aimTarget ?? subject)[keyPath: key] }, set: { value in
            guard var target = optics.aimTarget else { return }
            target[keyPath: key] = value
            var next = optics; next.aimTarget = target; optics = next
        })
    }

    private enum Measurement: Equatable { case distance, angle }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        domain: ClosedRange<Double>, step: Double, measurement: Measurement = .distance,
                        id: String) -> some View {
        // A migrated or externally authored valid target may be outside the usual studio range.
        let actual = value.wrappedValue
        let limits = StudioNumericInput.sliderBounds(usual: range, current: actual)
        let units = self.units
        return VStack(alignment: .leading, spacing: 4) {
            fieldLayout {
                Text(title).font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if measurement == .distance {
                    DistanceValueButton(title: title, id: id, value: value, range: domain)
                } else {
                    PrecisionValueButton(title: title, unit: "°", id: id, value: value, range: domain)
                }
            }
            StudioSlider(value: value, in: limits, step: step,
                         accessibility: .init(label: measurement == .distance
                                              ? title + " in " + (units == .metric ? "meters" : "feet") : title,
                                              value: { [locale] in
                                                  measurement == .distance
                                                      ? DistanceValueButton.formattedValue($0, units: units, locale: locale)
                                                      : StudioNumericInput.formattedValue($0, unit: "°", locale: locale)
                                              },
                                              identifier: id)) { editing in
                onEditingChanged(editing, id)
            }
        }
    }
}
