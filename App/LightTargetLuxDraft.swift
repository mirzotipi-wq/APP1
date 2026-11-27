import Foundation
import LightingCore

/// Retains the number format that accepted a target-lux draft. A locale
/// change cannot make unchanged text eligible for a different interpretation.
struct LightTargetLuxDraft {
    struct LocaleContext: Equatable {
        let identifier: String
        let decimalSeparator: String

        init(locale: Locale) {
            // Store values, not a potentially autoupdating Locale instance.
            identifier = locale.identifier
            decimalSeparator = locale.decimalSeparator ?? "."
        }
    }

    private(set) var text = ""
    private(set) var rejectedOversizedDraft = false
    private var acceptedLocale: LocaleContext?
    private var localeInvalidated = false

    mutating func initialize(value: Double?, in context: LocaleContext) {
        guard acceptedLocale == nil else { return }
        acceptedLocale = context
        text = value.flatMap {
            StudioNumericInput.editableText($0, decimalSeparator: context.decimalSeparator)
        } ?? ""
    }

    func requiresLocaleEdit(in context: LocaleContext) -> Bool {
        localeInvalidated || acceptedLocale.map { $0 != context } == true
    }

    mutating func invalidate(ifChangedTo context: LocaleContext) {
        guard let acceptedLocale, acceptedLocale != context else { return }
        // Returning to the original locale must not revive a retired draft.
        localeInvalidated = true
    }

    /// True means an actual bounded edit, the only event that may clear the
    /// view's existing validation error or adopt the current number format.
    mutating func replaceText(with replacement: String, in context: LocaleContext) -> Bool {
        guard StudioNumericInput.isWithinDraftLimit(replacement) else {
            rejectedOversizedDraft = true
            return false
        }
        guard replacement != text else { return false }
        text = replacement
        acceptedLocale = context
        localeInvalidated = false
        rejectedOversizedDraft = false
        return true
    }

    func target(in context: LocaleContext) -> Double? {
        // Check immediately for preview and Apply, before onChange may run.
        guard let acceptedLocale, acceptedLocale == context, !localeInvalidated,
              text.utf8.prefix(97).count <= 96 else { return nil }
        return StudioNumericInput.parse(text, decimalSeparator: acceptedLocale.decimalSeparator,
                                        in: 0...Double.greatestFiniteMagnitude)
    }
}
