import SwiftUI

/// Captures history before a slider-origin value write, including platforms
/// that deliver that write before the editing-began callback. Exact-value
/// fields keep their original binding and remain discrete history commands.
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
        let editing = StudioSliderEditing(read: { value.wrappedValue },
                                          write: { value.wrappedValue = $0 },
                                          onEditingChanged: onEditingChanged)
        Slider(value: Binding(get: editing.read, set: editing.setValue),
               in: bounds, step: step, onEditingChanged: onEditingChanged)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: editing.adjust(by: step, in: bounds)
                case .decrement: editing.adjust(by: -step, in: bounds)
                @unknown default: break
                }
            }
    }
}
