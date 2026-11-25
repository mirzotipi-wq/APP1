import XCTest
import UIKit

/// Required app semantics and layout coverage. Platform accessibility audits
/// remain separate diagnostics; these assertions do not run or replace them.
final class StudioAppAccessibilityUITests: XCTestCase {
    private var runningApp: XCUIApplication?
    private var observations: [String] = []

    override func setUpWithError() throws { continueAfterFailure = false }

    override func tearDownWithError() throws {
        if let app = runningApp {
            capture("Accessibility-workflow-failure", in: app)
            let hierarchy = XCTAttachment(string: String(app.debugDescription.prefix(24_000)))
            hierarchy.name = "Accessibility-workflow-failure-hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            app.terminate()
        }
        let text = observations.joined(separator: "\n")
        print("Studio-app-accessibility-observations:\n" + text)
        let attachment = XCTAttachment(string: text)
        attachment.name = "Studio-app-accessibility-observed-frames"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEssentialWorkflowAtDefaultAndLargestAccessibilityTextSize() throws {
        let standard = try exerciseEssentialWorkflow(category: .large,
                                                     launchValue: "UICTContentSizeCategoryL", name: "Default")
        let largest = try exerciseEssentialWorkflow(category: .accessibilityExtraExtraExtraLarge,
                                                    launchValue: "UICTContentSizeCategoryAccessibilityXXXL", name: "AXXXL")
        for key in ["projectStatus", "intensityReadout", "precisionHeading", "libraryWarning"] {
            let before = try XCTUnwrap(standard[key], key)
            let after = try XCTUnwrap(largest[key], key)
            observations.append("Growth \(key): default=\(before), AXXXL=\(after)")
            XCTAssertGreaterThanOrEqual(after.height, before.height * 1.25,
                "The actual \(key) text must enlarge; a launch argument alone is not evidence")
        }
        // The identical short numeric text also has room to grow horizontally.
        // This prevents a changed container height from masquerading as scaling.
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(largest["intensityReadout"]).width,
                                   try XCTUnwrap(standard["intensityReadout"]).width * 1.25)
    }

    private func exerciseEssentialWorkflow(category: UIContentSizeCategory, launchValue: String,
                                           name: String) throws -> [String: CGRect] {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-UIPreferredContentSizeCategoryName", launchValue]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        runningApp = app
        observations.append("\nRequested size: \(name) / \(launchValue)")
        app.launch()
        var measured: [String: CGRect] = [:]

        let save = app.buttons["saveProject"], undo = app.buttons["undo"], redo = app.buttons["redo"]
        waitForEnabledStudioControl(save)
        try control(save, label: "Save", in: app, scrolling: false)
        try control(undo, label: "Undo", in: app, scrolling: false, enabled: false)
        try control(redo, label: "Redo", in: app, scrolling: false, enabled: false)
        try text(app.staticTexts["projectName"], equals: "Portrait setup", style: .title2,
                 category: category, in: app, weight: .bold)
        measured["projectStatus"] = try text(app.staticTexts["projectStatus"], equals: "Unsaved changes",
                                             style: .caption1, category: category, in: app)
        for title in ["Plan", "3D", "Camera", "Study"] {
            let choice = try control(app.buttons["viewMode-" + title], label: title, in: app)
            XCTAssertEqual(choice.isSelected, title == "Plan",
                           "The visible mode checkmark must have an equivalent selected trait")
        }
        capture(name + "-Plan-choices", in: app)

        let fillMarker = app.buttons["Select Fill on plan"]
        try control(fillMarker, label: "Select Fill on plan", in: app)
        fillMarker.tap()
        let selectedText = app.staticTexts["planSelectedLight"]
        try text(selectedText, equals: "Selected: Fill · Drag its marker to move", style: .caption1,
                 category: category, in: app, weight: .medium)
        capture(name + "-Plan-selection", in: app)
        let fill = app.buttons["light-Fill"], key = app.buttons["light-Key"]
        let fillState = try control(fill, in: app)
        XCTAssertTrue(fillState.isSelected)
        try selectedCheckmark(in: fill)
        XCTAssertFalse(key.isSelected)
        try control(key, in: app, towardBottom: false)
        key.tap()
        XCTAssertTrue(key.isSelected)
        XCTAssertFalse(fill.isSelected)
        try selectedCheckmark(in: key)
        XCTAssertEqual(selectedText.label, "Selected: Key · Drag its marker to move")

        let exact = app.buttons["lightIntensityExact"], slider = app.sliders["lightIntensity"]
        let exactState = try control(exact, label: "Enter exact intensity", in: app)
        XCTAssertEqual(exactState.value as? String, "900 cd")
        try text(app.staticTexts["Intensity"], equals: "Intensity", style: .subheadline,
                 category: category, in: app, weight: .medium)
        measured["intensityReadout"] = try text(exact.staticTexts["900 cd"], equals: "900 cd",
                                                style: .subheadline, category: category, in: app,
                                                monospacedDigits: true)
        let sliderState = try control(slider, label: "Intensity", in: app)
        XCTAssertEqual(sliderState.value as? String, "900 cd")
        capture(name + "-Inspector", in: app)
        revealStudioContent(exact, in: app, towardBottom: false, fullyVisible: true)
        exact.tap()

        let field = app.textFields["precisionValue"], apply = app.buttons["precisionApply"]
        let cancel = app.buttons["precisionCancel"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        measured["precisionHeading"] = try text(app.staticTexts["Exact value"], equals: "Exact value",
                                                style: .headline, category: category, in: app)
        try control(cancel, label: "Cancel", in: app)
        let draft = try control(field, label: "Intensity in cd", in: app)
        XCTAssertEqual(draft.value as? String, "900")
        try control(apply, label: "Apply value", in: app)
        let allowed = "Allowed: 0 to 100000 cd. No grouping or scientific notation. The value is not snapped to slider increments."
        try text(app.staticTexts[allowed], equals: allowed, style: .footnote, category: category, in: app)
        capture(name + "-Precision-instructions", in: app)
        revealStudioContent(field, in: app, towardBottom: false, fullyVisible: true)
        field.tap()
        dismissKeyboardTypingIntroduction(in: app)
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "4321.5")
        expectValue(field, "4321.5")
        try control(apply, label: "Apply value", in: app)
        capture(name + "-Precision-keyboard", in: app)
        apply.tap()
        expectGone(field)
        expectValue(exact, "4321.5 cd")
        expectValue(slider, "4321.5 cd")
        try control(undo, label: "Undo", in: app, scrolling: false)
        XCTAssertFalse(redo.isEnabled)
        undo.tap()
        expectValue(exact, "900 cd")
        expectValue(slider, "900 cd")
        XCTAssertFalse(undo.isEnabled)
        try control(redo, label: "Redo", in: app, scrolling: false)
        redo.tap()
        expectValue(exact, "4321.5 cd")
        expectValue(slider, "4321.5 cd")
        XCTAssertTrue(undo.isEnabled)
        XCTAssertFalse(redo.isEnabled)
        try text(exact.staticTexts["4321.5 cd"], equals: "4321.5 cd", style: .subheadline,
                 category: category, in: app, monospacedDigits: true)
        exact.tap()
        expectValue(field, "4321.5")
        try control(cancel, label: "Cancel", in: app, towardBottom: false)
        cancel.tap()
        expectGone(field)
        expectValue(exact, "4321.5 cd")

        let projects = app.buttons["openProjectLibrary"]
        try control(projects, label: "Projects", in: app, towardBottom: false)
        projects.tap()
        let librarySave = app.buttons["librarySaveCurrent"]
        waitForEnabledStudioControl(librarySave)
        measured["libraryWarning"] = try text(app.staticTexts["Unsaved lighting setup"],
                                              equals: "Unsaved lighting setup", style: .headline,
                                              category: category, in: app, towardBottom: false)
        try control(librarySave, label: "Save current setup", in: app)
        capture(name + "-Library-unsaved", in: app)
        let create = app.buttons["newProject"], importProject = app.buttons["importEditableProject"]
        try control(create, label: "New project", in: app, enabled: false)
        try control(importProject, label: "Import editable project", in: app, enabled: false)
        revealStudioContent(librarySave, in: app, towardBottom: false, fullyVisible: true)
        librarySave.tap()
        waitForEnabledStudioControl(create)
        expectGone(librarySave)
        try control(create, label: "New project", in: app)
        try control(importProject, label: "Import editable project", in: app)
        let active = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "activeProjectRow", "Current project: Portrait setup")).firstMatch
        XCTAssertTrue(active.waitForExistence(timeout: 10))
        revealStudioContent(active, in: app, towardBottom: false, fullyVisible: true)
        let activeState = try active.snapshot()
        record(activeState)
        XCTAssertEqual(activeState.label, "Current project: Portrait setup")
        XCTAssertEqual(activeState.value as? String, "3 lights")
        XCTAssertTrue(activeState.isSelected, "The current project must expose its checkmark as selection")
        assertContained(activeState.frame, inside: contentViewport(for: activeState, in: app))
        try control(app.buttons["Options for Portrait setup"], label: "Options for Portrait setup", in: app)
        capture(name + "-Library-saved", in: app)
        let done = app.navigationBars["Projects"].buttons["Done"]
        try control(done, label: "Done", in: app, scrolling: false)
        done.tap()
        waitForCommittedProject(in: app)
        expectValue(exact, "4321.5 cd")
        app.terminate()
        runningApp = nil
        return measured
    }

    @discardableResult
    private func control(_ element: XCUIElement, label: String? = nil, in app: XCUIApplication,
                         scrolling: Bool = true, enabled: Bool = true,
                         towardBottom: Bool = true) throws -> any XCUIElementSnapshot {
        if scrolling { revealStudioContent(element, in: app, towardBottom: towardBottom, fullyVisible: true) }
        let state = try element.snapshot()
        record(state)
        if let label { XCTAssertEqual(state.label, label) }
        XCTAssertFalse(state.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertEqual(state.isEnabled, enabled, state.label)
        if enabled { XCTAssertTrue(element.isHittable, state.label) }
        XCTAssertGreaterThanOrEqual(state.frame.width, 44, state.label + " target width")
        XCTAssertGreaterThanOrEqual(state.frame.height, 44, state.label + " target height")
        assertContained(state.frame, inside: scrolling ? contentViewport(for: state, in: app) : app.frame)
        return state
    }

    @discardableResult
    private func text(_ element: XCUIElement, equals expected: String, style: UIFont.TextStyle,
                      category: UIContentSizeCategory, in app: XCUIApplication,
                      weight: UIFont.Weight? = nil, monospacedDigits: Bool = false,
                      towardBottom: Bool = true) throws -> CGRect {
        revealStudioContent(element, in: app, towardBottom: towardBottom, fullyVisible: true)
        let state = try element.snapshot()
        record(state)
        XCTAssertEqual(state.elementType, .staticText, "Measure actual text, not its surrounding control")
        XCTAssertEqual(state.label, expected)
        assertContained(state.frame, inside: contentViewport(for: state, in: app))
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        var font = UIFont.preferredFont(forTextStyle: style, compatibleWith: traits)
        if monospacedDigits { font = .monospacedDigitSystemFont(ofSize: font.pointSize, weight: weight ?? .regular) }
        else if let weight { font = .systemFont(ofSize: font.pointSize, weight: weight) }
        let required = (expected as NSString).boundingRect(
            with: CGSize(width: max(1, state.frame.width), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        // One point accommodates text-bound rounding, not a smaller tap target.
        // This catches constrained text frames; retained screenshots still need
        // rendered-glyph inspection and are not replaced by an AX label check.
        XCTAssertGreaterThanOrEqual(state.frame.height + 1, required.height,
                                   "The complete \(expected) text must fit its observed frame")
        return state.frame
    }

    private func selectedCheckmark(in row: XCUIElement) throws {
        let checkmark = row.images["checkmark.circle.fill"]
        XCTAssertTrue(checkmark.exists, "Selection needs a visible shape as well as color")
        let state = try checkmark.snapshot()
        record(state)
        assertContained(state.frame, inside: row.frame)
    }

    /// Independently check the actual containing scroll surface, not merely the
    /// shared helper's screen inset. Native Forms/Lists may use either container.
    private func contentViewport(for state: any XCUIElementSnapshot, in app: XCUIApplication) -> CGRect {
        let key = state.identifier.isEmpty ? state.label : state.identifier
        let containers = [app.scrollViews.containing(state.elementType, identifier: key).firstMatch,
                          app.collectionViews.containing(state.elementType, identifier: key).firstMatch,
                          app.tables.containing(state.elementType, identifier: key).firstMatch]
        var viewport = CGRect.null
        for container in containers where container.exists {
            let frame = container.frame.intersection(app.frame)
            if !frame.isEmpty { viewport = frame; break }
        }
        XCTAssertFalse(viewport.isNull, "Expected a real scroll container for \(state.label)")
        // The first AX navigation bar may belong to the covered studio. A
        // presented sheet can have a lower bar that also obscures this surface.
        let navigationBottom = app.navigationBars.allElementsBoundByIndex
            .map(\.frame)
            .filter { !$0.isEmpty && $0.maxY.isFinite && $0.intersects(viewport) }
            .map(\.maxY).max()
        if let navigationBottom {
            let bottom = viewport.maxY
            viewport.origin.y = max(viewport.minY, navigationBottom)
            viewport.size.height = max(0, bottom - viewport.minY)
        }
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists { viewport.size.height = max(0, min(viewport.maxY, keyboard.frame.minY) - viewport.minY) }
        let undo = app.buttons["undo"]
        if undo.exists, undo.isHittable {
            viewport.size.height = max(0, min(viewport.maxY, undo.frame.minY) - viewport.minY)
        }
        return viewport
    }

    private func assertContained(_ frame: CGRect, inside viewport: CGRect) {
        XCTAssertTrue(!frame.isEmpty && frame.minX.isFinite && frame.minY.isFinite &&
                      frame.maxX.isFinite && frame.maxY.isFinite, "Expected a finite, nonempty frame: \(frame)")
        XCTAssertTrue(viewport.contains(frame), "Observed frame \(frame) extends outside visible bounds \(viewport)")
    }

    private func expectValue(_ element: XCUIElement, _ value: String) {
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND value == %@", value),
                                              object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed, value)
    }

    private func expectGone(_ element: XCUIElement) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 10), .completed)
    }

    private func record(_ state: any XCUIElementSnapshot) {
        observations.append("\(state.identifier) | \(state.label) | value=\(String(describing: state.value)) | " +
                            "frame=\(state.frame) | enabled=\(state.isEnabled) | selected=\(state.isSelected)")
    }

    private func capture(_ name: String, in app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
