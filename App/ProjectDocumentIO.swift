import Foundation
import LightingCore
import SwiftUI
import UniformTypeIdentifiers

/// A prepared, immutable snapshot for the system file exporter. Exporting does
/// not save, switch or overwrite a project in the app's library.
struct ProjectBackupFile: FileDocument, Sendable {
    static let suggestedFilename = "Key-and-Fill-project.json"
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(project: LightingProjectDocument) throws {
        data = try project.encode()
    }

    init(configuration: ReadConfiguration) throws {
        guard configuration.file.isRegularFile,
              let contents = configuration.file.regularFileContents else {
            throw ProjectDocumentIO.ImportError.notRegularFile
        }
        // FileDocument supplies an already materialized wrapper. The app's
        // importer uses read(from:) below to bound bytes before loading them.
        _ = try LightingProjectDocument.decode(contents)
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum ProjectDocumentIO {
    enum ImportError: Error, Equatable, LocalizedError {
        case notRegularFile, unreadable

        var errorDescription: String? {
            switch self {
            case .notRegularFile:
                return "Choose a regular Key & Fill project file, not a folder or symbolic link."
            case .unreadable:
                return "The selected project file could not be opened. No saved projects have been changed."
            }
        }
    }

    /// File-provider URLs are accessed only for this operation. Cancellation
    /// propagates to the utility worker and prevents a completed result from
    /// being delivered to an already-cancelled caller.
    static func read(from url: URL) async throws -> LightingProjectDocument {
        try Task.checkCancellation()
        let cancellation = ReadCancellation()
        let worker = Task.detached(priority: .utility) {
            try readFile(from: url, cancellation: cancellation)
        }
        return try await withTaskCancellationHandler {
            let project = try await worker.value
            try Task.checkCancellation()
            return project
        } onCancel: {
            worker.cancel()
            cancellation.cancel()
        }
    }

    /// Synchronous worker shared with native file tests. It never mutates the
    /// selected file or the project library, and reads at most maximumBytes + 1.
    static func readFile(from url: URL) throws -> LightingProjectDocument {
        try readFile(from: url, cancellation: ReadCancellation())
    }

    private static func readFile(from url: URL, cancellation: ReadCancellation) throws -> LightingProjectDocument {
        try cancellation.checkCancellation()
        guard url.isFileURL else { throw ImportError.unreadable }
        let scopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if scopedAccess { url.stopAccessingSecurityScopedResource() }
        }
        // A false scope result is normal for files already inside the sandbox.
        // Keep the scope open while a provider materializes the file and while
        // the accessor reads it. Scope permission alone does not coordinate a
        // provider's outstanding writes or downloads.
        let coordinator = NSFileCoordinator(filePresenter: nil)
        try cancellation.install(coordinator)
        defer { cancellation.finish() }
        try cancellation.checkCancellation()
        var coordinationError: NSError?
        var result: Result<LightingProjectDocument, Error>?
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinatedURL in
            result = Result {
                try cancellation.checkCancellation()
                // The provider may have moved the item. Read its supplied URL;
                // do not request symbolic-link resolution from the coordinator.
                return try readCoordinatedFile(from: coordinatedURL, cancellation: cancellation)
            }
        }
        try cancellation.checkCancellation()
        if let coordinationError { throw coordinationError }
        guard let result else { throw ImportError.unreadable }
        return try result.get()
    }

    private static func readCoordinatedFile(from url: URL, cancellation: ReadCancellation) throws -> LightingProjectDocument {
        let contents: Data
        do {
            contents = try BoundedFileReader.read(from: url, maximumBytes: LightingProjectDocument.maximumBytes,
                                                  checkCancellation: cancellation.checkCancellation)
        } catch let error as BoundedFileReader.ReadError {
            switch error {
            case .tooLarge: throw LightingProjectDocument.DocumentError.tooLarge
            case .notRegularFile: throw ImportError.notRegularFile
            case .unreadable: throw ImportError.unreadable
            }
        }
        try cancellation.checkCancellation()
        let project = try LightingProjectDocument.decode(contents)
        try cancellation.checkCancellation()
        return project
    }

    /// Only cancel() crosses the coordinator's worker thread; Foundation
    /// explicitly permits that method from any thread. The lock protects its
    /// lifetime and cancellation arriving before the worker installs it.
    private final class ReadCancellation: @unchecked Sendable {
        private let lock = NSLock()
        private var coordinator: NSFileCoordinator?
        private var isCancelled = false

        func checkCancellation() throws {
            try Task.checkCancellation()
            lock.lock()
            defer { lock.unlock() }
            if isCancelled { throw CancellationError() }
        }

        func install(_ coordinator: NSFileCoordinator) throws {
            lock.lock()
            defer { lock.unlock() }
            guard !isCancelled else { throw CancellationError() }
            self.coordinator = coordinator
        }

        func cancel() {
            lock.lock()
            isCancelled = true
            let current = coordinator
            lock.unlock()
            current?.cancel()
        }

        func finish() {
            lock.lock()
            coordinator = nil
            lock.unlock()
        }
    }
}
