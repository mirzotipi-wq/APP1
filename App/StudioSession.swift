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
    typealias RecoveryInspector = @Sendable () async throws -> ProjectLibraryRecoverySnapshot

    /// The Plan gesture uses cumulative translation, so its origin and scale
    /// must remain fixed until that exact gesture ends.
    struct PlanDrag: Equatable {
        let token: UUID
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
    private struct MessageReceipt {
        let text: String
        let savedRevision: UUID?
        let projectID: UUID?
    }
    private var messageReceipt: MessageReceipt?
    /// A completed save describes one editor revision, not later edits. Keep
    /// errors independent of revision so editing cannot hide a failed write.
    var message: String? {
        get {
            guard let receipt = messageReceipt else { return nil }
            if let savedRevision = receipt.savedRevision {
                guard savedRevision == revision, receipt.projectID == library?.activeID,
                      saved == scene else { return nil }
            }
            return receipt.text
        }
        set {
            messageReceipt = newValue.map {
                MessageReceipt(text: $0, savedRevision: nil, projectID: nil)
            }
        }
    }
    var showRecoveryCapacity = false

    private let store: ProjectStore
    private let execute: Executor
    private let inspectUnreadable: RecoveryInspector
    /// Only the session-created starter may be replaced before its first save.
    /// An actual edit changes the revision even when a gesture returns to its
    /// starting values and leaves no undo entry.
    private var initialProjectRevision: UUID?
    // Observation is the native SwiftUI adapter. Portable tests execute this
    // same orchestration without depending on a Linux Observation runtime.
    // Keep each ignored attribute on its complete native declaration so the
    // Observable macro does not also generate tracking accessors for it.
    #if canImport(Darwin)
    @ObservationIgnored private(set) var operationTask: Task<Void, Error>?
    @ObservationIgnored private var operationTaskID: UUID?
    #else
    private(set) var operationTask: Task<Void, Error>?
    private var operationTaskID: UUID?
    #endif

    init(editor: StudioEditorState? = nil, store: ProjectStore = ProjectStore(),
         execute: Executor? = nil, inspectUnreadable: RecoveryInspector? = nil) {
        let initialEditor = editor ?? StudioEditorState()
        self.editor = initialEditor
        // A caller-supplied editor may already contain an unsaved draft, even
        // when its history is empty. It never receives the starter exception.
        initialProjectRevision = editor == nil ? initialEditor.revision : nil
        self.store = store
        self.execute = execute ?? { request in try await store.perform(request) }
        self.inspectUnreadable = inspectUnreadable ?? { try await store.inspectUnreadableLibrary() }
    }

    var scene: LightingScene { editor.scene }
    var selection: UUID? { editor.selection }
    var history: SceneEditHistory { editor.history }
    var generation: UUID { libraryOperation.generation }
    var revision: UUID { editor.revision }
    var isBusy: Bool { libraryOperation.isBusy }
    var projectName: String { library?.activeProject?.name ?? "Portrait setup" }

    var canCreateInitialProject: Bool {
        loaded && !saveBlocked && !saveConflict && library == nil && saved == nil &&
            !isBusy && !history.isEditing && !history.canUndo && !history.canRedo &&
            planDrag == nil && feature == nil && initialProjectRevision == revision
    }

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
            if let drag = planDrag { candidate.endEditing(owner: drag.owner) }
            guard try candidate.update(with: next) else { return false }
            editor = candidate
            planDrag = nil
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
            // An unrelated command cannot silently join an open Plan/room/AR group.
            // Stage its boundary too: invalid/no-op commands leave that group intact.
            var candidate = editor
            if let feature { candidate.endEditing(owner: feature.context.owner) }
            if let drag = planDrag { candidate.endEditing(owner: drag.owner) }
            guard try candidate.apply(command) else { return false }
            editor = candidate
            planDrag = nil
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
            endEditing(owner: owner)
        }
    }

    func endEditing(owner: String? = nil) {
        if let drag = planDrag, owner == nil || owner == drag.owner {
            finishPlanDrag()
        } else {
            editor.endEditing(owner: owner)
        }
    }

    /// Only a newly recognized gesture may begin a transaction. A retired
    /// callback can never rebase its cumulative translation onto the live scene.
    func beginPlanDrag(_ id: UUID, scale: Double, from generation: UUID) -> UUID? {
        guard allowsMutation(from: generation), selection == id,
              scene.lights.contains(where: { $0.id == id }), planDrag == nil,
              scale.isFinite, scale > 0 else { return nil }
        let token = UUID()
        let owner = editOwner("plan.\(id.uuidString).\(token.uuidString)")
        editor.beginEditing(owner: owner)
        planDrag = PlanDrag(token: token, lightID: id, generation: generation, scene: scene,
                            pointsPerMeter: scale, owner: owner)
        return token
    }

    @discardableResult
    func dragLight(_ id: UUID, token: UUID, translationX: Double, translationZ: Double,
                   scale: Double, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation), selection == id,
              let light = scene.lights.first(where: { $0.id == id }),
              scale.isFinite, scale > 0,
              translationX.isFinite, translationZ.isFinite,
              let drag = planDrag, drag.token == token,
              drag.lightID == id, drag.generation == generation,
              let source = drag.scene.lights.first(where: { $0.id == id }) else { return false }
        let range = Position.coordinateRange
        // Plan owns x/z only. Keep the live height rather than restoring an
        // unrelated coordinate from the frozen cumulative-translation origin.
        var position = light.position
        position.x = min(range.upperBound, max(range.lowerBound,
            source.position.x + translationX / drag.pointsPerMeter))
        position.z = min(range.upperBound, max(range.lowerBound,
            source.position.z + translationZ / drag.pointsPerMeter))
        guard position.isValid else { return false }
        // This command belongs to the active Plan transaction. Public apply
        // closes that transaction for unrelated discrete control commands.
        do { return try editor.apply(.lightPosition(id: id, position: position)) }
        catch { return false }
    }

    func finishPlanDrag(token: UUID, lightID: UUID, generation: UUID) {
        guard let drag = planDrag, drag.token == token,
              lightID == drag.lightID, generation == drag.generation else { return }
        finishPlanDrag()
    }

    /// Parent lifecycle boundaries retire whichever gesture currently owns Plan.
    /// Value/end callbacks must use the token-qualified overload instead.
    func finishPlanDrag() {
        guard let drag = planDrag else { return }
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
        try beginLibraryOperation(.change(command), from: generation)
    }

    /// Inspection may suspend while another callback retries loading or starts
    /// recovery. A returned observation must still belong to this blocked editor.
    func inspectUnreadableLibrary(from generation: UUID) async throws -> ProjectLibraryRecoverySnapshot {
        try requireUnreadableRecovery(from: generation)
        try Task.checkCancellation()
        let snapshot = try await inspectUnreadable()
        try Task.checkCancellation()
        try requireUnreadableRecovery(from: generation)
        return snapshot
    }

    func recoverUnreadableLibrary(_ snapshot: ProjectLibraryRecoverySnapshot,
                                  from generation: UUID) throws -> Task<Void, Error> {
        try beginLibraryOperation(.recoverUnreadable(snapshot: snapshot), from: generation)
    }

    private func requireUnreadableRecovery(from generation: UUID) throws {
        guard generation == self.generation else { throw ProjectLibraryOperationState.OperationError.staleEditor }
        guard !isBusy else { throw ProjectLibraryOperationState.OperationError.busy }
        guard loaded, saveBlocked else { throw ProjectLibraryError.recoveryNotNeeded }
        // A failed initial load is not permission to discard a supplied draft.
        // Only the session's untouched starter can become the new library.
        guard library == nil, saved == nil, !saveConflict, initialProjectRevision == revision,
              !history.isEditing, !history.canUndo, !history.canRedo,
              planDrag == nil, feature == nil else { throw ProjectLibraryError.staleSnapshot }
    }

    /// Reserve first. A stale Save callback must not end a newer drag or split
    /// its undo group before discovering that its document identity is obsolete.
    func beginLibraryOperation(_ operation: ProjectLibraryOperation,
                               from generation: UUID) throws -> Task<Void, Error> {
        switch operation {
        case .recoverUnreadable:
            try requireUnreadableRecovery(from: generation)
        case .load:
            // Initial load and a protected-data retry are allowed. Re-running
            // initial load on a healthy editor must not discard a dirty document.
            guard !loaded || saveBlocked else { throw ProjectLibraryError.staleSnapshot }
        default:
            guard loaded, !saveBlocked else { throw ProjectLibraryError.invalidLibrary }
        }
        if case let .change(command) = operation {
            switch command {
            case .create where canCreateInitialProject:
                break
            default:
                guard saved == scene, library != nil else { throw ProjectLibraryError.staleSnapshot }
            }
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
                if case .load = operation, result == nil, initialProjectRevision == editor.revision {
                    // Initial load resets editor history/revision. Carry the
                    // pristine marker only across that healthy empty receipt.
                    initialProjectRevision = nextEditor.revision
                } else {
                    initialProjectRevision = nil
                }
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
                case .save: showSavedMessage("Project saved on this device.")
                case .reload: showSavedMessage("Latest saved library opened.")
                case .recover: showSavedMessage("Your setup was saved as a recovery project.")
                case .recoverUnreadable:
                    showRecoveryCapacity = false
                    showSavedMessage("A new library was created. Original saved files were kept on this device.")
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
                    case .recoverUnreadable:
                        message = "The saved library remains blocked. Check the saved files again before starting over."
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

    private func showSavedMessage(_ text: String) {
        // A committed receipt may describe an earlier scene if future callers
        // permit editing during a write. Never label those newer edits saved.
        guard saved == scene else { message = nil; return }
        messageReceipt = MessageReceipt(text: text, savedRevision: revision,
                                        projectID: library?.activeID)
    }

    func recoveryProjects() async throws -> [LightingProject] {
        try await store.recoveryLibrarySnapshot().projects
    }

    var recoveryProjectName: String {
        let suffix = " recovery"
        return StudioDisplayName.display(projectName, maximumCharacters: ProjectLibrary.maximumNameLength - suffix.count) + suffix
    }
}
