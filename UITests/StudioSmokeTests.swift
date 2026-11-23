import XCTest

final class StudioSmokeTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testRecipeEditSaveAndReopen() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["recipes"].waitForExistence(timeout: 15))
        app.buttons["recipes"].tap()
        app.buttons["recipe-Silhouette"].tap()
        let add = app.buttons["addLight"]
        if !add.isHittable { app.swipeUp() }
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        let row = app.buttons["light-Light 1"]
        if !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.buttons["saveProject"].tap()
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["Saved locally"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-plan"; attachment.lifetime = .keepAlways; addAttachment(attachment)
        app.terminate()
        app.launch()
        if !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["light-Backlight"].exists)
    }
}
