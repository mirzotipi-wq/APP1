import Foundation

/// One editor's validated scene, selection and bounded undo history. Presentation
/// and disk state live outside this value. Revisions are identity tokens, not
/// counters: undoing back to equal content never revives an obsolete result.
public struct StudioEditorState: Equatable, Sendable {
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
        let validated = try candidate.validated()
        let normalized = history.preservingOptionalRepresentations(in: validated)
        guard normalized != scene else { return false }
        if !history.isEditing { history.record(previous: scene) }
        scene = normalized
        revision = UUID()
        repairSelection()
        return true
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
        if resettingHistory {
            history.reset()
            scene = validated
            selection = scene.lights.first?.id
            revision = UUID()
        } else if validated != scene {
            scene = validated
            revision = UUID()
            repairSelection()
        }
    }

    private mutating func repairSelection() {
        if !scene.lights.contains(where: { $0.id == selection }) {
            selection = scene.lights.first?.id
        }
    }
}
