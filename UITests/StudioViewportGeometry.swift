import Foundation

/// Pure geometry over one immutable accessibility snapshot. The UI adapter
/// supplies live fixed-control hittability separately; no result survives a scroll.
struct StudioViewportGeometry {
    enum Kind { case application, other, scrollView, collectionView, table, navigationBar, keyboard, button, content }
    struct Node {
        let kind: Kind
        let identifier: String
        let frame: CGRect
        let parent: Int?
    }
    enum Failure: Error { case invalidTree, invalidFrame, missingScrollContainer, missingNavigationOwner }

    let nodes: [Node]

    init(nodes: [Node]) throws {
        guard !nodes.isEmpty, nodes[0].parent == nil else { throw Failure.invalidTree }
        for index in nodes.indices.dropFirst() {
            guard let parent = nodes[index].parent, parent >= 0, parent < index else {
                throw Failure.invalidTree
            }
        }
        guard Self.valid(nodes[0].frame) else { throw Failure.invalidFrame }
        self.nodes = nodes
    }

    var applicationFrame: CGRect { nodes[0].frame }

    /// A missing lazy row can still be searched by scrolling above the keyboard.
    /// This fallback never establishes target visibility or a successful check.
    func searchViewport() throws -> CGRect { try avoidingKeyboard(applicationFrame) }

    func viewport(target: Int, hittableFixedControls: Set<Int>) throws -> CGRect {
        guard nodes.indices.contains(target), Self.valid(nodes[target].frame) else {
            throw Failure.invalidFrame
        }
        let parents = ancestors(of: target)
        let scrolls = parents.filter { [.scrollView, .collectionView, .table].contains(nodes[$0].kind) }
        guard !scrolls.isEmpty else { throw Failure.missingScrollContainer }
        var result = applicationFrame
        for index in scrolls {
            guard Self.valid(nodes[index].frame) else { throw Failure.invalidFrame }
            result = result.intersection(nodes[index].frame)
        }
        let navigation = owningNavigationBars(of: target)
        for index in navigation where !nodes[index].frame.isEmpty {
            let frame = nodes[index].frame
            guard Self.valid(frame) else { throw Failure.invalidFrame }
            if frame.intersects(result) {
                let bottom = result.maxY
                result.origin.y = max(result.minY, frame.maxY)
                result.size.height = max(0, bottom - result.minY)
            }
        }
        result = try avoidingKeyboard(result)
        for index in hittableFixedControls {
            guard nodes.indices.contains(index), nodes[index].kind == .button,
                  ["undo", "projectLibraryDone"].contains(nodes[index].identifier),
                  Self.valid(nodes[index].frame) else { throw Failure.invalidFrame }
            // The closest navigation owner distinguishes a foreground naming
            // sheet from the covered Projects sheet and the studio behind it.
            guard nodes[index].frame.intersects(result) else { continue }
            let controlNavigation = owningNavigationBars(of: index)
            guard !navigation.isEmpty, !controlNavigation.isEmpty else {
                // An overlapping live control with unknown ownership cannot
                // be dismissed as belonging to an unrelated covered sheet.
                throw Failure.missingNavigationOwner
            }
            guard !navigation.isDisjoint(with: controlNavigation) else { continue }
            result.size.height = max(0, min(result.maxY, nodes[index].frame.minY) - result.minY)
        }
        return result
    }

    private func ancestors(of index: Int) -> [Int] {
        var result: [Int] = []
        var parent = nodes[index].parent
        while let index = parent {
            result.append(index)
            parent = nodes[index].parent
        }
        return result
    }

    private func owningNavigationBars(of index: Int) -> Set<Int> {
        for ancestor in ancestors(of: index) where nodes[ancestor].kind == .other {
            let bars = Set(nodes.indices.filter {
                nodes[$0].parent == ancestor && nodes[$0].kind == .navigationBar
            })
            if !bars.isEmpty { return bars }
        }
        return []
    }

    private func avoidingKeyboard(_ viewport: CGRect) throws -> CGRect {
        let keyboards = nodes.indices.filter { nodes[$0].kind == .keyboard && !nodes[$0].frame.isEmpty }
        guard !keyboards.isEmpty else { return viewport }
        let assistant = nodes.indices.filter {
            nodes[$0].kind == .other && ["inputView", "SystemInputAssistantView"].contains(nodes[$0].identifier)
        }
        var result = viewport
        for index in keyboards + assistant where !nodes[index].frame.isEmpty {
            let frame = nodes[index].frame
            guard Self.valid(frame) else { throw Failure.invalidFrame }
            if frame.intersects(result) {
                result.size.height = max(0, min(result.maxY, frame.minY) - result.minY)
            }
        }
        return result
    }

    private static func valid(_ frame: CGRect) -> Bool {
        !frame.isEmpty && !frame.isNull && !frame.isInfinite &&
        frame.minX.isFinite && frame.minY.isFinite && frame.maxX.isFinite && frame.maxY.isFinite
    }
}
