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

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, direction: Bool = true) {
        for _ in 0..<8 where !element.isHittable {
            if direction { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.exists && element.isHittable)
    }

    func testOpticsEditingUndoRedoAndRelaunch() throws {
        let app = makeApp()
        app.launch()
        assertStatus("Unsaved changes", in: app)
        let emitter = app.buttons["emitterKind"]
        reveal(emitter, in: app)
        emitter.tap()
        app.buttons["Rectangular softbox"].tap()
        XCTAssertEqual(emitter.value as? String, "Rectangular softbox")
        let width = app.sliders["emitterWidth"]
        reveal(width, in: app)
        width.adjust(toNormalizedSliderPosition: 0.5)
        let editedWidth = width.value as? String
        XCTAssertNotNil(editedWidth)

        let undo = app.buttons["undo"]
        reveal(undo, in: app, direction: false)
        undo.tap()
        reveal(width, in: app)
        XCTAssertNotEqual(width.value as? String, editedWidth)
        let redo = app.buttons["redo"]
        reveal(redo, in: app, direction: false)
        redo.tap()
        reveal(width, in: app)
        XCTAssertEqual(width.value as? String, editedWidth)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-optics"; attachment.lifetime = .keepAlways; addAttachment(attachment)
        app.buttons["saveProject"].tap()
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        reveal(emitter, in: app)
        XCTAssertEqual(emitter.value as? String, "Rectangular softbox")
        reveal(width, in: app)
        XCTAssertEqual(width.value as? String, editedWidth)
    }

    func testCameraFocalLengthUndoAndRelaunch() throws {
        let app = makeApp()
        app.launch()
        assertStatus("Unsaved changes", in: app)
        let camera = app.buttons["editCamera"]
        reveal(camera, in: app)
        camera.tap()
        let focal = app.sliders["cameraFocalLength"]
        reveal(focal, in: app)
        let initial = focal.value as? String
        let tele = app.buttons["85 millimeter lens"]
        reveal(tele, in: app)
        tele.tap()
        XCTAssertEqual(focal.value as? String, "85 mm")
        let undo = app.buttons["undo"]
        reveal(undo, in: app, direction: false)
        undo.tap()
        reveal(focal, in: app)
        XCTAssertEqual(focal.value as? String, initial)
        let redo = app.buttons["redo"]
        reveal(redo, in: app, direction: false)
        redo.tap()
        reveal(focal, in: app)
        XCTAssertEqual(focal.value as? String, "85 mm")
        reveal(undo, in: app, direction: false)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-camera"; attachment.lifetime = .keepAlways; addAttachment(attachment)
        app.buttons["saveProject"].tap()
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        reveal(camera, in: app)
        camera.tap()
        reveal(focal, in: app)
        XCTAssertEqual(focal.value as? String, "85 mm")
    }

    func testMeterBalanceSaveUndoAndRelaunch() throws {
        let app = makeApp()
        app.launch()
        assertStatus("Unsaved changes", in: app)
        let disclosure = app.buttons["meterDisclosure"]
        reveal(disclosure, in: app)
        disclosure.tap()
        let lux = app.staticTexts["combinedLux"]
        reveal(lux, in: app)
        XCTAssertTrue(lux.waitForExistence(timeout: 10))
        let originalLux = lux.label
        let balance = app.sliders["previewWhiteBalance"]
        reveal(balance, in: app)
        XCTAssertEqual(balance.value as? String, "5600 K")
        let tungsten = app.buttons["balance-3200"]
        reveal(tungsten, in: app)
        tungsten.tap()
        XCTAssertEqual(balance.value as? String, "3200 K")
        reveal(lux, in: app, direction: false)
        XCTAssertEqual(lux.label, originalLux, "Balance changes color, not incident lux")
        let undo = app.buttons["undo"]
        reveal(undo, in: app, direction: false)
        undo.tap()
        reveal(balance, in: app)
        XCTAssertEqual(balance.value as? String, "5600 K")
        reveal(tungsten, in: app)
        tungsten.tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-test-card"; attachment.lifetime = .keepAlways; addAttachment(attachment)
        app.buttons["saveProject"].tap()
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        reveal(disclosure, in: app)
        disclosure.tap()
        reveal(balance, in: app)
        XCTAssertEqual(balance.value as? String, "3200 K")
    }

    func testStudyRendersActualReferenceFrame() throws {
        let app = makeApp()
        app.launch()
        assertStatus("Unsaved changes", in: app)
        let study = app.segmentedControls["viewMode"].buttons["Study"]
        XCTAssertTrue(study.waitForExistence(timeout: 10))
        study.tap()
        let rendered = app.images["studyPreview"]
        XCTAssertTrue(rendered.waitForExistence(timeout: 20), "The reference renderer must publish a real frame")
        XCTAssertTrue(rendered.isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-light-study"; attachment.lifetime = .keepAlways; addAttachment(attachment)
        let plan = app.segmentedControls["viewMode"].buttons["Plan"]
        plan.tap()
        XCTAssertTrue(app.buttons["editCamera"].waitForExistence(timeout: 5))
        study.tap()
        XCTAssertTrue(rendered.waitForExistence(timeout: 20))
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
