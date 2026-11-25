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
            // The keyboard's first Key can be zero-size Padding-Left.
            let typingKey = app.keyboards.firstMatch.keys
                .matching(NSPredicate(format: "label IN %@", ["q", "Q", "1"])).firstMatch
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                // Readiness belongs to the real keyboard. Querying the removed
                // system Continue button consumed the previous wait budget.
                // Subsequent workflows still type and assert the exact value.
                typingKey.isHittable
            }, object: typingKey)
            let result = XCTWaiter.wait(for: [ready], timeout: 10)
            if result != .completed {
                // Inspect one immutable app snapshot after the original wait.
                // Traversal and output are bounded; this never retries readiness.
                func boundedUTF8(_ value: String, limit: Int) -> (text: String, truncated: Bool) {
                    let prefix = Array(value.utf8.prefix(limit + 1))
                    var endIndex = min(limit, prefix.count)
                    if prefix.count > limit {
                        while endIndex > 0 && (prefix[endIndex] & 0xC0) == 0x80 {
                            endIndex -= 1
                        }
                    }
                    return (String(decoding: prefix.prefix(endIndex), as: UTF8.self), prefix.count > limit)
                }
                let metadata: String
                do {
                    let snapshot = try app.snapshot()
                    var pending: [(any XCUIElementSnapshot, Int)] = [(snapshot, 0)]
                    var visited = 0
                    var truncated = false
                    var lines = ["Failure-only app snapshot; selected keyboard/name-entry nodes:"]
                    while visited < 256, let (node, depth) = pending.popLast() {
                        visited += 1
                        if depth == 0 || node.elementType == .keyboard || node.elementType == .key ||
                            node.elementType == .textField || node.label == "Continue" || node.label == message {
                            let identifier = boundedUTF8(node.identifier, limit: 256).text
                            let label = boundedUTF8(node.label, limit: 256).text
                            lines.append("node: \(visited), depth: \(depth), type: \(node.elementType), " +
                                         "identifier: \(identifier), label: \(label), " +
                                         "frame: \(node.frame), isEnabled: \(node.isEnabled)")
                        }
                        let remaining = max(0, 256 - visited - pending.count)
                        let children = node.children
                        truncated = truncated || children.count > remaining
                        pending.append(contentsOf: children.prefix(remaining).reversed().map { ($0, depth + 1) })
                    }
                    lines.append("nodesVisited: \(visited), traversalTruncated: \(truncated); labels/identifiers capped at 256 UTF-8 bytes")
                    metadata = lines.joined(separator: "\n")
                } catch {
                    metadata = "keyboardSnapshotError: \(error.localizedDescription)"
                }
                let bounded = boundedUTF8(metadata, limit: 16_384)
                var excerpt = bounded.text
                if bounded.truncated {
                    excerpt += "\n[Truncated after 16,384 UTF-8 bytes.]"
                }
                print("Keyboard-introduction-readiness-failure:\n\(excerpt)")
                let state = XCTAttachment(string: excerpt)
                state.name = "Keyboard-introduction-readiness-failure"
                state.lifetime = .keepAlways
                add(state)
                let screen = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                screen.name = "Keyboard-introduction-readiness-failure-screen"
                screen.lifetime = .keepAlways
                add(screen)
            }
            XCTAssertEqual(result, .completed,
                           "The keyboard introduction must expose usable typing keys", file: file, line: line)
            return
        }
    }

    /// Hittable alone is insufficient for SwiftUI scroll content: an offscreen
    /// row can report hittable while an event lands in a sticky bar or nowhere.
    /// Only for scrolling content, never fixed navigation or edit-history buttons.
    func revealStudioContent(_ target: XCUIElement, in app: XCUIApplication,
                             towardBottom: Bool = true,
                             fullyVisible: Bool = false,
                             file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<12 {
            // Full-frame callers separately assert the real scroll-container
            // bounds. Keep a small screen margin here, then exclude observed
            // bars/keyboard below; a fixed 100pt bottom inset could make the
            // last Form footer unreachable even when it is fully visible.
            var viewport = app.frame.insetBy(dx: 0, dy: fullyVisible ? 8 : 100)
            if fullyVisible {
                // The keyboard and fixed edit bar can cover scroll content.
                // Full-frame assertions opt in; ordinary functional navigation
                // retains its established midpoint/hit-point requirement.
                // A presented sheet can leave the underlying navigation bar
                // first in the AX tree. Respect every overlapping bar so the
                // sheet's lower boundary cannot be mistaken for visible text.
                let navigationBottom = app.navigationBars.allElementsBoundByIndex
                    .map(\.frame)
                    .filter { !$0.isEmpty && $0.maxY.isFinite && $0.intersects(viewport) }
                    .map(\.maxY).max()
                if let navigationBottom {
                    let bottom = viewport.maxY
                    viewport.origin.y = max(viewport.minY, navigationBottom + 8)
                    viewport.size.height = max(0, bottom - viewport.minY)
                }
                let keyboard = app.keyboards.firstMatch
                if keyboard.exists {
                    viewport.size.height = max(0, min(viewport.maxY, keyboard.frame.minY - 8) - viewport.minY)
                }
                let undo = app.buttons["undo"]
                if undo.exists, undo.isHittable {
                    viewport.size.height = max(0, min(viewport.maxY, undo.frame.minY - 8) - viewport.minY)
                }
            }
            var down = towardBottom
            if target.exists {
                let frame = target.frame
                if !frame.isEmpty, frame.midX.isFinite, frame.midY.isFinite {
                    let contained = fullyVisible ? viewport.contains(frame)
                        : viewport.contains(CGPoint(x: frame.midX, y: frame.midY))
                    if contained, target.isHittable {
                        return
                    }
                    // Use actual position when AX provides a meaningful frame.
                    if (fullyVisible ? frame.minY : frame.midY) <= viewport.minY { down = false }
                    else if (fullyVisible ? frame.maxY : frame.midY) >= viewport.maxY { down = true }
                }
            }
            // Drag on the edge so an ordinary scroll cannot adjust a slider.
            let startY: CGFloat
            let endY: CGFloat
            if fullyVisible {
                // Keep the gesture itself above the keyboard/fixed controls.
                // A full-window drag could begin on a key instead of the Form.
                guard viewport.height >= 48, app.frame.height > 0 else { break }
                startY = (viewport.minY - app.frame.minY + viewport.height * (down ? 0.78 : 0.30)) / app.frame.height
                endY = (viewport.minY - app.frame.minY + viewport.height * (down ? 0.30 : 0.78)) / app.frame.height
            } else {
                startY = down ? 0.78 : 0.30
                endY = down ? 0.30 : 0.78
            }
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: startY))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: endY))
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
