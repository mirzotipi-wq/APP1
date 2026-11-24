import XCTest

extension XCTestCase {
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
