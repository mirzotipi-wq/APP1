import Foundation
import Metal
import LightingCore

enum StudyBackend: String, Sendable {
    case cpu = "CPU reference"
    case metal = "Metal compute"
}

struct StudyRenderedFrame: Sendable {
    let image: StudyImage
    let backend: StudyBackend
}

enum MetalStudyError: Error {
    case unavailable, allocation, command, parity, precisionDomain
}

/// The actor creates and exclusively owns its backend. Keeping this contract
/// synchronous avoids transferring Metal resources across isolation boundaries.
protocol StudyComputeBackend {
    func validate(isCancelled: () -> Bool) throws
    func render(scene: LightingScene, width: Int, isCancelled: () -> Bool) throws -> StudyImage
}

/// Retains the compiled pipeline/queue. Used only inside the render actor or
/// a serial native parity test. The buffer layout is explicit float4/uchar4.
final class MetalStudyRenderer: StudyComputeBackend {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLComputePipelineState

    init(device: MTLDevice) throws {
        guard let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "keyfillStudy") else {
            throw MetalStudyError.unavailable
        }
        self.device = device; self.queue = queue
        pipeline = try device.makeComputePipelineState(function: function)
    }

    /// Far-away geometry and potentially ambiguous near-field masks stay on
    /// the Double-precision oracle. Routing does not invalidate this backend.
    static func supports(_ scene: LightingScene) -> Bool {
        supports(scene, width: 192)
    }

    static func supports(_ scene: LightingScene, width: Int) -> Bool {
        StudyFloat32Eligibility.supports(scene, width: width)
    }

    func render(scene: LightingScene, width: Int,
                isCancelled: () -> Bool = { Task.isCancelled }) throws -> StudyImage {
        // Preserve the compute input's resolution error before the
        // width-aware precision predicate can reject the request.
        guard width >= 24, width <= 192, width.isMultiple(of: 3) else { throw StudyError.invalidResolution }
        // Preserve the CPU constructor's scene/camera errors before making
        // the optional precision routing decision. No GPU resource is made
        // until both input validation and eligibility have succeeded.
        guard !isCancelled() else { throw StudyError.cancelled }
        let input = try StudyComputeInput(scene: scene, width: width)
        guard Self.supports(scene, width: width) else { throw MetalStudyError.precisionDomain }
        return try compute(input, isCancelled: isCancelled)
    }

    /// Internal parity-only path: retain the deliberately unsupported fixture
    /// even though production routing now chooses CPU for near-field scenes.
    /// Input validation and the relative-coordinate limit still apply. The
    /// render engine never uses this entry point to publish a user's frame.
    func renderValidationFixture(scene: LightingScene, width: Int,
                                 isCancelled: () -> Bool = { Task.isCancelled }) throws -> StudyImage {
        let limit = StudyFloat32Eligibility.maximumRelativeDistanceMeters
        guard scene.camera.distance(to: scene.subject) <= limit,
              scene.lights.allSatisfy({ $0.position.distance(to: scene.subject) <= limit })
        else { throw MetalStudyError.precisionDomain }
        guard !isCancelled() else { throw StudyError.cancelled }
        return try compute(StudyComputeInput(scene: scene, width: width), isCancelled: isCancelled)
    }

    private func compute(_ input: StudyComputeInput,
                         isCancelled: () -> Bool = { Task.isCancelled }) throws -> StudyImage {
        try autoreleasepool {
            guard !isCancelled() else { throw StudyError.cancelled }
            guard let params = buffer(input.parameters),
                  let samples = buffer(input.samples),
                  let areas = buffer(input.areas),
                  let output = device.makeBuffer(length: input.width * input.height * 4, options: .storageModeShared),
                  let command = queue.makeCommandBuffer(),
                  let encoder = command.makeComputeCommandEncoder() else { throw MetalStudyError.allocation }
            command.label = "Key & Fill diagnostic study"
            encoder.setComputePipelineState(pipeline)
            encoder.setBuffer(params, offset: 0, index: 0)
            encoder.setBuffer(samples, offset: 0, index: 1)
            encoder.setBuffer(areas, offset: 0, index: 2)
            encoder.setBuffer(output, offset: 0, index: 3)
            var dimensions = SIMD2<UInt32>(UInt32(input.width), UInt32(input.height))
            encoder.setBytes(&dimensions, length: MemoryLayout<SIMD2<UInt32>>.stride, index: 4)
            let groupWidth = min(pipeline.threadExecutionWidth, pipeline.maxTotalThreadsPerThreadgroup)
            guard groupWidth > 0 else { encoder.endEncoding(); throw MetalStudyError.command }
            let groupHeight = max(1, min(8, pipeline.maxTotalThreadsPerThreadgroup / groupWidth))
            let group = MTLSize(width: groupWidth, height: groupHeight, depth: 1)
            let count = MTLSize(width: (input.width + groupWidth - 1) / groupWidth,
                                height: (input.height + groupHeight - 1) / groupHeight, depth: 1)
            encoder.dispatchThreadgroups(count, threadsPerThreadgroup: group)
            encoder.endEncoding()
            guard !isCancelled() else { throw StudyError.cancelled }
            command.commit()
            // Submitted work keeps its buffers alive until completion. A real
            // command failure remains visible even if cancellation also arrives.
            command.waitUntilCompleted()
            guard command.status == .completed else { throw MetalStudyError.command }
            guard !isCancelled() else { throw StudyError.cancelled }
            let bytes = Data(bytes: output.contents(), count: input.width * input.height * 4)
            return try StudyImage.fromComputeRGBA(width: input.width, height: input.height, data: bytes)
        }
    }

    /// Fail closed to CPU on any image-parity failure. Runtime gate is a numerical
    /// sanity check, not a measured performance or physical-rendering claim.
    func validate(isCancelled: () -> Bool = { Task.isCancelled }) throws {
        for fixture in StudyValidationFixtures.all() {
            guard !isCancelled() else { throw StudyError.cancelled }
            let reference = try ReferenceStudyRenderer.render(scene: fixture.scene, width: 48,
                                                               isCancelled: isCancelled)
            guard !isCancelled() else { throw StudyError.cancelled }
            let candidate = try renderValidationFixture(scene: fixture.scene, width: 48,
                                                         isCancelled: isCancelled)
            // A submitted GPU command must finish before its buffers can be
            // read, but cancellation prevents starting another fixture.
            guard !isCancelled() else { throw StudyError.cancelled }
            guard StudyParityMetrics(reference: reference, candidate: candidate)?.passes == true else {
                throw MetalStudyError.parity
            }
        }
    }

    private func buffer(_ rows: [SIMD4<Float>]) -> MTLBuffer? {
        // Metal requires a valid binding even when the shader's count is zero.
        let storage = rows.isEmpty ? [SIMD4<Float>.zero] : rows
        return storage.withUnsafeBufferPointer { pointer in
            guard let base = pointer.baseAddress else { return nil }
            return device.makeBuffer(bytes: UnsafeRawPointer(base),
                                     length: pointer.count * MemoryLayout<SIMD4<Float>>.stride,
                                     options: .storageModeShared)
        }
    }
}

/// Single worker serializes compute submissions and CPU fallbacks. Cooperative
/// cancellation guards frame return and cache admission; callers still decide
/// whether to adopt a returned frame. Submitted GPU work completes before its
/// buffers are released; CPU work checks cancellation every eight evaluations.
actor StudyRenderEngine {
    static let shared = StudyRenderEngine()
    // Bound both the number of scene snapshots and retained RGBA storage.
    // Four small frames fit; at 192 × 128 the byte limit retains at most two.
    static let maximumCachedFrames = 4
    static let maximumCachedPixelBytes = 256 * 1024
    static let maximumCachedMaskBytes = 64 * 1024

    private struct CacheKey: Equatable, Sendable {
        let scene: LightingScene
        let width: Int
        let subject: StudySubject

        init?(scene: LightingScene, width: Int, subject: StudySubject) {
            // A hit must never bypass validation of metadata that the renderer
            // otherwise rejects. Leave errors and their ordering to the actual
            // render path when validation fails.
            guard (try? scene.validated()) != nil else { return nil }
            var snapshot = scene
            snapshot.lights = scene.lights.map { light in
                var copy = light
                // Display names do not affect pixels. Do not retain arbitrary
                // Unicode storage: the 80-character limit is not a byte limit.
                copy.name = ""
                return copy
            }
            // Retain every other scene value, including complete optics, light
            // order, camera, exposure and room metadata. Equality is exact;
            // there is no hash-only or rounded-coordinate cache identity.
            self.scene = snapshot
            self.width = width
            self.subject = subject
        }
    }

    private enum State { case unchecked, cpu, metal(any StudyComputeBackend) }
    private var state = State.unchecked
    // Least recently used first. Validated keys contain at most twelve lights
    // and only bounded, fixed-size values after display names are removed.
    private var frameCache = StudyFrameCache<CacheKey, StudyRenderedFrame>(
        maximumCount: StudyRenderEngine.maximumCachedFrames,
        maximumPixelBytes: StudyRenderEngine.maximumCachedPixelBytes,
        maximumMaskBytes: StudyRenderEngine.maximumCachedMaskBytes)
    private let additionalCancellation: @Sendable () -> Bool
    private let makeComputeBackend: @Sendable () throws -> any StudyComputeBackend

    var cacheUsage: (count: Int, pixelBytes: Int, maskBytes: Int) {
        (frameCache.count, frameCache.pixelBytes, frameCache.maskBytes)
    }

    /// An additional cooperative cancellation source is useful to callers that
    /// invalidate work independently of a task, and permits deterministic
    /// lifecycle tests. It can never suppress actual task cancellation.
    init(cancellationRequested: @escaping @Sendable () -> Bool = { false }) {
        additionalCancellation = cancellationRequested
        makeComputeBackend = {
            guard let device = MTLCreateSystemDefaultDevice() else { throw MetalStudyError.unavailable }
            return try MetalStudyRenderer(device: device)
        }
    }

    /// The factory runs inside this actor when an eligible request first needs
    /// compute. The resulting backend is never shared with another actor.
    init(cancellationRequested: @escaping @Sendable () -> Bool = { false },
         makeComputeBackend: @escaping @Sendable () throws -> any StudyComputeBackend) {
        additionalCancellation = cancellationRequested
        self.makeComputeBackend = makeComputeBackend
    }

    func render(scene: LightingScene, width: Int = 192, subject: StudySubject = .sphere) throws -> StudyRenderedFrame {
        let additionalCancellation = additionalCancellation
        let isCancelled = { Task.isCancelled || additionalCancellation() }
        guard !isCancelled() else { throw StudyError.cancelled }
        let renderWidth = subject == .bust ? min(width, PortraitStudyRenderer.maximumWidth) : width
        let key = CacheKey(scene: scene, width: renderWidth, subject: subject)
        if let key {
            // Check before the cache promotes a hit. A cancelled request must
            // neither publish pixels nor change the eviction order.
            guard !isCancelled() else { throw StudyError.cancelled }
            if let cached = frameCache.value(for: key) { return cached }
        }
        if subject == .bust {
            // The mannequin has additional geometry. Do not send it
            // to the sphere-only Metal kernel or claim a validated GPU path.
            let image = try PortraitStudyRenderer.render(scene: scene, width: renderWidth,
                                                        isCancelled: isCancelled)
            guard !isCancelled() else { throw StudyError.cancelled }
            return retain(StudyRenderedFrame(image: image, backend: .cpu), for: key)
        }
        // Eligibility belongs to this request. CPU-only and invalid requests
        // must not initialize or change an unchecked backend.
        let supportsMetal = MetalStudyRenderer.supports(scene, width: width)
        if case .unchecked = state, supportsMetal {
            do {
                guard !isCancelled() else { throw StudyError.cancelled }
                let renderer = try makeComputeBackend()
                try renderer.validate(isCancelled: isCancelled)
                guard !isCancelled() else { throw StudyError.cancelled }
                state = .metal(renderer)
            } catch let error as StudyError {
                // Cancellation and scene errors leave startup retryable.
                // Malformed output confirms a backend failure instead.
                if error != .invalidComputeOutput { throw error }
                selectCPU()
            } catch MetalStudyError.precisionDomain {
                // A precision boundary only routes this request through CPU.
            } catch {
                // Fail closed before observing concurrent cancellation.
                selectCPU()
            }
        }
        guard !isCancelled() else { throw StudyError.cancelled }
        if case .metal(let renderer) = state, supportsMetal {
            do {
                let image = try renderer.render(scene: scene, width: width, isCancelled: isCancelled)
                guard !isCancelled() else { throw StudyError.cancelled }
                return retain(StudyRenderedFrame(image: image, backend: .metal), for: key)
            } catch let error as StudyError {
                // Validation/cancellation is a scene error, not a backend failure.
                if error != .invalidComputeOutput { throw error }
                selectCPU()
            } catch MetalStudyError.precisionDomain {
                // Preserve the validated backend for a later eligible request.
            } catch {
                selectCPU()
            }
        }
        // In particular, a precision-domain fallback must observe cancellation
        // before the CPU renderer constructs its scene and emitter samples.
        guard !isCancelled() else { throw StudyError.cancelled }
        let image = try ReferenceStudyRenderer.render(scene: scene, width: width, isCancelled: isCancelled)
        guard !isCancelled() else { throw StudyError.cancelled }
        return retain(StudyRenderedFrame(image: image, backend: .cpu), for: key)
    }

    private func selectCPU() {
        state = .cpu
        // A runtime backend failure invalidates its old frames as well. A later
        // hit must not resurrect Metal after the engine has failed closed.
        frameCache.removeAll { $0.backend == .metal }
    }

    /// Only called after the final cooperative cancellation check. There is no
    /// suspension between that check, cache admission and returning the frame.
    private func retain(_ frame: StudyRenderedFrame, for key: CacheKey?) -> StudyRenderedFrame {
        guard let key else { return frame }
        frameCache.insert(frame, for: key, pixelBytes: frame.image.rgba.count,
                          maskBytes: frame.image.unsupportedPixelMask.count)
        return frame
    }
}
