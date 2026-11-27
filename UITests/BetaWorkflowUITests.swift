import Foundation
import XCTest

final class BetaWorkflowUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func makeApp(corrupt: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["KEYFILL_UI_TEXT_INPUT_TRACE"] = "1"
        if corrupt { app.launchEnvironment["KEYFILL_UI_TEST_CORRUPT"] = "1" }
        return app
    }

    private func launchHealthyStudio(_ app: XCUIApplication) {
        app.launch()
        waitForEnabledStudioControl(app.buttons["openProjectLibrary"])
    }

    private func assertLabel(_ expected: String, of element: XCUIElement, in app: XCUIApplication,
                             file: StaticString = #filePath, line: UInt = #line) {
        // Match the existing readiness pattern: one immutable AX snapshot
        // supplies the label instead of separate presence and value queries.
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? element.snapshot().label) == expected
        }, object: element)
        let result = XCTWaiter.wait(for: [ready], timeout: 15)
        if result != .completed {
            recordAssertionFailure("label", expected: expected, of: element, in: app,
                                   result: result, file: file, line: line)
        }
        XCTAssertEqual(result, .completed,
                       "Expected exact label: \(expected)", file: file, line: line)
    }

    private func assertValue(_ expected: String, of element: XCUIElement, in app: XCUIApplication,
                             file: StaticString = #filePath, line: UInt = #line) {
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND value == %@", expected), object: element)
        let result = XCTWaiter.wait(for: [ready], timeout: 10)
        if result != .completed {
            recordAssertionFailure("value", expected: expected, of: element, in: app,
                                   result: result, file: file, line: line)
        }
        XCTAssertEqual(result, .completed,
                       "The real editor must contain the complete entered draft", file: file, line: line)
    }

    private struct DiagnosticText {
        let limit: Int
        private(set) var text = ""
        private(set) var truncated = false
        private var scalarCount = 0

        init(limit: Int) { self.limit = limit }

        mutating func append(_ line: @autoclosure () -> String) {
            guard !truncated else { return }
            let marker = "\n[diagnostic text truncated]"
            let separator = text.isEmpty ? "" : "\n"
            // Reserve the marker before accumulating any content. Scalar limits
            // also bound bytes, even for a single enormous grapheme cluster.
            let available = limit - scalarCount - separator.unicodeScalars.count - marker.unicodeScalars.count
            guard available >= 0 else {
                text += marker
                truncated = true
                return
            }
            let scalars = Array(line().unicodeScalars.prefix(available + 1))
            text += separator
            text.unicodeScalars.append(contentsOf: scalars.prefix(available))
            scalarCount += separator.unicodeScalars.count + min(scalars.count, available)
            if scalars.count > available {
                text += marker
                truncated = true
            }
        }
    }

    private func diagnosticField(_ value: String) -> String {
        // Bound the source before reflection can expand control characters.
        let scalars = Array(value.unicodeScalars.prefix(513))
        var prefix = ""
        prefix.unicodeScalars.append(contentsOf: scalars.prefix(512))
        return String(reflecting: prefix) + (scalars.count > 512 ? " [field truncated at 512 scalars]" : "")
    }

    private func diagnosticValue(_ value: Any?) -> String {
        guard let value else { return "nil" }
        if let text = value as? String { return diagnosticField(text) }
        if let number = value as? NSNumber { return diagnosticField(number.stringValue) }
        return "[non-string, nonnumeric value omitted]"
    }

    private func diagnosticError(_ error: Error) -> String {
        let failure = error as NSError
        return "domain=\(diagnosticField(failure.domain)), code=\(failure.code), " +
            "description=\(diagnosticField(failure.localizedDescription))"
    }

    private func snapshotDetails(_ snapshot: XCUIElementSnapshot) -> String {
        "identifier=\(diagnosticField(snapshot.identifier)), type=\(snapshot.elementType.rawValue), " +
            "label=\(diagnosticField(snapshot.label)), value=\(diagnosticValue(snapshot.value)), " +
            "frame=\(snapshot.frame), enabled=\(snapshot.isEnabled)"
    }

    private func recordAssertionFailure(_ attribute: String, expected: String, of element: XCUIElement,
                                        in app: XCUIApplication, result: XCTWaiter.Result,
                                        file: StaticString, line: UInt) {
        let attachmentName = "Beta-\(attribute)-failure-\(line)"
        var observations = DiagnosticText(limit: 16_384)
        observations.append("Test: \(diagnosticField(name))")
        observations.append("Source: \(diagnosticField(String(describing: file))):\(line)")
        observations.append("Waiter result: \(result.rawValue)")
        observations.append("Expected exact \(attribute) (diagnostic display): \(diagnosticField(expected))")
        observations.append("Application state: \(app.state.rawValue)")
        // Capture after the original deadline without retrying the expectation.
        // Every attribute comes from this single actual element snapshot.
        do {
            let target = try element.snapshot()
            observations.append("Target snapshot: \(snapshotDetails(target))")
            observations.append("Target snapshot error: none")
        } catch {
            observations.append("Target snapshot unavailable; error: \(diagnosticError(error))")
        }

        // Inspect one immutable application snapshot, with bounded traversal and
        // samples. Missing recovery identities never trigger extra AX queries.
        var hierarchyText = DiagnosticText(limit: 32_768)
        do {
            let nodeLimit = 2_048
            var pending = [(snapshot: try app.snapshot(), depth: 0)]
            var snapshots: [(snapshot: XCUIElementSnapshot, depth: Int)] = []
            var traversalTruncated = false
            while let entry = pending.popLast() {
                snapshots.append(entry)
                let available = nodeLimit - snapshots.count - pending.count
                let children = entry.snapshot.children
                if children.count > available { traversalTruncated = true }
                pending.append(contentsOf: children.prefix(available).reversed().map {
                    (snapshot: $0, depth: entry.depth + 1)
                })
            }
            let summary = "Application snapshot: \(snapshots.count) nodes inspected; traversal truncated=\(traversalTruncated); error: none"
            observations.append(summary)
            hierarchyText.append("\(summary). Hierarchy uses the same snapshot; node limit=\(nodeLimit), field limit=512 scalars.")
            for entry in snapshots {
                hierarchyText.append("depth=\(entry.depth): \(snapshotDetails(entry.snapshot))")
                if hierarchyText.truncated { break }
            }
            for identifier in ["libraryRecoverySuccess", "libraryRecoveryProgress",
                               "libraryRecoveryInspectionProgress", "libraryRecoveryMessage",
                               "closeLibraryRecovery", "reviewLibraryRecovery",
                               "libraryRecoveryImportInstructions"] {
                let matches = snapshots.filter { $0.snapshot.identifier == identifier }
                observations.append("Recovery identity \(identifier): \(matches.count) matches in inspected nodes; sample truncated=\(matches.count > 4)")
                for match in matches.prefix(4) { observations.append(snapshotDetails(match.snapshot)) }
            }
            let alerts = snapshots.filter { $0.snapshot.elementType == .alert }
            observations.append("Alerts: \(alerts.count) matches in inspected nodes; sample truncated=\(alerts.count > 4)")
            for alert in alerts.prefix(4) { observations.append(snapshotDetails(alert.snapshot)) }
            for label in ["Keep files and start again", "Cancel"] {
                let actions = snapshots.filter { $0.snapshot.elementType == .button && $0.snapshot.label == label }
                observations.append("Confirmation action \(diagnosticField(label)): \(actions.count) matches in inspected nodes; sample truncated=\(actions.count > 4)")
                for action in actions.prefix(4) { observations.append(snapshotDetails(action.snapshot)) }
            }
        } catch {
            let failure = "Application snapshot unavailable; error: \(diagnosticError(error))"
            observations.append(failure)
            hierarchyText.append(failure)
        }

        // Both the interrupted-run log and text attachments have explicit caps.
        print("\(attachmentName):\n\(observations.text)")
        let state = XCTAttachment(string: observations.text)
        state.name = attachmentName
        state.lifetime = .keepAlways
        add(state)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "\(attachmentName)-screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let hierarchy = XCTAttachment(string: hierarchyText.text)
        hierarchy.name = "\(attachmentName)-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    private func waitForDismissal(_ element: XCUIElement,
                                  file: StaticString = #filePath, line: UInt = #line) {
        let dismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed,
                       file: file, line: line)
    }

    private func tapContent(_ element: XCUIElement, in app: XCUIApplication,
                            towardBottom: Bool = true, avoidingKeyboard: Bool = false,
                            file: StaticString = #filePath, line: UInt = #line) {
        revealStudioContent(element, in: app, towardBottom: towardBottom,
                            fullyVisible: avoidingKeyboard, file: file, line: line)
        waitForEnabledStudioControl(element, file: file, line: line)
        XCTAssertTrue(element.isHittable, file: file, line: line)
        element.tap()
    }

    private func openProjects(in app: XCUIApplication) {
        tapContent(app.buttons["openProjectLibrary"], in: app, towardBottom: false)
        waitForEnabledStudioControl(app.buttons["projectLibraryDone"])
    }

    private func closeProjects(in app: XCUIApplication) {
        let done = app.buttons["projectLibraryDone"]
        waitForEnabledStudioControl(done)
        XCTAssertTrue(done.isHittable)
        done.tap()
        waitForDismissal(done)
        waitForEnabledStudioControl(app.buttons["openProjectLibrary"])
    }

    private func assertEmptyInitialLibrary(in app: XCUIApplication) {
        let empty = app.staticTexts["No saved projects yet."]
        revealStudioContent(empty, in: app, towardBottom: false)
        XCTAssertEqual(empty.label, "No saved projects yet.")
        XCTAssertFalse(app.descendants(matching: .any)["activeProjectRow"].firstMatch.exists)
        XCTAssertFalse(app.buttons["Options for Portrait setup"].exists,
                       "Opening Projects must not save an unwanted default project")
        XCTAssertFalse(app.buttons["librarySaveCurrent"].exists,
                       "A pristine first project must not require saving the starter")
        for identifier in ["newProject", "importEditableProject"] {
            let action = app.buttons[identifier]
            revealStudioContent(action, in: app)
            waitForEnabledStudioControl(action)
            XCTAssertTrue(action.isHittable)
        }
    }

    private func assertOnlyProject(_ name: String, in app: XCUIApplication) {
        let active = app.descendants(matching: .any)["activeProjectRow"].firstMatch
        assertLabel("Current project: \(name)", of: active, in: app)
        XCTAssertEqual(active.value as? String, "3 lights")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Options for ")).count, 1,
                       "First creation must save only the requested project")
        XCTAssertTrue(app.buttons["Options for \(name)"].exists)
        if name != "Portrait setup" {
            XCTAssertFalse(app.buttons["Options for Portrait setup"].exists)
            XCTAssertFalse(app.buttons["Open Portrait setup"].exists)
        }
        XCTAssertFalse(app.staticTexts["No saved projects yet."].exists)
    }

    private func createInitialProject(named name: String, in app: XCUIApplication) {
        assertLabel("Unsaved changes", of: app.staticTexts["projectStatus"], in: app)
        openProjects(in: app)
        assertEmptyInitialLibrary(in: app)
        tapContent(app.buttons["newProject"], in: app, towardBottom: false)
        let input = app.textFields["projectNameInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        let clear = app.buttons["clearProjectName"]
        waitForEnabledStudioControl(clear)
        clear.tap()
        input.tap()
        dismissKeyboardTypingIntroduction(in: app)
        revealStudioContent(input, in: app, fullyVisible: true)
        input.tap()
        input.typeText(name)
        assertValue(name, of: input, in: app)
        tapContent(app.buttons["confirmProjectName"], in: app, avoidingKeyboard: true)
        waitForDismissal(input)
        assertOnlyProject(name, in: app)
        closeProjects(in: app)
        waitForCommittedProject(in: app)
        assertLabel(name, of: app.staticTexts["projectName"], in: app)
    }

    func testWelcomeDismissalPersistsAndInitialActionsNeedNoDefaultSave() throws {
        let app = makeApp()
        defer { app.terminate() }
        launchHealthyStudio(app)
        let welcome = app.staticTexts["studioWelcomeTitle"]
        assertLabel("Start your first portrait", of: welcome, in: app)
        assertLabel("Unsaved changes", of: app.staticTexts["projectStatus"], in: app)
        waitForEnabledStudioControl(app.buttons["welcomeSaveCurrent"])

        // Exercise the welcome's actual Projects route without using Save.
        tapContent(app.buttons["welcomeOpenProjects"], in: app)
        waitForEnabledStudioControl(app.buttons["projectLibraryDone"])
        assertEmptyInitialLibrary(in: app)
        closeProjects(in: app)
        assertLabel("Start your first portrait", of: welcome, in: app)
        tapContent(app.buttons["dismissStudioWelcome"], in: app, towardBottom: false)
        waitForDismissal(welcome)
        assertLabel("Unsaved changes", of: app.staticTexts["projectStatus"], in: app)

        app.terminate()
        launchHealthyStudio(app)
        XCTAssertFalse(welcome.exists, "Explicit welcome dismissal must survive the same-UUID relaunch")
        XCTAssertFalse(app.buttons["dismissStudioWelcome"].exists)
        assertLabel("Unsaved changes", of: app.staticTexts["projectStatus"], in: app)
        openProjects(in: app)
        assertEmptyInitialLibrary(in: app)
        closeProjects(in: app)
        // Import availability is covered here; no file-provider import is performed.
    }

    func testInitialProjectNameEditorSavesOnlyRequestedProjectAndReopens() throws {
        let app = makeApp()
        defer { app.terminate() }
        launchHealthyStudio(app)
        let name = "First beta portrait"
        createInitialProject(named: name, in: app)
        XCTAssertFalse(app.staticTexts["studioWelcomeTitle"].exists)

        // No extra Save can conceal a missing create transaction.
        app.terminate()
        launchHealthyStudio(app)
        waitForCommittedProject(in: app)
        assertLabel(name, of: app.staticTexts["projectName"], in: app)
        XCTAssertFalse(app.staticTexts["studioWelcomeTitle"].exists)
        openProjects(in: app)
        assertOnlyProject(name, in: app)
        closeProjects(in: app)
    }

    private func assertProtectedLibrary(in app: XCUIApplication) {
        assertLabel("Saved data protected", of: app.staticTexts["projectStatus"], in: app)
        assertLabel("Project unavailable", of: app.staticTexts["projectName"], in: app)
        for identifier in ["saveProject", "openProjectLibrary", "exportLightingPlan", "recipes"] {
            let action = app.buttons[identifier]
            XCTAssertTrue(action.exists, "Protected storage must retain \(identifier)")
            XCTAssertFalse(action.isEnabled, "Recovery must not enable editing before confirmation")
        }
        XCTAssertFalse(app.staticTexts["studioWelcomeTitle"].exists)
        XCTAssertFalse(app.buttons["addLightShortcut"].exists)
        waitForEnabledStudioControl(app.buttons["openLibraryRecovery"])
    }

    private func reviewRecovery(in app: XCUIApplication) -> XCUIElement {
        tapContent(app.buttons["openLibraryRecovery"], in: app)
        waitForEnabledStudioControl(app.buttons["closeLibraryRecovery"])
        let review = app.buttons["reviewLibraryRecovery"]
        revealStudioContent(review, in: app)
        waitForEnabledStudioControl(review)
        let summary = app.descendants(matching: .any)["libraryRecoveryInspectionSummary"].firstMatch
        XCTAssertTrue(summary.exists)
        XCTAssertTrue(summary.label.contains("Saved files to keep: 1"),
                      "The existing corrupt fixture supplies one unreadable legacy file")
        review.tap()
        let confirmation = app.alerts["Keep files and start again?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        XCTAssertTrue(confirmation.buttons["Keep files and start again"].isEnabled)
        return confirmation
    }

    private func closeRecovery(in app: XCUIApplication) {
        let done = app.buttons["closeLibraryRecovery"]
        waitForEnabledStudioControl(done)
        XCTAssertTrue(done.isHittable)
        done.tap()
        waitForDismissal(done)
    }

    func testUnreadableLibraryRecoveryNeedsConfirmationAndSurvivesRelaunch() throws {
        let app = makeApp(corrupt: true)
        defer { app.terminate() }
        app.launch()
        assertProtectedLibrary(in: app)
        let confirmation = reviewRecovery(in: app)
        confirmation.buttons["Cancel"].tap()
        waitForDismissal(confirmation)
        XCTAssertFalse(app.descendants(matching: .any)["libraryRecoverySuccess"].firstMatch.exists)
        waitForEnabledStudioControl(app.buttons["reviewLibraryRecovery"])
        closeRecovery(in: app)
        assertProtectedLibrary(in: app)

        // Cancellation must leave the original failure durable. Removing the
        // seed flag proves the next launch does not recreate the damaged file.
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "KEYFILL_UI_TEST_CORRUPT")
        app.launch()
        assertProtectedLibrary(in: app)
        reviewRecovery(in: app).buttons["Keep files and start again"].tap()
        let success = app.descendants(matching: .any)["libraryRecoverySuccess"].firstMatch
        assertLabel("New library is ready", of: success, in: app)
        XCTAssertTrue(app.staticTexts["libraryRecoveryImportInstructions"].exists,
                      "The committed outcome must remain reviewable until Done")
        closeRecovery(in: app)
        waitForCommittedProject(in: app)
        waitForEnabledStudioControl(app.buttons["openProjectLibrary"])
        XCTAssertFalse(app.buttons["openLibraryRecovery"].exists)
        XCTAssertFalse(app.staticTexts["studioWelcomeTitle"].exists)

        // Relaunch immediately, without an ordinary Save that could mask a
        // recovery which cleared the block in memory but failed to persist.
        app.terminate()
        launchHealthyStudio(app)
        waitForCommittedProject(in: app)
        waitForEnabledStudioControl(app.buttons["saveProject"])
        assertLabel("Portrait setup", of: app.staticTexts["projectName"], in: app)
        XCTAssertFalse(app.buttons["openLibraryRecovery"].exists)
        XCTAssertFalse(app.staticTexts["studioWelcomeTitle"].exists)
        openProjects(in: app)
        assertOnlyProject("Portrait setup", in: app)
        closeProjects(in: app)
    }

    private func openFeedbackFromSettings(in app: XCUIApplication) {
        tapContent(app.buttons["openBetaFeedback"], in: app)
        waitForEnabledStudioControl(app.buttons["closeBetaFeedback"])
        XCTAssertFalse(app.buttons["shareBetaFeedbackReport"].exists,
                       "The exact report must be reviewed before sharing is available")
    }

    private func enterFeedbackNote(_ text: String, identifier: String, in app: XCUIApplication) {
        // SwiftUI's vertical TextField can be exposed as either native input type.
        let field = app.descendants(matching: .any)[identifier].firstMatch
        revealStudioContent(field, in: app, fullyVisible: true)
        XCTAssertTrue([XCUIElement.ElementType.textField, .textView].contains(field.elementType))
        field.tap()
        dismissKeyboardTypingIntroduction(in: app)
        revealStudioContent(field, in: app, fullyVisible: true)
        field.tap()
        field.typeText(text)
        assertValue(text, of: field, in: app)
    }

    private func assertFeedbackReport(problem: String, steps: String, expected: String,
                                      privateProject: String, in app: XCUIApplication) {
        let preview = app.staticTexts["betaFeedbackReportText"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        let report = preview.label
        let lines = report.components(separatedBy: "\n")
        guard lines.count >= 6 else {
            XCTFail("The report must expose its complete text, including all environment fields")
            return
        }
        // Versions may change between builds. Accept only the bounded version
        // token contract; compare every other byte against an independent fixture.
        for (index, key) in [(2, "App version"), (3, "Build")] {
            let pattern = "^\(key): (?=[A-Za-z0-9.+-]*[0-9])[A-Za-z0-9.+-]{1,64}$"
            XCTAssertNotNil(lines[index].range(of: pattern, options: .regularExpression))
        }
        XCTAssertTrue(["Device family: iPhone", "Device family: iPad", "Device family: Other"].contains(lines[5]))
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let exact = """
        Key & Fill — beta feedback

        \(lines[2])
        \(lines[3])
        OS version: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)
        \(lines[5])

        Problem or observation
        \(problem)

        Steps to reproduce
        \(steps)

        Expected result
        \(expected)

        Report contents
        This report contains app version/build, OS version, device family, and any notes you enter. The app adds no photographs, project or scene contents, account details, network or hardware identifiers, or logs. Check your notes for personal information before sharing.

        Simulation and calibration
        Lighting previews and reference suggestions are simulations and planning aids. They are not calibrated equipment or camera exposure, and do not establish an exact reconstruction. Confirm results with your equipment, a light meter and test photographs.
        """
        XCTAssertEqual(report, exact, "Preview must contain exactly the reviewed notes and allowed metadata")
        XCTAssertFalse(report.contains(privateProject), "The app must not append the actual saved project name")
        let fixtureID = app.launchEnvironment["KEYFILL_UI_TEST_ID"]!
        XCTAssertFalse(report.localizedCaseInsensitiveContains(fixtureID), "A session or storage identifier is not report metadata")
        let share = app.buttons["shareBetaFeedbackReport"]
        revealStudioContent(share, in: app)
        waitForEnabledStudioControl(share)
        XCTAssertEqual(share.label, "Share report")
        // Do not choose a destination: this verifies the reviewed app content,
        // not system sharing, provider delivery, or network behavior.
    }

    private func returnToFeedbackDraft(in app: XCUIApplication) {
        let navigation = app.navigationBars["Review report"]
        XCTAssertTrue(navigation.exists)
        XCTAssertEqual(navigation.buttons.count, 1, "The preview has one native Back action")
        let back = navigation.buttons.firstMatch
        waitForEnabledStudioControl(back)
        back.tap()
        waitForDismissal(navigation)
        let close = app.buttons["closeBetaFeedback"]
        // The Form keeps its previous scroll position when navigating back.
        // Reveal its header before waiting for a lazily materialized action.
        revealStudioContent(close, in: app, towardBottom: false, fullyVisible: true)
        waitForEnabledStudioControl(close)
    }

    func testFeedbackExactReviewBackAndDiscardExcludePrivateProjectData() throws {
        let app = makeApp()
        defer { app.terminate() }
        launchHealthyStudio(app)
        let privateName = "Private beta rig " + String(app.launchEnvironment["KEYFILL_UI_TEST_ID"]!.prefix(8))
        createInitialProject(named: privateName, in: app)
        tapContent(app.buttons["studioTools"], in: app, towardBottom: false)
        let settings = app.buttons["Settings"]
        waitForEnabledStudioControl(settings)
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        openFeedbackFromSettings(in: app)

        let notes = [
            ("betaFeedbackProblem", "The preview stops after choosing Study."),
            ("betaFeedbackSteps", "Open Study. Return to Plan."),
            ("betaFeedbackExpectedResult", "The previous setup should remain visible.")
        ]
        for (identifier, text) in notes { enterFeedbackNote(text, identifier: identifier, in: app) }
        tapContent(app.buttons["reviewBetaFeedback"], in: app, avoidingKeyboard: true)
        assertFeedbackReport(problem: notes[0].1, steps: notes[1].1, expected: notes[2].1,
                             privateProject: privateName, in: app)
        returnToFeedbackDraft(in: app)
        for (identifier, text) in notes {
            let field = app.descendants(matching: .any)[identifier].firstMatch
            revealStudioContent(field, in: app, fullyVisible: true)
            assertValue(text, of: field, in: app)
        }

        let close = app.buttons["closeBetaFeedback"]
        tapContent(close, in: app, towardBottom: false, avoidingKeyboard: true)
        let keepEditing = app.buttons["Keep editing"]
        XCTAssertTrue(keepEditing.waitForExistence(timeout: 10))
        keepEditing.tap()
        waitForDismissal(keepEditing)
        let problem = app.descendants(matching: .any)[notes[0].0].firstMatch
        revealStudioContent(problem, in: app, towardBottom: false, fullyVisible: true)
        assertValue(notes[0].1, of: problem, in: app)
        tapContent(close, in: app, towardBottom: false, avoidingKeyboard: true)
        let discard = app.buttons["Discard draft"]
        XCTAssertTrue(discard.waitForExistence(timeout: 10))
        discard.tap()
        waitForDismissal(close)

        openFeedbackFromSettings(in: app)
        tapContent(app.buttons["reviewBetaFeedback"], in: app)
        assertFeedbackReport(problem: "Not provided.", steps: "Not provided.", expected: "Not provided.",
                             privateProject: privateName, in: app)
        returnToFeedbackDraft(in: app)
        tapContent(close, in: app, towardBottom: false)
        waitForDismissal(close)
        XCTAssertFalse(app.buttons["Discard draft"].exists,
                       "A reopened, empty draft must close without retaining discarded notes")
        let settingsDone = app.navigationBars["Settings"].buttons["Done"]
        waitForEnabledStudioControl(settingsDone)
        settingsDone.tap()
        waitForDismissal(app.navigationBars["Settings"])
        waitForCommittedProject(in: app)
        assertLabel(privateName, of: app.staticTexts["projectName"], in: app)
    }
}
