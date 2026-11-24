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
        XCTAssertFalse(app.staticTexts["guidedObservedCues"].exists)
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
            revealStudioContent(element, in: app, towardBottom: up)
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
        second.tap()
        let observed = app.staticTexts["guidedObservedCues"]
        reveal(observed)
        XCTAssertEqual(observed.label, "Your observations — Key side: Image left")
        let assumed = app.staticTexts["guidedAssumedCues"]
        reveal(assumed)
        XCTAssertEqual(assumed.label, "Assumed cues — Shadow edges, Shadow fill, Rim highlight")
        let startingValues = app.staticTexts["guidedStartingValues"]
        reveal(startingValues)
        let fartherValues = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "2.25 m key distance"), object: startingValues)
        XCTAssertEqual(XCTWaiter.wait(for: [fartherValues], timeout: 5), .completed)
        XCTAssertTrue(second.isSelected)
        XCTAssertTrue(startingValues.label.contains("400 lx key"))
        XCTAssertTrue(startingValues.label.contains("5600 K"))
        // A nested comparison must preserve the parent's manual observations and rig.
        let testShot = app.buttons["openPhotoComparison"]
        reveal(testShot, up: false)
        testShot.tap()
        let closeTestShot = app.buttons["closePhotoComparison"]
        XCTAssertTrue(closeTestShot.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["chooseComparisonReference"].exists)
        XCTAssertTrue(app.buttons["chooseComparisonTestShot"].exists)
        closeTestShot.tap()
        XCTAssertTrue(app.buttons["closeReference"].waitForExistence(timeout: 10))
        reveal(second)
        XCTAssertTrue(second.isSelected)
        reveal(observed)
        XCTAssertEqual(observed.label, "Your observations — Key side: Image left")
        reveal(startingValues)
        XCTAssertTrue(startingValues.label.contains("2.25 m key distance"))
        XCTAssertTrue(startingValues.label.contains("400 lx key"))
        XCTAssertTrue(startingValues.label.contains("5600 K"))
        reveal(first, up: false)
        first.tap()
        reveal(startingValues)
        let closerValues = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "1.5 m key distance"), object: startingValues)
        XCTAssertEqual(XCTWaiter.wait(for: [closerValues], timeout: 5), .completed)
        XCTAssertTrue(first.isSelected)
        XCTAssertFalse(startingValues.label.contains("2.25 m key distance"))
        let basisShot = XCTAttachment(screenshot: app.screenshot())
        basisShot.name = "Reference-guided-basis"
        basisShot.lifetime = .keepAlways
        self.add(basisShot)
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
        XCTAssertTrue(undo.exists && undo.isHittable)
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertFalse(undo.isEnabled)
        XCTAssertTrue(app.buttons["redo"].isEnabled)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
    }
}
