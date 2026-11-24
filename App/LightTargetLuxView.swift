import LightingCore
import SwiftUI

/// Sets one source's modeled contribution without changing its geometry.
struct LightTargetLuxView: View {
    let light: StudioLight
    let scene: LightingScene
    let onApply: (StudioLight) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var draft = ""
    @State private var error: String?
    @FocusState private var inputFocused: Bool

    private var target: Double? {
        StudioNumericInput.parse(draft, decimalSeparator: locale.decimalSeparator ?? ".",
                                 in: 0...Double.greatestFiniteMagnitude)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Target contribution") {
                    Text(StudioDisplayName.label(light.name, fallback: "Selected light"))
                        .font(.headline)
                    if let current = StudioPhotometry.illuminance(for: light, in: scene) {
                        LabeledContent("Current ideal illuminance",
                                       value: StudioNumericInput.formattedValue(current, unit: "lx", locale: locale))
                    }
                    HStack {
                        TextField("Desired lux", text: $draft)
                            .keyboardType(.decimalPad).focused($inputFocused)
                            .accessibilityIdentifier("targetLuxInput")
                        Text("lx").foregroundStyle(.secondary)
                    }
                    if let value = target, let adjusted = try? LightOutputAdjustment.light(light, targetingLux: value, in: scene) {
                        LabeledContent("Required intensity",
                            value: StudioNumericInput.formattedValue(adjusted.candela, unit: "cd", locale: locale))
                    }
                }
                Section {
                    Text("The calculation uses this light alone on the ideal camera-facing plane at the subject center. It does not measure skin exposure, camera settings or a real fixture. Other lights are unchanged.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("A target of zero switches this source off. If the requested output exceeds the model's limits or the light cannot illuminate the plane, change the target or geometry.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let error {
                    Section { Label(error, systemImage: "exclamationmark.triangle") }
                }
                Section {
                    Button("Apply to light") { apply() }
                        .disabled(target == nil)
                        .accessibilityIdentifier("applyTargetLux")
                }
            }
            .navigationTitle("Set ideal lux")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { inputFocused = false }
                }
            }
            .onAppear {
                if draft.isEmpty, let current = StudioPhotometry.illuminance(for: light, in: scene) {
                    draft = StudioNumericInput.editableText(current, decimalSeparator: locale.decimalSeparator ?? ".") ?? ""
                }
            }
            .onChange(of: draft) { _, _ in error = nil }
        }
    }

    private func apply() {
        guard let target else { return }
        do {
            let adjusted = try LightOutputAdjustment.light(light, targetingLux: target, in: scene)
            onApply(adjusted)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
