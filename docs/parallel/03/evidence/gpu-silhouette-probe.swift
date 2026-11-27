import Foundation

/// Actual shipped Swift CPU oracle for lane04's independently reported
/// Float32 silhouette boundary. Does not alter the six startup fixtures.
@main enum GPUSilhouetteProbe {
    static func main() throws {
        let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var scene = LightingScene.portrait()
        scene.subject = .init(x: 0, y: 1.5, z: 0)
        scene.camera = .init(x: 0, y: 1.5, z: 3)
        scene.cameraLens = .init(focalLengthMillimeters: 161.27198111190464)
        scene.lights = []
        let input = try StudyComputeInput(scene: scene, width: 24)
        let image = try ReferenceStudyRenderer.render(scene: scene, width: 24)
        var data = Data()
        func append(_ value: UInt32) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        for n in [input.width, input.height, input.parameters.count, input.samples.count,
                  input.areas.count, image.unsupportedPixels] { append(UInt32(n)) }
        for row in input.parameters + input.samples + input.areas {
            for v in [row.x, row.y, row.z, row.w] { append(v.bitPattern) }
        }
        var reference = [UInt8](image.rgba)
        for (pixel, flag) in image.unsupportedPixelMask.enumerated() {
            reference[4 * pixel + 3] = flag == 1 ? 0 : 255
        }
        data.append(contentsOf: reference)
        try data.write(to: folder.appendingPathComponent("silhouette-width24.bin"))
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        try encoder.encode(scene).write(to: folder.appendingPathComponent("scene.json"))
        print("width=\(image.width), height=\(image.height), unsupported=\(image.unsupportedPixels), parameterRows=\(input.parameters.count), sampleRows=\(input.samples.count), areaRows=\(input.areas.count)")
    }
}
