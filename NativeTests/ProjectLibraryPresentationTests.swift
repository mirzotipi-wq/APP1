import Foundation
import XCTest
import LightingCore
@testable import KeyAndFill

final class ProjectLibraryPresentationTests: XCTestCase {
    private func project(_ name: String, id: UUID = UUID()) throws -> LightingProject {
        let library = try ProjectLibrary(name: name, scene: .portrait(), id: id)
        return try XCTUnwrap(library.activeProject)
    }

    func testDefaultIgnorableSuffixesCannotHideDuplicateNames() throws {
        let names = ["Studio", "Studio\u{200D}", "Studio\u{200C}", "Studio\u{FE0F}", "Studio\u{034F}"]
        let projects = try names.map { try project($0) }
        let rows = ProjectLibraryRowPresentation.make(for: projects)

        XCTAssertEqual(rows.map(\.name), names)
        XCTAssertEqual(rows.map(\.project), projects)
        XCTAssertEqual(Set(rows.compactMap(\.identifier)).count, projects.count,
                       "Studio and Studio plus a zero-width joiner must be distinguishable")
        for row in rows {
            let identifier = try XCTUnwrap(row.identifier)
            XCTAssertEqual(row.confirmationName, "\(row.name) (ID \(identifier))")
            XCTAssertEqual(row.identityValue(), "Project ID \(identifier)")
            XCTAssertEqual(row.identityValue(prefix: "Saved. "), "Saved. Project ID \(identifier)")
        }
    }

    func testDuplicateCaseWidthAndDiacriticNamesKeepTheirSpellingsAndDistinctIdentities() throws {
        let names = ["Cafe", "Cafe", "CAFE", "Ｃａｆｅ", "Café"]
        let projects = try names.map { try project($0) }
        let rows = ProjectLibraryRowPresentation.make(for: projects)

        XCTAssertEqual(rows.map(\.name), names)
        XCTAssertEqual(rows.map(\.project), projects)
        XCTAssertEqual(Set(rows.compactMap(\.identifier)).count, projects.count)
        XCTAssertEqual(Set(rows.map(\.confirmationName)).count, projects.count)
    }

    func testInvisibleOnlyLegacyNameHasReadableFallbackAndIdentityWithoutRewritingStorage() throws {
        // These names remain valid in the legacy library even though new-name
        // entry requires visible content. Presentation must retain each source.
        for name in ["\u{200D}", "\u{200C}", "\u{FE0F}", "\u{034F}\u{FE0F}",
                     "\u{2800}", "\u{2800}\u{2800}", " \u{200D}\u{2800}\u{FE0F} "] {
            let original = try project(name)
            let row = try XCTUnwrap(ProjectLibraryRowPresentation.make(for: [original]).first)
            let identifier = String(original.id.uuidString.prefix(8))

            XCTAssertEqual(row.name, "Unnamed project")
            XCTAssertEqual(row.identifier, identifier)
            XCTAssertEqual(row.confirmationName, "Unnamed project (ID \(identifier))")
            XCTAssertEqual(row.identityValue(), "Project ID \(identifier)")
            XCTAssertTrue(row.matches("unnamed"))
            XCTAssertEqual(row.project, original)
            XCTAssertEqual(Array(row.project.name.unicodeScalars), Array(original.name.unicodeScalars))
        }
    }

    func testFallbackCollisionAlsoIdentifiesTheProjectActuallyNamedUnnamedProject() throws {
        let projects = try ["\u{200D}", "Unnamed project"].map { try project($0) }
        let rows = ProjectLibraryRowPresentation.make(for: projects)

        XCTAssertEqual(rows.map(\.name), ["Unnamed project", "Unnamed project"])
        XCTAssertEqual(Set(rows.compactMap(\.identifier)).count, projects.count)
        XCTAssertEqual(rows.map(\.project), projects)
    }

    func testVisibleJoinedEmojiAndScriptsKeepTheirExactDisplayedScalars() throws {
        let names = ["Family 👩\u{200D}👩\u{200D}👧\u{200D}👦", "نورپردازی می\u{200C}شود",
                     "क्\u{200D}ष", "❤️", "e\u{0301}", "\u{2803}\u{2800}\u{2817}", "Key\u{2800}light"]
        let projects = try names.map { try project($0) }
        let rows = ProjectLibraryRowPresentation.make(for: projects)

        XCTAssertEqual(rows.count, names.count)
        for (row, name) in zip(rows, names) {
            XCTAssertEqual(Array(row.name.unicodeScalars), Array(name.unicodeScalars))
            XCTAssertEqual(Array(row.project.name.unicodeScalars), Array(name.unicodeScalars))
            XCTAssertNil(row.identifier)
        }
    }

    func testCollidingUUIDPrefixesExpandAtGroupBoundariesUntilDistinct() throws {
        let firstID = try XCTUnwrap(UUID(uuidString: "12345678-1234-1234-1234-000000000001"))
        let cases = [
            ("12345678-ABCD-1234-1234-000000000002", 13),
            ("12345678-1234-ABCD-1234-000000000002", 18),
            ("12345678-1234-1234-ABCD-000000000002", 23),
            ("12345678-1234-1234-1234-000000000002", 36)
        ]
        for (otherUUID, length) in cases {
            let otherID = try XCTUnwrap(UUID(uuidString: otherUUID))
            let projects = try [project("Studio", id: firstID), project("Studio", id: otherID)]
            let rows = ProjectLibraryRowPresentation.make(for: projects)

            XCTAssertEqual(rows.map(\.identifier), [String(firstID.uuidString.prefix(length)),
                                                   String(otherID.uuidString.prefix(length))])
            XCTAssertNotEqual(rows[0].confirmationName, rows[1].confirmationName)
        }
    }

    func testSearchKeepsIdentityComputedAgainstHiddenAndArchivedProjects() throws {
        let visibleID = try XCTUnwrap(UUID(uuidString: "12345678-1234-1234-1234-000000000001"))
        let duplicateID = try XCTUnwrap(UUID(uuidString: "ABCDEF00-0000-0000-0000-000000000001"))
        let hiddenID = try XCTUnwrap(UUID(uuidString: "12345678-1234-1234-1234-000000000002"))
        var library = try ProjectLibrary(name: "Hidden", scene: .portrait(), id: hiddenID)
        try library.create(name: "Studio", scene: .portrait(), id: visibleID)
        try library.create(name: "Studio", scene: .portrait(), id: duplicateID)
        try library.archive(hiddenID)

        let rows = ProjectLibraryRowPresentation.make(for: library.projects)
        let results = rows.filter { $0.matches("studio") }
        XCTAssertEqual(Set(results.map(\.id)), Set([visibleID, duplicateID]))
        let visible = try XCTUnwrap(results.first { $0.id == visibleID })
        XCTAssertEqual(visible.identifier, visibleID.uuidString,
                       "An archived project hidden by search still shares this UUID prefix")
        XCTAssertEqual(visible.identityValue(), "Project ID \(visibleID.uuidString)")
        XCTAssertEqual(visible.confirmationName, "Studio (ID \(visibleID.uuidString))")
        XCTAssertNil(try XCTUnwrap(rows.first { $0.id == hiddenID }).identifier)

        // Library ordering and the active search must not assign a different
        // identifier to the same project during the next presentation pass.
        let reordered = ProjectLibraryRowPresentation.make(for: Array(library.projects.reversed()))
        let repeated = try XCTUnwrap(reordered.filter { $0.matches("Studio") }.first { $0.id == visibleID })
        XCTAssertEqual(repeated.identifier, visible.identifier)
        XCTAssertEqual(repeated.confirmationName, visible.confirmationName)
        XCTAssertEqual(rows.filter { $0.matches("") }.count, rows.count)
        XCTAssertTrue(rows.filter { $0.matches("No such project") }.isEmpty)
    }

    func testUniqueOrdinaryNamesRetainExistingLabelsWithoutExtraIdentity() throws {
        let names = ["Portrait setup", "Window light", "Café session"]
        let projects = try names.map { try project($0) }
        let rows = ProjectLibraryRowPresentation.make(for: projects)

        XCTAssertEqual(rows.map(\.name), names)
        XCTAssertEqual(rows.map(\.confirmationName), names)
        XCTAssertEqual(rows.map(\.project), projects)
        for row in rows {
            XCTAssertNil(row.identifier)
            XCTAssertEqual(row.identityValue(), "")
            XCTAssertEqual(row.identityValue(prefix: "Saved. "), "")
        }
    }
}
