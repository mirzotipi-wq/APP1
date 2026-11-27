import Foundation

public struct SceneFileStore: Sendable {
    public enum StoreError: Error, Equatable { case notRegularFile }
    public let url: URL
    public init(url: URL) { self.url = url }

    public func load() throws -> LightingScene? {
        // Missing is not the same as inaccessible or malformed. Do not authorize
        // a replacement write merely because fileExists cannot inspect a path.
        let attributes: [FileAttributeKey: Any]
        do {
            attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
            (error.code == NSFileNoSuchFileError || error.code == NSFileReadNoSuchFileError) {
            return nil
        }
        guard attributes[.type] as? FileAttributeType == .typeRegular else {
            throw StoreError.notRegularFile
        }
        guard let size = attributes[.size] as? NSNumber,
              size.uint64Value <= UInt64(SceneCodec.maximumBytes) else {
            throw SceneCodec.CodecError.tooLarge
        }

        // Also bound actual bytes read, even if the file grew after stat.
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var data = Data()
        let limit = SceneCodec.maximumBytes + 1
        while data.count < limit {
            guard let chunk = try handle.read(upToCount: min(64 * 1024, limit - data.count)),
                  !chunk.isEmpty else { break }
            data.append(chunk)
        }
        return try SceneCodec.decode(data)
    }

    public func save(_ scene: LightingScene) throws {
        _ = try load()
        let data = try SceneCodec.encode(scene)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
