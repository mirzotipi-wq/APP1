import SwiftUI
import SceneKit
import LightingCore
import simd

/// Temporary illustrative renderer; SceneKit intensity and spotlight cones are
/// not calibrated candela or area-source shading. Emitter geometry uses world meters.
@MainActor
struct SpatialPreview: UIViewRepresentable {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isEnabled) private var isEnabled
    let scene: LightingScene
    let cameraMode: Bool
    let fitRequest: Int
    let selected: UUID?
    let onSelect: ((UUID) -> Void)?

    init(scene: LightingScene, cameraMode: Bool = false, fitRequest: Int = 0,
         selected: UUID? = nil, onSelect: ((UUID) -> Void)? = nil) {
        self.scene = scene
        self.cameraMode = cameraMode
        self.fitRequest = fitRequest
        self.selected = selected
        self.onSelect = onSelect
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let content = SCNNode()
        let camera = SCNNode()
        var lastScene: LightingScene?
        var lastCameraMode: Bool?
        var lastFitRequest: Int?
        var lastSelected: UUID?
        var lightIDs: [ObjectIdentifier: UUID] = [:]
        var selectionIndicators: [UUID: SCNNode] = [:]
        var onSelect: ((UUID) -> Void)?
        private weak var view: SCNView?
        private weak var selectionGesture: UITapGestureRecognizer?
        private var interactionEnabled = true

        func attach(to view: SCNView) {
            self.view = view
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectLight(_:)))
            tap.delegate = self
            // Retain SceneKit's native orbit, two-finger pan and pinch controls.
            // Selection must wait for a camera gesture (including double-tap).
            for gesture in view.gestureRecognizers ?? [] {
                if gesture is UIPanGestureRecognizer || gesture is UIPinchGestureRecognizer ||
                    gesture is UIRotationGestureRecognizer ||
                    (gesture as? UITapGestureRecognizer).map({ $0.numberOfTapsRequired > 1 }) == true {
                    tap.require(toFail: gesture)
                }
            }
            view.addGestureRecognizer(tap)
            selectionGesture = tap
        }

        func setInteractionEnabled(_ enabled: Bool) {
            interactionEnabled = enabled
            view?.isUserInteractionEnabled = enabled
            if !enabled { view?.defaultCameraController.stopInertia() }
        }

        func detach(from view: SCNView) {
            onSelect = nil
            interactionEnabled = false
            if let tap = selectionGesture {
                tap.delegate = nil
                tap.removeTarget(self, action: nil)
                view.removeGestureRecognizer(tap)
            }
            selectionGesture = nil
            view.defaultCameraController.stopInertia()
            view.allowsCameraControl = false
            view.isUserInteractionEnabled = false
            view.isPlaying = false
            view.pointOfView = nil
            view.scene = nil
            content.childNodes.forEach { $0.removeFromParentNode() }
            content.removeFromParentNode()
            camera.removeFromParentNode()
            lightIDs.removeAll()
            selectionIndicators.removeAll()
            lastScene = nil
            self.view = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            interactionEnabled && lastCameraMode == false && onSelect != nil &&
                view?.window != nil && !UIAccessibility.isVoiceOverRunning
        }

        @objc private func selectLight(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, gestureRecognizerShouldBegin(gesture),
                  let view, let hit = view.hitTest(gesture.location(in: view), options: nil).first else { return }
            var node: SCNNode? = hit.node
            while let current = node {
                if let id = lightIDs[ObjectIdentifier(current)],
                   lastScene?.lights.contains(where: { $0.id == id }) == true {
                    onSelect?(id)
                    return
                }
                node = current.parent
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        makeView(coordinator: context.coordinator)
    }

    /// Shared with native integration tests so the actual SceneKit projection
    /// and camera-controller state are exercised without a SwiftUI host.
    func makeView(coordinator: Coordinator) -> SCNView {
        let view = OrbitAwareSceneView(frame: .zero, options: nil)
        let world = SCNScene()
        world.background.contents = UIColor(red: 0.075, green: 0.085, blue: 0.10, alpha: 1)
        view.scene = world
        let camera = coordinator.camera
        camera.camera = SCNCamera(); camera.camera?.fieldOfView = 48
        world.rootNode.addChildNode(camera)
        world.rootNode.addChildNode(coordinator.content)
        view.pointOfView = camera
        view.allowsCameraControl = !cameraMode
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling2X
        coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        updateView(view, coordinator: context.coordinator)
        context.coordinator.setInteractionEnabled(isEnabled && scenePhase == .active)
    }

    static func dismantleUIView(_ view: SCNView, coordinator: Coordinator) {
        coordinator.detach(from: view)
    }

    func updateView(_ view: SCNView, coordinator: Coordinator) {
        // A project or command generation can change without changing geometry.
        // Never retain a selection callback from the previous SwiftUI update.
        coordinator.onSelect = cameraMode ? nil : onSelect
        let modeChanged = coordinator.lastCameraMode != cameraMode
        let sceneChanged = coordinator.lastScene != scene
        let selectionChanged = coordinator.lastSelected != selected
        let contentChanged = modeChanged || coordinator.lastScene?.subject != scene.subject ||
            coordinator.lastScene?.lights != scene.lights ||
            (!cameraMode && coordinator.lastScene?.camera != scene.camera)
        let needsFit = !cameraMode && (modeChanged || coordinator.lastFitRequest != fitRequest)
        guard sceneChanged || modeChanged || needsFit || selectionChanged else { return }
        // Publish geometry, camera pose, lens, clipping and controller target as
        // one nonanimated update. Do not inherit an enclosing UI animation's
        // duration or expose an intermediate camera configuration to rendering.
        // SceneKit presents this transaction at its normal run-loop boundary;
        // a synchronous test must commit/flush before querying projectPoint.
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        SCNTransaction.disableActions = true
        defer { SCNTransaction.commit() }
        // Keep the viewport, user orbit and controller alive during ordinary
        // edits. Only an initial presentation or explicit Fit request recenters.
        if contentChanged {
            let root = coordinator.content
            root.childNodes.forEach { $0.removeFromParentNode() }
            coordinator.lightIDs.removeAll()
            coordinator.selectionIndicators.removeAll()
            populate(root, coordinator: coordinator)
        }
        for (id, indicator) in coordinator.selectionIndicators {
            indicator.isHidden = id != selected
        }
        view.allowsCameraControl = !cameraMode
        (view as? OrbitAwareSceneView)?.usesOrbitProjection = !cameraMode
        if cameraMode, let framing = CameraFraming(scene: scene) {
            let camera = coordinator.camera
            camera.position = vector(framing.position)
            camera.camera?.projectionDirection = .vertical
            camera.camera?.fieldOfView = CGFloat(framing.verticalFieldOfViewDegrees)
            camera.camera?.zNear = CameraFraming.minimumDepthMeters
            camera.camera?.zFar = 400
            camera.look(at: vector(framing.target), up: vector(framing.up), localFront: SCNVector3(0, 0, -1))
            view.pointOfView = camera
        } else if needsFit, let bounds = try? StudioSceneBounds(scene: scene) {
            fitOrbit(view, coordinator: coordinator, bounds: bounds)
            coordinator.lastFitRequest = fitRequest
        }
        coordinator.lastScene = scene
        coordinator.lastCameraMode = cameraMode
        coordinator.lastSelected = selected
    }

    private func fitOrbit(_ view: SCNView, coordinator: Coordinator, bounds: StudioSceneBounds) {
        let center = bounds.center
        // Include the illustrative subject/body and fixture housing beyond the
        // authored centers. Infinite floor and remote stand bases are not fitted.
        let radius = max(1, bounds.radiusMeters + 1)
        let distance = radius / sin(24 * Double.pi / 180) * 1.12
        let direction = SIMD3<Double>(4, 2.6, 6)
        let length = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
        let offset = direction * (distance / length)
        let camera = coordinator.camera
        view.defaultCameraController.stopInertia()
        camera.position = SCNVector3(Float(center.x + offset.x), Float(center.y + offset.y), Float(center.z + offset.z))
        camera.camera?.fieldOfView = 48
        camera.camera?.projectionDirection = view.bounds.width < view.bounds.height ? .horizontal : .vertical
        camera.camera?.zNear = 0.02
        camera.camera?.zFar = max(400, distance + radius * 2)
        camera.look(at: vector(center), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        view.pointOfView = camera
        view.defaultCameraController.automaticTarget = false
        view.defaultCameraController.target = vector(center)
    }

    private func vector(_ p: Position) -> SCNVector3 { SCNVector3(Float(p.x), Float(p.y), Float(p.z)) }
    private func vector(_ d: UnitDirection) -> SCNVector3 { SCNVector3(Float(d.x), Float(d.y), Float(d.z)) }

    private func orient(_ node: SCNNode, to frame: EmitterFrame, negativeZForward: Bool = false) {
        // Use the complete shared basis, including roll and the deterministic
        // vertical-aim frame. Fixtures emit along +Z; SceneKit lights use -Z.
        // Flipping both right and normal preserves a right-handed rotation.
        let sign: Float = negativeZForward ? -1 : 1
        let right = SIMD3<Float>(Float(frame.right.x), Float(frame.right.y), Float(frame.right.z)) * sign
        let up = SIMD3<Float>(Float(frame.up.x), Float(frame.up.y), Float(frame.up.z))
        let normal = SIMD3<Float>(Float(frame.normal.x), Float(frame.normal.y), Float(frame.normal.z)) * sign
        node.simdOrientation = simd_quatf(simd_float3x3(columns: (right, up, normal)))
    }
    private func object(_ g: SCNGeometry, color: UIColor, at p: SCNVector3, in root: SCNNode) -> SCNNode {
        g.firstMaterial?.diffuse.contents = color
        g.firstMaterial?.lightingModel = .blinn
        let node = SCNNode(geometry: g); node.position = p; root.addChildNode(node)
        return node
    }

    private func populate(_ root: SCNNode, coordinator: Coordinator) {
        let floor = SCNFloor(); floor.reflectivity = 0
        _ = object(floor, color: UIColor(white: 0.19, alpha: 1), at: SCNVector3Zero, in: root)
        let p = vector(scene.subject)
        _ = object(SCNSphere(radius: 0.19), color: UIColor(red: 0.62, green: 0.48, blue: 0.39, alpha: 1), at: p, in: root)
        let torso = object(SCNCapsule(capRadius: 0.23, height: 0.76), color: UIColor(white: 0.37, alpha: 1),
                           at: SCNVector3(p.x, p.y - 0.55, p.z), in: root)
        torso.scale = SCNVector3(1.2, 1, 0.65)
        let ambient = SCNNode()
        ambient.light = SCNLight(); ambient.light?.type = .ambient
        // This readability fill is illustrative, but an empty or powered-off
        // rig must not acquire illumination from the preview itself.
        let hasActiveEmitter = scene.lights.contains {
            $0.isValid && $0.candela > 0 &&
                (!$0.effectiveOptics.kind.isAimed || StudioPhotometry.frame(for: $0, subject: scene.subject) != nil)
        }
        ambient.light?.intensity = hasActiveEmitter ? 90 : 0
        root.addChildNode(ambient)
        if !cameraMode {
            let cameraBody = object(SCNBox(width: 0.26, height: 0.18, length: 0.18, chamferRadius: 0.02),
                                    color: .darkGray, at: vector(scene.camera), in: root)
            if let framing = CameraFraming(scene: scene) {
                cameraBody.look(at: vector(framing.target), up: vector(framing.up), localFront: SCNVector3(0, 0, -1))
            }
        }
        for light in scene.lights {
            guard light.isValid else { continue }
            let optics = light.effectiveOptics
            let pos = vector(light.position)
            let frame = StudioPhotometry.frame(for: light, subject: scene.subject)
            // A degenerate aiming direction must not silently become an omnidirectional light.
            if !optics.kind.isAimed || frame != nil {
                let emitter = SCNNode(); emitter.position = pos
                let source = SCNLight(); emitter.light = source
                source.type = optics.kind.isAimed ? .spot : .omni
                source.temperature = CGFloat(light.kelvin)
                source.intensity = CGFloat(min(4000, light.candela * 1.5))
                source.attenuationStartDistance = 0; source.attenuationEndDistance = 10
                root.addChildNode(emitter)
                if let frame {
                    source.spotInnerAngle = 25; source.spotOuterAngle = 140
                    orient(emitter, to: frame, negativeZForward: true)
                }
            }
            let color: UIColor = light.candela > 0 ? .systemOrange : .darkGray
            let geometry: SCNGeometry
            switch optics.kind {
            case .point: geometry = SCNSphere(radius: 0.09)
            case .directional: geometry = SCNBox(width: 0.22, height: 0.18, length: 0.13, chamferRadius: 0.015)
            case .rectangle: geometry = SCNBox(width: CGFloat(optics.widthMeters), height: CGFloat(optics.heightMeters), length: 0.055, chamferRadius: 0.012)
            }
            let fixture = object(geometry, color: color, at: pos, in: root)
            if let frame { orient(fixture, to: frame) }
            if !cameraMode {
                coordinator.lightIDs[ObjectIdentifier(fixture)] = light.id
                // A wire outline marks selection without changing light output
                // or the authored equipment dimensions used by the scene.
                if let outline = geometry.copy() as? SCNGeometry {
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.systemYellow
                    material.lightingModel = .constant
                    material.fillMode = .lines
                    outline.materials = [material]
                    let indicator = SCNNode(geometry: outline)
                    indicator.scale = SCNVector3(1.06, 1.06, 1.06)
                    indicator.isHidden = light.id != selected
                    fixture.addChildNode(indicator)
                    coordinator.selectionIndicators[light.id] = indicator
                }
            }
            // Keep equipment readable, but do not imply a powered-off fixture is emitting light.
            if light.candela > 0 && (!optics.kind.isAimed || frame != nil) {
                fixture.geometry?.firstMaterial?.emission.contents = UIColor.systemOrange.withAlphaComponent(0.35)
            }
            if pos.y > 0.05 {
                let stand = object(SCNCylinder(radius: 0.015, height: CGFloat(pos.y)), color: .gray,
                                   at: SCNVector3(pos.x, pos.y / 2, pos.z), in: root)
                if !cameraMode { coordinator.lightIDs[ObjectIdentifier(stand)] = light.id }
            }
        }
    }
}

/// SwiftUI may first update a zero-sized view. Choose the orbit FOV's smaller
/// viewport axis after layout without resetting the user's position or target.
private final class OrbitAwareSceneView: SCNView {
    var usesOrbitProjection = false

    override func layoutSubviews() {
        super.layoutSubviews()
        guard usesOrbitProjection, bounds.width > 0, bounds.height > 0 else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        SCNTransaction.disableActions = true
        defer { SCNTransaction.commit() }
        pointOfView?.camera?.projectionDirection = bounds.width < bounds.height ? .horizontal : .vertical
    }
}
