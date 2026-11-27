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

#if DEBUG
    private func traceRecords(_ lines: [String]) throws -> [[String: Any]] {
        let prefix = "KEYFILL_INPUT_TRACE_V1 "
        return try lines.map { line in
            XCTAssertTrue(line.hasPrefix(prefix))
            return try XCTUnwrap(JSONSerialization.jsonObject(
                with: Data(line.dropFirst(prefix.count).utf8)) as? [String: Any])
        }
    }

    func testInputTraceOmitsPrivateDraftsLabelsHintsAndUnknownIdentifiers() throws {
        let secret = "PRIVATE-CANARY-096-e\u{0301}-\u{1F511}"
        let identifier = "PRIVATE_IDENTIFIER\ninjected=true"
        var model = secret, lines: [String] = []
        let field = StudioNativeTextField(frame: .zero)
        field.inputTrace = StudioTextInputTrace(isEnabled: true, sink: { lines.append($0) })
        let view = StudioTextField(secret, text: Binding(get: { model }, set: { next in
            if StudioNumericInput.isWithinDraftLimit(next) { model = next }
        }), isFocused: .constant(false),
            accessibility: .init(label: secret, identifier: identifier, hint: secret))
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                                      replacementString: secret))
        field.text = secret + "-accepted"
        field.sendActions(for: .editingChanged)
        let accepted = model
        let oversized = secret + String(repeating: "x", count: 1_000)
        XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                                      replacementString: oversized))
        field.text = oversized
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(field.text, accepted)
        XCTAssertEqual(model, accepted)
        field.invalidate()

        let records = try traceRecords(lines)
        XCTAssertFalse(records.isEmpty)
        XCTAssertFalse(lines.joined().contains("PRIVATE-CANARY"))
        XCTAssertFalse(lines.joined().contains("PRIVATE_IDENTIFIER"))
        XCTAssertFalse(lines.joined().contains("injected=true"))
        XCTAssertTrue(lines.allSatisfy { !$0.contains("\n") })
        XCTAssertFalse(lines.joined().contains(oversized))
        let allowed = Set(["version", "sequence", "control", "lifecycle", "epochSeconds", "field", "event", "state"])
        for record in records {
            XCTAssertTrue(Set(record.keys).isSubset(of: allowed))
            XCTAssertEqual(record["field"] as? String, "other")
        }
        let readbacks = records.filter { $0["event"] as? String == "bindingReadback" }
        XCTAssertEqual(readbacks.count, 2)
        XCTAssertEqual((readbacks.first?["state"] as? [String: Any])?["bindingMatchesNative"] as? Bool, true)
        XCTAssertEqual((readbacks.last?["state"] as? [String: Any])?["bindingMatchesNative"] as? Bool, false)
        XCTAssertTrue(records.contains { record in
            guard let state = record["state"] as? [String: Any] else { return false }
            return state["replacementUTF16"] as? Int == 257
        }, "Oversized input is observed with a bounded length, never copied into output")
    }

    func testInputTraceCapsIncludeMarkersAndDisabledRecorderEmitsNothing() throws {
        var lines: [String] = [], disabledLines: [String] = []
        var collected = 0, disabledCollected = 0
        let trace = StudioTextInputTrace(isEnabled: true, sink: { lines.append($0) })
        let disabled = StudioTextInputTrace(isEnabled: false, sink: { disabledLines.append($0) })
        let state = StudioTextInputTrace.State(
            configured: true, enabled: true, firstResponder: false, inWindow: false,
            markedText: false, applyingConfiguration: false, replacingText: false,
            synchronizingFocus: false, nativeUTF16: 3, modelUTF16: 3,
            bindingUTF16: nil, replacementUTF16: nil, bindingMatchesNative: nil,
            requestedFocus: nil, rangeLocation: nil, rangeLength: nil)
        let lifecycle = UUID()
        let first = trace.makeControlID(), second = trace.makeControlID(), third = trace.makeControlID()
        for control in [first, second, third] {
            for _ in 0..<600 {
                trace.record(control: control, lifecycle: lifecycle, identifier: "precisionValue",
                             event: .editingChanged) { collected += 1; return state }
                disabled.record(control: control, lifecycle: lifecycle, identifier: "precisionValue",
                                event: .editingChanged) { disabledCollected += 1; return state }
            }
        }
        XCTAssertTrue(disabledLines.isEmpty)
        XCTAssertEqual(disabledCollected, 0)
        XCTAssertEqual(collected, 510, "Neither cap/disabled attempts nor either marker may collect native state")
        let records = try traceRecords(lines)
        XCTAssertEqual(records.count, 512, "The process cap includes its terminal marker")
        XCTAssertEqual(records.filter { $0["control"] as? Int == first }.count, 256)
        XCTAssertEqual(records.filter { $0["control"] as? Int == second }.count, 256)
        XCTAssertEqual(records.filter { $0["control"] as? Int == third }.count, 0)
        XCTAssertEqual(records.compactMap { $0["sequence"] as? Int }, Array(1...512))
        XCTAssertEqual(records.filter { $0["event"] as? String == "controlLimit" }.count, 1)
        XCTAssertEqual(records.filter { $0["event"] as? String == "processLimit" }.count, 1)
        XCTAssertEqual(records.last?["event"] as? String, "processLimit")
        XCTAssertNil(records.last?["state"])
        XCTAssertFalse(trace.canRecord(control: first))
        XCTAssertFalse(trace.canRecord(control: third))
    }

    func testInputTraceLeavesAcceptedRejectedAndExternalResetBehaviorIdentical() throws {
        var outcomes: [[String]] = [], recorded: [String] = []
        for tracing in [false, true] {
            var model = "900", writes = 0, textReads = 0, focusReads = 0, focusWrites = 0
            var focused = false, lines: [String] = []
            let view = control(text: Binding(get: { textReads += 1; return model }, set: { next in
                writes += 1
                if StudioNumericInput.isWithinDraftLimit(next) { model = next }
            }), focus: Binding(get: { focusReads += 1; return focused }, set: { focused = $0; focusWrites += 1 }))
            let field = StudioNativeTextField(frame: .zero)
            field.inputTrace = StudioTextInputTrace(isEnabled: tracing, sink: { lines.append($0) })
            field.configure(view, contentSizeCategory: .large, isEnabled: true)
            defer { field.invalidate() }
            try select(NSRange(location: 3, length: 0), in: field)
            XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: NSRange(location: 3, length: 0),
                                          replacementString: "1"))
            field.text = "9001"
            try select(NSRange(location: 4, length: 0), in: field)
            field.sendActions(for: .editingChanged)
            XCTAssertEqual(model, "9001")
            XCTAssertEqual(try selection(in: field), NSRange(location: 4, length: 0))
            let acceptedSelection = try selection(in: field)
            XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: acceptedSelection,
                                          replacementString: String(repeating: "8", count: 1_000)))
            field.text = String(repeating: "8", count: 1_000)
            field.sendActions(for: .editingChanged)
            XCTAssertEqual(model, "9001")
            XCTAssertEqual(field.text, "9001")
            XCTAssertEqual(try selection(in: field), acceptedSelection)
            model = "42"
            field.text = "90012" // A real external reset wins over this late native event.
            field.sendActions(for: .editingChanged)
            XCTAssertEqual(field.text, "42")
            XCTAssertEqual(model, "42")
            XCTAssertEqual(writes, 2)
            XCTAssertFalse(field.isFirstResponder)
            field.textFieldDidBeginEditing(field)
            XCTAssertTrue(focused)
            field.textFieldDidEndEditing(field)
            XCTAssertFalse(focused)
            XCTAssertEqual(focusWrites, 2)
            outcomes.append([model, field.text ?? "<nil>", String(writes), String(describing: try selection(in: field)),
                             String(textReads), String(focusReads), String(focusWrites)])
            if tracing { recorded = lines } else { XCTAssertTrue(lines.isEmpty) }
        }
        XCTAssertEqual(outcomes[0], outcomes[1])
        let events = try traceRecords(recorded).compactMap { $0["event"] as? String }
        XCTAssertTrue(events.contains("delegateEdit"))
        XCTAssertTrue(events.contains("editingChanged"))
        XCTAssertTrue(events.contains("publishExternalReset"))
        XCTAssertTrue(events.contains("replaceNativeText"))
    }

    func testUnchangedReconfigurationPreservesTraceBudgetForTheNextNativeEdit() async throws {
        var model = "900", lines: [String] = []
        let view = control(text: Binding(get: { model }, set: { model = $0 }))
        let field = StudioNativeTextField(frame: .zero)
        field.inputTrace = StudioTextInputTrace(isEnabled: true, sink: { lines.append($0) })
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        defer { field.invalidate() }
        await drainMainQueue()
        let before = lines.count
        for _ in 0..<100 {
            field.configure(view, contentSizeCategory: .large, isEnabled: true)
            await drainMainQueue() // Exercise each queued unchanged focus request.
        }
        XCTAssertEqual(lines.count, before, "Unchanged renders/focus checks must not consume the input diagnostic budget")
        try select(NSRange(location: 3, length: 0), in: field)
        XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: NSRange(location: 3, length: 0),
                                      replacementString: "1"))
        field.text = "9001"
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(model, "9001")
        let events = try traceRecords(lines).compactMap { $0["event"] as? String }
        XCTAssertTrue(events.contains("delegateEdit"))
        XCTAssertTrue(events.contains("editingChanged"))
        XCTAssertTrue(events.contains("bindingReadback"))
        XCTAssertFalse(events.contains("controlLimit"))
        XCTAssertFalse(events.contains("processLimit"))
    }

    func testInputTraceDistinguishesDeliveryRejectionResetAndBlockedEventsWithoutText() throws {
        let original = "PRIVATE_INITIAL_CANARY"
        let accepted = "PRIVATE_ACCEPTED_CANARY"
        let rejected = "PRIVATE_REJECTED_CANARY"
        let external = "PRIVATE_RESET_CANARY"
        let stale = "PRIVATE_STALE_CANARY"
        var model = original, reject = false, writes = 0
        var lines: [String] = []
        let view = control(text: Binding(get: { model }, set: {
            writes += 1
            if !reject { model = $0 }
        }))
        let field = StudioNativeTextField(frame: .zero)
        field.inputTrace = StudioTextInputTrace(isEnabled: true, sink: { lines.append($0) })
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        defer { field.invalidate() }
        let initialEvents = try traceRecords(lines).compactMap { $0["event"] as? String }
        XCTAssertTrue(initialEvents.contains("configureInitialValue"))
        XCTAssertFalse(initialEvents.contains("delegateEdit") || initialEvents.contains("editingChanged"),
                       "Configuration alone must not report delivery of an input event")

        let acceptedStart = lines.count
        XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: original.utf16.count),
                                      replacementString: accepted))
        field.text = accepted
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(model, accepted)
        XCTAssertEqual(field.text, accepted)
        let acceptedRecords = try traceRecords(Array(lines.dropFirst(acceptedStart)))
        let acceptedEvents = acceptedRecords.compactMap { $0["event"] as? String }
        XCTAssertEqual(acceptedEvents.filter { $0 == "delegateEdit" }.count, 1)
        XCTAssertEqual(acceptedEvents.filter { $0 == "editingChanged" }.count, 1)
        XCTAssertEqual(acceptedEvents.filter { $0 == "bindingWrite" }.count, 1)
        XCTAssertFalse(acceptedEvents.contains("replaceNativeText"))
        let acceptedReadback = try XCTUnwrap(acceptedRecords.last { $0["event"] as? String == "bindingReadback" })
        let acceptedState = try XCTUnwrap(acceptedReadback["state"] as? [String: Any])
        XCTAssertEqual(acceptedState["bindingMatchesNative"] as? Bool, true)

        let rejectedStart = lines.count
        reject = true
        field.text = rejected
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(model, accepted)
        XCTAssertEqual(field.text, accepted)
        let rejectedRecords = try traceRecords(Array(lines.dropFirst(rejectedStart)))
        XCTAssertEqual(rejectedRecords.filter { $0["event"] as? String == "bindingWrite" }.count, 1)
        let rejectedReadback = try XCTUnwrap(rejectedRecords.last { $0["event"] as? String == "bindingReadback" })
        let rejectedState = try XCTUnwrap(rejectedReadback["state"] as? [String: Any])
        XCTAssertEqual(rejectedState["bindingMatchesNative"] as? Bool, false)
        XCTAssertEqual(rejectedRecords.last?["event"] as? String, "replaceNativeText")

        let resetStart = lines.count
        model = external
        field.text = stale
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(field.text, external)
        XCTAssertEqual(model, external)
        XCTAssertEqual(writes, 2, "An external reset must not be counted as a binding write")
        let resetEvents = try traceRecords(Array(lines.dropFirst(resetStart))).compactMap { $0["event"] as? String }
        XCTAssertTrue(resetEvents.contains("publishExternalReset"))
        XCTAssertFalse(resetEvents.contains("bindingWrite"))
        XCTAssertFalse(resetEvents.contains("bindingReadback"))
        XCTAssertEqual(resetEvents.last, "replaceNativeText")

        field.configure(view, contentSizeCategory: .large, isEnabled: false)
        XCTAssertFalse(field.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                                       replacementString: rejected))
        field.sendActions(for: .editingChanged)
        let disabledRecord = try XCTUnwrap(try traceRecords(lines).last)
        XCTAssertEqual(disabledRecord["event"] as? String, "publishIgnored")
        let disabledState = try XCTUnwrap(disabledRecord["state"] as? [String: Any])
        XCTAssertEqual(disabledState["configured"] as? Bool, true)
        XCTAssertEqual(disabledState["enabled"] as? Bool, false)
        field.invalidate()
        field.sendActions(for: .editingChanged)
        let invalidatedRecord = try XCTUnwrap(try traceRecords(lines).last)
        XCTAssertEqual(invalidatedRecord["event"] as? String, "publishIgnored")
        let invalidatedState = try XCTUnwrap(invalidatedRecord["state"] as? [String: Any])
        XCTAssertEqual(invalidatedState["configured"] as? Bool, false)
        XCTAssertEqual(invalidatedState["enabled"] as? Bool, false)
        XCTAssertEqual(writes, 2)
        let output = lines.joined(separator: "\n")
        for privateValue in [original, accepted, rejected, external, stale] {
            XCTAssertFalse(output.contains(privateValue), "Diagnostic output must never contain a draft")
        }
    }
#endif

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

    func testCanonicalEquivalentOversizedPasteStillReachesBoundedValidation() throws {
        let accepted = String(repeating: "é\u{0301}\u{0302}\u{0303}", count: 80)
        let rejected = String(repeating: "e\u{0301}\u{0301}\u{0302}\u{0303}", count: 80)
        XCTAssertEqual(accepted, rejected, "Swift's canonical equality is the regression trigger")
        XCTAssertEqual(accepted.unicodeScalars.count, 320)
        XCTAssertEqual(rejected.unicodeScalars.count, 400)
        var draft = ProjectNameDraft(initial: accepted)
        var attempts = 0
        var submitted: [String] = []
        let view = control(text: Binding(get: { draft.text }, set: {
            attempts += 1
            _ = try? draft.update($0)
        }), onSubmit: {
            if let value = try? draft.submittedName() { submitted.append(value) }
        })
        let field = configured(view)
        defer { field.invalidate() }
        let originalSelection = NSRange(location: accepted.utf16.count, length: 0)
        try select(originalSelection, in: field)
        XCTAssertTrue(field.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: accepted.utf16.count),
                                      replacementString: rejected))
        field.text = rejected
        try select(NSRange(location: rejected.utf16.count, length: 0), in: field)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(attempts, 1)
        XCTAssertTrue(draft.rejectedOversizedInput)
        XCTAssertFalse(draft.canSubmit)
        XCTAssertEqual(Array((field.text ?? "").utf16), Array(accepted.utf16))
        XCTAssertEqual(try selection(in: field), originalSelection)
        _ = field.textFieldShouldReturn(field)
        XCTAssertTrue(submitted.isEmpty)
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(attempts, 1, "Restoring an exact accepted value must not replay validation")
    }

    func testCanonicalEquivalentExternalResetWinsOverLateEventsAndReconfiguration() {
        let composed = "é", decomposed = "e\u{0301}"
        var model = composed, writes = 0
        let view = control(text: Binding(get: { model }, set: { model = $0; writes += 1 }))
        let field = configured(view)
        defer { field.invalidate() }
        field.text = "Stale native edit"
        model = decomposed
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(writes, 0, "An external representation change wins before the next render")
        XCTAssertEqual(Array((field.text ?? "").utf16), Array(decomposed.utf16))
        model = composed
        field.configure(view, contentSizeCategory: .large, isEnabled: true)
        XCTAssertEqual(Array((field.text ?? "").utf16), Array(composed.utf16))
        field.configure(control(text: .constant(decomposed), identifier: "anotherField"),
                        contentSizeCategory: .large, isEnabled: true)
        XCTAssertEqual(Array((field.text ?? "").utf16), Array(decomposed.utf16))
        XCTAssertEqual(writes, 0)
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

    func testIdentityChangeDuringSetterCannotSubmitOrRestoreThePreviousControl() throws {
        var first = "1", oldSubmits = 0, newSubmits = 0
        let field = StudioNativeTextField(frame: .zero)
        #if DEBUG
        var lines: [String] = []
        field.inputTrace = StudioTextInputTrace(isEnabled: true, sink: { lines.append($0) })
        #endif
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
        #if DEBUG
        let events = try traceRecords(lines).compactMap { $0["event"] as? String }
        XCTAssertTrue(events.contains("identityChange"))
        XCTAssertTrue(events.contains("publishLifecycleChanged"))
        XCTAssertTrue(events.contains("submitLifecycleChanged"))
        XCTAssertFalse(events.contains("bindingReadback"))
        #endif
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
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        let host = UIHostingController(rootView: HostedNameDraft(observation: observation))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            nativeFields(in: host.view).forEach { $0.invalidate() }
            observation.model = nil
            observation.clear = nil
            observation.requestFocus = nil
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKeyAndVisible()
        }
        await drainMainQueue()
        host.view.layoutIfNeeded()
        await drainMainQueue()
        XCTAssertEqual(nativeFields(in: host.view).count, 1)
        let field = try XCTUnwrap(nativeFields(in: host.view).first)
        let model = try XCTUnwrap(observation.model)
        let clear = try XCTUnwrap(observation.clear)
        let requestFocus = try XCTUnwrap(observation.requestFocus)
        XCTAssertTrue(field.window === window)
        XCTAssertEqual(field.text, "Portrait setup")
        XCTAssertEqual(model.wrappedValue, "Portrait setup")
        // This test delivers editingChanged events itself. Keep real UIKit
        // responder ownership while isolating it from the simulator's remote
        // system-keyboard service; required UI tests still type on that keyboard.
        // Install the local input view before the first focus request, never
        // repair focus after a failed edit or replace the native responder.
        let inputView = UIInputView(frame: CGRect(x: 0, y: 0, width: 390, height: 44), inputViewStyle: .keyboard)
        field.inputView = inputView
        field.inputAssistantItem.leadingBarButtonGroups = []
        field.inputAssistantItem.trailingBarButtonGroups = []
        requestFocus()
        await drainMainQueue()
        host.view.layoutIfNeeded()
        await drainMainQueue()
        XCTAssertTrue(field.inputView === inputView)
        XCTAssertTrue(window.isKeyWindow)
        XCTAssertTrue(field.isFirstResponder)

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
            print("Hosted name final focus: renderAfterFirst=\(renderAfterFirstCharacter), " +
                  "keyWindow=\(window.isKeyWindow), firstResponder=\(field.isFirstResponder), " +
                  "native=\(field.text ?? "<nil>"), model=\(model.wrappedValue)")
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
        var requestFocus: (() -> Void)?
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
                    observation.requestFocus = { focused = true }
                }
            }
        }
    }

}
