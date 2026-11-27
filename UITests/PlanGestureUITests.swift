import XCTest

/// Native touch delivery is intentional: session-level drag calls cannot prove
/// that SwiftUI recognizes a short gesture or permits the next recognition.
final class PlanGestureUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private struct PositionReadout: Equatable, CustomStringConvertible {
        let x: String
        let y: String
        let z: String

        var description: String { "x=\(x), y=\(y), z=\(z)" }
    }

    private func launchSelectedKey() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        waitForEnabledStudioControl(app.buttons["recipes"])
        let plan = app.buttons["viewMode-Plan"]
        revealStudioContent(plan, in: app, towardBottom: false)
        XCTAssertTrue(plan.isSelected)
        let key = app.buttons["Select Key on plan"]
        revealStudioContent(key, in: app, towardBottom: false, fullyVisible: true)
        key.tap()
        XCTAssertTrue(key.isSelected, "The real selected marker must own the drag")
        XCTAssertFalse(app.buttons["undo"].isEnabled, "Selection must not add an edit")
        XCTAssertFalse(app.buttons["redo"].isEnabled)
        return app
    }

    private func position(in app: XCUIApplication,
                          file: StaticString = #filePath, line: UInt = #line) throws -> PositionReadout {
        // The public exact-value buttons expose round-trip digits. Reading them
        // leaves the scene untouched and does not seed a synthetic gesture. The
        // inspector lives in the eager studio VStack: read its AX values without
        // scrolling the marker offscreen between consecutive gestures.
        func value(_ id: String) throws -> String {
            let value = try XCTUnwrap(app.buttons[id].snapshot().value as? String,
                                      "Missing coordinate readout: \(id)", file: file, line: line)
            XCTAssertTrue(value.hasSuffix(" m"), "The isolated launch uses metric units", file: file, line: line)
            return value
        }
        let result = try PositionReadout(x: value("lightXExact"), y: value("lightYExact"), z: value("lightZExact"))
        let attachment = XCTAttachment(string: result.description)
        attachment.name = "Plan-coordinate-readout-line-\(line)"
        attachment.lifetime = .keepAlways
        add(attachment)
        return result
    }

    private func dragSelectedKey(in app: XCUIApplication, by offset: CGVector,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let key = app.buttons["Select Key on plan"]
        revealStudioContent(key, in: app, towardBottom: false, fullyVisible: true, file: file, line: line)
        XCTAssertTrue(key.isSelected && key.isEnabled && key.isHittable, file: file, line: line)
        let start = key.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(offset)
        XCTAssertTrue(app.frame.contains(end.screenPoint), "The touch must finish inside the app", file: file, line: line)
        // Thirty-point travel clears the actual ten-point recognition threshold.
        // A short press and fast movement exercise event delivery without making
        // any assertion about the number or ordering of SwiftUI callback samples.
        start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
        waitForEnabledStudioControl(app.buttons["undo"], file: file, line: line)
        XCTAssertTrue(key.isSelected, "Moving a marker must retain selection", file: file, line: line)
    }

    private func assertMoved(_ moved: PositionReadout, from original: PositionReadout,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotEqual(moved.x, original.x, "The touch drag must change horizontal position", file: file, line: line)
        XCTAssertNotEqual(moved.z, original.z, "The touch drag must change depth", file: file, line: line)
        XCTAssertEqual(moved.y, original.y, "A Plan drag must preserve the exact height", file: file, line: line)
    }

    private func history(_ id: String, restores expected: PositionReadout, in app: XCUIApplication,
                         file: StaticString = #filePath, line: UInt = #line) throws {
        let button = app.buttons[id]
        waitForEnabledStudioControl(button, file: file, line: line)
        XCTAssertTrue(button.isHittable, file: file, line: line)
        button.tap()
        XCTAssertEqual(try position(in: app, file: file, line: line), expected,
                       "\(id) must restore every exact coordinate readout", file: file, line: line)
    }

    func testShortFastSelectedMarkerDragChangesPositionAndUndoRedoRestoresExactly() throws {
        let app = launchSelectedKey()
        let initial = try position(in: app)
        dragSelectedKey(in: app, by: CGVector(dx: 24, dy: 18))
        let moved = try position(in: app)
        assertMoved(moved, from: initial)
        XCTAssertFalse(app.buttons["redo"].isEnabled)

        try history("undo", restores: initial, in: app)
        XCTAssertFalse(app.buttons["undo"].isEnabled, "One completed drag must create exactly one undo entry")
        try history("redo", restores: moved, in: app)
        XCTAssertFalse(app.buttons["redo"].isEnabled)
    }

    func testFreshDragAfterCompletionCreatesASeparateUndoableEdit() throws {
        let app = launchSelectedKey()
        let initial = try position(in: app)
        dragSelectedKey(in: app, by: CGVector(dx: 24, dy: 18))
        let first = try position(in: app)
        assertMoved(first, from: initial)

        dragSelectedKey(in: app, by: CGVector(dx: 24, dy: -18))
        let second = try position(in: app)
        assertMoved(second, from: first)
        try history("undo", restores: first, in: app)
        try history("undo", restores: initial, in: app)
        XCTAssertFalse(app.buttons["undo"].isEnabled, "Two completed gestures must create exactly two edits")
        try history("redo", restores: first, in: app)
        try history("redo", restores: second, in: app)
        XCTAssertFalse(app.buttons["redo"].isEnabled)
    }

    func testFreshDragAfterBackgroundResumeKeepsPriorPositionAndHistory() throws {
        let app = launchSelectedKey()
        let initial = try position(in: app)
        dragSelectedKey(in: app, by: CGVector(dx: 24, dy: 18))
        let beforeBackground = try position(in: app)
        assertMoved(beforeBackground, from: initial)

        // Background the actual process without relaunching or replacing the
        // fixture. Both background states prove that it left the foreground.
        let observationStarted = ProcessInfo.processInfo.systemUptime
        var stateObservations: [(started: TimeInterval, finished: TimeInterval, state: XCUIApplication.State)] = []
        var stateObservationCount = 0
        XCUIDevice.shared.press(.home)
        let backgrounded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let started = ProcessInfo.processInfo.systemUptime - observationStarted
            let state = app.state
            let finished = ProcessInfo.processInfo.systemUptime - observationStarted
            stateObservationCount += 1
            if stateObservations.count == 32 { stateObservations.removeFirst() }
            stateObservations.append((started: started, finished: finished, state: state))
            return state == .runningBackground || state == .runningBackgroundSuspended
        }, object: app)
        let backgroundResult = XCTWaiter.wait(for: [backgrounded], timeout: 10)
        if backgroundResult != .completed {
            let elapsed = ProcessInfo.processInfo.systemUptime - observationStarted
            let lastState = stateObservations.last?.state
            let outcome: String
            if lastState == .notRunning {
                outcome = "terminated: last state was notRunning; termination cause is unknown"
            } else if lastState == .runningForeground {
                outcome = "stillForeground: last state was runningForeground"
            } else if lastState == .runningBackground || lastState == .runningBackgroundSuspended {
                outcome = "backgroundObserved: waiter did not complete despite an observed background state"
            } else {
                outcome = "noResponse: no usable state response; unknown or absent samples do not prove termination"
            }
            let samples = stateObservations.map { sample in
                "readStarted=\(sample.started)s, readFinished=\(sample.finished)s, " +
                    "state=\(sample.state) (raw=\(sample.state.rawValue))"
            }.joined(separator: "\n")
            let description = "Outcome: \(outcome)\nWaiter result: \(backgroundResult)\n" +
                "Configured wait: 10s; elapsed since before Home: \(elapsed)s (monotonic uptime)\n" +
                "Completed state reads: \(stateObservationCount); retained latest \(stateObservations.count) (maximum 32)\n" +
                samples
            // Retain actual observations before optional capture requests can
            // fail. Neither capture participates in the predicate or its wait.
            print("Plan-background-state-failure:\n\(description)")
            let observation = XCTAttachment(string: description)
            observation.name = "Plan-background-state-failure"
            observation.lifetime = .keepAlways
            add(observation)
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Plan-background-state-failure-screen"
            screenshot.lifetime = .keepAlways
            add(screenshot)

            func boundedDiagnosticText(_ value: String, limit: Int) -> String {
                // Cap scalars before reflection or materializing a prefix: one
                // grapheme can contain an arbitrarily large combining cluster.
                let scalars = Array(value.unicodeScalars.prefix(limit + 1))
                let marker = " [truncated]"
                let truncated = scalars.count > limit
                let contentLimit = truncated ? limit - marker.unicodeScalars.count : limit
                var text = ""
                text.unicodeScalars.append(contentsOf: scalars.prefix(contentLimit))
                return text + (truncated ? marker : "")
            }

            let hierarchyDescription: String
            if lastState == .runningForeground {
                do {
                    // One throwable snapshot; traverse its immutable children
                    // locally, with no extra accessibility requests or retries.
                    let snapshot = try app.snapshot()
                    var pending = [(snapshot, 0)]
                    var text = "Single snapshot, capped at 128 nodes, depth 16 and 24,000 Unicode scalars (including header and truncation marker):"
                    var scalarCount = text.unicodeScalars.count
                    var nodeCount = 0
                    let marker = "\n[diagnostic text truncated]"
                    while let (node, depth) = pending.popLast(), nodeCount < 128 {
                        nodeCount += 1
                        let line = String(repeating: "  ", count: depth) +
                            "type=\(node.elementType.rawValue), " +
                            "identifier=\(String(reflecting: boundedDiagnosticText(node.identifier, limit: 256))), " +
                            "label=\(String(reflecting: boundedDiagnosticText(node.label, limit: 512))), frame=\(node.frame)"
                        // Reserve the marker and accumulate bounded scalars;
                        // never join an unbounded hierarchy before truncating.
                        let available = 24_000 - scalarCount - 1 - marker.unicodeScalars.count
                        guard available >= 0 else {
                            text += marker
                            break
                        }
                        let scalars = Array(line.unicodeScalars.prefix(available + 1))
                        text += "\n"
                        text.unicodeScalars.append(contentsOf: scalars.prefix(available))
                        scalarCount += 1 + min(scalars.count, available)
                        if scalars.count > available {
                            text += marker
                            break
                        }
                        let remaining = 128 - nodeCount - pending.count
                        if depth < 16 && remaining > 0 {
                            pending.append(contentsOf: node.children.prefix(remaining).reversed().map { ($0, depth + 1) })
                        }
                    }
                    hierarchyDescription = text
                } catch {
                    hierarchyDescription = "Hierarchy unavailable: \(boundedDiagnosticText(error.localizedDescription, limit: 2_000))"
                }
            } else {
                hierarchyDescription = "Hierarchy unavailable: no foreground state was returned by the last observation."
            }
            let hierarchy = XCTAttachment(string: hierarchyDescription)
            hierarchy.name = "Plan-background-state-failure-hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        XCTAssertEqual(backgroundResult, .completed)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        waitForEnabledStudioControl(app.buttons["recipes"])
        XCTAssertEqual(try position(in: app), beforeBackground)

        dragSelectedKey(in: app, by: CGVector(dx: 24, dy: -18))
        let afterResume = try position(in: app)
        assertMoved(afterResume, from: beforeBackground)
        try history("undo", restores: beforeBackground, in: app)
        try history("undo", restores: initial, in: app)
        XCTAssertFalse(app.buttons["undo"].isEnabled)
        try history("redo", restores: beforeBackground, in: app)
        try history("redo", restores: afterResume, in: app)
        XCTAssertFalse(app.buttons["redo"].isEnabled)
    }
}
