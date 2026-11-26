import Foundation

/// Minimal, session-only contract for an editor opened against a scene snapshot.
/// Never encode this token into projects or derive it from scene/light UUIDs.
public struct StudioFeatureContext: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let generation: UUID
    public let revision: UUID
    public let scene: LightingScene

    public init(generation: UUID, revision: UUID, scene: LightingScene) {
        id = UUID()
        self.generation = generation
        self.revision = revision
        self.scene = scene
    }

    public var owner: String { id.uuidString }
}

/// An owned feature may emit several changes (room measurement and AR). Each
/// accepted change advances its receipt to the current revision. An unrelated
/// edit, a new project, dismissal or a newer presentation invalidates it.
public struct StudioFeatureSession: Equatable, Sendable {
    public let context: StudioFeatureContext
    public private(set) var acceptedRevision: UUID
    public private(set) var isPresented = true

    public init(context: StudioFeatureContext) {
        self.context = context
        acceptedRevision = context.revision
    }

    public func accepts(_ captured: StudioFeatureContext, generation: UUID,
                        revision: UUID, isBusy: Bool) -> Bool {
        isPresented && !isBusy && captured.id == context.id &&
        captured.generation == generation && acceptedRevision == revision
    }

    /// Call only after successfully applying this feature's validated result.
    /// A dismissed session cannot advance its receipt.
    public mutating func didApply(revision: UUID) {
        guard isPresented else { return }
        acceptedRevision = revision
    }

    public mutating func dismiss() { isPresented = false }
}
