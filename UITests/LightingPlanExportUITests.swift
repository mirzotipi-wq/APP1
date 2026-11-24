import Foundation
import XCTest

final class LightingPlanExportUITests: XCTestCase {
    func testFullLibraryCanPrepareUnsavedEditableCopyWithoutSavingOrChangingHistory() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["KEYFILL_UI_TEST_FULL_LIBRARY"] = "1"
        app.launch()

        func assertLabel(_ element: XCUIElement, _ expected: String) {
            let predicate = NSPredicate(format: "exists == true AND label == %@", expected)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 15), .completed)
        }
        let status = app.staticTexts["projectStatus"]
        // The UUID-isolated fixture writes all 64 records in one atomic save.
        // Saved state proves preparation succeeded rather than falling back to
        // the unsaved default scene if fixture creation failed.
        assertLabel(status, "Saved locally")
        assertLabel(app.staticTexts["projectName"], "Portrait setup")
        let undo = app.buttons["undo"]
        let redo = app.buttons["redo"]
        XCTAssertFalse(undo.isEnabled)
        XCTAssertFalse(redo.isEnabled)

        let addLight = app.buttons["addLightShortcut"]
        revealStudioContent(addLight, in: app, towardBottom: false)
        addLight.tap()
        let addedLight = app.buttons["light-Light 1"]
        XCTAssertTrue(addedLight.waitForExistence(timeout: 15), "The copy must contain a real unsaved scene edit")
        assertLabel(status, "Unsaved changes")
        XCTAssertTrue(undo.isEnabled)
        XCTAssertFalse(redo.isEnabled)

        func openCopy(expectedLights: Int) {
            let export = app.buttons["exportLightingPlan"]
            XCTAssertTrue(export.waitForExistence(timeout: 10))
            XCTAssertTrue(export.isEnabled && export.isHittable)
            export.tap()
            assertFormatChooser(in: app, expectedLights: expectedLights)
            let prepare = app.buttons["prepareEditableProjectCopy"]
            XCTAssertTrue(prepare.waitForExistence(timeout: 5))
            prepare.tap()
            assertLabel(app.staticTexts["editableCopyProjectName"], "Portrait setup")
            assertLabel(app.staticTexts["editableCopyLightCount"], "\(expectedLights) lights")
            let saveCopy = app.buttons["saveEditableProjectCopy"]
            XCTAssertTrue(saveCopy.waitForExistence(timeout: 15), "The actual document preparation must finish at full library capacity")
            revealStudioContent(saveCopy, in: app)
            XCTAssertTrue(saveCopy.isEnabled)
            XCTAssertFalse(app.staticTexts["editableCopyPreparationError"].exists)
            XCTAssertFalse(app.staticTexts["editableCopyExportMessage"].exists,
                           "Preparing a document must not claim it has been exported")
            let scope = app.staticTexts["editableCopyScope"]
            revealStudioContent(scope, in: app)
            XCTAssertTrue(scope.label.contains("Reference photos, room measurements and edit history are not included"))
        }
        func closeCopy() {
            let close = app.buttons["closeEditableProjectCopy"]
            XCTAssertTrue(close.isHittable)
            close.tap()
            let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: close)
            XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed)
            XCTAssertTrue(app.buttons["exportLightingPlan"].isHittable)
        }

        openCopy(expectedLights: 4)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Full-library-editable-copy"
        attachment.lifetime = .keepAlways
        self.add(attachment)
        closeCopy()

        // Reuse the same presenter for a different format while the library is
        // full and the fourth light is still unsaved. The chooser must reset;
        // neither the earlier copy screen nor its prepared state may survive.
        app.buttons["exportLightingPlan"].tap()
        assertFormatChooser(in: app, expectedLights: 4)
        app.buttons["prepareLightingPlanPDF"].tap()
        let fullLibraryPages = app.staticTexts["lightingPlanPDFPages"]
        XCTAssertTrue(fullLibraryPages.waitForExistence(timeout: 15))
        XCTAssertTrue(fullLibraryPages.label.contains("2 pages"))
        XCTAssertTrue(app.buttons["shareLightingPlanPDF"].exists)
        closePDF(in: app)
        assertLabel(status, "Unsaved changes")
        XCTAssertTrue(addedLight.exists)
        XCTAssertTrue(undo.isEnabled && undo.isHittable)
        XCTAssertFalse(redo.isEnabled)
        undo.tap()
        assertLabel(status, "Saved locally")
        XCTAssertFalse(addedLight.exists)
        XCTAssertFalse(undo.isEnabled)
        XCTAssertTrue(redo.isEnabled)

        // Reopening captures the current 3-light scene, not the earlier 4-light
        // prepared snapshot, and must leave the redo command available.
        openCopy(expectedLights: 3)
        closeCopy()
        assertLabel(status, "Saved locally")
        XCTAssertFalse(undo.isEnabled)
        XCTAssertTrue(redo.isEnabled && redo.isHittable)
        redo.tap()
        assertLabel(status, "Unsaved changes")
        XCTAssertTrue(addedLight.exists)

        // No system destination was selected and no library save occurred.
        // Keep the same namespace and full-library flag: initialization must
        // preserve the original saved setup rather than rewrite the fixture.
        app.terminate()
        app.launch()
        assertLabel(status, "Saved locally")
        assertLabel(app.staticTexts["projectName"], "Portrait setup")
        XCTAssertFalse(addedLight.exists)
        XCTAssertFalse(undo.isEnabled)
        XCTAssertFalse(redo.isEnabled)
    }

    func testExportPreviewOpensWithoutSavingOrChangingScene() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        let export = app.buttons["exportLightingPlan"]
        waitForEnabledStudioControl(export)
        export.tap()
        assertFormatChooser(in: app, expectedLights: 3)

        // Cancelling before choosing a format must dismiss the sole sheet
        // without preparing a document or changing the editor/history.
        let cancel = app.buttons["closeLightingPlanExportFormats"]
        cancel.tap()
        let cancelled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: cancel)
        XCTAssertEqual(XCTWaiter.wait(for: [cancelled], timeout: 10), .completed)
        XCTAssertTrue(export.isHittable)
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
        XCTAssertFalse(app.buttons["undo"].isEnabled)
        XCTAssertFalse(app.buttons["redo"].isEnabled)

        export.tap()
        assertFormatChooser(in: app, expectedLights: 3)
        let prepare = app.buttons["prepareLightingPlanPDF"]
        XCTAssertTrue(prepare.waitForExistence(timeout: 5))
        prepare.tap()
        let pages = app.staticTexts["lightingPlanPDFPages"]
        XCTAssertTrue(pages.waitForExistence(timeout: 15))
        XCTAssertTrue(pages.label.contains("2 pages"))
        XCTAssertTrue(app.buttons["shareLightingPlanPDF"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Lighting-plan-preview"; attachment.lifetime = .keepAlways; add(attachment)
        closePDF(in: app)
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
        XCTAssertFalse(app.buttons["undo"].isEnabled)
        XCTAssertFalse(app.buttons["redo"].isEnabled)
    }

    private func assertFormatChooser(in app: XCUIApplication, expectedLights: Int) {
        XCTAssertTrue(app.buttons["closeLightingPlanExportFormats"].waitForExistence(timeout: 5),
                      "The export sheet must become interactive before a document format is selected")
        XCTAssertEqual(app.staticTexts["exportSnapshotProjectName"].label, "Portrait setup")
        XCTAssertEqual(app.staticTexts["exportSnapshotLightCount"].label, "\(expectedLights) lights")
        XCTAssertTrue(app.buttons["prepareLightingPlanPDF"].isHittable)
        XCTAssertTrue(app.buttons["prepareEditableProjectCopy"].isHittable)
        XCTAssertFalse(app.staticTexts["lightingPlanPDFPages"].exists)
        XCTAssertFalse(app.staticTexts["editableCopyProjectName"].exists)
    }

    private func closePDF(in app: XCUIApplication) {
        let close = app.buttons["closeLightingPlanPDF"]
        XCTAssertTrue(close.isHittable)
        close.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: close)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed)
        XCTAssertTrue(app.buttons["exportLightingPlan"].isHittable)
    }
}
