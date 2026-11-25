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

    #if targetEnvironment(simulator)
    func testSettingsFeet3DFitAndSimulatorARManualFallback() throws {
        let app = makeApp()
        app.launch()
        let tools = app.buttons["studioTools"]
        waitForEnabledStudioControl(tools)
        revealStudioContent(tools, in: app, towardBottom: false)
        tools.tap()
        app.buttons["Settings"].tap()
        let units = app.buttons["distanceUnits"]
        XCTAssertTrue(units.waitForExistence(timeout: 10))
        XCTAssertEqual(units.value as? String, "Meters")
        units.tap()
        app.buttons["Feet"].tap()
        XCTAssertEqual(units.value as? String, "Feet")
        app.navigationBars["Settings"].buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Feet · cd · K"].waitForExistence(timeout: 10))

        tools.tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(units.waitForExistence(timeout: 10))
        XCTAssertEqual(units.value as? String, "Feet", "Reopening Settings must retain the preference")
        app.navigationBars["Settings"].buttons["Done"].tap()
        let orbit = app.segmentedControls["viewMode"].buttons["3D"]
        revealStudioContent(orbit, in: app)
        orbit.tap()
        let fit = app.buttons["fitStudioSetup"]
        XCTAssertTrue(fit.waitForExistence(timeout: 10))
        revealStudioContent(fit, in: app)
        fit.tap()
        XCTAssertTrue(orbit.isSelected)
        let orbitLabel = app.staticTexts["3D / DRAG TO ORBIT"]
        revealStudioContent(orbitLabel, in: app, towardBottom: false)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Studio-3D-fit-feet"; screenshot.lifetime = .keepAlways; add(screenshot)

        revealStudioContent(tools, in: app, towardBottom: false)
        tools.tap()
        app.buttons["Place in AR"].tap()
        let status = app.descendants(matching: .any)["arTrackingStatus"].firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertEqual(status.label, "AR is unavailable on this device")
        XCTAssertFalse(app.buttons["startARCamera"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["arCameraPreview"].firstMatch.exists)
        let manual = app.buttons["arManualMeasurements"]
        revealStudioContent(manual, in: app)
        manual.tap()
        XCTAssertTrue(app.buttons["closeRoomPlacement"].waitForExistence(timeout: 10))
        let width = app.textFields["roomWidth"]
        revealStudioContent(width, in: app)
        XCTAssertEqual(width.label, "Width in feet", "The manual fallback must use the selected units")
        app.buttons["closeRoomPlacement"].tap()
        XCTAssertTrue(app.buttons["closeARPlacement"].waitForExistence(timeout: 10))
        app.buttons["closeARPlacement"].tap()
        XCTAssertTrue(orbit.waitForExistence(timeout: 10))
        XCTAssertTrue(orbit.isSelected)

        revealStudioContent(tools, in: app, towardBottom: false)
        tools.tap()
        let arrange = app.buttons["Arrange setup"]
        XCTAssertTrue(arrange.waitForExistence(timeout: 10))
        arrange.tap()
        let setupPosition = app.buttons["setupXExact"]
        XCTAssertTrue(setupPosition.waitForExistence(timeout: 10), "Arrangement must present its coordinate editor")
        revealStudioContent(setupPosition, in: app, towardBottom: false)
        XCTAssertTrue(setupPosition.isEnabled)
        let arrangementScreenshot = XCTAttachment(screenshot: app.screenshot())
        arrangementScreenshot.name = "Studio-arrangement-feet"
        arrangementScreenshot.lifetime = .keepAlways
        add(arrangementScreenshot)
        let cancelArrangement = app.buttons["cancelArrangement"]
        XCTAssertTrue(cancelArrangement.exists && cancelArrangement.isHittable)
        cancelArrangement.tap()
        XCTAssertTrue(orbit.waitForExistence(timeout: 10))
        revealStudioContent(orbit, in: app, towardBottom: false)
        XCTAssertTrue(orbit.isSelected, "Cancelling Arrangement must preserve the selected 3D mode")
    }
    #endif

    func testRecipeEditSaveAndReopen() throws {
        let app = makeApp()
        app.launch()
        waitForEnabledStudioControl(app.buttons["recipes"])
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
        revealStudioContent(app.staticTexts["projectStatus"], in: app, towardBottom: false)
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
        revealStudioContent(element, in: app, towardBottom: direction)
        XCTAssertTrue(element.exists && element.isHittable)
    }

    func testOpticsEditingUndoRedoAndRelaunch() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability02() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability03() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability04() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability05() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability06() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability07() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability08() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability09() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    func testOpticsRepeatability10() throws {
        try runOpticsEditingUndoRedoAndRelaunch()
    }

    private func runOpticsEditingUndoRedoAndRelaunch() throws {
        let app = makeApp()
        app.launchEnvironment["KEYFILL_UI_TEST_SLIDER_TRACE"] = "1"
        app.launch()
        assertStatus("Unsaved changes", in: app)
        let emitter = app.buttons["emitterKind"]
        revealStudioContent(emitter, in: app)
        emitter.tap()
        app.buttons["Rectangular softbox"].tap()
        XCTAssertEqual(emitter.value as? String, "Rectangular softbox")
        let width = app.sliders["emitterWidth"]
        revealStudioContent(width, in: app)
        XCTAssertEqual(app.sliders.matching(identifier: "emitterWidth").count, 1,
                       "One native slider must own the width accessibility metadata")
        let initialWidth = try XCTUnwrap(width.value as? String)
        XCTAssertEqual(width.label, "Width in meters", "The native slider must retain its accessible label")
        XCTAssertEqual(initialWidth, "0.6 m", "The native slider must expose the model readout, not a percentage")
        width.adjust(toNormalizedSliderPosition: 0.5)
        let undo = app.buttons["undo"]
        let gestureCompleted = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                guard let currentWidth = width.value as? String,
                      currentWidth != initialWidth else { return false }
                return undo.exists && undo.isEnabled
            }, object: width)
        XCTAssertEqual(XCTWaiter.wait(for: [gestureCompleted], timeout: 10), .completed,
                       "The width must change and finish its edit before capturing the value for Undo and Redo")

        let editedWidth = try XCTUnwrap(width.value as? String)
        XCTAssertNotEqual(editedWidth, initialWidth, "The width adjustment must actually change the model before testing undo")

        XCTAssertTrue(undo.exists && undo.isHittable)
        let state = XCTAttachment(string: "Initial width: \(initialWidth)\nEdited width: \(editedWidth)\nUndo enabled: \(undo.isEnabled)\nRedo enabled: \(app.buttons["redo"].isEnabled)\n\(width.debugDescription)\n\(undo.debugDescription)")
        state.name = "Optics-tracking-before-undo"; state.lifetime = .keepAlways; add(state)
        XCTAssertTrue(undo.isEnabled, "The completed width gesture must close its edit before Undo")
        undo.tap()
        XCTAssertEqual(emitter.value as? String, "Rectangular softbox", "Undo width, not the preceding emitter selection")
        revealStudioContent(width, in: app)
        XCTAssertEqual(width.value as? String, initialWidth)
        let redo = app.buttons["redo"]
        XCTAssertTrue(redo.exists && redo.isHittable)
        XCTAssertTrue(redo.isEnabled, "Undo must complete and enable Redo")
        redo.tap()
        revealStudioContent(width, in: app)
        XCTAssertEqual(width.value as? String, editedWidth)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-optics"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.buttons["saveProject"].tap()
        waitForCommittedProject(in: app)
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
        XCTAssertTrue(undo.exists && undo.isHittable)
        undo.tap()
        reveal(focal, in: app)
        XCTAssertEqual(focal.value as? String, initial)
        let redo = app.buttons["redo"]
        XCTAssertTrue(redo.exists && redo.isHittable)
        redo.tap()
        reveal(focal, in: app)
        XCTAssertEqual(focal.value as? String, "85 mm")
        XCTAssertTrue(undo.exists && undo.isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-camera"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.buttons["saveProject"].tap()
        waitForCommittedProject(in: app)
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
        XCTAssertTrue(undo.exists && undo.isHittable)
        undo.tap()
        reveal(balance, in: app)
        XCTAssertEqual(balance.value as? String, "5600 K")
        reveal(tungsten, in: app)
        tungsten.tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-test-card"; attachment.lifetime = .keepAlways; self.add(attachment)
        app.buttons["saveProject"].tap()
        waitForCommittedProject(in: app)
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

    func testStudySwitchesBetweenSphereAndMannequinWithoutEditingScene() throws {
        let app = makeApp()
        app.launch()
        assertStatus("Unsaved changes", in: app)
        let study = app.segmentedControls["viewMode"].buttons["Study"]
        XCTAssertTrue(study.waitForExistence(timeout: 15))
        study.tap()
        let rendered = app.images["studyPreview"]
        XCTAssertTrue(rendered.waitForExistence(timeout: 20))
        XCTAssertEqual(rendered.label, "Rendered neutral sphere and panel")
        let bust = app.segmentedControls["studySubject"].buttons["Bust"]
        revealStudioContent(bust, in: app)
        bust.tap()
        let predicate = NSPredicate(format: "exists == true AND label == %@", "Rendered neutral mannequin bust")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: rendered)], timeout: 30), .completed)
        XCTAssertEqual(app.staticTexts["studyBackend"].label, "CPU reference")
        revealStudioContent(rendered, in: app, towardBottom: false)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-mannequin-study"; attachment.lifetime = .keepAlways; add(attachment)
        XCTAssertFalse(app.buttons["undo"].isEnabled)
        assertStatus("Unsaved changes", in: app)
        let sphere = app.segmentedControls["studySubject"].buttons["Sphere"]
        revealStudioContent(sphere, in: app)
        sphere.tap()
        let spherePredicate = NSPredicate(format: "exists == true AND label == %@", "Rendered neutral sphere and panel")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: spherePredicate, object: rendered)], timeout: 30), .completed)
        XCTAssertFalse(app.buttons["undo"].isEnabled)
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

    func testStudioGuideKeepsUnsavedSetupSelectionAndHistory() throws {
        let app = makeApp()
        app.launch()
        waitForEnabledStudioControl(app.buttons["recipes"])
        assertStatus("Unsaved changes", in: app)
        let projectName = app.staticTexts["projectName"].label
        XCTAssertFalse(projectName.isEmpty)

        func assertLightCount(_ count: Int, line: UInt = #line) {
            XCTAssertTrue(app.staticTexts["\(count) lights"].waitForExistence(timeout: 10),
                          "Expected the actual studio to contain \(count) lights", line: line)
        }

        // Leave genuine unsaved edits and both history branches available.
        assertLightCount(3)
        let addLight = app.buttons["addLightShortcut"]
        for count in [4, 5] {
            revealStudioContent(addLight, in: app, towardBottom: false)
            addLight.tap()
            assertLightCount(count)
        }
        let undo = app.buttons["undo"]
        let redo = app.buttons["redo"]
        waitForEnabledStudioControl(undo)
        undo.tap()
        assertLightCount(4)
        let key = app.buttons["Select Key on plan"]
        revealStudioContent(key, in: app, towardBottom: false)
        key.tap()
        XCTAssertTrue(key.isSelected)
        XCTAssertTrue(undo.isEnabled && redo.isEnabled)
        XCTAssertTrue(app.buttons["light-Light 1"].exists)
        XCTAssertFalse(app.buttons["light-Light 2"].exists)
        let plan = app.segmentedControls["viewMode"].buttons["Plan"]
        XCTAssertTrue(plan.isSelected)
        assertStatus("Unsaved changes", in: app)

        let guide = app.buttons["openStudioGuide"]
        revealStudioContent(guide, in: app, towardBottom: false)
        waitForEnabledStudioControl(guide)
        let guideFrame = guide.frame
        // CGRect dimensions can inherit rounding from subtracting coordinate endpoints.
        // Allow only four endpoint ULPs while retaining the 44-point target.
        let coordinateRoundingTolerance = max(guideFrame.maxX.ulp, guideFrame.maxY.ulp) * 4
        XCTAssertGreaterThanOrEqual(guideFrame.width + coordinateRoundingTolerance, 44)
        XCTAssertGreaterThanOrEqual(guideFrame.height + coordinateRoundingTolerance, 44)
        XCTAssertTrue(app.buttons["openProjectLibrary"].isHittable)
        XCTAssertTrue(app.buttons["exportLightingPlan"].isHittable)
        guide.tap()
        let overview = app.staticTexts["studioGuideOverview"]
        XCTAssertTrue(overview.waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "closeStudioGuide").count, 1,
                       "The overview must expose exactly one Done action")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Studio-guide-overview"
        attachment.lifetime = .keepAlways
        add(attachment)

        let referenceTopic = app.buttons["studioGuideTopic-4"]
        revealStudioContent(referenceTopic, in: app)
        referenceTopic.tap()
        let referenceBar = app.navigationBars["Explore a reference"]
        XCTAssertTrue(referenceBar.waitForExistence(timeout: 10))
        let back = referenceBar.buttons.element(boundBy: 0)
        XCTAssertTrue(back.isHittable)
        XCTAssertLessThan(back.frame.midX, app.frame.midX, "Use the native back action, not Done")
        back.tap()
        XCTAssertTrue(overview.waitForExistence(timeout: 10))

        let savingTopic = app.buttons["studioGuideTopic-6"]
        revealStudioContent(savingTopic, in: app)
        savingTopic.tap()
        XCTAssertTrue(app.navigationBars["Save and share"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "closeStudioGuide").count, 1,
                       "A pushed topic must expose exactly one Done action")
        let done = app.buttons["closeStudioGuide"]
        done.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: done)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed,
                       "Done on a topic page must dismiss the entire guide")

        assertStatus("Unsaved changes", in: app)
        XCTAssertEqual(app.staticTexts["projectName"].label, projectName)
        assertLightCount(4)
        XCTAssertTrue(plan.isSelected)
        XCTAssertTrue(key.isSelected, "Reading the guide must keep the selected light")
        XCTAssertTrue(app.buttons["light-Light 1"].exists)
        XCTAssertFalse(app.buttons["light-Light 2"].exists)
        XCTAssertTrue(undo.isEnabled && redo.isEnabled)

        // Exercise the retained entries, not just the enabled state of the arrows.
        redo.tap()
        assertLightCount(5)
        XCTAssertTrue(app.buttons["light-Light 2"].exists)
        undo.tap()
        assertLightCount(4)
        XCTAssertFalse(app.buttons["light-Light 2"].exists)
        undo.tap()
        assertLightCount(3)
        XCTAssertFalse(app.buttons["light-Light 1"].exists)
        assertStatus("Unsaved changes", in: app)
    }
}
