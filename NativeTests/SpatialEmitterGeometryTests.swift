import SceneKit
import XCTest
import LightingCore
@testable import KeyAndFill

@MainActor
final class SpatialEmitterGeometryTests: XCTestCase {
    private func render(_ scene: LightingScene, cameraMode: Bool = false, selected: UUID? = nil)
        -> (view: SCNView, coordinator: SpatialPreview.Coordinator) {
        let preview = SpatialPreview(scene: scene, cameraMode: cameraMode, selected: selected)
        let coordinator = preview.makeCoordinator()
        let view = preview.makeView(coordinator: coordinator)
        view.frame = CGRect(x: 0, y: 0, width: 360, height: 240)
        preview.updateView(view, coordinator: coordinator)
        SCNTransaction.flush()
        return (view, coordinator)
    }

    private func fixture(for light: StudioLight, in coordinator: SpatialPreview.Coordinator) throws -> SCNNode {
        let optics = light.effectiveOptics
        let candidates = coordinator.content.childNodes.filter { node in
            if optics.kind == .point {
                return (node.geometry as? SCNSphere).map { abs(Double($0.radius) - 0.09) < 1e-6 } ?? false
            }
            guard let box = node.geometry as? SCNBox else { return false }
            let width = optics.kind == .rectangle ? optics.widthMeters : 0.22
            let height = optics.kind == .rectangle ? optics.heightMeters : 0.18
            return abs(Double(box.width) - width) < 1e-6 && abs(Double(box.height) - height) < 1e-6
        }
        XCTAssertEqual(candidates.count, 1)
        return try XCTUnwrap(candidates.first)
    }

    private func assertPosition(_ actual: SCNVector3, _ expected: Position,
                                file: StaticString = #filePath, line: UInt = #line) {
        // SceneKit stores transforms as Float32, including translated rigs.
        XCTAssertEqual(Double(actual.x), expected.x, accuracy: 2e-5, file: file, line: line)
        XCTAssertEqual(Double(actual.y), expected.y, accuracy: 2e-5, file: file, line: line)
        XCTAssertEqual(Double(actual.z), expected.z, accuracy: 2e-5, file: file, line: line)
    }

    private func assertDirection(_ actual: SCNVector3, _ expected: UnitDirection,
                                 file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(Double(actual.x), expected.x, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(Double(actual.y), expected.y, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(Double(actual.z), expected.z, accuracy: 1e-6, file: file, line: line)
    }

    func testRectangularFrontPlaneAndRollMatchAuthoredFrameInBothPreviewModes() throws {
        let position = Position(x: 80, y: 2.1, z: 75)
        let aims: [(Position, Double)] = [
            (.init(x: 78, y: 1.5, z: 72), 37.5),
            (.init(x: 80, y: 5, z: 75), 90),
            (.init(x: 80, y: 0, z: 75), -125)
        ]
        for (target, roll) in aims {
            for cameraMode in [false, true] {
                let light = StudioLight(name: "Rectangle", position: position, candela: 900, kelvin: 5600,
                                        optics: .init(kind: .rectangle, aimTarget: target,
                                                      widthMeters: 1.2, heightMeters: 0.7, rollDegrees: roll))
                var scene = LightingScene.portrait(); scene.lights = [light]
                let rendered = render(scene, cameraMode: cameraMode)
                defer { SpatialPreview.dismantleUIView(rendered.view, coordinator: rendered.coordinator) }
                let node = try fixture(for: light, in: rendered.coordinator)
                let box = try XCTUnwrap(node.geometry as? SCNBox)
                let frame = try XCTUnwrap(StudioPhotometry.frame(for: light, subject: scene.subject))
                XCTAssertEqual(Double(box.width), 1.2, accuracy: 1e-6)
                XCTAssertEqual(Double(box.height), 0.7, accuracy: 1e-6)
                assertPosition(node.convertPosition(SCNVector3(0, 0, Float(box.length) / 2), to: nil), position)
                assertDirection(node.convertVector(SCNVector3(1, 0, 0), to: nil), frame.right)
                assertDirection(node.convertVector(SCNVector3(0, 1, 0), to: nil), frame.up)
                assertDirection(node.convertVector(SCNVector3(0, 0, 1), to: nil), frame.normal)

                let source = try XCTUnwrap(rendered.coordinator.content.childNodes.first { $0.light?.type == .spot })
                assertPosition(source.worldPosition, position)
                assertDirection(source.convertVector(SCNVector3(0, 0, -1), to: nil), frame.normal)
            }
        }
    }

    func testDirectionalHousingFrontUsesAuthoredPlaneEvenWhenPoweredOff() throws {
        let light = StudioLight(name: "Directional", position: .init(x: -2, y: 2.5, z: 1), candela: 0, kelvin: 3200,
                                optics: .init(kind: .directional, rollDegrees: 45))
        var scene = LightingScene.portrait(); scene.lights = [light]
        let rendered = render(scene)
        defer { SpatialPreview.dismantleUIView(rendered.view, coordinator: rendered.coordinator) }
        let node = try fixture(for: light, in: rendered.coordinator)
        let box = try XCTUnwrap(node.geometry as? SCNBox)
        assertPosition(node.convertPosition(SCNVector3(0, 0, Float(box.length) / 2), to: nil), light.position)
        let source = try XCTUnwrap(rendered.coordinator.content.childNodes.first { $0.light?.type == .spot })
        assertPosition(source.worldPosition, light.position)
        XCTAssertEqual(source.light?.intensity, 0)
    }

    func testBarePointAndOmnidirectionalSourceKeepAuthoredCenter() throws {
        let position = Position(x: 2, y: 1.8, z: 3)
        let light = StudioLight(name: "Point", position: position, candela: 300, kelvin: 5600,
                                optics: .init(kind: .point, aimTarget: position, rollDegrees: 90))
        var scene = LightingScene.portrait(); scene.lights = [light]
        let rendered = render(scene)
        defer { SpatialPreview.dismantleUIView(rendered.view, coordinator: rendered.coordinator) }
        let node = try fixture(for: light, in: rendered.coordinator)
        XCTAssertNotNil(node.geometry as? SCNSphere)
        assertPosition(node.worldPosition, position)
        let source = try XCTUnwrap(rendered.coordinator.content.childNodes.first { $0.light?.type == .omni })
        assertPosition(source.worldPosition, position)
        XCTAssertFalse(rendered.coordinator.content.childNodes.contains { $0.light?.type == .spot })
        XCTAssertEqual(rendered.coordinator.lightIDs[ObjectIdentifier(node)], light.id)
    }

    func testOffsetHousingPreservesFixtureStandAndSelectionIdentity() throws {
        let light = StudioLight(name: "Rectangle", position: .init(x: -1.5, y: 2.1, z: 1.2), candela: 900, kelvin: 5600,
                                optics: .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.7, rollDegrees: 63))
        var scene = LightingScene.portrait(); scene.lights = [light]
        let rendered = render(scene, selected: light.id)
        defer { SpatialPreview.dismantleUIView(rendered.view, coordinator: rendered.coordinator) }
        let node = try fixture(for: light, in: rendered.coordinator)
        let indicator = try XCTUnwrap(rendered.coordinator.selectionIndicators[light.id])
        XCTAssertEqual(rendered.coordinator.lightIDs[ObjectIdentifier(node)], light.id)
        XCTAssertTrue(indicator.parent === node, "Outline hits must still resolve through the registered fixture ancestor")
        XCTAssertFalse(indicator.isHidden)
        let stand = try XCTUnwrap(rendered.coordinator.content.childNodes.first { $0.geometry is SCNCylinder })
        XCTAssertEqual(rendered.coordinator.lightIDs[ObjectIdentifier(stand)], light.id)
        assertPosition(stand.worldPosition, .init(x: light.position.x, y: light.position.y / 2, z: light.position.z))

        SpatialPreview(scene: scene, selected: nil).updateView(rendered.view, coordinator: rendered.coordinator)
        XCTAssertTrue(indicator.isHidden)
        XCTAssertTrue(try fixture(for: light, in: rendered.coordinator) === node,
                      "Selection-only updates must preserve geometry and its hit-test identity")
        SpatialPreview(scene: scene, selected: light.id).updateView(rendered.view, coordinator: rendered.coordinator)
        XCTAssertFalse(indicator.isHidden)
    }

    func testDegenerateAimKeepsSelectableMarkerWithoutInventingEmitterDirection() throws {
        let position = Position(x: 1, y: 2, z: 3)
        let light = StudioLight(name: "Degenerate", position: position, candela: 900, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: position, widthMeters: 1.2, heightMeters: 0.7))
        var scene = LightingScene.portrait(); scene.lights = [light]
        let rendered = render(scene, selected: light.id)
        defer { SpatialPreview.dismantleUIView(rendered.view, coordinator: rendered.coordinator) }
        let node = try fixture(for: light, in: rendered.coordinator)
        assertPosition(node.worldPosition, position)
        XCTAssertFalse(rendered.coordinator.content.childNodes.contains { $0.light?.type == .spot || $0.light?.type == .omni })
        XCTAssertEqual(rendered.coordinator.lightIDs[ObjectIdentifier(node)], light.id)
        XCTAssertFalse(try XCTUnwrap(rendered.coordinator.selectionIndicators[light.id]).isHidden)
    }
}
