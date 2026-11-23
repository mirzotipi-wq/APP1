import XCTest

final class ReferenceComparisonUITests: XCTestCase {
    func testReferenceComparisonOpensWithRealStudyAndNoPhoto() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let compare = app.buttons["openReference"]
        XCTAssertTrue(compare.waitForExistence(timeout: 15))
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: compare)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 15), .completed)
        compare.tap()
        XCTAssertTrue(app.buttons["chooseReference"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["No reference selected"].exists)
        XCTAssertTrue(app.images["studyPreview"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.images["importedReference"].exists)
        XCTAssertFalse(app.buttons["removeReference"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Reference-comparison-empty"
        shot.lifetime = .keepAlways
        self.add(shot)
        app.buttons["closeReference"].tap()
        XCTAssertTrue(compare.waitForExistence(timeout: 10))
        compare.tap()
        XCTAssertTrue(app.buttons["chooseReference"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.images["importedReference"].exists)
    }
}
