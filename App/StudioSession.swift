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

    private(set) var editor: StudioEditorState
    private(set) var library: ProjectLibrary?
    private(set) var saved: LightingScene?
    private(set) var libraryOperation = ProjectLibraryOperationState()
    private(set) var loaded = false
    private(set) var saveBlocked = false
    private(set) var saveConflict = false
    private(set) var workspaceResetID = UUID()
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
        return editor.select(id)
    }

    @discardableResult
    func replace(_ next: LightingScene, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        do { return try editor.replace(with: next) }
        catch {
            message = "The proposed setup contains unsupported values. Your current setup has been kept."
            return false
        }
    }

    @discardableResult
    func update(_ next: LightingScene, from generation: UUID) -> Bool {
        guard allowsMutation(from: generation) else { return false }
        do { return try editor.update(with: next) }
        catch { return false }
    }

    func editChanged(_ editing: Bool, owner: String, from generation: UUID) {
        guard generation == self.generation else { return }
        if editing {
            guard allowsMutation(from: generation) else { return }
            editor.beginEditing(owner: owner)
        } else {
            editor.endEditing(owner: owner)
        }
    }

    func endEditing(owner: String? = nil) { editor.endEditing(owner: owner) }

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
        "\(generation.uuidString).\(library?.activeID.uuidString ?? "draft").\(control)"
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
        case .load: break
        default:
            guard loaded, !saveBlocked else { throw ProjectLibraryError.invalidLibrary }
        }
        let request = try libraryOperation.reserve(operation, library: library, scene: scene, from: generation)
        editor.endEditing()
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
                if adoption.resetsPresentation { workspaceResetID = UUID() }
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
