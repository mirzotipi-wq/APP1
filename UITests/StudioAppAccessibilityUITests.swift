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
        for key in ["projectStatus", "intensityReadout", "precisionHeading", "libraryWarning", "projectNameHeading",
                    "projectNameSave", "projectNameCancel", "libraryDone"] {
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
        // Only this semantics/layout workflow opts into recorded Text geometry.
        app.launchEnvironment["KEYFILL_UI_TEXT_LAYOUT_PROBES"] = "1"
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

        let openMeter = app.buttons["openMeter"]
        try control(openMeter, label: "Open light meter and test card", in: app, towardBottom: false)
        openMeter.tap()
        let balance = app.sliders["previewWhiteBalance"]
        expectValue(balance, "5600 K")
        // SwiftUI localizes interpolated integers in both Text and its spoken
        // label. This workflow pins en_US, whose preset labels use grouping.
        for (kelvin, displayedKelvin) in [(3200, "3,200"), (5600, "5,600"), (6500, "6,500")] {
            let preset = app.buttons["balance-\(kelvin)"]
            let state = try control(preset, label: "Balance \(displayedKelvin) kelvin", in: app)
            XCTAssertEqual(state.isSelected, kelvin == 5600)
            try text(preset.staticTexts["\(displayedKelvin) K"], equals: "\(displayedKelvin) K", style: .caption1,
                     category: category, in: app, weight: .medium, monospacedDigits: true)
            if kelvin == 5600 { try selectedCheckmark(in: preset) }
        }
        let tungsten = app.buttons["balance-3200"]
        try control(tungsten, in: app, towardBottom: false)
        tungsten.tap()
        expectValue(balance, "3200 K")
        XCTAssertTrue(tungsten.isSelected)
        XCTAssertFalse(app.buttons["balance-5600"].isSelected)
        try selectedCheckmark(in: tungsten)
        capture(name + "-Meter-preset-selection", in: app)
        try control(undo, label: "Undo", in: app, scrolling: false)
        undo.tap()
        expectValue(balance, "5600 K")
        let daylight = app.buttons["balance-5600"]
        try control(daylight, in: app)
        XCTAssertTrue(daylight.isSelected)
        XCTAssertFalse(tungsten.isSelected)
        try selectedCheckmark(in: daylight)

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

        try control(create, label: "New project", in: app)
        create.tap()
        let nameField = app.textFields["projectNameInput"]
        let nameCancel = app.buttons["projectNameCancel"]
        let nameSave = app.buttons["confirmProjectName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        dismissKeyboardTypingIntroduction(in: app)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10),
                      "Name-entry controls must remain reachable with the keyboard visible")
        measured["projectNameHeading"] = try text(app.staticTexts["Project name"], equals: "Project name",
                                                  style: .headline, category: category, in: app,
                                                  towardBottom: false)
        let nameDraft = try control(nameField, label: "Name", in: app)
        XCTAssertEqual(nameDraft.value as? String, "Portrait setup")
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        capture(name + "-Project-name-field-keyboard", in: app)
        try control(nameSave, label: "Save project name", in: app)
        measured["projectNameSave"] = try recordedButtonText(nameSave, probe: "projectNameSaveTitle",
            equals: "Save project name", style: .body, category: category, in: app, weight: .semibold)
        XCTAssertTrue(app.keyboards.firstMatch.exists,
                      "Reaching Save must not depend on dismissing the keyboard")
        capture(name + "-Project-name-save-keyboard", in: app)
        try control(nameCancel, label: "Cancel", in: app, towardBottom: false)
        measured["projectNameCancel"] = try recordedButtonText(nameCancel, probe: "projectNameCancelTitle",
            equals: "Cancel", style: .body, category: category, in: app)
        XCTAssertTrue(app.keyboards.firstMatch.exists,
                      "Reaching Cancel must not depend on dismissing the keyboard")
        capture(name + "-Project-name-cancel-keyboard", in: app)
        nameCancel.tap()
        expectGone(nameField)

        let done = app.buttons["projectLibraryDone"]
        let doneState = try control(done, label: "Done", in: app, scrolling: false)
        measured["libraryDone"] = try recordedButtonText(done, probe: "libraryDoneTitle",
            equals: "Done", style: .body, category: category, in: app, weight: .semibold, scrolling: false)
        assertContained(try XCTUnwrap(measured["libraryDone"]), inside: doneState.frame)
        capture(name + "-Library-done", in: app)
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
        assertStudioMinimumHitTarget(state.frame, label: state.label)
        assertContained(state.frame, inside: scrolling ? contentViewport(for: state, in: app) : app.frame)
        return state
    }

    @discardableResult
    private func text(_ element: XCUIElement, equals expected: String, style: UIFont.TextStyle,
                      category: UIContentSizeCategory, in app: XCUIApplication,
                      weight: UIFont.Weight? = nil, monospacedDigits: Bool = false,
                      towardBottom: Bool = true, scrolling: Bool = true) throws -> CGRect {
        if scrolling { revealStudioContent(element, in: app, towardBottom: towardBottom, fullyVisible: true) }
        let state = try element.snapshot()
        record(state)
        XCTAssertEqual(state.elementType, .staticText, "Measure actual text, not its surrounding control")
        XCTAssertEqual(state.label, expected)
        assertContained(state.frame, inside: scrolling ? contentViewport(for: state, in: app) : app.frame)
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        var font = UIFont.preferredFont(forTextStyle: style, compatibleWith: traits)
        if monospacedDigits { font = .monospacedDigitSystemFont(ofSize: font.pointSize, weight: weight ?? .regular) }
        else if let weight { font = .systemFont(ofSize: font.pointSize, weight: weight) }
        let required = (expected as NSString).boundingRect(
            with: CGSize(width: max(1, state.frame.width), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        // SwiftUI's text frame contains the line's ascent/descent, not optional
        // font leading. In the retained baseline, caption text has a complete
        // 14.333pt frame; requesting font leading incorrectly requires 16pt.
        // Compare physical pixel counts so fractional AX coordinates do not
        // introduce a whole-point allowance. Required text is rounded upward;
        // the observed frame is normalized to its nearest physical pixel.
        // Screenshots still require inspection of the actual rendered glyphs.
        let scale = UIScreen.main.scale
        let requiredPixels = ceil(required.height * scale)
        let observedPixels = (state.frame.height * scale).rounded()
        observations.append("Text metrics \(expected): ascent=\(font.ascender), descent=\(font.descender), " +
                            "leading=\(font.leading), requiredHeightWithoutLeading=\(required.height), " +
                            "scale=\(scale), requiredPixels=\(requiredPixels), observedPixels=\(observedPixels)")
        XCTAssertGreaterThanOrEqual(observedPixels, requiredPixels,
                                   "The complete \(expected) text must fit its observed frame")
        return state.frame
    }

    /// A native Button may aggregate its visible title into its own AX label.
    /// This reads explicitly tagged DEBUG app layout, not a fabricated StaticText.
    /// Parent semantics/hit targets and original screenshots remain independent.
    private func recordedButtonText(_ element: XCUIElement, probe: String,
                                    equals expected: String, style: UIFont.TextStyle,
                                    category: UIContentSizeCategory, in app: XCUIApplication,
                                    weight: UIFont.Weight? = nil,
                                    scrolling: Bool = true) throws -> CGRect {
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let state = try? element.snapshot(), let value = state.value as? String else { return false }
            return RecordedTextLayout.frame(from: value, probe: probe) != nil
        }, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed,
                       "The opted-in app must publish actual Text layout for \(probe)")
        let state = try element.snapshot()
        XCTAssertEqual(state.elementType, .button)
        XCTAssertEqual(state.label, expected)
        XCTAssertTrue(element.isHittable)
        assertStudioMinimumHitTarget(state.frame, label: expected)
        let viewport = scrolling ? contentViewport(for: state, in: app) : app.frame
        assertContained(state.frame, inside: viewport)
        let value = try XCTUnwrap(state.value as? String, "Expected tagged app layout diagnostic")
        let frame = try XCTUnwrap(RecordedTextLayout.frame(from: value, probe: probe),
                                 "Missing or invalid actual Text frame for \(probe)")
        assertContained(frame, inside: state.frame)
        assertContained(frame, inside: viewport)

        // The same UIFont line-box and physical-pixel rule as the unchanged
        // StaticText helper. The measured rectangle is the Text BEFORE the
        // Button's expanding frame/padding, never the parent action's rectangle.
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        var font = UIFont.preferredFont(forTextStyle: style, compatibleWith: traits)
        if let weight { font = .systemFont(ofSize: font.pointSize, weight: weight) }
        let required = (expected as NSString).boundingRect(
            with: CGSize(width: max(1, frame.width), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        let scale = UIScreen.main.scale
        let requiredPixels = ceil(required.height * scale)
        let observedPixels = (frame.height * scale).rounded()
        observations.append("Recorded app Text layout \(probe): text=\(expected), frame=\(frame), " +
                            "owner=\(state.frame), viewport=\(viewport), " +
                            "requiredPixels=\(requiredPixels), observedPixels=\(observedPixels); " +
                            "source=DEBUG GeometryReader before frame/padding, not AX StaticText")
        XCTAssertGreaterThanOrEqual(observedPixels, requiredPixels,
                                   "The complete \(expected) text must fit its recorded Text layout")
        return frame
    }

    private struct RecordedTextLayout: Decodable {
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
        // Scope obscuring navigation to the target's actual ancestors. A
        // covered Projects large-title bar is lower than the New project bar
        // but cannot obscure content in that foreground sheet.
        let navigationBars = app.otherElements.containing(state.elementType, identifier: key)
            .children(matching: .navigationBar).allElementsBoundByIndex
        // Keep this independent check fresh after reveal. Each bar contributes
        // its identifier and frame from one actual snapshot.
        guard let navigationStates = try? navigationBars.map({ try $0.snapshot() }) else {
            XCTFail("Could not snapshot owning navigation bars for \(state.label)")
            return .null
        }
        let navigationIdentifiers = Set(navigationStates.map { $0.identifier })
        let navigationBottom = navigationStates.map { $0.frame }
            .filter { !$0.isEmpty && $0.maxY.isFinite && $0.intersects(viewport) }
            .map(\.maxY).max()
        if let navigationBottom {
            let bottom = viewport.maxY
            viewport.origin.y = max(viewport.minY, navigationBottom)
            viewport.size.height = max(0, bottom - viewport.minY)
        }
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            let inputViews = app.otherElements.matching(NSPredicate(
                format: "identifier IN %@", ["inputView", "SystemInputAssistantView"]))
            let frames = [keyboard.frame] + inputViews.allElementsBoundByIndex.map(\.frame)
            if let top = frames.filter({ !$0.isEmpty && $0.minY.isFinite && $0.intersects(viewport) })
                .map(\.minY).min() {
                viewport.size.height = max(0, min(viewport.maxY, top) - viewport.minY)
            }
        }
        let fixedControls = app.buttons.matching(NSPredicate(
            format: "identifier IN %@", ["undo", "projectLibraryDone"]))
        for control in fixedControls.allElementsBoundByIndex where control.isHittable {
            guard let controlState = try? control.snapshot() else {
                XCTFail("Could not snapshot a hittable fixed control")
                return .null
            }
            let owners = app.otherElements.containing(.button, identifier: controlState.identifier)
                .children(matching: .navigationBar)
                .matching(NSPredicate(format: "identifier IN %@", Array(navigationIdentifiers)))
            guard owners.firstMatch.exists else { continue }
            viewport.size.height = max(0, min(viewport.maxY, controlState.frame.minY) - viewport.minY)
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
