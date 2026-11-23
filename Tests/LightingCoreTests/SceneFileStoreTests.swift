import Foundation
import XCTest
@testable import LightingCore

final class SceneFileStoreTests: XCTestCase {
    private func withStore(_ test: (URL, SceneFileStore) throws -> Void) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("scene.json")
        try test(url, SceneFileStore(url: url))
    }

    func testMissingParentAllowsFirstSave() throws {
        try withStore { _, store in
            XCTAssertNil(try store.load())
            let scene = LightingScene.portrait()
            try store.save(scene)
            XCTAssertEqual(try store.load(), scene)
        }
    }

    func testOversizedFileRemainsUnchanged() throws {
        try withStore { url, store in
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let bytes = Data(repeating: 0x41, count: SceneCodec.maximumBytes + 1)
            try bytes.write(to: url)
            XCTAssertThrowsError(try store.load()) { XCTAssertEqual($0 as? SceneCodec.CodecError, .tooLarge) }
            XCTAssertThrowsError(try store.save(.portrait()))
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    func testDirectoryAtProjectPathIsNotMissing() throws {
        try withStore { url, store in
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            XCTAssertThrowsError(try store.load()) { XCTAssertEqual($0 as? SceneFileStore.StoreError, .notRegularFile) }
            XCTAssertThrowsError(try store.save(.portrait()))
            XCTAssertEqual(try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, true)
        }
    }

    func testSymbolicLinkIsNotAcceptedOrOverwritten() throws {
        try withStore { url, store in
            let original = url.deletingLastPathComponent().appendingPathComponent("original.json")
            let scene = LightingScene.portrait()
            try SceneFileStore(url: original).save(scene)
            try FileManager.default.createSymbolicLink(at: url, withDestinationURL: original)
            XCTAssertThrowsError(try store.load()) { XCTAssertEqual($0 as? SceneFileStore.StoreError, .notRegularFile) }
            XCTAssertThrowsError(try store.save(.portrait()))
            XCTAssertEqual(try SceneFileStore(url: original).load(), scene)
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: url.path), original.path)
        }
    }

    func testExactlyMaximumSizeValidJSONLoads() throws {
        try withStore { url, store in
            let scene = LightingScene.portrait()
            try store.save(scene)
            var bytes = try Data(contentsOf: url)
            bytes.append(Data(repeating: 0x20, count: SceneCodec.maximumBytes - bytes.count))
            try bytes.write(to: url)
            XCTAssertEqual(try store.load(), scene)
        }
    }
}
