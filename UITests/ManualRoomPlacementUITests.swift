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
        let primaryViewport = app.frame.insetBy(dx: 0, dy: 100)
        XCTAssertTrue(open.isHittable && primaryViewport.contains(CGPoint(x: open.frame.midX, y: open.frame.midY)),
                      "Room placement must be a primary visible workflow action without scrolling")
        open.tap()
        XCTAssertTrue(app.buttons["closeRoomPlacement"].waitForExistence(timeout: 15), "Room sheet must actually open")
        let status = app.descendants(matching: .any)["roomPlacementStatus"].firstMatch
        let allInside = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label CONTAINS %@", "All 5 center positions inside room"), object: status)
        let insideResult = XCTWaiter.wait(for: [allInside], timeout: 15)
        if insideResult != .completed { recordRoomFailure(in: app) }
        XCTAssertEqual(insideResult, .completed)
        let rotate = app.buttons["roomHalfTurn"]
        revealStudioContent(rotate, in: app)
        rotate.tap()
        let outside = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "center positions outside room"), object: status)
        let outsideResult = XCTWaiter.wait(for: [outside], timeout: 10)
        if outsideResult != .completed { recordRoomFailure(in: app) }
        XCTAssertEqual(outsideResult, .completed)
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

    func testRoomResizeRequiresExplicitSubjectMoveAndPreservesSignedCoordinates() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let open = app.buttons["openRoomPlacement"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()
        XCTAssertTrue(app.buttons["closeRoomPlacement"].waitForExistence(timeout: 15))
        let width = app.textFields["roomWidth"]
        let subject = app.textFields["roomSubjectX"]
        let status = app.descendants(matching: .any)["roomPlacementStatus"].firstMatch
        func enter(_ text: String, in field: XCUIElement, button: String) {
            revealStudioContent(field, in: app)
            field.tap()
            if let old = field.value as? String {
                field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count))
            }
            field.typeText(text)
            app.buttons[button].tap()
        }
        func expect(_ text: String) {
            let predicate = NSPredicate(format: "exists == true AND label CONTAINS %@", text)
            let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: status)], timeout: 15)
            if result != .completed { recordRoomFailure(in: app) }
            XCTAssertEqual(result, .completed)
        }
        enter("2", in: width, button: "roomWidthSet")
        XCTAssertTrue(app.descendants(matching: .any)["roomWidthError"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(subject.value as? String, "3", "The rejected resize must not relocate the subject")
        expect("All 5 center positions inside room")
        // Restore a valid draft to dismiss the keyboard, then move explicitly.
        enter("6", in: width, button: "roomWidthSet")
        enter("1.4999", in: subject, button: "roomSubjectXSet")
        XCTAssertEqual(subject.value as? String, "1.4999")
        expect("1 of 5 center positions outside room")
        enter("2", in: width, button: "roomWidthSet")
        XCTAssertEqual(subject.value as? String, "1.4999")
        expect("3 of 5 center positions outside room")
        let signed = app.staticTexts["X from left wall: -0.0001 m"]
        XCTAssertTrue(signed.waitForExistence(timeout: 10))
        revealStudioContent(signed, in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Room-precise-signed-coordinate"; attachment.lifetime = .keepAlways; add(attachment)
        app.buttons["closeRoomPlacement"].tap()
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
        XCTAssertFalse(app.buttons["undo"].isEnabled)
    }

    private func recordRoomFailure(in app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Room-status-failure"; screenshot.lifetime = .keepAlways; add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Room-status-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
    }
}
