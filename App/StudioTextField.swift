import SwiftUI
import UIKit

struct StudioTextFieldAccessibility {
    let label: String
    let identifier: String
    var hint: String? = nil
}

/// The editable UIKit element owns both the touch area and accessibility frame.
/// Validation remains in the caller's binding; this bridge never parses or clips.
struct StudioTextField: View {
    let placeholder: String
    let text: Binding<String>
    let isFocused: Binding<Bool>
    let accessibility: StudioTextFieldAccessibility
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType
    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let textAlignment: NSTextAlignment
    let monospacedDigits: Bool
    let onSubmit: () -> Void

    init(_ placeholder: String, text: Binding<String>, isFocused: Binding<Bool>,
         accessibility: StudioTextFieldAccessibility,
         keyboardType: UIKeyboardType = .default, returnKeyType: UIReturnKeyType = .default,
         autocapitalizationType: UITextAutocapitalizationType = .none,
         autocorrectionType: UITextAutocorrectionType = .no,
         textAlignment: NSTextAlignment = .natural, monospacedDigits: Bool = false,
         onSubmit: @escaping () -> Void = {}) {
        self.placeholder = placeholder
        self.text = text
        self.isFocused = isFocused
        self.accessibility = accessibility
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.autocapitalizationType = autocapitalizationType
        self.autocorrectionType = autocorrectionType
        self.textAlignment = textAlignment
        self.monospacedDigits = monospacedDigits
        self.onSubmit = onSubmit
    }

    var body: some View {
        StudioTextFieldControl(configuration: self)
            .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
    }
}

private struct StudioTextFieldControl: UIViewRepresentable {
    let configuration: StudioTextField
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.sizeCategory) private var sizeCategory

    func makeUIView(context: Context) -> StudioNativeTextField {
        StudioNativeTextField(frame: .zero)
    }

    func updateUIView(_ uiView: StudioNativeTextField, context: Context) {
        uiView.configure(configuration, contentSizeCategory: nativeSizeCategory, isEnabled: isEnabled)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: StudioNativeTextField,
                     context: Context) -> CGSize? {
        let intrinsic = uiView.intrinsicContentSize
        let proposedWidth = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        let width = max(44, proposedWidth ?? intrinsic.width)
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(44, max(intrinsic.height, fitted.height)))
    }

    static func dismantleUIView(_ uiView: StudioNativeTextField, coordinator: ()) {
        uiView.invalidate()
    }

    private var nativeSizeCategory: UIContentSizeCategory {
        switch sizeCategory {
        case .extraSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .extraLarge
        case .extraExtraLarge: return .extraExtraLarge
        case .extraExtraExtraLarge: return .extraExtraExtraLarge
        case .accessibilityMedium: return .accessibilityMedium
        case .accessibilityLarge: return .accessibilityLarge
        case .accessibilityExtraLarge: return .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: return .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
}

/// UIKit keeps its own selection and marked-text state between SwiftUI updates.
/// Only a changed external value, rejected edit, or changed control identity
/// replaces that state. Accepted native edits are never assigned back to `text`.
final class StudioNativeTextField: UITextField, UITextFieldDelegate {
    private var configuration: StudioTextField?
    private var modelText: String?
    private var selectionBeforeEdit: NSRange?
    private var applyingConfiguration = false
    private var replacingText = false
    private var synchronizingFocus = false
    private var lifecycle = UUID()
    private var focusUpdate: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        borderStyle = .none
        clearButtonMode = .never
        textColor = .label
        adjustsFontForContentSizeCategory = true
        isAccessibilityElement = true
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        addTarget(self, action: #selector(nativeTextChanged), for: .editingChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: max(44, size.height))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fitted = super.sizeThatFits(size)
        return CGSize(width: fitted.width, height: max(44, fitted.height))
    }

    func configure(_ next: StudioTextField, contentSizeCategory: UIContentSizeCategory,
                   isEnabled: Bool) {
        applyingConfiguration = true
        defer { applyingConfiguration = false }
        let changedIdentity = configuration.map {
            $0.accessibility.identifier != next.accessibility.identifier
        } ?? false
        if changedIdentity {
            lifecycle = UUID()
            focusUpdate?.cancel()
            focusUpdate = nil
            // A recycled native view must not deliver the previous editor's
            // composition or pending focus request to a different control.
            if isFirstResponder { resignFirstResponder() }
            selectionBeforeEdit = nil
        }
        let initial = configuration == nil
        configuration = next
        placeholder = next.placeholder
        if keyboardType != next.keyboardType { keyboardType = next.keyboardType }
        if returnKeyType != next.returnKeyType { returnKeyType = next.returnKeyType }
        if autocapitalizationType != next.autocapitalizationType {
            autocapitalizationType = next.autocapitalizationType
        }
        if autocorrectionType != next.autocorrectionType { autocorrectionType = next.autocorrectionType }
        if textAlignment != next.textAlignment { textAlignment = next.textAlignment }
        if self.isEnabled != isEnabled { self.isEnabled = isEnabled }
        accessibilityLabel = next.accessibility.label
        accessibilityIdentifier = next.accessibility.identifier
        accessibilityHint = next.accessibility.hint
        tintColor = StudioPalette.actionUIColor
        let traits = UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
        let nextFont = next.monospacedDigits
            ? UIFontMetrics(forTextStyle: .body).scaledFont(
                for: .monospacedDigitSystemFont(ofSize: 17, weight: .regular), compatibleWith: traits)
            : UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
        if font != nextFont { font = nextFont; invalidateIntrinsicContentSize() }

        let external = next.text.wrappedValue
        if initial || changedIdentity {
            modelText = external
            replaceDisplayedText(with: external)
        } else if external != modelText {
            modelText = external
            // An explicit Clear/reset/context change must replace the visible
            // draft immediately, including an active input-method composition.
            replaceDisplayedText(with: external)
        }
        scheduleFocusUpdate()
    }

    func invalidate() {
        lifecycle = UUID()
        focusUpdate?.cancel()
        focusUpdate = nil
        configuration = nil
        modelText = nil
        selectionBeforeEdit = nil
        isEnabled = false
        resignFirstResponder()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { scheduleFocusUpdate() }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard acceptsNativeEvents else { return false }
        selectionBeforeEdit = selectionOffsets()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard acceptsNativeEvents, !synchronizingFocus, let configuration,
              !configuration.isFocused.wrappedValue else { return }
        configuration.isFocused.wrappedValue = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard acceptsNativeEvents, !synchronizingFocus else { return }
        let token = lifecycle
        publishNativeText()
        guard token == lifecycle, let configuration,
              configuration.isFocused.wrappedValue else { return }
        configuration.isFocused.wrappedValue = false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard acceptsNativeEvents, markedTextRange == nil else { return false }
        let token = lifecycle
        publishNativeText()
        guard token == lifecycle, let configuration else { return false }
        // The caller decides whether a valid submit dismisses the keyboard.
        configuration.onSubmit()
        return false
    }

    private var acceptsNativeEvents: Bool {
        configuration != nil && isEnabled && !applyingConfiguration && !replacingText
    }

    @objc private func nativeTextChanged() { publishNativeText() }

    private func publishNativeText() {
        guard acceptsNativeEvents, let configuration else { return }
        let current = configuration.text.wrappedValue
        if current != modelText {
            // A clear/reset can reach the binding before updateUIView. Its new
            // value wins over a late event containing the previous draft.
            modelText = current
            replaceDisplayedText(with: current)
            selectionBeforeEdit = nil
            return
        }
        let replacement = text ?? ""
        guard replacement != current else { selectionBeforeEdit = nil; return }
        let token = lifecycle
        // Keep the caller's raw draft current even while an input method has
        // marked text, so an explicit Save/Apply cannot read an older value.
        // An accepted edit never reassigns native text or disrupts composition.
        configuration.text.wrappedValue = replacement
        guard token == lifecycle, let currentConfiguration = self.configuration else { return }
        let accepted = currentConfiguration.text.wrappedValue
        modelText = accepted
        // Read the caller's binding back even when it rejected the change
        // without changing state. UIKit must not keep displaying that paste.
        if text != accepted { replaceDisplayedText(with: accepted, selection: selectionBeforeEdit) }
        selectionBeforeEdit = nil
    }

    private func replaceDisplayedText(with replacement: String, selection: NSRange? = nil) {
        guard text != replacement else { return }
        let offsets = selection ?? selectionOffsets()
        replacingText = true
        defer { replacingText = false }
        if markedTextRange != nil { unmarkText() }
        text = replacement
        if let offsets {
            let count = replacement.utf16.count
            let start = min(offsets.location, count)
            let end = min(offsets.location + offsets.length, count)
            if let from = position(from: beginningOfDocument, offset: start),
               let to = position(from: beginningOfDocument, offset: max(start, end)) {
                selectedTextRange = textRange(from: from, to: to)
            }
        }
    }

    private func selectionOffsets() -> NSRange? {
        guard let selectedTextRange else { return nil }
        let start = offset(from: beginningOfDocument, to: selectedTextRange.start)
        let end = offset(from: beginningOfDocument, to: selectedTextRange.end)
        guard start >= 0, end >= start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    private func scheduleFocusUpdate() {
        guard configuration != nil, focusUpdate == nil else { return }
        let token = lifecycle
        let update = DispatchWorkItem { [weak self] in
            guard let self, token == self.lifecycle else { return }
            self.focusUpdate = nil
            self.synchronizeFocusRequest()
        }
        focusUpdate = update
        // UIViewRepresentable updates must not publish focus state while
        // SwiftUI is rendering. Coalesce requests and read the latest binding.
        DispatchQueue.main.async(execute: update)
    }

    private func synchronizeFocusRequest() {
        guard let configuration else { return }
        let shouldFocus = configuration.isFocused.wrappedValue && isEnabled
        guard shouldFocus != isFirstResponder else { return }
        if shouldFocus, window == nil { return }
        synchronizingFocus = true
        defer { synchronizingFocus = false }
        if shouldFocus { becomeFirstResponder() } else { resignFirstResponder() }
    }
}
