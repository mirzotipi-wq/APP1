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
}
