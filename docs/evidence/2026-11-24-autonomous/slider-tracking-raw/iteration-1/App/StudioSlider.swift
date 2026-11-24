import SwiftUI
import UIKit

/// Continuous preview with an explicit native touch boundary. Exact-value
/// fields retain their original binding and remain separate history commands.
struct StudioSlider: View {
    let value: Binding<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    let onEditingChanged: (Bool) -> Void

    init(value: Binding<Double>, in bounds: ClosedRange<Double>, step: Double,
         onEditingChanged: @escaping (Bool) -> Void) {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        StudioSliderControl(editing: StudioSliderEditing(read: { value.wrappedValue },
                                                        write: { value.wrappedValue = $0 },
                                                        onEditingChanged: onEditingChanged),
                            bounds: bounds, step: step)
            .frame(minHeight: 44)
    }
}

private struct StudioSliderControl: UIViewRepresentable {
    let editing: StudioSliderEditing
    let bounds: ClosedRange<Double>
    let step: Double
    @Environment(\.isEnabled) private var isEnabled

    func makeUIView(context: Context) -> StudioTrackingSlider {
        StudioTrackingSlider(frame: .zero)
    }

    func updateUIView(_ uiView: StudioTrackingSlider, context: Context) {
        uiView.configure(editing: editing, mapping: StudioSliderMapping(bounds: bounds, step: step),
                         isEnabled: isEnabled)
    }

    static func dismantleUIView(_ uiView: StudioTrackingSlider, coordinator: ()) {
        uiView.invalidate()
    }
}

/// The same instance survives SwiftUI value updates. Touch sessions retain the
/// binding captured at begin, including the caller's project/control generation.
final class StudioTrackingSlider: UISlider {
    private let editTracking = StudioSliderTracking()
    private var token: StudioSliderTracking.Token?
    private var editing: StudioSliderEditing?
    private var mapping: StudioSliderMapping?

    override init(frame: CGRect) {
        super.init(frame: frame)
        minimumValue = 0
        maximumValue = 1
        isContinuous = true
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: max(44, size.height))
    }

    func configure(editing: StudioSliderEditing, mapping: StudioSliderMapping?, isEnabled: Bool) {
        let enabled = isEnabled && mapping != nil && editing.read().isFinite
        if !enabled, editTracking.isTracking { cancelTracking(with: nil) }
        self.editing = editing
        self.mapping = mapping
        self.isEnabled = enabled
        synchronizeDisplay()
    }

    func invalidate() {
        cancelTracking(with: nil)
        editing = nil
        mapping = nil
        isEnabled = false
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isEnabled, let editing, let mapping else { return false }
        token = editTracking.begin(editing: editing, mapping: mapping, displayedValue: value)
        guard isEnabled, let token, token == editTracking.currentToken else {
            finishTracking(finalDisplay: nil, reason: "invalidated begin")
            return false
        }
        trace("begin")
        let accepted = super.beginTracking(touch, with: event)
        if !accepted { finishTracking(finalDisplay: nil, reason: "declined") }
        return accepted
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let continued = super.continueTracking(touch, with: event)
        if !continued { finishTracking(finalDisplay: value, reason: "stopped") }
        return continued
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        // Let UIKit finish its own tracking work while this session still owns
        // value events. Then publish the final value before ending history.
        super.endTracking(touch, with: event)
        finishTracking(finalDisplay: value, reason: "end")
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        finishTracking(finalDisplay: nil, reason: "cancel")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil, editTracking.isTracking { cancelTracking(with: nil) }
    }

    @objc private func valueChanged() {
        guard let token else {
            trace("ignored value outside tracking")
            return
        }
        editTracking.change(value, for: token)
        trace("value")
    }

    private func finishTracking(finalDisplay: Float?, reason: String) {
        guard let token = token ?? editTracking.currentToken else { return }
        self.token = nil
        editTracking.finish(token, finalDisplay: finalDisplay)
        trace(reason)
        synchronizeDisplay()
    }

    private func synchronizeDisplay() {
        // Updating the thumb during a drag would feed a stepped or stale model
        // value back into UIKit's active pointer tracking. Configure only the
        // next session; the current one retains its original range and binding.
        guard !editTracking.isTracking, let editing, let mapping,
              let display = mapping.normalized(editing.read()), display != value else { return }
        setValue(display, animated: false)
    }

    override func accessibilityIncrement() { adjustAccessibly(by: 1) }
    override func accessibilityDecrement() { adjustAccessibly(by: -1) }

    private func adjustAccessibly(by direction: Double) {
        if editTracking.isTracking { cancelTracking(with: nil) }
        // Ending the old edit can synchronously disable, remove or reconfigure
        // this view. Read the current configuration only after that callback.
        guard isEnabled, let editing, let mapping else { return }
        // Exact Double arithmetic and one complete command per VoiceOver
        // action, including imported values outside the usual quick range.
        editing.adjust(by: direction * mapping.step, in: mapping.bounds)
        trace(direction > 0 ? "accessibility increment" : "accessibility decrement")
        synchronizeDisplay()
    }

    #if DEBUG
    private var traceCount = 0
    private func trace(_ event: String) {
        guard traceCount < 64,
              ProcessInfo.processInfo.arguments.contains("-ui-testing"),
              ProcessInfo.processInfo.environment["KEYFILL_UI_TEST_SLIDER_TRACE"] == "1" else { return }
        traceCount += 1
        print("StudioSliderTrace \(traceCount) \(accessibilityIdentifier ?? "unidentified") \(event) display=\(value) model=\(editing?.read() ?? .nan) tracking=\(editTracking.isTracking) enabled=\(isEnabled)")
    }
    #else
    private func trace(_ event: String) {}
    #endif
}
