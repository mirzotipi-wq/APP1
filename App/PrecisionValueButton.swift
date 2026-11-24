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
                Text(display).font(.subheadline.monospacedDigit())
                Image(systemName: "pencil").font(.caption2)
            }
            .padding(.horizontal, 4)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel("Enter exact " + title.lowercased())
        .accessibilityValue(display)
        .accessibilityHint("Opens a numeric editor")
        .accessibilityIdentifier(id + "Exact")
        .sheet(isPresented: $showingEditor) {
            PrecisionValueEditor(title: title, unit: unit, value: $value, range: range)
        }
    }
}

private struct PrecisionValueEditor: View {
    let title: String
    let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var draft = ""
    @State private var initialDraft = ""
    @State private var invalid = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
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
                        Text(unit).foregroundStyle(.secondary)
                    }
                    if invalid {
                        Label("Enter a valid decimal within the allowed range.",
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.primary)
                            .accessibilityIdentifier("precisionError")
                    }
                    Button("Apply value") { apply() }
                        .fontWeight(.semibold)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("precisionApply")
                } header: {
                    Text("Exact value")
                } footer: {
                    Text("Allowed: \(format(range.lowerBound)) to \(format(range.upperBound)) \(unit). No grouping or scientific notation. The value is not snapped to slider increments.")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("precisionCancel")
                }
            }
            .onAppear {
                initialDraft = format(value)
                draft = initialDraft
            }
            .onChange(of: draft) { _, _ in invalid = false }
        }
    }

    private func format(_ number: Double) -> String {
        // ASCII digits plus the user's decimal separator avoid hidden bidi
        // marks in editable text while accepting local decimal digits on input.
        let posix = number.formatted(.number.precision(.fractionLength(0...12))
            .grouping(.never).locale(Locale(identifier: "en_US_POSIX")))
        return posix.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
    }

    private func apply() {
        // Applying untouched formatted text must not round an imported value.
        if draft == initialDraft {
            focused = false; dismiss(); return
        }
        guard let next = StudioNumericInput.parse(draft, decimalSeparator: locale.decimalSeparator ?? ".",
                                                  in: range) else {
            invalid = true
            return
        }
        value = next
        focused = false
        dismiss()
    }
}
