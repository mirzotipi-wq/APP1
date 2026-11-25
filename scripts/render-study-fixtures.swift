import Foundation

/// Reproduce the diagnostic images using exactly the portable renderer shipped in the app.
/// No image synthesis service, camera calibration, or photographic evidence is implied.
@main struct RenderStudyFixtures {
    private struct Fixture {
        let name: String
        let scene: LightingScene
        let subject: StudySubject
        let coverage: [String]
        let comparison: String?
        var width: Int { subject == .sphere ? 120 : 144 }
    }

    private struct Result: Encodable {
        let name: String
        let subject: String
        let renderer: String
        let coverage: [String]
        let expectedWidth: Int
        let expectedHeight: Int
        let width: Int?
        let height: Int?
        let rgbaByteCount: Int?
        let unsupportedPixels: Int?
        let unsupportedMaskByteCount: Int?
        let comparisonFixture: String?
        let differentPixelsFromComparison: Int?
        let sceneFile: String
        let ppmFile: String?
        let passed: Bool
        let validationErrors: [String]
    }

    private struct Manifest: Encodable {
        let schemaVersion = 1
        let syntheticOnly = true
        let provenance = "Original project sphere/panel and neutral mannequin geometry rendered by the portable CPU Study renderers. No photographs or external image assets."
        let sampling = "Interactive deterministic finite-emitter sampling (8 x 8 samples on fully illuminated rectangles)."
        let limitations = [
            "Software regression fixtures only; not physical calibration or photographic ground truth.",
            "Ideal direct lighting and synthetic neutral materials; not measured skin, fabric, camera response, or equipment profiles.",
            "No independent photographer, physical-device performance, or real-world comparison result is implied."
        ]
        let expectedFixtureCount = 12
        let softwareValidationPassed: Bool
        let fixtures: [Result]
    }

    static func main() {
        do {
            try renderFixtures()
        } catch {
            FileHandle.standardError.write(Data("Fixture generation failed: \(error)\n".utf8))
            exit(1)
        }
    }

    private static func renderFixtures() throws {
        guard CommandLine.arguments.count == 2 else {
            FileHandle.standardError.write(Data("Usage: render-study-fixtures <output-directory>\n".utf8))
            throw StudyError.invalidResolution
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let cases = try fixtures()
        guard cases.count == 12, Set(cases.map(\.name)).count == cases.count else {
            throw StudyError.invalidScene
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var results: [Result] = []
        var images: [String: StudyImage] = [:]
        for fixture in cases {
            let sceneFile = fixture.name + ".json"
            var study: StudyImage?
            var errors: [String] = []
            var ppmFile: String?
            var differentPixels: Int?
            do {
                try encoder.encode(fixture.scene).write(to: output.appendingPathComponent(sceneFile), options: .atomic)
                _ = try fixture.scene.validated()
                let rendered = try fixture.subject == .sphere
                    ? ReferenceStudyRenderer.render(scene: fixture.scene, width: fixture.width)
                    : PortraitStudyRenderer.render(scene: fixture.scene, width: fixture.width)
                study = rendered
                errors = validationErrors(rendered, expectedWidth: fixture.width)
                if let comparison = fixture.comparison {
                    if let previous = images[comparison],
                       previous.width == rendered.width, previous.height == rendered.height,
                       previous.rgba.count == rendered.rgba.count {
                        differentPixels = stride(from: 0, to: rendered.rgba.count, by: 4).reduce(0) {
                            $0 + (rendered.rgba[$1..<$1+4] != previous.rgba[$1..<$1+4] ? 1 : 0)
                        }
                        if differentPixels == 0 { errors.append("Expected visible change from \(comparison), but every pixel is identical.") }
                    } else {
                        errors.append("Comparison fixture \(comparison) is unavailable or has incompatible dimensions.")
                    }
                }
                // Preserve diagnostic pixels even for an unsupported-surface failure.
                // Malformed dimensions or storage cannot safely produce a PPM.
                if rendered.width == fixture.width, rendered.height == fixture.width * 2 / 3,
                   rendered.rgba.count == rendered.width * rendered.height * 4 {
                    var ppm = Data("P6\n\(rendered.width) \(rendered.height)\n255\n".utf8)
                    let pixels = [UInt8](rendered.rgba)
                    for i in stride(from: 0, to: pixels.count, by: 4) {
                        ppm.append(contentsOf: pixels[i...i+2])
                    }
                    let name = fixture.name + ".ppm"
                    try ppm.write(to: output.appendingPathComponent(name), options: .atomic)
                    ppmFile = name
                }
                if errors.isEmpty { images[fixture.name] = rendered }
            } catch {
                errors.append("Rendering or artifact write failed: \(error)")
            }
            results.append(.init(name: fixture.name,
                                 subject: fixture.subject == .sphere ? "sphere" : "neutral-mannequin",
                                 renderer: fixture.subject == .sphere ? "ReferenceStudyRenderer" : "PortraitStudyRenderer",
                                 coverage: fixture.coverage,
                                 expectedWidth: fixture.width, expectedHeight: fixture.width * 2 / 3,
                                 width: study?.width, height: study?.height,
                                 rgbaByteCount: study?.rgba.count, unsupportedPixels: study?.unsupportedPixels,
                                 unsupportedMaskByteCount: study?.unsupportedPixelMask.count,
                                 comparisonFixture: fixture.comparison, differentPixelsFromComparison: differentPixels,
                                 sceneFile: sceneFile, ppmFile: ppmFile,
                                 passed: errors.isEmpty, validationErrors: errors))
            if let study {
                print("\(fixture.name): \(study.width)×\(study.height), unsupported pixels \(study.unsupportedPixels)")
            }
            for error in errors {
                FileHandle.standardError.write(Data("Invalid fixture: \(fixture.name): \(error)\n".utf8))
            }
        }
        let passed = results.allSatisfy(\.passed)
        // No timestamp or absolute paths: repeated runs produce identical scene JSON,
        // image bytes and manifests when the renderer and toolchain are unchanged.
        try encoder.encode(Manifest(softwareValidationPassed: passed, fixtures: results))
            .write(to: output.appendingPathComponent("manifest.json"), options: .atomic)
        guard passed else { throw StudyError.invalidSurface }
    }

    private static func validationErrors(_ image: StudyImage, expectedWidth: Int) -> [String] {
        let expectedHeight = expectedWidth * 2 / 3
        let count = expectedWidth * expectedHeight
        var errors: [String] = []
        if image.width != expectedWidth || image.height != expectedHeight {
            errors.append("Unexpected dimensions; expected \(expectedWidth)×\(expectedHeight).")
        }
        if image.rgba.count != count * 4 {
            errors.append("Malformed RGBA byte count.")
        } else if stride(from: 3, to: image.rgba.count, by: 4).contains(where: { image.rgba[$0] != 255 }) {
            errors.append("Study pixels must be opaque RGBA8.")
        }
        if image.unsupportedPixelMask.count != count || !image.unsupportedPixelMask.allSatisfy({ $0 == 0 || $0 == 1 }) {
            errors.append("Malformed unsupported-pixel mask.")
        }
        let flagged = image.unsupportedPixelMask.reduce(0) { $0 + ($1 == 1 ? 1 : 0) }
        if image.unsupportedPixels != flagged { errors.append("Unsupported-pixel count and mask disagree.") }
        if image.unsupportedPixels != 0 { errors.append("Unsupported surface pixels: \(image.unsupportedPixels).") }
        return errors
    }

    private static func fixtures() throws -> [Fixture] {
        var soft = LightingScene.portrait()
        // IDs are not rendering inputs. Fixed identities make exported scenes
        // reproducible without changing any of the original six images.
        let lightIDs = [
            "00000000-0000-4000-8000-000000000001",
            "00000000-0000-4000-8000-000000000002",
            "00000000-0000-4000-8000-000000000003"
        ].compactMap(UUID.init(uuidString:))
        guard lightIDs.count == 3, soft.lights.count == lightIDs.count else { throw StudyError.invalidScene }
        for i in soft.lights.indices { soft.lights[i].id = lightIDs[i] }
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
        var keyOnly = hard
        keyOnly.lights = [hard.lights[0]]
        var fillOnly = soft
        fillOnly.lights = [soft.lights[1]]
        var rimOnly = bustSoft
        rimOnly.lights = [bustSoft.lights[2]]
        var rolled = bustSoft
        rolled.lights[0].optics?.rollDegrees = 90
        var lowerExposure = soft
        lowerExposure.previewSettings = .init(whiteBalanceKelvin: 5600, exposureStops: -2)
        var whiteBalance = soft
        whiteBalance.previewSettings = .init(whiteBalanceKelvin: 3200, exposureStops: 0)
        return [
            .init(name: "soft", scene: soft, subject: .sphere,
                  coverage: ["key", "fill", "rim", "soft-rectangle", "sphere-material", "panel-shadow"], comparison: nil),
            .init(name: "hard", scene: hard, subject: .sphere,
                  coverage: ["key", "fill", "rim", "hard-point", "panel-shadow"], comparison: "soft"),
            .init(name: "warm", scene: warm, subject: .sphere,
                  coverage: ["white-balance-3200K", "exposure-plus-one-stop"], comparison: "soft"),
            .init(name: "bust-soft", scene: bustSoft, subject: .bust,
                  coverage: ["key", "fill", "rim", "soft-rectangle", "neutral-head-and-clothing"], comparison: nil),
            .init(name: "bust-hard", scene: bustHard, subject: .bust,
                  coverage: ["hard-point", "facial-self-shadow"], comparison: "bust-soft"),
            .init(name: "bust-side", scene: bustSide, subject: .bust,
                  coverage: ["oblique-camera", "silhouette", "white-balance-4300K"], comparison: "bust-soft"),
            .init(name: "key-only-hard", scene: keyOnly, subject: .sphere,
                  coverage: ["key-only", "hard-point", "panel-shadow"], comparison: "hard"),
            .init(name: "fill-only-soft", scene: fillOnly, subject: .sphere,
                  coverage: ["fill-only", "soft-rectangle", "panel-shadow"], comparison: "soft"),
            .init(name: "bust-rim-only", scene: rimOnly, subject: .bust,
                  coverage: ["rim-only", "soft-rectangle", "silhouette", "facial-self-shadow"], comparison: "bust-soft"),
            .init(name: "bust-roll-90", scene: rolled, subject: .bust,
                  coverage: ["non-square-key-rectangle", "emitter-roll-90-degrees"], comparison: "bust-soft"),
            .init(name: "exposure-minus-two", scene: lowerExposure, subject: .sphere,
                  coverage: ["isolated-exposure-minus-two-stops"], comparison: "soft"),
            .init(name: "white-balance-3200", scene: whiteBalance, subject: .sphere,
                  coverage: ["isolated-white-balance-3200K"], comparison: "soft")
        ]
    }
}
