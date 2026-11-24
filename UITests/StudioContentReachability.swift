import XCTest

extension XCTestCase {
    /// Header and toolbar buttons can exist during asynchronous initial load.
    /// Their enabled state is the editor's actual readiness boundary.
    func waitForEnabledStudioControl(_ element: XCUIElement,
                                     file: StaticString = #filePath, line: UInt = #line) {
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND enabled == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed, file: file, line: line)
    }

    /// Saving runs on the store actor. Wait for its actual committed receipt
    /// before terminating the process or starting another editing workflow.
    func waitForCommittedProject(in app: XCUIApplication,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let status = app.staticTexts["projectStatus"]
        let committed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label == %@", "Saved locally"),
            object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [committed], timeout: 10), .completed,
                       "The save must finish before this workflow continues", file: file, line: line)
    }

    /// A fresh simulator can show this iOS introduction instead of the keyboard.
    /// Identify its exact recorded copy before touching its Continue button.
    func dismissKeyboardTypingIntroduction(in app: XCUIApplication,
                                            file: StaticString = #filePath, line: UInt = #line) {
        let message = "Speed up your typing by sliding your finger across the letters to compose a word."
        for host in [app, XCUIApplication(bundleIdentifier: "com.apple.springboard")] {
            let introduction = host.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", message)).firstMatch
            guard introduction.exists else { continue }
            let proceed = host.buttons.matching(NSPredicate(format: "label == %@", "Continue")).firstMatch
            guard proceed.waitForExistence(timeout: 5) else {
                XCTFail("The identified keyboard introduction has no Continue button", file: file, line: line)
                return
            }
            proceed.tap()
            // UIKit can retain the hidden introduction in its accessibility tree.
            // Require the actual transition to usable typing keys instead.
            let typingKey = app.keyboards.firstMatch.keys.firstMatch
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (!proceed.exists || !proceed.isHittable) && typingKey.exists && typingKey.isHittable
            }, object: typingKey)
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed,
                           "The keyboard introduction must close and expose typing keys", file: file, line: line)
            return
        }
    }

    /// Hittable alone is insufficient for SwiftUI scroll content: an offscreen
    /// row can report hittable while an event lands in a sticky bar or nowhere.
    /// Only for scrolling content, never fixed navigation or edit-history buttons.
    func revealStudioContent(_ target: XCUIElement, in app: XCUIApplication,
                             towardBottom: Bool = true,
                             file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<12 {
            let viewport = app.frame.insetBy(dx: 0, dy: 100)
            var down = towardBottom
            if target.exists {
                let frame = target.frame
                if !frame.isEmpty, frame.midX.isFinite, frame.midY.isFinite {
                    if viewport.contains(CGPoint(x: frame.midX, y: frame.midY)), target.isHittable {
                        return
                    }
                    // Use actual position when AX provides a meaningful frame.
                    if frame.midY <= viewport.minY { down = false }
                    else if frame.midY >= viewport.maxY { down = true }
                }
            }
            // Drag on the edge so an ordinary scroll cannot adjust a slider.
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: down ? 0.78 : 0.30))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: down ? 0.30 : 0.78))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Unreachable-studio-content"; screenshot.lifetime = .keepAlways; add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Unreachable-studio-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        XCTFail("Scrolling content was not visibly reachable: \(target)", file: file, line: line)
    }
    /// Use the app's explicit clear affordance, not cursor-position-dependent
    /// backspaces on a localized decimal keyboard. Verify exactly what was
    /// entered before pressing Set, and require keyboard dismissal afterwards.
    func setRoomMeasurement(_ text: String, id: String, in app: XCUIApplication,
                            file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[id]
        revealStudioContent(field, in: app, file: file, line: line)
        let clear = app.buttons[id + "Clear"]
        XCTAssertTrue(clear.exists && clear.isEnabled && clear.isHittable, file: file, line: line)
        clear.tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5), file: file, line: line)
        field.tap()
        field.typeText(text)
        XCTAssertEqual(field.value as? String, text, "Exact measurement draft must be entered", file: file, line: line)
        let set = app.buttons[id + "Set"]
        XCTAssertTrue(set.isHittable, file: file, line: line)
        set.tap()
        let keyboardGone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: keyboardGone, object: app.keyboards.firstMatch)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed,
                       "Set must dismiss the numeric keyboard, including on validation failure", file: file, line: line)
    }
}
