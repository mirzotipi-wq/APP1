import Foundation

/// Bounded, session-only history for an editor whose scene lives outside this
/// value. Call `record(previous:)` immediately before a discrete change, or
/// bracket continuous changes with `begin(scene:)` and `end(scene:)`.
/// Scene validation remains the editor's responsibility.
public struct SceneEditHistory: Equatable, Sendable {
    public static let maximumEntries = 60
    private let limit: Int
    private var past: [LightingScene] = []
    private var future: [LightingScene] = []
    private var transactionStart: LightingScene?

    /// Custom limits are useful for constrained editors; history is always
    /// bounded to between one and sixty entries in each direction.
    public init(limit: Int = maximumEntries) {
        self.limit = min(Self.maximumEntries, max(1, limit))
    }

    /// An active edit can be undone even before its final callback arrives.
    /// If that edit made no change, Undo falls through to the previous command.
    public var canUndo: Bool { !past.isEmpty || transactionStart != nil }
    public var canRedo: Bool { !future.isEmpty }
    public var isEditing: Bool { transactionStart != nil }

    /// Record only actual discrete changes. If a gesture is still open,
    /// `previous` is its current result: commit that gesture before recording
    /// the new command so both operations remain independently reversible.
    public mutating func record(previous: LightingScene) {
        end(scene: previous)
        pushPast(previous)
        future.removeAll()
    }

    /// Repeated begin callbacks preserve the first scene of the gesture.
    public mutating func begin(scene: LightingScene) {
        if transactionStart == nil { transactionStart = scene }
    }

    /// A gesture that returns to its initial value does not create history or
    /// discard redo. A late callback after a history command is a no-op.
    public mutating func end(scene: LightingScene) {
        guard let start = transactionStart else { return }
        transactionStart = nil
        guard start != scene else { return }
        pushPast(start)
        future.removeAll()
    }

    /// Explicit rollback: the caller must restore the returned scene. Existing
    /// history and redo are retained because the gesture was not committed.
    @discardableResult
    public mutating func cancel() -> LightingScene? {
        let start = transactionStart
        transactionStart = nil
        return start
    }

    public mutating func undo(current: LightingScene) -> LightingScene? {
        end(scene: current)
        guard let previous = past.popLast() else { return nil }
        if future.last != current { future.append(current) }
        if future.count > limit { future.removeFirst(future.count - limit) }
        return previous
    }

    public mutating func redo(current: LightingScene) -> LightingScene? {
        end(scene: current)
        guard let next = future.popLast() else { return nil }
        pushPast(current)
        return next
    }

    /// Project switching and successful recovery must not retain another
    /// project's snapshots or an unfinished gesture.
    public mutating func reset() {
        past.removeAll()
        future.removeAll()
        transactionStart = nil
    }

    private mutating func pushPast(_ scene: LightingScene) {
        if past.last != scene { past.append(scene) }
        if past.count > limit { past.removeFirst(past.count - limit) }
    }
}
