/// Maps the native control's normalized Float display to a stepped Double.
/// Display conversion is one-way: configuring a control must never write its
/// rounded Float value back into the scene.
struct StudioSliderMapping: Equatable {
    let bounds: ClosedRange<Double>
    let step: Double

    init?(bounds: ClosedRange<Double>, step: Double) {
        guard bounds.lowerBound.isFinite, bounds.upperBound.isFinite,
              bounds.upperBound > bounds.lowerBound,
              (bounds.upperBound - bounds.lowerBound).isFinite,
              step.isFinite, step > 0 else { return nil }
        self.bounds = bounds
        self.step = step
    }

    func normalized(_ value: Double) -> Float? {
        guard value.isFinite else { return nil }
        let clamped = min(bounds.upperBound, max(bounds.lowerBound, value))
        return Float((clamped - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
    }

    func modelValue(_ normalized: Float) -> Double? {
        guard normalized.isFinite else { return nil }
        let position = min(1, max(0, Double(normalized)))
        if position == 0 { return bounds.lowerBound }
        if position == 1 { return bounds.upperBound }
        let distance = position * (bounds.upperBound - bounds.lowerBound)
        let increment = (distance / step).rounded()
        let value = bounds.lowerBound + increment * step
        guard value.isFinite else { return nil }
        return min(bounds.upperBound, max(bounds.lowerBound, value))
    }
}

/// One native touch sequence owns one frozen adapter and mapping. UIKit begins
/// this session before dispatching value changes and finishes it after the
/// final value has been read. A value event cannot create or reopen a session.
/// The control owns this object on the main actor; it has no UI dependency so
/// the transaction and exact-value invariants can be exercised independently.
final class StudioSliderTracking {
    struct Token: Equatable { fileprivate let sequence: UInt64 }

    private struct Session {
        let token: Token
        let editing: StudioSliderEditing
        let mapping: StudioSliderMapping
        let initialValue: Double
        let initialDisplay: Float
        var lastDisplay: Float
    }

    private var sequence: UInt64 = 0
    private var session: Session?
    var isTracking: Bool { session != nil }
    var currentToken: Token? { session?.token }

    @discardableResult
    func begin(editing: StudioSliderEditing, mapping: StudioSliderMapping,
               displayedValue: Float) -> Token? {
        if let previous = session { finish(previous.token) }
        let initial = editing.read()
        guard initial.isFinite, displayedValue.isFinite else { return nil }
        sequence &+= 1
        let token = Token(sequence: sequence)
        session = Session(token: token, editing: editing, mapping: mapping,
                          initialValue: initial, initialDisplay: displayedValue,
                          lastDisplay: displayedValue)
        editing.onEditingChanged(true)
        return token
    }

    func change(_ displayedValue: Float, for token: Token) {
        guard var current = session, current.token == token,
              displayedValue.isFinite, displayedValue != current.lastDisplay else { return }
        // Returning to the exact displayed starting position also restores an
        // imported value that is not on the slider's grid. No Float round trip.
        let next = displayedValue == current.initialDisplay
            ? current.initialValue : current.mapping.modelValue(displayedValue)
        guard let next, next.isFinite else { return }
        current.lastDisplay = displayedValue
        session = current
        // This explicit session has already begun. Do not manufacture another
        // begin from a value event or allow reentrant cancellation to reopen it.
        if next != current.editing.read() { current.editing.write(next) }
    }

    /// A completed touch supplies its final value before closing. Cancellation
    /// or removal supplies nil and commits the last value already published,
    /// matching the editor's existing owner-qualified end contract.
    func finish(_ token: Token, finalDisplay: Float? = nil) {
        guard session?.token == token else { return }
        if let finalDisplay { change(finalDisplay, for: token) }
        guard let current = session, current.token == token else { return }
        session = nil // Close first: a delayed or reentrant event cannot reopen it.
        current.editing.onEditingChanged(false)
    }
}
