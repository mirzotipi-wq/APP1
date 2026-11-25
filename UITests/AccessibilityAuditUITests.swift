import XCTest

final class AccessibilityAuditUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchLoadedPlanStudio() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["KEYFILL_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        waitForEnabledStudioControl(app.buttons["recipes"])
        let plan = app.segmentedControls["viewMode"].buttons["Plan"]
        XCTAssertTrue(plan.waitForExistence(timeout: 10))
        XCTAssertTrue(plan.isSelected, "Audit the initial Plan studio, not another preview mode")
        XCTAssertEqual(app.staticTexts["projectName"].label, "Portrait setup")
        XCTAssertEqual(app.staticTexts["projectStatus"].label, "Unsaved changes")
        XCTAssertTrue(app.staticTexts["3 lights"].exists)
        XCTAssertTrue(app.buttons["editCamera"].exists)
        return app
    }

    @MainActor
    func testInitialLoadedPlanStudioAccessibilityAudit() throws {
        let app = launchLoadedPlanStudio()
        try auditCurrentScreen(app, name: "Accessibility-initial-Plan")
    }

    @MainActor
    func testExactLightIntensityEditorAccessibilityAudit() throws {
        let app = launchLoadedPlanStudio()
        let exact = app.buttons["lightIntensityExact"]
        revealStudioContent(exact, in: app)
        waitForEnabledStudioControl(exact)
        XCTAssertEqual(exact.value as? String, "900 cd")
        exact.tap()

        let field = app.textFields["precisionValue"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Intensity"].exists)
        XCTAssertEqual(field.value as? String, "900")
        XCTAssertTrue(field.isHittable)
        let apply = app.buttons["precisionApply"]
        let cancel = app.buttons["precisionCancel"]
        waitForEnabledStudioControl(apply)
        waitForEnabledStudioControl(cancel)
        XCTAssertTrue(apply.isHittable && cancel.isHittable)
        try auditCurrentScreen(app, name: "Accessibility-exact-light-intensity")
    }

    @MainActor
    private func auditCurrentScreen(_ app: XCUIApplication, name: String) throws {
        // Preserve the actual screen before an audit can report a failure.
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name + "-before-audit"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let hierarchy = app.debugDescription
        let byteLimit = 32_768
        var excerpt = String(decoding: hierarchy.utf8.prefix(byteLimit), as: UTF8.self)
        if hierarchy.utf8.count > byteLimit {
            excerpt += "\n[AX tree truncated after 32,768 UTF-8 bytes.]\n"
        }
        let tree = XCTAttachment(string: excerpt)
        tree.name = name + "-AX-before-audit"
        tree.lifetime = .keepAlways
        add(tree)

        // Navigation remains fail-fast. Report every issue from this audit,
        // then restore the previous policy even if the audit throws.
        let previousContinueAfterFailure = continueAfterFailure
        continueAfterFailure = true
        defer { continueAfterFailure = previousContinueAfterFailure }
        var issueIndex = 0
        try app.performAccessibilityAudit(for: .all) { issue in
            issueIndex += 1
            self.attachAuditIssue(issue, name: "\(name)-AX-issue-\(issueIndex)")
            // Apple defines false as reporting the original issue as a failure.
            // Diagnostics must never filter, waive, or replace an audit failure.
            return false
        }
    }

    @MainActor
    private func attachAuditIssue(_ issue: XCUIAccessibilityAuditIssue, name: String) {
        let element = issue.element
        let details = XCTAttachment(string: [
            "auditType.rawValue: \(issue.auditType.rawValue)",
            "auditType.isContrast: \(issue.auditType.contains(.contrast))",
            "compactDescription: \(boundedAuditText(issue.compactDescription))",
            "detailedDescription: \(boundedAuditText(issue.detailedDescription))",
            "elementProvided: \(element != nil)"
        ].joined(separator: "\n"))
        details.name = name + "-details"
        details.lifetime = .keepAlways
        add(details)

        // Preserve the issue itself before attempting optional element metadata.
        // A missing element has no query/screenshot fallback. Resolve a supplied
        // element only once, then read attributes from the immutable snapshot.
        guard let element else { return }
        let metadata: String
        do {
            let snapshot = try element.snapshot()
            metadata = [
                "identifier: \(boundedAuditText(snapshot.identifier))",
                "label: \(boundedAuditText(snapshot.label))",
                "elementType: \(snapshot.elementType)",
                "frame: \(snapshot.frame)",
                "isEnabled: \(snapshot.isEnabled)",
                "isSelected: \(snapshot.isSelected)"
            ].joined(separator: "\n")
        } catch {
            // Do not let a diagnostic lookup error escape the issue handler.
            metadata = "elementSnapshotError: \(boundedAuditText(error.localizedDescription))"
        }
        let attachment = XCTAttachment(string: metadata)
        attachment.name = name + "-element"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func boundedAuditText(_ text: String) -> String {
        let byteLimit = 4_096
        let prefix = text.utf8.prefix(byteLimit + 1)
        guard prefix.count > byteLimit else { return text }
        return String(decoding: prefix.prefix(byteLimit), as: UTF8.self)
            + "\n[Truncated after 4,096 UTF-8 bytes.]"
    }
}
