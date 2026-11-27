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
#if DEBUG
    // Internal injection is for native verification; ordinary builds use the
    // one process-wide, explicitly opted-in recorder below.
    var inputTrace = StudioTextInputTrace.shared
    private lazy var inputTraceControl = inputTrace.makeControlID()
    private var inputTraceMissingWindowReported = false
#endif

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
#if DEBUG
            trace(.identityChange)
            inputTraceMissingWindowReported = false
#endif
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
        if keyboardType != next.keyboardType {
            keyboardType = next.keyboardType
#if DEBUG
            trace(.keyboardConfigurationChanged)
#endif
        }
        if returnKeyType != next.returnKeyType { returnKeyType = next.returnKeyType }
        if autocapitalizationType != next.autocapitalizationType {
            autocapitalizationType = next.autocapitalizationType
        }
        if autocorrectionType != next.autocorrectionType { autocorrectionType = next.autocorrectionType }
        if textAlignment != next.textAlignment { textAlignment = next.textAlignment }
        if self.isEnabled != isEnabled {
            self.isEnabled = isEnabled
#if DEBUG
            trace(.enabledChanged)
#endif
        }
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
#if DEBUG
            trace(.configureInitialValue, binding: external)
#endif
            modelText = external
            replaceDisplayedText(with: external)
        } else if !sameNativeText(external, modelText) {
#if DEBUG
            trace(.configureExternalReset, binding: external)
#endif
            modelText = external
            // An explicit Clear/reset/context change must replace the visible
            // draft immediately, including an active input-method composition.
            replaceDisplayedText(with: external)
        }
        scheduleFocusUpdate()
    }

    func invalidate() {
#if DEBUG
        trace(.invalidate)
        inputTraceMissingWindowReported = false
#endif
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
#if DEBUG
        trace(.windowChanged)
        inputTraceMissingWindowReported = false
#endif
        if window != nil { scheduleFocusUpdate() }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
#if DEBUG
        trace(.delegateEdit, replacement: string, range: range)
#endif
        guard acceptsNativeEvents else {
#if DEBUG
            trace(.delegateEditIgnored)
#endif
            return false
        }
        selectionBeforeEdit = selectionOffsets()
#if DEBUG
        trace(.delegateEditAccepted)
#endif
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
#if DEBUG
        trace(.focusBegan)
#endif
        guard acceptsNativeEvents, !synchronizingFocus, let configuration,
              !configuration.isFocused.wrappedValue else {
#if DEBUG
            trace(.focusBeganIgnored)
#endif
            return
        }
        configuration.isFocused.wrappedValue = true
#if DEBUG
        trace(.focusBindingTrue)
#endif
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
#if DEBUG
        trace(.focusEnded)
#endif
        guard acceptsNativeEvents, !synchronizingFocus else {
#if DEBUG
            trace(.focusEndedIgnored)
#endif
            return
        }
        let token = lifecycle
        publishNativeText()
        guard token == lifecycle, let configuration,
              configuration.isFocused.wrappedValue else {
#if DEBUG
            trace(.focusEndWriteIgnored)
#endif
            return
        }
        configuration.isFocused.wrappedValue = false
#if DEBUG
        trace(.focusBindingFalse)
#endif
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
#if DEBUG
        trace(.submit)
#endif
        guard acceptsNativeEvents, markedTextRange == nil else {
#if DEBUG
            trace(.submitIgnored)
#endif
            return false
        }
        let token = lifecycle
        publishNativeText()
        guard token == lifecycle, let configuration else {
#if DEBUG
            trace(.submitLifecycleChanged)
#endif
            return false
        }
        // The caller decides whether a valid submit dismisses the keyboard.
        configuration.onSubmit()
        return false
    }

    private var acceptsNativeEvents: Bool {
        configuration != nil && isEnabled && !applyingConfiguration && !replacingText
    }

    @objc private func nativeTextChanged() {
#if DEBUG
        trace(.editingChanged)
#endif
        publishNativeText()
    }

    private func publishNativeText() {
        guard acceptsNativeEvents, let configuration else {
#if DEBUG
            trace(.publishIgnored)
#endif
            return
        }
        let current = configuration.text.wrappedValue
#if DEBUG
        trace(.publishBegin, binding: current)
#endif
        if !sameNativeText(current, modelText) {
#if DEBUG
            trace(.publishExternalReset, binding: current)
#endif
            // A clear/reset can reach the binding before updateUIView. Its new
            // value wins over a late event containing the previous draft.
            modelText = current
            replaceDisplayedText(with: current)
            selectionBeforeEdit = nil
            return
        }
        let replacement = text ?? ""
        guard !sameNativeText(replacement, current) else {
#if DEBUG
            trace(.publishUnchanged)
#endif
            selectionBeforeEdit = nil
            return
        }
        let token = lifecycle
        // Keep the caller's raw draft current even while an input method has
        // marked text, so an explicit Save/Apply cannot read an older value.
        // An accepted edit never reassigns native text or disrupts composition.
#if DEBUG
        trace(.bindingWrite, replacement: replacement)
#endif
        configuration.text.wrappedValue = replacement
        guard token == lifecycle, let currentConfiguration = self.configuration else {
#if DEBUG
            trace(.publishLifecycleChanged)
#endif
            return
        }
        let accepted = currentConfiguration.text.wrappedValue
        modelText = accepted
#if DEBUG
        trace(.bindingReadback, binding: accepted)
#endif
        // Read the caller's binding back even when it rejected the change
        // without changing state. UIKit must not keep displaying that paste.
        if !sameNativeText(text, accepted) { replaceDisplayedText(with: accepted, selection: selectionBeforeEdit) }
        selectionBeforeEdit = nil
    }

    private func replaceDisplayedText(with replacement: String, selection: NSRange? = nil) {
        guard !sameNativeText(text, replacement) else { return }
#if DEBUG
        trace(.replaceNativeText, replacement: replacement)
#endif
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

    /// Swift String equality folds canonically equivalent Unicode spellings.
    /// Native editing and selection use exact UTF-16, and a decomposed paste
    /// can exceed a caller's scalar bound even when it compares equal to the
    /// accepted text. Every synchronization boundary must observe that change.
    private func sameNativeText(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return true
        case (let lhs?, let rhs?): return lhs.utf16.elementsEqual(rhs.utf16)
        default: return false
        }
    }

    private func scheduleFocusUpdate() {
        guard configuration != nil, focusUpdate == nil else { return }
        let token = lifecycle
        let update = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard token == self.lifecycle else {
#if DEBUG
                self.trace(.focusLifecycleChanged)
#endif
                return
            }
            self.focusUpdate = nil
            self.synchronizeFocusRequest()
        }
        focusUpdate = update
        // UIViewRepresentable updates must not publish focus state while
        // SwiftUI is rendering. Coalesce requests and read the latest binding.
        DispatchQueue.main.async(execute: update)
    }

    private func synchronizeFocusRequest() {
        guard let configuration else {
#if DEBUG
            trace(.focusRequestUnconfigured)
#endif
            return
        }
        let shouldFocus = configuration.isFocused.wrappedValue && isEnabled
#if DEBUG
        if !shouldFocus { inputTraceMissingWindowReported = false }
#endif
        guard shouldFocus != isFirstResponder else { return }
        if shouldFocus, window == nil {
#if DEBUG
            if !inputTraceMissingWindowReported {
                trace(.focusMissingWindow, requestedFocus: shouldFocus)
                inputTraceMissingWindowReported = true
            }
#endif
            return
        }
#if DEBUG
        inputTraceMissingWindowReported = false
        trace(.focusRequest, requestedFocus: shouldFocus)
#endif
        synchronizingFocus = true
        defer { synchronizingFocus = false }
        if shouldFocus { becomeFirstResponder() } else { resignFirstResponder() }
#if DEBUG
        trace(.focusResult, requestedFocus: shouldFocus)
#endif
    }

#if DEBUG
    private func trace(_ event: StudioTextInputTrace.Event, binding: String? = nil,
                       replacement: String? = nil, range: NSRange? = nil,
                       requestedFocus: Bool? = nil) {
        guard inputTrace.isEnabled else { return }
        let control = inputTraceControl
        guard inputTrace.canRecord(control: control) else { return }
        inputTrace.record(control: control, lifecycle: lifecycle,
                          identifier: configuration?.accessibility.identifier, event: event) {
            // The recorder invokes this only after both budgets and never for
            // a truncation marker. No extra binding getter or focus action.
            // Length257 means at least257 UTF-16 units; equality is unknown
            // when both exceed256, without traversing an unbounded replacement.
            func length(_ value: String?) -> Int? { value.map { $0.utf16.prefix(257).count } }
            let native = text
            let nativeCount = length(native), bindingCount = length(binding)
            let matches: Bool?
            if let binding, (nativeCount ?? 0) <= 256, (bindingCount ?? 0) <= 256 {
                matches = sameNativeText(native, binding)
            } else if binding != nil, (nativeCount == 257) != (bindingCount == 257) {
                matches = false // One value is bounded and the other is longer.
            } else { matches = nil }
            return StudioTextInputTrace.State(
                configured: configuration != nil, enabled: isEnabled,
                firstResponder: isFirstResponder, inWindow: window != nil,
                markedText: markedTextRange != nil, applyingConfiguration: applyingConfiguration,
                replacingText: replacingText, synchronizingFocus: synchronizingFocus,
                nativeUTF16: nativeCount, modelUTF16: length(modelText),
                bindingUTF16: bindingCount, replacementUTF16: length(replacement),
                bindingMatchesNative: matches, requestedFocus: requestedFocus,
                rangeLocation: range?.location, rangeLength: range?.length)
        }
    }
#endif
}

#if DEBUG
/// Opt-in process diagnostics for real input-delivery failures. The full
/// xcresult retains app stdout; compact screenshot attachments alone do not.
/// No raw draft, replacement, label, hint, name or device identifier is stored.
@MainActor
final class StudioTextInputTrace {
    static let environmentKey = "KEYFILL_UI_TEXT_INPUT_TRACE"
    static let shared = StudioTextInputTrace(
        isEnabled: ProcessInfo.processInfo.environment[environmentKey] == "1")
    static let maximumProcessRecords = 512
    static let maximumControlRecords = 256
    let isEnabled: Bool

    enum Event: String, Encodable {
        case identityChange, configureInitialValue, configureExternalReset, keyboardConfigurationChanged, enabledChanged
        case invalidate, windowChanged, delegateEdit, delegateEditIgnored, delegateEditAccepted
        case focusBegan, focusBeganIgnored, focusBindingTrue, focusEnded, focusEndedIgnored
        case focusEndWriteIgnored, focusBindingFalse, submit, submitIgnored, submitLifecycleChanged
        case editingChanged, publishIgnored, publishBegin, publishExternalReset, publishUnchanged
        case bindingWrite, bindingReadback, publishLifecycleChanged, replaceNativeText
        case focusLifecycleChanged, focusRequestUnconfigured, focusRequest, focusMissingWindow, focusResult
        case controlLimit, processLimit
    }

    struct State: Encodable {
        let configured, enabled, firstResponder, inWindow, markedText: Bool
        let applyingConfiguration, replacingText, synchronizingFocus: Bool
        let nativeUTF16, modelUTF16, bindingUTF16, replacementUTF16: Int?
        let bindingMatchesNative, requestedFocus: Bool?
        let rangeLocation, rangeLength: Int?
    }

    private struct Record: Encodable {
        let version = 1
        let sequence, control: Int
        let lifecycle: UUID
        let uptime, epochSeconds: TimeInterval
        let field: String
        let event: Event
        let state: State?
    }

    private var nextControl = 0
    private var processCount = 0
    private var controlCounts: [Int: Int] = [:]
    private let sink: (String) -> Void

    init(isEnabled: Bool, sink: @escaping (String) -> Void = { print($0) }) {
        self.isEnabled = isEnabled
        self.sink = sink
    }

    func makeControlID() -> Int {
        nextControl += 1
        return nextControl
    }

    func canRecord(control: Int) -> Bool {
        isEnabled && processCount < Self.maximumProcessRecords &&
            controlCounts[control, default: 0] < Self.maximumControlRecords
    }

    func record(control: Int, lifecycle: UUID, identifier: String?, event: Event, state: () -> State) {
        guard canRecord(control: control) else { return }
        let count = controlCounts[control, default: 0]
        // Limits include their one terminal marker. After either marker, no
        // additional record for that budget is encoded or emitted.
        let emitted: Event
        if processCount == Self.maximumProcessRecords - 1 { emitted = .processLimit }
        else if count == Self.maximumControlRecords - 1 { emitted = .controlLimit }
        else { emitted = event }
        processCount += 1
        controlCounts[control] = count + 1
        let record = Record(sequence: processCount, control: control, lifecycle: lifecycle,
                            uptime: ProcessInfo.processInfo.systemUptime,
                            epochSeconds: Date().timeIntervalSince1970,
                            field: Self.fieldName(identifier), event: emitted,
                            state: emitted == .processLimit || emitted == .controlLimit ? nil : state())
        guard let data = try? JSONEncoder().encode(record), let line = String(data: data, encoding: .utf8) else { return }
        sink("KEYFILL_INPUT_TRACE_V1 " + line)
    }

    private static func fieldName(_ identifier: String?) -> String {
        // A private canary in an unexpected identifier must not become output.
        switch identifier {
        case "precisionValue", "projectNameInput", "roomWidth", "roomDepth", "roomHeight",
             "roomSubjectX", "roomSubjectZ", "targetLuxInput": return identifier!
        default: return "other"
        }
    }
}
#endif
