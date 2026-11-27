import Foundation

public enum SceneCodec {
    public static let maximumBytes = 1_048_576
    public enum CodecError: Error { case tooLarge }

    public static func encode(_ scene: LightingScene) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(scene.validated())
        guard data.count <= maximumBytes else { throw CodecError.tooLarge }
        return data
    }

    public static func decode(_ data: Data) throws -> LightingScene {
        guard data.count <= maximumBytes else { throw CodecError.tooLarge }
        return try JSONDecoder().decode(LightingScene.self, from: data).validated()
    }
}
