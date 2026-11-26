import XCTest

final class PrecisionEditingUITests: XCTestCase {
    private func reveal(_ target: XCUIElement, in app: XCUIApplication, towardBottom: Bool = true) {
        revealStudioContent(target, in: app, towardBottom: towardBottom)
    }

    private func replaceText(_ field: XCUIElement, with text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        if let current = field.value as? String {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }

    private func expectValue(_ element: XCUIElement, equals value: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND value == %@", value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed,
                       "The slider's spoken current value must preserve the exact edit", file: file, line: line)
    }

    func testExactLightIntensityValidationUndoRedoAndReopen() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["recipes"].waitForExistence(timeout: 15))
        let exact = app.buttons["lightIntensityExact"]
        reveal(exact, in: app)
        XCTAssertEqual(exact.value as? String, "900 cd")
        exact.tap()
        let field = app.textFields["precisionValue"]
        let apply = app.buttons["precisionApply"]
        replaceText(field, with: "100001")
        apply.tap()
        XCTAssertTrue(app.descendants(matching: .any)["precisionError"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["precisionCancel"].tap()
        XCTAssertEqual(exact.value as? String, "900 cd")
        exact.tap()
        replaceText(field, with: "4321.5")
        apply.tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND value == %@", "4321.5 cd"), object: exact)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 10), .completed)
        expectValue(app.sliders["lightIntensity"], equals: "4321.5 cd")
        app.buttons["undo"].tap()
        XCTAssertEqual(exact.value as? String, "900 cd")
        expectValue(app.sliders["lightIntensity"], equals: "900 cd")
        app.buttons["redo"].tap()
        XCTAssertEqual(exact.value as? String, "4321.5 cd")
        expectValue(app.sliders["lightIntensity"], equals: "4321.5 cd")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Studio-exact-light-intensity"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.buttons["saveProject"].tap()
        waitForCommittedProject(in: app)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["recipes"].waitForExistence(timeout: 15))
        reveal(exact, in: app)
        XCTAssertEqual(exact.value as? String, "4321.5 cd")
    }

    func testExactCameraFocalLengthUndoRedoAndReopen() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let camera = app.buttons["viewMode-Camera"]
        XCTAssertTrue(camera.waitForExistence(timeout: 15))
        camera.tap()
        let exact = app.buttons["cameraFocalLengthExact"]
        reveal(exact, in: app)
        XCTAssertEqual(exact.value as? String, "50 mm")
        exact.tap()
        replaceText(app.textFields["precisionValue"], with: "73.125")
        app.buttons["precisionApply"].tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND value == %@", "73.125 mm"), object: exact)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 10), .completed)
        expectValue(app.sliders["cameraFocalLength"], equals: "73.125 mm")
        app.buttons["undo"].tap()
        XCTAssertEqual(exact.value as? String, "50 mm")
        expectValue(app.sliders["cameraFocalLength"], equals: "50 mm")
        app.buttons["redo"].tap()
        XCTAssertEqual(exact.value as? String, "73.125 mm")
        expectValue(app.sliders["cameraFocalLength"], equals: "73.125 mm")
        app.buttons["saveProject"].tap()
        waitForCommittedProject(in: app)
        app.terminate()
        app.launch()
        XCTAssertTrue(camera.waitForExistence(timeout: 15))
        camera.tap()
        reveal(exact, in: app)
        XCTAssertEqual(exact.value as? String, "73.125 mm")
        expectValue(app.sliders["cameraFocalLength"], equals: "73.125 mm")
    }

    func testExactModifierWidthAndRoomCrossingWithInsideCenters() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["recipes"].waitForExistence(timeout: 15))
        let emitter = app.buttons["emitterKind"]
        reveal(emitter, in: app)
        emitter.tap()
        app.buttons["Rectangular softbox"].tap()
        let exact = app.buttons["emitterWidthExact"]
        reveal(exact, in: app)
        exact.tap()
        replaceText(app.textFields["precisionValue"], with: "1.237")
        app.buttons["precisionApply"].tap()
        let width = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND value == %@", "1.237 m"), object: exact)
        XCTAssertEqual(XCTWaiter.wait(for: [width], timeout: 10), .completed)
        expectValue(app.sliders["emitterWidth"], equals: "1.237 m")
        app.buttons["undo"].tap()
        expectValue(app.sliders["emitterWidth"], equals: "0.6 m")
        app.buttons["redo"].tap()
        expectValue(app.sliders["emitterWidth"], equals: "1.237 m")
        XCTAssertEqual(exact.value as? String, "1.237 m")
        app.buttons["saveProject"].tap()
        waitForCommittedProject(in: app)
        let open = app.buttons["openRoomPlacement"]
        reveal(open, in: app, towardBottom: false)
        open.tap()
        XCTAssertTrue(app.buttons["closeRoomPlacement"].waitForExistence(timeout: 15),
                      "Room sheet must actually open")
        let centers = app.otherElements["roomPlacementStatus"]
        let faces = app.descendants(matching: .any)["modifierCrossingStatus"].firstMatch
        func expect(_ target: XCUIElement, contains message: String) {
            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", message), object: target)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 15), .completed)
        }
        expect(centers, contains: "All 5 center positions inside room")
        expect(faces, contains: "Rectangular emitting faces within room outline")
        setRoomMeasurement("1.6", id: "roomSubjectX", in: app)
        expect(centers, contains: "All 5 center positions inside room")
        expect(faces, contains: "1 rectangular modifier crosses a wall")
        // The summary is above the measurements. Keep moving toward it when
        // its frame reaches the sheet's navigation bar but is not yet hittable.
        reveal(faces, in: app, towardBottom: false)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Manual-room-modifier-crossing"; attachment.lifetime = .keepAlways; add(attachment)
        app.buttons["closeRoomPlacement"].tap()
        let status = app.staticTexts["projectStatus"]
        // Committed room measurements now belong to the editable project.
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label == %@", "Unsaved changes"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 10), .completed)
        app.buttons["undo"].tap()
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label == %@", "Saved locally"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 10), .completed)
        XCTAssertEqual(exact.value as? String, "1.237 m", "Undoing room placement must preserve the saved modifier width")
        app.buttons["redo"].tap()
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label == %@", "Unsaved changes"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 10), .completed)
        app.buttons["saveProject"].tap()
        waitForCommittedProject(in: app)
    }
}
