import SwiftUI
import UIKit
import XCTest
import LightingCore
@testable import KeyAndFill

@MainActor
final class StudioTextFieldTests: XCTestCase {
    private func control(text: Binding<String> = .constant("900"),
                         focus: Binding<Bool> = .constant(false),
                         identifier: String = "precisionValue", monospacedDigits: Bool = true,
                         onSubmit: @escaping () -> Void = {}) -> StudioTextField {
        StudioTextField("Value", text: text, isFocused: focus,
                        accessibility: .init(label: "Intensity in cd", identifier: identifier,
                                             hint: "Enter an exact value"),
                        keyboardType: .numbersAndPunctuation, returnKeyType: .done,
                        autocapitalizationType: .none, autocorrectionType: .no,
                        textAlignment: .right, monospacedDigits: monospacedDigits,
                        onSubmit: onSubmit)
    }

    private func configured(_ control: StudioTextField,
                            category: UIContentSizeCategory = .large) -> StudioNativeTextField {
        let field = StudioNativeTextField(frame: .zero)
        field.configure(control, contentSizeCategory: category, isEnabled: true)
        return field
    }

    private func select(_ range: NSRange, in field: UITextField) throws {
        let start = try XCTUnwrap(field.position(from: field.beginningOfDocument, offset: range.location))
        let end = try XCTUnwrap(field.position(from: start, offset: range.length))
        field.selectedTextRange = field.textRange(from: start, to: end)
    }

    private func selection(in field: UITextField) throws -> NSRange {
        let selected = try XCTUnwrap(field.selectedTextRange)
        let start = field.offset(from: field.beginningOfDocument, to: selected.start)
        let end = field.offset(from: field.beginningOfDocument, to: selected.end)
        return NSRange(location: start, length: end - start)
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    private func mount(_ field: StudioNativeTextField) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        let controller = UIViewController()
        window.rootViewController = controller
        field.frame = CGRect(x: 20, y: 100, width: 300, height: field.intrinsicContentSize.height)
        controller.view.addSubview(field)
        window.makeKeyAndVisible()
        return window
    }

    private func nativeFields(in view: UIView) -> [StudioNativeTextField] {
        let own = (view as? StudioNativeTextField).map { [$0] } ?? []
        return own + view.subviews.flatMap { nativeFields(in: $0) }
    }

    func testNativeSizingAndConfigurationOwnTheAccessibleInput() {
        let field = configured(control())
        defer { field.invalidate() }
        XCTAssertEqual(field.intrinsicContentSize.height, 44, accuracy: 0.01)
        XCTAssertEqual(field.sizeThatFits(CGSize(width: 280, height: 1)).height, 44, accuracy: 0.01)
        XCTAssertTrue(field.isAccessibilityElement)
        XCTAssertEqual(field.accessibilityLabel, "Intensity in cd")
        XCTAssertEqual(field.accessibilityIdentifier, "precisionValue")
        XCTAssertEqual(field.accessibilityHint, "Enter an exact value")
        XCTAssertEqual(field.text, "900")
        XCTAssertEqual(field.placeholder, "Value")
        XCTAssertEqual(field.keyboardType, .numbersAndPunctuation)
        XCTAssertEqual(field.returnKeyType, .done)
        XCTAssertEqual(field.autocapitalizationType, .none)
        XCTAssertEqual(field.autocorrectionType, .no)
        XCTAssertEqual(field.textAlignment, .right)
        XCTAssertEqual(field.borderStyle, .none)
        XCTAssertTrue(field.adjustsFontForContentSizeCategory)
    }

    func testHostedFormGivesTheNativeControlAtLeast44PointsInScreenCoordinates() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive },
            "The app-hosted geometry test requires a foreground window scene")
        for category in [ContentSizeCategory.large, .accessibilityExtraExtraExtraLarge] {
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
            let host = UIHostingController(rootView: AnyView(
                Form {
                    HStack {
                        control()
                        Text("cd")
                    }
                }
                .environment(\.sizeCategory, category)
            ))
            window.rootViewController = host
            window.makeKeyAndVisible()
            defer { window.isHidden = true; window.rootViewController = nil }
            await drainMainQueue()
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            await drainMainQueue()
            let fields = nativeFields(in: host.view)
            XCTAssertEqual(fields.count, 1, "The editable UIKit field must remain the single native input")
            let field = try XCTUnwrap(fields.first)
            XCTAssertTrue(field.window === window)
            XCTAssertTrue(window.windowScene === scene)
            XCTAssertFalse(window.isHidden)
            // This checks native layout in screen coordinates. The required UI
            // workflow independently checks the system accessibility snapshot;
            // the direct accessibilityFrame getter was zero in this unit host.
            let screenBounds = UIAccessibility.convertToScreenCoordinates(field.bounds, in: field)
            print("StudioTextField \(category): bounds=\(field.bounds), screenBounds=\(screenBounds)")
            XCTAssertGreaterThanOrEqual(field.bounds.height, 44)
            XCTAssertGreaterThanOrEqual(screenBounds.height, 44)
            XCTAssertGreaterThan(screenBounds.width, 150)
            XCTAssertGreaterThan(field.bounds.width, 150, "The input must expand in the Form/HStack")
            XCTAssertGreaterThanOrEqual(field.bounds.height, try XCTUnwrap(field.font).lineHeight)
            if category == .large {
                XCTAssertEqual(field.bounds.height, 44, accuracy: 0.5)
            } else {
                XCTAssertGreaterThan(try XCTUnwrap(field.font).pointSize, 17)
            }
            XCTAssertTrue(field.isEnabled)
            field.invalidate()
        }
    }

    func testDisabledEnvironmentReachesNativeControl() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        let host = UIHostingController(rootView: control().disabled(true))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        await drainMainQueue()
        host.view.layoutIfNeeded()
        let field = try XCTUnwrap(nativeFields(in: host.view).first)
        XCTAssertFalse(field.isEnabled)
        XCTAssertGreaterThanOrEqual(field.bounds.height, 44)
        field.invalidate()
    }

    func testAcceptedIncompleteDraftPreservesNativeSelectionWithoutParsing() throws {
        var model = "900", writes = 0
        let binding = Binding(get: { model }, set: { model = $0; writes += 1 })
        let view = control(text: binding)
        let field = configured(view)
        defer { field.invalidate() }
        field.text = "12,"
        try select(NSRange(location: 2, length: 0), in: field)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(model, "12,", "The caller, not this bridge, validates numeric syntax")
        XCTAssertEqual(field.text, "12,")
        XCTAssertEqual(writes, 1)
        XCTAssertEqual(try selection(in: field), NSRange(location: 2, length: 0))
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(writes, 1, "A render or duplicate native event must not write the binding")
        XCTAssertEqual(try selection(in: field), NSRange(location: 2, length: 0))
    }

    func testRejectedOversizedBindingRestoresActualNativeTextAndPriorSelectionOnce() throws {
        var model = "900", attempts = 0
        let binding = Binding(get: { model }, set: {
            attempts += 1
            guard StudioNumericInput.isWithinDraftLimit($0) else { return }
            model = $0
        })
        let view = control(text: binding)
        let field = configured(view)
        defer { field.invalidate() }
        let originalSelection = NSRange(location: 1, length: 1)
        try select(originalSelection, in: field)
        let paste = String(repeating: "9", count: 1_000)
        XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: originalSelection,
                                      replacementString: paste))
        field.text = paste
        try select(NSRange(location: paste.utf16.count, length: 0), in: field)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(attempts, 1)
        XCTAssertEqual(model, "900")
        XCTAssertEqual(field.text, "900", "A rejected setter cannot leave the oversized text on screen")
        XCTAssertEqual(try selection(in: field), originalSelection)
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(attempts, 1, "Restoration must not replay the binding setter")
    }

    func testUpdatesDoNotWriteBindingsOrEraseAnUndeliveredNativeEdit() throws {
        var model = "900", writes = 0, focused = false, focusWrites = 0
        let view = control(text: Binding(get: { model }, set: { model = $0; writes += 1 }),
                           focus: Binding(get: { focused }, set: { focused = $0; focusWrites += 1 }))
        let field = configured(view)
        defer { field.invalidate() }
        field.text = "9001" // UIKit may update its text before dispatching editingChanged.
        try select(NSRange(location: 4, length: 0), in: field)
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        XCTAssertEqual(field.text, "9001")
        XCTAssertEqual(try selection(in: field).location, 4)
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(focusWrites, 0)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(model, "9001")
        XCTAssertEqual(writes, 1)
        model = "42"
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        XCTAssertEqual(field.text, "42")
        XCTAssertEqual(writes, 1)
        XCTAssertEqual(focusWrites, 0)
    }

    func testExternalResetWinsOverLateNativeEventBeforeAnotherRender() {
        var model = "900", writes = 0
        let field = configured(control(text: Binding(get: { model }, set: { model = $0; writes += 1 })))
        defer { field.invalidate() }
        field.text = "9001"
        model = "" // The caller's Clear action has already replaced the draft.
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(model, "")
        XCTAssertEqual(field.text, "")
        XCTAssertEqual(writes, 0)
    }

    func testAcceptedMarkedTextUpdatesRawDraftAndSurvivesUnchangedConfiguration() async throws {
        var model = "", writes = 0, submits = 0
        let view = control(text: Binding(get: { model }, set: { model = $0; writes += 1 }),
                           focus: .constant(true), monospacedDigits: false,
                           onSubmit: { submits += 1 })
        let field = configured(view)
        let window = mount(field)
        defer { field.invalidate(); window.isHidden = true }
        await drainMainQueue()
        XCTAssertTrue(field.isFirstResponder)
        field.setMarkedText("ni", selectedRange: NSRange(location: 2, length: 0))
        XCTAssertNotNil(field.markedTextRange)
        field.sendActions(for: .editingChanged)
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        XCTAssertEqual(field.text, "ni")
        XCTAssertNotNil(field.markedTextRange)
        XCTAssertEqual(writes, 1)
        XCTAssertEqual(model, "ni", "An explicit Save action must see the visible raw draft")
        XCTAssertFalse(field.textFieldShouldReturn(field))
        XCTAssertEqual(submits, 0, "Return during composition must not submit the form")
        field.unmarkText()
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(model, "ni")
        XCTAssertEqual(writes, 1)
    }

    func testExplicitClearImmediatelyReplacesMarkedTextWithoutWritingBack() async {
        var model = "", writes = 0
        let view = control(text: Binding(get: { model }, set: { model = $0; writes += 1 }),
                           focus: .constant(true), monospacedDigits: false)
        let field = configured(view)
        let window = mount(field)
        defer { field.invalidate(); window.isHidden = true }
        await drainMainQueue()
        field.setMarkedText("ni", selectedRange: NSRange(location: 2, length: 0))
        field.sendActions(for: .editingChanged)
        XCTAssertNotNil(field.markedTextRange)
        XCTAssertEqual(model, "ni")
        XCTAssertEqual(writes, 1)
        model = ""
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        XCTAssertEqual(field.text, "")
        XCTAssertNil(field.markedTextRange)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(field.text, "")
        XCTAssertEqual(model, "")
        XCTAssertEqual(writes, 1)
    }

    func testRequestedAndNativeFocusChangesDoNotEchoConfiguration() async {
        var focused = true, writes = 0
        let focus = Binding(get: { focused }, set: { focused = $0; writes += 1 })
        let view = control(focus: focus)
        let field = configured(view)
        let window = mount(field)
        defer { field.invalidate(); window.isHidden = true }
        XCTAssertEqual(writes, 0)
        await drainMainQueue()
        XCTAssertTrue(field.isFirstResponder)
        XCTAssertEqual(writes, 0)
        focused = false
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        XCTAssertEqual(writes, 0)
        await drainMainQueue()
        XCTAssertFalse(field.isFirstResponder)
        XCTAssertEqual(writes, 0)
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertTrue(focused)
        XCTAssertEqual(writes, 1)
        field.textFieldDidBeginEditing(field)
        XCTAssertEqual(writes, 1)
        XCTAssertTrue(field.resignFirstResponder())
        XCTAssertFalse(focused)
        XCTAssertEqual(writes, 2)
    }

    func testSubmitPublishesPendingTextOnceAndLeavesFocusDecisionToCaller() {
        var model = "900", writes = 0, submits: [String] = [], focused = true
        let field = configured(control(
            text: Binding(get: { model }, set: { model = $0; writes += 1 }),
            focus: Binding(get: { focused }, set: { focused = $0 }),
            onSubmit: { submits.append(model) }))
        defer { field.invalidate() }
        field.text = "1200"
        XCTAssertFalse(field.textFieldShouldReturn(field))
        XCTAssertEqual(model, "1200")
        XCTAssertEqual(writes, 1)
        XCTAssertEqual(submits, ["1200"])
        XCTAssertTrue(focused)
        field.configure(control(text: .constant(model)), contentSizeCategory: .large, isEnabled: false)
        field.text = "2000"
        field.sendActions(for: .editingChanged)
        XCTAssertFalse(field.textFieldShouldReturn(field))
        XCTAssertEqual(writes, 1)
        XCTAssertEqual(submits, ["1200"])
    }

    func testReconfigurationUsesCurrentBindingAndSubmitClosure() {
        var first = "1", second = "2", firstSubmits = 0, secondSubmits = 0
        let field = configured(control(text: Binding(get: { first }, set: { first = $0 }),
                                       onSubmit: { firstSubmits += 1 }))
        defer { field.invalidate() }
        field.configure(control(text: Binding(get: { second }, set: { second = $0 }),
                                onSubmit: { secondSubmits += 1 }),
                        contentSizeCategory: .large, isEnabled: true)
        field.text = "3"
        field.sendActions(for: .editingChanged)
        _ = field.textFieldShouldReturn(field)
        XCTAssertEqual(first, "1")
        XCTAssertEqual(second, "3")
        XCTAssertEqual(firstSubmits, 0)
        XCTAssertEqual(secondSubmits, 1)
    }

    func testIdentityChangeDuringSetterCannotSubmitOrRestoreThePreviousControl() {
        var first = "1", oldSubmits = 0, newSubmits = 0
        let field = StudioNativeTextField(frame: .zero)
        let replacement = control(text: .constant("New control"), identifier: "otherField",
                                  onSubmit: { newSubmits += 1 })
        let binding = Binding(get: { first }, set: {
            first = $0
            field.configure(replacement, contentSizeCategory: .large, isEnabled: true)
        })
        field.configure(control(text: binding, onSubmit: { oldSubmits += 1 }),
                        contentSizeCategory: .large, isEnabled: true)
        defer { field.invalidate() }
        field.text = "12"
        _ = field.textFieldShouldReturn(field)
        XCTAssertEqual(first, "12")
        XCTAssertEqual(field.text, "New control")
        XCTAssertEqual(field.accessibilityIdentifier, "otherField")
        XCTAssertEqual(oldSubmits, 0)
        XCTAssertEqual(newSubmits, 0)
    }

    func testInvalidationCancelsPendingFocusAndIgnoresStaleEvents() async {
        var model = "900", writes = 0, focusWrites = 0, submits = 0
        let field = configured(control(
            text: Binding(get: { model }, set: { model = $0; writes += 1 }),
            focus: Binding(get: { true }, set: { _ in focusWrites += 1 }),
            onSubmit: { submits += 1 }))
        let window = mount(field)
        defer { window.isHidden = true }
        field.invalidate()
        field.text = "Stale"
        field.sendActions(for: .editingChanged)
        field.textFieldDidBeginEditing(field)
        field.textFieldDidEndEditing(field)
        XCTAssertFalse(field.textFieldShouldReturn(field))
        await drainMainQueue()
        XCTAssertFalse(field.isEnabled)
        XCTAssertFalse(field.isFirstResponder)
        XCTAssertEqual(model, "900")
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(focusWrites, 0)
        XCTAssertEqual(submits, 0)
    }

    /// Exercise the installed @State location used by the naming sheet, not a
    /// synchronous local-variable Binding. This delivers native editingChanged
    /// events; it deliberately makes no claim about XCTest keyboard injection.
    func testHostedNameDraftPreservesRapidEditsAcrossStateReconfiguration() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive })
        let observation = HostedNameObservation()
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        let host = UIHostingController(rootView: HostedNameDraft(observation: observation))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            nativeFields(in: host.view).forEach { $0.invalidate() }
            observation.model = nil
            observation.clear = nil
            window.isHidden = true
            window.rootViewController = nil
        }
        await drainMainQueue()
        host.view.layoutIfNeeded()
        await drainMainQueue()
        XCTAssertEqual(nativeFields(in: host.view).count, 1)
        let field = try XCTUnwrap(nativeFields(in: host.view).first)
        let model = try XCTUnwrap(observation.model)
        let clear = try XCTUnwrap(observation.clear)
        XCTAssertTrue(field.window === window)
        XCTAssertEqual(field.text, "Portrait setup")
        XCTAssertEqual(model.wrappedValue, "Portrait setup")

        for renderAfterFirstCharacter in [false, true] {
            clear() // Same name/error/focus state changes as the real Clear action.
            await drainMainQueue()
            host.view.layoutIfNeeded()
            await drainMainQueue()
            XCTAssertEqual(model.wrappedValue, "")
            XCTAssertEqual(field.text, "")
            XCTAssertTrue(field.isFirstResponder)
            XCTAssertTrue(nativeFields(in: host.view).first === field)
            observation.writes.removeAll()
            var expected = ""
            for character in "Keep" {
                let previousBuilds = observation.bindingBuilds
                let selectionBefore = try selection(in: field)
                XCTAssertEqual(selectionBefore, NSRange(location: expected.utf16.count, length: 0))
                let fragment = String(character)
                XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: selectionBefore,
                                              replacementString: fragment))
                // Apply exactly one accepted native edit, then deliver the real
                // UIControl event to StudioNativeTextField's registered target.
                let delivered = (field.text ?? "") + fragment
                field.text = delivered
                try select(NSRange(location: delivered.utf16.count, length: 0), in: field)
                field.sendActions(for: .editingChanged)
                expected += fragment
                print("Hosted name edit: renderAfterFirst=\(renderAfterFirstCharacter), " +
                      "delivered=\(delivered), expected=\(expected), native=\(field.text ?? "<nil>"), " +
                      "model=\(model.wrappedValue), writes=\(observation.writes), " +
                      "bindingBuilds=\(observation.bindingBuilds), focused=\(field.isFirstResponder)")
                XCTAssertEqual(field.text, expected)
                XCTAssertEqual(model.wrappedValue, expected)
                XCTAssertEqual(try selection(in: field),
                               NSRange(location: expected.utf16.count, length: 0))
                if renderAfterFirstCharacter && expected == "K" {
                    await drainMainQueue()
                    host.view.layoutIfNeeded()
                    await drainMainQueue()
                    XCTAssertGreaterThan(observation.bindingBuilds, previousBuilds,
                                         "The first edit must actually rebuild the hosted State binding")
                    XCTAssertTrue(nativeFields(in: host.view).first === field,
                                  "Showing Clear must preserve the native editor identity")
                    XCTAssertEqual(field.text, "K")
                    XCTAssertEqual(model.wrappedValue, "K")
                }
            }
            await drainMainQueue()
            host.view.layoutIfNeeded()
            await drainMainQueue()
            XCTAssertEqual(nativeFields(in: host.view).count, 1)
            XCTAssertTrue(nativeFields(in: host.view).first === field)
            XCTAssertTrue(field.window === window)
            XCTAssertTrue(field.isFirstResponder)
            XCTAssertEqual(field.text, "Keep")
            XCTAssertEqual(model.wrappedValue, "Keep")
            XCTAssertEqual(observation.writes, ["K", "Ke", "Kee", "Keep"])
            XCTAssertEqual(try selection(in: field), NSRange(location: 4, length: 0))
        }
    }

    private final class HostedNameObservation {
        var model: Binding<String>?
        var clear: (() -> Void)?
        var writes: [String] = []
        var bindingBuilds = 0
    }

    /// Mirrors the actual ProjectNameEditor draft binding and the conditional
    /// Clear action that changes the HStack after the first typed character.
    private struct HostedNameDraft: View {
        let observation: HostedNameObservation
        @State private var name = StudioDisplayName.display("Portrait setup")
        @State private var errorMessage: String?
        @State private var focused = false
        @State private var isSubmitting = false

        private var boundedDraft: Binding<String> {
            observation.bindingBuilds += 1
            return Binding(get: { name }, set: { next in
                guard next.unicodeScalars.prefix(StudioDisplayName.maximumScalars + 1).count <= StudioDisplayName.maximumScalars else {
                    errorMessage = StudioDisplayName.NameError.tooLong.localizedDescription
                    return
                }
                guard next != name else { return }
                name = next
                errorMessage = nil
                observation.writes.append(next)
            })
        }

        private func clearName() {
            name = ""
            errorMessage = nil
            focused = true
        }

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        HStack {
                            StudioTextField("Name", text: boundedDraft, isFocused: $focused,
                                accessibility: .init(label: "Name", identifier: "projectNameInput"),
                                returnKeyType: .done)
                                .disabled(isSubmitting)
                            if !name.isEmpty {
                                Button(action: clearName) {
                                    Image(systemName: "xmark.circle.fill")
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.borderless)
                                .disabled(isSubmitting)
                                .accessibilityIdentifier("clearProjectName")
                            }
                        }
                    }
                    Section {
                        Button("Save project name") {}
                            .disabled(isSubmitting || (try? StudioDisplayName.newInput(name)) == nil)
                    }
                }
                .scrollDismissesKeyboard(.never)
                .onAppear {
                    observation.model = $name
                    observation.clear = clearName
                    focused = true
                }
            }
        }
    }

}
