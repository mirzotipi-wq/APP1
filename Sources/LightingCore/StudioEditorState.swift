import Foundation

/// One editor's validated scene, selection and bounded undo history. Presentation
/// and disk state live outside this value. Revisions are identity tokens, not
/// counters: undoing back to equal content never revives an obsolete result.
public struct StudioEditorState: Equatable, Sendable {
    public enum AdoptionError: Error, Equatable {
        case changesSceneWithoutReset
    }
    public private(set) var scene: LightingScene
    public private(set) var selection: UUID?
    public private(set) var history = SceneEditHistory()
    public private(set) var revision = UUID()

    public init() {
        let scene = LightingScene.portrait()
        self.scene = scene
        selection = scene.lights.first?.id
    }

    public init(scene: LightingScene, selection: UUID? = nil) throws {
        self.scene = try scene.validated()
        self.selection = selection
        repairSelection()
    }

    /// Selection is always an existing UUID, or nil for an empty rig. Selecting
    /// another control commits the previous gesture without changing geometry.
    @discardableResult
    public mutating func select(_ id: UUID?) -> Bool {
        guard id != selection else { return false }
        guard let id, scene.lights.contains(where: { $0.id == id }) else { return false }
        endEditing()
        selection = id
        return true
    }

    /// A discrete command commits an open continuous edit first, giving each
    /// its own undo entry. Validation happens before changing any editor state.
    @discardableResult
    public mutating func replace(with candidate: LightingScene) throws -> Bool {
        let validated = try candidate.validated()
        guard validated != scene else { return false }
        history.record(previous: scene)
        scene = validated
        revision = UUID()
        repairSelection()
        return true
    }

    /// A control update belongs to the current continuous transaction, if any;
    /// otherwise it is one discrete change. Only the editor owns history writes.
    @discardableResult
    public mutating func update(with candidate: LightingScene) throws -> Bool {
        commitValidatedUpdate(try candidate.validated())
    }

    /// Like `update(with:)`, joins the current continuous edit or records one
    /// discrete change. The private scene is already validated, so these closed
    /// edits validate only their payload and live light UUID before any mutation.
    @discardableResult
    public mutating func apply(_ command: StudioFieldCommand) throws -> Bool {
        var candidate = scene
        switch command {
        case let .lightValue(id, field, value):
            guard value.isFinite, field.domain.contains(value),
                  let index = scene.lights.firstIndex(where: { $0.id == id }) else {
                throw SceneError.invalidLight
            }
            guard field.value(in: scene.lights[index]) != value else { return false }
            switch field {
            case .x: candidate.lights[index].position.x = value
            case .y: candidate.lights[index].position.y = value
            case .z: candidate.lights[index].position.z = value
            case .candela: candidate.lights[index].candela = value
            case .kelvin: candidate.lights[index].kelvin = value
            }
        case let .lightPosition(id, position):
            guard position.isValid,
                  let index = scene.lights.firstIndex(where: { $0.id == id }) else {
                throw SceneError.invalidLight
            }
            guard scene.lights[index].position != position else { return false }
            candidate.lights[index].position = position
        case let .lightOptics(id, optics):
            guard optics.isValid,
                  let index = scene.lights.firstIndex(where: { $0.id == id }) else {
                throw SceneError.invalidLight
            }
            let current = scene.lights[index].effectiveOptics
            var normalized = optics
            if normalized.effectiveRollDegrees == current.effectiveRollDegrees {
                normalized.rollDegrees = current.rollDegrees
            }
            // An implicit subject target remains distinct from a manual target,
            // even when their current positions happen to be equal.
            guard normalized != current else { return false }
            candidate.lights[index].optics = normalized
        case let .cameraPosition(position):
            guard position.isValid else { throw SceneError.invalidScene }
            guard scene.camera != position else { return false }
            candidate.camera = position
        case let .subjectPosition(position):
            guard position.isValid else { throw SceneError.invalidScene }
            guard scene.subject != position else { return false }
            candidate.subject = position
        case let .cameraLens(lens):
            guard lens.isValid else { throw SceneError.invalidScene }
            guard scene.effectiveCameraLens != lens else { return false }
            candidate.cameraLens = lens
        case let .previewSettings(settings):
            guard settings.isValid else { throw SceneError.invalidScene }
            guard scene.effectivePreviewSettings != settings else { return false }
            candidate.previewSettings = settings
        case let .room(room):
            guard room?.isValid ?? true else { throw SceneError.invalidScene }
            guard scene.placementRoom != room else { return false }
            candidate.placementRoom = room
        }
        return commitValidatedUpdate(candidate)
    }

    public mutating func beginEditing(owner: String) {
        history.begin(scene: scene, owner: owner)
    }

    public mutating func endEditing(owner: String? = nil) {
        if let owner { history.end(scene: scene, owner: owner) }
        else { history.end(scene: scene) }
    }

    /// A lifecycle rollback must restore the original scene as well as history.
    @discardableResult
    public mutating func cancelEditing() -> Bool {
        guard let original = history.cancel() else { return false }
        if original != scene { scene = original; revision = UUID() }
        repairSelection()
        return true
    }

    @discardableResult
    public mutating func undo() -> Bool {
        guard !history.isEditing, let previous = history.undo(current: scene) else { return false }
        scene = previous
        revision = UUID()
        repairSelection()
        return true
    }

    @discardableResult
    public mutating func redo() -> Bool {
        guard !history.isEditing, let next = history.redo(current: scene) else { return false }
        scene = next
        revision = UUID()
        repairSelection()
        return true
    }

    /// A storage receipt is not an editing command. The caller passes the
    /// adoption policy, rather than inferring history reset from an ID change:
    /// first save establishes project identity but must retain undo/selection.
    public mutating func adopt(_ candidate: LightingScene, resettingHistory: Bool) throws {
        let validated = try candidate.validated()
        // Save and metadata receipts retain the live scene. Replacing it while
        // keeping another scene's redo or open transaction would rebase history.
        guard resettingHistory || validated == scene else {
            throw AdoptionError.changesSceneWithoutReset
        }
        if resettingHistory {
            history.reset()
            scene = validated
            selection = scene.lights.first?.id
            revision = UUID()
        }
    }

    /// Only fully validated candidates or closed, payload-validated commands
    /// enter here. Keep normalization and history/revision changes in one place.
    private mutating func commitValidatedUpdate(_ candidate: LightingScene) -> Bool {
        let normalized = history.preservingOptionalRepresentations(in: candidate)
        guard normalized != scene else { return false }
        if !history.isEditing { history.record(previous: scene) }
        scene = normalized
        revision = UUID()
        repairSelection()
        return true
    }

    private mutating func repairSelection() {
        if !scene.lights.contains(where: { $0.id == selection }) {
            selection = scene.lights.first?.id
        }
    }
}
