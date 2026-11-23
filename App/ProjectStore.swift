import Foundation
import LightingCore

struct ProjectStore {
    private let store: SceneFileStore
    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var directory = base.appendingPathComponent("KeyAndFill", isDirectory: true)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            directory = base.appendingPathComponent("KeyAndFill-UITests", isDirectory: true)
        }
        #endif
        store = SceneFileStore(url: directory.appendingPathComponent("portrait.json"))
    }
    func load() throws -> LightingScene? { try store.load() }
    func save(_ scene: LightingScene) throws { try store.save(scene) }
}
