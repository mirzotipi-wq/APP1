import SwiftUI
import LightingCore

/// The displayed value is an editing action as well as a readout. Draft
/// changes never touch the scene until an explicit, validated Apply.
struct PrecisionValueButton: View {
    let title: String
    let unit: String
    let id: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    // Compact visual text leaves the accessible value and editor exact.
    var visualReadout: String? = nil
    @Environment(\.locale) private var locale
    @State private var showingEditor = false

    private var display: String {
        StudioNumericInput.formattedValue(value, unit: unit, locale: locale)
    }

    var body: some View {
        Button {
            showingEditor = true
        } label: {
            HStack(spacing: 5) {
                Text(visualReadout ?? display).font(.subheadline.monospacedDigit())
                Image(systemName: "pencil").font(.caption2)
            }
            .padding(.horizontal, 4)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(StudioPalette.action)
        .accessibilityLabel("Enter exact " + title.lowercased())
        .accessibilityValue(display)
        .accessibilityHint("Opens a numeric editor")
        .accessibilityIdentifier(id + "Exact")
        .sheet(isPresented: $showingEditor) {
            PrecisionValueEditor(title: title, unit: unit, value: $value, range: range,
                                 isPresented: $showingEditor)
        }
    }
}

private struct PrecisionValueEditor: View {
    let title: String
    let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    @Binding var isPresented: Bool
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var draft = ""
    @State private var initialDraft = ""
    @State private var requiresReplacementDraft = false
    @State private var invalid = false
    @State private var active = false
    @State private var originalValueBits: UInt64?
    @State private var originalLocale = Locale.current
    @State private var originalRange: ClosedRange<Double>?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if requiresReplacementDraft {
                        Text("Current value: \(StudioNumericInput.formattedValue(value, unit: unit, locale: locale))")
                            .font(.body.monospacedDigit())
                            .accessibilityIdentifier("precisionPreservedValue")
                        Text("This value needs scientific notation. Leave the field empty to keep it, or enter a new decimal value.")
                            .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                    }
                    HStack {
                        TextField("Value", text: $draft)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focused)
                            .accessibilityLabel(title + " in " + unit)
                            .accessibilityIdentifier("precisionValue")
                            .onSubmit { apply() }
                        Text(unit).font(.body).foregroundStyle(StudioPalette.secondaryText)
                    }
                    if invalid {
                        Label("Enter a valid decimal within the allowed range.",
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.primary)
                            .accessibilityIdentifier("precisionError")
                    }
                    Button("Apply value") { apply() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(StudioPalette.action)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("precisionApply")
                } header: {
                    Text("Exact value")
                        .font(.headline)
                        .foregroundStyle(StudioPalette.secondaryText)
                } footer: {
                    Text("Allowed: \(format(range.lowerBound)) to \(format(range.upperBound)) \(unit). No grouping or scientific notation. The value is not snapped to slider increments.")
                        .font(.footnote)
                        .foregroundStyle(StudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { cancel() } label: {
                        Text("Cancel").font(.body)
                    }
                    .accessibilityIdentifier("precisionCancel")
                }
            }
            .onAppear {
                guard originalValueBits == nil else { return }
                originalValueBits = value.bitPattern
                originalLocale = locale
                originalRange = range
                let exact = StudioNumericInput.editableText(value, decimalSeparator: locale.decimalSeparator ?? ".")
                requiresReplacementDraft = exact == nil
                initialDraft = exact ?? ""
                draft = initialDraft
                active = true
            }
            .onChange(of: draft) { _, _ in invalid = false }
            .onChange(of: value.bitPattern) { _, _ in if active { cancel() } }
            .onChange(of: locale) { _, _ in if active { cancel() } }
            .onChange(of: range) { _, _ in if active { cancel() } }
            .onDisappear { active = false }
        }
        .tint(StudioPalette.action)
    }

    private func format(_ number: Double) -> String {
        // ASCII digits plus the user's decimal separator avoid hidden bidi
        // marks in editable text while accepting local decimal digits on input.
        StudioNumericInput.editableText(number, decimalSeparator: locale.decimalSeparator ?? ".") ??
            StudioNumericInput.formattedValue(number, locale: locale)
    }

    private func apply() {
        // A stale keyboard submission must not overwrite an external edit or
        // reinterpret digits after the presentation's locale has changed.
        guard active, isPresented else { return }
        guard value.bitPattern == originalValueBits, locale == originalLocale,
              range == originalRange else { cancel(); return }
        // Applying untouched formatted text must not round an imported value.
        if draft == initialDraft {
            cancel(); return
        }
        guard let next = StudioNumericInput.parse(draft, decimalSeparator: locale.decimalSeparator ?? ".",
                                                  in: range) else {
            invalid = true
            return
        }
        active = false
        // Equivalent decimal spellings preserve the stored bits (and signed
        // zero), and do not create a redundant history entry.
        if next != value { value = next }
        focused = false
        isPresented = false
        dismiss()
    }

    private func cancel() {
        active = false
        focused = false
        isPresented = false
        dismiss()
    }
}
