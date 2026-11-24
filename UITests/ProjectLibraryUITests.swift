import XCTest

final class ProjectLibraryUITests: XCTestCase {
    private func waitUntilEnabled(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == true AND enabled == true")
        let ready = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed, file: file, line: line)
    }

    private func waitForTitle(_ title: String, in app: XCUIApplication) {
        let predicate = NSPredicate(format: "exists == true AND label == %@", title)
        let ready = XCTNSPredicateExpectation(predicate: predicate, object: app.staticTexts["projectName"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
    }

    func testCreateDuplicateRenameSwitchAndRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let projects = app.buttons["openProjectLibrary"]
        waitUntilEnabled(projects)
        waitUntilEnabled(app.buttons["saveProject"])
        app.buttons["saveProject"].tap()
        projects.tap()
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
        input.typeText("Editorial")
        let exactEditorial = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Editorial"), object: input)
        XCTAssertEqual(XCTWaiter.wait(for: [exactEditorial], timeout: 10), .completed)
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
        input.typeText("Campaign")
        let exactCampaign = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Campaign"), object: input)
        XCTAssertEqual(XCTWaiter.wait(for: [exactCampaign], timeout: 10), .completed)
        waitUntilEnabled(app.buttons["confirmProjectName"])
        app.buttons["confirmProjectName"].tap()
        XCTAssertTrue(app.buttons["Options for Campaign"].waitForExistence(timeout: 10))
        app.buttons["Open Editorial"].tap()
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label == %@", "Current project: Editorial"), object: activeRow)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 10), .completed)
        XCTAssertFalse(app.buttons["Open Editorial"].exists)
        waitUntilEnabled(app.buttons["Options for Editorial"])
        app.buttons["Done"].tap()
        waitForTitle("Editorial", in: app)
        app.terminate()
        app.launch()
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
        app.launch()
        let projects = app.buttons["openProjectLibrary"]
        waitUntilEnabled(projects)
        waitUntilEnabled(app.buttons["saveProject"])
        app.buttons["saveProject"].tap()
        projects.tap()
        let create = app.buttons["newProject"]
        waitUntilEnabled(create)
        create.tap()
        let input = app.textFields["projectNameInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        app.buttons["clearProjectName"].tap()
        input.tap()
        input.typeText("Keep")
        let exactKeep = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Keep"), object: input)
        XCTAssertEqual(XCTWaiter.wait(for: [exactKeep], timeout: 10), .completed)
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
        app.launch()
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
        app.launch()
        let save = app.buttons["saveProject"]
        waitUntilEnabled(save)
        save.tap()
        let recipes = app.buttons["recipes"]
        waitUntilEnabled(recipes)
        recipes.tap()
        app.buttons["recipe-Silhouette"].tap()
        save.tap()
        let copy = app.buttons["saveConflictCopy"]
        for _ in 0..<8 where !copy.isHittable { app.swipeDown() }
        waitUntilEnabled(copy)
        return app
    }

    func testStaleSaveRecoveryPreservesBothProjectsAcrossRelaunch() throws {
        continueAfterFailure = false
        let app = try conflictingEditor()
        let copy = app.buttons["saveConflictCopy"]
        let reload = app.buttons["reloadConflict"]
        if !reload.isHittable { app.swipeUp() }
        reload.tap()
        let alert = app.alerts["Reload saved project?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Keep editing"].tap()
        XCTAssertTrue(copy.exists)
        if !copy.isHittable { app.swipeDown() }
        copy.tap()
        waitForTitle("Portrait setup recovery", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "KEYFILL_UI_TEST_CONFLICT")
        app.launch()
        waitForTitle("Portrait setup recovery", in: app)
        let backlight = app.buttons["light-Backlight"]
        for _ in 0..<8 where !backlight.isHittable { app.swipeUp() }
        XCTAssertTrue(backlight.exists)
        XCTAssertFalse(app.buttons["light-Key"].exists)
        let projects = app.buttons["openProjectLibrary"]
        for _ in 0..<8 where !projects.isHittable { app.swipeDown() }
        projects.tap()
        let original = app.buttons["Open Other window"]
        waitUntilEnabled(original)
        original.tap()
        app.buttons["Done"].tap()
        waitForTitle("Other window", in: app)
        let key = app.buttons["light-Key"]
        for _ in 0..<8 where !key.isHittable { app.swipeUp() }
        XCTAssertTrue(key.exists)
        XCTAssertFalse(app.buttons["light-Backlight"].exists)
    }

    func testStaleSaveReloadRequiresConfirmation() throws {
        continueAfterFailure = false
        let app = try conflictingEditor()
        let reload = app.buttons["reloadConflict"]
        for _ in 0..<4 where !reload.isHittable { app.swipeUp() }
        reload.tap()
        let alert = app.alerts["Reload saved project?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Reload and discard edits"].tap()
        waitForTitle("Other window", in: app)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
        XCTAssertFalse(app.buttons["saveConflictCopy"].exists)
        let key = app.buttons["light-Key"]
        for _ in 0..<8 where !key.isHittable { app.swipeUp() }
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
        app.launch()
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
        app.launch()
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
        app.launch()
        let projects = app.buttons["openProjectLibrary"]
        waitUntilEnabled(projects)
        projects.tap()
        XCTAssertTrue(app.buttons["librarySaveCurrent"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["newProject"].isEnabled)
        app.buttons["librarySaveCurrent"].tap()
        let create = app.buttons["newProject"]
        waitUntilEnabled(create)
        app.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
    }
}
