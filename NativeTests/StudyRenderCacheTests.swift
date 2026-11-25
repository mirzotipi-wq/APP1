import Foundation
import XCTest
import LightingCore
@testable import KeyAndFill

final class StudyRenderCacheTests: XCTestCase {
    /// A 24 × 16 CPU render needs at least 48 pixel cancellation checks. A
    /// budget of eight therefore permits a cache hit, but interrupts real CPU
    /// work without timers, artificial renderers or production test counters.
    private final class CancellationBudget: @unchecked Sendable {
        private let lock = NSLock()
        private var checks = 0
        private var cancellationCheck: Int?

        func requested() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            checks += 1
            return cancellationCheck.map { checks >= $0 } ?? false
        }

        func reset(cancelAt check: Int? = nil) {
            lock.lock()
            checks = 0
            cancellationCheck = check
            lock.unlock()
        }

        var checkCount: Int {
            lock.lock()
            defer { lock.unlock() }
            return checks
        }
    }

    private func portraitScene(exposure: Double = 0) -> LightingScene {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 1.6, z: 1.7)
        scene.cameraLens = .init(focalLengthMillimeters: 70)
        scene.previewSettings = .init(exposureStops: exposure)
        return scene
    }

    private func assertCancelled(_ engine: StudyRenderEngine, scene: LightingScene,
                                 width: Int = 24, subject: StudySubject = .bust,
                                 file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await engine.render(scene: scene, width: width, subject: subject)
            XCTFail("Uncached or cancelled work must not return a frame", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? StudyError, .cancelled, file: file, line: line)
        }
    }

    private func cachedFrame(_ engine: StudyRenderEngine, budget: CancellationBudget,
                             scene: LightingScene, width: Int = 24,
                             subject: StudySubject = .bust) async throws -> StudyRenderedFrame {
        budget.reset(cancelAt: 8)
        defer { budget.reset() }
        return try await engine.render(scene: scene, width: width, subject: subject)
    }

    func testRevertedAndReopenedSceneReusesExactSuccessfulPixels() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let original = portraitScene()
        let first = try await engine.render(scene: original, width: 24, subject: .bust)
        XCTAssertEqual(first.backend, .cpu)
        XCTAssertEqual(first.image, try PortraitStudyRenderer.render(scene: original, width: 24))

        var edited = original
        edited.previewSettings?.exposureStops = 2
        let second = try await engine.render(scene: edited, width: 24, subject: .bust)
        XCTAssertNotEqual(second.image, first.image)

        // Reopening uses a new decoded value, with the persisted light IDs.
        let reopened = try JSONDecoder().decode(LightingScene.self, from: JSONEncoder().encode(original))
        let reused = try await cachedFrame(engine, budget: budget, scene: reopened)
        XCTAssertEqual(reused.image, first.image)
        XCTAssertEqual(reused.backend, first.backend)
    }

    func testEntryLimitEvictsLeastRecentlyUsedSuccessfulFrame() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let original = portraitScene()
        let scenes = (0...StudyRenderEngine.maximumCachedFrames).map { exposure in
            var scene = original
            scene.previewSettings?.exposureStops = Double(exposure)
            return scene
        }
        var frames: [StudyRenderedFrame] = []
        for scene in scenes.dropLast() {
            frames.append(try await engine.render(scene: scene, width: 24, subject: .bust))
        }
        XCTAssertLessThan(frames.reduce(0) { $0 + $1.image.rgba.count },
                          StudyRenderEngine.maximumCachedPixelBytes)
        _ = try await cachedFrame(engine, budget: budget, scene: scenes[0])
        let newest = try await engine.render(scene: scenes.last!, width: 24, subject: .bust)

        // Refreshing the first entry makes the second entry the eviction target.
        budget.reset(cancelAt: 8)
        await assertCancelled(engine, scene: scenes[1])
        let recent = try await cachedFrame(engine, budget: budget, scene: scenes[0])
        let last = try await cachedFrame(engine, budget: budget, scene: scenes.last!)
        XCTAssertEqual(recent.image, frames[0].image)
        XCTAssertEqual(last.image, newest.image)
    }

    func testPixelBudgetEvictsLargeFramesBeforeEntryLimit() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        var original = LightingScene.portrait()
        // Deliberately outside Metal's domain, so the cancellation probe tests
        // actual CPU work on devices both with and without a Metal backend.
        original.camera.z = 25
        original.previewSettings = .init()
        let scenes = (0..<3).map { exposure in
            var scene = original
            scene.previewSettings?.exposureStops = Double(exposure)
            return scene
        }
        var frames: [StudyRenderedFrame] = []
        for scene in scenes {
            let frame = try await engine.render(scene: scene, width: 192)
            XCTAssertEqual(frame.backend, .cpu)
            frames.append(frame)
        }
        XCTAssertLessThan(scenes.count, StudyRenderEngine.maximumCachedFrames)
        XCTAssertGreaterThan(frames.reduce(0) { $0 + $1.image.rgba.count },
                             StudyRenderEngine.maximumCachedPixelBytes)
        XCTAssertLessThanOrEqual(frames[1].image.rgba.count + frames[2].image.rgba.count,
                                StudyRenderEngine.maximumCachedPixelBytes)
        budget.reset(cancelAt: 8)
        await assertCancelled(engine, scene: scenes[0], width: 192, subject: .sphere)
        for index in 1...2 {
            let reused = try await cachedFrame(engine, budget: budget, scene: scenes[index],
                                               width: 192, subject: .sphere)
            XCTAssertEqual(reused.image, frames[index].image)
        }
    }

    func testEveryRenderingControlKeepsDistinctCacheIdentity() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        var original = portraitScene()
        original.lights[0].optics = .init(kind: .rectangle)
        let first = try await engine.render(scene: original, width: 24, subject: .bust)
        let edits: [(String, (inout LightingScene) -> Void)] = [
            ("subject", { $0.subject.x += 0.1 }),
            ("camera", { $0.camera.y += 0.1 }),
            ("lens", { $0.cameraLens?.focalLengthMillimeters = 85 }),
            ("light position", { $0.lights[0].position.z += 0.2 }),
            ("output", { $0.lights[0].candela = 600 }),
            ("temperature", { $0.lights[0].kelvin = 3200 }),
            ("emitter kind", { $0.lights[0].optics?.kind = .directional }),
            ("emitter aim", { $0.lights[0].optics?.aimTarget = .init(x: 0.2, y: 1.5, z: 0) }),
            ("emitter width", { $0.lights[0].optics?.widthMeters = 0.8 }),
            ("emitter height", { $0.lights[0].optics?.heightMeters = 1.1 }),
            ("emitter roll", { $0.lights[0].optics?.rollDegrees = 30 }),
            ("exposure", { $0.previewSettings?.exposureStops = 1 }),
            ("white balance", { $0.previewSettings?.whiteBalanceKelvin = 4500 }),
            ("light count", { $0.lights.removeLast() }),
            ("light order", { $0.lights.reverse() })
        ]
        for (name, edit) in edits {
            var changed = original
            edit(&changed)
            _ = try changed.validated()
            budget.reset(cancelAt: 8)
            do {
                _ = try await engine.render(scene: changed, width: 24, subject: .bust)
                XCTFail("Changing \(name) must require a new render")
            } catch {
                XCTAssertEqual(error as? StudyError, .cancelled, name)
            }
        }
        let reused = try await cachedFrame(engine, budget: budget, scene: original)
        XCTAssertEqual(reused.image, first.image,
                       "Interrupted edits must leave the completed original available")
    }

    func testSubjectAndResolutionDoNotShareFrames() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let scene = portraitScene()
        _ = try await engine.render(scene: scene, width: 24, subject: .bust)
        budget.reset(cancelAt: 8)
        await assertCancelled(engine, scene: scene, width: 30)
        budget.reset(cancelAt: 8)
        await assertCancelled(engine, scene: scene, subject: .sphere)
        let reused = try await cachedFrame(engine, budget: budget, scene: scene)
        XCTAssertEqual(reused.image.width, 24)
        XCTAssertEqual(reused.backend, .cpu)
    }

    func testBustCachePreservesExistingMaximumWidthClamping() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let scene = portraitScene()
        let first = try await engine.render(scene: scene, width: 192, subject: .bust)
        let reused = try await cachedFrame(engine, budget: budget, scene: scene, width: Int.max)
        XCTAssertEqual(first.image.width, PortraitStudyRenderer.maximumWidth)
        XCTAssertEqual(reused.image, first.image)
        XCTAssertEqual(reused.backend, .cpu)
    }

    func testInvalidMetadataCannotReuseAValidatedFrame() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let original = portraitScene()
        let first = try await engine.render(scene: original, width: 24, subject: .bust)
        let invalidEdits: [(inout LightingScene) -> Void] = [
            { $0.lights[0].name = " \n " },
            { $0.lights[0].name = String(repeating: "x", count: 81) },
            { $0.lights[1].id = $0.lights[0].id },
            { $0.schemaVersion = 0 },
            { $0.schemaVersion = 4; $0.placementRoom = .init() },
            { $0.placementRoom = .init(widthMeters: 0) },
            { $0.lights[0].candela = .nan },
            { $0.previewSettings?.whiteBalanceKelvin = .infinity }
        ]
        for edit in invalidEdits {
            var invalid = original
            edit(&invalid)
            do {
                _ = try await engine.render(scene: invalid, width: 24, subject: .bust)
                XCTFail("Invalid input must still be rejected after a successful render")
            } catch {
                XCTAssertEqual(error as? StudyError, .invalidScene)
            }
        }
        // A valid display-only edit may reuse pixels, including a Unicode name
        // whose character count would otherwise hide unbounded retained bytes.
        var renamed = original
        renamed.lights[0].name = "A" + String(repeating: "\u{301}", count: 4096)
        XCTAssertTrue(renamed.lights[0].isValid)
        let reused = try await cachedFrame(engine, budget: budget, scene: renamed)
        XCTAssertEqual(reused.image, first.image)
    }

    func testInvalidResolutionAndCameraKeepOriginalErrorOrdering() async throws {
        let engine = StudyRenderEngine()
        let original = portraitScene()
        _ = try await engine.render(scene: original, width: 24, subject: .bust)
        var invalid = original
        invalid.camera = invalid.subject
        invalid.lights[0].name = ""
        for width in [Int.min, 0, 25] {
            do {
                _ = try await engine.render(scene: invalid, width: width, subject: .bust)
                XCTFail("Invalid resolution must precede camera and scene validation")
            } catch {
                XCTAssertEqual(error as? StudyError, .invalidResolution)
            }
        }
        do {
            _ = try await engine.render(scene: invalid, width: 24, subject: .bust)
            XCTFail("An invalid camera must not return cached pixels")
        } catch {
            XCTAssertEqual(error as? StudyError, .invalidCamera)
        }
    }

    func testCancelledCacheLookupCannotPublishOrDiscardCompletedFrame() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let scene = portraitScene()
        let first = try await engine.render(scene: scene, width: 24, subject: .bust)
        // Cover both cancellation before lookup and after a matching entry is found.
        for check in [1, 2] {
            budget.reset(cancelAt: check)
            await assertCancelled(engine, scene: scene)
        }
        let reused = try await cachedFrame(engine, budget: budget, scene: scene)
        XCTAssertEqual(reused.image, first.image)
    }

    func testCancelledTaskCannotReturnCachedFrame() async throws {
        let engine = StudyRenderEngine(cancellationRequested: { false })
        let scene = portraitScene()
        _ = try await engine.render(scene: scene, width: 24, subject: .bust)
        let operation = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await engine.render(scene: scene, width: 24, subject: .bust)
        }
        do {
            _ = try await operation.value
            XCTFail("Actual task cancellation must apply to cached results")
        } catch {
            XCTAssertEqual(error as? StudyError, .cancelled)
        }
    }

    func testCancelledCPUWorkAndFinalCancellationAreNeverCached() async throws {
        let budget = CancellationBudget()
        let scene = portraitScene()
        let measuringEngine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let reference = try await measuringEngine.render(scene: scene, width: 24, subject: .bust)
        let completedChecks = budget.checkCount
        XCTAssertGreaterThan(completedChecks, 8)

        // The measured last check occurs after the real CPU renderer returns.
        // Both mid-render and final cancellation must leave the next call cold.
        for check in [8, completedChecks] {
            let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
            budget.reset(cancelAt: check)
            await assertCancelled(engine, scene: scene)
            budget.reset(cancelAt: 8)
            await assertCancelled(engine, scene: scene)
            budget.reset()
            let completed = try await engine.render(scene: scene, width: 24, subject: .bust)
            XCTAssertEqual(completed.image, reference.image)
            let reused = try await cachedFrame(engine, budget: budget, scene: scene)
            XCTAssertEqual(reused.image, reference.image)
        }
    }
}
