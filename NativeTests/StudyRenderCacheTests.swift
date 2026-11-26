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
}
