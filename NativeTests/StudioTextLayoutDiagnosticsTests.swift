import SwiftUI
import UIKit
import XCTest
@testable import KeyAndFill

@MainActor
final class StudioTextLayoutDiagnosticsTests: XCTestCase {
    private let probe = "hostedDoneTitle"

    func testExplicitGatingAndExactFrameRoundTrip() throws {
        let flag = StudioTextLayoutDiagnostics.environmentKey
        XCTAssertFalse(StudioTextLayoutDiagnostics.isEnabled(arguments: [], environment: [:]))
        XCTAssertFalse(StudioTextLayoutDiagnostics.isEnabled(arguments: ["-ui-testing"], environment: [:]))
        XCTAssertFalse(StudioTextLayoutDiagnostics.isEnabled(arguments: [], environment: [flag: "1"]))
        XCTAssertFalse(StudioTextLayoutDiagnostics.isEnabled(arguments: ["-ui-testing"],
                                                            environment: [flag: "0"]))
        #if DEBUG
        XCTAssertTrue(StudioTextLayoutDiagnostics.isEnabled(arguments: ["-ui-testing"],
                                                           environment: [flag: "1"]))
        #else
        XCTAssertFalse(StudioTextLayoutDiagnostics.isEnabled(arguments: ["-ui-testing"],
                                                            environment: [flag: "1"]))
        #endif

        let frames = [
            CGRect(x: 32, y: 203.83333333333334, width: 105, height: 20.333333333333343),
            CGRect(x: 19.125, y: 117.875, width: 233.0625, height: 64.9375)
        ]
        for frame in frames {
            let value = StudioTextLayoutDiagnostics.value(probe: probe, frame: frame)
            XCTAssertTrue(value.hasPrefix("DEBUG_UI_TEXT_LAYOUT_V1:"))
            XCTAssertEqual(StudioTextLayoutDiagnostics.frame(from: value, probe: probe), frame)
            XCTAssertNil(StudioTextLayoutDiagnostics.frame(from: value, probe: "anotherTitle"))
        }
        for invalid in [CGRect.zero, .null, .infinite] {
            let value = StudioTextLayoutDiagnostics.value(probe: probe, frame: invalid)
            XCTAssertNil(StudioTextLayoutDiagnostics.frame(from: value, probe: probe))
        }
        XCTAssertNil(StudioTextLayoutDiagnostics.frame(from: "Original action value", probe: probe))
        XCTAssertNil(StudioTextLayoutDiagnostics.frame(from: "DEBUG_UI_TEXT_LAYOUT_V1:pending", probe: probe))
    }

    func testHostedProbeMeasuresIntrinsicTextAndRejectsSmallTextInsideLargeButton() async throws {
        #if DEBUG
        var normalFrames: [CGRect] = []
        for (category, nativeCategory) in [
            (ContentSizeCategory.large, UIContentSizeCategory.large),
            (.accessibilityExtraExtraExtraLarge, .accessibilityExtraExtraExtraLarge)
        ] {
            let observed = try await observe(category: category, font: .body.weight(.semibold),
                                             installModifiers: true, enabled: true)
            let measured = try XCTUnwrap(observed.frames[probe])
            let nativeText = try XCTUnwrap(observed.nativeTextFrame)
            let nativeControl = try XCTUnwrap(observed.nativeControlFrame)
            XCTAssertTrue(nativeControl.contains(measured))
            // Independent UIKit view conversion checks the actual hosted Text's
            // global geometry. Compare physical-pixel coordinates, not an inset.
            XCTAssertEqual(pixels(measured, scale: observed.scale),
                           pixels(nativeText, scale: observed.scale))
            XCTAssertGreaterThanOrEqual(nativeControl.height, 44)
            XCTAssertLessThan(measured.height, nativeControl.height,
                              "A padded action must not masquerade as its Text")
            XCTAssertTrue(fitsBodyText(measured, category: nativeCategory, scale: observed.scale))
            let value = try XCTUnwrap(observed.elements.first?.value)
            XCTAssertEqual(StudioTextLayoutDiagnostics.frame(from: value, probe: probe), measured)
            XCTAssertEqual(observed.elements.count, 1, "The probe must not add accessible children")
            XCTAssertEqual(observed.elements.first?.label, "Done")
            normalFrames.append(measured)
        }
        XCTAssertGreaterThanOrEqual(normalFrames[1].height, normalFrames[0].height * 1.25)

        let undersized = try await observe(category: .large, font: .system(size: 8, weight: .semibold),
                                           installModifiers: true, enabled: true)
        let smallText = try XCTUnwrap(undersized.frames[probe])
        let largeControl = try XCTUnwrap(undersized.nativeControlFrame)
        XCTAssertGreaterThanOrEqual(largeControl.height, 44)
        XCTAssertTrue(fitsBodyText(largeControl, category: .large, scale: undersized.scale),
                      "This fixture demonstrates why using parent bounds would falsely pass")
        XCTAssertFalse(fitsBodyText(smallText, category: .large, scale: undersized.scale),
                       "The actual undersized Text must fail despite the large action")
        #else
        XCTAssertFalse(StudioTextLayoutDiagnostics.isEnabled)
        #endif
    }

    func testDisabledHostedProbePreservesNormalValueAndElementGrouping() async throws {
        let baseline = try await observe(category: .large, font: .body.weight(.semibold),
                                         installModifiers: false, enabled: false)
        let disabled = try await observe(category: .large, font: .body.weight(.semibold),
                                         installModifiers: true, enabled: false)
        XCTAssertTrue(disabled.frames.isEmpty)
        XCTAssertEqual(baseline.elements.count, 1,
                       "Read the real foreground-hosted action; an empty AX tree is not a pass")
        XCTAssertEqual(disabled.elements, baseline.elements)
        XCTAssertEqual(disabled.elements.first?.label, "Done")
        XCTAssertEqual(disabled.elements.first?.value, "Original action value")
        XCTAssertEqual(disabled.elements.first?.isButton, true)
        XCTAssertEqual(pixels(try XCTUnwrap(disabled.nativeTextFrame), scale: disabled.scale),
                       pixels(try XCTUnwrap(baseline.nativeTextFrame), scale: baseline.scale))
    }

    private struct Element: Equatable {
        let label: String?
        let value: String?
        let traits: UInt64
        let isButton: Bool
    }

    private struct Observation {
        let frames: [String: CGRect]
        let nativeTextFrame: CGRect?
        let nativeControlFrame: CGRect?
        let scale: CGFloat
        let elements: [Element]
    }

    private func observe(category: ContentSizeCategory, font: Font,
                         installModifiers: Bool, enabled: Bool) async throws -> Observation {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive },
            "The geometry regression requires a real foreground app-hosted scene")
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        var frames: [String: CGRect] = [:]
        var nativeText: CGRect?
        var nativeControl: CGRect?
        let fixture = Fixture(probe: probe, font: font, installModifiers: installModifiers,
                              enabled: enabled, onFrames: { frames = $0 },
                              onTextFrame: { nativeText = $0 },
                              onControlFrame: { nativeControl = $0 })
        let host = UIHostingController(rootView: fixture.environment(\.sizeCategory, category))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        // As in StudioTextFieldTests, attach to a foreground scene and let the
        // actual view/preferences settle; no unattached accessibilityFrame read.
        await drainMainQueue()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        await drainMainQueue()
        host.view.layoutIfNeeded()
        await drainMainQueue()
        XCTAssertTrue(window.windowScene === scene)
        XCTAssertFalse(window.isHidden)
        let elements = try accessibleLeaves(in: host.view).map {
            Element(label: $0.accessibilityLabel, value: $0.accessibilityValue,
                    traits: $0.accessibilityTraits.rawValue,
                    isButton: $0.accessibilityTraits.contains(.button))
        }
        print("Hosted Text probe: enabled=\(enabled), category=\(category), " +
              "frames=\(frames), nativeText=\(String(describing: nativeText)), " +
              "nativeControl=\(String(describing: nativeControl)), elements=\(elements)")
        return Observation(frames: frames, nativeTextFrame: nativeText,
                           nativeControlFrame: nativeControl, scale: scene.screen.scale,
                           elements: elements)
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    private func pixels(_ frame: CGRect, scale: CGFloat) -> CGRect {
        CGRect(x: (frame.minX * scale).rounded(), y: (frame.minY * scale).rounded(),
               width: (frame.width * scale).rounded(), height: (frame.height * scale).rounded())
    }

    /// Same line-box/physical-pixel predicate as the required UI text checks.
    private func fitsBodyText(_ frame: CGRect, category: UIContentSizeCategory, scale: CGFloat) -> Bool {
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        let body = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
        let font = UIFont.systemFont(ofSize: body.pointSize, weight: .semibold)
        let required = ("Done" as NSString).boundingRect(
            with: CGSize(width: max(1, frame.width), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        return (frame.height * scale).rounded() >= ceil(required.height * scale)
    }

    private enum InspectionError: Error { case hierarchyExceededBound }

    /// Inspect the real public accessibility containers. No test AX elements are
    /// fabricated, and an accessible Button remains one leaf.
    private func accessibleLeaves(in root: NSObject) throws -> [NSObject] {
        var pending: [NSObject] = [root]
        var visited = Set<ObjectIdentifier>()
        var leaves: [NSObject] = []
        while let object = pending.popLast() {
            guard visited.insert(ObjectIdentifier(object)).inserted else { continue }
            guard visited.count <= 512 else { throw InspectionError.hierarchyExceededBound }
            if object.accessibilityElementsHidden { continue }
            if let view = object as? UIView, view.isHidden { continue }
            if object.isAccessibilityElement {
                leaves.append(object)
                continue
            }
            var children = (object.accessibilityElements ?? []).compactMap { $0 as? NSObject }
            if children.isEmpty {
                let count = object.accessibilityElementCount()
                if count != NSNotFound && count > 0 {
                    guard count <= 128 else { throw InspectionError.hierarchyExceededBound }
                    children = (0..<count).compactMap { object.accessibilityElement(at: $0) as? NSObject }
                }
            }
            if let view = object as? UIView { children.append(contentsOf: view.subviews) }
            pending.append(contentsOf: children.reversed())
        }
        return leaves
    }

    private struct Fixture: View {
        let probe: String
        let font: Font
        let installModifiers: Bool
        let enabled: Bool
        let onFrames: ([String: CGRect]) -> Void
        let onTextFrame: (CGRect) -> Void
        let onControlFrame: (CGRect) -> Void

        private var text: some View {
            Text("Done").font(font)
                .fixedSize(horizontal: false, vertical: true)
                .background(NativeFrameObserver(onFrame: onTextFrame)
                    .allowsHitTesting(false).accessibilityHidden(true))
        }

        @ViewBuilder private var title: some View {
            if installModifiers {
                text.studioTextLayoutProbe(probe, enabled: enabled)
            } else {
                text
            }
        }

        private var button: some View {
            Button {} label: {
                title.frame(width: 300, height: 100)
                    .background(NativeFrameObserver(onFrame: onControlFrame)
                        .allowsHitTesting(false).accessibilityHidden(true))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("hostedLayoutAction")
            .accessibilityValue(Text("Original action value"))
        }

        @ViewBuilder private var action: some View {
            if installModifiers {
                button.studioTextLayoutValue(probe, enabled: enabled)
            } else {
                button
            }
        }

        var body: some View {
            action.padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .onPreferenceChange(StudioTextLayoutPreferenceKey.self, perform: onFrames)
        }
    }

    private struct NativeFrameObserver: UIViewRepresentable {
        let onFrame: (CGRect) -> Void

        func makeUIView(context: Context) -> FrameView {
            let view = FrameView()
            view.onFrame = onFrame
            view.isAccessibilityElement = false
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            return view
        }

        func updateUIView(_ uiView: FrameView, context: Context) {
            uiView.onFrame = onFrame
            uiView.report()
        }

        final class FrameView: UIView {
            var onFrame: ((CGRect) -> Void)?
            override func layoutSubviews() { super.layoutSubviews(); report() }
            override func didMoveToWindow() { super.didMoveToWindow(); report() }
            func report() {
                guard window != nil, !bounds.isEmpty else { return }
                onFrame?(UIAccessibility.convertToScreenCoordinates(bounds, in: self))
            }
        }
    }
}
