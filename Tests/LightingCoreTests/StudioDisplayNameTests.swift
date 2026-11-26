import Foundation
import XCTest
@testable import LightingCore

final class StudioDisplayNameTests: XCTestCase {
    func testJoinedInternationalNamesSurviveActualLibraryCreationAndRoundTrip() throws {
        for input in ["نورپردازی می\u{200C}شود", "Family 👩\u{200D}👩\u{200D}👧\u{200D}👦", "Café"] {
            let name = try StudioDisplayName.newInput(input)
            let library = try ProjectLibrary(name: name, scene: .portrait())
            let encoded = try JSONEncoder().encode(library)
            let decoded = try JSONDecoder().decode(ProjectLibrary.self, from: encoded).validated()
            XCTAssertEqual(decoded.activeProject?.name, input)
        }
        XCTAssertThrowsError(try ProjectLibrary(name: "Invalid\u{202E}name", scene: .portrait()))
    }
    func testOrdinaryInternationalNamesAndJoinedEmojiArePreserved() throws {
        let names = ["Cafe\u{301} portrait", "Éclairage été", "نورپردازی", "نور\u{200C}پردازی",
                     "إضاءة البورتريه", "תאורת דיוקן", "人物照明", "👩🏽‍💻 Studio 👨‍👩‍👧‍👦"]
        for name in names {
            XCTAssertEqual(StudioDisplayName.display(name), name)
            XCTAssertEqual(try StudioDisplayName.newInput("  " + name + "  "), name)
        }
    }

    func testPathologicalSingleGraphemeIsBoundedWithoutChangingLegacyData() throws {
        let name = "A" + String(repeating: "\u{301}", count: 50_000)
        XCTAssertEqual(name.count, 1)
        let library = try ProjectLibrary(name: name, scene: .portrait())
        let encoded = try JSONEncoder().encode(library)
        let reopened = try JSONDecoder().decode(ProjectLibrary.self, from: encoded).validated()
        XCTAssertEqual(reopened.activeProject?.name, name)
        let label = StudioDisplayName.display(try XCTUnwrap(reopened.activeProject?.name))
        assertBounds(label)
        XCTAssertTrue(label.hasSuffix("…"))
        XCTAssertEqual(reopened.activeProject?.name, name)
        XCTAssertThrowsError(try StudioDisplayName.newInput(name)) {
            XCTAssertEqual($0 as? StudioDisplayName.NameError, .tooLong)
        }
    }

    func testControlsAndExplicitBidiFormattingDoNotReachLabels() throws {
        for scalar in ["\n", "\r", "\t", "\0", "\u{2028}", "\u{2029}", "\u{202E}", "\u{2066}", "\u{200F}"] {
            let name = "Key" + scalar + "light"
            XCTAssertEqual(StudioDisplayName.display(name), "Key light")
            XCTAssertThrowsError(try StudioDisplayName.newInput(name)) {
                XCTAssertEqual($0 as? StudioDisplayName.NameError, .unsupportedCharacter)
            }
        }
        XCTAssertEqual(StudioDisplayName.display("  \n  "), "")
        XCTAssertThrowsError(try StudioDisplayName.newInput("  \n  ")) {
            XCTAssertEqual($0 as? StudioDisplayName.NameError, .empty)
        }
    }

    func testExactLimitsAndEllipsisStayWithinAllBounds() throws {
        let ascii = String(repeating: "x", count: 80)
        XCTAssertEqual(try StudioDisplayName.newInput(ascii), ascii)
        XCTAssertEqual(StudioDisplayName.display(ascii), ascii)
        XCTAssertEqual(StudioDisplayName.display(ascii + "x"), String(repeating: "x", count: 79) + "…")
        let combining = "A" + String(repeating: "\u{301}", count: 319)
        XCTAssertEqual(try StudioDisplayName.newInput(combining), combining)
        XCTAssertEqual(StudioDisplayName.display(combining), combining)
        XCTAssertThrowsError(try StudioDisplayName.newInput(combining + "\u{301}"))
        for name in [ascii + "x", combining + "B", String(repeating: "👨‍👩‍👧‍👦", count: 200),
                     String(repeating: "💡", count: 500)] {
            assertBounds(StudioDisplayName.display(name))
        }
    }

    func testRequestedLimitsAreClampedAndDoNotSplitOrdinaryGraphemes() {
        XCTAssertEqual(StudioDisplayName.display("Portrait", maximumCharacters: 0), "")
        XCTAssertEqual(StudioDisplayName.display("Portrait", maximumCharacters: -1), "")
        XCTAssertEqual(StudioDisplayName.display("Portrait", maximumCharacters: 1), "…")
        XCTAssertEqual(StudioDisplayName.display("👩🏽‍💻AB", maximumCharacters: 2), "👩🏽‍💻…")
        let oversized = String(repeating: "x", count: 200)
        XCTAssertEqual(StudioDisplayName.display(oversized, maximumCharacters: Int.max).count, 80)
    }

    func testScalarCutoffNeverPublishesAPartialJoinedEmojiAfterLeadingTrim() {
        let family = "👩‍👩‍👧‍👦"
        for leadingSpaces in 1...7 {
            let original = String(repeating: " ", count: leadingSpaces) + String(repeating: family, count: 46)
            XCTAssertGreaterThan(original.unicodeScalars.count, StudioDisplayName.maximumScalars)
            let label = StudioDisplayName.display(original)
            assertBounds(label)
            XCTAssertTrue(label.hasSuffix("…"))
            XCTAssertFalse(label.dropLast().isEmpty)
            XCTAssertTrue(label.dropLast().allSatisfy { String($0) == family },
                          "A bounded label must contain complete original graphemes before its ellipsis")
        }
    }

    func testNewNamesNeedContentBeyondInvisibleFormattingCharacters() {
        let invisibleNames = ["\u{200C}", "\u{200D}", "\u{FE0F}", "\u{034F}",
                              "\u{115F}", "\u{3164}", "\u{2060}", "\u{00AD}",
                              "\u{FEFF}", "\u{E0067}", " \u{200C}\u{200D}\u{FE0F} "]
        for name in invisibleNames {
            XCTAssertThrowsError(try StudioDisplayName.newInput(name)) {
                XCTAssertEqual($0 as? StudioDisplayName.NameError, .empty)
            }
        }
    }

    func testInvisibleLegacyNamesRemainStoredButSelectTheVisibleIdentityFallback() throws {
        for name in ["\u{200C}", "\u{200D}", "\u{FE0F}", "\u{034F}\u{FE0F}"] {
            let library = try ProjectLibrary(name: name, scene: .portrait())
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try encoder.encode(library)
            let reopened = try JSONDecoder().decode(ProjectLibrary.self, from: encoded).validated()
            let project = try XCTUnwrap(reopened.activeProject)
            XCTAssertEqual(project.name, name)
            // Projects and recovery already map an empty display to "Unnamed
            // project" and include the short ID when it differs from storage.
            XCTAssertEqual(StudioDisplayName.display(project.name), "")
            XCTAssertNotEqual(StudioDisplayName.display(project.name), project.name)
            XCTAssertEqual(try encoder.encode(reopened), encoded)
        }
        // Do not scan beyond the existing scalar budget looking for a glyph.
        // The ellipsis remains truthful when the unseen suffix may be visible.
        let hiddenPrefix = String(repeating: "\u{034F}", count: 500) + "Portrait"
        XCTAssertEqual(StudioDisplayName.display(hiddenPrefix), "…")
        assertBounds(StudioDisplayName.display(hiddenPrefix))
    }

    func testInvisibleCharactersWithinVisibleScriptsAndEmojiArePreserved() throws {
        for name in ["❤️", "🏳️‍🌈", "क्‍ष", "\u{200C}نور\u{200C}", "e\u{0301}"] {
            XCTAssertEqual(try StudioDisplayName.newInput(name), name)
            XCTAssertEqual(StudioDisplayName.display(name), name)
            let library = try ProjectLibrary(name: name, scene: .portrait())
            XCTAssertEqual(library.activeProject?.name, name)
        }
    }

    func testContextualLabelsPreserveVisibleNamesAndBoundTheirFallbacks() {
        for name in ["\u{200C}", "\u{200D}", "\u{FE0F}", "\u{034F}\u{FE0F}"] {
            XCTAssertEqual(StudioDisplayName.label(name, fallback: "Unnamed project"), "Unnamed project")
            XCTAssertEqual(StudioDisplayName.label(name, fallback: "Light 2"), "Light 2")
        }
        for name in ["نور\u{200C}پردازی", "Family 👨‍👩‍👧‍👦", "e\u{0301}"] {
            XCTAssertEqual(StudioDisplayName.label(name, fallback: "Unnamed project"), name)
        }
        let fallback = "Light " + String(repeating: "💡", count: 500)
        assertBounds(StudioDisplayName.label("\u{200C}", fallback: fallback))
        XCTAssertTrue(StudioDisplayName.label("\u{200C}", fallback: fallback).hasSuffix("…"))
    }

    func testBrailleBlankAloneCannotSupplyVisibleNameContent() {
        for name in ["\u{2800}", String(repeating: "\u{2800}", count: 8),
                     " \u{200D}\u{2800}\u{FE0F}\u{2800} "] {
            XCTAssertThrowsError(try StudioDisplayName.newInput(name)) {
                XCTAssertEqual($0 as? StudioDisplayName.NameError, .empty)
            }
            XCTAssertEqual(StudioDisplayName.display(name), "")
            XCTAssertEqual(StudioDisplayName.label(name, fallback: "Unnamed project"), "Unnamed project")
        }
    }

    func testBrailleSpacingIsPreservedAndLegacyBlankNameRoundTripsUnchanged() throws {
        for name in ["\u{2803}\u{2800}\u{2817}", "Key\u{2800}light", "\u{2800}Portrait\u{2800}"] {
            XCTAssertEqual(try StudioDisplayName.newInput(name), name)
            XCTAssertEqual(StudioDisplayName.display(name), name)
        }
        let originalName = "\u{2800}\u{2800}"
        let library = try ProjectLibrary(name: originalName, scene: .portrait())
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(library)
        let reopened = try JSONDecoder().decode(ProjectLibrary.self, from: encoded).validated()
        let project = try XCTUnwrap(reopened.activeProject)
        XCTAssertEqual(project.id, library.activeProject?.id)
        XCTAssertEqual(Array(project.name.unicodeScalars), Array(originalName.unicodeScalars))
        XCTAssertEqual(StudioDisplayName.label(project.name, fallback: "Unnamed project"), "Unnamed project")
        XCTAssertEqual(try encoder.encode(reopened), encoded)
    }

    private func assertBounds(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertLessThanOrEqual(label.count, StudioDisplayName.maximumCharacters, file: file, line: line)
        XCTAssertLessThanOrEqual(label.unicodeScalars.count, StudioDisplayName.maximumScalars, file: file, line: line)
        XCTAssertLessThanOrEqual(label.utf8.count, StudioDisplayName.maximumUTF8Bytes, file: file, line: line)
    }
}
