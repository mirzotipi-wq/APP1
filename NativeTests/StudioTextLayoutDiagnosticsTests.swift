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
            let measured = try checkedRecordedText(in: observed)
            XCTAssertTrue(fitsBodyText(measured, category: nativeCategory, scale: observed.scale))
            for width in [measured.width.nextDown, measured.width.nextUp] {
                var adjacent = measured
                adjacent.size.width = width
                XCTAssertTrue(fitsBodyText(adjacent, category: nativeCategory, scale: observed.scale),
                              "Equivalent physical-pixel widths must not introduce a spurious second line")
            }
            var shortLine = measured
            shortLine.size.height -= 1 / observed.scale
            XCTAssertFalse(fitsBodyText(shortLine, category: nativeCategory, scale: observed.scale),
                           "Normalizing width must not permit a line that is one physical pixel too short")
            normalFrames.append(measured)
        }
        XCTAssertGreaterThanOrEqual(normalFrames[1].height, normalFrames[0].height * 1.25)

        let undersized = try await observe(category: .large, font: .system(size: 8, weight: .semibold),
                                           installModifiers: true, enabled: true)
        let smallText = try checkedRecordedText(in: undersized)
        let largeControl = undersized.nativeControlFrame
        XCTAssertTrue(fitsBodyText(largeControl, category: .large, scale: undersized.scale),
                      "This fixture demonstrates why using parent bounds would falsely pass")
        XCTAssertFalse(fitsBodyText(smallText, category: .large, scale: undersized.scale),
                       "The actual undersized Text must fail despite the large action")
        #else
        XCTAssertFalse(StudioTextLayoutDiagnostics.isEnabled)
        #endif
    }

    func testDisabledHostedProbePreservesUninstrumentedLayout() async throws {
        let baseline = try await observe(category: .large, font: .body.weight(.semibold),
                                         installModifiers: false, enabled: false)
        let disabled = try await observe(category: .large, font: .body.weight(.semibold),
                                         installModifiers: true, enabled: false)
        XCTAssertTrue(baseline.frames.isEmpty)
        XCTAssertTrue(disabled.frames.isEmpty, "Disabled probes must emit no layout preferences")
        XCTAssertEqual(disabled.scale, baseline.scale)
        for observed in [baseline, disabled] {
            XCTAssertTrue(observed.nativeControlFrame.contains(observed.nativeTextFrame))
            XCTAssertEqual(observed.nativeControlFrame.size, CGSize(width: 300, height: 100))
            XCTAssertLessThan(observed.nativeTextFrame.height, observed.nativeControlFrame.height)
            XCTAssertTrue(fitsBodyText(observed.nativeTextFrame, category: .large, scale: observed.scale))
        }
        XCTAssertEqual(pixels(disabled.nativeTextFrame, scale: disabled.scale),
                       pixels(baseline.nativeTextFrame, scale: baseline.scale))
        XCTAssertEqual(pixels(disabled.nativeControlFrame, scale: disabled.scale),
                       pixels(baseline.nativeControlFrame, scale: baseline.scale))
        // The native public AX traversal returned no SwiftUI leaves in the
        // original CI failure. Normal labels/values/grouping are verified from
        // external snapshots in ProjectLibraryUITests' existing workflow.
    }

    private struct Observation {
        let frames: [String: CGRect]
        let nativeTextFrame: CGRect
        let nativeControlFrame: CGRect
        let scale: CGFloat
    }

    private func checkedRecordedText(in observed: Observation,
                                     file: StaticString = #filePath, line: UInt = #line) throws -> CGRect {
        let measured = try XCTUnwrap(observed.frames[probe], file: file, line: line)
        XCTAssertEqual(Set(observed.frames.keys), Set([probe]), file: file, line: line)
        XCTAssertTrue(observed.nativeControlFrame.contains(measured), file: file, line: line)
        XCTAssertTrue(observed.nativeControlFrame.contains(observed.nativeTextFrame), file: file, line: line)
        // Read the attached UIKit views after layout has settled. Keep exact
        // physical-pixel equality; no coordinate or size allowance is added.
        XCTAssertEqual(pixels(measured, scale: observed.scale),
                       pixels(observed.nativeTextFrame, scale: observed.scale), file: file, line: line)
        XCTAssertGreaterThanOrEqual(observed.nativeControlFrame.height, 44, file: file, line: line)
        XCTAssertLessThan(measured.height, observed.nativeControlFrame.height,
                          "A padded action must not masquerade as its Text", file: file, line: line)
        let encoded = StudioTextLayoutDiagnostics.value(probe: probe, frame: measured)
        XCTAssertEqual(StudioTextLayoutDiagnostics.frame(from: encoded, probe: probe), measured,
                       "The actual recorded frame must survive an exact transport round trip",
                       file: file, line: line)
        return measured
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
        var nativeTextView: UIView?
        var nativeControlView: UIView?
        let fixture = Fixture(probe: probe, font: font, installModifiers: installModifiers,
                              enabled: enabled, onFrames: { frames = $0 },
                              onTextView: { nativeTextView = $0 },
                              onControlView: { nativeControlView = $0 })
        let host = UIHostingController(rootView: fixture.environment(\.sizeCategory, category))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        // Retain views, not callback-time frames: a later ancestor layout can
        // move an observer without invoking its own layoutSubviews again.
        await drainMainQueue()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        await drainMainQueue()
        host.view.layoutIfNeeded()
        await drainMainQueue()
        XCTAssertTrue(window.windowScene === scene)
        XCTAssertFalse(window.isHidden)
        let textView = try XCTUnwrap(nativeTextView)
        let controlView = try XCTUnwrap(nativeControlView)
        XCTAssertFalse(textView === controlView)
        let nativeText = liveScreenFrame(of: textView, in: host.view, window: window,
                                         screen: scene.screen, role: "Text")
        let nativeControl = liveScreenFrame(of: controlView, in: host.view, window: window,
                                            screen: scene.screen, role: "control")
        print("Hosted Text probe LIVE: enabled=\(enabled), category=\(category), " +
              "frames=\(frames), textBounds=\(textView.bounds), nativeText=\(nativeText), " +
              "controlBounds=\(controlView.bounds), nativeControl=\(nativeControl), " +
              "textAttached=\(textView.window === window), controlAttached=\(controlView.window === window)")
        return Observation(frames: frames, nativeTextFrame: nativeText,
                           nativeControlFrame: nativeControl, scale: scene.screen.scale)
    }

    private func liveScreenFrame(of view: UIView, in host: UIView, window: UIWindow,
                                 screen: UIScreen, role: String,
                                 file: StaticString = #filePath, line: UInt = #line) -> CGRect {
        XCTAssertTrue(view.window === window, "Sample the expected attached window", file: file, line: line)
        XCTAssertTrue(view.isDescendant(of: host), "Sample the actual hosted fixture", file: file, line: line)
        XCTAssertTrue(window.windowScene?.screen === screen, file: file, line: line)
        XCTAssertTrue(StudioTextLayoutDiagnostics.valid(view.bounds), file: file, line: line)
        // The actual attached-view run still returned local bounds through
        // UIAccessibility conversion. Convert through the real view/window
        // hierarchy and then the scene's screen coordinate space instead.
        let windowFrame = view.convert(view.bounds, to: window)
        let frame = window.convert(windowFrame, to: screen.coordinateSpace)
        print("Native direct \(role) conversion: bounds=\(view.bounds), viewFrame=\(view.frame), " +
              "center=\(view.center), transform=\(view.transform), layerTransform=\(view.layer.transform), " +
              "viewScale=\(view.contentScaleFactor), traitScale=\(view.traitCollection.displayScale), " +
              "hostBounds=\(host.bounds), hostFrame=\(host.frame), hostTransform=\(host.transform), " +
              "windowBounds=\(window.bounds), windowFrame=\(window.frame), windowTransform=\(window.transform), " +
              "screenBounds=\(screen.coordinateSpace.bounds), screenScale=\(screen.scale), " +
              "convertedWindowFrame=\(windowFrame), convertedScreenFrame=\(frame)")
        XCTAssertTrue(StudioTextLayoutDiagnostics.valid(windowFrame), file: file, line: line)
        XCTAssertTrue(StudioTextLayoutDiagnostics.valid(frame), file: file, line: line)
        return frame
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
        // The independent views already agree in physical pixels. A global
        // CGRect subtraction can put a width one ULP below the same pixel
        // boundary and make NSString wrap an otherwise identical line.
        let measurementWidth = max(1, (frame.width * scale).rounded() / scale)
        let required = ("Done" as NSString).boundingRect(
            with: CGSize(width: measurementWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        print("Hosted body fit: rawFrame=\(frame), category=\(category.rawValue), scale=\(scale), " +
              "measurementWidth=\(measurementWidth), requiredHeight=\(required.height), " +
              "requiredPixels=\(ceil(required.height * scale)), observedPixels=\((frame.height * scale).rounded())")
        return (frame.height * scale).rounded() >= ceil(required.height * scale)
    }

    private struct Fixture: View {
        let probe: String
        let font: Font
        let installModifiers: Bool
        let enabled: Bool
        let onFrames: ([String: CGRect]) -> Void
        let onTextView: (UIView) -> Void
        let onControlView: (UIView) -> Void

        private var text: some View {
            Text("Done").font(font)
                .fixedSize(horizontal: false, vertical: true)
                .background(NativeViewObserver(onView: onTextView)
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
                // Use a common pixel-aligned origin for the two independent
                // observers. Centering an odd-pixel Text inside an even-pixel
                // action produces a half-pixel SwiftUI layout origin, whereas
                // UIKit snaps a represented view's placement to a pixel.
                // The title keeps its actual intrinsic fractional size.
                title.frame(width: 300, height: 100, alignment: .topLeading)
                    .background(NativeViewObserver(onView: onControlView)
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

    private struct NativeViewObserver: UIViewRepresentable {
        let onView: (UIView) -> Void

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            view.contentScaleFactor = context.environment.displayScale
            view.isAccessibilityElement = false
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            onView(view)
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            uiView.contentScaleFactor = context.environment.displayScale
            onView(uiView)
        }

        func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView,
                          context: Context) -> CGSize? {
            // This empty view observes its background proposal; it has no
            // content whose default UIKit fitting size should replace it.
            // The default bridge rounded a 41⅔ × 20⅓ pt Text to 42 × 20 pt
            // in the actual 3× run, falsely failing both font-fit and exact
            // geometry checks. Preserve the proposed size without assigning
            // UIKit's frame/bounds, which SwiftUI owns.
            guard let width = proposal.width, let height = proposal.height,
                  width.isFinite, height.isFinite, width >= 0, height >= 0 else {
                return nil
            }
            return CGSize(width: width, height: height)
        }
    }
}
