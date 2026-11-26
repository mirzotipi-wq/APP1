import XCTest

/// One remote AX capture supplies a coherent geometry pass. A subsequent pass
/// takes another capture; live hit testing and every real interaction remain separate.
struct StudioViewportObservation {
    enum Failure: Error { case excessiveTree, missingTarget, ambiguousTarget, ambiguousFixedControl }
    let target: (any XCUIElementSnapshot)?
    let viewport: CGRect
    let applicationFrame: CGRect

    init(in app: XCUIApplication, matching expected: (any XCUIElementSnapshot)?) throws {
        let root = try app.snapshot()
        var snapshots: [any XCUIElementSnapshot] = [root]
        var nodes = [StudioViewportGeometry.Node(kind: .application, identifier: root.identifier,
                                                 frame: root.frame, parent: nil)]
        var cursor = 0
        while cursor < snapshots.count {
            let children = snapshots[cursor].children
            guard snapshots.count + children.count <= 10_000 else { throw Failure.excessiveTree }
            for child in children {
                nodes.append(.init(kind: Self.kind(child.elementType), identifier: child.identifier,
                                   frame: child.frame, parent: cursor))
                snapshots.append(child)
            }
            cursor += 1
        }
        let geometry = try StudioViewportGeometry(nodes: nodes)
        applicationFrame = geometry.applicationFrame
        guard let expected else {
            target = nil
            viewport = try geometry.searchViewport()
            return
        }
        var matches = snapshots.indices.filter {
            snapshots[$0].elementType == expected.elementType &&
            snapshots[$0].identifier == expected.identifier && snapshots[$0].label == expected.label
        }
        if matches.count > 1 { matches = matches.filter { snapshots[$0].frame == expected.frame } }
        guard !matches.isEmpty else { throw Failure.missingTarget }
        guard matches.count == 1, let index = matches.first else { throw Failure.ambiguousTarget }
        target = snapshots[index]
        var hittableFixedControls: Set<Int> = []
        for identifier in ["undo", "projectLibraryDone"] {
            let candidates = nodes.indices.filter { nodes[$0].kind == .button && nodes[$0].identifier == identifier }
            guard candidates.count <= 1 else { throw Failure.ambiguousFixedControl }
            if let candidate = candidates.first,
               app.buttons.matching(identifier: identifier).firstMatch.isHittable {
                hittableFixedControls.insert(candidate)
            }
        }
        viewport = try geometry.viewport(target: index, hittableFixedControls: hittableFixedControls)
    }

    private static func kind(_ type: XCUIElement.ElementType) -> StudioViewportGeometry.Kind {
        switch type {
        case .application: return .application
        case .other: return .other
        case .scrollView: return .scrollView
        case .collectionView: return .collectionView
        case .table: return .table
        case .navigationBar: return .navigationBar
        case .keyboard: return .keyboard
        case .button: return .button
        default: return .content
        }
    }
}
