import Dispatch
import Foundation

/// Reproducible, bounded CPU diagnostics. Build with -O and run on an otherwise
/// controlled host; these measurements are not a device, Metal or 60 FPS gate.
@main struct BenchmarkStudy {
    private struct Timing: Codable {
        let samplesMilliseconds: [Double]
        let p50Milliseconds: Double
        let p95Milliseconds: Double

        init(_ values: [Double]) {
            samplesMilliseconds = values
            let sorted = values.sorted()
            func percentile(_ fraction: Double) -> Double {
                sorted[max(0, min(sorted.count - 1, Int(ceil(fraction * Double(sorted.count))) - 1))]
            }
            p50Milliseconds = percentile(0.50)
            p95Milliseconds = percentile(0.95)
        }
    }

    private struct FrameResult: Codable {
        let name: String
        let width: Int
        let height: Int
        let lightSamplesPerSurface: Int
        let warmupMilliseconds: Double
        let timing: Timing
        let unsupportedPixels: Int
        let rgbaFNV1a64: String
    }

    private struct CancellationResult: Codable {
        let name: String
        let requestedAfterMilliseconds: Double
        let finishedAfterMilliseconds: Double
        let observedAtMilliseconds: Double?
        let precedingCheckAtMilliseconds: Double?
        let deadlineToReturnMilliseconds: Double?
        let checks: Int
        let cancelled: Bool
    }

    private struct VisibilityResult: Codable {
        let name: String
        let receivers: Int
        let evaluationsPerSample: Int
        let lightSamplesPerSurface: Int
        let visibilityEnabled: Bool
        let timing: Timing
        let signalComponentSum: Double
    }

    private struct Report: Codable {
        let sourceRevision: String
        let operatingSystem: String
        let architecture: String
        let cpuModel: String
        let reportedProcessors: Int
        let reportedActiveProcessors: Int
        let optimizedBuild: Bool
        let measuredSamplesPerWorkload: Int
        let totalWorkloadMilliseconds: Double
        let fixtureDefinition: String
        let methodology: String
        let frames: [FrameResult]
        let cancellation: [CancellationResult]
        let visibility: [VisibilityResult]
    }

    private enum BenchmarkError: Error {
        case arguments, requiresOptimizedBuild, inconsistentImage, unexpectedCancellationResult, missingReceiver
    }

    private struct Receiver {
        let position: SIMD3<Double>
        let normal: SIMD3<Double>
        let geometricNormal: SIMD3<Double>
        let view: SIMD3<Double>
        let material: StudyMaterial
    }

    static func main() throws {
        guard optimizedBuild() else { throw BenchmarkError.requiresOptimizedBuild }
        var samples = 7
        var revision = "unrecorded"
        var index = 1
        while index < CommandLine.arguments.count {
            guard index + 1 < CommandLine.arguments.count else { throw BenchmarkError.arguments }
            let value = CommandLine.arguments[index + 1]
            switch CommandLine.arguments[index] {
            case "--samples":
                guard let count = Int(value), (3...21).contains(count) else { throw BenchmarkError.arguments }
                samples = count
            case "--revision":
                guard value.count == 40, value.allSatisfy({ $0.isHexDigit }) else { throw BenchmarkError.arguments }
                revision = value
            default: throw BenchmarkError.arguments
            }
            index += 2
        }

        let workloadStart = now()
        let hard = scene(area: false), soft = scene(area: true)
        var frames: [FrameResult] = []
        for subject in [StudySubject.sphere, .bust] {
            for (kind, scene) in [("point3", hard), ("area3", soft)] {
                let lightSamples = try StudyLighting(scene: scene).sampleCount
                for width in [72, 144] {
                    let start = now()
                    let warmup = try render(scene, subject, width)
                    let warmupMs = elapsed(start)
                    var times: [Double] = []
                    for _ in 0..<samples {
                        let start = now()
                        let image = try render(scene, subject, width)
                        times.append(elapsed(start))
                        guard image == warmup, image.unsupportedPixels == 0 else { throw BenchmarkError.inconsistentImage }
                    }
                    frames.append(.init(name: "\(subject.rawValue.lowercased())-\(kind)-\(width)",
                                        width: width, height: warmup.height, lightSamplesPerSurface: lightSamples,
                                        warmupMilliseconds: warmupMs, timing: Timing(times),
                                        unsupportedPixels: warmup.unsupportedPixels, rgbaFNV1a64: checksum(warmup.rgba)))
                }
            }
        }

        var crowded = soft
        crowded.lights = (0..<12).map { i in
            var light = soft.lights[i % 3]
            light.id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", i + 1))!
            light.name = "Diagnostic light \(i + 1)"
            light.candela /= 4
            return light
        }
        _ = try crowded.validated()
        var cancellation: [CancellationResult] = []
        for (name, scene) in [("bust-area3-144", soft), ("bust-area12-144", crowded)] {
            for threshold in [5.0, 25.0] {
                for _ in 0..<3 {
                    cancellation.append(try cancelProbe(name, scene, after: threshold))
                }
            }
        }

        let geometry = PortraitGeometry(center: soft.subject)
        let receivers = try receivers(for: soft, geometry: geometry)
        var visibility: [VisibilityResult] = []
        for (name, scene) in [("point3", hard), ("area3", soft)] {
            let lighting = try StudyLighting(scene: scene)
            for occluded in [false, true] {
                let operation = {
                    try receiverBatch(lighting, geometry: geometry, receivers: receivers,
                                      evaluations: 1000, visibility: occluded)
                }
                _ = try operation()
                var times: [Double] = []
                var total = 0.0
                for _ in 0..<samples {
                    let start = now()
                    total = try operation()
                    times.append(elapsed(start))
                }
                visibility.append(.init(name: "bust-\(name)-receivers", receivers: receivers.count,
                                        evaluationsPerSample: 1000, lightSamplesPerSurface: lighting.sampleCount,
                                        visibilityEnabled: occluded, timing: Timing(times), signalComponentSum: total))
            }
        }

        let process = ProcessInfo.processInfo
        let report = Report(sourceRevision: revision, operatingSystem: process.operatingSystemVersionString,
                            architecture: architecture, cpuModel: cpuModel(), reportedProcessors: process.processorCount,
                            reportedActiveProcessors: process.activeProcessorCount, optimizedBuild: true,
                            measuredSamplesPerWorkload: samples, totalWorkloadMilliseconds: elapsed(workloadStart),
                            fixtureDefinition: "No random sampling or seed: fixed midpoint quadrature and stable fixture light UUIDs. Portrait recipe; camera (0,1.60,1.7)m, 85mm full-frame lens, 5600K white balance, +1.25 stops. Point3 uses recipe point emitters. Area3 replaces them with 1x1.2m, 0.8x0.8m and 0.4x0.8m rectangles, 8x8 samples each. Area12 repeats each area light four times at one quarter intensity for cancellation only.",
                            methodology: "One warm-up per workload; monotonic wall time; nearest-rank p50/p95. Deterministic synchronous CPU renders. Cancellation uses monotonic deadlines in the real callback, not asynchronous UI scheduling. Receiver microbenchmarks omit image/color conversion and primary intersections. Short-run shared-host diagnostics, not physical-device, GPU, thermal, memory or sustained frame-rate evidence.",
                            frames: frames, cancellation: cancellation, visibility: visibility)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        FileHandle.standardOutput.write(try encoder.encode(report))
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    private static func scene(area: Bool) -> LightingScene {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 1.60, z: 1.7)
        scene.cameraLens = .init(focalLengthMillimeters: 85)
        scene.previewSettings = .init(whiteBalanceKelvin: 5600, exposureStops: 1.25)
        for index in scene.lights.indices {
            scene.lights[index].id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!
        }
        if area {
            scene.lights[0].optics = .init(kind: .rectangle, widthMeters: 1, heightMeters: 1.2)
            scene.lights[1].optics = .init(kind: .rectangle, widthMeters: 0.8, heightMeters: 0.8)
            scene.lights[2].optics = .init(kind: .rectangle, widthMeters: 0.4, heightMeters: 0.8)
        }
        return scene
    }

    private static func render(_ scene: LightingScene, _ subject: StudySubject, _ width: Int,
                               isCancelled: () -> Bool = { false }) throws -> StudyImage {
        switch subject {
        case .sphere: return try ReferenceStudyRenderer.render(scene: scene, width: width, isCancelled: isCancelled)
        case .bust: return try PortraitStudyRenderer.render(scene: scene, width: width, isCancelled: isCancelled)
        }
    }

    private static func cancelProbe(_ name: String, _ scene: LightingScene,
                                    after threshold: Double) throws -> CancellationResult {
        let start = now()
        var checks = 0, observed: Double?, preceding: Double?
        var cancelled = false
        do {
            _ = try render(scene, .bust, 144) {
                checks += 1
                let time = elapsed(start)
                if time >= threshold { observed = time; return true }
                preceding = time
                return false
            }
        } catch StudyError.cancelled {
            cancelled = true
        }
        let finished = elapsed(start)
        guard cancelled == (observed != nil) else { throw BenchmarkError.unexpectedCancellationResult }
        return .init(name: name, requestedAfterMilliseconds: threshold,
                     finishedAfterMilliseconds: finished, observedAtMilliseconds: observed,
                     precedingCheckAtMilliseconds: preceding,
                     deadlineToReturnMilliseconds: cancelled ? finished - threshold : nil,
                     checks: checks, cancelled: cancelled)
    }

    private static func receivers(for scene: LightingScene, geometry: PortraitGeometry) throws -> [Receiver] {
        guard let camera = CameraFraming(scene: scene) else { throw BenchmarkError.missingReceiver }
        let origin = vector(camera.position)
        let forward = vector(camera.forward), right = vector(camera.right), up = vector(camera.up)
        let halfW = CameraLens.sensorWidthMillimeters / (2 * camera.lens.focalLengthMillimeters)
        let halfH = CameraLens.sensorHeightMillimeters / (2 * camera.lens.focalLengthMillimeters)
        var result: [Receiver] = []
        for y in 0..<8 {
            for x in 0..<12 {
                let px = (2 * (Double(x) + 0.5) / 12 - 1) * halfW
                let py = (1 - 2 * (Double(y) + 0.5) / 8) * halfH
                let v = forward + right * px + up * py
                let direction = v / sqrt(dot(v, v))
                let minimum = CameraFraming.minimumDepthMeters / dot(direction, forward)
                if let hit = geometry.hit(origin: origin, direction: direction, minimum: minimum) {
                    result.append(.init(position: origin + direction * hit.distance, normal: hit.normal,
                                        geometricNormal: hit.geometricNormal, view: -direction,
                                        material: hit.region.material))
                }
            }
        }
        guard !result.isEmpty else { throw BenchmarkError.missingReceiver }
        return result
    }

    private static func receiverBatch(_ lighting: StudyLighting, geometry: PortraitGeometry,
                                     receivers: [Receiver], evaluations: Int, visibility: Bool) throws -> Double {
        var total = 0.0
        for i in 0..<evaluations {
            let receiver = receivers[i % receivers.count]
            let signal = try lighting.evaluate(receiver: receiver.position, normal: receiver.normal,
                                               view: receiver.view, material: receiver.material,
                                               occlusionTest: visibility ? geometry.occludes : nil,
                                               geometricNormal: receiver.geometricNormal)
            // Consume every computed output so optimization cannot omit the
            // material/color response when timing the direct-light evaluator.
            total += signal.visibleLux + signal.unoccludedLux
                + signal.signalXYZ.x + signal.signalXYZ.y + signal.signalXYZ.z
        }
        return total
    }

    private static func now() -> UInt64 { DispatchTime.now().uptimeNanoseconds }
    @inline(never) private static func optimizedBuild() -> Bool { !_isDebugAssertConfiguration() }
    private static func elapsed(_ start: UInt64) -> Double { Double(now() - start) / 1_000_000 }
    private static func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x * b.x + a.y * b.y + a.z * b.z }
    private static func vector(_ p: Position) -> SIMD3<Double> { .init(p.x, p.y, p.z) }
    private static func vector(_ d: UnitDirection) -> SIMD3<Double> { .init(d.x, d.y, d.z) }

    private static func checksum(_ data: Data) -> String {
        var hash: UInt64 = 14695981039346656037
        for byte in data { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return String(format: "%016llx", hash)
    }

    private static func cpuModel() -> String {
        guard let contents = try? String(contentsOfFile: "/proc/cpuinfo", encoding: .utf8),
              let line = contents.split(separator: "\n").first(where: { $0.hasPrefix("model name") }),
              let colon = line.firstIndex(of: ":") else { return "Not exposed by this host" }
        return line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
    }

    private static var architecture: String {
#if arch(x86_64)
        return "x86_64"
#elseif arch(arm64)
        return "arm64"
#else
        return "Other Swift target; record swiftc --version with the report"
#endif
    }
}
