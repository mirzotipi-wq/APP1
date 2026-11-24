import XCTest
@testable import LightingCore

final class StudyCancellationTests: XCTestCase {
    func testCancellationAtCompletedPixelBoundariesLimitsAdditionalWork() throws {
        // Raise cancellation only at completed-pixel boundaries across two
        // intervals. This trigger permits fewer than eight additional pixels;
        // an external request immediately after a false poll can permit eight.
        for requestAfter in 0..<16 {
            var checkpoint = StudyPixelCancellation()
            var completedPixels = 0
            var observedCancellation = false
            do {
                for _ in 0..<32 {
                    try checkpoint.check { completedPixels >= requestAfter }
                    completedPixels += 1
                }
            } catch StudyError.cancelled {
                observedCancellation = true
            }
            XCTAssertTrue(observedCancellation)
            XCTAssertGreaterThanOrEqual(completedPixels, requestAfter)
            XCTAssertLessThan(completedPixels - requestAfter, 8,
                              "A completed-pixel-boundary request permits fewer than eight additional evaluations")
        }
    }

    func testCancellationImmediatelyAfterFalsePollStopsAfterEightPixelEvaluations() throws {
        var checkpoint = StudyPixelCancellation()
        var cancellationRequested = false
        var completedPixels = 0
        var polls = 0

        try checkpoint.check { polls += 1; return cancellationRequested }
        // Model an external request after the callback returned false, but
        // before the pixel guarded by that checkpoint has been evaluated.
        cancellationRequested = true
        completedPixels += 1

        var observedCancellation = false
        do {
            for _ in 0..<16 {
                try checkpoint.check { polls += 1; return cancellationRequested }
                completedPixels += 1
            }
        } catch StudyError.cancelled {
            observedCancellation = true
        }
        XCTAssertTrue(observedCancellation)
        XCTAssertEqual(completedPixels, 8,
                       "A request immediately after a false poll can allow eight pixel evaluations")
        XCTAssertEqual(polls, 2, "The next callback observes cancellation and stops pixel work")
    }

    func testEveryRendererUsesPixelCheckpointsAndPreservesImageWhenNotCancelled() throws {
        var scene = LightingScene.portrait()
        scene.lights = []
        for width in [24, 27] {
            let renderers: [(String, (() -> Bool) throws -> StudyImage)] = [
                ("sphere interactive", { try ReferenceStudyRenderer.render(scene: scene, width: width, isCancelled: $0) }),
                ("sphere reference", { try ReferenceStudyRenderer.render(scene: scene, width: width, quality: .reference, isCancelled: $0) }),
                ("mannequin", { try PortraitStudyRenderer.render(scene: scene, width: width, isCancelled: $0) })
            ]
            for (name, render) in renderers {
                var checks = 0
                let image = try render { checks += 1; return false }
                XCTAssertGreaterThanOrEqual(checks, (image.width * image.height + 7) / 8, name)
                XCTAssertEqual(image, try render { false }, name)
                XCTAssertEqual(image.unsupportedPixels, 0, name)
                var calls = 0
                XCTAssertThrowsError(try render { calls += 1; return calls == 3 }, name) {
                    XCTAssertEqual($0 as? StudyError, .cancelled)
                }
                XCTAssertEqual(calls, 3, "No further pixel or callback work after cancellation: \(name)")
            }
        }
    }

    func testCancellationAtFinalCheckpointCannotPublishCompletedFrame() throws {
        var scene = LightingScene.portrait()
        scene.lights = []
        let renderers: [(() -> Bool) throws -> StudyImage] = [
            { try ReferenceStudyRenderer.render(scene: scene, width: 24, isCancelled: $0) },
            { try PortraitStudyRenderer.render(scene: scene, width: 24, isCancelled: $0) }
        ]
        for render in renderers {
            var fullChecks = 0
            _ = try render { fullChecks += 1; return false }
            var checks = 0
            XCTAssertThrowsError(try render { checks += 1; return checks == fullChecks }) {
                XCTAssertEqual($0 as? StudyError, .cancelled)
            }
            XCTAssertEqual(checks, fullChecks)
        }
    }
}
