import Foundation
import LightingCore

/// Commands cross the storage boundary as values. Their domain mutations and
/// validation run on the store actor, never while constructing a UI callback.
enum ProjectLibraryCommand: Sendable {
    case create(name: String, scene: LightingScene)
    case rename(UUID, name: String)
    case duplicate(UUID, name: String)
    case select(UUID)
    case archive(UUID)
    case restore(UUID)
    case deleteArchived(UUID)

    func apply(to library: inout ProjectLibrary) throws {
        switch self {
        case let .create(name, scene): try library.create(name: name, scene: scene)
        case let .rename(id, name): try library.rename(id, to: name)
        case let .duplicate(id, name): try library.duplicate(id, name: name)
        case let .select(id): try library.select(id)
        case let .archive(id): try library.archive(id)
        case let .restore(id): try library.restore(id)
        case let .deleteArchived(id): try library.deleteArchived(id)
        }
    }
}

enum ProjectLibraryOperation: Sendable {
    case load
    case save
    case change(ProjectLibraryCommand)
    case reload
    case recover(name: String, replacing: LightingProject?)
    case recoverUnreadable(snapshot: ProjectLibraryRecoverySnapshot)

    var progressTitle: String {
        switch self {
        case .load, .reload: return "Opening projects…"
        case .save: return "Saving lighting setup…"
        case .change: return "Updating projects…"
        case .recover: return "Saving recovery project…"
        case .recoverUnreadable: return "Keeping saved files and creating a new library…"
        }
    }
}

struct ProjectLibraryRequest: Sendable {
    let id: UUID
    let generation: UUID
    let projectID: UUID?
    let expected: ProjectLibrary?
    let scene: LightingScene
    let operation: ProjectLibraryOperation
}

struct ProjectLibraryAdoption {
    let library: ProjectLibrary?
    let scene: LightingScene
    let saved: LightingScene?
    let resetsHistory: Bool
    let resetsPresentation: Bool
}

/// The parent editor reserves synchronously before starting a task. Children
/// may await that task, but closing a sheet cannot abandon a committed write.
/// Identity checks use UUIDs rather than comparing a potentially large library.
struct ProjectLibraryOperationState {
    enum OperationError: Error, Equatable, LocalizedError {
        case busy, staleEditor

        var errorDescription: String? {
            switch self {
            case .busy: return "Wait for the current project operation to finish."
            case .staleEditor: return "The open project changed. Your current setup has been kept."
            }
        }
    }

    private(set) var generation = UUID()
    private(set) var pending: ProjectLibraryRequest?
    var isBusy: Bool { pending != nil }

    func allowsSceneMutation(from capturedGeneration: UUID) -> Bool {
        !isBusy && generation == capturedGeneration
    }

    mutating func reserve(_ operation: ProjectLibraryOperation, library: ProjectLibrary?,
                          scene: LightingScene, from capturedGeneration: UUID) throws -> ProjectLibraryRequest {
        guard generation == capturedGeneration else { throw OperationError.staleEditor }
        guard pending == nil else { throw OperationError.busy }
        let request = ProjectLibraryRequest(id: UUID(), generation: generation, projectID: library?.activeID,
                                            expected: library, scene: scene, operation: operation)
        pending = request
        return request
    }

    /// A delayed completion cannot clear another operation's busy state.
    @discardableResult
    mutating func finish(_ request: ProjectLibraryRequest) -> Bool {
        guard pending?.id == request.id else { return false }
        pending = nil
        return true
    }

    mutating func adopt(_ result: ProjectLibrary?, for request: ProjectLibraryRequest,
                        currentProjectID: UUID?, currentScene: LightingScene) throws -> ProjectLibraryAdoption? {
        guard pending?.id == request.id, generation == request.generation,
              currentProjectID == request.projectID else { return nil }

        let adoption: ProjectLibraryAdoption
        switch request.operation {
        case .load:
            let active = result?.activeProject
            if result != nil && active == nil { throw ProjectLibraryError.invalidLibrary }
            adoption = .init(library: result, scene: active?.scene ?? request.scene, saved: active?.scene,
                             resetsHistory: true, resetsPresentation: false)
        case .save:
            guard let active = result?.activeProject else { throw ProjectLibraryError.invalidLibrary }
            // Even if a future caller allows edits during save, never mark its
            // newer current scene as written or replace it with the old scene.
            adoption = .init(library: result, scene: currentScene, saved: active.scene,
                             resetsHistory: false, resetsPresentation: false)
        case .change:
            guard let active = result?.activeProject else { throw ProjectLibraryError.invalidLibrary }
            let switching = active.id != request.projectID
            adoption = .init(library: result, scene: switching ? active.scene : currentScene,
                             saved: active.scene, resetsHistory: switching, resetsPresentation: switching)
        case .reload, .recover, .recoverUnreadable:
            guard let active = result?.activeProject else { throw ProjectLibraryError.invalidLibrary }
            adoption = .init(library: result, scene: active.scene, saved: active.scene,
                             resetsHistory: true, resetsPresentation: true)
        }
        // First save changes draft identity, but deliberately keeps history,
        // selection and mode. Reloading the same ID still invalidates old views.
        if adoption.resetsHistory || result?.activeID != request.projectID { generation = UUID() }
        finish(request)
        return adoption
    }
}
