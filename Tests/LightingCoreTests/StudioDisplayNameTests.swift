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

    private func assertBounds(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertLessThanOrEqual(label.count, StudioDisplayName.maximumCharacters, file: file, line: line)
        XCTAssertLessThanOrEqual(label.unicodeScalars.count, StudioDisplayName.maximumScalars, file: file, line: line)
        XCTAssertLessThanOrEqual(label.utf8.count, StudioDisplayName.maximumUTF8Bytes, file: file, line: line)
    }
}
