import XCTest

final class StudioSmokeTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func makeApp(corrupt: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        if corrupt { app.launchEnvironment["KEYFILL_UI_TEST_CORRUPT"] = "1" }
        return app
    }

    private func assertStatus(_ value: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let status = app.staticTexts["projectStatus"]
        let predicate = NSPredicate(format: "exists == true AND label == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed, file: file, line: line)
    }

    func testRecipeEditSaveAndReopen() throws {
        let app = makeApp()
        app.launch()
        XCTAssertTrue(app.buttons["recipes"].waitForExistence(timeout: 15))
        assertStatus("Unsaved changes", in: app)
        app.buttons["recipes"].tap()
        app.buttons["recipe-Silhouette"].tap()
        let add = app.buttons["addLight"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        if !add.isHittable { app.swipeUp() }
        add.tap()
        let row = app.buttons["light-Light 1"]
        if !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.buttons["saveProject"].tap()
        app.swipeDown()
        assertStatus("Saved locally", in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-plan"; attachment.lifetime = .keepAlways; addAttachment(attachment)
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        if !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["light-Backlight"].exists)
        XCTAssertFalse(app.buttons["light-Key"].exists)
    }

    func testCorruptProjectBlocksSavingAcrossRelaunch() throws {
        let app = makeApp(corrupt: true)
        app.launch()
        assertStatus("Saved data protected", in: app)
        XCTAssertFalse(app.buttons["saveProject"].isEnabled)
        app.terminate()
        // Prove the protected state persists without recreating the corrupt fixture.
        app.launchEnvironment.removeValue(forKey: "KEYFILL_UI_TEST_CORRUPT")
        app.launch()
        assertStatus("Saved data protected", in: app)
        XCTAssertFalse(app.buttons["saveProject"].isEnabled)
    }
}
