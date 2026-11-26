import SceneKit
import XCTest
import LightingCore
@testable import KeyAndFill

@MainActor
final class SpatialInteractionTests: XCTestCase {
    private func render(_ scene: LightingScene, cameraMode: Bool = false, selected: UUID? = nil)
        -> (SCNView, SpatialPreview.Coordinator) {
        let preview = SpatialPreview(scene: scene, cameraMode: cameraMode, selected: selected)
        let coordinator = preview.makeCoordinator()
        let view = preview.makeView(coordinator: coordinator)
        view.frame = CGRect(x: 0, y: 0, width: 360, height: 280)
        preview.updateView(view, coordinator: coordinator)
        SCNTransaction.flush()
        return (view, coordinator)
    }

    func testMetadataOutputAndSelectionKeepLiveNodesAndRefreshCallback() throws {
        var scene = LightingScene.portrait()
        let id = scene.lights[0].id
        let (view, coordinator) = render(scene, selected: id)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        let nodes = coordinator.content.childNodes.map(ObjectIdentifier.init)
        let indicator = try XCTUnwrap(coordinator.selectionIndicators[id])
        let fixture = try XCTUnwrap(indicator.parent)
        let geometry = try XCTUnwrap(fixture.geometry)
        let camera = try XCTUnwrap(view.pointOfView)
        camera.position = SCNVector3(7, 5, 9)
        view.defaultCameraController.target = SCNVector3(1, 2, 3)
        var first = 0, second = 0
        SpatialPreview(scene: scene, selected: id, onSelect: { _ in first += 1 }).updateView(view, coordinator: coordinator)
        scene.lights[0].name = "Renamed"
        scene.lights[0].candela = 0
        scene.lights[1].kelvin = 3200
        SpatialPreview(scene: scene, selected: id, onSelect: { _ in second += 1 }).updateView(view, coordinator: coordinator)
        XCTAssertEqual(coordinator.content.childNodes.map(ObjectIdentifier.init), nodes)
        XCTAssertTrue(fixture.geometry === geometry)
        XCTAssertTrue(coordinator.selectionIndicators[id] === indicator)
        XCTAssertFalse(indicator.isHidden)
        XCTAssertTrue(view.pointOfView === camera)
        XCTAssertEqual(camera.position.x, 7)
        XCTAssertEqual(view.defaultCameraController.target.z, 3)
        XCTAssertEqual(coordinator.lightID(for: fixture), id)
        coordinator.onSelect?(id)
        XCTAssertEqual(first, 0)
        XCTAssertEqual(second, 1)
    }

    func testRemovedAndReintroducedUUIDCannotReuseOldHitObject() throws {
        var scene = LightingScene.portrait()
        let light = scene.lights.removeFirst()
        var original = scene; original.lights.insert(light, at: 0)
        let (view, coordinator) = render(original, selected: light.id)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        let old = try XCTUnwrap(coordinator.selectionIndicators[light.id]?.parent)
        SpatialPreview(scene: scene).updateView(view, coordinator: coordinator)
        XCTAssertNil(coordinator.lightID(for: old))
        XCTAssertNil(old.parent)
        SpatialPreview(scene: original, selected: light.id).updateView(view, coordinator: coordinator)
        let replacement = try XCTUnwrap(coordinator.selectionIndicators[light.id]?.parent)
        XCTAssertFalse(replacement === old)
        XCTAssertNil(coordinator.lightID(for: old))
        XCTAssertEqual(coordinator.lightID(for: replacement), light.id)
    }

    func testInvalidSceneDiscardsHitIdentitiesAndRecoversWithoutOldGeometry() throws {
        let scene = LightingScene.portrait()
        let id = scene.lights[0].id
        let (view, coordinator) = render(scene, selected: id)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        let old = try XCTUnwrap(coordinator.selectionIndicators[id]?.parent)
        var invalid = scene; invalid.lights.append(invalid.lights[0])
        SpatialPreview(scene: invalid, selected: id).updateView(view, coordinator: coordinator)
        XCTAssertTrue(coordinator.content.isHidden)
        XCTAssertTrue(coordinator.lightIDs.isEmpty)
        XCTAssertFalse(view.isUserInteractionEnabled)
        XCTAssertNil(coordinator.lightID(for: old))
        XCTAssertNil(old.parent)
        SpatialPreview(scene: scene, selected: id).updateView(view, coordinator: coordinator)
        XCTAssertFalse(coordinator.content.isHidden)
        let replacement = try XCTUnwrap(coordinator.selectionIndicators[id]?.parent)
        XCTAssertFalse(replacement === old)
        XCTAssertNil(coordinator.lightID(for: old))
        XCTAssertEqual(coordinator.lightID(for: replacement), id)
    }

    func testDisablingAndDismantlingRejectsSelectionAndReleasesGeometry() throws {
        let scene = LightingScene.portrait()
        let id = scene.lights[0].id
        let (view, coordinator) = render(scene, selected: id)
        let old = try XCTUnwrap(coordinator.selectionIndicators[id]?.parent)
        coordinator.setInteractionEnabled(false)
        XCTAssertFalse(view.isUserInteractionEnabled)
        XCTAssertFalse(coordinator.gestureRecognizerShouldBegin(UITapGestureRecognizer()))
        coordinator.setInteractionEnabled(true)
        XCTAssertTrue(view.isUserInteractionEnabled)
        SpatialPreview.dismantleUIView(view, coordinator: coordinator)
        XCTAssertNil(view.scene)
        XCTAssertNil(view.pointOfView)
        XCTAssertNil(coordinator.onSelect)
        XCTAssertTrue(coordinator.content.childNodes.isEmpty)
        XCTAssertTrue(coordinator.lightIDs.isEmpty)
        XCTAssertNil(coordinator.lightID(for: old))
    }

    func testUndefinedCameraHidesPriorViewAndRecoversAuthoredLens() throws {
        var scene = LightingScene.portrait()
        let (view, coordinator) = render(scene, cameraMode: true)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        scene.camera = scene.subject
        SpatialPreview(scene: scene, cameraMode: true).updateView(view, coordinator: coordinator)
        XCTAssertNil(view.pointOfView)
        XCTAssertTrue(coordinator.content.isHidden)
        XCTAssertFalse(view.allowsCameraControl)
        scene.camera = .init(x: 0, y: 4, z: 0)
        scene.cameraLens = .init(focalLengthMillimeters: 85)
        SpatialPreview(scene: scene, cameraMode: true).updateView(view, coordinator: coordinator)
        XCTAssertTrue(view.pointOfView === coordinator.camera)
        XCTAssertFalse(coordinator.content.isHidden)
        let framing = try XCTUnwrap(CameraFraming(scene: scene))
        XCTAssertEqual(Double(coordinator.camera.camera?.fieldOfView ?? 0), framing.verticalFieldOfViewDegrees,
                       accuracy: Double(Float(framing.verticalFieldOfViewDegrees).ulp))
        let forward = coordinator.camera.convertVector(SCNVector3(0, 0, -1), to: nil)
        XCTAssertEqual(Double(forward.y), framing.forward.y, accuracy: 1e-6)
    }

    func testCameraBodyAndLensFollowTheAuthoredNegativeZConvention() throws {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 4, z: 0)
        let (view, coordinator) = render(scene)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        let body = try XCTUnwrap(coordinator.content.childNode(withName: "Authored camera", recursively: false))
        let lens = try XCTUnwrap(body.childNodes.first)
        let framing = try XCTUnwrap(CameraFraming(scene: scene))
        let forward = body.convertVector(SCNVector3(0, 0, -1), to: nil)
        XCTAssertEqual(Double(forward.x), framing.forward.x, accuracy: 1e-6)
        XCTAssertEqual(Double(forward.y), framing.forward.y, accuracy: 1e-6)
        XCTAssertEqual(Double(forward.z), framing.forward.z, accuracy: 1e-6)
        XCTAssertEqual(Double(lens.worldPosition.y), scene.camera.y + framing.forward.y * 0.12, accuracy: 1e-6)
    }

    func testRepeatedUpdatesKeepBoundedNodeCountAndLiveFixtureIdentity() throws {
        var scene = LightingScene.portrait()
        let id = scene.lights[0].id
        let (view, coordinator) = render(scene, selected: id)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        let original = try XCTUnwrap(coordinator.selectionIndicators[id]?.parent)
        let count = coordinator.content.childNodes.count
        for index in 0..<100 {
            scene.lights[0].name = "Key \(index)"
            scene.lights[0].candela = Double(index) * 5
            scene.lights[0].position.x = sin(Double(index))
            scene.lights.reverse()
            SpatialPreview(scene: scene, selected: id).updateView(view, coordinator: coordinator)
            XCTAssertEqual(coordinator.content.childNodes.count, count)
            XCTAssertTrue(coordinator.selectionIndicators[id]?.parent === original)
            XCTAssertEqual(coordinator.lightID(for: original), id)
        }
    }

    func testCoincidentSoftboxAndHighStandFitActualNarrowProjection() throws {
        let light = StudioLight(name: "Coincident softbox", position: .init(x: 0, y: 20, z: 0),
                                candela: 900, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 20, z: 0),
                                              widthMeters: 4, heightMeters: 4))
        let scene = LightingScene(subject: .init(x: 0, y: 20, z: -0.1),
                                  camera: .init(x: 0, y: 20, z: 0.1), lights: [light])
        let (view, coordinator) = render(scene, selected: light.id)
        defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
        let fixture = try XCTUnwrap(coordinator.selectionIndicators[light.id]?.parent)
        for size in [CGSize(width: 120, height: 600), CGSize(width: 600, height: 120)] {
            view.frame = CGRect(origin: .zero, size: size)
            SpatialPreview(scene: scene, fitRequest: 1, selected: light.id).updateView(view, coordinator: coordinator)
            view.setNeedsLayout(); view.layoutIfNeeded(); SCNTransaction.flush()
            var points = [SCNVector3(0, 0, 0)]
            for x in [Float(-2.02), Float(2.02)] {
                for y in [Float(-2.02), Float(2.02)] {
                    points.append(fixture.convertPosition(SCNVector3(x, y, 0.03), to: nil))
                }
            }
            for point in points {
                let projected = view.projectPoint(point)
                XCTAssertGreaterThan(projected.x, 0)
                XCTAssertLessThan(projected.x, Float(size.width))
                XCTAssertGreaterThan(projected.y, 0)
                XCTAssertLessThan(projected.y, Float(size.height))
                XCTAssertGreaterThan(projected.z, 0)
                XCTAssertLessThan(projected.z, 1)
            }
        }
    }

    func testCaptureRealSceneKitOrdinaryAndCrowdedViewports() throws {
        var crowded = LightingScene.portrait()
        crowded.lights = (0..<12).map { index in
            let angle = Double(index) * .pi / 6
            return StudioLight(name: "Fixture \(index)", position: .init(x: cos(angle) * 3, y: 1.7, z: sin(angle) * 3),
                               candela: 900, kelvin: 5600,
                               optics: .init(kind: .rectangle, widthMeters: 0.8, heightMeters: 1.2,
                                             rollDegrees: Double(index) * 15))
        }
        for (name, scene) in [("ordinary", LightingScene.portrait()), ("crowded", crowded)] {
            let (view, coordinator) = render(scene, selected: scene.lights.first?.id)
            defer { SpatialPreview.dismantleUIView(view, coordinator: coordinator) }
            let controller = UIViewController()
            controller.view = UIView(frame: view.frame)
            controller.view.addSubview(view)
            let window = UIWindow(frame: view.frame)
            window.rootViewController = controller
            window.makeKeyAndVisible()
            view.setNeedsLayout(); view.layoutIfNeeded(); SCNTransaction.flush()
            let image = view.snapshot()
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
            let attachment = XCTAttachment(image: image)
            attachment.name = "spatial05-\(name)-SceneKit"
            attachment.lifetime = .keepAlways
            add(attachment)
            window.isHidden = true
            window.rootViewController = nil
        }
    }
}
