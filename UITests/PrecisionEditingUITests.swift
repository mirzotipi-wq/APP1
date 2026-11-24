import XCTest

final class PrecisionEditingUITests: XCTestCase {
    private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
        // AX can mark an offscreen SwiftUI row as hittable. Require a finite,
        // usable onscreen center, clear of navigation and edit-history bars.
        for _ in 0..<12 {
            if target.exists {
                let frame = target.frame
                if target.isHittable, !frame.isEmpty, frame.midY.isFinite,
                   frame.midY > app.frame.minY + 100, frame.midY < app.frame.maxY - 100 {
                    return
                }
            }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.78))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.30)))
        }
        XCTFail("Exact value control was not reachable in the inspector")
    }

    private func replaceText(_ field: XCUIElement, with text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        if let current = field.value as? String {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
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
        app.buttons["undo"].tap()
        XCTAssertEqual(exact.value as? String, "900 cd")
        app.buttons["redo"].tap()
        XCTAssertEqual(exact.value as? String, "4321.5 cd")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Studio-exact-light-intensity"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.buttons["saveProject"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["recipes"].waitForExistence(timeout: 15))
        reveal(exact, in: app)
        XCTAssertEqual(exact.value as? String, "4321.5 cd")
    }
}
