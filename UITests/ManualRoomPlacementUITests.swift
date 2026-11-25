import XCTest

final class ManualRoomPlacementUITests: XCTestCase {
    func testManualRoomReportsOutOfBoundsAndRecordsRoomEdit() throws {
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
        let rotateFrame = rotate.frame
        assertStudioMinimumHitTarget(rotateFrame, label: "Rotate 180 degrees")
        let rotationFrame = app.sliders["roomRotation"].frame
        assertStudioMinimumHitTarget(rotationFrame, label: "Room rotation")
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
        revealStudioContent(project, in: app, towardBottom: false)
        XCTAssertEqual(project.label, "Unsaved changes")
        XCTAssertTrue(app.buttons["undo"].exists)
        XCTAssertTrue(app.buttons["undo"].isEnabled, "Committed room changes must be undoable")
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
        // Captures identify an Other; redundant existence snapshots exhausted
        // the status wait after notes dismissal before its label was read.
        let status = app.otherElements["roomPlacementStatus"]
        func expect(_ text: String) {
            let predicate = NSPredicate(format: "label CONTAINS %@", text)
            let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: status)], timeout: 15)
            if result != .completed { recordRoomFailure(in: app) }
            XCTAssertEqual(result, .completed)
        }
        func openNotes(containing text: String) -> XCUIElement {
            let review = app.buttons["reviewRoomNotes"]
            revealStudioContent(review, in: app, towardBottom: false)
            review.tap()
            XCTAssertTrue(app.buttons["closeRoomNotes"].waitForExistence(timeout: 10))
            // Failure captures identify this as StaticText with the full notes
            // label. Query that content once per poll; separate existence and
            // label requests consumed the deadline before diagnostics read it.
            let notes = app.staticTexts["roomNotesText"]
            let predicate = NSPredicate(format: "label CONTAINS %@", text)
            let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: notes)], timeout: 10)
            recordRoomNotesAccessibility(notes, in: app, includeFailure: result != .completed)
            XCTAssertEqual(result, .completed)
            XCTAssertTrue(app.buttons["shareRoomNotes"].exists)
            XCTAssertTrue(app.buttons["shareRoomNotes"].isEnabled)
            return notes
        }
        setRoomMeasurement("2", id: "roomWidth", in: app)
        let error = app.descendants(matching: .any)["roomWidthError"].firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.label.contains("Current value is 6 m"))
        XCTAssertEqual(subject.value as? String, "3", "The rejected resize must not relocate the subject")
        expect("All 5 center positions inside room")
        // The review must use committed width 6, not the rejected width 2 draft.
        let originalNotes = openNotes(containing: "Room width: 6.00 m")
        XCTAssertFalse(originalNotes.label.contains("Room width: 2.00 m"))
        app.buttons["closeRoomNotes"].tap()
        XCTAssertTrue(app.buttons["closeRoomPlacement"].waitForExistence(timeout: 10))
        XCTAssertEqual(subject.value as? String, "3")
        expect("All 5 center positions inside room")
        // Restore the committed value using the visible recovery action.
        let reset = app.buttons["roomWidthReset"]
        revealStudioContent(reset, in: app)
        reset.tap()
        XCTAssertEqual(width.value as? String, "6")
        XCTAssertFalse(error.exists)
        setRoomMeasurement("1.4999", id: "roomSubjectX", in: app)
        XCTAssertEqual(subject.value as? String, "1.4999")
        expect("1 of 5 center positions outside room")
        setRoomMeasurement("2", id: "roomWidth", in: app)
        XCTAssertEqual(width.value as? String, "2")
        XCTAssertEqual(subject.value as? String, "1.4999")
        expect("3 of 5 center positions outside room")
        let signed = app.staticTexts["X from left wall: -0.0001 m"]
        XCTAssertTrue(signed.waitForExistence(timeout: 10))
        revealStudioContent(signed, in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Room-precise-signed-coordinate"; attachment.lifetime = .keepAlways; add(attachment)
        let currentNotes = openNotes(containing: "Room width: 2.00 m")
        XCTAssertTrue(currentNotes.label.contains("X from left wall: -0.0001 m"))
        XCTAssertFalse(currentNotes.label.contains("Room width: 6.00 m"))
        let notesAttachment = XCTAttachment(screenshot: app.screenshot())
        notesAttachment.name = "Room-measurement-notes"; notesAttachment.lifetime = .keepAlways; add(notesAttachment)
        app.buttons["closeRoomNotes"].tap()
        XCTAssertTrue(app.buttons["closeRoomPlacement"].waitForExistence(timeout: 10))
        XCTAssertEqual(width.value as? String, "2")
        XCTAssertEqual(subject.value as? String, "1.4999")
        expect("3 of 5 center positions outside room")
        app.buttons["closeRoomPlacement"].tap()
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
        XCTAssertTrue(app.buttons["undo"].isEnabled, "Committed room changes must be undoable")
        app.buttons["saveProject"].tap()
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Saved locally"),
                                             object: app.staticTexts["projectStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 15), .completed)
        app.terminate()
        app.launch()
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()
        XCTAssertTrue(app.buttons["closeRoomPlacement"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.textFields["roomWidth"].value as? String, "2")
        XCTAssertEqual(app.textFields["roomSubjectX"].value as? String, "1.4999")
    }

    private func recordRoomNotesAccessibility(_ notes: XCUIElement, in app: XCUIApplication,
                                               includeFailure: Bool) {
        let details = notes.exists
            ? "Type: \(notes.elementType)\nLabel: \(notes.label)\nValue: \(String(describing: notes.value))\nFrame: \(notes.frame)"
            : "roomNotesText does not exist"
        // A cancelled test run may never finalize its xcresult attachments.
        // Retain the actual observed accessibility content in the raw log too.
        print("Room-notes-accessibility-details:\n\(details)")
        let content = XCTAttachment(string: details)
        content.name = "Room-notes-accessibility-details"; content.lifetime = .keepAlways; add(content)
        if includeFailure {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Room-notes-content-failure"; screenshot.lifetime = .keepAlways; add(screenshot)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Room-notes-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        }
    }

    private func recordRoomFailure(in app: XCUIApplication) {
        let matches = app.descendants(matching: .any).matching(identifier: "roomPlacementStatus")
        let count = matches.count
        print("Room-status-accessibility-match-count: \(count)")
        for index in 0..<min(count, 4) {
            let status = matches.element(boundBy: index)
            print("Room-status-accessibility[\(index)]: type=\(status.elementType), label=\(String(reflecting: status.label)), value=\(String(describing: status.value)), frame=\(status.frame)")
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Room-status-failure"; screenshot.lifetime = .keepAlways; add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Room-status-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
    }
}
