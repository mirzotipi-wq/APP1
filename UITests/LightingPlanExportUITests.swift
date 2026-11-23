import Foundation
import XCTest

final class LightingPlanExportUITests: XCTestCase {
    func testExportPreviewOpensWithoutSavingOrChangingScene() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let export = app.buttons["exportLightingPlan"]
        XCTAssertTrue(export.waitForExistence(timeout: 15))
        export.tap()
        let prepare = app.buttons["prepareLightingPlanPDF"]
        if prepare.waitForExistence(timeout: 5) { prepare.tap() }
        else { app.buttons["Lighting plan (PDF)"].tap() }
        let pages = app.staticTexts["lightingPlanPDFPages"]
        XCTAssertTrue(pages.waitForExistence(timeout: 15))
        XCTAssertTrue(pages.label.contains("2 pages"))
        XCTAssertTrue(app.buttons["shareLightingPlanPDF"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Lighting-plan-preview"; attachment.lifetime = .keepAlways; add(attachment)
        app.buttons["Done"].tap()
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
    }
}
