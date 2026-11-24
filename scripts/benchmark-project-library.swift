import Foundation

/// Standalone diagnostic benchmark. Compile with the LightingCore sources;
/// this is not part of the app target and never accesses application storage.
@main
enum ProjectLibraryBenchmark {
    private static let measuredSamples = 5

    private struct Timing: Codable {
        let operation: String
        let samplesMilliseconds: [Double]
        let medianMilliseconds: Double
        let nearestRankP95Milliseconds: Double

        init(_ operation: String, _ samples: [Double]) {
            self.operation = operation
            samplesMilliseconds = samples
            let sorted = samples.sorted()
            medianMilliseconds = sorted[sorted.count / 2]
            nearestRankP95Milliseconds = sorted[Int(ceil(0.95 * Double(sorted.count))) - 1]
        }
    }

    private struct Workload: Codable {
        let name: String
        let projects: Int
        let lightsPerProject: Int
        let encodedBytes: Int
        let fractionOfLibraryByteLimit: Double
        let longestNameGraphemes: Int
        let longestNameScalars: Int
        let timings: [Timing]
    }

    private struct Result: Codable {
        let sampleCount: Int
        let warmupsPerOperation: Int
        let elapsedSeconds: Double
        let libraryByteLimit: Int
        let temporaryDirectoryRemoved: Bool
        let workloads: [Workload]
    }

    private enum Failure: Error { case fixture, roundTrip, size, persistedBytes }

    private static func identifier(_ namespace: UInt32, _ index: Int) -> UUID {
        UUID(uuidString: String(format: "%08x-0000-4000-8000-%012llx", namespace, UInt64(index)))!
    }

    private static func scene(project: Int, lights count: Int) -> LightingScene {
        let lights = (0..<count).map { index -> StudioLight in
            let kind: EmitterKind = index % 3 == 0 ? .point : index % 3 == 1 ? .directional : .rectangle
            return StudioLight(id: identifier(2, project * 12 + index), name: "Light \(index + 1)",
                               position: .init(x: Double(index % 4) - 1.5,
                                               y: 1.4 + Double(index % 3) * 0.3,
                                               z: 1.2 + Double(index / 4) * 0.2),
                               candela: 500 + Double(index) * 20,
                               kelvin: index % 2 == 0 ? 5600 : 4300,
                               optics: .init(kind: kind, widthMeters: 0.6, heightMeters: 0.9))
        }
        return LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                             camera: .init(x: 0, y: 1.5, z: 3), lights: lights,
                             cameraLens: .init(focalLengthMillimeters: 85),
                             previewSettings: .init(whiteBalanceKelvin: 5600, exposureStops: 0))
    }

    private static func library(projects count: Int, lights: Int, largeLegacyName: Bool = false) throws -> ProjectLibrary {
        let firstName = largeLegacyName
            ? "Legacy" + String(repeating: "\u{0301}", count: 4_000_000)
            : "Portrait 1"
        var result = try ProjectLibrary(name: firstName, scene: scene(project: 0, lights: lights),
                                        id: identifier(1, 0))
        for index in 1..<count {
            try result.create(name: "Portrait \(index + 1)", scene: scene(project: index, lights: lights),
                              id: identifier(1, index))
        }
        return result
    }

    private static func encode(_ library: ProjectLibrary) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(library)
    }

    private static func milliseconds(since start: UInt64) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
    }

    /// Verification occurs after the measured interval. Warm-up results are
    /// verified too; there are no dropped measured samples or timing cutoffs.
    private static func measure<T>(_ name: String, operation: () throws -> T,
                                   verify: (T) throws -> Void) throws -> Timing {
        var samples: [Double] = []
        for index in 0...measuredSamples {
            let start = DispatchTime.now().uptimeNanoseconds
            let value = try operation()
            let elapsed = milliseconds(since: start)
            try verify(value)
            if index > 0 { samples.append(elapsed) }
        }
        return Timing(name, samples)
    }

    private static func run(_ name: String, library: ProjectLibrary, lights: Int, directory: URL) throws -> Workload {
        let encoded = try encode(library)
        guard encoded.count <= ProjectLibraryFileStore.maximumBytes else { throw Failure.size }
        let store = ProjectLibraryFileStore(directory: directory)
        try store.save(library, replacing: nil)
        guard try Data(contentsOf: store.url) == encoded else { throw Failure.persistedBytes }

        var timings: [Timing] = []
        timings.append(try measure("JSON encode, pretty/sorted, without validation", operation: {
            try encode(library)
        }, verify: {
            guard $0 == encoded else { throw Failure.roundTrip }
        }))
        timings.append(try measure("JSON decode plus library validation", operation: {
            try JSONDecoder().decode(ProjectLibrary.self, from: encoded).validated()
        }, verify: {
            guard $0 == library else { throw Failure.roundTrip }
        }))
        timings.append(try measure("File store load, including read/decode/validation", operation: {
            try store.load()
        }, verify: {
            guard $0 == library else { throw Failure.roundTrip }
        }))

        // Every save changes a real light intensity. Prepare that proposed
        // snapshot before timing; include the store's validation, locked
        // read/compare, encoding and actual atomic file replacement in timing.
        var current = library
        var saveSamples: [Double] = []
        for index in 0...measuredSamples {
            var next = current
            guard var updated = next.activeProject?.scene, !updated.lights.isEmpty else { throw Failure.fixture }
            updated.lights[0].candela = 700 + Double(index)
            try next.updateActiveScene(updated)
            let start = DispatchTime.now().uptimeNanoseconds
            try store.save(next, replacing: current)
            let elapsed = milliseconds(since: start)
            current = next
            guard try store.load() == current,
                  try Data(contentsOf: store.url) == encode(current) else { throw Failure.persistedBytes }
            if index > 0 { saveSamples.append(elapsed) }
        }
        timings.append(Timing("File store save, validation/CAS/encode/atomic replacement", saveSamples))
        let longest = library.projects.max { $0.name.unicodeScalars.count < $1.name.unicodeScalars.count }!.name
        return Workload(name: name, projects: library.projects.count, lightsPerProject: lights,
                        encodedBytes: encoded.count,
                        fractionOfLibraryByteLimit: Double(encoded.count) / Double(ProjectLibraryFileStore.maximumBytes),
                        longestNameGraphemes: longest.count, longestNameScalars: longest.unicodeScalars.count,
                        timings: timings)
    }

    static func main() throws {
        let start = DispatchTime.now().uptimeNanoseconds
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("keyfill-storage-benchmark-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let workloads = [
            try run("one project, three lights", library: library(projects: 1, lights: 3), lights: 3,
                    directory: root.appendingPathComponent("one")),
            try run("64 projects, twelve lights each", library: library(projects: 64, lights: 12), lights: 12,
                    directory: root.appendingPathComponent("full")),
            try run("one project, approximately 8 MB legacy name", library: library(projects: 1, lights: 3, largeLegacyName: true), lights: 3,
                    directory: root.appendingPathComponent("legacy"))
        ]
        let elapsedSeconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
        try FileManager.default.removeItem(at: root)
        let result = Result(sampleCount: measuredSamples, warmupsPerOperation: 1,
                            elapsedSeconds: elapsedSeconds,
                            libraryByteLimit: ProjectLibraryFileStore.maximumBytes,
                            temporaryDirectoryRemoved: true, workloads: workloads)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let output = try encoder.encode(result)
        FileHandle.standardOutput.write(output)
        FileHandle.standardOutput.write(Data([0x0A]))
    }
}
