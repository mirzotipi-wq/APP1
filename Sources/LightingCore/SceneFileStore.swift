import Foundation

public struct SceneFileStore: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func load() throws -> LightingScene? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size <= SceneCodec.maximumBytes else { throw SceneCodec.CodecError.tooLarge }
        return try SceneCodec.decode(Data(contentsOf: url))
    }
    public func save(_ scene: LightingScene) throws {
        _ = try load()
        let data = try SceneCodec.encode(scene)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
