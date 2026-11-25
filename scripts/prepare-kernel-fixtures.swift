import Foundation

@main struct PrepareKernelFixtures {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { throw StudyError.invalidResolution }
        let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for fixture in StudyValidationFixtures.all() {
            let width = 96
            let input = try StudyComputeInput(scene: fixture.scene, width: width)
            let image = try ReferenceStudyRenderer.render(scene: fixture.scene, width: width)
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
            // Fixture alpha preserves validity, while StudyImage.rgba stays opaque.
            guard image.unsupportedPixelMask.count == image.width * image.height else {
                throw StudyError.invalidComputeOutput
            }
            var reference = [UInt8](image.rgba)
            for (pixel, flag) in image.unsupportedPixelMask.enumerated() {
                guard flag <= 1 else { throw StudyError.invalidComputeOutput }
                reference[pixel * 4 + 3] = flag == 1 ? 0 : 255
            }
            data.append(contentsOf: reference)
            try data.write(to: folder.appendingPathComponent(fixture.name + ".bin"), options: .atomic)
        }
    }
}
