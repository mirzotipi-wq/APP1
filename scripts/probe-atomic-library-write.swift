import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// Compile with Sources/LightingCore/*.swift; run through
/// probe_atomic_library_write.py or the commit/interruption probe driver.
/// This diagnostic never uses app storage.
@main
enum AtomicLibraryWriteProbe {
    private static let fileLimitBytes = 32 * 1024
    private static let fixtureByteCeiling = 1024 * 1024
    private struct Failure: Error { let message: String }

    private static func require(_ condition: Bool, _ message: String) throws {
        guard condition else { throw Failure(message: message) }
    }

    private static func identifier(_ namespace: UInt32, _ index: Int) -> UUID {
        UUID(uuidString: String(format: "%08x-0000-4000-8000-%012llx", namespace, UInt64(index)))!
    }

    private static func scene(_ project: Int, lights count: Int) -> LightingScene {
        let lights: [StudioLight] = (0..<count).map { (index: Int) -> StudioLight in
            let id: UUID = identifier(2, project * 12 + index)
            let x: Double = Double(index % 4) - 1.5
            let y: Double = 1.4 + Double(index % 3) * 0.3
            let z: Double = 1.2 + Double(index / 4) * 0.2
            let position: Position = Position(x: x, y: y, z: z)
            let candela: Double = Double(300 + project * 10 + index * 17)
            return StudioLight(id: id, name: "Light \(index + 1)", position: position,
                               candela: candela, kelvin: 5600)
        }
        return LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                             camera: .init(x: 0, y: 1.5, z: 3), lights: lights)
    }

    private static func fixtures() throws -> (prior: ProjectLibrary, candidate: ProjectLibrary) {
        let primary = identifier(1, 0)
        var prior = try ProjectLibrary(name: "Edited project", scene: scene(0, lights: 3), id: primary)
        try prior.create(name: "Unrelated open project", scene: scene(1, lights: 3), id: identifier(1, 1))
        try prior.create(name: "Unrelated archived project", scene: scene(2, lights: 3), id: identifier(1, 2))
        try prior.select(primary)
        try prior.archive(identifier(1, 2))

        var candidate = prior
        try candidate.rename(primary, to: "Changed before injected write")
        try candidate.updateActiveScene(scene(0, lights: 12))
        for index in 3..<ProjectLibrary.maximumProjects {
            try candidate.create(name: "Additional project \(index)", scene: scene(index, lights: 12),
                                 id: identifier(1, index))
        }
        try candidate.select(primary)
        return (try prior.validated(), try candidate.validated())
    }

    private static func encoded(_ library: ProjectLibrary) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(library)
    }

    private static func readFixture(_ name: String, root: URL) throws -> (ProjectLibrary, Data) {
        let data = try Data(contentsOf: root.appendingPathComponent(name))
        try require(data.count <= fixtureByteCeiling, "Fixture exceeds diagnostic bound")
        let library = try JSONDecoder().decode(ProjectLibrary.self, from: data).validated()
        try require(try encoded(library) == data, "Fixture is not the canonical validated encoding")
        return (library, data)
    }

    private static func errorChain(_ error: Error) -> [[String: Any]] {
        var result: [[String: Any]] = []
        var current: NSError? = error as NSError
        for _ in 0..<8 {
            guard let item = current else { break }
            result.append(["domain": item.domain, "code": item.code,
                           "description": item.localizedDescription])
            current = item.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return result
    }

    private static func run(phase: String, root: URL) throws -> [String: Any] {
        let store = ProjectLibraryFileStore(directory: root.appendingPathComponent("library", isDirectory: true))
        let control = ProjectLibraryFileStore(directory: root.appendingPathComponent("control", isDirectory: true))

        if phase == "setup" {
            try require(!FileManager.default.fileExists(atPath: store.directory.path) &&
                        !FileManager.default.fileExists(atPath: control.directory.path),
                        "Setup requires fresh diagnostic directories")
            let (prior, candidate) = try fixtures()
            let before = try encoded(prior)
            let proposed = try encoded(candidate)
            try require(before.count < fileLimitBytes && proposed.count > fileLimitBytes,
                        "Fixtures must straddle the child file-size limit")
            try require(proposed.count <= fixtureByteCeiling &&
                        before.count < ProjectLibraryFileStore.maximumBytes &&
                        proposed.count < ProjectLibraryFileStore.maximumBytes,
                        "Fixtures must remain below both diagnostic and application bounds")
            try store.save(prior, replacing: nil)
            try control.save(prior, replacing: nil)
            try require(try store.load() == prior && control.load() == prior, "Initial store reopen failed")
            try require(try Data(contentsOf: store.url) == before &&
                        Data(contentsOf: control.url) == before, "Initial store bytes differ")
            try before.write(to: root.appendingPathComponent("prior.json"))
            try proposed.write(to: root.appendingPathComponent("candidate.json"))
            return ["phase": phase, "status": "setup_complete", "priorBytes": before.count,
                    "candidateBytes": proposed.count, "fileLimitBytes": fileLimitBytes,
                    "libraryByteLimit": ProjectLibraryFileStore.maximumBytes,
                    "fixtureByteCeiling": fixtureByteCeiling,
                    "priorProjects": prior.projects.count, "candidateProjects": candidate.projects.count,
                    "candidateValidated": true, "initialReopenMatchesPrior": true]
        }

        let (prior, before) = try readFixture("prior.json", root: root)
        let (candidate, proposed) = try readFixture("candidate.json", root: root)
        try require(before.count < fileLimitBytes && proposed.count > fileLimitBytes &&
                    proposed.count < ProjectLibraryFileStore.maximumBytes,
                    "Stored fixture bounds do not permit the intended injection")

        switch phase {
        case "control":
            try require(try control.load() == prior, "Control initial snapshot mismatch")
            try control.save(candidate, replacing: prior)
            return ["phase": phase, "status": "control_saved", "saveReturnedNormally": true]
        case "inject", "save":
            try require(try store.load() == prior && Data(contentsOf: store.url) == before,
                        "Injection preflight snapshot mismatch")
            // Only this call is inside the catch that certifies a write attempt.
            // For inject, the Python owner sets RLIMIT_FSIZE and ignores
            // SIGXFSZ in this child before exec. The save phase uses the same
            // production write for a separate, witnessed rename/interruption
            // driver. A validation/CAS/setup error cannot count as success:
            // each owner additionally requires direct injection evidence.
            // Some Foundation implementations discard the underlying NSError.
            // Reset errno immediately before save and capture it before any
            // error formatting or other calls can overwrite the observation.
            errno = 0
            do {
                try store.save(candidate, replacing: prior)
                let saveErrno = errno
                var result: [String: Any] = [
                    "phase": phase,
                    "status": phase == "save" ? "save_complete" : "unexpected_save_success",
                    "writeAttempted": true,
                    "posixErrnoResetBeforeSave": true,
                    "posixErrnoImmediatelyAfterSave": saveErrno
                ]
                if phase == "save" { result["saveReturnedNormally"] = true }
                return result
            } catch {
                let saveErrno = errno
                return ["phase": phase, "status": "save_threw", "writeAttempted": true,
                        "posixErrnoResetBeforeSave": true, "posixErrnoImmediatelyAfterSave": saveErrno,
                        "errorChain": errorChain(error)]
            }
        case "verify":
            let reopened = try store.load()
            let after = try Data(contentsOf: store.url)
            let unrelated = prior.projects.filter { $0.id != prior.activeID }
            try require(unrelated.count == 2 && unrelated.contains(where: { $0.isArchived }) &&
                        unrelated.contains(where: { !$0.isArchived }), "Unrelated-record fixture mismatch")
            try require(reopened == prior && after == before, "Prior complete snapshot or bytes were lost")
            try require(reopened?.activeID == prior.activeID && unrelated.allSatisfy { record in
                reopened?.projects.first(where: { $0.id == record.id }) == record
            }, "Active identity or unrelated records changed")
            try require(try control.load() == candidate && Data(contentsOf: control.url) == proposed,
                        "Unrestricted control replacement did not survive a fresh-process reopen")
            return ["phase": phase, "status": "verification_complete",
                    "priorCompleteSnapshotPreserved": true, "priorExactBytesPreserved": true,
                    "activeIdentityPreserved": true, "unrelatedRecordsPreserved": true,
                    "unrelatedProjectIDs": unrelated.map { $0.id.uuidString },
                    "controlCandidateReopened": true, "controlExactCandidateBytes": true]
        case "verify-candidate", "verify-either":
            // Run only in a fresh, unrestricted process after the writer has
            // exited or been killed. A valid partial mixture cannot pass: both
            // the complete decoded library and every encoded byte must match
            // the same fixture. The driver selects the strict expected phase
            // from its witnessed position around the real rename.
            let reopened = try store.load()
            let after = try Data(contentsOf: store.url)
            let priorMatches = reopened == prior && after == before
            let candidateMatches = reopened == candidate && after == proposed
            if phase == "verify-candidate" {
                try require(candidateMatches, "Candidate complete snapshot or bytes were lost")
            } else {
                try require(priorMatches || candidateMatches,
                            "Reopened library is neither complete prior nor complete candidate")
            }
            let unrelated = prior.projects.filter { $0.id != prior.activeID }
            try require(unrelated.count == 2 && unrelated.contains(where: { $0.isArchived }) &&
                        unrelated.contains(where: { !$0.isArchived }), "Unrelated-record fixture mismatch")
            try require(candidate.activeID == prior.activeID && reopened?.activeID == prior.activeID,
                        "Active identity changed")
            try require(unrelated.allSatisfy { record in
                reopened?.projects.first(where: { $0.id == record.id }) == record
            }, "Unrelated records changed")
            try require(try control.load() == candidate && Data(contentsOf: control.url) == proposed,
                        "Unrestricted control replacement did not survive a fresh-process reopen")
            return ["phase": phase,
                    "status": phase == "verify-candidate"
                        ? "candidate_verification_complete" : "either_verification_complete",
                    "reopenedSnapshot": candidateMatches ? "candidate" : "prior",
                    "completeSnapshotPreserved": true, "exactBytesPreserved": true,
                    "allSnapshotRecordsPreserved": true,
                    "priorCompleteSnapshotPreserved": priorMatches,
                    "priorExactBytesPreserved": priorMatches,
                    "candidateCompleteSnapshotPreserved": candidateMatches,
                    "candidateExactBytesPreserved": candidateMatches,
                    "candidateRecordsPreserved": candidateMatches,
                    "activeIdentityPreserved": true, "unrelatedRecordsPreserved": true,
                    "unrelatedProjectIDs": unrelated.map { $0.id.uuidString },
                    "controlCandidateReopened": true, "controlExactCandidateBytes": true]
        default:
            throw Failure(message: "Unknown diagnostic phase")
        }
    }

    private static func emit(_ value: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data([0x0A]))
        } catch {
            FileHandle.standardError.write(Data("Diagnostic JSON output failed\n".utf8))
            exit(2)
        }
    }

    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 3 else {
            emit(["status": "invalid_arguments",
                  "usage": "helper setup|control|inject|verify|save|verify-candidate|verify-either OUTPUT_DIRECTORY"])
            exit(2)
        }
        do {
            emit(try run(phase: arguments[1], root: URL(fileURLWithPath: arguments[2], isDirectory: true)))
        } catch {
            emit(["phase": arguments[1], "status": "setup_or_verification_failed",
                  "errorChain": errorChain(error), "detail": String(describing: error)])
            exit(2)
        }
    }
}
