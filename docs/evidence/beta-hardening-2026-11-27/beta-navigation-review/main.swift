import Foundation

typealias Node = StudioViewportGeometry.Node
let screen = CGRect(x: 0, y: 0, width: 402, height: 874)
var assertions = 0
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    assertions += 1
    guard condition() else { fatalError(message) }
}
func base() -> [Node] {
    [Node(kind: .application, identifier: "app", frame: screen, parent: nil),
     Node(kind: .other, identifier: "feedbackOwner", frame: screen, parent: 0),
     Node(kind: .navigationBar, identifier: "Beta feedback", frame: CGRect(x: 0, y: 78, width: 402, height: 54), parent: 1),
     Node(kind: .collectionView, identifier: "feedbackForm", frame: CGRect(x: 0, y: 62, width: 402, height: 812), parent: 1)]
}
var nodes = base()
nodes.append(Node(kind: .button, identifier: "closeBetaFeedback", frame: CGRect(x: 20, y: 160, width: 150, height: 80), parent: 3))
let plain = try StudioViewportGeometry(nodes: nodes).viewport(target: 4, hittableFixedControls: [])
require(plain == CGRect(x: 0, y: 132, width: 402, height: 742), "Owning navigation must trim form")
require(plain.contains(nodes[4].frame), "Form Close must remain fully containable")
nodes.append(Node(kind: .keyboard, identifier: "", frame: CGRect(x: 0, y: 550, width: 402, height: 324), parent: 0))
nodes.append(Node(kind: .other, identifier: "SystemInputAssistantView", frame: CGRect(x: 0, y: 505, width: 402, height: 45), parent: 0))
let keyboardGeometry = try StudioViewportGeometry(nodes: nodes)
let keyboard = try keyboardGeometry.viewport(target: 4, hittableFixedControls: [])
require(keyboard.maxY == 505, "Assistant strip must trim before keyboard")
require(keyboard.contains(nodes[4].frame), "Form Close remains above keyboard")
require(!keyboard.contains(CGRect(x: 20, y: 480, width: 150, height: 80)), "Partially keyboard-covered controls must fail")
require(!keyboard.contains(CGRect(x: -1, y: 160, width: 150, height: 80)), "Horizontal clipping must fail")
let search = try keyboardGeometry.searchViewport()
require(search.maxY == 505, "Lazy target search remains above keyboard")
var navigation = base()
navigation.append(Node(kind: .button, identifier: "Back", frame: CGRect(x: 16, y: 85, width: 44, height: 44), parent: 2))
do {
    _ = try StudioViewportGeometry(nodes: navigation).viewport(target: 4, hittableFixedControls: [])
    fatalError("Navigation Back must not be accepted as scroll content")
} catch StudioViewportGeometry.Failure.missingScrollContainer { assertions += 1 }
require(screen.contains(navigation[4].frame), "Fixed Back is in application bounds")
var recovery = base()
recovery.append(Node(kind: .button, identifier: "closeLibraryRecovery", frame: CGRect(x: 16, y: 790, width: 370, height: 60), parent: 1))
do {
    _ = try StudioViewportGeometry(nodes: recovery).viewport(target: 4, hittableFixedControls: [])
    fatalError("Fixed Done must not be accepted as scroll content")
} catch StudioViewportGeometry.Failure.missingScrollContainer { assertions += 1 }
require(screen.contains(recovery[4].frame), "Fixed Done remains within application")
var presented = base()
presented.append(Node(kind: .button, identifier: "undo", frame: CGRect(x: 0, y: 500, width: 402, height: 80), parent: 1))
presented.append(Node(kind: .other, identifier: "presentedOwner", frame: screen, parent: 0))
presented.append(Node(kind: .navigationBar, identifier: "Review report", frame: CGRect(x: 0, y: 78, width: 402, height: 54), parent: 5))
presented.append(Node(kind: .scrollView, identifier: "report", frame: CGRect(x: 0, y: 132, width: 402, height: 742), parent: 5))
presented.append(Node(kind: .button, identifier: "shareBetaFeedbackReport", frame: CGRect(x: 20, y: 600, width: 350, height: 60), parent: 7))
let foreground = try StudioViewportGeometry(nodes: presented).viewport(target: 8, hittableFixedControls: [4])
require(foreground.maxY == 874, "Covered previous-owner undo must not trim presented report")
require(foreground.contains(presented[8].frame), "Foreground share remains fully visible")
// Synthetic boundary only: no actual recovery AX frame was captured here.
var footerBoundary = base()
footerBoundary.append(Node(kind: .button, identifier: "reviewLibraryRecovery", frame: CGRect(x: 20, y: 775, width: 350, height: 70), parent: 3))
footerBoundary.append(Node(kind: .button, identifier: "closeLibraryRecovery", frame: CGRect(x: 16, y: 790, width: 370, height: 60), parent: 1))
let untrimmed = try StudioViewportGeometry(nodes: footerBoundary).viewport(target: 4, hittableFixedControls: [])
require(untrimmed.contains(footerBoundary[4].frame), "Synthetic boundary must demonstrate helper has no implicit recovery-footer knowledge")
require(footerBoundary[4].frame.intersects(footerBoundary[5].frame), "Synthetic source includes hypothetical overlapping footer")
print("PASS \(assertions) pure geometry assertions; synthetic fixtures, not native snapshots")
print("Unverified recovery boundary: actual Form frame/safe-area inset and live hittability must be observed before alleging a defect.")
