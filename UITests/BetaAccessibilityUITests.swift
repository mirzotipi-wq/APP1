import XCTest
import UIKit

/// Supplemental coverage for the beta surfaces. The existing Default/AXXXL
/// workflow and its 28 required original captures remain independent.
final class BetaAccessibilityUITests: XCTestCase {
    private let category = UIContentSizeCategory.accessibilityExtraExtraExtraLarge
    private var observations: [String] = []

    override func setUpWithError() throws { continueAfterFailure = false }

    override func tearDownWithError() throws {
        let details = observations.joined(separator: "\n")
        print("Supplemental-AXXXL-Beta-observed-controls:\n" + details)
        let attachment = XCTAttachment(string: details)
        attachment.name = "Supplemental-AXXXL-Beta-observed-controls"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func makeApp(corrupt: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["KEYFILL_UI_TEXT_LAYOUT_PROBES"] = "1"
        app.launchEnvironment["KEYFILL_UI_TEXT_INPUT_TRACE"] = "1"
        if corrupt { app.launchEnvironment["KEYFILL_UI_TEST_CORRUPT"] = "1" }
        return app
    }

    func testBetaSurfacesAtLargestAccessibilityTextSize() throws {
        let healthy = makeApp(), recovery = makeApp(corrupt: true)
        XCTAssertNotEqual(healthy.launchEnvironment["KEYFILL_UI_TEST_ID"],
                          recovery.launchEnvironment["KEYFILL_UI_TEST_ID"])
        defer { healthy.terminate(); recovery.terminate() }

        healthy.launch()
        waitForEnabledStudioControl(healthy.buttons["openProjectLibrary"])
        // The opted-in layout value can expose an empty-label AX wrapper.
        // Select the actual labeled title and reject ambiguous real matches.
        let titles = healthy.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "studioWelcomeTitle", "Start your first portrait"))
        XCTAssertEqual(titles.count, 1, "Expected one actual labeled welcome title")
        let title = titles.firstMatch
        revealStudioContent(title, in: healthy, towardBottom: false, fullyVisible: true)
        try assertWelcomeTitleFitsLargestFont(title, in: healthy)
        try control(healthy.buttons["dismissStudioWelcome"], label: "Dismiss welcome", in: healthy,
                    towardBottom: false)
        for (identifier, label) in [("welcomeSaveCurrent", "Save current setup"),
                                    ("welcomeOpenGuide", "Studio guide"),
                                    ("welcomeOpenProjects", "Projects")] {
            try control(healthy.buttons[identifier], label: label, in: healthy)
        }
        capture("Welcome-actions", in: healthy)
        let limitations = healthy.staticTexts["studioWelcomeLimitations"]
        revealStudioContent(limitations, in: healthy)
        XCTAssertTrue(limitations.label.contains("Previews and suggestions are not calibrated measurements."))
        let dismiss = healthy.buttons["dismissStudioWelcome"]
        try control(dismiss, label: "Dismiss welcome", in: healthy, towardBottom: false)
        dismiss.tap()
        // Dismissal must remove every title identity, including the wrapper.
        expectGone(healthy.staticTexts.matching(NSPredicate(
            format: "identifier == %@", "studioWelcomeTitle")).firstMatch)

        // Settings is only the entry route; this smoke exercises the new sheet.
        let tools = healthy.buttons["studioTools"]
        try control(tools, label: "Studio tools", in: healthy, towardBottom: false)
        tools.tap()
        let settings = healthy.buttons["Settings"]
        waitForEnabledStudioControl(settings)
        settings.tap()
        XCTAssertTrue(healthy.navigationBars["Settings"].waitForExistence(timeout: 10))
        let openFeedback = healthy.buttons["openBetaFeedback"]
        try control(openFeedback, label: "Beta feedback", in: healthy)
        openFeedback.tap()
        let closeFeedback = healthy.buttons["closeBetaFeedback"]
        try control(closeFeedback, label: "Close", in: healthy, towardBottom: false)
        for (identifier, label) in [("betaFeedbackProblem", "Problem or observation, optional"),
                                    ("betaFeedbackSteps", "Steps to reproduce, optional"),
                                    ("betaFeedbackExpectedResult", "Expected result, optional")] {
            let field = healthy.descendants(matching: .any)[identifier].firstMatch
            try control(field, label: label, in: healthy)
            XCTAssertTrue([XCUIElement.ElementType.textField, .textView].contains(field.elementType))
        }
        let note = "The largest text remains readable."
        let editor = healthy.descendants(matching: .any)["betaFeedbackExpectedResult"].firstMatch
        editor.tap()
        dismissKeyboardTypingIntroduction(in: healthy)
        revealStudioContent(editor, in: healthy, fullyVisible: true)
        editor.tap()
        editor.typeText(note)
        expectValue(note, of: editor)
        XCTAssertTrue(healthy.keyboards.firstMatch.waitForExistence(timeout: 10))
        capture("Feedback-editor-keyboard", in: healthy)
        let review = healthy.buttons["reviewBetaFeedback"]
        try control(review, label: "Review report", in: healthy)
        review.tap()
        let previewNavigation = healthy.navigationBars["Review report"]
        XCTAssertTrue(previewNavigation.waitForExistence(timeout: 10))
        expectGone(healthy.keyboards.firstMatch)
        let preview = healthy.staticTexts["betaFeedbackReportText"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        XCTAssertTrue(preview.label.contains(note))
        // The complete report is taller than the viewport; never demand that
        // this scrollable text's whole AX frame fit on one screen.
        capture("Feedback-review-keyboard-dismissed", in: healthy)
        try control(healthy.buttons["shareBetaFeedbackReport"], label: "Share report", in: healthy)
        capture("Feedback-reviewed-share-control", in: healthy)
        // Do not invoke sharing or select an external destination.
        XCTAssertEqual(previewNavigation.buttons.count, 1)
        let back = previewNavigation.buttons.firstMatch
        try control(back, in: healthy, scrolling: false)
        back.tap()
        expectGone(previewNavigation)
        revealStudioContent(editor, in: healthy, towardBottom: false, fullyVisible: true)
        expectValue(note, of: editor)
        try control(closeFeedback, label: "Close", in: healthy, towardBottom: false)
        closeFeedback.tap()
        let discard = healthy.buttons["Discard draft"]
        try control(discard, label: "Discard draft", in: healthy, scrolling: false)
        discard.tap()
        expectGone(closeFeedback)
        XCTAssertTrue(healthy.navigationBars["Settings"].exists)
        healthy.terminate()

        recovery.launch()
        let openRecovery = recovery.buttons["openLibraryRecovery"]
        try control(openRecovery, label: "Review recovery options", in: recovery)
        openRecovery.tap()
        let done = recovery.buttons["closeLibraryRecovery"]
        try control(done, label: "Done", in: recovery, scrolling: false)
        let summary = recovery.descendants(matching: .any)["libraryRecoveryInspectionSummary"].firstMatch
        revealStudioContent(summary, in: recovery, fullyVisible: true)
        XCTAssertTrue(summary.label.contains("Saved files to keep: 1"))
        XCTAssertTrue(summary.label.contains("Total size:"))
        capture("Recovery-inspection", in: recovery)
        let reviewRecovery = recovery.buttons["reviewLibraryRecovery"]
        try control(reviewRecovery, label: "Review starting again", in: recovery)
        reviewRecovery.tap()
        let confirmation = recovery.alerts["Keep files and start again?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        let cancel = confirmation.buttons["Cancel"]
        try control(cancel, label: "Cancel", in: recovery, scrolling: false)
        try control(confirmation.buttons["Keep files and start again"], label: "Keep files and start again",
                    in: recovery, scrolling: false)
        capture("Recovery-confirmation", in: recovery)
        cancel.tap()
        expectGone(confirmation)
        XCTAssertFalse(recovery.descendants(matching: .any)["libraryRecoverySuccess"].firstMatch.exists)
        try control(reviewRecovery, label: "Review starting again", in: recovery)
        reviewRecovery.tap()
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        let confirm = confirmation.buttons["Keep files and start again"]
        try control(confirm, label: "Keep files and start again", in: recovery, scrolling: false)
        confirm.tap()
        expectGone(confirmation)
        let success = recovery.descendants(matching: .any)["libraryRecoverySuccess"].firstMatch
        XCTAssertTrue(success.waitForExistence(timeout: 15))
        revealStudioContent(success, in: recovery, towardBottom: false, fullyVisible: true)
        XCTAssertEqual(success.label, "New library is ready")
        try control(done, label: "Done", in: recovery, scrolling: false)
        capture("Recovery-success", in: recovery)
        done.tap()
        expectGone(done)
        waitForCommittedProject(in: recovery)
        waitForEnabledStudioControl(recovery.buttons["openProjectLibrary"])
        XCTAssertFalse(recovery.buttons["openLibraryRecovery"].exists)
    }

    private func control(_ element: XCUIElement, label: String? = nil, in app: XCUIApplication,
                         scrolling: Bool = true, towardBottom: Bool = true) throws {
        if scrolling {
            // Measure only after fully revealing a single actionable control,
            // never a clipped row or an entire multi-screen Form/report.
            revealStudioContent(element, in: app, towardBottom: towardBottom, fullyVisible: true)
        }
        waitForEnabledStudioControl(element)
        let state = try element.snapshot()
        observations.append("\(state.identifier) | \(state.label) | frame=\(state.frame)")
        if let label { XCTAssertEqual(state.label, label) }
        XCTAssertFalse(state.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(state.isEnabled)
        XCTAssertTrue(element.isHittable)
        assertStudioMinimumHitTarget(state.frame, label: state.label)
        let viewport = scrolling ? try StudioViewportObservation(in: app, matching: state).viewport : app.frame
        XCTAssertTrue(viewport.contains(state.frame), "\(state.label): \(state.frame) outside \(viewport)")
    }

    private func assertWelcomeTitleFitsLargestFont(_ element: XCUIElement, in app: XCUIApplication) throws {
        let initial = try element.snapshot()
        XCTAssertEqual(initial.elementType, .staticText)
        XCTAssertEqual(initial.label, "Start your first portrait")
        observations.append("Welcome title before recorded layout: AX frame=\(initial.frame), " +
                            "value=\(String(describing: initial.value))")
        // Preserve the reached title even if its geometry assertion fails. The
        // original 587 < 591 failure occurred before any welcome image existed.
        capture("Welcome-heading", in: app)

        let probe = "studioWelcomeTitle"
        var readyState: (any XCUIElementSnapshot)?
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let state = try? element.snapshot(), let value = state.value as? String,
                  RecordedTitleLayout.frame(from: value, probe: probe) != nil else { return false }
            readyState = state
            return true
        }, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed,
                       "The opted-in app must publish the actual welcome Text layout")
        let state = try XCTUnwrap(readyState, "Expected the current layout-readiness snapshot")
        XCTAssertEqual(state.elementType, .staticText)
        XCTAssertEqual(state.label, "Start your first portrait")
        let value = try XCTUnwrap(state.value as? String)
        let frame = try XCTUnwrap(RecordedTitleLayout.frame(from: value, probe: probe))
        let viewport = try StudioViewportObservation(in: app, matching: state).viewport
        XCTAssertTrue(viewport.contains(state.frame), "The semantic title must be fully visible")
        XCTAssertTrue(viewport.contains(frame), "The actual Text layout must be fully visible")
        let preferred = UIFont.preferredFont(forTextStyle: .title3,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: category))
        let font = UIFont.systemFont(ofSize: preferred.pointSize, weight: .semibold)
        let scale = UIScreen.main.scale
        let measurementWidth = max(1, (frame.width * scale).rounded() / scale)
        let required = (state.label as NSString).boundingRect(
            with: CGSize(width: measurementWidth,
                         height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        let axRequired = (state.label as NSString).boundingRect(
            with: CGSize(width: max(1, (state.frame.width * scale).rounded() / scale),
                         height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        // The AX semantic rectangle is not an intrinsic SwiftUI layout probe.
        // Keep both observations; apply the unchanged physical-pixel line-box
        // rule to the actual Text BEFORE its expanding frame, never its card.
        observations.append("Welcome AX title: frame=\(state.frame), " +
                            "observedPixels=\((state.frame.height * scale).rounded()), " +
                            "requiredPixelsAtAXWidth=\(ceil(axRequired.height * scale))")
        observations.append("Welcome title: category=\(category.rawValue), font=\(font.pointSize), " +
                            "fontName=\(font.fontName), ascent=\(font.ascender), descent=\(font.descender), " +
                            "frame=\(frame), measurementWidth=\(measurementWidth), " +
                            "requiredHeight=\(required.height), scale=\(scale), " +
                            "observedPixels=\((frame.height * scale).rounded()), " +
                            "requiredPixels=\(ceil(required.height * scale)); " +
                            "source=DEBUG GeometryReader before frame/padding, not AX StaticText")
        XCTAssertGreaterThanOrEqual((frame.height * scale).rounded(), ceil(required.height * scale),
                                   "The actual title must fit the requested largest-size font in its recorded Text layout")
    }

    private struct RecordedTitleLayout: Decodable {
        let kind: String
        let probe: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double

        static func frame(from value: String, probe: String) -> CGRect? {
            let prefix = "DEBUG_UI_TEXT_LAYOUT_V1:"
            guard value.utf8.count <= 1_024, value.hasPrefix(prefix),
                  let data = String(value.dropFirst(prefix.count)).data(using: .utf8),
                  let record = try? JSONDecoder().decode(Self.self, from: data),
                  record.kind == "recorded-swiftui-text-layout", record.probe == probe else { return nil }
            let frame = CGRect(x: record.x, y: record.y, width: record.width, height: record.height)
            guard !frame.isEmpty, !frame.isNull, !frame.isInfinite,
                  frame.minX.isFinite, frame.minY.isFinite,
                  frame.maxX.isFinite, frame.maxY.isFinite else { return nil }
            return frame
        }
    }

    private func expectValue(_ value: String, of element: XCUIElement) {
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND value == %@", value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
    }

    private func expectGone(_ element: XCUIElement) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 10), .completed)
    }

    private func capture(_ suffix: String, in app: XCUIApplication) {
        XCTAssertEqual(app.state, .runningForeground,
                       "Supplemental captures must show the reached foreground app")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Supplemental-AXXXL-Beta-" + suffix
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
