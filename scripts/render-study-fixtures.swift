import Foundation

/// Reproduce the diagnostic images using exactly the portable renderer shipped in the app.
/// No image synthesis service, camera calibration, or photographic evidence is implied.
@main struct RenderStudyFixtures {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw StudyError.invalidResolution
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var soft = LightingScene.portrait()
        soft.camera = .init(x: 0, y: 1.66, z: 2.3)
        soft.cameraLens = .init(focalLengthMillimeters: 85)
        soft.lights[0].optics = .init(kind: .rectangle, widthMeters: 1, heightMeters: 1.2)
        soft.lights[1].optics = .init(kind: .rectangle, widthMeters: 0.8, heightMeters: 0.8)
        soft.lights[2].optics = .init(kind: .rectangle, widthMeters: 0.4, heightMeters: 0.8)
        var hard = soft
        for i in hard.lights.indices { hard.lights[i].optics = nil }
        var warm = soft
        warm.previewSettings = .init(whiteBalanceKelvin: 3200, exposureStops: 1)
        var bustSoft = soft
        bustSoft.camera = .init(x: 0, y: 1.60, z: 1.7)
        bustSoft.cameraLens = .init(focalLengthMillimeters: 85)
        // A declared closer portrait fixture, with explicit relative exposure.
        // Do not silently change a user's camera or exposure on subject switch.
        bustSoft.previewSettings = .init(whiteBalanceKelvin: 5600, exposureStops: 1.25)
        var bustHard = bustSoft
        for i in bustHard.lights.indices { bustHard.lights[i].optics = nil }
        var bustSide = bustSoft
        bustSide.camera = .init(x: 0.84, y: 1.63, z: 1.45)
        bustSide.previewSettings = .init(whiteBalanceKelvin: 4300, exposureStops: 1.25)
        let cases: [(String, LightingScene, StudySubject)] = [
            ("soft", soft, .sphere), ("hard", hard, .sphere), ("warm", warm, .sphere),
            ("bust-soft", bustSoft, .bust), ("bust-hard", bustHard, .bust), ("bust-side", bustSide, .bust)
        ]
        for (name, scene, subject) in cases {
            let study = try subject == .sphere
                ? ReferenceStudyRenderer.render(scene: scene, width: 120)
                : PortraitStudyRenderer.render(scene: scene, width: 144)
            var ppm = Data("P6\n\(study.width) \(study.height)\n255\n".utf8)
            let pixels = [UInt8](study.rgba)
            for i in stride(from: 0, to: pixels.count, by: 4) {
                ppm.append(contentsOf: pixels[i...i+2])
            }
            try ppm.write(to: output.appendingPathComponent(name + ".ppm"), options: .atomic)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(scene).write(to: output.appendingPathComponent(name + ".json"), options: .atomic)
            print("\(name): \(study.width)×\(study.height), unsupported pixels \(study.unsupportedPixels)")
            // Keep the failed render as an artifact, but fail the fixture gate.
            if study.unsupportedPixels != 0 {
                FileHandle.standardError.write(Data("Invalid fixture: \(name), \(study.unsupportedPixels) pixels\n".utf8))
                throw StudyError.invalidSurface
            }
        }
    }
}
