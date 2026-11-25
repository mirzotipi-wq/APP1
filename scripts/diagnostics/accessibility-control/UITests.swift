import Dispatch
import Foundation
import XCTest

final class AccessibilityControlUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testStaticScreenFullAccessibilityAudit() throws {
        record("test_body_started")
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        record("launch_begin")
        app.launch()
        record("launch_returned")

        let status = app.staticTexts["control.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        XCTAssertEqual(status.label, "Ready for audit")
        let button = app.buttons["control.confirm"]
        XCTAssertTrue(button.exists)
        XCTAssertTrue(button.isEnabled)
        XCTAssertTrue(button.isHittable)
        record("screen_ready")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Accessibility-control-before-audit"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        record("before_audit_screenshot_attached")

        let previousContinueAfterFailure = continueAfterFailure
        continueAfterFailure = true
        defer { continueAfterFailure = previousContinueAfterFailure }

        var issueCount = 0
        let issueLogLimit = 32
        record("audit_begin", ["auditTypes": "all"])
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                issueCount += 1
                if issueCount <= issueLogLimit {
                    let compact = self.bounded(issue.compactDescription)
                    let detailed = self.bounded(issue.detailedDescription)
                    self.record("audit_issue", [
                        "index": String(issueCount),
                        "auditTypeRawValue": String(issue.auditType.rawValue),
                        "compactDescription": compact.text,
                        "compactDescriptionTruncated": String(compact.truncated),
                        "detailedDescription": detailed.text,
                        "detailedDescriptionTruncated": String(detailed.truncated)
                    ])
                } else if issueCount == issueLogLimit + 1 {
                    self.record("issue_log_limit", ["loggedIssueLimit": String(issueLogLimit)])
                }
                // Only diagnostic text is bounded. Every original issue remains
                // a failing XCTest issue, including those beyond the log limit.
                return false
            }
            // A returned audit can still have recorded failing XCTest issues.
            record("audit_returned", ["issueCount": String(issueCount)])
        } catch {
            let failure = error as NSError
            let description = bounded(failure.localizedDescription)
            record("audit_threw", [
                "issueCount": String(issueCount),
                "errorDomain": failure.domain,
                "errorCode": String(failure.code),
                "errorDescription": description.text,
                "errorDescriptionTruncated": String(description.truncated)
            ])
            throw error
        }
    }

    private func bounded(_ text: String) -> (text: String, truncated: Bool) {
        let byteLimit = 4_096
        let bytes = Array(text.utf8.prefix(byteLimit + 1))
        var end = min(byteLimit, bytes.count)
        if bytes.count > byteLimit {
            while end > 0 && (bytes[end] & 0xC0) == 0x80 {
                end -= 1
            }
        }
        return (String(decoding: bytes.prefix(end), as: UTF8.self), bytes.count > byteLimit)
    }

    private func record(_ phase: String, _ fields: [String: String] = [:]) {
        var record = fields
        record["phase"] = phase
        record["uptimeNanoseconds"] = String(DispatchTime.now().uptimeNanoseconds)
        do {
            let json = try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
            var line = Data("AX_CONTROL ".utf8)
            line.append(json)
            line.append(0x0A)
            // Write directly so a later timeout cannot leave markers buffered.
            FileHandle.standardOutput.write(line)
        } catch {
            FileHandle.standardOutput.write(Data("AX_CONTROL_LOG_ENCODING_FAILED\n".utf8))
        }
    }
}

