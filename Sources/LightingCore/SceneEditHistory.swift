import Foundation

/// Bounded, session-only history for an editor whose scene lives outside this
/// value. Call `record(previous:)` immediately before a discrete change, or
/// bracket continuous changes with a stable control owner. Unqualified
/// `end(scene:)` explicitly closes the current edit for lifecycle boundaries.
/// Scene validation remains the editor's responsibility.
public struct SceneEditHistory: Equatable, Sendable {
    public static let maximumEntries = 60
    private let limit: Int
    private var past: [LightingScene] = []
    private var future: [LightingScene] = []
    private var transactionStart: LightingScene?
    private var transactionOwner: String?

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

    /// Repeated callbacks from the same control preserve its original scene.
    /// Starting a different control commits the previous edit at the supplied
    /// current scene before starting the new one. Nil retains the legacy owner.
    public mutating func begin(scene: LightingScene, owner: String? = nil) {
        if transactionStart != nil {
            guard transactionOwner != owner else { return }
            end(scene: scene)
        }
        transactionStart = scene
        transactionOwner = owner
    }

    /// A delayed end from another control cannot close a newer edit. Owners
    /// identify controls, not event generations: overlapping gestures from the
    /// same control still require ordered begin/end callbacks from the caller.
    public mutating func end(scene: LightingScene, owner: String) {
        guard transactionStart != nil, transactionOwner == owner else { return }
        end(scene: scene)
    }

    /// A gesture that returns to its initial value does not create history or
    /// discard redo. This unqualified form deliberately closes any owner for
    /// save, selection, lifecycle and history commands; slider callbacks should
    /// use the owner-qualified form.
    public mutating func end(scene: LightingScene) {
        guard let start = transactionStart else { return }
        transactionStart = nil
        transactionOwner = nil
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
        transactionOwner = nil
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
        transactionOwner = nil
    }

    private mutating func pushPast(_ scene: LightingScene) {
        if past.last != scene { past.append(scene) }
        if past.count > limit { past.removeFirst(past.count - limit) }
    }
}
