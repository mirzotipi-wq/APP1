import Foundation
import XCTest
@testable import LightingCore

final class ProjectLibraryRecoveryFaultTests: XCTestCase {
    private let corrupt = Data([0x00, 0xFF, 0x7B, 0x22, 0x0A, 0x20])

    private func withStore(_ work: (ProjectLibraryFileStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try work(ProjectLibraryFileStore(directory: directory))
    }

    private func recoveryRoot(_ store: ProjectLibraryFileStore) -> URL {
        store.directory.appendingPathComponent("Recovery", isDirectory: true)
    }

    func testOversizedReplacementDoesNotArchiveOrChangeSourcesAndConfirmationRemainsUsable() throws {
        var scene = LightingScene.portrait()
        // The scene contract bounds graphemes, while the storage contract bounds
        // encoded bytes. This is a valid scene that reaches the real encoding
        // limit, not an invalid replacement rejected by model validation.
        scene.lights[0].name = "A" + String(repeating: "\u{0301}",
            count: ProjectLibraryFileStore.maximumBytes / 2 + 1)
        XCTAssertEqual(scene.lights[0].name.count, 1)
        let oversized = try ProjectLibrary(name: "Oversized recovery", scene: scene)
        XCTAssertNoThrow(try oversized.validated())
        XCTAssertGreaterThan(try JSONEncoder().encode(oversized).count, ProjectLibraryFileStore.maximumBytes)

        for hasLibrary in [false, true] {
            try withStore { store in
                if hasLibrary { try corrupt.write(to: store.url) }
                let legacy = Data("unreadable legacy bytes to preserve".utf8)
                try legacy.write(to: store.legacyURL)
                let observed = try store.inspectUnreadableLibrary()
                let originalNames = Set(try FileManager.default.contentsOfDirectory(atPath: store.directory.path))

                XCTAssertThrowsError(try store.recoverUnreadableLibrary(oversized, replacing: observed)) {
                    XCTAssertEqual($0 as? ProjectLibraryError, .tooLarge)
                }
                XCTAssertEqual(try store.inspectUnreadableLibrary(), observed,
                               "Rejected encoding must preserve file identities as well as original bytes")
                XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: store.directory.path)), originalNames)
                XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
                XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacy)
                if hasLibrary {
                    XCTAssertEqual(try Data(contentsOf: store.url), corrupt)
                } else {
                    XCTAssertFalse(FileManager.default.fileExists(atPath: store.url.path))
                }

                // The failure must not consume the confirmation or leave a
                // partial archive that changes the subsequent recovery result.
                let candidate = try ProjectLibrary(name: "Bounded recovery", scene: .portrait())
                let result = try store.recoverUnreadableLibrary(candidate, replacing: observed)
                XCTAssertEqual(try store.load(), candidate)
                XCTAssertEqual(try Data(contentsOf: store.legacyURL), legacy)
                XCTAssertEqual(try Data(contentsOf: result.archiveDirectory.appendingPathComponent("portrait.json")), legacy)
                let archivedLibrary = result.archiveDirectory.appendingPathComponent("projects.json")
                if hasLibrary {
                    XCTAssertEqual(try Data(contentsOf: archivedLibrary), corrupt)
                } else {
                    XCTAssertFalse(FileManager.default.fileExists(atPath: archivedLibrary.path))
                }
                XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: recoveryRoot(store).path).count, 1)
            }
        }
    }

    func testLegacyOnlyConfirmationCannotOverwriteANewlyCreatedLibrary() throws {
        try withStore { store in
            try corrupt.write(to: store.legacyURL)
            let observed = try store.inspectUnreadableLibrary()
            XCTAssertEqual(observed.fileCount, 1)
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.url.path))

            var newer = try ProjectLibrary(name: "Saved after confirmation", scene: .portrait())
            try newer.create(name: "Other saved project", scene: .portrait())
            let newerBytes = try JSONEncoder().encode(newer)
            try newerBytes.write(to: store.url)
            let candidate = try ProjectLibrary(name: "Recovery", scene: .portrait())

            XCTAssertThrowsError(try store.recoverUnreadableLibrary(candidate, replacing: observed)) {
                XCTAssertEqual($0 as? ProjectLibraryError, .staleSnapshot)
            }
            XCTAssertEqual(try Data(contentsOf: store.url), newerBytes)
            XCTAssertEqual(try store.load(), newer)
            XCTAssertEqual(try Data(contentsOf: store.legacyURL), corrupt)
            XCTAssertFalse(FileManager.default.fileExists(atPath: recoveryRoot(store).path))
            XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: store.directory.path)),
                           ["projects.json", "portrait.json"])
        }
    }
}
