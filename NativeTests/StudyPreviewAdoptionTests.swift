import SwiftUI
import UIKit
import CoreGraphics
import XCTest
import LightingCore
@testable import KeyAndFill

@MainActor
final class StudyPreviewAdoptionTests: XCTestCase {
    @MainActor private final class SceneHolder: ObservableObject {
        @Published var scene: LightingScene
        init(scene: LightingScene) { self.scene = scene }
    }

    @MainActor private struct HostedPreview: View {
        @ObservedObject var model: SceneHolder
        let renderer: ControlledRenderer

        var body: some View {
            ReferenceStudyPreview(scene: model.scene, renderStudy: renderer.render)
                .environment(\.scenePhase, .active)
                .frame(width: 360, height: 240)
        }
    }

    @MainActor private final class ControlledRenderer {
        let firstARequested = XCTestExpectation(description: "First A entered renderer")
        let downgradeConfirmed = XCTestExpectation(description: "B confirmed mock downgrade")
        let secondARequested = XCTestExpectation(description: "Second A entered renderer")
        let sceneA: LightingScene
        let sceneB: LightingScene
        let metal: StudyPreviewOutput
        let cpu: StudyPreviewOutput
        private(set) var aCalls = 0
        private(set) var bCalls = 0
        private(set) var downgraded = false
        private var b: CheckedContinuation<StudyPreviewOutput, Error>?
        private var secondA: CheckedContinuation<StudyPreviewOutput, Error>?
        private var closed = false

        init(sceneA: LightingScene, sceneB: LightingScene,
             metal: StudyPreviewOutput, cpu: StudyPreviewOutput) {
            self.sceneA = sceneA; self.sceneB = sceneB
            self.metal = metal; self.cpu = cpu
        }

        func render(scene: LightingScene, subject: StudySubject) async throws -> StudyPreviewOutput {
            guard !closed else { throw CancellationError() }
            XCTAssertEqual(subject, .sphere)
            if scene == sceneA {
                aCalls += 1
                if aCalls == 1 {
                    firstARequested.fulfill()
                    return metal
                }
                if aCalls == 2 {
                    XCTAssertTrue(downgraded)
                    return try await withCheckedThrowingContinuation { continuation in
                        secondA = continuation
                        secondARequested.fulfill()
                    }
                }
            } else if scene == sceneB {
                bCalls += 1
                if bCalls == 1 {
                    // Deliberately noncooperative: policy changes before B's
                    // cancellation is delivered to the view's publication seam.
                    downgraded = true
                    return try await withCheckedThrowingContinuation { continuation in
                        b = continuation
                        downgradeConfirmed.fulfill()
                    }
                }
            }
            XCTFail("Unexpected preview render invocation")
            throw StudyError.cancelled
        }

        func finishB() {
            let continuation = b; b = nil
            XCTAssertNotNil(continuation)
            continuation?.resume(throwing: StudyError.cancelled)
        }

        func finishSecondA() {
            let continuation = secondA; secondA = nil
            XCTAssertNotNil(continuation)
            continuation?.resume(returning: cpu)
        }

        func close() {
            closed = true
            let pendingB = b, pendingA = secondA
            b = nil; secondA = nil
            pendingB?.resume(throwing: CancellationError())
            pendingA?.resume(throwing: CancellationError())
        }
    }

    private enum ObservationError: Error {
        case timedOut
    }

    /// Observe the actual mounted preview through public UIKit drawing. Native
    /// unit hosts need not expose SwiftUI's virtual accessibility hierarchy.
    /// A visible first frame is a positive control before testing reactivation.
    private func centerPixel(in view: UIView) -> [UInt8]? {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        var drewHierarchy = false
        let snapshot = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { context in
            context.cgContext.translateBy(x: -view.bounds.midX, y: -view.bounds.midY)
            drewHierarchy = view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        guard drewHierarchy, let image = snapshot.cgImage else { return nil }
        var rgba = [UInt8](repeating: 0, count: 4)
        let converted = rgba.withUnsafeMutableBytes { bytes -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(data: bytes.baseAddress, width: 1, height: 1,
                      bitsPerComponent: 8, bytesPerRow: 4, space: space,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }
        return converted ? rgba : nil
    }

    private func waitForPixel(in view: UIView, expected: UInt8, description: String) async throws -> [UInt8] {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        var observed: [UInt8]?
        repeat {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            observed = centerPixel(in: view)
            if let observed, observed[3] == 255,
               observed.prefix(3).allSatisfy({ abs(Int($0) - Int(expected)) <= 2 }) {
                print("StudyPreviewAdoption pixel: \(description), RGBA=\(observed)")
                return observed
            }
            // Explicit renderer handshakes establish ordering. This bounded
            // observation wait permits the mounted view to finish display work.
            try await Task.sleep(nanoseconds: 20_000_000)
        } while clock.now < deadline
        XCTFail("Timed out: \(description); last RGBA=\(String(describing: observed))")
        throw ObservationError.timedOut
    }

    private func output(value: UInt8, backend: String, unsupported: Bool) throws -> StudyPreviewOutput {
        var bytes = [UInt8](repeating: value, count: 24 * 16 * 4)
        for index in stride(from: 3, to: bytes.count, by: 4) { bytes[index] = 255 }
        if unsupported { bytes.replaceSubrange(0..<4, with: [255, 0, 255, 0]) }
        return .init(image: try StudyImage.fromComputeRGBA(width: 24, height: 16, data: Data(bytes)),
                     backendLabel: backend)
    }

    func testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade() async throws {
        var sceneA = LightingScene.portrait()
        sceneA.previewSettings = .init(exposureStops: 0)
        var sceneB = sceneA
        sceneB.previewSettings = .init(exposureStops: 1)
        // Both outputs are synthetic fixtures; no GPU or physical result is claimed.
        let renderer = ControlledRenderer(sceneA: sceneA, sceneB: sceneB,
            metal: try output(value: 32, backend: "Metal compute", unsupported: true),
            cpu: try output(value: 160, backend: "CPU reference", unsupported: false))
        let model = SceneHolder(scene: sceneA)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive })
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        // Keep this single host and view identity throughout A → B → A.
        let host = UIHostingController(rootView: HostedPreview(model: model, renderer: renderer))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            renderer.close()
            previousKeyWindow?.makeKeyAndVisible()
        }

        await fulfillment(of: [renderer.firstARequested], timeout: 5)
        _ = try await waitForPixel(in: host.view, expected: 32,
                                   description: "First A is visibly adopted")
        XCTAssertEqual(renderer.aCalls, 1)

        model.scene = sceneB
        await fulfillment(of: [renderer.downgradeConfirmed], timeout: 5)
        XCTAssertTrue(renderer.downgraded)
        XCTAssertEqual(renderer.bCalls, 1)
        model.scene = sceneA
        await fulfillment(of: [renderer.secondARequested], timeout: 5)
        renderer.finishB()

        _ = try await waitForPixel(in: host.view, expected: 32,
                                   description: "Retained A remains visible while second A is held")
        XCTAssertEqual(renderer.aCalls, 2)

        renderer.finishSecondA()
        _ = try await waitForPixel(in: host.view, expected: 160,
                                   description: "Second A adopts the replacement pixels")
        XCTAssertEqual(renderer.aCalls, 2)
        XCTAssertEqual(renderer.bCalls, 1)
    }
}
