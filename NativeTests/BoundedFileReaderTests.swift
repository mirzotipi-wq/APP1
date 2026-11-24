import Darwin
import Foundation
import XCTest
@testable import KeyAndFill

final class BoundedFileReaderTests: XCTestCase {
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testReadsEmptyAndExactLimitFilesWithoutChangingBytes() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        for count in [0, 1, 64 * 1024 + 17] {
            let file = folder.appendingPathComponent("\(count).dat")
            let bytes = Data((0..<count).map { UInt8($0 % 251) })
            try bytes.write(to: file)
            XCTAssertEqual(try BoundedFileReader.read(from: file, maximumBytes: count), bytes)
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
    }

    func testRejectsOversizeBeforeAnyReadCheckpoint() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("oversized.dat")
        let bytes = Data(repeating: 17, count: 1025)
        try bytes.write(to: file)
        var checkpoints = 0
        XCTAssertThrowsError(try BoundedFileReader.read(from: file, maximumBytes: 1024,
                                                       checkCancellation: { checkpoints += 1 })) {
            XCTAssertEqual($0 as? BoundedFileReader.ReadError, .tooLarge)
        }
        XCTAssertEqual(checkpoints, 1, "fstat rejects size before entering the read loop")
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testRejectsSymlinksDirectoriesAndFIFOsWithoutBlocking() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("original.dat")
        let bytes = Data("original".utf8)
        try bytes.write(to: file)
        let link = folder.appendingPathComponent("link.dat")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        let fifo = folder.appendingPathComponent("pipe.dat")
        XCTAssertEqual(Darwin.mkfifo(fifo.path, mode_t(0o600)), 0)
        for url in [link, folder, fifo] {
            XCTAssertThrowsError(try BoundedFileReader.read(from: url, maximumBytes: 1024)) {
                XCTAssertEqual($0 as? BoundedFileReader.ReadError, .notRegularFile)
            }
        }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testPathReplacedBeforeOpenCannotMakeReaderFollowASymbolicLink() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let selected = folder.appendingPathComponent("selected.dat")
        let other = folder.appendingPathComponent("other.dat")
        let original = Data("selected contents".utf8)
        let unrelated = Data("unrelated contents".utf8)
        try original.write(to: selected)
        try unrelated.write(to: other)
        var replaced = false
        XCTAssertThrowsError(try BoundedFileReader.read(from: selected, maximumBytes: 1024) {
            guard !replaced else { return }
            replaced = true
            try FileManager.default.removeItem(at: selected)
            try FileManager.default.createSymbolicLink(at: selected, withDestinationURL: other)
        }) {
            XCTAssertEqual($0 as? BoundedFileReader.ReadError, .notRegularFile)
        }
        XCTAssertTrue(replaced)
        XCTAssertEqual(try Data(contentsOf: other), unrelated)
    }

    func testPathReplacementAfterOpenDoesNotRedirectTheOpenedDescriptor() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("selected.dat")
        let original = Data("original opened contents".utf8)
        let replacement = Data("new pathname contents".utf8)
        try original.write(to: file)
        var checkpoints = 0
        let contents = try BoundedFileReader.read(from: file, maximumBytes: 1024) {
            checkpoints += 1
            if checkpoints == 2 { try replacement.write(to: file, options: .atomic) }
        }
        XCTAssertEqual(contents, original)
        XCTAssertEqual(try Data(contentsOf: file), replacement)
    }

    func testGrowthAfterMetadataCheckStillHonorsTheByteLimit() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("growing.dat")
        try Data(repeating: 1, count: 4).write(to: file)
        var checkpoints = 0
        XCTAssertThrowsError(try BoundedFileReader.read(from: file, maximumBytes: 8) {
            checkpoints += 1
            if checkpoints == 2 {
                let writer = try FileHandle(forWritingTo: file)
                defer { try? writer.close() }
                try writer.seekToEnd()
                try writer.write(contentsOf: Data(repeating: 2, count: 5))
            }
        }) {
            XCTAssertEqual($0 as? BoundedFileReader.ReadError, .tooLarge)
        }
        XCTAssertEqual(try Data(contentsOf: file), Data([1, 1, 1, 1, 2, 2, 2, 2, 2]))
    }

    func testCancellationDuringReadPreservesSourceAndDoesNotReturnPartialData() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("cancel.dat")
        let bytes = Data(repeating: 23, count: 64 * 1024 + 17)
        try bytes.write(to: file)
        var checkpoints = 0
        XCTAssertThrowsError(try BoundedFileReader.read(from: file, maximumBytes: bytes.count) {
            checkpoints += 1
            if checkpoints == 3 { throw CancellationError() }
        }) {
            XCTAssertTrue($0 is CancellationError)
        }
        XCTAssertEqual(checkpoints, 3)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testCheckpointCannotSuppressActualTaskCancellation() async throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("cancelled.dat")
        let bytes = Data("unchanged".utf8)
        try bytes.write(to: file)
        let operation = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try BoundedFileReader.read(from: file, maximumBytes: 1024, checkCancellation: {})
        }
        do {
            _ = try await operation.value
            XCTFail("An additional checkpoint cannot disable task cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testInvalidLimitsMissingFilesAndNonFileURLsFailWithoutReading() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("empty.dat")
        try Data().write(to: file)
        let remote = try XCTUnwrap(URL(string: "https://example.invalid/selected.dat"))
        for (url, limit) in [(file, -1), (file, Int.max), (remote, 1024),
                             (folder.appendingPathComponent("missing.dat"), 1024)] {
            XCTAssertThrowsError(try BoundedFileReader.read(from: url, maximumBytes: limit)) {
                XCTAssertEqual($0 as? BoundedFileReader.ReadError, .unreadable)
            }
        }
    }
}
