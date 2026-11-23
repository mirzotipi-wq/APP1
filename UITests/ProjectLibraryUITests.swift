import XCTest

final class ProjectLibraryUITests: XCTestCase {
    func testCreateDuplicateRenameSwitchAndRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let projects = app.buttons["openProjectLibrary"]
        XCTAssertTrue(projects.waitForExistence(timeout: 15))
        app.buttons["saveProject"].tap()
        projects.tap()
        let create = app.buttons["newProject"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        create.tap()
        let input = app.textFields["projectNameInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        if let value = input.value as? String {
            input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
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
        input.tap()
        if let value = input.value as? String {
            input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        input.typeText("Campaign")
        app.buttons["confirmProjectName"].tap()
        XCTAssertTrue(app.buttons["Options for Campaign"].waitForExistence(timeout: 10))
        app.buttons["Open Editorial"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["projectName"].label, "Editorial")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["projectName"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["projectName"].label, "Editorial")
        projects.tap()
        XCTAssertTrue(app.buttons["Options for Campaign"].waitForExistence(timeout: 10))
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
        XCTAssertTrue(projects.waitForExistence(timeout: 15))
        projects.tap()
        XCTAssertTrue(app.buttons["librarySaveCurrent"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["newProject"].isEnabled)
        app.buttons["librarySaveCurrent"].tap()
        let create = app.buttons["newProject"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: create)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        app.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Saved locally")
    }
}
