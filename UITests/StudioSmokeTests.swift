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
        let closeRecipes = app.buttons["closeRecipes"]
        XCTAssertTrue(closeRecipes.waitForExistence(timeout: 15), "Recipe sheet must actually open")
        let silhouette = app.buttons["recipe-Silhouette"]
        revealStudioContent(silhouette, in: app)
        silhouette.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: closeRecipes)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 15), .completed)
        let backlight = app.buttons["light-Backlight"]
        XCTAssertTrue(backlight.waitForExistence(timeout: 15), "Verify the recipe changed the actual rig before adding a light")
        XCTAssertFalse(app.buttons["light-Key"].exists)
        let addLightButton = app.buttons["addLightShortcut"]
        revealStudioContent(addLightButton, in: app, towardBottom: false)
        addLightButton.tap()
        let row = app.buttons["light-Light 1"]
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        revealStudioContent(row, in: app)
        XCTAssertTrue(backlight.exists)
        XCTAssertTrue(row.isSelected, "The new light must be selected")
        app.buttons["saveProject"].tap()
        app.swipeDown()
        assertStatus("Saved locally", in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-plan"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        revealStudioContent(row, in: app)
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
        revealStudioContent(emitter, in: app)
        emitter.tap()
        app.buttons["Rectangular softbox"].tap()
        XCTAssertEqual(emitter.value as? String, "Rectangular softbox")
        let width = app.sliders["emitterWidth"]
        revealStudioContent(width, in: app)
        let initialWidth = try XCTUnwrap(width.value as? String)
        width.adjust(toNormalizedSliderPosition: 0.5)
        let editedWidth = try XCTUnwrap(width.value as? String)
        XCTAssertNotEqual(editedWidth, initialWidth, "The width adjustment must actually change the model before testing undo")

        let undo = app.buttons["undo"]
        reveal(undo, in: app, direction: false)
        undo.tap()
        XCTAssertEqual(emitter.value as? String, "Rectangular softbox", "Undo width, not the preceding emitter selection")
        revealStudioContent(width, in: app)
        XCTAssertEqual(width.value as? String, initialWidth)
        let redo = app.buttons["redo"]
        reveal(redo, in: app, direction: false)
        redo.tap()
        revealStudioContent(width, in: app)
        XCTAssertEqual(width.value as? String, editedWidth)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-optics"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.buttons["saveProject"].tap()
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        revealStudioContent(emitter, in: app)
        XCTAssertEqual(emitter.value as? String, "Rectangular softbox")
        revealStudioContent(width, in: app)
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
        attachment.name = "Studio-camera"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.buttons["saveProject"].tap()
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        reveal(camera, in: app)
        camera.tap()
        reveal(focal, in: app)
        XCTAssertEqual(focal.value as? String, "85 mm")
    }

    private func assertMeterState(_ value: String, disclosure: XCUIElement, in app: XCUIApplication,
                                  file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == true AND value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: disclosure)
        let result = XCTWaiter.wait(for: [expectation], timeout: 10)
        if result != .completed {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Meter-state-failure"; screenshot.lifetime = .keepAlways; self.add(screenshot)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Meter-accessibility-failure"; hierarchy.lifetime = .keepAlways; self.add(hierarchy)
        }
        XCTAssertEqual(result, .completed, "Expected meter to be \(value)", file: file, line: line)
    }

    private func openMeterFromScene(in app: XCUIApplication) {
        let shortcut = app.buttons["openMeter"]
        reveal(shortcut, in: app, direction: false)
        shortcut.tap()
        let disclosure = app.buttons["meterDisclosure"]
        assertMeterState("Expanded", disclosure: disclosure, in: app)
        XCTAssertTrue(disclosure.isHittable, "The shortcut must reveal the meter, not merely change state offscreen")
    }

    func testMeterBalanceSaveUndoAndRelaunch() throws {
        let app = makeApp()
        app.launch()
        assertStatus("Unsaved changes", in: app)
        let disclosure = app.buttons["meterDisclosure"]
        assertMeterState("Collapsed", disclosure: disclosure, in: app)
        // Navigate from the visible Scene toolbar before exercising the disclosure.
        openMeterFromScene(in: app)
        disclosure.tap()
        assertMeterState("Collapsed", disclosure: disclosure, in: app)
        XCTAssertFalse(app.staticTexts["combinedLux"].exists)
        XCTAssertTrue(disclosure.isHittable)
        disclosure.tap()
        assertMeterState("Expanded", disclosure: disclosure, in: app)
        let lux = app.staticTexts["combinedLux"]
        let meterReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label ENDSWITH %@", " lx"), object: lux)
        XCTAssertEqual(XCTWaiter.wait(for: [meterReady], timeout: 15), .completed)
        reveal(lux, in: app)
        let originalLux = lux.label
        let balance = app.sliders["previewWhiteBalance"]
        reveal(balance, in: app)
        XCTAssertEqual(balance.value as? String, "5600 K")
        let tungsten = app.buttons["balance-3200"]
        reveal(tungsten, in: app)
        tungsten.tap()
        XCTAssertEqual(balance.value as? String, "3200 K")
        let stableLux = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label == %@", originalLux), object: lux)
        XCTAssertEqual(XCTWaiter.wait(for: [stableLux], timeout: 15), .completed, "Balance changes color, not incident lux")
        reveal(lux, in: app, direction: false)
        XCTAssertEqual(lux.label, originalLux)
        let undo = app.buttons["undo"]
        reveal(undo, in: app, direction: false)
        undo.tap()
        reveal(balance, in: app)
        XCTAssertEqual(balance.value as? String, "5600 K")
        reveal(tungsten, in: app)
        tungsten.tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-test-card"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.buttons["saveProject"].tap()
        app.terminate()
        app.launch()
        assertStatus("Saved locally", in: app)
        assertMeterState("Collapsed", disclosure: disclosure, in: app)
        openMeterFromScene(in: app)
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
        attachment.name = "Studio-light-study"; attachment.lifetime = .keepAlways; self.add(attachment)
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
