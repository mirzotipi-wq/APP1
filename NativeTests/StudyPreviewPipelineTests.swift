import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudyPreviewHarness
#endif

final class StudyPreviewPipelineTests: XCTestCase {
    @MainActor private final class ControlledRender {
        private var continuation: CheckedContinuation<StudyPreviewOutput, Error>?
        private var waiters: [CheckedContinuation<Void, Never>] = []
        private var requested = false

        func render() async throws -> StudyPreviewOutput {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                requested = true
                waiters.forEach { $0.resume() }
                waiters.removeAll()
            }
        }

        func waitUntilRequested() async {
            if requested { return }
            await withCheckedContinuation { waiters.append($0) }
        }

        func finish(_ result: Result<StudyPreviewOutput, Error>) {
            precondition(continuation != nil)
            continuation?.resume(with: result)
            continuation = nil
        }
    }

    private func output(_ value: UInt8) throws -> StudyPreviewOutput {
        var bytes = [UInt8](repeating: value, count: 24 * 16 * 4)
        for i in stride(from: 3, to: bytes.count, by: 4) { bytes[i] = 255 }
        return .init(image: try StudyImage.fromComputeRGBA(width: 24, height: 16, data: Data(bytes)),
                     backendLabel: "Controlled CPU")
    }

    @MainActor func testLateSuccessCannotReplaceNewerCompletion() async throws {
        let pipeline = StudyPreviewPipeline<UInt8>()
        let old = ControlledRender(), new = ControlledRender()
        var published: [UInt8] = []
        let firstTicket = pipeline.begin()
        let first = Task { await pipeline.load(ticket: firstTicket, render: old.render,
                                               convert: { $0.rgba[0] }, publish: { published.append($0.image!) }) }
        await old.waitUntilRequested()
        let secondTicket = pipeline.begin()
        let second = Task { await pipeline.load(ticket: secondTicket, render: new.render,
                                                convert: { $0.rgba[0] }, publish: { published.append($0.image!) }) }
        await new.waitUntilRequested()
        new.finish(.success(try output(2)))
        await second.value
        old.finish(.success(try output(1)))
        await first.value
        XCTAssertEqual(published, [2])
    }

    @MainActor func testLateFailureCannotReplaceNewerImage() async throws {
        let pipeline = StudyPreviewPipeline<UInt8>(), old = ControlledRender()
        var completions: [StudyPreviewPipeline<UInt8>.Completion] = []
        let firstTicket = pipeline.begin()
        let first = Task { await pipeline.load(ticket: firstTicket, render: old.render,
                                               convert: { $0.rgba[0] }, publish: { completions.append($0) }) }
        await old.waitUntilRequested()
        await pipeline.load(ticket: pipeline.begin(), render: { try self.output(3) },
                            convert: { $0.rgba[0] }, publish: { completions.append($0) })
        old.finish(.failure(StudyError.invalidCamera))
        await first.value
        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(completions.first?.image, 3)
        XCTAssertNil(completions.first?.message)
    }

    @MainActor func testReturningToCompletedRequestInvalidatesIntermediateWork() async throws {
        let pipeline = StudyPreviewPipeline<UInt8>(), intermediate = ControlledRender()
        _ = pipeline.begin() // Previously completed A.
        let ticketB = pipeline.begin()
        var published = 0
        let task = Task { await pipeline.load(ticket: ticketB, render: intermediate.render,
                                              convert: { $0.rgba[0] }, publish: { _ in published += 1 }) }
        await intermediate.waitUntilRequested()
        _ = pipeline.begin() // Reuse A without another render.
        intermediate.finish(.success(try output(4)))
        await task.value
        XCTAssertEqual(published, 0)
    }

    @MainActor func testCancellationDiscardsNoncooperativeRenderCompletion() async throws {
        let pipeline = StudyPreviewPipeline<UInt8>(), renderer = ControlledRender()
        let ticket = pipeline.begin()
        var conversions = 0, publications = 0
        let task = Task { await pipeline.load(ticket: ticket, render: renderer.render,
            convert: { conversions += 1; return $0.rgba[0] }, publish: { _ in publications += 1 }) }
        await renderer.waitUntilRequested()
        task.cancel()
        renderer.finish(.success(try output(5)))
        await task.value
        XCTAssertEqual(conversions, 0)
        XCTAssertEqual(publications, 0)
    }

    @MainActor func testDisappearanceOrInactivityInvalidatesLateFailure() async {
        let pipeline = StudyPreviewPipeline<UInt8>(), renderer = ControlledRender()
        let ticket = pipeline.begin()
        var publications = 0
        let task = Task { await pipeline.load(ticket: ticket, render: renderer.render,
            convert: { $0.rgba[0] }, publish: { _ in publications += 1 }) }
        await renderer.waitUntilRequested()
        pipeline.invalidate()
        renderer.finish(.failure(StudyError.invalidEmitter))
        await task.value
        XCTAssertEqual(publications, 0)
    }

    @MainActor func testCurrentFailureCanRetryWithFreshAttempt() async throws {
        let pipeline = StudyPreviewPipeline<UInt8>()
        var completions: [StudyPreviewPipeline<UInt8>.Completion] = []
        let first = pipeline.begin()
        await pipeline.load(ticket: first, render: { throw StudyError.invalidCamera },
                            convert: { $0.rgba[0] }, publish: { completions.append($0) })
        let retry = pipeline.begin()
        XCTAssertNotEqual(first, retry)
        await pipeline.load(ticket: retry, render: { try self.output(6) },
                            convert: { $0.rgba[0] }, publish: { completions.append($0) })
        XCTAssertEqual(completions.count, 2)
        XCTAssertNil(completions[0].image)
        XCTAssertEqual(completions[0].message, "Move the camera above the panel and away from the subject.")
        XCTAssertEqual(completions[1].image, 6)
        XCTAssertNil(completions[1].message)
        XCTAssertEqual(completions[1].backendLabel, "Controlled CPU")
    }

    @MainActor func testConversionFailureHasNoSuccessfulImageOrBackend() async throws {
        let pipeline = StudyPreviewPipeline<UInt8>()
        var completion: StudyPreviewPipeline<UInt8>.Completion?
        await pipeline.load(ticket: pipeline.begin(), render: { try self.output(7) },
                            convert: { _ in nil }, publish: { completion = $0 })
        XCTAssertNotNil(completion)
        XCTAssertNil(completion?.image)
        XCTAssertNil(completion?.backendLabel)
        XCTAssertEqual(completion?.unsupportedPixels, 0)
        XCTAssertEqual(completion?.message, "The rendered image could not be displayed.")
    }

    @MainActor func testInvalidationDuringConversionCannotPublish() async throws {
        let pipeline = StudyPreviewPipeline<UInt8>()
        var publications = 0
        await pipeline.load(ticket: pipeline.begin(), render: { try self.output(8) },
                            convert: { image in pipeline.invalidate(); return image.rgba[0] },
                            publish: { _ in publications += 1 })
        XCTAssertEqual(publications, 0)
    }

    @MainActor func testCancelledErrorsAndPrecancelledWorkStaySilent() async {
        let pipeline = StudyPreviewPipeline<UInt8>()
        var publications = 0, renders = 0
        for error in [CancellationError() as Error, StudyError.cancelled] {
            await pipeline.load(ticket: pipeline.begin(), render: { throw error },
                                convert: { $0.rgba[0] }, publish: { _ in publications += 1 })
        }
        let ticket = pipeline.begin()
        let task = Task { await pipeline.load(ticket: ticket, render: {
            renders += 1
            throw StudyError.invalidCamera
        }, convert: { $0.rgba[0] }, publish: { _ in publications += 1 }) }
        task.cancel()
        await task.value
        XCTAssertEqual(renders, 0)
        XCTAssertEqual(publications, 0)
    }
}
