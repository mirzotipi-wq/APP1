import SwiftUI
import LightingCore

/// A diagnostic 18% neutral card, separate from the uncalibrated 3D renderer.
struct NeutralCardInspector: View {
    let scene: LightingScene
    @Binding var settings: PreviewSettings
    let onEditingChanged: (Bool, String) -> Void
    @Environment(\.locale) private var locale
    @State private var sample: Sample?

    private struct Sample {
        let scene: LightingScene
        let card: NeutralCardPreview?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let sample, sample.scene == scene {
                    if let card = sample.card {
                        cardView(card)
                    } else {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("Meter unavailable", systemImage: "exclamationmark.triangle")
                                .font(.subheadline.weight(.semibold))
                            Text("Check the camera position and active emitters. An unsupported light invalidates the combined estimate.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                } else {
                    ProgressView("Updating test card").font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
            slider("White balance", value: $settings.whiteBalanceKelvin,
                   range: PreviewSettings.whiteBalanceRange, step: 100, unit: "K",
                   id: "previewWhiteBalance")
            HStack(spacing: 0) {
                ForEach([3200.0, 5600.0, 6500.0], id: \.self) { k in
                    Button {
                        settings.whiteBalanceKelvin = k
                    } label: {
                        Text("\(Int(k)) K")
                            .font(.caption.monospacedDigit().weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(settings.whiteBalanceKelvin == k ? Color.accentColor.opacity(0.16) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                        .accessibilityLabel("Balance \(Int(k)) kelvin")
                        .accessibilityIdentifier("balance-\(Int(k))")
                        .accessibilityAddTraits(settings.whiteBalanceKelvin == k ? .isSelected : [])
                }
            }
            slider("Relative exposure", value: $settings.exposureStops,
                   range: PreviewSettings.exposureRange, step: 0.25, unit: "stops",
                   id: "previewExposure")
            Button("Reset card settings") { settings = PreviewSettings() }
                .disabled(settings == PreviewSettings())
                .accessibilityIdentifier("resetCardSettings")
            Text("18% neutral card at subject center, with a relative 1000 lx reference. These controls affect the card and Study viewport, not the illustrative 3D shading. No measured fixture spectra, indirect light, actual camera response or exposure calibration.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .task(id: scene) {
            // Debounce rapid slider changes, compute on a background executor and
            // publish only the result of the current non-cancelled snapshot.
            let snapshot = scene
            do { try await Task.sleep(nanoseconds: 50_000_000) } catch { return }
            let work = Task.detached(priority: .userInitiated) {
                NeutralCardPreview(scene: snapshot)
            }
            let result = await withTaskCancellationHandler(operation: {
                await work.value
            }, onCancel: {
                work.cancel()
            })
            guard !Task.isCancelled else { return }
            sample = Sample(scene: snapshot, card: result)
        }
    }

    private func cardView(_ card: NeutralCardPreview) -> some View {
        let rgb = card.display
        return HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: 1))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1) }
                .frame(width: 80, height: 80)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("COMBINED DIRECT LIGHT").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                Text(StudioMeterReadout.lux(card.totalLux, locale: locale))
                    .font(.system(.title2, design: .monospaced).weight(.semibold))
                    .accessibilityIdentifier("combinedLux")
                Text("Relative 18% card · sRGB")
                    .font(.caption).foregroundStyle(.secondary)
                Text("R \(Int((rgb.red * 255).rounded())) · G \(Int((rgb.green * 255).rounded())) · B \(Int((rgb.blue * 255).rounded()))")
                    .font(.caption2.monospacedDigit())
                    .accessibilityLabel("Red \(Int((rgb.red * 255).rounded())), green \(Int((rgb.green * 255).rounded())), blue \(Int((rgb.blue * 255).rounded()))")
            }
            Spacer(minLength: 0)
        }.padding(12)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        step: Double, unit: String, id: String) -> some View {
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                PrecisionValueButton(title: title, unit: unit, id: id, value: value, range: range)
            }
            StudioSlider(value: value, in: range, step: step,
                         accessibility: .init(label: title,
                                              value: { [locale] in StudioNumericInput.formattedValue($0, unit: unit, locale: locale) },
                                              identifier: id)) { editing in
                onEditingChanged(editing, id)
            }
        }
    }
}
