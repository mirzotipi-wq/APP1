import XCTest

final class ManualRoomPlacementUITests: XCTestCase {
    func testManualRoomReportsOutOfBoundsWithoutChangingStudio() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let open = app.buttons["openRoomPlacement"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        for _ in 0..<8 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.isHittable)
        open.tap()
        let status = app.descendants(matching: .any)["roomPlacementStatus"].firstMatch
        let allInside = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label CONTAINS %@", "All 5 center positions inside room"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [allInside], timeout: 15), .completed)
        let rotate = app.buttons["roomHalfTurn"]
        for _ in 0..<8 where !rotate.isHittable { app.swipeUp() }
        XCTAssertTrue(rotate.isHittable)
        rotate.tap()
        let outside = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "center positions outside room"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [outside], timeout: 10), .completed)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Manual-room-placement"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["closeRoomPlacement"].tap()
        let project = app.staticTexts["projectStatus"]
        for _ in 0..<8 where !project.isHittable { app.swipeDown() }
        XCTAssertEqual(project.label, "Unsaved changes")
        XCTAssertTrue(app.buttons["undo"].exists)
        XCTAssertFalse(app.buttons["undo"].isEnabled)
    }
}
