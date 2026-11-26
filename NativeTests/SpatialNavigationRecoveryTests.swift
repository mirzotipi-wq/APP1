import SceneKit
import XCTest
import LightingCore
@testable import KeyAndFill

@MainActor
final class SpatialNavigationRecoveryTests: XCTestCase {
    private func render(_ scene: LightingScene) -> (SCNView, SpatialPreview.Coordinator) {
        let preview = SpatialPreview(scene: scene, fitRequest: 0)
        let coordinator = preview.makeCoordinator()
        let view = preview.makeView(coordinator: coordinator)
        view.frame = CGRect(x: 0, y: 0, width: 360, height: 280)
        update(scene, view: view, coordinator: coordinator)
        return (view, coordinator)
    }

    private func update(_ scene: LightingScene, cameraMode: Bool = false,
                        view: SCNView, coordinator: SpatialPreview.Coordinator) {
        SpatialPreview(scene: scene, cameraMode: cameraMode, fitRequest: 0)
            .updateView(view, coordinator: coordinator)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        SCNTransaction.flush()
    }

    private func invalidated(_ scene: LightingScene) -> LightingScene {
        var invalid = scene
        invalid.lights.append(invalid.lights[0])
        return invalid
    }

    private func assertPosition(_ actual: SCNVector3, _ expected: Position,
                                file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(Double(actual.x), expected.x, accuracy: 1e-5, file: file, line: line)
        XCTAssertEqual(Double(actual.y), expected.y, accuracy: 1e-5, file: file, line: line)
        XCTAssertEqual(Double(actual.z), expected.z, accuracy: 1e-5, file: file, line: line)
    }

    private func assertFittedOrbit(_ scene: LightingScene, view: SCNView,
                                   coordinator: SpatialPreview.Coordinator,
                                   file: StaticString = #filePath, line: UInt = #line) throws {
        var expected = SpatialOrbitState()
        expected.fit(try SpatialViewportBounds(scene: scene))
        XCTAssertFalse(coordinator.content.isHidden, file: file, line: line)
        XCTAssertTrue(view.isUserInteractionEnabled, file: file, line: line)
        XCTAssertTrue(view.allowsCameraControl, file: file, line: line)
        XCTAssertTrue(view.pointOfView === coordinator.camera, file: file, line: line)
        assertPosition(coordinator.camera.position, expected.position, file: file, line: line)
        assertPosition(view.defaultCameraController.target, expected.target, file: file, line: line)
        let camera = try XCTUnwrap(coordinator.camera.camera, file: file, line: line)
        XCTAssertEqual(camera.projectionDirection, .vertical, file: file, line: line)
        XCTAssertEqual(Double(camera.fieldOfView), 48, accuracy: Double(Float(48).ulp), file: file, line: line)
        XCTAssertEqual(camera.zNear, 0.02, accuracy: Double(Float(0.02).ulp), file: file, line: line)
        XCTAssertEqual(camera.zFar, expected.farDistance, accuracy: Double(Float(expected.farDistance).ulp),
                       file: file, line: line)
    }

    func testInvalidOrbitTransitionRecoversFromAuthoredCameraWithUnchangedFitRequest() throws {
        var scene = LightingScene.portrait()
        scene.cameraLens = .init(focalLengthMillimeters: 85)
        let (view, coordinator) = render(scene)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        XCTAssertEqual(coordinator.lastFitRequest, 0)

        update(scene, cameraMode: true, view: view, coordinator: coordinator)
        XCTAssertTrue(view.pointOfView === coordinator.camera)
        XCTAssertFalse(view.allowsCameraControl)
        assertPosition(coordinator.camera.position, scene.camera)
        let framing = try XCTUnwrap(CameraFraming(scene: scene))
        XCTAssertEqual(Double(try XCTUnwrap(coordinator.camera.camera).fieldOfView),
                       framing.verticalFieldOfViewDegrees,
                       accuracy: Double(Float(framing.verticalFieldOfViewDegrees).ulp))

        update(invalidated(scene), view: view, coordinator: coordinator)
        XCTAssertTrue(coordinator.content.isHidden)
        XCTAssertFalse(view.isUserInteractionEnabled)
        XCTAssertTrue(coordinator.lightIDs.isEmpty)

        update(scene, view: view, coordinator: coordinator)
        try assertFittedOrbit(scene, view: view, coordinator: coordinator)
    }

    func testInvalidOrbitTransitionRecoversFromUndefinedCameraWithUnchangedFitRequest() throws {
        var scene = LightingScene.portrait()
        scene.camera = scene.subject
        let (view, coordinator) = render(scene)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        XCTAssertEqual(coordinator.lastFitRequest, 0)

        update(scene, cameraMode: true, view: view, coordinator: coordinator)
        XCTAssertNil(view.pointOfView)
        XCTAssertTrue(coordinator.content.isHidden)

        update(invalidated(scene), view: view, coordinator: coordinator)
        XCTAssertTrue(coordinator.content.isHidden)
        XCTAssertFalse(view.isUserInteractionEnabled)

        update(scene, view: view, coordinator: coordinator)
        try assertFittedOrbit(scene, view: view, coordinator: coordinator)
    }

    func testInvalidOrbitScenePreservesUserCameraAndTargetWithoutFitRequest() throws {
        let scene = LightingScene.portrait()
        let (view, coordinator) = render(scene)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        let userCamera = SCNNode()
        userCamera.camera = SCNCamera()
        userCamera.position = SCNVector3(7, 5, 9)
        view.scene?.rootNode.addChildNode(userCamera)
        view.pointOfView = userCamera
        view.defaultCameraController.target = SCNVector3(1, 2, 3)
        SCNTransaction.flush()

        update(invalidated(scene), view: view, coordinator: coordinator)
        XCTAssertTrue(coordinator.content.isHidden)
        XCTAssertFalse(view.isUserInteractionEnabled)
        update(scene, view: view, coordinator: coordinator)

        XCTAssertFalse(coordinator.content.isHidden)
        XCTAssertTrue(view.isUserInteractionEnabled)
        XCTAssertTrue(view.allowsCameraControl)
        XCTAssertTrue(view.pointOfView === userCamera)
        assertPosition(userCamera.position, .init(x: 7, y: 5, z: 9))
        assertPosition(view.defaultCameraController.target, .init(x: 1, y: 2, z: 3))
    }

    func testInitialValidEmptyOrbitEnablesInteraction() throws {
        var scene = LightingScene.portrait()
        scene.lights = []
        let (view, coordinator) = render(scene)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        // No UUID cancellation or camera-control toggle should be needed to
        // publish the initial mode before interaction availability is derived.
        try assertFittedOrbit(scene, view: view, coordinator: coordinator)
        XCTAssertTrue(coordinator.lightIDs.isEmpty)
    }
}
