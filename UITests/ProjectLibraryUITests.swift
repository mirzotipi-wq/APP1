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
        let create = app.buttons["newProject"]
        waitUntilEnabled(create)
        create.tap()
        let input = app.textFields["projectNameInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        app.buttons["clearProjectName"].tap()
        input.tap()
        input.typeText("Editorial")
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
        app.buttons["confirmProjectName"].tap()
        XCTAssertTrue(app.buttons["Options for Campaign"].waitForExistence(timeout: 10))
        app.buttons["Open Editorial"].tap()
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
