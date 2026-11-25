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
    // A conversion can give distinct model values identical display bits.
    var underlyingValue: Binding<Double>? = nil
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
                                 underlyingValue: underlyingValue,
                                 isPresented: $showingEditor)
        }
    }
}

private struct PrecisionValueEditor: View {
    let title: String
    let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var underlyingValue: Binding<Double>? = nil
    @Binding var isPresented: Bool
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var focused: Bool
    @State private var draft = ""
    @State private var initialDraft = ""
    @State private var requiresReplacementDraft = false
    @State private var inputError: InputError?
    @State private var active = false
    @State private var originalValueBits: UInt64?
    @State private var originalUnderlyingValueBits: UInt64?
    @State private var originalLocale = Locale.current
    @State private var originalRange: ClosedRange<Double>?

    private enum InputError: Equatable {
        case invalidDecimal
        case oversizedDraft

        var message: String {
            switch self {
            case .invalidDecimal:
                return "Enter a valid decimal within the allowed range."
            case .oversizedDraft:
                return "That entry is too long. Your previous entry was kept. Edit the value before applying."
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    editorHeading
                    if requiresReplacementDraft {
                        Text("Current value: \(StudioNumericInput.formattedValue(value, unit: unit, locale: locale))")
                            .font(.body.monospacedDigit())
                            .accessibilityIdentifier("precisionPreservedValue")
                        Text("This value needs scientific notation. Leave the field empty to keep it, or enter a new decimal value.")
                            .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                    }
                    HStack {
                        TextField("Value", text: boundedDraft)
                            .font(.body.monospacedDigit())
                            .frame(minHeight: 44)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focused)
                            .accessibilityLabel(title + " in " + unit)
                            .accessibilityHint(inputError?.message ?? "Enter a decimal value within the allowed range.")
                            .accessibilityIdentifier("precisionValue")
                            .onSubmit { apply() }
                        Text(unit).font(.body).foregroundStyle(StudioPalette.secondaryText)
                    }
                    if let inputError {
                        Label(inputError.message,
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("precisionError")
                    }
                    Button { apply() } label: {
                        Text("Apply value")
                            .font(.body.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                        .foregroundStyle(StudioPalette.action)
                        .disabled(inputError == .oversizedDraft)
                        .accessibilityIdentifier("precisionApply")
                } footer: {
                    Text("Allowed: \(format(range.lowerBound)) to \(format(range.upperBound)) \(unit). No grouping or scientific notation. The value is not snapped to slider increments.")
                        .font(.footnote)
                        .foregroundStyle(StudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard originalValueBits == nil else { return }
                originalValueBits = value.bitPattern
                originalUnderlyingValueBits = underlyingValue?.wrappedValue.bitPattern
                originalLocale = locale
                originalRange = range
                let exact = StudioNumericInput.editableText(value, decimalSeparator: locale.decimalSeparator ?? ".")
                requiresReplacementDraft = exact == nil
                initialDraft = exact ?? ""
                draft = initialDraft
                active = true
            }
            .onChange(of: value.bitPattern) { _, _ in if active { cancel() } }
            .onChange(of: underlyingValue?.wrappedValue.bitPattern) { _, _ in if active { cancel() } }
            .onChange(of: locale) { _, _ in if active { cancel() } }
            .onChange(of: range) { _, _ in if active { cancel() } }
            .onDisappear { active = false }
        }
        .tint(StudioPalette.action)
    }

    private var boundedDraft: Binding<String> {
        Binding(get: { draft }, set: { replacement in
            // Reject before assigning SwiftUI state. Truncation could turn a
            // pasted number into a different, apparently valid scene value.
            guard StudioNumericInput.isWithinDraftLimit(replacement) else {
                inputError = .oversizedDraft
                return
            }
            guard replacement != draft else { return }
            draft = replacement
            inputError = nil
        })
    }

    /// Ordinary Form content can grow with its text, including while the
    /// keyboard is open; the native navigation bar has a fixed control height.
    private var editorHeading: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            Text("Exact value")
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Button { cancel() } label: {
                Text("Cancel")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(StudioPalette.action)
            .accessibilityIdentifier("precisionCancel")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
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
        // Read the live source even if a view update has not yet observed it;
        // converting distinct source values can collapse their displayed bits.
        guard value.bitPattern == originalValueBits, locale == originalLocale,
              underlyingValue?.wrappedValue.bitPattern == originalUnderlyingValueBits,
              range == originalRange else { cancel(); return }
        // A rejected paste is not permission to apply the preceding draft.
        // The next bounded edit clears this error, including delete/retype.
        if case .oversizedDraft? = inputError { return }
        // Applying untouched formatted text must not round an imported value.
        if draft == initialDraft {
            cancel(); return
        }
        guard let next = StudioNumericInput.parse(draft, decimalSeparator: locale.decimalSeparator ?? ".",
                                                  in: range) else {
            inputError = .invalidDecimal
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
