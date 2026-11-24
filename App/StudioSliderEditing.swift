/// Keeps a slider's value writes inside the scene-history transaction. This
/// adapter has no UI dependency so callback ordering can be tested directly.
struct StudioSliderEditing {
    let read: () -> Double
    let write: (Double) -> Void
    let onEditingChanged: (Bool) -> Void

    func setValue(_ value: Double) {
        guard value.isFinite, value != read() else { return }
        // Slider may write its first value before onEditingChanged(true).
        // Repeated begins for this captured owner retain the original scene.
        onEditingChanged(true)
        write(value)
    }

    /// Accessibility adjustments are complete commands, not drag callbacks.
    /// Keep an imported value in range even if this closure's usual bounds
    /// predate it; clamping must never reverse the requested direction.
    func adjust(by delta: Double, in bounds: ClosedRange<Double>) {
        let current = read()
        guard current.isFinite, delta.isFinite, delta != 0 else { return }
        let lower = min(bounds.lowerBound, current)
        let upper = max(bounds.upperBound, current)
        let next = min(upper, max(lower, current + delta))
        guard next.isFinite, next != current else { return }
        setValue(next)
        onEditingChanged(false)
    }
}
