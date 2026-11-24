import Darwin
import Foundation
import LightingCore
import XCTest
@testable import KeyAndFill

final class ProjectDocumentIOTests: XCTestCase {
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testPreparedBackupRoundTripsThroughCoordinatedAsyncFileReaderWithoutChangingSource() async throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        var scene = LightingScene.portrait()
        scene.lights[0].candela = 1234.56789
        scene.cameraLens = .init(focalLengthMillimeters: 73.125)
        let project = try LightingProjectDocument(name: "Editable portrait", scene: scene)
        let prepared = try ProjectBackupFile(project: project)
        XCTAssertEqual(ProjectBackupFile.suggestedFilename, "Key-and-Fill-project.json")
        let file = folder.appendingPathComponent(ProjectBackupFile.suggestedFilename)
        try prepared.data.write(to: file)

        let reopened = try await ProjectDocumentIO.read(from: file)
        XCTAssertEqual(reopened, project)
        XCTAssertEqual(try Data(contentsOf: file), prepared.data)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path),
                       [ProjectBackupFile.suggestedFilename])
        // The returned value no longer relies on a source URL or open handle.
        try FileManager.default.removeItem(at: file)
        XCTAssertEqual(reopened.scene.cameraLens?.focalLengthMillimeters, 73.125)
    }

    func testOversizedFileIsRejectedBeforeReadingItsContents() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("oversized.json")
        try Data().write(to: file)
        let handle = try FileHandle(forWritingTo: file)
        try handle.truncate(atOffset: UInt64(LightingProjectDocument.maximumBytes + 1))
        try handle.close()
        XCTAssertThrowsError(try ProjectDocumentIO.readFile(from: file)) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .tooLarge)
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        XCTAssertEqual((attributes[.size] as? NSNumber)?.intValue, LightingProjectDocument.maximumBytes + 1)
    }

    func testSymbolicLinkDirectoryAndFIFOAreRejectedWithoutFollowingOrBlocking() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let bytes = try LightingProjectDocument(name: "Original", scene: .portrait()).encode()
        let source = folder.appendingPathComponent("source.json")
        try bytes.write(to: source)
        let link = folder.appendingPathComponent("linked.json")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: source)
        let fifo = folder.appendingPathComponent("pipe.json")
        XCTAssertEqual(Darwin.mkfifo(fifo.path, mode_t(0o600)), 0)
        for file in [link, folder, fifo] {
            XCTAssertThrowsError(try ProjectDocumentIO.readFile(from: file)) {
                XCTAssertEqual($0 as? ProjectDocumentIO.ImportError, .notRegularFile)
            }
        }
        XCTAssertEqual(try Data(contentsOf: source), bytes)
    }

    func testMalformedAndNonFileInputsDoNotChangeExistingBytes() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("invalid.json")
        let malformed = Data("{ invalid project".utf8)
        try malformed.write(to: file)
        XCTAssertThrowsError(try ProjectDocumentIO.readFile(from: file)) {
            XCTAssertEqual($0 as? LightingProjectDocument.DocumentError, .invalidDocument)
        }
        XCTAssertEqual(try Data(contentsOf: file), malformed)
        let remote = try XCTUnwrap(URL(string: "https://example.invalid/project.json"))
        XCTAssertThrowsError(try ProjectDocumentIO.readFile(from: remote)) {
            XCTAssertEqual($0 as? ProjectDocumentIO.ImportError, .unreadable)
        }
    }

    /// A real registered presenter lets the tests hold file coordination before
    /// its accessor starts. Releasing is sticky so a failed expectation cannot
    /// leave a late presenter callback blocked during test cleanup.
    private final class HoldingPresenter: NSObject, NSFilePresenter {
        let presentedItemURL: URL?
        let presentedItemOperationQueue: OperationQueue
        let requested: XCTestExpectation
        private let lock = NSLock()
        private var completion: ((Error?) -> Void)?
        private var released = false
        private var releaseError: Error?

        init(url: URL, requested: XCTestExpectation) {
            presentedItemURL = url
            self.requested = requested
            presentedItemOperationQueue = OperationQueue()
            presentedItemOperationQueue.maxConcurrentOperationCount = 1
            super.init()
        }

        func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
            lock.lock()
            let alreadyReleased = released
            let error = releaseError
            if !alreadyReleased { completion = completionHandler }
            lock.unlock()
            requested.fulfill()
            if alreadyReleased { completionHandler(error) }
        }

        func release(error: Error? = nil) {
            lock.lock()
            released = true
            releaseError = error
            let pending = completion
            completion = nil
            lock.unlock()
            pending?(error)
        }
    }

    func testFilePresenterCoordinationErrorIsPropagatedWithoutPublishingOrChangingSource() async throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("project.json")
        let bytes = try LightingProjectDocument(name: "Original", scene: .portrait()).encode()
        try bytes.write(to: file)
        let requested = expectation(description: "Presenter receives the coordinated read")
        let presenter = HoldingPresenter(url: file, requested: requested)
        NSFileCoordinator.addFilePresenter(presenter)
        defer {
            presenter.release()
            NSFileCoordinator.removeFilePresenter(presenter)
        }
        let operation = Task { try await ProjectDocumentIO.read(from: file) }
        await fulfillment(of: [requested], timeout: 5)
        let expected = NSError(domain: "ProjectDocumentIOTests.presenter", code: 17)
        presenter.release(error: expected)
        do {
            _ = try await operation.value
            XCTFail("A coordination error must prevent the import")
        } catch {
            XCTAssertEqual((error as NSError).domain, expected.domain)
            XCTAssertEqual((error as NSError).code, expected.code)
        }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testCancellationStopsWaitingForFilePresenterAndDoesNotPublishProject() async throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("project.json")
        let bytes = try LightingProjectDocument(name: "Original", scene: .portrait()).encode()
        try bytes.write(to: file)
        let requested = expectation(description: "Presenter holds the coordinated read")
        let presenter = HoldingPresenter(url: file, requested: requested)
        NSFileCoordinator.addFilePresenter(presenter)
        defer {
            presenter.release()
            NSFileCoordinator.removeFilePresenter(presenter)
        }
        let operation = Task { try await ProjectDocumentIO.read(from: file) }
        let finished = expectation(description: "Cancelled read finishes before the presenter releases")
        let observation = Task {
            let result = await operation.result
            finished.fulfill()
            return result
        }
        await fulfillment(of: [requested], timeout: 5)
        operation.cancel()
        await fulfillment(of: [finished], timeout: 5)
        presenter.release()
        switch await observation.value {
        case .success:
            XCTFail("A cancelled import must not return an editable project")
        case .failure(let error):
            XCTAssertTrue(error is CancellationError, "Unexpected error: \(error)")
        }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    private actor StartGate {
        private var opened = false
        private var continuation: CheckedContinuation<Void, Never>?
        func wait() async {
            if opened { return }
            await withCheckedContinuation { continuation = $0 }
        }
        func open() {
            opened = true
            continuation?.resume()
            continuation = nil
        }
    }

    func testCancelledReaderDoesNotPublishOrModifyASelectedProject() async throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("project.json")
        let bytes = try LightingProjectDocument(name: "Original", scene: .portrait()).encode()
        try bytes.write(to: file)
        for asynchronous in [true, false] {
            let gate = StartGate()
            let operation = Task {
                await gate.wait()
                if asynchronous { return try await ProjectDocumentIO.read(from: file) }
                return try ProjectDocumentIO.readFile(from: file)
            }
            operation.cancel()
            await gate.open()
            do {
                _ = try await operation.value
                XCTFail("A cancelled import must not return an editable project")
            } catch {
                XCTAssertTrue(error is CancellationError, "Unexpected error: \(error)")
            }
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
    }
}
