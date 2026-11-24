import Foundation
import Glibc
import LightingCore

@main
struct NamespaceProbe {
    static func main() async throws {
        var violations = 0
        for (label, environment) in [("missing", [String: String]()), ("malformed", ["KEYFILL_UI_TEST_ID": "not-a-uuid"])] {
            let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            defer { try? FileManager.default.removeItem(at: base) }
            let normal = ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill", isDirectory: true))
            let existing = try ProjectLibrary(name: "Normal user project", scene: .portrait())
            try normal.save(existing, replacing: nil)
            let originalBytes = try Data(contentsOf: normal.url)
            let worker = ProjectStore(applicationSupportDirectory: base, arguments: ["-ui-testing"], environment: environment)
            var state = ProjectLibraryOperationState()
            let loading = try state.reserve(.load, library: nil, scene: .portrait(), from: state.generation)
            let loaded = try await worker.perform(loading)
            _ = state.finish(loading)
            var edited = LightingScene.portrait()
            edited.lights[0].candela = 777
            let saving = try state.reserve(.save, library: loaded, scene: edited, from: state.generation)
            _ = try await worker.perform(saving)
            let loadedNormal = loaded == existing
            let changedNormal = try Data(contentsOf: normal.url) != originalBytes
            print("case=\(label) loadedNormalUserLibrary=\(loadedNormal) changedNormalUserFile=\(changedNormal)")
            if loadedNormal || changedNormal { violations += 1 }
        }
        print("isolationViolationCases=\(violations)")
        exit(violations == 0 ? 0 : 1)
    }
}
