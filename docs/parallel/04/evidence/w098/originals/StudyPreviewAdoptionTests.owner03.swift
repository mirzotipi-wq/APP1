import SwiftUI
import UIKit
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

    private struct Element {
        let identifier: String
        let label: String
    }

    private enum ObservationError: Error {
        case hierarchyLimit
        case timedOut
    }

    /// Read real hosted UIKit/SwiftUI accessibility nodes, including virtual
    /// elements. Missing positive controls fail instead of proving absence.
    private func elements(in root: UIView) throws -> [Element] {
        var pending: [(NSObject, Int)] = [(root, 0)]
        var seen: [ObjectIdentifier: NSObject] = [:]
        var result: [Element] = []
        while let (node, depth) = pending.popLast() {
            let identity = ObjectIdentifier(node)
            guard seen[identity] == nil else { continue }
            seen[identity] = node
            guard seen.count <= 2_048, depth <= 64 else { throw ObservationError.hierarchyLimit }
            if node.accessibilityElementsHidden { continue }
            if let view = node as? UIView {
                if view.isHidden || view.alpha <= 0.01 { continue }
                pending.append(contentsOf: view.subviews.map { ($0, depth + 1) })
            }
            if let identifier = (node as? UIAccessibilityIdentification)?.accessibilityIdentifier {
                result.append(.init(identifier: identifier, label: node.accessibilityLabel ?? ""))
            }
            if let children = node.accessibilityElements {
                guard children.count <= 2_048 else { throw ObservationError.hierarchyLimit }
                pending.append(contentsOf: children.compactMap { ($0 as? NSObject).map { ($0, depth + 1) } })
            }
            let count = node.accessibilityElementCount()
            if count != NSNotFound && count > 0 {
                guard count <= 2_048 else { throw ObservationError.hierarchyLimit }
                for index in 0..<count {
                    if let child = node.accessibilityElement(at: index) as? NSObject {
                        pending.append((child, depth + 1))
                    }
                }
            }
        }
        return result
    }

    private func waitForElements(in view: UIView, description: String,
                                 matching predicate: ([Element]) -> Bool) async throws -> [Element] {
        let deadline = Date().addingTimeInterval(5)
        var observed: [Element] = []
        repeat {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            observed = try elements(in: view)
            if predicate(observed) { return observed }
            // Yield for layout/accessibility updates; ordering comes from the
            // controlled renderer's explicit request/completion handshakes.
            try await Task.sleep(nanoseconds: 20_000_000)
        } while Date() < deadline
        XCTFail("Timed out: \(description); identifiers=\(observed.map(\.identifier))")
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
        _ = try await waitForElements(in: host.view, description: "Initial A is current Metal") { elements in
            elements.contains { $0.identifier == "studyPreview" }
                && elements.contains { $0.identifier == "studyBackend" && $0.label == "Metal compute" }
                && elements.contains { $0.identifier == "studyWarning" }
        }
        XCTAssertEqual(renderer.aCalls, 1)

        model.scene = sceneB
        await fulfillment(of: [renderer.downgradeConfirmed], timeout: 5)
        XCTAssertTrue(renderer.downgraded)
        XCTAssertEqual(renderer.bCalls, 1)
        model.scene = sceneA
        await fulfillment(of: [renderer.secondARequested], timeout: 5)
        renderer.finishB()

        let held = try await waitForElements(in: host.view, description: "Retained A awaits authoritative adoption") { elements in
            elements.contains { $0.identifier == "studyPreviousPreview"
                && $0.label.contains("Previous render: 1 unsupported pixels (magenta)") }
                && elements.contains { $0.identifier == "studyUpdating" }
        }
        XCTAssertFalse(held.contains { $0.identifier == "studyPreview" })
        XCTAssertFalse(held.contains { $0.identifier == "studyBackend" })
        XCTAssertFalse(held.contains { $0.identifier == "studyWarning" })
        XCTAssertEqual(renderer.aCalls, 2)

        renderer.finishSecondA()
        let adopted = try await waitForElements(in: host.view, description: "Second A adopts CPU") { elements in
            elements.contains { $0.identifier == "studyPreview" }
                && elements.contains { $0.identifier == "studyBackend" && $0.label == "CPU reference" }
                && !elements.contains { $0.identifier == "studyPreviousPreview" || $0.identifier == "studyUpdating" }
        }
        XCTAssertFalse(adopted.contains { $0.identifier == "studyWarning" })
        XCTAssertEqual(renderer.aCalls, 2)
        XCTAssertEqual(renderer.bCalls, 1)
    }
}
