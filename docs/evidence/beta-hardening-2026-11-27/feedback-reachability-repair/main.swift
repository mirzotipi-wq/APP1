import Foundation

let kinds: [String: StudioViewportGeometry.Kind] = [
    "application": .application, "other": .other, "scrollView": .scrollView,
    "collectionView": .collectionView, "table": .table, "navigationBar": .navigationBar,
    "keyboard": .keyboard, "button": .button, "content": .content
]
let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let raw = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
let nodes = raw.map { record -> StudioViewportGeometry.Node in
    let frame = record["frame"] as! [Double]
    return .init(kind: kinds[record["kind"] as! String]!,
                 identifier: record["identifier"] as! String,
                 frame: CGRect(x: frame[0], y: frame[1], width: frame[2], height: frame[3]),
                 parent: record["parent"] as? Int)
}
let targets = nodes.indices.filter { nodes[$0].identifier == "openBetaFeedback" }
precondition(targets.count == 1)
let target = targets[0]
let frame = nodes[target].frame
let geometry = try StudioViewportGeometry(nodes: nodes)
let actual = try geometry.viewport(target: target, hittableFixedControls: [])
precondition(actual == CGRect(x: 0, y: 132, width: 402, height: 742))
precondition(actual.contains(frame))
let legacy = geometry.applicationFrame.insetBy(dx: 0, dy: 100)
precondition(!legacy.contains(CGPoint(x: frame.midX, y: frame.midY)))
print("Observed full frame: \(frame); viewport: \(actual); legacy rejects center: true")

let coveredUndo = Set(nodes.indices.filter { nodes[$0].identifier == "undo" })
let withCoveredControl = try geometry.viewport(target: target, hittableFixedControls: coveredUndo)
precondition(withCoveredControl == actual)

let keyboard = StudioViewportGeometry.Node(kind: .keyboard, identifier: "",
    frame: CGRect(x: 0, y: 780, width: 402, height: 94), parent: 0)
let occluded = try StudioViewportGeometry(nodes: nodes + [keyboard])
    .viewport(target: target, hittableFixedControls: [])
precondition(!occluded.contains(frame))
precondition(occluded.maxY == 780)
for clipped in [CGRect(x: 16, y: 110, width: 370, height: 52),
                CGRect(x: 16, y: 850, width: 370, height: 52),
                CGRect(x: -1, y: 768, width: 370, height: 52)] {
    precondition(!actual.contains(clipped))
}
print("Covered-control owner preserved; keyboard, navigation, bottom and horizontal clipping rejected.")
