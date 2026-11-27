import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// Compile with the current LightingCore sources and run only through
/// probe_library_recovery_failure.py. All files belong to its fresh directory;
/// the production store has no fault hooks and this helper never uses app data.
@main
enum LibraryRecoveryProbe {
    private static let fixtureByteCeiling = 1024 * 1024
    private static let originalLibrary = Data([0x00, 0xFF, 0x7B, 0x22, 0x0A, 0x20, 0x80, 0x0D])
        + Data("unreadable library original\r\n".utf8)
    private static let manager = FileManager.default
    private struct Failure: Error { let message: String }

    private static func require(_ condition: Bool, _ message: String) throws {
        guard condition else { throw Failure(message: message) }
    }

    private static func read(_ url: URL) throws -> Data {
        let attributes = try manager.attributesOfItem(atPath: url.path)
        try require(attributes[.type] as? FileAttributeType == .typeRegular,
                    "Diagnostic input must be a regular file")
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let bytes = try handle.read(upToCount: fixtureByteCeiling + 1) ?? Data()
        try require(bytes.count <= fixtureByteCeiling, "Diagnostic input exceeds its byte bound")
        return bytes
    }

    private static func encoded(_ library: ProjectLibrary) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(library)
    }

    private static func fixture() throws -> ProjectLibrary {
        let primary = UUID(uuidString: "03000000-0000-4000-8000-000000000001")!
        let secondary = UUID(uuidString: "03000000-0000-4000-8000-000000000002")!
        let light = StudioLight(id: UUID(uuidString: "03000000-0000-4000-8000-000000000003")!,
                                name: "Recovered key", position: .init(x: -1, y: 2, z: 1),
                                candela: 1234, kelvin: 5600)
        let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1.5, z: 3), lights: [light])
        var candidate = try ProjectLibrary(name: "Recovered local edit", scene: scene, id: primary)
        try candidate.create(name: "Recovery comparison", scene: scene, id: secondary)
        try candidate.select(primary)
        try candidate.archive(secondary)
        return try candidate.validated()
    }

    private static func sourceBytesMatch(_ store: ProjectLibraryFileStore,
                                         library: Data, legacy: Data) throws {
        try require(try read(store.url) == library && read(store.legacyURL) == legacy,
                    "Source library or legacy bytes changed")
    }

    private static func archives(_ store: ProjectLibraryFileStore, count: Int,
                                  library: Data, legacy: Data) throws -> [URL] {
        let root = store.directory.appendingPathComponent("Recovery", isDirectory: true)
        let attributes = try manager.attributesOfItem(atPath: root.path)
        try require(attributes[.type] as? FileAttributeType == .typeDirectory,
                    "Recovery must be a real directory")
        let entries = try manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        try require(entries.count == count, "Unexpected recovery archive count")
        for archive in entries {
            let attributes = try manager.attributesOfItem(atPath: archive.path)
            try require(attributes[.type] as? FileAttributeType == .typeDirectory,
                        "Recovery archive must be a real directory")
            let names = Set(try manager.contentsOfDirectory(atPath: archive.path))
            try require(names == ["projects.json", "portrait.json"], "Archive filenames differ")
            try require(try read(archive.appendingPathComponent("projects.json")) == library
                        && read(archive.appendingPathComponent("portrait.json")) == legacy,
                        "Recovery archive does not preserve both exact originals")
        }
        return entries
    }

    private static func unreadable(_ store: ProjectLibraryFileStore,
                                    library: Data, legacy: Data) throws -> ProjectLibraryRecoverySnapshot {
        try sourceBytesMatch(store, library: library, legacy: legacy)
        let snapshot = try store.inspectUnreadableLibrary()
        try require(snapshot.fileCount == 2 && snapshot.byteCount == library.count + legacy.count,
                    "Recovery confirmation does not cover both originals")
        return snapshot
    }

    private static func recovered(_ store: ProjectLibraryFileStore,
                                   candidate: ProjectLibrary, bytes: Data, legacy: Data) throws {
        try require(try store.load() == candidate, "Recovered library did not reopen completely")
        try sourceBytesMatch(store, library: bytes, legacy: legacy)
    }

    private static func run(phase: String, root: URL) throws -> [String: Any] {
        let store = ProjectLibraryFileStore(directory: root.appendingPathComponent("library", isDirectory: true))
        let control = ProjectLibraryFileStore(directory: root.appendingPathComponent("control", isDirectory: true))
        if phase == "setup" {
            try require(!manager.fileExists(atPath: store.directory.path)
                        && !manager.fileExists(atPath: control.directory.path),
                        "Setup requires fresh diagnostic stores")
            let candidate = try fixture()
            let candidateBytes = try encoded(candidate)
            let legacy = try SceneCodec.encode(candidate.activeProject!.scene)
            try require(candidateBytes.count < fixtureByteCeiling
                        && candidateBytes.count < ProjectLibraryFileStore.maximumBytes,
                        "Replacement fixture exceeds diagnostic or production bounds")
            try originalLibrary.write(to: root.appendingPathComponent("original-projects.bin"),
                                      options: .withoutOverwriting)
            try legacy.write(to: root.appendingPathComponent("original-portrait.json"),
                             options: .withoutOverwriting)
            try candidateBytes.write(to: root.appendingPathComponent("candidate.json"),
                                     options: .withoutOverwriting)
            for target in [store, control] {
                try manager.createDirectory(at: target.directory, withIntermediateDirectories: false)
                try originalLibrary.write(to: target.url, options: .withoutOverwriting)
                try legacy.write(to: target.legacyURL, options: .withoutOverwriting)
                _ = try unreadable(target, library: originalLibrary, legacy: legacy)
                try require(!manager.fileExists(atPath: target.directory.appendingPathComponent("Recovery").path),
                            "Inspection unexpectedly created a recovery archive")
            }
            return ["status": "setup_complete", "originalLibraryBytes": originalLibrary.count,
                    "legacyBytes": legacy.count, "candidateBytes": candidateBytes.count,
                    "libraryByteLimit": ProjectLibraryFileStore.maximumBytes,
                    "candidateValidated": true, "inspectionCreatedNoArchive": true]
        }

        let original = try read(root.appendingPathComponent("original-projects.bin"))
        let legacy = try read(root.appendingPathComponent("original-portrait.json"))
        let candidateBytes = try read(root.appendingPathComponent("candidate.json"))
        let candidate = try JSONDecoder().decode(ProjectLibrary.self, from: candidateBytes).validated()
        try require(original == originalLibrary && encoded(candidate) == candidateBytes,
                    "Original or canonical replacement fixture changed")

        switch phase {
        case "control":
            let snapshot = try unreadable(control, library: original, legacy: legacy)
            let result = try control.recoverUnreadableLibrary(candidate, replacing: snapshot)
            try require(result.library == candidate, "Control recovery result differs")
            let preserved = try archives(control, count: 1, library: original, legacy: legacy)
            try require(preserved == [result.archiveDirectory], "Control archive result differs")
            try recovered(control, candidate: candidate, bytes: candidateBytes, legacy: legacy)
            return ["status": "control_recovered", "freshConfirmationObserved": true,
                    "exactOriginalsArchived": true, "exactReplacementReopened": true]
        case "recover":
            try require(!manager.fileExists(atPath: store.directory.appendingPathComponent("Recovery").path),
                        "Injection requires a store with no earlier recovery archive")
            let snapshot = try unreadable(store, library: original, legacy: legacy)
            // The owner injects only the final projects.json rename. An archive,
            // validation, or stale-token failure cannot satisfy this narrow catch.
            errno = 0
            do {
                _ = try store.recoverUnreadableLibrary(candidate, replacing: snapshot)
                return ["status": "unexpected_recovery_success", "recoveryCallAttempted": true]
            } catch {
                let capturedErrno = errno
                try require(error as? ProjectLibraryError == .recoveryWriteFailed,
                            "Recovery failed before its final atomic write: \(error)")
                try sourceBytesMatch(store, library: original, legacy: legacy)
                let preserved = try archives(store, count: 1, library: original, legacy: legacy)
                try require(try store.inspectUnreadableLibrary() == snapshot,
                            "Failed commit changed the confirmed source identities")
                return ["status": "recovery_write_failed", "recoveryCallAttempted": true,
                        "errorCase": "recoveryWriteFailed", "errorDescription": error.localizedDescription,
                        "posixErrnoImmediatelyAfterRecovery": capturedErrno,
                        "exactSourceBytesPreserved": true, "confirmedSnapshotUnchanged": true,
                        "exactOriginalsArchived": true, "archiveDirectory": preserved[0].path]
            }
        case "verify-preserved":
            _ = try unreadable(store, library: original, legacy: legacy)
            _ = try archives(store, count: 1, library: original, legacy: legacy)
            try recovered(control, candidate: candidate, bytes: candidateBytes, legacy: legacy)
            return ["status": "preserved_verification_complete", "exactSourceBytesPreserved": true,
                    "exactOriginalsArchived": true, "freshConfirmationAvailable": true,
                    "unrestrictedControlReopened": true]
        case "retry":
            let earlier = try archives(store, count: 1, library: original, legacy: legacy)
            let snapshot = try unreadable(store, library: original, legacy: legacy)
            let result = try store.recoverUnreadableLibrary(candidate, replacing: snapshot)
            let preserved = try archives(store, count: 2, library: original, legacy: legacy)
            try require(result.library == candidate && !earlier.contains(result.archiveDirectory)
                        && preserved.contains(result.archiveDirectory) && preserved.contains(earlier[0]),
                        "Retry did not retain the old archive and create a new one")
            try recovered(store, candidate: candidate, bytes: candidateBytes, legacy: legacy)
            return ["status": "recovery_retry_complete", "freshConfirmationObserved": true,
                    "earlierArchiveRetained": true, "distinctArchiveCreated": true,
                    "exactReplacementReopened": true, "archiveDirectory": result.archiveDirectory.path]
        case "verify-recovered":
            try recovered(store, candidate: candidate, bytes: candidateBytes, legacy: legacy)
            try recovered(control, candidate: candidate, bytes: candidateBytes, legacy: legacy)
            _ = try archives(store, count: 2, library: original, legacy: legacy)
            _ = try archives(control, count: 1, library: original, legacy: legacy)
            do {
                _ = try store.inspectUnreadableLibrary()
                throw Failure(message: "Valid recovered library still authorized recovery")
            } catch let error as ProjectLibraryError {
                try require(error == .recoveryNotNeeded, "Unexpected recovered inspection error")
            }
            return ["status": "recovered_verification_complete", "exactReplacementReopened": true,
                    "exactLegacyBytesPreserved": true, "bothArchivesRetained": true,
                    "unrestrictedControlReopened": true, "recoveryNoLongerNeeded": true,
                    "activeID": candidate.activeID.uuidString, "projectCount": candidate.projects.count]
        default:
            throw Failure(message: "Unknown diagnostic phase")
        }
    }

    private static func emit(_ value: [String: Any]) {
        do {
            let bytes = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
            FileHandle.standardOutput.write(bytes + Data([0x0A]))
        } catch {
            FileHandle.standardError.write(Data("Diagnostic JSON output failed\n".utf8))
            exit(2)
        }
    }

    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 3 && arguments[2].hasPrefix("/") else {
            emit(["status": "invalid_arguments",
                  "usage": "helper setup|control|recover|verify-preserved|retry|verify-recovered ABSOLUTE_DIRECTORY"])
            exit(2)
        }
        do {
            var result = try run(phase: arguments[1],
                                 root: URL(fileURLWithPath: arguments[2], isDirectory: true))
            result["phase"] = arguments[1]
            result["processID"] = ProcessInfo.processInfo.processIdentifier
            emit(result)
        } catch {
            emit(["phase": arguments[1], "status": "setup_or_verification_failed",
                  "detail": String(describing: error)])
            exit(2)
        }
    }
}
