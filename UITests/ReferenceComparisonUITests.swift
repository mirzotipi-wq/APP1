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

    func testGuidedRigAbstainsThenAppliesAndUndoesWithoutSaving() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let open = app.buttons["openReference"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: open)], timeout: 15), .completed)
        open.tap()
        let build = app.buttons["buildReferenceRigs"]
        func reveal(_ element: XCUIElement, up: Bool = true) {
            for _ in 0..<8 where !element.isHittable {
                if up { app.swipeUp() } else { app.swipeDown() }
            }
            XCTAssertTrue(element.isHittable)
        }
        reveal(build)
        build.tap()
        XCTAssertTrue(app.staticTexts["guidedRigError"].waitForExistence(timeout: 5))
        let direction = app.buttons["referenceKeySide"]
        reveal(direction, up: false)
        direction.tap()
        app.buttons["Image left"].tap()
        reveal(build)
        build.tap()
        let first = app.buttons["guidedRig-near"]
        reveal(first)
        XCTAssertTrue(first.exists)
        let second = app.buttons["guidedRig-far"]
        reveal(second)
        XCTAssertTrue(second.exists)
        first.tap()
        let apply = app.buttons["applyReferenceRig"]
        reveal(apply)
        apply.tap()
        let confirmation = app.alerts["Replace the current lights?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        let confirm = confirmation.buttons["Apply rig"]
        XCTAssertTrue(confirm.isHittable)
        confirm.tap()
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        let undo = app.buttons["undo"]
        reveal(undo, up: false)
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertFalse(undo.isEnabled)
        XCTAssertTrue(app.buttons["redo"].isEnabled)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
    }
}
