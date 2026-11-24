import SceneKit
import XCTest
import LightingCore
@testable import KeyAndFill

@MainActor
final class SpatialPreviewTests: XCTestCase {
    private func translated(_ scene: LightingScene, x: Double, z: Double) -> LightingScene {
        var result = scene
        func move(_ p: Position) -> Position { .init(x: p.x + x, y: p.y, z: p.z + z) }
        result.subject = move(scene.subject)
        result.camera = move(scene.camera)
        for index in result.lights.indices {
            result.lights[index].position = move(scene.lights[index].position)
            if let target = scene.lights[index].optics?.aimTarget {
                result.lights[index].optics?.aimTarget = move(target)
            }
        }
        return result
    }

    func testTranslatedRigAndModifierFitActualSceneKitProjection() throws {
        var base = LightingScene.portrait()
        base.lights[0].optics = .init(kind: .rectangle, widthMeters: 4, heightMeters: 3)
        let scene = translated(base, x: 80, z: 75)
        let bounds = try StudioSceneBounds(scene: scene)
        let preview = SpatialPreview(scene: scene)
        let coordinator = preview.makeCoordinator()
        let view = preview.makeView(coordinator: coordinator)
        for size in [CGSize(width: 360, height: 280), CGSize(width: 240, height: 400)] {
            view.frame = CGRect(origin: .zero, size: size)
            preview.updateView(view, coordinator: coordinator)
            view.setNeedsLayout()
            view.layoutIfNeeded()
            let target = view.defaultCameraController.target
            XCTAssertEqual(Double(target.x), bounds.center.x, accuracy: 1e-5)
            XCTAssertEqual(Double(target.y), bounds.center.y, accuracy: 1e-5)
            XCTAssertEqual(Double(target.z), bounds.center.z, accuracy: 1e-5)
            for x in [bounds.minimum.x, bounds.maximum.x] {
                for y in [bounds.minimum.y, bounds.maximum.y] {
                    for z in [bounds.minimum.z, bounds.maximum.z] {
                        let point = view.projectPoint(SCNVector3(Float(x), Float(y), Float(z)))
                        XCTAssertTrue(point.x.isFinite && point.y.isFinite && point.z.isFinite)
                        XCTAssertGreaterThan(point.x, 0)
                        XCTAssertLessThan(point.x, Float(size.width))
                        XCTAssertGreaterThan(point.y, 0)
                        XCTAssertLessThan(point.y, Float(size.height))
                        XCTAssertGreaterThan(point.z, 0)
                        XCTAssertLessThan(point.z, 1)
                    }
                }
            }
        }
    }

    func testOrdinarySceneEditPreservesOrbitButExplicitFitRestoresCamera() throws {
        let scene = translated(.portrait(), x: 80, z: 75)
        let preview = SpatialPreview(scene: scene)
        let coordinator = preview.makeCoordinator()
        let view = preview.makeView(coordinator: coordinator)
        view.frame = CGRect(x: 0, y: 0, width: 360, height: 280)
        preview.updateView(view, coordinator: coordinator)
        let userCamera = SCNNode()
        userCamera.camera = SCNCamera()
        userCamera.position = SCNVector3(82, 4, 83)
        view.scene?.rootNode.addChildNode(userCamera)
        view.pointOfView = userCamera
        let userTarget = SCNVector3(80.5, 1.8, 76)
        view.defaultCameraController.target = userTarget

        var edited = scene
        edited.lights[0].candela = 1234
        SpatialPreview(scene: edited).updateView(view, coordinator: coordinator)
        XCTAssertTrue(view.pointOfView === userCamera)
        XCTAssertEqual(userCamera.position.x, 82)
        XCTAssertEqual(userCamera.position.y, 4)
        XCTAssertEqual(userCamera.position.z, 83)
        XCTAssertEqual(view.defaultCameraController.target.x, userTarget.x)
        XCTAssertEqual(view.defaultCameraController.target.z, userTarget.z)

        SpatialPreview(scene: edited, fitRequest: 1).updateView(view, coordinator: coordinator)
        XCTAssertTrue(view.pointOfView === coordinator.camera)
        let bounds = try StudioSceneBounds(scene: edited)
        XCTAssertEqual(Double(view.defaultCameraController.target.x), bounds.center.x, accuracy: 1e-5)
        XCTAssertEqual(Double(view.defaultCameraController.target.z), bounds.center.z, accuracy: 1e-5)
        XCTAssertGreaterThan(coordinator.camera.camera?.zFar ?? 0, 0)
    }

    func testEmptyExtremeRigHasFiniteFitAndCameraModeRemainsPhysical() throws {
        let empty = LightingScene(subject: .init(x: 100, y: 100, z: 100),
                                  camera: .init(x: 100, y: 100, z: 100), lights: [])
        let preview = SpatialPreview(scene: empty)
        let coordinator = preview.makeCoordinator()
        let view = preview.makeView(coordinator: coordinator)
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 280)
        preview.updateView(view, coordinator: coordinator)
        let position = coordinator.camera.position
        XCTAssertTrue(position.x.isFinite && position.y.isFinite && position.z.isFinite)
        XCTAssertEqual(view.defaultCameraController.target.x, 100)

        let scene = translated(.portrait(), x: 80, z: 75)
        SpatialPreview(scene: scene, cameraMode: true).updateView(view, coordinator: coordinator)
        let framing = try XCTUnwrap(CameraFraming(scene: scene))
        XCTAssertFalse(view.allowsCameraControl)
        XCTAssertEqual(Double(coordinator.camera.position.x), scene.camera.x, accuracy: 1e-5)
        XCTAssertEqual(Double(coordinator.camera.position.z), scene.camera.z, accuracy: 1e-5)
        XCTAssertEqual(Double(coordinator.camera.camera?.fieldOfView ?? 0), framing.verticalFieldOfViewDegrees, accuracy: 1e-8)
        XCTAssertEqual(coordinator.camera.camera?.projectionDirection, .vertical)
    }
}
