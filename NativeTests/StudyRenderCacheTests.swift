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
        // Cover cancellation at entry and immediately before cache lookup/promotion.
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

    // These scripted backends exercise actor/cache lifecycle only. Their opaque
    // synthetic images are not Metal output and establish no GPU parity claim.
    private enum ComputeStage { case factory, validation, render }
    private enum ComputeOutcome {
        case success
        case study(StudyError)
        case metal(MetalStudyError)
    }
    private struct ComputeStep {
        let outcome: ComputeOutcome
        let cancel: Bool

        init(_ outcome: ComputeOutcome = .success, cancel: Bool = false) {
            self.outcome = outcome
            self.cancel = cancel
        }
    }

    /// The factory captures this locked script, never a backend instance. Every
    /// mutable value shared with the test is synchronized; the backend itself
    /// remains actor-owned and does not require an unchecked Sendable claim.
    private final class ComputeScript: @unchecked Sendable {
        private let lock = NSLock()
        private let budget: CancellationBudget
        private var factoryStep = ComputeStep()
        private var validationStep = ComputeStep()
        private var renderStep = ComputeStep()
        private var factoryCalls = 0
        private var validationCalls = 0
        private var renderCalls = 0
        private var releases = 0

        init(budget: CancellationBudget) { self.budget = budget }

        func set(_ stage: ComputeStage, to step: ComputeStep) {
            lock.lock()
            defer { lock.unlock() }
            switch stage {
            case .factory: factoryStep = step
            case .validation: validationStep = step
            case .render: renderStep = step
            }
        }

        private func take(_ stage: ComputeStage) -> ComputeStep {
            lock.lock()
            defer { lock.unlock() }
            switch stage {
            case .factory: factoryCalls += 1; return factoryStep
            case .validation: validationCalls += 1; return validationStep
            case .render: renderCalls += 1; return renderStep
            }
        }

        func run(_ stage: ComputeStage) throws {
            let step = take(stage)
            // Toggle the real engine cancellation source in the same callback
            // that reports failure; no timer or scheduling race is involved.
            if step.cancel { budget.reset(cancelAt: 1) }
            switch step.outcome {
            case .success: return
            case .study(let error): throw error
            case .metal(let error): throw error
            }
        }

        func released() {
            lock.lock()
            releases += 1
            lock.unlock()
        }

        var counts: (factory: Int, validation: Int, render: Int, releases: Int) {
            lock.lock()
            defer { lock.unlock() }
            return (factoryCalls, validationCalls, renderCalls, releases)
        }
    }

    private final class ScriptedComputeBackend: StudyComputeBackend {
        private let script: ComputeScript

        init(script: ComputeScript) { self.script = script }
        deinit { script.released() }

        func validate(isCancelled: () -> Bool) throws {
            try script.run(.validation)
        }

        func render(scene: LightingScene, width: Int,
                    isCancelled: () -> Bool) throws -> StudyImage {
            try script.run(.render)
            // A distinctive synthetic frame makes stale mock cache hits visible.
            return try StudyImage.fromComputeRGBA(width: width, height: width * 2 / 3,
                data: Data(repeating: 255, count: width * (width * 2 / 3) * 4))
        }
    }

    private func scriptedEngine(budget: CancellationBudget, script: ComputeScript) -> StudyRenderEngine {
        StudyRenderEngine(cancellationRequested: { budget.requested() }, makeComputeBackend: {
            try script.run(.factory)
            return ScriptedComputeBackend(script: script)
        })
    }

    private func computeScene(exposure: Double = 0) -> LightingScene {
        var scene = LightingScene.portrait()
        scene.previewSettings = .init(exposureStops: exposure)
        XCTAssertTrue(MetalStudyRenderer.supports(scene, width: 48))
        return scene
    }

    private func assertCacheUsage(_ engine: StudyRenderEngine, images: [StudyImage],
                                  file: StaticString = #filePath, line: UInt = #line) async {
        let usage = await engine.cacheUsage
        XCTAssertEqual(usage.count, images.count, file: file, line: line)
        XCTAssertEqual(usage.pixelBytes, images.reduce(0) { $0 + $1.rgba.count }, file: file, line: line)
        XCTAssertEqual(usage.maskBytes, images.reduce(0) { $0 + $1.unsupportedPixelMask.count },
                       file: file, line: line)
        XCTAssertLessThanOrEqual(usage.count, 4, file: file, line: line)
        XCTAssertLessThanOrEqual(usage.pixelBytes, 262_144, file: file, line: line)
        XCTAssertLessThanOrEqual(usage.maskBytes, 65_536, file: file, line: line)
    }

    private func assertStudyError(_ expected: StudyError, engine: StudyRenderEngine,
                                  scene: LightingScene, width: Int = 48,
                                  file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await engine.render(scene: scene, width: width)
            XCTFail("Expected \(expected), not a completed frame", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? StudyError, expected, file: file, line: line)
        }
    }

    func testConfirmedComputeFailuresDowngradeBeforeConcurrentCancellation() async throws {
        let failures: [ComputeOutcome] = [.metal(.command), .metal(.allocation), .study(.invalidComputeOutput)]
        for failure in failures {
            let budget = CancellationBudget()
            let script = ComputeScript(budget: budget)
            let engine = scriptedEngine(budget: budget, script: script)
            let cpuScene = portraitScene()
            let cpu = try await engine.render(scene: cpuScene, width: 24, subject: .bust)
            let original = computeScene()
            let compute = try await engine.render(scene: original, width: 48)
            XCTAssertEqual(compute.backend, .metal)
            await assertCacheUsage(engine, images: [cpu.image, compute.image])

            var failed = original
            failed.previewSettings?.exposureStops = 1
            script.set(.render, to: ComputeStep(failure, cancel: true))
            await assertCancelled(engine, scene: failed, width: 48, subject: .sphere)
            // After await, the failing callback's local backend reference has
            // unwound. This proves mock object release, not GPU resource release.
            XCTAssertEqual(script.counts.releases, 1)
            await assertCacheUsage(engine, images: [cpu.image])
            let preserved = try await cachedFrame(engine, budget: budget, scene: cpuScene)
            XCTAssertEqual(preserved.image, cpu.image)
            XCTAssertEqual(preserved.backend, .cpu)

            script.set(.render, to: ComputeStep())
            let retried = try await engine.render(scene: failed, width: 48)
            XCTAssertEqual(retried.backend, .cpu)
            XCTAssertEqual(retried.image, try ReferenceStudyRenderer.render(scene: failed, width: 48))
            let oldKey = try await engine.render(scene: original, width: 48)
            XCTAssertEqual(oldKey.backend, .cpu)
            XCTAssertEqual(oldKey.image, try ReferenceStudyRenderer.render(scene: original, width: 48))
            XCTAssertNotEqual(oldKey.image, compute.image)
            XCTAssertEqual(script.counts.factory, 1)
            XCTAssertEqual(script.counts.validation, 1)
            XCTAssertEqual(script.counts.render, 2)
            await assertCacheUsage(engine, images: [cpu.image, retried.image, oldKey.image])
        }
    }

    func testOrdinaryComputeCancellationRetainsBackendAndCompletedCache() async throws {
        for step in [ComputeStep(.study(.cancelled)), ComputeStep(cancel: true)] {
            let budget = CancellationBudget()
            let script = ComputeScript(budget: budget)
            let engine = scriptedEngine(budget: budget, script: script)
            let original = computeScene()
            let first = try await engine.render(scene: original, width: 48)
            var interrupted = original
            interrupted.previewSettings?.exposureStops = 1
            script.set(.render, to: step)
            await assertCancelled(engine, scene: interrupted, width: 48, subject: .sphere)
            await assertCacheUsage(engine, images: [first.image])
            XCTAssertEqual(script.counts.releases, 0)
            let cached = try await cachedFrame(engine, budget: budget, scene: original,
                                                width: 48, subject: .sphere)
            XCTAssertEqual(cached.backend, .metal)
            XCTAssertEqual(cached.image, first.image)
            XCTAssertEqual(script.counts.render, 2)

            script.set(.render, to: ComputeStep())
            let retried = try await engine.render(scene: interrupted, width: 48)
            XCTAssertEqual(retried.backend, .metal)
            XCTAssertEqual(script.counts.factory, 1)
            XCTAssertEqual(script.counts.validation, 1)
            XCTAssertEqual(script.counts.render, 3, "Cancelled work must require a new render")
            await assertCacheUsage(engine, images: [first.image, retried.image])
        }
    }

    func testPrecisionDomainFallbackPreservesValidatedBackend() async throws {
        for cancel in [false, true] {
            let budget = CancellationBudget()
            let script = ComputeScript(budget: budget)
            let engine = scriptedEngine(budget: budget, script: script)
            let original = computeScene()
            let first = try await engine.render(scene: original, width: 48)
            var boundary = original
            boundary.previewSettings?.exposureStops = 1
            script.set(.render, to: ComputeStep(.metal(.precisionDomain), cancel: cancel))
            var expectedImages = [first.image]
            if cancel {
                await assertCancelled(engine, scene: boundary, width: 48, subject: .sphere)
            } else {
                let fallback = try await engine.render(scene: boundary, width: 48)
                XCTAssertEqual(fallback.backend, .cpu)
                XCTAssertEqual(fallback.image, try ReferenceStudyRenderer.render(scene: boundary, width: 48))
                expectedImages.append(fallback.image)
            }
            await assertCacheUsage(engine, images: expectedImages)
            budget.reset()
            script.set(.render, to: ComputeStep())
            var fresh = original
            fresh.previewSettings?.exposureStops = 2
            let next = try await engine.render(scene: fresh, width: 48)
            XCTAssertEqual(next.backend, .metal)
            let cached = try await engine.render(scene: original, width: 48)
            XCTAssertEqual(cached.backend, .metal)
            XCTAssertEqual(cached.image, first.image)
            XCTAssertEqual(script.counts.factory, 1)
            XCTAssertEqual(script.counts.validation, 1)
            XCTAssertEqual(script.counts.render, 3)
            XCTAssertEqual(script.counts.releases, 0)
        }
    }

    func testStartupStudyErrorsPropagateAndLeaveInitializationRetryable() async throws {
        let errors: [StudyError] = [.cancelled, .invalidScene, .invalidCamera,
                                    .invalidResolution, .invalidEmitter, .invalidSurface]
        for stage in [ComputeStage.factory, .validation] {
            for error in errors {
                let budget = CancellationBudget()
                let script = ComputeScript(budget: budget)
                let engine = scriptedEngine(budget: budget, script: script)
                let scene = computeScene()
                script.set(stage, to: ComputeStep(.study(error)))
                await assertStudyError(error, engine: engine, scene: scene)
                await assertCacheUsage(engine, images: [])
                script.set(stage, to: ComputeStep())
                let retried = try await engine.render(scene: scene, width: 48)
                XCTAssertEqual(retried.backend, .metal)
                XCTAssertEqual(script.counts.factory, 2)
                XCTAssertEqual(script.counts.validation, stage == .factory ? 1 : 2)
                XCTAssertEqual(script.counts.render, 1)
            }
        }
    }

    func testStartupFinalCancellationLeavesInitializationRetryable() async throws {
        let budget = CancellationBudget()
        let script = ComputeScript(budget: budget)
        let engine = scriptedEngine(budget: budget, script: script)
        let scene = computeScene()
        script.set(.validation, to: ComputeStep(cancel: true))
        await assertCancelled(engine, scene: scene, width: 48, subject: .sphere)
        await assertCacheUsage(engine, images: [])
        XCTAssertEqual(script.counts.releases, 1)
        XCTAssertEqual(script.counts.render, 0)
        budget.reset()
        script.set(.validation, to: ComputeStep())
        let retried = try await engine.render(scene: scene, width: 48)
        XCTAssertEqual(retried.backend, .metal)
        XCTAssertEqual(script.counts.factory, 2)
        XCTAssertEqual(script.counts.validation, 2)
        XCTAssertEqual(script.counts.render, 1)
    }

    func testConfirmedStartupFailuresSelectCPUBeforeConcurrentCancellation() async throws {
        let failures: [ComputeOutcome] = [.metal(.unavailable), .metal(.allocation), .metal(.command),
                                          .metal(.parity), .study(.invalidComputeOutput)]
        for stage in [ComputeStage.factory, .validation] {
            for failure in failures {
                for cancel in [false, true] {
                    let budget = CancellationBudget()
                    let script = ComputeScript(budget: budget)
                    let engine = scriptedEngine(budget: budget, script: script)
                    let scene = computeScene()
                    script.set(stage, to: ComputeStep(failure, cancel: cancel))
                    if cancel {
                        await assertCancelled(engine, scene: scene, width: 48, subject: .sphere)
                        await assertCacheUsage(engine, images: [])
                    } else {
                        let fallback = try await engine.render(scene: scene, width: 48)
                        XCTAssertEqual(fallback.backend, .cpu)
                        XCTAssertEqual(fallback.image, try ReferenceStudyRenderer.render(scene: scene, width: 48))
                        await assertCacheUsage(engine, images: [fallback.image])
                    }
                    budget.reset()
                    script.set(stage, to: ComputeStep())
                    // An uncached key distinguishes a permanent downgrade from
                    // merely returning a previously cached CPU fallback.
                    var fresh = scene
                    fresh.previewSettings?.exposureStops = 1
                    let next = try await engine.render(scene: fresh, width: 48)
                    XCTAssertEqual(next.backend, .cpu)
                    XCTAssertEqual(next.image, try ReferenceStudyRenderer.render(scene: fresh, width: 48))
                    XCTAssertEqual(script.counts.factory, 1)
                    XCTAssertEqual(script.counts.validation, stage == .factory ? 0 : 1)
                    XCTAssertEqual(script.counts.render, 0)
                    XCTAssertEqual(script.counts.releases, stage == .factory ? 0 : 1)
                }
            }
        }
    }

    func testStartupPrecisionDomainFallbackRemainsRetryable() async throws {
        for stage in [ComputeStage.factory, .validation] {
            for cancel in [false, true] {
                let budget = CancellationBudget()
                let script = ComputeScript(budget: budget)
                let engine = scriptedEngine(budget: budget, script: script)
                let scene = computeScene()
                script.set(stage, to: ComputeStep(.metal(.precisionDomain), cancel: cancel))
                if cancel {
                    await assertCancelled(engine, scene: scene, width: 48, subject: .sphere)
                    await assertCacheUsage(engine, images: [])
                } else {
                    let fallback = try await engine.render(scene: scene, width: 48)
                    XCTAssertEqual(fallback.backend, .cpu)
                    XCTAssertEqual(fallback.image, try ReferenceStudyRenderer.render(scene: scene, width: 48))
                    await assertCacheUsage(engine, images: [fallback.image])
                }
                budget.reset()
                script.set(stage, to: ComputeStep())
                var fresh = scene
                fresh.previewSettings?.exposureStops = 1
                let next = try await engine.render(scene: fresh, width: 48)
                XCTAssertEqual(next.backend, .metal)
                XCTAssertEqual(script.counts.factory, 2)
                XCTAssertEqual(script.counts.validation, stage == .factory ? 1 : 2)
                XCTAssertEqual(script.counts.render, 1)
            }
        }
    }

    func testFactoryIsDeferredUntilEligibleUncachedSphereRequest() async throws {
        let budget = CancellationBudget()
        let script = ComputeScript(budget: budget)
        let engine = scriptedEngine(budget: budget, script: script)
        let scene = computeScene()
        _ = try await engine.render(scene: scene, width: 24, subject: .bust)
        var distant = scene
        distant.camera.z = 25
        XCTAssertFalse(MetalStudyRenderer.supports(distant, width: 48))
        let cpu = try await engine.render(scene: distant, width: 48)
        XCTAssertEqual(cpu.backend, .cpu)
        await assertStudyError(.invalidResolution, engine: engine, scene: scene, width: 25)
        var invalidCamera = scene
        invalidCamera.camera = invalidCamera.subject
        await assertStudyError(.invalidCamera, engine: engine, scene: invalidCamera)
        var invalidScene = scene
        invalidScene.lights[0].name = ""
        await assertStudyError(.invalidScene, engine: engine, scene: invalidScene)
        budget.reset(cancelAt: 1)
        await assertCancelled(engine, scene: scene, width: 48, subject: .sphere)
        XCTAssertEqual(script.counts.factory, 0)
        XCTAssertEqual(script.counts.validation, 0)
        XCTAssertEqual(script.counts.render, 0)

        budget.reset()
        let compute = try await engine.render(scene: scene, width: 48)
        XCTAssertEqual(compute.backend, .metal)
        distant.previewSettings?.exposureStops = 1
        let laterCPU = try await engine.render(scene: distant, width: 48)
        XCTAssertEqual(laterCPU.backend, .cpu)
        XCTAssertEqual(laterCPU.image, try ReferenceStudyRenderer.render(scene: distant, width: 48))
        var fresh = scene
        fresh.previewSettings?.exposureStops = 1
        let next = try await engine.render(scene: fresh, width: 48)
        XCTAssertEqual(next.backend, .metal)
        XCTAssertEqual(script.counts.factory, 1)
        XCTAssertEqual(script.counts.validation, 1)
        XCTAssertEqual(script.counts.render, 2)
    }

    func testCancelledHitLeavesFullCacheEvictionOrderUnchanged() async throws {
        // Each cancellation boundary starts with a fresh full LRU: A, B, C, D.
        // A cancelled lookup of A must not promote it ahead of inserting E.
        for check in [1, 2] {
            let budget = CancellationBudget()
            let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
            let original = portraitScene()
            let scenes = (0..<5).map { exposure in
                var scene = original
                scene.previewSettings?.exposureStops = Double(exposure)
                return scene
            }
            var frames: [StudyRenderedFrame] = []
            for scene in scenes.prefix(4) {
                frames.append(try await engine.render(scene: scene, width: 24, subject: .bust))
            }
            await assertCacheUsage(engine, images: frames.map(\.image))

            budget.reset(cancelAt: check)
            await assertCancelled(engine, scene: scenes[0])
            XCTAssertEqual(budget.checkCount, check)
            await assertCacheUsage(engine, images: frames.map(\.image))
            budget.reset()
            let newest = try await engine.render(scene: scenes[4], width: 24, subject: .bust)
            let survivors = Array(frames.dropFirst()) + [newest]
            await assertCacheUsage(engine, images: survivors.map(\.image))

            // Probe eviction before any successful hit can change the order.
            // A promote-before-cancel bug retains A and evicts B instead.
            budget.reset(cancelAt: 8)
            await assertCancelled(engine, scene: scenes[0])
            for index in 1...4 {
                let reused = try await cachedFrame(engine, budget: budget, scene: scenes[index])
                XCTAssertEqual(reused.image, survivors[index - 1].image)
                XCTAssertEqual(reused.backend, .cpu)
            }
            await assertCacheUsage(engine, images: survivors.map(\.image))
        }
    }

    private struct CacheResourceMeasurement: Encodable {
        struct Dimensions: Encodable {
            let width: Int
            let height: Int
        }

        let fixture: String
        let dimensions: [Dimensions]
        let count: Int
        let pixelBytes: Int
        let maskBytes: Int
    }

    private func assertCPUResourceFrame(_ frame: StudyRenderedFrame, width: Int, height: Int,
                                        file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(frame.backend, .cpu, file: file, line: line)
        XCTAssertEqual(frame.image.width, width, file: file, line: line)
        XCTAssertEqual(frame.image.height, height, file: file, line: line)
        XCTAssertEqual(frame.image.rgba.count, width * height * 4, file: file, line: line)
        XCTAssertEqual(frame.image.unsupportedPixelMask.count, width * height, file: file, line: line)
    }

    /// The logged counters come from the actor after real CPU rendering.
    /// Returned images independently cross-check its retained payload accounting.
    /// These bytes exclude caller-held image copies, allocator overhead, Metal
    /// driver resources and process RSS. Fixtures and dimensions contain no names.
    private func recordCacheResources(_ engine: StudyRenderEngine, fixture: String,
                                      retained: [StudyRenderedFrame], expectedCount: Int,
                                      expectedPixelBytes: Int, expectedMaskBytes: Int,
                                      file: StaticString = #filePath, line: UInt = #line) async throws {
        let usage = await engine.cacheUsage
        let row = CacheResourceMeasurement(fixture: fixture,
            dimensions: retained.map {
                CacheResourceMeasurement.Dimensions(width: $0.image.width, height: $0.image.height)
            }, count: usage.count, pixelBytes: usage.pixelBytes, maskBytes: usage.maskBytes)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(row), as: UTF8.self)
        print("KEYFILL_CACHE_RESOURCES \(json)")

        XCTAssertEqual(usage.count, expectedCount, file: file, line: line)
        XCTAssertEqual(usage.pixelBytes, expectedPixelBytes, file: file, line: line)
        XCTAssertEqual(usage.maskBytes, expectedMaskBytes, file: file, line: line)
        XCTAssertEqual(usage.count, retained.count, file: file, line: line)
        XCTAssertEqual(usage.pixelBytes, retained.reduce(0) { $0 + $1.image.rgba.count },
                       file: file, line: line)
        XCTAssertEqual(usage.maskBytes, retained.reduce(0) { $0 + $1.image.unsupportedPixelMask.count },
                       file: file, line: line)
        XCTAssertLessThanOrEqual(usage.count, 4, file: file, line: line)
        XCTAssertLessThanOrEqual(usage.pixelBytes, 262_144, file: file, line: line)
        XCTAssertLessThanOrEqual(usage.maskBytes, 65_536, file: file, line: line)
    }

    func testRealCPUCacheResourcesForFourSmallFrames() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let original = portraitScene()
        let scenes = (0..<4).map { exposure in
            var scene = original
            scene.previewSettings?.exposureStops = Double(exposure)
            return scene
        }
        var frames: [StudyRenderedFrame] = []
        for scene in scenes {
            let frame = try await engine.render(scene: scene, width: 24, subject: .bust)
            assertCPUResourceFrame(frame, width: 24, height: 16)
            frames.append(frame)
            let step = frames.count
            try await recordCacheResources(engine, fixture: "small-bust-step-\(step)", retained: frames,
                expectedCount: step, expectedPixelBytes: 1_536 * step, expectedMaskBytes: 384 * step)
        }
        try await recordCacheResources(engine, fixture: "small-bust", retained: frames,
            expectedCount: 4, expectedPixelBytes: 6_144, expectedMaskBytes: 1_536)
        // All four entries fit; every lookup must succeed without CPU work.
        for index in scenes.indices {
            let reused = try await cachedFrame(engine, budget: budget, scene: scenes[index])
            XCTAssertEqual(reused.image, frames[index].image)
        }
    }

    func testRealCPUCacheResourcesForFourMaximumBustFrames() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let original = portraitScene()
        let scenes = (0..<4).map { exposure in
            var scene = original
            scene.previewSettings?.exposureStops = Double(exposure)
            return scene
        }
        var frames: [StudyRenderedFrame] = []
        for scene in scenes {
            // The requested sphere-size width must still clamp to 144 for busts.
            let frame = try await engine.render(scene: scene, width: 192, subject: .bust)
            assertCPUResourceFrame(frame, width: 144, height: 96)
            frames.append(frame)
            let step = frames.count
            try await recordCacheResources(engine, fixture: "maximum-bust-step-\(step)", retained: frames,
                expectedCount: step, expectedPixelBytes: 55_296 * step, expectedMaskBytes: 13_824 * step)
        }
        try await recordCacheResources(engine, fixture: "maximum-bust", retained: frames,
            expectedCount: 4, expectedPixelBytes: 221_184, expectedMaskBytes: 55_296)
        for index in scenes.indices {
            let reused = try await cachedFrame(engine, budget: budget, scene: scenes[index], width: 144)
            XCTAssertEqual(reused.image, frames[index].image)
        }
    }

    func testRealCPUCacheResourcesForMaximumSpheresEvictOldest() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        var original = LightingScene.portrait()
        original.camera.z = 25
        original.previewSettings = .init()
        // Stay outside Metal's precision domain on every host.
        XCTAssertFalse(MetalStudyRenderer.supports(original, width: 192))
        let scenes = (0..<3).map { exposure in
            var scene = original
            scene.previewSettings?.exposureStops = Double(exposure)
            return scene
        }
        var frames: [StudyRenderedFrame] = []
        for scene in scenes {
            let frame = try await engine.render(scene: scene, width: 192, subject: .sphere)
            assertCPUResourceFrame(frame, width: 192, height: 128)
            frames.append(frame)
            let step = frames.count
            let retainedCount = min(step, 2)
            try await recordCacheResources(engine, fixture: "maximum-sphere-step-\(step)",
                retained: Array(frames.suffix(2)), expectedCount: retainedCount,
                expectedPixelBytes: 98_304 * retainedCount, expectedMaskBytes: 24_576 * retainedCount)
        }
        let retained = Array(frames.suffix(2))
        try await recordCacheResources(engine, fixture: "maximum-sphere", retained: retained,
            expectedCount: 2, expectedPixelBytes: 196_608, expectedMaskBytes: 49_152)
        budget.reset(cancelAt: 8)
        await assertCancelled(engine, scene: scenes[0], width: 192, subject: .sphere)
        for index in 1...2 {
            let reused = try await cachedFrame(engine, budget: budget, scene: scenes[index],
                                               width: 192, subject: .sphere)
            XCTAssertEqual(reused.image, frames[index].image)
        }
        await assertCacheUsage(engine, images: retained.map(\.image))
    }

    func testRealCPUCacheResourcesForMixedSubjectsEvictOnlyOldestBust() async throws {
        let budget = CancellationBudget()
        let engine = StudyRenderEngine(cancellationRequested: { budget.requested() })
        let original = portraitScene()
        let bustScenes = (0..<3).map { exposure in
            var scene = original
            scene.previewSettings?.exposureStops = Double(exposure)
            return scene
        }
        var bustFrames: [StudyRenderedFrame] = []
        for scene in bustScenes {
            let frame = try await engine.render(scene: scene, width: 144, subject: .bust)
            assertCPUResourceFrame(frame, width: 144, height: 96)
            bustFrames.append(frame)
            let step = bustFrames.count
            try await recordCacheResources(engine, fixture: "mixed-bust-sphere-step-\(step)",
                retained: bustFrames, expectedCount: step,
                expectedPixelBytes: 55_296 * step, expectedMaskBytes: 13_824 * step)
        }
        var sphereScene = LightingScene.portrait()
        sphereScene.camera.z = 25
        XCTAssertFalse(MetalStudyRenderer.supports(sphereScene, width: 192))
        let sphere = try await engine.render(scene: sphereScene, width: 192, subject: .sphere)
        assertCPUResourceFrame(sphere, width: 192, height: 128)
        let retained = Array(bustFrames.suffix(2)) + [sphere]
        try await recordCacheResources(engine, fixture: "mixed-bust-sphere-step-4", retained: retained,
            expectedCount: 3, expectedPixelBytes: 208_896, expectedMaskBytes: 52_224)
        try await recordCacheResources(engine, fixture: "mixed-bust-sphere", retained: retained,
            expectedCount: 3, expectedPixelBytes: 208_896, expectedMaskBytes: 52_224)
        // Three busts plus the sphere exceed both byte budgets. One bust alone
        // must be evicted, even though the entry-count limit would allow four.
        budget.reset(cancelAt: 8)
        await assertCancelled(engine, scene: bustScenes[0], width: 144)
        for index in 1...2 {
            let reused = try await cachedFrame(engine, budget: budget, scene: bustScenes[index], width: 144)
            XCTAssertEqual(reused.image, bustFrames[index].image)
        }
        let reusedSphere = try await cachedFrame(engine, budget: budget, scene: sphereScene,
                                                  width: 192, subject: .sphere)
        XCTAssertEqual(reusedSphere.image, sphere.image)
        await assertCacheUsage(engine, images: retained.map(\.image))
    }

    /// This observer cannot extend the backend's lifetime. The lock protects
    /// weak storage across the test executor and actor; no backend method is
    /// called outside the actor, and the getter returns only a Boolean.
    private final class WeakComputeBackendObserver: @unchecked Sendable {
        private let lock = NSLock()
        private weak var backend: ScriptedComputeBackend?

        func observe(_ value: ScriptedComputeBackend) {
            lock.lock()
            backend = value
            lock.unlock()
        }

        var isAlive: Bool {
            lock.lock()
            defer { lock.unlock() }
            return backend != nil
        }
    }

    func testFailedBackendReleasesWeaklyObservedInstanceWhileEngineRemainsAlive() async throws {
        // First falsify accidental ownership by the observer itself. The test
        // explicitly drops its only strong reference before checking the weak one.
        let controlScript = ComputeScript(budget: CancellationBudget())
        let controlObserver = WeakComputeBackendObserver()
        var controlBackend: ScriptedComputeBackend? = ScriptedComputeBackend(script: controlScript)
        controlObserver.observe(controlBackend!)
        withExtendedLifetime(controlBackend) {
            XCTAssertTrue(controlObserver.isAlive)
        }
        controlBackend = nil
        XCTAssertFalse(controlObserver.isAlive)
        XCTAssertEqual(controlScript.counts.releases, 1)

        let failures: [ComputeOutcome] = [.metal(.command), .metal(.allocation), .study(.invalidComputeOutput)]
        for failure in failures {
            for cancel in [false, true] {
                let budget = CancellationBudget()
                let script = ComputeScript(budget: budget)
                let observer = WeakComputeBackendObserver()
                // Only script and observer are captured. The backend is created
                // inside this factory; its local reference ends on return.
                let engine = StudyRenderEngine(cancellationRequested: { budget.requested() },
                    makeComputeBackend: {
                        try script.run(.factory)
                        let backend = ScriptedComputeBackend(script: script)
                        observer.observe(backend)
                        return backend
                    })
                let cpuScene = portraitScene()
                let cpu = try await engine.render(scene: cpuScene, width: 24, subject: .bust)
                let original = computeScene()
                let compute = try await engine.render(scene: original, width: 48)
                XCTAssertEqual(compute.backend, .metal)
                XCTAssertTrue(observer.isAlive, "The live actor must own its validated backend")
                XCTAssertEqual(script.counts.releases, 0)
                await assertCacheUsage(engine, images: [cpu.image, compute.image])

                var failed = original
                failed.previewSettings?.exposureStops = 1
                script.set(.render, to: ComputeStep(failure, cancel: cancel))
                var retainedImages = [cpu.image]
                if cancel {
                    await assertCancelled(engine, scene: failed, width: 48, subject: .sphere)
                } else {
                    let fallback = try await engine.render(scene: failed, width: 48)
                    XCTAssertEqual(fallback.backend, .cpu)
                    XCTAssertEqual(fallback.image, try ReferenceStudyRenderer.render(scene: failed, width: 48))
                    retainedImages.append(fallback.image)
                }
                // Await has unwound the render callback and all temporary strong
                // backend references. Keep using the same engine below, proving
                // release follows downgrade rather than actor destruction.
                XCTAssertFalse(observer.isAlive)
                XCTAssertEqual(script.counts.releases, 1)
                await assertCacheUsage(engine, images: retainedImages)
                let preserved = try await cachedFrame(engine, budget: budget, scene: cpuScene)
                XCTAssertEqual(preserved.backend, .cpu)
                XCTAssertEqual(preserved.image, cpu.image)

                var fresh = original
                fresh.previewSettings?.exposureStops = 2
                let next = try await engine.render(scene: fresh, width: 48)
                XCTAssertEqual(next.backend, .cpu)
                XCTAssertFalse(observer.isAlive)
                XCTAssertEqual(script.counts.factory, 1)
                XCTAssertEqual(script.counts.validation, 1)
                XCTAssertEqual(script.counts.render, 2)
                XCTAssertEqual(script.counts.releases, 1)
            }
        }
    }

    // These additional cases use the existing scripted backend for lifecycle
    // evidence only. Synthetic compute frames are not actual Metal output.
    func testStartupFailureWithCancellationPreservesPreviouslyCachedCPUFrame() async throws {
        // Exercise both catch paths that confirm failure while the cache already
        // holds CPU pixels. The broader startup failure matrix remains above.
        let failures: [ComputeOutcome] = [.metal(.parity), .study(.invalidComputeOutput)]
        for stage in [ComputeStage.factory, .validation] {
            for failure in failures {
                let budget = CancellationBudget()
                let script = ComputeScript(budget: budget)
                let engine = scriptedEngine(budget: budget, script: script)
                let cpuScene = portraitScene()
                let cpu = try await engine.render(scene: cpuScene, width: 24, subject: .bust)
                XCTAssertEqual(cpu.backend, .cpu)
                XCTAssertEqual(script.counts.factory, 0)
                await assertCacheUsage(engine, images: [cpu.image])

                let interrupted = computeScene()
                script.set(stage, to: ComputeStep(failure, cancel: true))
                await assertCancelled(engine, scene: interrupted, width: 48, subject: .sphere)
                await assertCacheUsage(engine, images: [cpu.image])
                XCTAssertEqual(script.counts.factory, 1)
                XCTAssertEqual(script.counts.validation, stage == .factory ? 0 : 1)
                XCTAssertEqual(script.counts.render, 0)
                XCTAssertEqual(script.counts.releases, stage == .factory ? 0 : 1)
                let preserved = try await cachedFrame(engine, budget: budget, scene: cpuScene)
                XCTAssertEqual(preserved.backend, .cpu)
                XCTAssertEqual(preserved.image, cpu.image)

                // The failed request must still be cold after cancellation.
                // A retained CPU fallback would incorrectly pass this probe.
                script.set(stage, to: ComputeStep())
                budget.reset(cancelAt: 8)
                await assertCancelled(engine, scene: interrupted, width: 48, subject: .sphere)
                await assertCacheUsage(engine, images: [cpu.image])
                budget.reset()
                var fresh = interrupted
                fresh.previewSettings?.exposureStops = 1
                let next = try await engine.render(scene: fresh, width: 48)
                XCTAssertEqual(next.backend, .cpu)
                XCTAssertEqual(next.image, try ReferenceStudyRenderer.render(scene: fresh, width: 48))
                XCTAssertEqual(script.counts.factory, 1)
                XCTAssertEqual(script.counts.validation, stage == .factory ? 0 : 1)
                XCTAssertEqual(script.counts.render, 0)
                await assertCacheUsage(engine, images: [cpu.image, next.image])
            }
        }
    }

    func testCancelledValidationPreservesCPUCacheAndRetriesOnSameEngine() async throws {
        // Cover a thrown cancellation and the final cancellation check after
        // validate returns. Neither may adopt the unchecked backend.
        for step in [ComputeStep(.study(.cancelled)), ComputeStep(cancel: true)] {
            let budget = CancellationBudget()
            let script = ComputeScript(budget: budget)
            let engine = scriptedEngine(budget: budget, script: script)
            let cpuScene = portraitScene()
            let cpu = try await engine.render(scene: cpuScene, width: 24, subject: .bust)
            XCTAssertEqual(cpu.backend, .cpu)
            XCTAssertEqual(script.counts.factory, 0)

            let interrupted = computeScene()
            script.set(.validation, to: step)
            await assertCancelled(engine, scene: interrupted, width: 48, subject: .sphere)
            await assertCacheUsage(engine, images: [cpu.image])
            XCTAssertEqual(script.counts.factory, 1)
            XCTAssertEqual(script.counts.validation, 1)
            XCTAssertEqual(script.counts.render, 0)
            XCTAssertEqual(script.counts.releases, 1)
            let preserved = try await cachedFrame(engine, budget: budget, scene: cpuScene)
            XCTAssertEqual(preserved.backend, .cpu)
            XCTAssertEqual(preserved.image, cpu.image)
            XCTAssertEqual(script.counts.factory, 1)
            XCTAssertEqual(script.counts.validation, 1)

            script.set(.validation, to: ComputeStep())
            var fresh = interrupted
            fresh.previewSettings?.exposureStops = 1
            let next = try await engine.render(scene: fresh, width: 48)
            XCTAssertEqual(next.backend, .metal)
            XCTAssertEqual(script.counts.factory, 2)
            XCTAssertEqual(script.counts.validation, 2)
            XCTAssertEqual(script.counts.render, 1)
            XCTAssertEqual(script.counts.releases, 1)
            await assertCacheUsage(engine, images: [cpu.image, next.image])

            // Revisit the original interrupted key only after validating with
            // a distinct key. It must require its own successful render.
            let retried = try await engine.render(scene: interrupted, width: 48)
            XCTAssertEqual(retried.backend, .metal)
            XCTAssertEqual(script.counts.factory, 2)
            XCTAssertEqual(script.counts.validation, 2)
            XCTAssertEqual(script.counts.render, 2)
            let stillCached = try await cachedFrame(engine, budget: budget, scene: cpuScene)
            XCTAssertEqual(stillCached.backend, .cpu)
            XCTAssertEqual(stillCached.image, cpu.image)
            await assertCacheUsage(engine, images: [cpu.image, next.image, retried.image])
        }
    }

    func testConcurrentEligibleRequestsValidateOnceAndCacheDistinctImages() async throws {
        let budget = CancellationBudget()
        let script = ComputeScript(budget: budget)
        let engine = scriptedEngine(budget: budget, script: script)
        let scene = computeScene()
        // Select three distinct eligible widths deterministically. The images
        // differ in dimensions even though this existing fake uses white pixels.
        let widths = Array(stride(from: 24, through: 192, by: 3).filter {
            MetalStudyRenderer.supports(scene, width: $0)
        }.prefix(3))
        XCTAssertEqual(widths.count, 3, "This fixture must supply three eligible requests")
        guard widths.count == 3 else { return }

        // Submit all children before collecting results. Assertions do not
        // depend on start order, completion order, delays or actor scheduling.
        let frames = try await withThrowingTaskGroup(of: (Int, StudyRenderedFrame).self) { group in
            for width in widths {
                group.addTask {
                    let frame = try await engine.render(scene: scene, width: width)
                    return (width, frame)
                }
            }
            var completed: [Int: StudyRenderedFrame] = [:]
            for try await (width, frame) in group {
                XCTAssertNil(completed.updateValue(frame, forKey: width))
            }
            return completed
        }
        XCTAssertEqual(frames.count, widths.count)
        XCTAssertEqual(script.counts.factory, 1)
        XCTAssertEqual(script.counts.validation, 1)
        XCTAssertEqual(script.counts.render, widths.count)
        XCTAssertEqual(script.counts.releases, 0)

        let expectedImages = try widths.map { width in
            try StudyImage.fromComputeRGBA(width: width, height: width * 2 / 3,
                data: Data(repeating: 255, count: width * (width * 2 / 3) * 4))
        }
        for (index, width) in widths.enumerated() {
            let frame = try XCTUnwrap(frames[width])
            XCTAssertEqual(frame.backend, .metal)
            XCTAssertEqual(frame.image, expectedImages[index])
        }
        await assertCacheUsage(engine, images: expectedImages)

        // Any miss now throws, so a same-image rerender cannot masquerade as
        // cache reuse. Lookup order deliberately differs from submission order.
        script.set(.render, to: ComputeStep(.study(.invalidSurface)))
        for index in widths.indices.reversed() {
            let cached = try await cachedFrame(engine, budget: budget, scene: scene,
                                                 width: widths[index], subject: .sphere)
            XCTAssertEqual(cached.backend, .metal)
            XCTAssertEqual(cached.image, expectedImages[index])
        }
        XCTAssertEqual(script.counts.factory, 1)
        XCTAssertEqual(script.counts.validation, 1)
        XCTAssertEqual(script.counts.render, widths.count)
        XCTAssertEqual(script.counts.releases, 0)
        await assertCacheUsage(engine, images: expectedImages)
    }

    func testSteadyStateSceneErrorsPreserveValidatedBackendAndCachedFrames() async throws {
        let errors: [StudyError] = [.invalidScene, .invalidCamera, .invalidResolution,
                                    .invalidEmitter, .invalidSurface]
        for error in errors {
            let budget = CancellationBudget()
            let script = ComputeScript(budget: budget)
            let engine = scriptedEngine(budget: budget, script: script)
            let cpuScene = portraitScene()
            let cpu = try await engine.render(scene: cpuScene, width: 24, subject: .bust)
            let original = computeScene()
            let first = try await engine.render(scene: original, width: 48)
            XCTAssertEqual(first.backend, .metal)
            var failed = original
            failed.previewSettings?.exposureStops = 1
            // Valid eligible input ensures the injected scene error reaches the
            // steady-state backend catch, rather than failing before startup.
            script.set(.render, to: ComputeStep(.study(error)))
            await assertStudyError(error, engine: engine, scene: failed)
            XCTAssertEqual(script.counts.render, 2)
            XCTAssertEqual(script.counts.releases, 0)
            await assertCacheUsage(engine, images: [cpu.image, first.image])

            let cached = try await cachedFrame(engine, budget: budget, scene: original,
                                                width: 48, subject: .sphere)
            XCTAssertEqual(cached.backend, .metal)
            XCTAssertEqual(cached.image, first.image)
            let preserved = try await cachedFrame(engine, budget: budget, scene: cpuScene)
            XCTAssertEqual(preserved.backend, .cpu)
            XCTAssertEqual(preserved.image, cpu.image)
            XCTAssertEqual(script.counts.render, 2)

            // Repeat while failure is still armed: the errored key must remain
            // uncached, without discarding either completed frame.
            await assertStudyError(error, engine: engine, scene: failed)
            XCTAssertEqual(script.counts.render, 3)
            await assertCacheUsage(engine, images: [cpu.image, first.image])
            script.set(.render, to: ComputeStep())
            let retried = try await engine.render(scene: failed, width: 48)
            XCTAssertEqual(retried.backend, .metal)
            XCTAssertEqual(script.counts.factory, 1)
            XCTAssertEqual(script.counts.validation, 1)
            XCTAssertEqual(script.counts.render, 4)
            XCTAssertEqual(script.counts.releases, 0)
            await assertCacheUsage(engine, images: [cpu.image, first.image, retried.image])
        }
    }

}
