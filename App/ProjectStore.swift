import Foundation
import LightingCore

struct ProjectStore {
    private var url: URL {
        get throws {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("KeyAndFill", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory.appendingPathComponent("portrait.json")
        }
    }

    func load() throws -> LightingScene? {
        let file = try url
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard let size, size <= SceneCodec.maximumBytes else { throw SceneCodec.CodecError.tooLarge }
        return try SceneCodec.decode(Data(contentsOf: file))
    }

    func save(_ scene: LightingScene) throws {
        try SceneCodec.encode(scene).write(to: url, options: .atomic)
    }
}
