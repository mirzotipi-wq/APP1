import Foundation

/// The destination for a session-only Studio feature presentation.
public enum StudioFeatureDestination: Equatable, Sendable {
    case reference
    case arrangement
    case room
    case ar
    case targetLux(lightID: UUID)
}

/// A route and its owned receipt, kept in the live parent session.
///
/// Capture `context` for feature work, but check admission against the parent's
/// current presentation value. Copies retain their own state; dismissing or
/// replacing the live value does not invalidate a captured copy automatically.
/// The context's generation is the logical workspace identity, which survives
/// first save, rather than the storage operation generation.
///
/// Dismissal retires this receipt while retaining its immutable scene snapshot.
/// Clear the parent's optional presentation on matching teardown or reset,
/// checking its ID so an older teardown cannot clear a newer presentation.
public struct StudioFeaturePresentation: Identifiable, Equatable, Sendable {
    public let destination: StudioFeatureDestination
    public private(set) var session: StudioFeatureSession

    public var context: StudioFeatureContext { session.context }
    public var id: UUID { context.id }
    public var isPresented: Bool { session.isPresented }
    public var acceptedRevision: UUID { session.acceptedRevision }

    public init(destination: StudioFeatureDestination, context: StudioFeatureContext) {
        self.destination = destination
        session = StudioFeatureSession(context: context)
    }

    public func accepts(_ context: StudioFeatureContext, generation: UUID,
                        revision: UUID, isBusy: Bool) -> Bool {
        session.accepts(context, generation: generation, revision: revision, isBusy: isBusy)
    }

    /// Call synchronously after admitting and applying this feature's validated
    /// result, including an accepted no-op. Dismissed receipts remain unchanged.
    public mutating func didApply(revision: UUID) {
        session.didApply(revision: revision)
    }

    public mutating func dismiss() {
        session.dismiss()
    }
}
