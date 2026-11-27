import Foundation
let kinds: [String: StudioViewportGeometry.Kind] = ["application": .application, "other": .other, "scrollView": .scrollView, "collectionView": .collectionView, "table": .table, "navigationBar": .navigationBar, "keyboard": .keyboard, "button": .button, "content": .content]
for stem in ["feedback", "welcome"] {
    let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1] + "/" + stem + "-geometry-nodes.json"))
    let raw = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
    let nodes = raw.map { d -> StudioViewportGeometry.Node in
        let f = d["frame"] as! [Double]
        return .init(kind: kinds[d["kind"] as! String]!, identifier: d["identifier"] as! String,
                     frame: CGRect(x: f[0], y: f[1], width: f[2], height: f[3]), parent: d["parent"] as? Int)
    }
    let geometry = try StudioViewportGeometry(nodes: nodes)
    let targets = nodes.indices.filter { ["openBetaFeedback", "studioWelcomeTitle"].contains(nodes[$0].identifier) }
    let undo = Set(nodes.indices.filter { nodes[$0].identifier == "undo" })
    for target in targets {
        for fixed in [Set<Int>(), undo] {
            let viewport = try geometry.viewport(target: target, hittableFixedControls: fixed)
            let frame = nodes[target].frame
            print("\(stem) target=\(frame), actualViewport=\(viewport), contained=\(viewport.contains(frame)), fixedControls=\(fixed.sorted())")
            precondition(viewport.contains(frame))
            if stem == "feedback" {
                let legacy = geometry.applicationFrame.insetBy(dx: 0, dy: 100)
                let center = CGPoint(x: frame.midX,y: frame.midY)
                print("feedback legacyViewport=\(legacy), center=\(center), legacyContainsCenter=\(legacy.contains(center))")
                precondition(!legacy.contains(center))
            }
        }
    }
}
