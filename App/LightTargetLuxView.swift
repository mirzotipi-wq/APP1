import LightingCore
import SwiftUI

/// Sets one source's modeled contribution without changing its geometry.
struct LightTargetLuxView: View {
    let light: StudioLight
    let scene: LightingScene
    let onApply: (StudioLight) -> Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var draft = LightTargetLuxDraft()
    @State private var error: String?
    @State private var didApply = false
    @State private var inputFocused = false

    private var inputLocale: LightTargetLuxDraft.LocaleContext { .init(locale: locale) }
    private var target: Double? { draft.target(in: inputLocale) }

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
                        StudioTextField("Desired lux", text: boundedDraft, isFocused: $inputFocused,
                            accessibility: .init(label: "Desired illuminance in lux", identifier: "targetLuxInput",
                                hint: "Enter zero to switch this light off."), keyboardType: .decimalPad)
                        Text("lx").foregroundStyle(StudioPalette.secondaryText)
                    }
                    if draft.requiresLocaleEdit(in: inputLocale) {
                        Text("Your number format changed. Edit the value before applying.")
                            .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                            .accessibilityIdentifier("targetLuxLocaleError")
                    } else if !draft.text.isEmpty && target == nil {
                        Text("Enter zero or a positive decimal number using up to 32 characters.")
                            .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                    }
                    if let value = target, let adjusted = try? LightOutputAdjustment.light(light, targetingLux: value, in: scene) {
                        LabeledContent("Required intensity",
                            value: StudioNumericInput.formattedValue(adjusted.candela, unit: "cd", locale: locale))
                    }
                }
                Section {
                    Text("The calculation uses this light alone on the ideal camera-facing plane at the subject center. It does not measure skin exposure, camera settings or a real fixture. Other lights are unchanged.")
                        .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                    Text("A target of zero switches this source off. If the requested output exceeds the model's limits or the light cannot illuminate the plane, change the target or geometry.")
                        .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .accessibilityIdentifier("targetLuxError")
                    }
                }
                Section {
                    Button { apply() } label: {
                        Text("Apply to light")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                        .disabled(target == nil || draft.rejectedOversizedDraft || didApply)
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
                draft.initialize(value: StudioPhotometry.illuminance(for: light, in: scene), in: inputLocale)
            }
            .onChange(of: inputLocale) { _, next in
                draft.invalidate(ifChangedTo: next)
                if draft.requiresLocaleEdit(in: next) { inputFocused = false }
            }
        }
        .tint(StudioPalette.action)
    }

    private var boundedDraft: Binding<String> {
        Binding(get: { draft.text }, set: { replacement in
            // Reject the entire replacement before storing it. Truncating a
            // pasted number could silently select a different light output.
            let changed = draft.replaceText(with: replacement, in: inputLocale)
            if draft.rejectedOversizedDraft {
                error = "That entry is too long. Your previous entry was kept. Edit the value before applying."
            } else if changed {
                error = nil
            }
        })
    }

    private func apply() {
        guard !didApply, !draft.rejectedOversizedDraft, let target else { return }
        do {
            let adjusted = try LightOutputAdjustment.light(light, targetingLux: target, in: scene)
            // Block reentrant taps while the parent decides whether this draft
            // still belongs to the selected light. Keep the entry on rejection.
            didApply = true
            guard onApply(adjusted) else {
                didApply = false
                error = "The light could not be updated. Your entry is still here. Try again, or cancel and reopen Set ideal lux."
                return
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
