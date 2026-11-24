import Dispatch
import Foundation
import XCTest
import LightingCore
@testable import KeyAndFill

/// A controlled worker pause tests ordering without sleeps or latency targets.
private final class ProjectWorkerBarrier: @unchecked Sendable {
    let entered: XCTestExpectation
    private let semaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var timedOut = false

    init(_ description: String) { entered = XCTestExpectation(description: description) }
    func wait() {
        entered.fulfill()
        let timeout = semaphore.wait(timeout: .now() + 5) == .timedOut
        lock.lock(); timedOut = timeout; lock.unlock()
    }
    func open() { semaphore.signal() }
    var didTimeOut: Bool {
        lock.lock(); defer { lock.unlock() }; return timedOut
    }
}

private extension ProjectStore {
    func pause(on barrier: ProjectWorkerBarrier) { barrier.wait() }
    func performThenPause(_ request: ProjectLibraryRequest,
                          on barrier: ProjectWorkerBarrier) throws -> ProjectLibrary? {
        let committed = try perform(request)
        barrier.wait() // Actual replacement has finished; receipt is not delivered yet.
        return committed
    }
}

@MainActor
final class ProjectStoreOperationTests: XCTestCase {
    private func directory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func backingStore(_ base: URL) -> ProjectLibraryFileStore {
        .init(directory: base.appendingPathComponent("KeyAndFill", isDirectory: true))
    }

    private func worker(_ base: URL) -> ProjectStore {
        ProjectStore(applicationSupportDirectory: base, arguments: [], environment: [:])
    }

    private func reserve(_ operation: ProjectLibraryOperation, library: ProjectLibrary? = nil,
                         scene: LightingScene = .portrait()) throws -> ProjectLibraryRequest {
        var state = ProjectLibraryOperationState()
        return try state.reserve(operation, library: library, scene: scene, from: state.generation)
    }

    func testReservationRejectsDuplicateCommandsAndSceneCallbacksUntilItSettles() async throws {
        var state = ProjectLibraryOperationState()
        let generation = state.generation
        var scene = LightingScene.portrait()
        let original = scene
        var history = SceneEditHistory()
        let request = try state.reserve(.save, library: nil, scene: scene, from: generation)
        for command in [ProjectLibraryOperation.save, .change(.create(name: "Second", scene: scene))] {
            XCTAssertThrowsError(try state.reserve(command, library: nil, scene: scene, from: generation)) {
                XCTAssertEqual($0 as? ProjectLibraryOperationState.OperationError, .busy)
            }
        }
        // Slider, precision, recipe, guided and history callbacks share this gate.
        for _ in 0..<5 where state.allowsSceneMutation(from: generation) {
            history.record(previous: scene)
            scene.lights[0].candela += 100
        }
        XCTAssertEqual(scene, original)
        XCTAssertFalse(history.canUndo)
        XCTAssertEqual(state.pending?.id, request.id)
        XCTAssertTrue(state.finish(request)) // Failure releases the same reservation.
        XCTAssertTrue(state.allowsSceneMutation(from: generation))
        let next = try state.reserve(.save, library: nil, scene: scene, from: generation)
        XCTAssertFalse(state.finish(request), "An old observer cannot clear a newer operation")
        XCTAssertEqual(state.pending?.id, next.id)
    }

    func testFirstSavePreservesHistoryAndPresentationWhileInvalidatingDraftCallbacks() async throws {
        var state = ProjectLibraryOperationState()
        let draftGeneration = state.generation
        let before = LightingScene.portrait()
        var edited = before
        edited.lights[0].candela = 1200
        var history = SceneEditHistory()
        history.record(previous: before)
        let request = try state.reserve(.save, library: nil, scene: edited, from: draftGeneration)
        let committed = try ProjectLibrary(name: "Portrait setup", scene: edited)
        let adoption = try XCTUnwrap(state.adopt(committed, for: request, currentProjectID: nil, currentScene: edited))
        XCTAssertEqual(adoption.saved, edited)
        XCTAssertEqual(adoption.scene, edited)
        XCTAssertFalse(adoption.resetsHistory)
        XCTAssertFalse(adoption.resetsPresentation)
        XCTAssertEqual(history.undo(current: adoption.scene), before)
        XCTAssertFalse(state.isBusy)
        XCTAssertFalse(state.allowsSceneMutation(from: draftGeneration))
        XCTAssertTrue(state.allowsSceneMutation(from: state.generation))
    }

    func testSaveReceiptKeepsAnyNewerSceneDirtyInsteadOfMarkingItSaved() async throws {
        var state = ProjectLibraryOperationState()
        let captured = LightingScene.portrait()
        let library = try ProjectLibrary(name: "Captured", scene: captured)
        let request = try state.reserve(.save, library: library, scene: captured, from: state.generation)
        var newer = captured
        newer.camera.x = 3
        let adoption = try XCTUnwrap(state.adopt(library, for: request,
                                                currentProjectID: library.activeID, currentScene: newer))
        XCTAssertEqual(adoption.saved, captured)
        XCTAssertEqual(adoption.scene, newer)
        XCTAssertNotEqual(adoption.saved, adoption.scene)
        XCTAssertFalse(adoption.resetsHistory)
    }

    func testMetadataSwitchAndConfirmedReloadHaveDistinctAdoptionPolicies() async throws {
        var state = ProjectLibraryOperationState()
        let originalGeneration = state.generation
        let scene = LightingScene.portrait()
        let library = try ProjectLibrary(name: "Original", scene: scene)
        let rename = try state.reserve(.change(.rename(library.activeID, name: "Renamed")),
                                       library: library, scene: scene, from: state.generation)
        var renamed = library
        try renamed.rename(renamed.activeID, to: "Renamed")
        let metadata = try XCTUnwrap(state.adopt(renamed, for: rename, currentProjectID: library.activeID, currentScene: scene))
        XCTAssertFalse(metadata.resetsHistory)
        XCTAssertFalse(metadata.resetsPresentation)
        XCTAssertEqual(state.generation, originalGeneration)

        let create = try state.reserve(.change(.create(name: "Other", scene: .portrait())),
                                       library: renamed, scene: scene, from: state.generation)
        var other = renamed
        try other.create(name: "Other", scene: .portrait())
        let switched = try XCTUnwrap(state.adopt(other, for: create, currentProjectID: renamed.activeID, currentScene: scene))
        XCTAssertTrue(switched.resetsHistory)
        XCTAssertTrue(switched.resetsPresentation)
        XCTAssertEqual(switched.scene, other.activeProject?.scene)
        XCTAssertFalse(state.allowsSceneMutation(from: originalGeneration))

        let beforeReload = state.generation
        let reload = try state.reserve(.reload, library: other, scene: switched.scene, from: beforeReload)
        XCTAssertNil(try state.adopt(renamed, for: rename, currentProjectID: other.activeID, currentScene: switched.scene))
        XCTAssertEqual(state.pending?.id, reload.id)
        let reloaded = try XCTUnwrap(state.adopt(other, for: reload, currentProjectID: other.activeID, currentScene: switched.scene))
        XCTAssertTrue(reloaded.resetsHistory)
        XCTAssertFalse(state.allowsSceneMutation(from: beforeReload), "Reloading the same project invalidates its previous controls")
    }

    func testInitializerDoesNoFileWorkAndQueuedCancellationCannotCreateAFile() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        XCTAssertFalse(FileManager.default.fileExists(atPath: base.path))
        let barrier = ProjectWorkerBarrier("Store occupied before queued save")
        defer { barrier.open() }
        let occupying = Task { await store.pause(on: barrier) }
        await fulfillment(of: [barrier.entered], timeout: 2)

        let request = try reserve(.save)
        let saving = Task { try await store.perform(request) }
        saving.cancel()
        barrier.open()
        await occupying.value
        do { _ = try await saving.value; XCTFail("A queued cancelled operation must not write") }
        catch is CancellationError { }
        XCTAssertFalse(barrier.didTimeOut)
        XCTAssertFalse(FileManager.default.fileExists(atPath: base.path))
    }

    func testActorSerializesCompetingSavesWhileMainActorRemainsAvailable() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        let barrier = ProjectWorkerBarrier("Storage executor occupied")
        defer { barrier.open() }
        let occupying = Task { await store.pause(on: barrier) }
        await fulfillment(of: [barrier.entered], timeout: 2)
        // Reaching this main-actor continuation while the worker is held is the
        // responsiveness assertion; the barrier never uses an arbitrary sleep.
        let first = try reserve(.save)
        let second = try reserve(.save)
        let saveA = Task { try await store.perform(first) }
        let saveB = Task { try await store.perform(second) }
        barrier.open()
        await occupying.value
        var successes: [ProjectLibrary] = []
        var stale = 0
        for task in [saveA, saveB] {
            do {
                let receipt = try await task.value
                successes.append(try XCTUnwrap(receipt))
            }
            catch ProjectLibraryError.staleSnapshot { stale += 1 }
        }
        XCTAssertFalse(barrier.didTimeOut, "The main actor must release the worker before its bounded safety timeout")
        XCTAssertEqual(successes.count, 1)
        XCTAssertEqual(stale, 1)
        XCTAssertEqual(try backingStore(base).load(), successes.first)
    }

    func testCancellationAfterCommitStillDeliversAndAdoptsTheReceiptExactlyOnce() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        var state = ProjectLibraryOperationState()
        let scene = LightingScene.portrait()
        let request = try state.reserve(.save, library: nil, scene: scene, from: state.generation)
        let barrier = ProjectWorkerBarrier("Atomic write committed before receipt delivery")
        defer { barrier.open() }
        let saving = Task { try await store.performThenPause(request, on: barrier) }
        await fulfillment(of: [barrier.entered], timeout: 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: backingStore(base).url.path))
        saving.cancel() // Models closing/cancelling an observer after a committed write.
        barrier.open()
        let receipt = try await saving.value
        let adoption = try XCTUnwrap(state.adopt(receipt, for: request, currentProjectID: nil, currentScene: scene))
        XCTAssertEqual(adoption.library, try backingStore(base).load())
        XCTAssertEqual(adoption.saved, scene)
        XCTAssertFalse(state.isBusy)
        XCTAssertNil(try state.adopt(receipt, for: request, currentProjectID: nil, currentScene: scene))
        XCTAssertFalse(barrier.didTimeOut)
    }

    func testRealStaleSaveRetainsLocalSceneHistoryAndCompetingBytes() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        let initial = LightingScene.portrait()
        let initialReceipt = try await store.perform(reserve(.save, scene: initial))
        let library = try XCTUnwrap(initialReceipt)
        var remote = library
        try remote.rename(remote.activeID, to: "Other window")
        try backingStore(base).save(remote, replacing: library)
        let bytes = try Data(contentsOf: backingStore(base).url)
        var local = initial
        local.lights[0].candela = 1111
        var history = SceneEditHistory()
        history.record(previous: initial)
        var state = ProjectLibraryOperationState()
        let request = try state.reserve(.save, library: library, scene: local, from: state.generation)
        do { _ = try await store.perform(request); XCTFail("Expected revision CAS must reject the stale snapshot") }
        catch ProjectLibraryError.staleSnapshot { XCTAssertTrue(state.finish(request)) }
        XCTAssertEqual(try Data(contentsOf: backingStore(base).url), bytes)
        XCTAssertEqual(try backingStore(base).load(), remote)
        XCTAssertEqual(local.lights[0].candela, 1111)
        XCTAssertEqual(history.undo(current: local), initial)
        XCTAssertFalse(state.isBusy)
    }

    func testFailedCommandDoesNotAdoptOrChangeBytesAndCanBeRetried() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        let initialReceipt = try await store.perform(reserve(.save))
        let library = try XCTUnwrap(initialReceipt)
        let scene = try XCTUnwrap(library.activeProject?.scene)
        let bytes = try Data(contentsOf: backingStore(base).url)
        var state = ProjectLibraryOperationState()
        let bad = try state.reserve(.change(.create(name: "", scene: scene)), library: library,
                                    scene: scene, from: state.generation)
        do { _ = try await store.perform(bad); XCTFail("Worker-side command validation must reject the invalid name") }
        catch ProjectLibraryError.invalidName { XCTAssertTrue(state.finish(bad)) }
        XCTAssertEqual(try Data(contentsOf: backingStore(base).url), bytes)
        let retry = try state.reserve(.change(.rename(library.activeID, name: "Retried")), library: library,
                                      scene: scene, from: state.generation)
        let receipt = try await store.perform(retry)
        let adopted = try XCTUnwrap(state.adopt(receipt, for: retry, currentProjectID: library.activeID, currentScene: scene))
        XCTAssertEqual(adopted.library?.activeProject?.name, "Retried")
        XCTAssertFalse(adopted.resetsHistory)
        XCTAssertFalse(state.isBusy)
    }

    func testCorruptLoadAndSaveKeepProtectedBytesAndDoNotProduceAnAdoption() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = worker(base)
        let fileStore = backingStore(base)
        try FileManager.default.createDirectory(at: fileStore.directory, withIntermediateDirectories: true)
        let corrupt = Data("invalid library".utf8)
        try corrupt.write(to: fileStore.url)
        for operation in [ProjectLibraryOperation.load, .save] {
            var state = ProjectLibraryOperationState()
            let request = try state.reserve(operation, library: nil, scene: .portrait(), from: state.generation)
            do { _ = try await store.perform(request); XCTFail("Corrupt saved data must not authorize replacement") }
            catch { XCTAssertTrue(state.finish(request)) }
            XCTAssertFalse(state.isBusy)
            XCTAssertEqual(try Data(contentsOf: fileStore.url), corrupt)
        }
    }

    func testRecoveryCandidateReadNeverAdoptsLatestLibraryOrUnsavedEditor() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        var library = try ProjectLibrary(name: "Archived", scene: .portrait())
        let archivedID = library.activeID
        try library.create(name: "Saved", scene: .portrait())
        try library.archive(archivedID)
        try backingStore(base).save(library, replacing: nil)
        let store = worker(base)
        let state = ProjectLibraryOperationState()
        let generation = state.generation
        var local = try XCTUnwrap(library.activeProject?.scene)
        local.camera.x = 7
        var history = SceneEditHistory()
        history.record(previous: try XCTUnwrap(library.activeProject?.scene))
        let candidates = try await store.recoveryCandidates()
        XCTAssertEqual(candidates.map(\.id), [archivedID])
        XCTAssertEqual(local.camera.x, 7)
        XCTAssertTrue(history.canUndo)
        XCTAssertEqual(state.generation, generation)
        XCTAssertFalse(state.isBusy)
        XCTAssertEqual(try backingStore(base).load(), library)
    }

    func testRecoveryRechecksFullCandidateThenUsesNewlyAvailableCapacity() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        var full = try ProjectLibrary(name: "Archived", scene: .portrait())
        let archivedID = full.activeID
        for index in 1..<ProjectLibrary.maximumProjects {
            try full.create(name: "Project \(index)", scene: .portrait())
        }
        try full.archive(archivedID)
        try backingStore(base).save(full, replacing: nil)
        let store = worker(base)
        let candidates = try await store.recoveryCandidates()
        let candidate = try XCTUnwrap(candidates.first)
        var latest = full
        try latest.restore(candidate.id)
        try latest.rename(candidate.id, to: "Changed elsewhere")
        try latest.archive(candidate.id)
        try backingStore(base).save(latest, replacing: full)
        var local = try XCTUnwrap(full.activeProject?.scene)
        local.lights[0].candela = 1234
        var state = ProjectLibraryOperationState()
        let request = try state.reserve(.recover(name: "Recovery", replacing: candidate), library: full,
                                        scene: local, from: state.generation)
        let bytes = try Data(contentsOf: backingStore(base).url)
        do { _ = try await store.perform(request); XCTFail("Changed candidate must not be removed") }
        catch ProjectLibraryError.staleSnapshot { XCTAssertTrue(state.finish(request)) }
        XCTAssertEqual(try Data(contentsOf: backingStore(base).url), bytes)

        let removable = try XCTUnwrap(latest.projects.first { $0.id != candidate.id && $0.id != latest.activeID })
        var freed = latest
        try freed.archive(removable.id)
        try freed.deleteArchived(removable.id)
        try backingStore(base).save(freed, replacing: latest)
        let retry = try state.reserve(.recover(name: "Recovery", replacing: candidate), library: full,
                                      scene: local, from: state.generation)
        let receipt = try await store.perform(retry)
        let adoption = try XCTUnwrap(state.adopt(receipt, for: retry, currentProjectID: full.activeID, currentScene: local))
        XCTAssertEqual(adoption.saved, local)
        XCTAssertTrue(adoption.resetsHistory)
        XCTAssertEqual(adoption.library?.projects.first { $0.id == candidate.id }, freed.projects.first { $0.id == candidate.id })
        XCTAssertEqual(adoption.library?.projects.count, ProjectLibrary.maximumProjects)
        XCTAssertEqual(adoption.library, try backingStore(base).load())
    }

    #if DEBUG
    func testUITestingWithoutValidIDNeverLoadsOrChangesNormalSavedProjects() async throws {
        for rawID: String? in [nil, "not-a-uuid"] {
            let base = directory()
            defer { try? FileManager.default.removeItem(at: base) }
            let normal = try ProjectLibrary(name: "Normal saved work", scene: .portrait())
            try backingStore(base).save(normal, replacing: nil)
            let normalBytes = try Data(contentsOf: backingStore(base).url)
            var environment = ["KEYFILL_UI_TEST_CORRUPT": "1", "KEYFILL_UI_TEST_FULL_LIBRARY": "1",
                               "KEYFILL_UI_TEST_LARGE_LIBRARY": "1", "KEYFILL_UI_TEST_CONFLICT": "1"]
            if let rawID { environment["KEYFILL_UI_TEST_ID"] = rawID }
            let store = ProjectStore(applicationSupportDirectory: base, arguments: ["-ui-testing"], environment: environment)
            let initiallyLoaded = try await store.perform(reserve(.load))
            XCTAssertNil(initiallyLoaded, "A missing/malformed test UUID must never fall back to normal projects or create fixtures")
            var scene = LightingScene.portrait()
            scene.camera.x = 2
            let first = try await store.perform(reserve(.save, library: initiallyLoaded, scene: scene))
            scene.camera.x = 3
            // Even the conflict fixture must remain valid-UUID-only.
            let second = try await store.perform(reserve(.save, library: first, scene: scene))
            let testStore = ProjectLibraryFileStore(directory: base.appendingPathComponent("KeyAndFill-UITests"))
            XCTAssertEqual(try testStore.load(), second)
            XCTAssertEqual(second?.activeProject?.scene, scene)
            XCTAssertEqual(second?.projects.count, 1)
            XCTAssertEqual(try Data(contentsOf: backingStore(base).url), normalBytes)
            XCTAssertEqual(try backingStore(base).load(), normal)
        }
    }

    func testLargeLaunchFixtureUsesRealBoundedBytesAndRetainsSavedEditsOnRelaunch() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let id = UUID()
        let environment = ["KEYFILL_UI_TEST_ID": id.uuidString, "KEYFILL_UI_TEST_LARGE_LIBRARY": "1"]
        let store = ProjectStore(applicationSupportDirectory: base, arguments: ["-ui-testing"], environment: environment)
        XCTAssertFalse(FileManager.default.fileExists(atPath: base.path))
        let receipt = try await store.perform(reserve(.load))
        let library = try XCTUnwrap(receipt)
        let url = base.appendingPathComponent("KeyAndFill-UITests").appendingPathComponent(id.uuidString)
            .appendingPathComponent("projects.json")
        let bytes = try Data(contentsOf: url).count
        XCTAssertGreaterThan(bytes, 8_000_000)
        XCTAssertLessThanOrEqual(bytes, ProjectLibraryFileStore.maximumBytes)
        var edited = try XCTUnwrap(library.activeProject?.scene)
        edited.lights.append(.init(name: "Added light", position: .init(x: 1, y: 2, z: 1), candela: 500, kelvin: 5600))
        let saved = try await store.perform(reserve(.save, library: library, scene: edited))
        let reopened = ProjectStore(applicationSupportDirectory: base, arguments: ["-ui-testing"], environment: environment)
        let reloaded = try await reopened.perform(reserve(.load))
        XCTAssertEqual(reloaded, saved)
        XCTAssertEqual(reloaded?.activeProject?.scene, edited)
        XCTAssertEqual(reloaded?.activeProject?.name, library.activeProject?.name)
    }

    func testScopedLaunchFixtureIsDeferredAndRelaunchKeepsRecoveryResult() async throws {
        let base = directory()
        defer { try? FileManager.default.removeItem(at: base) }
        let id = UUID()
        let environment = ["KEYFILL_UI_TEST_ID": id.uuidString, "KEYFILL_UI_TEST_FULL_LIBRARY": "1"]
        let store = ProjectStore(applicationSupportDirectory: base, arguments: ["-ui-testing"], environment: environment)
        XCTAssertFalse(FileManager.default.fileExists(atPath: base.path))
        let loaded = try await store.perform(reserve(.load))
        let full = try XCTUnwrap(loaded)
        XCTAssertEqual(full.projects.count, ProjectLibrary.maximumProjects)
        let candidate = try XCTUnwrap(full.projects.first(where: \.isArchived))
        var local = try XCTUnwrap(full.activeProject?.scene)
        local.camera.x = 2
        let recovered = try await store.perform(reserve(.recover(name: "Recovery", replacing: candidate), library: full, scene: local))
        let reopened = ProjectStore(applicationSupportDirectory: base, arguments: ["-ui-testing"], environment: environment)
        let reloaded = try await reopened.perform(reserve(.load))
        XCTAssertEqual(reloaded, recovered)
        XCTAssertEqual(reloaded?.activeProject?.scene, local)
        XCTAssertFalse(FileManager.default.fileExists(atPath: backingStore(base).url.path))
    }
    #endif
}
