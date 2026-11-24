import SwiftUI
import LightingCore

/// Optical controls share the scene's undo transaction, not a second edit state.
struct OpticsInspector: View {
    @Binding var optics: LightOptics
    let subject: Position
    let onEditingChanged: (Bool, String) -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EMITTER & AIM").font(.caption2.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
            Menu {
                ForEach(EmitterKind.allCases, id: \.self) { kind in
                    Button {
                        var next = optics; next.kind = kind; optics = next
                    } label: {
                        if kind == optics.kind { Label(kind.title, systemImage: "checkmark") }
                        else { Text(kind.title) }
                    }
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Emitter").foregroundStyle(.primary)
                    Spacer()
                    Text(optics.kind.title).fontWeight(.medium)
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
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
                        var next = optics; next.aimTarget = follows ? nil : subject; optics = next
                    }
                )).accessibilityIdentifier("aimAtSubject")
                if optics.aimTarget != nil {
                    Text("Target position · world meters").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    slider("Aim X", value: aimCoordinate(\.x), range: -4...4, domain: Position.coordinateRange, step: 0.05, id: "aimX")
                    slider("Aim Y", value: aimCoordinate(\.y), range: 0...4, domain: Position.coordinateRange, step: 0.05, id: "aimY")
                    slider("Aim Z", value: aimCoordinate(\.z), range: -4...4, domain: Position.coordinateRange, step: 0.05, id: "aimZ")
                }
            }
            if optics.kind == .rectangle {
                Divider()
                Text("Diffusion surface · meters").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                slider("Width", value: dimension(\.widthMeters), range: 0.05...4, domain: LightOptics.dimensionRange, step: 0.05, id: "emitterWidth")
                slider("Height", value: dimension(\.heightMeters), range: 0.05...4, domain: LightOptics.dimensionRange, step: 0.05, id: "emitterHeight")
            }
        }
    }

    private var explanation: String {
        switch optics.kind {
        case .point: return "Equal intensity in every direction; aiming is not applicable."
        case .directional: return "Ideal cosine falloff from the aiming direction, not a calibrated beam profile."
        case .rectangle: return "Uniform rectangular diffuser. Width and height affect the ideal lux estimate; the 3D shading remains illustrative."
        }
    }

    private func dimension(_ key: WritableKeyPath<LightOptics, Double>) -> Binding<Double> {
        Binding(get: { optics[keyPath: key] }, set: { value in
            var next = optics; next[keyPath: key] = value; optics = next
        })
    }

    private func aimCoordinate(_ key: WritableKeyPath<Position, Double>) -> Binding<Double> {
        Binding(get: { (optics.aimTarget ?? subject)[keyPath: key] }, set: { value in
            guard var target = optics.aimTarget else { return }
            target[keyPath: key] = value
            var next = optics; next.aimTarget = target; optics = next
        })
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, domain: ClosedRange<Double>, step: Double, id: String) -> some View {
        // A migrated or externally authored valid target may be outside the usual studio range.
        let actual = value.wrappedValue
        let limits = StudioNumericInput.sliderBounds(usual: range, current: actual)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                PrecisionValueButton(title: title, unit: "m", id: id, value: value, range: domain)
            }
            Slider(value: value, in: limits, step: step) { editing in
                onEditingChanged(editing, id)
            }
                .accessibilityLabel(title)
                .accessibilityValue(StudioNumericInput.formattedValue(actual, unit: "m", locale: locale))
                .accessibilityIdentifier(id)
        }
    }
}
