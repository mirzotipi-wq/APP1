import Foundation
import XCTest

final class StudioViewportGeometryTests: XCTestCase {
    private typealias Node = StudioViewportGeometry.Node
    private let screen = CGRect(x: 0, y: 0, width: 390, height: 844)

    func testNavigationAndNestedScrollSurfacesAllBoundTheTarget() throws {
        let nodes = fixture() + [
            Node(kind: .scrollView, identifier: "nested", frame: CGRect(x: 20, y: 180, width: 350, height: 400), parent: 3),
            Node(kind: .button, identifier: "target", frame: CGRect(x: 30, y: 200, width: 100, height: 44), parent: 4)
        ]
        let observed = try StudioViewportGeometry(nodes: nodes).viewport(target: 5, hittableFixedControls: [])
        XCTAssertEqual(observed, CGRect(x: 20, y: 180, width: 350, height: 400))
    }

    func testKeyboardAndAssistantStripExcludeCoveredControls() throws {
        let nodes = fixture() + [
            Node(kind: .button, identifier: "target", frame: CGRect(x: 20, y: 480, width: 100, height: 44), parent: 3),
            Node(kind: .keyboard, identifier: "", frame: CGRect(x: 0, y: 550, width: 390, height: 294), parent: 0),
            Node(kind: .other, identifier: "SystemInputAssistantView", frame: CGRect(x: 0, y: 500, width: 390, height: 50), parent: 0)
        ]
        let observed = try StudioViewportGeometry(nodes: nodes).viewport(target: 4, hittableFixedControls: [])
        XCTAssertEqual(observed.maxY, 500)
        XCTAssertFalse(observed.contains(nodes[4].frame))
    }

    func testCoveredProjectsNavigationAndDoneDoNotObscureNamingSheet() throws {
        let nodes = fixture() + [
            Node(kind: .button, identifier: "projectLibraryDone", frame: CGRect(x: 10, y: 500, width: 370, height: 60), parent: 1),
            Node(kind: .other, identifier: "naming", frame: screen, parent: 0),
            Node(kind: .navigationBar, identifier: "New project", frame: CGRect(x: 0, y: 0, width: 390, height: 80), parent: 5),
            Node(kind: .collectionView, identifier: "nameForm", frame: CGRect(x: 0, y: 80, width: 390, height: 700), parent: 5),
            Node(kind: .button, identifier: "target", frame: CGRect(x: 20, y: 600, width: 100, height: 44), parent: 7)
        ]
        let observed = try StudioViewportGeometry(nodes: nodes).viewport(target: 8, hittableFixedControls: [4])
        XCTAssertEqual(observed, CGRect(x: 0, y: 80, width: 390, height: 700))
        XCTAssertTrue(observed.contains(nodes[8].frame))
    }

    func testOnlyHittableFixedControlsInTheSameNavigationOwnerTrimContent() throws {
        let nodes = fixture() + [
            Node(kind: .button, identifier: "target", frame: CGRect(x: 20, y: 600, width: 100, height: 44), parent: 3),
            Node(kind: .button, identifier: "undo", frame: CGRect(x: 0, y: 650, width: 390, height: 60), parent: 1)
        ]
        let geometry = try StudioViewportGeometry(nodes: nodes)
        XCTAssertEqual(try geometry.viewport(target: 4, hittableFixedControls: [5]).maxY, 650)
        XCTAssertEqual(try geometry.viewport(target: 4, hittableFixedControls: []).maxY, 800)
    }

    func testMissingScrollAndInvalidTreeFailClosed() throws {
        let noScroll = [Node(kind: .application, identifier: "", frame: screen, parent: nil),
                        Node(kind: .button, identifier: "target", frame: screen, parent: 0)]
        XCTAssertThrowsError(try StudioViewportGeometry(nodes: noScroll).viewport(target: 1, hittableFixedControls: []))
        let cycle = [Node(kind: .application, identifier: "", frame: screen, parent: nil),
                     Node(kind: .other, identifier: "", frame: screen, parent: 1)]
        XCTAssertThrowsError(try StudioViewportGeometry(nodes: cycle))
        XCTAssertThrowsError(try StudioViewportGeometry(nodes: []))
    }

    func testOverlappingLiveControlWithUnknownOwnerFailsClosed() throws {
        let nodes = [
            Node(kind: .application, identifier: "app", frame: screen, parent: nil),
            Node(kind: .other, identifier: "owner", frame: screen, parent: 0),
            Node(kind: .scrollView, identifier: "content", frame: screen, parent: 1),
            Node(kind: .button, identifier: "target", frame: CGRect(x: 20, y: 600, width: 100, height: 44), parent: 2),
            Node(kind: .button, identifier: "undo", frame: CGRect(x: 0, y: 600, width: 390, height: 60), parent: 1)
        ]
        XCTAssertThrowsError(try StudioViewportGeometry(nodes: nodes).viewport(target: 3, hittableFixedControls: [4])) {
            XCTAssertEqual($0 as? StudioViewportGeometry.Failure, .missingNavigationOwner)
        }
    }

    func testNonfiniteObstacleCannotBeDroppedFromTheViewport() throws {
        let nodes = fixture() + [
            Node(kind: .button, identifier: "target", frame: CGRect(x: 20, y: 200, width: 100, height: 44), parent: 3),
            Node(kind: .keyboard, identifier: "", frame: .infinite, parent: 0)
        ]
        XCTAssertThrowsError(try StudioViewportGeometry(nodes: nodes).viewport(target: 4, hittableFixedControls: []))
    }

    func testMissingLazyTargetSearchStillAvoidsKeyboard() throws {
        let nodes = fixture() + [Node(kind: .keyboard, identifier: "", frame: CGRect(x: 0, y: 500, width: 390, height: 344), parent: 0)]
        XCTAssertEqual(try StudioViewportGeometry(nodes: nodes).searchViewport(), CGRect(x: 0, y: 0, width: 390, height: 500))
    }

    private func fixture() -> [Node] {
        [Node(kind: .application, identifier: "app", frame: screen, parent: nil),
         Node(kind: .other, identifier: "owner", frame: screen, parent: 0),
         Node(kind: .navigationBar, identifier: "Projects", frame: CGRect(x: 0, y: 0, width: 390, height: 120), parent: 1),
         Node(kind: .scrollView, identifier: "content", frame: CGRect(x: 0, y: 100, width: 390, height: 700), parent: 1)]
    }
}
