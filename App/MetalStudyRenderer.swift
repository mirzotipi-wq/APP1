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

    /// Far-away or extreme geometry stays on the Double-precision oracle.
    /// Translation to subject-relative coordinates already minimizes error.
    static func supports(_ scene: LightingScene) -> Bool {
        scene.camera.distance(to: scene.subject) <= 20 &&
        scene.lights.allSatisfy { $0.position.distance(to: scene.subject) <= 20 }
    }

    func render(scene: LightingScene, width: Int) throws -> StudyImage {
        guard Self.supports(scene) else { throw MetalStudyError.precisionDomain }
        let input = try StudyComputeInput(scene: scene, width: width)
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
            let candidate = try render(scene: fixture.scene, width: 48)
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
/// allowed to complete, then discarded; CPU scans can stop at each row.
actor StudyRenderEngine {
    static let shared = StudyRenderEngine()
    private enum State { case unchecked, cpu, metal(MetalStudyRenderer) }
    private var state = State.unchecked
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
        if subject == .bust {
            // The mannequin has additional geometry. Do not send it
            // to the sphere-only Metal kernel or claim a validated GPU path.
            let image = try PortraitStudyRenderer.render(scene: scene, width: min(width, PortraitStudyRenderer.maximumWidth),
                                                        isCancelled: isCancelled)
            guard !isCancelled() else { throw StudyError.cancelled }
            return StudyRenderedFrame(image: image, backend: .cpu)
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
                state = .cpu
            }
        }
        guard !isCancelled() else { throw StudyError.cancelled }
        if case .metal(let renderer) = state, MetalStudyRenderer.supports(scene) {
            do {
                let image = try renderer.render(scene: scene, width: width)
                guard !isCancelled() else { throw StudyError.cancelled }
                return StudyRenderedFrame(image: image, backend: .metal)
            } catch let error as StudyError {
                // Validation/cancellation is a scene error, not a backend failure.
                if error != .invalidComputeOutput { throw error }
                guard !isCancelled() else { throw StudyError.cancelled }
                state = .cpu
            } catch {
                guard !isCancelled() else { throw StudyError.cancelled }
                state = .cpu
            }
        }
        let image = try ReferenceStudyRenderer.render(scene: scene, width: width, isCancelled: isCancelled)
        guard !isCancelled() else { throw StudyError.cancelled }
        return StudyRenderedFrame(image: image, backend: .cpu)
    }
}
