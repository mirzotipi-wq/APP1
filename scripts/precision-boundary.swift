import Foundation

/// Held-out host-kernel fixtures. These are numerical probes, not Metal or
/// physical-camera measurements, and are deliberately separate from the six
/// runtime startup fixtures. See the matching evidence report.
@main struct PrecisionBoundaryFixtures {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { throw StudyError.invalidResolution }
        let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let width = 192
        var fixtures: [(String, LightingScene)] = []
        let base = StudyValidationFixtures.all().first { $0.name == "soft" }!.scene

        for distance in [19.0, 19.999999, 20.0] {
            for focal in [85.0, 200.0] {
                var scene = base
                scene.camera = .init(x: scene.subject.x, y: scene.subject.y, z: scene.subject.z + distance)
                scene.cameraLens = .init(focalLengthMillimeters: focal)
                fixtures.append(("area-camera-\(distance)-lens-\(Int(focal))", scene))
            }
        }

        // Independent closed-form tangent angle for an axial camera. The
        // selected pixel lies exactly on the prescribed sphere silhouette.
        for distance in [1.0, 19.999999, 20.0] {
            let radius = 0.22
            let offset = distance < 2 ? 171.0 : 17.0
            let focal = 18 / Double(width) * hypot(offset, 1) * sqrt(distance * distance - radius * radius) / radius
            for multiplier in [1 - 1e-7, 1.0, 1 + 1e-7] {
                var scene = base
                scene.camera = .init(x: 0, y: 1.5, z: distance)
                scene.cameraLens = .init(focalLengthMillimeters: focal * multiplier)
                scene.lights = []
                fixtures.append(("tangent-\(distance)-scale-\(multiplier)", scene))
            }
        }

        // Place one point source immediately around the 5 cm invalid-distance
        // boundary for a known visible receiver. This probes the diagnostic
        // invalid mask independently of an aggregate RGB error threshold.
        for distance in [1.0, 20.0] {
            let focal = 200.0, radius = 0.22
            let px = -18 / Double(width) / focal, py = 12 / Double(width * 2 / 3) / focal
            let direction = unit(.init(px, py, -1))
            let origin = SIMD3<Double>(0, 0, distance)
            let b = dot(origin, direction)
            let t = -b - sqrt(b * b - dot(origin, origin) + radius * radius)
            let receiver = origin + direction * t
            let normal = unit(receiver)
            for epsilon in [-1e-4, -1e-6, -1e-8, 0.0, 1e-8, 1e-6, 1e-4] {
                var scene = base
                scene.camera = .init(x: 0, y: 1.5, z: distance)
                scene.cameraLens = .init(focalLengthMillimeters: focal)
                let source = receiver + normal * (0.05 + epsilon)
                scene.lights = [.init(name: "Near-boundary probe",
                                     position: .init(x: source.x, y: source.y + 1.5, z: source.z),
                                     candela: 100, kelvin: 5600)]
                fixtures.append(("near-mask-camera-\(distance)-epsilon-\(epsilon)", scene))
            }
        }

        for distance in [19.999999, 20.0] {
            var scene = base
            scene.camera = .init(x: 0.8, y: 1.7, z: 2.3)
            scene.lights = [.init(name: "Distant source", position: .init(x: distance, y: 1.5, z: 0),
                                  candela: 100_000, kelvin: 5600)]
            fixtures.append(("light-distance-\(distance)", scene))
        }

        // Absolute world position is not the support rule. The packer subtracts
        // the subject in Double before converting coordinates to Float32.
        for offset in [SIMD3<Double>(77, 70, 75), SIMD3<Double>(-77, -70, -75)] {
            var scene = fixtures[5].1
            func move(_ p: Position) -> Position {
                .init(x: p.x + offset.x, y: p.y + offset.y, z: p.z + offset.z)
            }
            scene.subject = move(scene.subject)
            scene.camera = move(scene.camera)
            for index in scene.lights.indices {
                scene.lights[index].position = move(scene.lights[index].position)
                if let aim = scene.lights[index].optics?.aimTarget {
                    scene.lights[index].optics?.aimTarget = move(aim)
                }
            }
            fixtures.append(("world-translation-\(Int(offset.x))", scene))
        }

        var descriptions: [[String: Any]] = []
        for (name, inputScene) in fixtures {
            var scene = try inputScene.validated()
            for index in scene.lights.indices {
                scene.lights[index].id = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", index + 1))!
            }
            let cameraDistance = scene.camera.distance(to: scene.subject)
            let lightDistance = scene.lights.map { $0.position.distance(to: scene.subject) }.max() ?? 0
            guard cameraDistance <= 20, lightDistance <= 20 else { throw StudyError.invalidScene }
            let input = try StudyComputeInput(scene: scene, width: width)
            let image = try ReferenceStudyRenderer.render(scene: scene, width: width)
            var data = Data()
            func append(_ value: UInt32) {
                var little = value.littleEndian
                withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
            }
            for value in [input.width, input.height, input.parameters.count, input.samples.count,
                          input.areas.count, image.unsupportedPixels] { append(UInt32(value)) }
            for row in input.parameters + input.samples + input.areas {
                for value in [row.x, row.y, row.z, row.w] { append(value.bitPattern) }
            }
            data.append(image.rgba)
            try data.write(to: folder.appendingPathComponent(name + ".bin"), options: .atomic)
            try SceneCodec.encode(scene).write(to: folder.appendingPathComponent(name + ".scene.json"), options: .atomic)
            descriptions.append(["name": name, "width": width, "height": image.height,
                                 "cameraDistanceMeters": cameraDistance, "maximumLightDistanceMeters": lightDistance,
                                 "focalLengthMillimeters": scene.effectiveCameraLens.focalLengthMillimeters,
                                 "doubleUnsupportedPixels": image.unsupportedPixels])
        }
        let manifest = try JSONSerialization.data(withJSONObject: descriptions, options: [.prettyPrinted, .sortedKeys])
        try manifest.write(to: folder.appendingPathComponent("manifest.json"), options: .atomic)
        print("Prepared \(fixtures.count) held-out fixtures using Double images and actual Float32 compute buffers")
    }

    private static func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        a.x * b.x + a.y * b.y + a.z * b.z
    }
    private static func unit(_ value: SIMD3<Double>) -> SIMD3<Double> {
        value / sqrt(dot(value, value))
    }
}
