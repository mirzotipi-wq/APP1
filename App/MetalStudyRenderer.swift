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

/// Retains the compiled pipeline/queue. Used only inside the render actor or
/// a serial native parity test. The buffer layout is explicit float4/uchar4.
final class MetalStudyRenderer {
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
        StudyFloat32Eligibility.supports(scene)
    }

    func render(scene: LightingScene, width: Int) throws -> StudyImage {
        guard Self.supports(scene) else { throw MetalStudyError.precisionDomain }
        return try compute(StudyComputeInput(scene: scene, width: width))
    }

    /// Internal parity-only path: retain the deliberately unsupported fixture
    /// even though production routing now chooses CPU for near-field scenes.
    /// Input validation and the relative-coordinate limit still apply. The
    /// render engine never uses this entry point to publish a user's frame.
    func renderValidationFixture(scene: LightingScene, width: Int) throws -> StudyImage {
        let limit = StudyFloat32Eligibility.maximumRelativeDistanceMeters
        guard scene.camera.distance(to: scene.subject) <= limit,
              scene.lights.allSatisfy({ $0.position.distance(to: scene.subject) <= limit })
        else { throw MetalStudyError.precisionDomain }
        return try compute(StudyComputeInput(scene: scene, width: width))
    }

    private func compute(_ input: StudyComputeInput) throws -> StudyImage {
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
        command.commit()
        // Only the isolated rendering actor waits. Read shared memory after GPU completion.
        command.waitUntilCompleted()
        guard command.status == .completed else { throw MetalStudyError.command }
        let bytes = Data(bytes: output.contents(), count: input.width * input.height * 4)
        return try StudyImage.fromComputeRGBA(width: input.width, height: input.height, data: bytes)
    }

    /// Fail closed to CPU on any image-parity failure. Runtime gate is a numerical
    /// sanity check, not a measured performance or physical-rendering claim.
    func validate(isCancelled: () -> Bool = { Task.isCancelled }) throws {
        for fixture in StudyValidationFixtures.all() {
            guard !isCancelled() else { throw StudyError.cancelled }
            let reference = try ReferenceStudyRenderer.render(scene: fixture.scene, width: 48,
                                                               isCancelled: isCancelled)
            guard !isCancelled() else { throw StudyError.cancelled }
            let candidate = try renderValidationFixture(scene: fixture.scene, width: 48)
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

/// Single worker serializes compute submissions and CPU fallbacks. A cancelled
/// request cannot publish a stale frame. GPU commands already submitted are
/// allowed to complete, then discarded; CPU pixel work checks cancellation at most every eight evaluations.
actor StudyRenderEngine {
    static let shared = StudyRenderEngine()
    // Bound both the number of scene snapshots and retained RGBA storage.
    // Four small frames fit; at 192 × 128 the byte limit retains at most two.
    static let maximumCachedFrames = 4
    static let maximumCachedPixelBytes = 256 * 1024

    private struct CacheKey: Equatable {
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

    private struct CachedFrame {
        let key: CacheKey
        let frame: StudyRenderedFrame
    }

    private enum State { case unchecked, cpu, metal(MetalStudyRenderer) }
    private var state = State.unchecked
    // Least recently used first. Validated keys contain at most twelve lights
    // and only bounded, fixed-size values after display names are removed.
    private var cachedFrames: [CachedFrame] = []
    private var cachedPixelBytes = 0
    private let additionalCancellation: @Sendable () -> Bool

    /// An additional cooperative cancellation source is useful to callers that
    /// invalidate work independently of a task, and permits deterministic
    /// lifecycle tests. It can never suppress actual task cancellation.
    init(cancellationRequested: @escaping @Sendable () -> Bool = { false }) {
        additionalCancellation = cancellationRequested
    }

    func render(scene: LightingScene, width: Int = 192, subject: StudySubject = .sphere) throws -> StudyRenderedFrame {
        let additionalCancellation = additionalCancellation
        let isCancelled = { Task.isCancelled || additionalCancellation() }
        guard !isCancelled() else { throw StudyError.cancelled }
        let renderWidth = subject == .bust ? min(width, PortraitStudyRenderer.maximumWidth) : width
        let key = CacheKey(scene: scene, width: renderWidth, subject: subject)
        if let key, let index = cachedFrames.firstIndex(where: { $0.key == key }) {
            let cached = cachedFrames[index]
            guard !isCancelled() else { throw StudyError.cancelled }
            cachedFrames.remove(at: index)
            cachedFrames.append(cached)
            return cached.frame
        }
        if subject == .bust {
            // The mannequin has additional geometry. Do not send it
            // to the sphere-only Metal kernel or claim a validated GPU path.
            let image = try PortraitStudyRenderer.render(scene: scene, width: renderWidth,
                                                        isCancelled: isCancelled)
            guard !isCancelled() else { throw StudyError.cancelled }
            return retain(StudyRenderedFrame(image: image, backend: .cpu), for: key)
        }
        if case .unchecked = state {
            do {
                guard let device = MTLCreateSystemDefaultDevice() else { throw MetalStudyError.unavailable }
                let renderer = try MetalStudyRenderer(device: device)
                try renderer.validate(isCancelled: isCancelled)
                guard !isCancelled() else { throw StudyError.cancelled }
                state = .metal(renderer)
            } catch let error as StudyError where error == .cancelled {
                // Incomplete validation is not a failed backend. Leave the
                // state unchecked so the next live request can validate it.
                throw error
            } catch {
                guard !isCancelled() else { throw StudyError.cancelled }
                selectCPU()
            }
        }
        guard !isCancelled() else { throw StudyError.cancelled }
        if case .metal(let renderer) = state, MetalStudyRenderer.supports(scene) {
            do {
                let image = try renderer.render(scene: scene, width: width)
                guard !isCancelled() else { throw StudyError.cancelled }
                return retain(StudyRenderedFrame(image: image, backend: .metal), for: key)
            } catch let error as StudyError {
                // Validation/cancellation is a scene error, not a backend failure.
                if error != .invalidComputeOutput { throw error }
                guard !isCancelled() else { throw StudyError.cancelled }
                selectCPU()
            } catch {
                guard !isCancelled() else { throw StudyError.cancelled }
                selectCPU()
            }
        }
        let image = try ReferenceStudyRenderer.render(scene: scene, width: width, isCancelled: isCancelled)
        guard !isCancelled() else { throw StudyError.cancelled }
        return retain(StudyRenderedFrame(image: image, backend: .cpu), for: key)
    }

    private func selectCPU() {
        state = .cpu
        // A runtime backend failure invalidates its old frames as well. A later
        // hit must not resurrect Metal after the engine has failed closed.
        for index in cachedFrames.indices.reversed() where cachedFrames[index].frame.backend == .metal {
            cachedPixelBytes -= cachedFrames.remove(at: index).frame.image.rgba.count
        }
    }

    /// Only called after the final cooperative cancellation check. There is no
    /// suspension between that check, cache admission and returning the frame.
    private func retain(_ frame: StudyRenderedFrame, for key: CacheKey?) -> StudyRenderedFrame {
        let byteCount = frame.image.rgba.count
        guard let key, byteCount <= Self.maximumCachedPixelBytes else { return frame }
        // Evict before appending, so storage never temporarily exceeds either
        // limit. Subtraction avoids overflow even if image bounds later grow.
        while !cachedFrames.isEmpty &&
                (cachedFrames.count >= Self.maximumCachedFrames ||
                 cachedPixelBytes > Self.maximumCachedPixelBytes - byteCount) {
            cachedPixelBytes -= cachedFrames.removeFirst().frame.image.rgba.count
        }
        cachedFrames.append(CachedFrame(key: key, frame: frame))
        cachedPixelBytes += byteCount
        return frame
    }
}
