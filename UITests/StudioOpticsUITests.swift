import XCTest

final class StudioOpticsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func makeApp(corrupt: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        if corrupt { app.launchEnvironment["KEYFILL_UI_TEST_CORRUPT"] = "1" }
        return app
    }

    private func assertStatus(_ value: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let status = app.staticTexts["projectStatus"]
        let predicate = NSPredicate(format: "exists == true AND label == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: status)
        let result = XCTWaiter.wait(for: [expectation], timeout: 10)
        if result != .completed {
            // Inspect one immutable snapshot only after the original wait fails.
            // Raw output survives a run that cannot finalize its result bundle.
            let metadata: String
            do {
                let snapshot = try status.snapshot()
                metadata = [
                    "expectedLabel: \(value)",
                    "identifier: \(snapshot.identifier)",
                    "label: \(snapshot.label)",
                    "elementType: \(snapshot.elementType)",
                    "frame: \(snapshot.frame)",
                    "isEnabled: \(snapshot.isEnabled)",
                    "isSelected: \(snapshot.isSelected)"
                ].joined(separator: "\n")
            } catch {
                metadata = "expectedLabel: \(value)\nstatusSnapshotError: \(error.localizedDescription)"
            }
            let byteLimit = 4_096
            let prefix = Array(metadata.utf8.prefix(byteLimit + 1))
            var endIndex = min(byteLimit, prefix.count)
            if prefix.count > byteLimit {
                // A continuation byte at the boundary belongs to the scalar
                // that must be omitted; valid UTF-8 needs at most three trims.
                while endIndex > 0 && (prefix[endIndex] & 0xC0) == 0x80 {
                    endIndex -= 1
                }
            }
            var excerpt = String(decoding: prefix.prefix(endIndex), as: UTF8.self)
            if prefix.count > byteLimit {
                excerpt += "\n[Truncated after 4,096 UTF-8 bytes.]"
            }
            print("Studio-status-readiness-failure:\n\(excerpt)")
        }
        XCTAssertEqual(result, .completed, file: file, line: line)
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

}
