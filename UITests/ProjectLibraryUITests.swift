import XCTest

final class ProjectLibraryUITests: XCTestCase {
    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 15,
                                  file: StaticString = #filePath, line: UInt = #line) {
        // Resolve one immutable accessibility snapshot for both presence and
        // enabled state. The failed initial-launch wait spent 29 seconds
        // resolving existence; read enabled state from that same snapshot.
        let predicate = NSPredicate { _, _ in
            guard let state = try? element.snapshot() else { return false }
            return state.isEnabled
        }
        let ready = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [ready], timeout: timeout)
        if result != .completed {
            // Preserve the real timeout. A cold-launch failure previously
            // retained only a query chain, although the recording later showed
            // the studio. Capture actual application state for the next failure.
            let app = XCUIApplication()
            let description = "Application state: \(app.state.rawValue)\n" +
                "Requested element:\n\(String(element.debugDescription.prefix(8_000)))\n" +
                "Application hierarchy:\n\(String(app.debugDescription.prefix(24_000)))"
            // Keep the same captured state when an interrupted run cannot
            // finalize its result bundle. This adds no accessibility queries.
            print("Project-control-readiness-failure:\n\(description)")
            let state = XCTAttachment(string: description)
            state.name = "Project-control-readiness-failure"
            state.lifetime = .keepAlways
            add(state)
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Project-control-readiness-failure-screen"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertEqual(result, .completed, file: file, line: line)
    }

    /// These scenarios launch a valid library. Finish launch readiness before
    /// starting their separate title and interaction deadlines.
    private func launchStudio(_ app: XCUIApplication,
                              file: StaticString = #filePath, line: UInt = #line) {
        app.launch()
        waitUntilEnabled(app.buttons["openProjectLibrary"], timeout: 30, file: file, line: line)
    }

    private func waitForTitle(_ title: String, in app: XCUIApplication) {
        let predicate = NSPredicate(format: "exists == true AND label == %@", title)
        let ready = XCTNSPredicateExpectation(predicate: predicate, object: app.staticTexts["projectName"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
    }

    /// Check the real external AX owner while layout diagnostics are disabled.
    /// These three actions are single Button leaves in the preserved hierarchy.
    private func assertNormalAction(_ action: XCUIElement, identifier: String, label: String,
                                    file: StaticString = #filePath, line: UInt = #line) throws {
        waitUntilEnabled(action, file: file, line: line)
        let snapshot = try action.snapshot()
        let children = snapshot.children.map {
            "type=\($0.elementType.rawValue), identifier=\($0.identifier), label=\($0.label)"
        }.joined(separator: "\n")
        let description = "identifier=\(snapshot.identifier), type=\(snapshot.elementType.rawValue), " +
            "label=\(snapshot.label), value=\(String(describing: snapshot.value)), " +
            "frame=\(snapshot.frame), children=\(snapshot.children.count)\n\(children)"
        print("Normal-project-action-AX: \(description)")
        let attachment = XCTAttachment(string: description)
        attachment.name = "Normal-project-action-AX-\(identifier)"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(snapshot.identifier, identifier, file: file, line: line)
        XCTAssertEqual(snapshot.elementType, .button, file: file, line: line)
        XCTAssertEqual(snapshot.label, label, file: file, line: line)
        let normalValue = snapshot.value
        XCTAssertTrue(normalValue == nil || (normalValue as? String) == "",
                      "Normal actions must retain an absent or empty String AX value",
                      file: file, line: line)
        XCTAssertTrue(snapshot.children.isEmpty, "The action must remain one grouped AX leaf",
                      file: file, line: line)
        XCTAssertTrue(snapshot.isEnabled, file: file, line: line)
        XCTAssertTrue(action.isHittable, file: file, line: line)
    }

    func testCreateDuplicateRenameSwitchAndRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        XCTAssertNil(app.launchEnvironment["KEYFILL_UI_TEXT_LAYOUT_PROBES"],
                     "This workflow verifies normal, uninstrumented accessibility")
        launchStudio(app)
        let projects = app.buttons["openProjectLibrary"]
        waitUntilEnabled(projects)
        waitUntilEnabled(app.buttons["saveProject"])
        app.buttons["saveProject"].tap()
        waitUntilEnabled(projects)
        projects.tap()
        try assertNormalAction(app.buttons["projectLibraryDone"],
                               identifier: "projectLibraryDone", label: "Done")
        let activeRow = app.descendants(matching: .any)["activeProjectRow"].firstMatch
        XCTAssertTrue(activeRow.waitForExistence(timeout: 10))
        XCTAssertEqual(activeRow.label, "Current project: Portrait setup")
        XCTAssertFalse(app.buttons["Open Portrait setup"].exists)
        waitUntilEnabled(app.buttons["Options for Portrait setup"])
        let create = app.buttons["newProject"]
        waitUntilEnabled(create)
        create.tap()
        let input = app.textFields["projectNameInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        app.buttons["clearProjectName"].tap()
        input.tap()
        dismissKeyboardTypingIntroduction(in: app)
        input.typeText("Editorial")
        let exactEditorial = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Editorial"), object: input)
        XCTAssertEqual(XCTWaiter.wait(for: [exactEditorial], timeout: 10), .completed)
        try assertNormalAction(app.buttons["projectNameCancel"],
                               identifier: "projectNameCancel", label: "Cancel")
        try assertNormalAction(app.buttons["confirmProjectName"],
                               identifier: "confirmProjectName", label: "Save project name")
        waitUntilEnabled(app.buttons["confirmProjectName"])
        app.buttons["confirmProjectName"].tap()
        let options = app.buttons["Options for Editorial"]
        XCTAssertTrue(options.waitForExistence(timeout: 10))
        options.tap()
        app.buttons["Duplicate"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        app.buttons["confirmProjectName"].tap()
        let copy = app.buttons["Options for Editorial copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 10))
        copy.tap()
        app.buttons["Rename"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        app.buttons["clearProjectName"].tap()
        input.tap()
        dismissKeyboardTypingIntroduction(in: app)
        input.typeText("Campaign")
        let exactCampaign = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Campaign"), object: input)
        XCTAssertEqual(XCTWaiter.wait(for: [exactCampaign], timeout: 10), .completed)
        waitUntilEnabled(app.buttons["confirmProjectName"])
        app.buttons["confirmProjectName"].tap()
        XCTAssertTrue(app.buttons["Options for Campaign"].waitForExistence(timeout: 10))
        app.buttons["Open Editorial"].tap()
        // Resolve identity and the required state in one AX query. Resolving
        // exists and then label separately exhausted the prior wait budget.
        let selected = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ AND label == %@",
                                  "activeProjectRow", "Current project: Editorial")).firstMatch
        let selectedInTime = selected.waitForExistence(timeout: 10)
        if !selectedInTime {
            let details: String
            do {
                let snapshot = try activeRow.snapshot()
                details = "Expected: Current project: Editorial\nActual: \(snapshot.label)\n" +
                    "identifier: \(snapshot.identifier), selected: \(snapshot.isSelected), frame: \(snapshot.frame)"
            } catch {
                details = "Expected: Current project: Editorial\nSnapshot error: \(error.localizedDescription)"
            }
            let diagnostic = XCTAttachment(string: String(details.prefix(4_096)))
            diagnostic.name = "Active-project-switch-failure"
            diagnostic.lifetime = .keepAlways
            add(diagnostic)
            let screen = XCTAttachment(screenshot: app.screenshot())
            screen.name = "Active-project-switch-failure-screen"
            screen.lifetime = .keepAlways
            add(screen)
        }
        XCTAssertTrue(selectedInTime, "The library must identify Editorial as its current project")
        XCTAssertFalse(app.buttons["Open Editorial"].exists)
        waitUntilEnabled(app.buttons["Options for Editorial"])
        app.buttons["Done"].tap()
        waitForTitle("Editorial", in: app)
        app.terminate()
        launchStudio(app)
        waitForTitle("Editorial", in: app)
        waitUntilEnabled(projects)
        projects.tap()
        let campaign = app.buttons["Options for Campaign"]
        waitUntilEnabled(campaign)
        campaign.tap()
        app.buttons["Archive"].tap()
        let restore = app.buttons["Restore Campaign"]
        waitUntilEnabled(restore)
        restore.tap()
        waitUntilEnabled(campaign)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Project-library"; attachment.lifetime = .keepAlways; self.add(attachment)
    }

    func testArchivedDeleteRequiresConfirmationAndPersistsOnlyThatRemoval() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        launchStudio(app)
        let projects = app.buttons["openProjectLibrary"]
        waitUntilEnabled(projects)
        waitUntilEnabled(app.buttons["saveProject"])
        app.buttons["saveProject"].tap()
        waitUntilEnabled(projects)
        projects.tap()
        let create = app.buttons["newProject"]
        waitUntilEnabled(create)
        create.tap()
        let input = app.textFields["projectNameInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        app.buttons["clearProjectName"].tap()
        input.tap()
        dismissKeyboardTypingIntroduction(in: app)
        input.typeText("Keep")
        let exactKeep = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Keep"), object: input)
        let enteredKeep = XCTWaiter.wait(for: [exactKeep], timeout: 10)
        if enteredKeep != .completed {
            // The failed run retained only an empty, focused text field.
            // Keep the original failure and capture keyboard/presentation state.
            let description = "Requested project name: Keep\n" +
                "Requested element:\n\(String(input.debugDescription.prefix(8_000)))\n" +
                "Application hierarchy:\n\(String(app.debugDescription.prefix(24_000)))"
            let state = XCTAttachment(string: description)
            state.name = "Project-name-entry-failure"
            state.lifetime = .keepAlways
            add(state)
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Project-name-entry-failure-screen"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertEqual(enteredKeep, .completed)
        waitUntilEnabled(app.buttons["confirmProjectName"])
        app.buttons["confirmProjectName"].tap()
        let original = app.buttons["Options for Portrait setup"]
        waitUntilEnabled(original)
        original.tap()
        app.buttons["Archive"].tap()
        let remove = app.buttons["Delete archived Portrait setup"]
        let restore = app.buttons["Restore Portrait setup"]
        waitUntilEnabled(remove)
        remove.tap()
        let alert = app.alerts["Delete archived project?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Cancel"].tap()
        waitUntilEnabled(restore)
        remove.tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Delete project"].tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: restore)], timeout: 10), .completed)
        app.buttons["Done"].tap()
        waitForTitle("Keep", in: app)
        app.terminate()
        launchStudio(app)
        waitForTitle("Keep", in: app)
        waitUntilEnabled(projects)
        projects.tap()
        XCTAssertTrue(app.buttons["Options for Keep"].waitForExistence(timeout: 10))
        XCTAssertFalse(original.exists)
        XCTAssertFalse(restore.exists)
        XCTAssertFalse(remove.exists)
    }

    private func conflictingEditor() throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["KEYFILL_UI_TEST_CONFLICT"] = "1"
        launchStudio(app)
        let save = app.buttons["saveProject"]
        waitUntilEnabled(save)
        save.tap()
        let recipes = app.buttons["recipes"]
        waitUntilEnabled(recipes)
        recipes.tap()
        app.buttons["recipe-Silhouette"].tap()
        save.tap()
        let copy = app.buttons["saveConflictCopy"]
        revealStudioContent(copy, in: app, towardBottom: false)
        waitUntilEnabled(copy)
        return app
    }

    func testStaleSaveRecoveryPreservesBothProjectsAcrossRelaunch() throws {
        continueAfterFailure = false
        let app = try conflictingEditor()
        let copy = app.buttons["saveConflictCopy"]
        let reload = app.buttons["reloadConflict"]
        revealStudioContent(reload, in: app)
        reload.tap()
        let alert = app.alerts["Reload saved project?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Keep editing"].tap()
        XCTAssertTrue(copy.exists)
        revealStudioContent(copy, in: app, towardBottom: false)
        copy.tap()
        waitForTitle("Portrait setup recovery", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "KEYFILL_UI_TEST_CONFLICT")
        launchStudio(app)
        waitForTitle("Portrait setup recovery", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        let backlight = app.buttons["light-Backlight"]
        revealStudioContent(backlight, in: app)
        XCTAssertTrue(backlight.exists)
        XCTAssertFalse(app.buttons["light-Key"].exists)
        let projects = app.buttons["openProjectLibrary"]
        revealStudioContent(projects, in: app, towardBottom: false)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally",
                       "Scrolling to Projects must preserve the saved lighting setup")
        projects.tap()
        let original = app.buttons["Open Other window"]
        waitUntilEnabled(original)
        original.tap()
        app.buttons["Done"].tap()
        waitForTitle("Other window", in: app)
        let key = app.buttons["light-Key"]
        revealStudioContent(key, in: app)
        XCTAssertTrue(key.exists)
        XCTAssertFalse(app.buttons["light-Backlight"].exists)
    }

    func testStaleSaveReloadRequiresConfirmation() throws {
        continueAfterFailure = false
        let app = try conflictingEditor()
        let reload = app.buttons["reloadConflict"]
        revealStudioContent(reload, in: app)
        reload.tap()
        let alert = app.alerts["Reload saved project?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Reload and discard edits"].tap()
        waitForTitle("Other window", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        XCTAssertFalse(app.buttons["saveConflictCopy"].exists)
        let key = app.buttons["light-Key"]
        revealStudioContent(key, in: app)
        XCTAssertTrue(key.exists)
        XCTAssertFalse(app.buttons["light-Backlight"].exists)
    }

    func testFullLibraryRecoveryRequiresConfirmationAndPersistsEditedSetup() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["KEYFILL_UI_TEST_CONFLICT"] = "1"
        app.launchEnvironment["KEYFILL_UI_TEST_FULL_LIBRARY"] = "1"
        launchStudio(app)
        waitForTitle("Portrait setup", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")

        let addLight = app.buttons["addLightShortcut"]
        revealStudioContent(addLight, in: app, towardBottom: false)
        addLight.tap()
        let newLight = app.buttons["light-Light 1"]
        XCTAssertTrue(newLight.waitForExistence(timeout: 15), "The unsaved setup must actually contain the new light")
        app.buttons["saveProject"].tap()
        let copy = app.buttons["saveConflictCopy"]
        revealStudioContent(copy, in: app, towardBottom: false)
        waitUntilEnabled(copy)
        copy.tap()

        let candidate = app.buttons["Replace archived Archived setup"]
        XCTAssertTrue(candidate.waitForExistence(timeout: 15), "A full library must offer explicit archived-record recovery")
        candidate.tap()
        let confirmation = app.alerts["Replace archived project?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        confirmation.buttons["Cancel"].tap()
        XCTAssertTrue(candidate.exists, "Cancel must keep the archived choice available")
        app.buttons["cancelRecoveryReplacement"].tap()
        waitForTitle("Portrait setup", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
        XCTAssertTrue(newLight.exists, "Cancelling recovery must preserve the editor's new light")

        revealStudioContent(copy, in: app, towardBottom: false)
        copy.tap()
        XCTAssertTrue(candidate.waitForExistence(timeout: 15), "Reopening must still find the untouched archive")
        candidate.tap()
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        let replacementActions = confirmation.buttons.matching(NSPredicate(format: "label == %@", "Replace and save setup"))
        let replacementCount = replacementActions.count
        if replacementCount != 1 {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Recovery-confirmation-hierarchy"; hierarchy.lifetime = .keepAlways; self.add(hierarchy)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Recovery-confirmation"; screenshot.lifetime = .keepAlways; self.add(screenshot)
        }
        XCTAssertEqual(replacementCount, 1, "The destructive recovery action must expose exactly one button in its alert")
        let replaceAction = replacementActions.element
        waitUntilEnabled(replaceAction)
        replaceAction.tap()
        waitForTitle("Portrait setup recovery", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        XCTAssertFalse(copy.exists)
        XCTAssertTrue(newLight.exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "light-")).count, 4)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Full-library-recovery"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "KEYFILL_UI_TEST_CONFLICT")
        // Deliberately leave FULL_LIBRARY enabled: initialization must not
        // replace the existing recovery library during the next launch.
        launchStudio(app)
        waitForTitle("Portrait setup recovery", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        XCTAssertTrue(newLight.waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "light-")).count, 4)
        XCTAssertFalse(copy.exists)
    }

    func testUnsavedSetupMustBeSavedBeforeLibraryChanges() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        launchStudio(app)
        let projects = app.buttons["openProjectLibrary"]
        waitUntilEnabled(projects)
        projects.tap()
        XCTAssertTrue(app.buttons["librarySaveCurrent"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["newProject"].isEnabled)
        app.buttons["librarySaveCurrent"].tap()
        let create = app.buttons["newProject"]
        waitUntilEnabled(create)
        // The first save replaces draft identity while Projects stays open.
        // Its next command must use the refreshed owner, not a stale callback.
        create.tap()
        let name = app.textFields["projectNameInput"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        app.buttons["clearProjectName"].tap()
        name.tap()
        dismissKeyboardTypingIntroduction(in: app)
        name.typeText("After first save")
        waitUntilEnabled(app.buttons["confirmProjectName"])
        app.buttons["confirmProjectName"].tap()
        waitUntilEnabled(app.buttons["Options for After first save"])
        app.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        waitForTitle("After first save", in: app)
    }

    func testLargeValidLibraryCanLoadSaveBrowseAndRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["KEYFILL_UI_TEST_LARGE_LIBRARY"] = "1"
        launchStudio(app)
        let save = app.buttons["saveProject"]
        waitUntilEnabled(save)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        let add = app.buttons["addLightShortcut"]
        revealStudioContent(add, in: app, towardBottom: false)
        add.tap()
        let light = app.buttons["light-Light 1"]
        XCTAssertTrue(light.waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
        save.tap()
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Saved locally"),
                                              object: app.staticTexts["projectStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 15), .completed)
        waitUntilEnabled(save)
        let projects = app.buttons["openProjectLibrary"]
        revealStudioContent(projects, in: app, towardBottom: false)
        waitUntilEnabled(projects)
        projects.tap()
        waitUntilEnabled(app.buttons["newProject"])
        app.buttons["Done"].tap()
        XCTAssertTrue(light.exists)
        app.terminate()
        // Keep the fixture flag enabled: a new actor must not recreate or
        // overwrite the existing large library during relaunch.
        launchStudio(app)
        waitUntilEnabled(save)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        XCTAssertTrue(light.waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "light-")).count, 4)
    }
}
