import SwiftUI
import UIKit
import XCTest
import LightingCore
@testable import KeyAndFill

@MainActor
final class ProjectNameEditorTests: XCTestCase {
    func testRejectedPasteRestoresNativeTextButCannotSubmitOldNameOnReturn() throws {
        var draft = ProjectNameDraft(initial: "Portrait setup")
        var submittedNames: [String] = []
        let field = StudioNativeTextField(frame: .zero)
        let control = StudioTextField("Name",
            text: Binding(get: { draft.text }, set: { _ = try? draft.update($0) }),
            isFocused: .constant(false),
            accessibility: .init(label: "Name", identifier: "projectNameInput"),
            returnKeyType: .done) {
                if let name = try? draft.submittedName() { submittedNames.append(name) }
            }
        field.configure(control, contentSizeCategory: .large, isEnabled: true)
        defer { field.invalidate() }
        XCTAssertTrue(draft.canSubmit)

        field.text = String(repeating: "x", count: StudioDisplayName.maximumScalars + 1)
        field.sendActions(for: .editingChanged)
        XCTAssertEqual(field.text, "Portrait setup")
        XCTAssertEqual(draft.text, "Portrait setup")
        XCTAssertTrue(draft.rejectedOversizedInput)
        XCTAssertFalse(draft.canSubmit, "The Save action must reject the preceding valid draft")
        _ = field.textFieldShouldReturn(field)
        XCTAssertTrue(submittedNames.isEmpty, "Return must not commit the restored stale name")

        field.configure(control, contentSizeCategory: .large, isEnabled: true)
        field.sendActions(for: .editingChanged)
        XCTAssertFalse(try draft.update("Portrait setup"), "An echoed restoration is not an edit")
        XCTAssertFalse(draft.canSubmit)
        _ = field.textFieldShouldReturn(field)
        XCTAssertTrue(submittedNames.isEmpty)

        field.text = "  Studio portrait  "
        field.sendActions(for: .editingChanged)
        XCTAssertFalse(draft.rejectedOversizedInput)
        XCTAssertTrue(draft.canSubmit)
        _ = field.textFieldShouldReturn(field)
        XCTAssertEqual(submittedNames, ["Studio portrait"])
    }

    func testClearAcknowledgesRejectionWithoutAllowingAnEmptySubmission() throws {
        var draft = ProjectNameDraft(initial: "Existing project")
        XCTAssertThrowsError(try draft.update(String(repeating: "x", count: 321)))
        draft.clear()
        XCTAssertEqual(draft.text, "")
        XCTAssertFalse(draft.rejectedOversizedInput)
        XCTAssertFalse(draft.canSubmit)
        XCTAssertThrowsError(try draft.submittedName()) {
            XCTAssertEqual($0 as? StudioDisplayName.NameError, .empty)
        }
        try draft.update("Existing project")
        XCTAssertEqual(try draft.submittedName(), "Existing project")
    }

    func testSingleGraphemeOversizedPasteCannotEscapeTheScalarLimit() throws {
        var draft = ProjectNameDraft(initial: "Kept")
        let paste = "e" + String(repeating: "\u{0301}", count: StudioDisplayName.maximumScalars)
        XCTAssertEqual(paste.count, 1)
        XCTAssertThrowsError(try draft.update(paste)) {
            XCTAssertEqual($0 as? StudioDisplayName.NameError, .tooLong)
        }
        XCTAssertEqual(draft.text, "Kept")
        XCTAssertFalse(draft.canSubmit)
        XCTAssertThrowsError(try draft.submittedName()) {
            XCTAssertEqual($0 as? StudioDisplayName.NameError, .tooLong)
        }
        try draft.update("Key light")
        XCTAssertEqual(try draft.submittedName(), "Key light")
    }

    func testShortenedLegacyNameStillRequiresADeliberateDifferentName() throws {
        let original = String(repeating: "A", count: 100)
        var draft = ProjectNameDraft(initial: original)
        let displayed = draft.text
        XCTAssertTrue(draft.requiresNewName)
        XCTAssertNotEqual(displayed, original)
        XCTAssertFalse(draft.canSubmit)
        XCTAssertThrowsError(try draft.submittedName())
        XCTAssertThrowsError(try draft.update(String(repeating: "B", count: 321)))
        XCTAssertFalse(try draft.update(displayed))
        XCTAssertFalse(draft.canSubmit)
        draft.clear()
        try draft.update(displayed)
        XCTAssertFalse(draft.canSubmit, "Clearing does not authorize saving a shortened original name")
        for whitespace in [" ", "\t", "\n", "\u{00a0}"] {
            try draft.update(whitespace + displayed + whitespace)
            XCTAssertFalse(draft.canSubmit, "Whitespace cannot authorize truncating a legacy name")
            XCTAssertThrowsError(try draft.submittedName())
        }
        try draft.update("Renamed legacy project")
        XCTAssertEqual(try draft.submittedName(), "Renamed legacy project")
    }
}
