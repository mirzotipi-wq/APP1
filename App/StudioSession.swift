import Foundation
#if canImport(Darwin)
import Observation
#endif
import LightingCore

/// Per-window editor owner. Views render this state and send commands; the
/// session reconciles storage receipts even when a presenting sheet disappears.
@MainActor
#if canImport(Darwin)
@Observable
#endif
final class StudioSession {
    typealias Executor = @Sendable (ProjectLibraryRequest) async throws -> ProjectLibrary?

    /// The Plan gesture uses cumulative translation, so its origin and scale
    /// must remain fixed until that exact gesture ends.
    struct PlanDrag: Equatable {
        let lightID: UUID
        let generation: UUID
        let scene: LightingScene
        let pointsPerMeter: Double
        let owner: String
    }

    private(set) var editor: StudioEditorState
    private(set) var library: ProjectLibrary?
    private(set) var saved: LightingScene?
    private(set) var libraryOperation = ProjectLibraryOperationState()
    private(set) var loaded = false
    private(set) var saveBlocked = false
    private(set) var saveConflict = false
    private(set) var workspaceResetID = UUID()
    private(set) var planDrag: PlanDrag?
    private(set) var feature: StudioFeaturePresentation?
    var message: String?
    var showRecoveryCapacity = false

    private let store: ProjectStore
    private let execute: Executor
    // Observation is the native SwiftUI adapter. Portable tests execute this
    // same orchestration without depending on a Linux Observation runtime.
    #if canImport(Darwin)
    @ObservationIgnored
    #endif
    private(set) var operationTask: Task<Void, Error>?
    #if canImport(Darwin)
    @ObservationIgnored
    #endif
    private var operationTaskID: UUID?

    init(editor: StudioEditorState = .init(), store: ProjectStore = ProjectStore(),
         execute: Executor? = nil) {
        self.editor = editor
        self.store = store
        self.execute = execute ?? { request in try await store.perform(request) }
    }

    var scene: LightingScene { editor.scene }
    var selection: UUID? { editor.selection }
    var history: SceneEditHistory { editor.history }
    var generation: UUID { libraryOperation.generation }
    var revision: UUID { editor.revision }
    var isBusy: Bool { libraryOperation.isBusy }
    var projectName: String { library?.activeProject?.name ?? "Portrait setup" }

    func allowsMutation(from generation: UUID) -> Bool {
        loaded && !saveBlocked && libraryOperation.allowsSceneMutation(from: generation)
    }

    @discardableResult
    func select(_ id: UUID?, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        let changed = editor.select(id)
        if changed { planDrag = nil }
        return changed
    }

    @discardableResult
    func replace(_ next: LightingScene, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        do {
            let changed = try editor.replace(with: next)
            if changed { planDrag = nil }
            return changed
        }
        catch {
            message = "The proposed setup contains unsupported values. Your current setup has been kept."
            return false
        }
    }

    @discardableResult
    func update(_ next: LightingScene, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        do {
            var candidate = editor
            if let feature { candidate.endEditing(owner: feature.context.owner) }
            guard try candidate.update(with: next) else { return false }
            editor = candidate
            return true
        }
        catch { return false }
    }

    /// Controls send a closed field command rather than replacing an entire
    /// scene. The editor validates its payload before touching history/state.
    @discardableResult
    func apply(_ command: StudioFieldCommand, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        do {
            // An unrelated command cannot silently join an open room/AR group.
            // Stage its boundary too: invalid/no-op commands leave that group intact.
            var candidate = editor
            if let feature { candidate.endEditing(owner: feature.context.owner) }
            guard try candidate.apply(command) else { return false }
            editor = candidate
            return true
        }
        catch { return false }
    }

    /// A document may have one active feature draft. Storage identity can change
    /// on first save without changing this presentation's document identity.
    @discardableResult
    func openFeature(_ destination: StudioFeatureDestination,
                     from generation: UUID) -> StudioFeatureContext? {
        guard allowsMutation(from: generation), feature?.isPresented != true else { return nil }
        if case let .targetLux(lightID) = destination {
            guard scene.lights.contains(where: { $0.id == lightID }) else { return nil }
        }
        finishPlanDrag()
        editor.endEditing()
        let context = StudioFeatureContext(generation: workspaceResetID,
                                           revision: revision, scene: scene)
        feature = StudioFeaturePresentation(destination: destination, context: context)
        return context
    }

    func acceptsFeature(_ context: StudioFeatureContext) -> Bool {
        guard allowsMutation(from: generation), let feature else { return false }
        return feature.accepts(context, generation: workspaceResetID,
                               revision: revision, isBusy: isBusy)
    }

    /// The Bool reports acceptance, including a valid unchanged proposal.
    @discardableResult
    func applyFeatureScene(_ next: LightingScene, from context: StudioFeatureContext) -> Bool {
        guard acceptsFeature(context), let destination = feature?.destination,
              destination == .reference || destination == .arrangement else { return false }
        do {
            let changed = try editor.replace(with: next)
            if changed { planDrag = nil }
            feature?.didApply(revision: revision)
            retireFeature(context)
            return true
        } catch { return false }
    }

    @discardableResult
    func applyFeatureLight(_ adjusted: StudioLight, from context: StudioFeatureContext) -> Bool {
        guard acceptsFeature(context),
              let destination = feature?.destination,
              case let .targetLux(lightID) = destination,
              adjusted.id == lightID,
              let original = context.scene.lights.first(where: { $0.id == lightID }),
              let index = scene.lights.firstIndex(where: { $0.id == lightID }),
              scene.lights[index] == original else { return false }
        // This feature adjusts output only. A malformed adapter cannot replace
        // another light, rename it, or change its geometry through this callback.
        var expected = original
        expected.candela = adjusted.candela
        guard adjusted == expected else { return false }
        var next = scene
        next.lights[index] = adjusted
        do {
            let changed = try editor.replace(with: next)
            if changed { planDrag = nil }
            feature?.didApply(revision: revision)
            retireFeature(context)
            return true
        } catch { return false }
    }

    @discardableResult
    func applyFeatureRoom(_ room: ManualRoom?, from context: StudioFeatureContext) -> Bool {
        guard acceptsFeature(context), let destination = feature?.destination,
              destination == .room || destination == .ar,
              room?.isValid ?? true else { return false }
        guard room != scene.placementRoom else { return true }
        do {
            var candidate = editor
            candidate.beginEditing(owner: context.owner)
            guard try candidate.apply(.room(room)) else { return true }
            editor = candidate
            planDrag = nil
            feature?.didApply(revision: revision)
            return true
        } catch { return false }
    }

    /// Retire callbacks immediately, before an asynchronous sheet animation.
    /// Keep the payload until the matching dismissal finishes.
    func retireFeature(_ context: StudioFeatureContext) {
        guard feature?.id == context.id else { return }
        feature?.dismiss()
        editor.endEditing(owner: context.owner)
    }

    func finishFeature(_ context: StudioFeatureContext) {
        guard feature?.id == context.id else { return }
        retireFeature(context)
        feature = nil
    }

    func editChanged(_ editing: Bool, owner: String, from generation: UUID) {
        guard generation == self.generation else { return }
        if editing {
            guard allowsMutation(from: generation) else { return }
            if let drag = planDrag, drag.owner != owner { finishPlanDrag() }
            editor.beginEditing(owner: owner)
        } else {
            editor.endEditing(owner: owner)
        }
    }

    func endEditing(owner: String? = nil) { editor.endEditing(owner: owner) }

    @discardableResult
    func dragLight(_ id: UUID, translationX: Double, translationZ: Double,
                   scale: Double, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation), selection == id,
              scene.lights.contains(where: { $0.id == id }),
              scale.isFinite, scale > 0,
              translationX.isFinite, translationZ.isFinite else { return false }
        if planDrag == nil {
            let owner = editOwner("plan.\(id.uuidString)")
            editor.beginEditing(owner: owner)
            planDrag = PlanDrag(lightID: id, generation: generation, scene: scene,
                                pointsPerMeter: scale, owner: owner)
        }
        guard let drag = planDrag, drag.lightID == id, drag.generation == generation,
              let source = drag.scene.lights.first(where: { $0.id == id }) else { return false }
        let range = Position.coordinateRange
        var position = source.position
        position.x = min(range.upperBound, max(range.lowerBound,
            source.position.x + translationX / drag.pointsPerMeter))
        position.z = min(range.upperBound, max(range.lowerBound,
            source.position.z + translationZ / drag.pointsPerMeter))
        guard position.isValid else { return false }
        return apply(.lightPosition(id: id, position: position), from: generation)
    }

    func finishPlanDrag(lightID: UUID? = nil, generation: UUID? = nil) {
        guard let drag = planDrag,
              lightID == nil || lightID == drag.lightID,
              generation == nil || generation == drag.generation else { return }
        if drag.generation == self.generation { editor.endEditing(owner: drag.owner) }
        planDrag = nil
    }

    @discardableResult
    func undo(from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        return editor.undo()
    }

    @discardableResult
    func redo(from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        return editor.redo()
    }

    func editOwner(_ control: String) -> String {
        // First save changes storage identity, but the same document's pending
        // numeric drafts and focus must keep their SwiftUI control identity.
        // Each callback still checks the separately captured generation.
        "\(workspaceResetID.uuidString).\(control)"
    }

    func applyLibrary(_ command: ProjectLibraryCommand, from generation: UUID) throws -> Task<Void, Error> {
        guard saved == scene, library != nil else { throw ProjectLibraryError.staleSnapshot }
        return try beginLibraryOperation(.change(command), from: generation)
    }

    /// Reserve first. A stale Save callback must not end a newer drag or split
    /// its undo group before discovering that its document identity is obsolete.
    func beginLibraryOperation(_ operation: ProjectLibraryOperation,
                               from generation: UUID) throws -> Task<Void, Error> {
        switch operation {
        case .load:
            // Initial load and a protected-data retry are allowed. Re-running
            // initial load on a healthy editor must not discard a dirty document.
            guard !loaded || saveBlocked else { throw ProjectLibraryError.staleSnapshot }
        default:
            guard loaded, !saveBlocked else { throw ProjectLibraryError.invalidLibrary }
        }
        let request = try libraryOperation.reserve(operation, library: library, scene: scene, from: generation)
        editor.endEditing()
        planDrag = nil
        let task = Task { @MainActor [self] in
            defer {
                if operationTaskID == request.id {
                    operationTask = nil
                    operationTaskID = nil
                }
            }
            do {
                let result = try await execute(request)
                // Cancellation cannot undo a committed write. Its receipt must
                // still settle the reservation and leave any newer edits dirty.
                var nextOperation = libraryOperation
                guard let adoption = try nextOperation.adopt(result, for: request,
                                                             currentProjectID: library?.activeID,
                                                             currentScene: scene) else {
                    if libraryOperation.finish(request) {
                        saveConflict = true
                        message = "An earlier project operation completed after this editor changed. Your current setup has been kept."
                    }
                    throw ProjectLibraryOperationState.OperationError.staleEditor
                }
                // Validate a complete prospective adoption before publishing any
                // of its scene/history/library/generation state to observers.
                var nextEditor = editor
                try nextEditor.adopt(adoption.scene, resettingHistory: adoption.resetsHistory)
                let nextSaved = try adoption.saved?.validated()
                libraryOperation = nextOperation
                editor = nextEditor
                library = adoption.library
                saved = nextSaved
                if adoption.resetsPresentation {
                    workspaceResetID = UUID()
                    feature = nil
                }
                loaded = true
                saveBlocked = false
                saveConflict = false
                switch operation {
                case .load, .change: message = nil
                case .save: message = "Project saved on this device."
                case .reload: message = "Latest saved library opened."
                case .recover: message = "Your setup was saved as a recovery project."
                }
            } catch {
                if libraryOperation.finish(request) {
                    switch operation {
                    case .load:
                        saveBlocked = true
                        loaded = true
                        message = "Saved project could not be opened. Saving is disabled to protect existing data."
                    case .recover:
                        message = "Could not save a recovery copy. Your edits remain in this window. \(error.localizedDescription)"
                        if (error as? ProjectLibraryError) == .capacity { showRecoveryCapacity = true }
                    case .reload:
                        message = "Could not reload. Your edits remain in this window. \(error.localizedDescription)"
                    case .save, .change:
                        if (error as? ProjectLibraryError) == .staleSnapshot { saveConflict = true }
                        message = "Could not save the project. Your edits remain in this session. \(error.localizedDescription)"
                    }
                }
                throw error
            }
        }
        operationTaskID = request.id
        operationTask = task
        return task
    }

    func recoveryProjects() async throws -> [LightingProject] {
        try await store.recoveryLibrarySnapshot().projects
    }

    var recoveryProjectName: String {
        let suffix = " recovery"
        return StudioDisplayName.display(projectName, maximumCharacters: ProjectLibrary.maximumNameLength - suffix.count) + suffix
    }
}
