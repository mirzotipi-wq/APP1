import Foundation
import LightingCore
@testable import StudioComposition

private enum ProbeError: Error { case invariant(String), timeout }
private actor ReceiptGate {
    private var entered = false
    private var released = false
    private var continuation: CheckedContinuation<Void, Never>?
    func pause() async {
        entered = true
        await withCheckedContinuation { next in
            if released { next.resume() } else { continuation = next }
        }
    }
    func awaitEntry() async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !entered {
            guard ContinuousClock.now < deadline else { throw ProbeError.timeout }
            await Task.yield()
        }
    }
    func open() {
        released = true
        continuation?.resume()
        continuation = nil
    }
}

@main struct W013Probe {
    @MainActor static var checks = 0
    @MainActor static func check(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
        checks += 1
        guard try condition() else { throw ProbeError.invariant(label) }
    }
    @MainActor static func run(switching: Bool, cancelSession: Bool) async throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("W013-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let gate = ReceiptGate()
        let store = ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:])
        let disk = ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill"))
        let first = StudioSession(store: store, execute: { request in
            let receipt = try await store.perform(request)
            if case .change = request.operation { await gate.pause() }
            return receipt
        })
        try await first.beginLibraryOperation(.load, from: first.generation).value
        var initial = first.scene
        initial.camera.x += 0.125
        try check(first.replace(initial, from: first.generation), "initial edit")
        try await first.beginLibraryOperation(.save, from: first.generation).value
        let originalID = first.library!.activeID
        let oldGeneration = first.generation
        let oldWorkspace = first.workspaceResetID
        let oldFeature = first.openFeature(.room, from: oldGeneration)!
        let command: ProjectLibraryCommand = switching
            ? .duplicate(originalID, name: "Duplicated A")
            : .rename(originalID, name: "Renamed A")
        let operation = try first.applyLibrary(command, from: oldGeneration)
        let observer = Task { @MainActor in try await operation.value }
        try await gate.awaitEntry()
        let committed = try disk.load()!
        try check(first.isBusy && first.operationTask != nil, "reservation remains live after commit")
        try check(first.library?.activeID == originalID, "receipt not adopted early")
        try check(committed.projects.count == (switching ? 2 : 1), "actual command committed")
        try check((committed.activeID != originalID) == switching, "committed switch identity")
        var rejected = first.scene.camera
        rejected.y += 0.2
        try check(!first.apply(.cameraPosition(rejected), from: oldGeneration), "busy editor rejects mutation")
        do {
            _ = try first.applyLibrary(.select(originalID), from: oldGeneration)
            throw ProbeError.invariant("busy editor accepted second reservation")
        } catch ProjectLibraryOperationState.OperationError.busy { checks += 1 }

        let second = StudioSession(store: ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:]))
        try await second.beginLibraryOperation(.load, from: second.generation).value
        try check(second.library == committed, "second window reads the real committed command")
        var secondScene = second.scene
        secondScene.camera.z += 0.7
        try check(second.replace(secondScene, from: second.generation), "second window edit")
        try await second.beginLibraryOperation(.save, from: second.generation).value
        let newerDisk = try disk.load()!
        let newerBytes = try Data(contentsOf: disk.url)
        try check(newerDisk.activeProject?.scene == secondScene, "second window save is authoritative")
        if cancelSession { operation.cancel() } else { observer.cancel() }
        try check(first.isBusy, "cancellation cannot abandon committed reservation")
        await gate.open()
        try await operation.value
        try await observer.value
        try check(!first.isBusy && first.operationTask == nil, "cancelled observer/task still settles")
        try check(first.library == committed, "adopts the matching committed receipt")
        try check(first.scene == committed.activeProject?.scene && first.saved == first.scene, "receipt scene is not fabricated from newer disk")
        try check(try Data(contentsOf: disk.url) == newerBytes, "receipt adoption never rewrites newer disk")
        try check((first.generation != oldGeneration) == switching, "generation switches exactly for a new project")
        try check((first.workspaceResetID != oldWorkspace) == switching, "presentation resets exactly for a new project")
        try check((first.feature == nil) == switching, "feature ownership follows switch policy")
        try check(first.acceptsFeature(oldFeature) == !switching, "old feature only survives metadata change")
        if switching {
            try check(!first.apply(.cameraPosition(rejected), from: oldGeneration), "old generation rejected after duplicate")
        }
        let settledGeneration = first.generation
        try await operation.value
        try check(first.generation == settledGeneration, "reading a receipt twice does not re-adopt")
        var local = first.scene
        local.camera.x += 0.4
        try check(first.replace(local, from: first.generation), "local edit after receipt")
        let localEditor = first.editor
        do {
            try await first.beginLibraryOperation(.save, from: first.generation).value
            throw ProbeError.invariant("stale post-receipt save overwrote other window")
        } catch ProjectLibraryError.staleSnapshot { checks += 1 }
        try check(first.editor == localEditor, "failed stale save preserves scene and history")
        try check(first.saveConflict && first.saved != first.scene, "failed stale save retains dirty/conflict state")
        try check(!first.isBusy && first.operationTask == nil, "failed stale save releases busy/task state")
        try check(try disk.load() == newerDisk, "stale save preserves newer library")
        try check(try Data(contentsOf: disk.url) == newerBytes, "stale save preserves bytes")
        try await first.beginLibraryOperation(.recover(name: "Recovered A", replacing: nil), from: first.generation).value
        let recovered = try disk.load()!
        try check(recovered.projects.count == newerDisk.projects.count + 1, "recovery appends exactly once")
        try check(recovered.projects.contains { $0.scene == secondScene }, "recovery preserves other window scene")
        try check(recovered.activeProject?.scene == local, "recovery stores local edits")
        try check(first.scene == local && first.saved == local && !first.saveConflict, "recovery settles current editor")
        try check(!first.isBusy && first.operationTask == nil, "recovery releases task")
        print("PASS switching=\(switching) cancellation=\(cancelSession ? "session" : "observer")")
    }
    @MainActor static func main() async throws {
        for switching in [false, true] {
            for cancelSession in [false, true] {
                try await run(switching: switching, cancelSession: cancelSession)
            }
        }
        print("W013 passed 4 real-store receipt interleavings and \(checks) invariant checks. Linux portable orchestration only; no Apple UI/device execution.")
    }
}
