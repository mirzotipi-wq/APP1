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
        fileprivate var base: SpatialBaseNodes?
        fileprivate var lamps: [UUID: SpatialLampNodes] = [:]
        var onSelect: ((UUID) -> Void)?
        private weak var view: SCNView?
        private weak var selectionGesture: UITapGestureRecognizer?
        private var interactionEnabled = true
        private var contentAvailable = false

        func attach(to view: SCNView) {
            self.view = view
            refreshSelectionGesture()
        }

        func refreshSelectionGesture() {
            guard let view else { return }
            if let existing = selectionGesture {
                existing.delegate = nil
                existing.removeTarget(self, action: nil)
                view.removeGestureRecognizer(existing)
            }
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
            updateInteractionState()
        }

        func setInteractionEnabled(_ enabled: Bool) {
            interactionEnabled = enabled
            updateInteractionState()
        }

        func setContentAvailable(_ available: Bool) {
            contentAvailable = available
            updateInteractionState()
        }

        private func updateInteractionState() {
            let enabled = interactionEnabled && contentAvailable && lastCameraMode == false
            view?.isUserInteractionEnabled = enabled
            selectionGesture?.isEnabled = enabled
            if !enabled { view?.defaultCameraController.stopInertia() }
        }

        func cancelSelection() {
            selectionGesture?.isEnabled = false
            updateInteractionState()
        }

        func discardEquipment() {
            for lamp in lamps.values {
                lamp.fixture.removeFromParentNode()
                lamp.source.removeFromParentNode()
                lamp.stand.removeFromParentNode()
            }
            lamps.removeAll()
            lightIDs.removeAll()
            selectionIndicators.removeAll()
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
            lamps.removeAll()
            base = nil
            lastScene = nil
            lastCameraMode = nil
            lastFitRequest = nil
            lastSelected = nil
            contentAvailable = false
            self.view = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            interactionEnabled && contentAvailable && lastCameraMode == false && onSelect != nil &&
                view?.window != nil && !UIAccessibility.isVoiceOverRunning
        }

        @objc private func selectLight(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, gestureRecognizerShouldBegin(gesture),
                  let view, let hit = view.hitTest(gesture.location(in: view), options: nil).first else { return }
            guard let id = lightID(for: hit.node) else { return }
            onSelect?(id)
        }

        /// Resolve only nodes currently owned by this graph. A retained hit
        /// from a removed/replaced scene cannot match a newly allocated UUID.
        func lightID(for hit: SCNNode) -> UUID? {
            guard contentAvailable, !content.isHidden, lastCameraMode == false else { return nil }
            var node: SCNNode? = hit
            while let current = node {
                guard !current.isHidden else { return nil }
                if let id = lightIDs[ObjectIdentifier(current)],
                   current.parent === content,
                   lastScene?.lights.contains(where: { $0.id == id }) == true {
                    return id
                }
                node = current.parent
            }
            return nil
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
        // Equipment-list actions are the accessible alternative to a visual
        // hit test. Keep implementation nodes out of the accessibility tree.
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true
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
        let valid = (try? scene.validated()) != nil
        let modeChanged = coordinator.lastCameraMode != cameraMode
        let sceneChanged = coordinator.lastScene != scene
        let selectionChanged = coordinator.lastSelected != selected
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
        let available = valid && (!cameraMode || CameraFraming(scene: scene) != nil)
        // An invalid scene cannot apply a mode change. Preserve the last
        // applied mode so recovery still performs any pending orbit Fit.
        if valid { coordinator.lastCameraMode = cameraMode }
        coordinator.setContentAvailable(available)
        coordinator.content.isHidden = !available
        (view as? OrbitAwareSceneView)?.setUnavailableMessage(available ? nil :
            (valid ? "Camera preview unavailable. Move the camera away from the subject." :
                "Preview unavailable. Check the setup values."))
        guard valid else {
            coordinator.cancelSelection()
            coordinator.onSelect = nil
            coordinator.discardEquipment()
            coordinator.lastScene = nil
            return
        }
        if Set(coordinator.lastScene?.lights.map(\.id) ?? []) != Set(scene.lights.map(\.id)) {
            coordinator.cancelSelection()
        }
        // Keep the viewport, user orbit and controller alive during ordinary
        // edits. Only an initial presentation or explicit Fit request recenters.
        if sceneChanged || modeChanged { updateContent(coordinator) }
        for (id, indicator) in coordinator.selectionIndicators {
            indicator.isHidden = cameraMode || id != selected
        }
        if view.allowsCameraControl != !cameraMode {
            view.allowsCameraControl = !cameraMode
            coordinator.refreshSelectionGesture()
        }
        (view as? OrbitAwareSceneView)?.usesOrbitProjection = !cameraMode
        if cameraMode, let framing = CameraFraming(scene: scene), available {
            let camera = coordinator.camera
            camera.position = vector(framing.position)
            camera.camera?.projectionDirection = .vertical
            camera.camera?.fieldOfView = CGFloat(framing.verticalFieldOfViewDegrees)
            camera.camera?.zNear = CameraFraming.minimumDepthMeters
            camera.camera?.zFar = 400
            camera.look(at: vector(framing.target), up: vector(framing.up), localFront: SCNVector3(0, 0, -1))
            view.pointOfView = camera
        } else if cameraMode {
            // Never display a prior camera pose for an undefined authored view.
            view.pointOfView = nil
        } else if needsFit, let bounds = try? SpatialViewportBounds(scene: scene) {
            fitOrbit(view, coordinator: coordinator, bounds: bounds)
            coordinator.lastFitRequest = fitRequest
        }
        coordinator.lastScene = scene
        coordinator.lastCameraMode = cameraMode
        coordinator.lastSelected = selected
    }

    private func fitOrbit(_ view: SCNView, coordinator: Coordinator, bounds: SpatialViewportBounds) {
        var orbit = SpatialOrbitState()
        orbit.fit(bounds)
        let center = orbit.target
        let camera = coordinator.camera
        view.defaultCameraController.stopInertia()
        camera.position = vector(orbit.position)
        camera.camera?.fieldOfView = 48
        camera.camera?.projectionDirection = view.bounds.width < view.bounds.height ? .horizontal : .vertical
        camera.camera?.zNear = 0.02
        camera.camera?.zFar = orbit.farDistance
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

    private func updateContent(_ coordinator: Coordinator) {
        let root = coordinator.content
        if coordinator.base == nil {
            let floor = SCNFloor(); floor.reflectivity = 0
            _ = object(floor, color: UIColor(white: 0.19, alpha: 1), at: SCNVector3Zero, in: root)
            let head = object(SCNSphere(radius: 0.19), color: UIColor(red: 0.62, green: 0.48, blue: 0.39, alpha: 1),
                              at: SCNVector3Zero, in: root)
            let torso = object(SCNCapsule(capRadius: 0.23, height: 0.76), color: UIColor(white: 0.37, alpha: 1),
                               at: SCNVector3Zero, in: root)
            torso.scale = SCNVector3(1.2, 1, 0.65)
            let ambient = SCNNode()
            ambient.light = SCNLight(); ambient.light?.type = .ambient
            root.addChildNode(ambient)
            let body = object(SCNBox(width: 0.26, height: 0.18, length: 0.18, chamferRadius: 0.02),
                              color: .darkGray, at: SCNVector3Zero, in: root)
            body.name = "Authored camera"
            _ = object(SCNBox(width: 0.095, height: 0.095, length: 0.10, chamferRadius: 0.008),
                       color: UIColor(white: 0.12, alpha: 1), at: SCNVector3(0, 0, -0.12), in: body)
            coordinator.base = SpatialBaseNodes(head: head, torso: torso, ambient: ambient, cameraBody: body)
        }
        guard let base = coordinator.base else { return }
        let p = vector(scene.subject)
        base.head.position = p
        base.torso.position = SCNVector3(p.x, p.y - 0.55, p.z)
        base.cameraBody.position = vector(scene.camera)
        base.cameraBody.isHidden = cameraMode
        if let framing = CameraFraming(scene: scene) {
            base.cameraBody.look(at: vector(framing.target), up: vector(framing.up), localFront: SCNVector3(0, 0, -1))
        } else {
            base.cameraBody.simdOrientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        }
        // This readability fill is illustrative, but an empty or powered-off
        // rig must not acquire illumination from the preview itself.
        let hasActiveEmitter = scene.lights.contains {
            $0.candela > 0 &&
                (!$0.effectiveOptics.kind.isAimed || StudioPhotometry.frame(for: $0, subject: scene.subject) != nil)
        }
        base.ambient.light?.intensity = hasActiveEmitter ? 90 : 0
        let ids = Set(scene.lights.map(\.id))
        for id in Array(coordinator.lamps.keys) where !ids.contains(id) {
            guard let lamp = coordinator.lamps.removeValue(forKey: id) else { continue }
            lamp.fixture.removeFromParentNode()
            lamp.source.removeFromParentNode()
            lamp.stand.removeFromParentNode()
            coordinator.selectionIndicators.removeValue(forKey: id)
        }
        coordinator.lightIDs.removeAll(keepingCapacity: true)
        for light in scene.lights {
            let lamp: SpatialLampNodes
            if let existing = coordinator.lamps[light.id] {
                lamp = existing
            } else {
                lamp = SpatialLampNodes()
                lamp.fixture.name = "Studio light \(light.id.uuidString)"
                root.addChildNode(lamp.fixture)
                root.addChildNode(lamp.source)
                lamp.fixture.addChildNode(lamp.indicator)
                coordinator.lamps[light.id] = lamp
                coordinator.selectionIndicators[light.id] = lamp.indicator
            }
            let optics = light.effectiveOptics
            let previous = lamp.lastLight
            let shapeChanged = previous == nil || optics.kind != previous?.effectiveOptics.kind ||
                (optics.kind == .rectangle && (optics.widthMeters != previous?.effectiveOptics.widthMeters ||
                                              optics.heightMeters != previous?.effectiveOptics.heightMeters))
            let renderChanged = shapeChanged || light.position != previous?.position ||
                optics != previous?.effectiveOptics || light.candela != previous?.candela ||
                light.kelvin != previous?.kelvin || scene.subject != lamp.lastSubject
            if shapeChanged {
                let geometry: SCNGeometry
                switch optics.kind {
                case .point: geometry = SCNSphere(radius: 0.09)
                case .directional: geometry = SCNBox(width: 0.22, height: 0.18, length: 0.13, chamferRadius: 0.015)
                case .rectangle: geometry = SCNBox(width: CGFloat(optics.widthMeters), height: CGFloat(optics.heightMeters),
                                                  length: 0.055, chamferRadius: 0.012)
                }
                let material = SCNMaterial()
                material.lightingModel = .blinn
                geometry.materials = [material]
                lamp.fixture.geometry = geometry
                if let outline = geometry.copy() as? SCNGeometry {
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.systemYellow
                    material.lightingModel = .constant
                    material.fillMode = .lines
                    outline.materials = [material]
                    lamp.indicator.geometry = outline
                    // A fixed meter margin remains bounded for large modifiers.
                    let width = optics.kind == .rectangle ? optics.widthMeters : 0.22
                    let height = optics.kind == .rectangle ? optics.heightMeters : 0.18
                    lamp.indicator.scale = optics.kind == .point ? SCNVector3(1.06, 1.06, 1.06) :
                        SCNVector3(Float(1 + 0.04 / width), Float(1 + 0.04 / height), 1.06)
                }
            }
            if !cameraMode {
                coordinator.lightIDs[ObjectIdentifier(lamp.fixture)] = light.id
                if light.position.y > 0.05 { coordinator.lightIDs[ObjectIdentifier(lamp.stand)] = light.id }
            }
            lamp.lastLight = light
            lamp.lastSubject = scene.subject
            guard renderChanged else { continue }
            let pos = vector(light.position)
            let frame = StudioPhotometry.frame(for: light, subject: scene.subject)
            // A degenerate aiming direction must not silently become an omnidirectional light.
            if !optics.kind.isAimed || frame != nil {
                let source = lamp.source.light ?? SCNLight()
                lamp.source.light = source
                lamp.source.position = pos
                lamp.source.simdOrientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                source.type = optics.kind.isAimed ? .spot : .omni
                source.temperature = CGFloat(light.kelvin)
                source.intensity = CGFloat(min(4000, light.candela * 1.5))
                source.attenuationStartDistance = 0; source.attenuationEndDistance = 10
                if let frame {
                    source.spotInnerAngle = 25; source.spotOuterAngle = 140
                    orient(lamp.source, to: frame, negativeZForward: true)
                }
            } else {
                lamp.source.light = nil
            }
            let color: UIColor = light.candela > 0 ? .systemOrange : .darkGray
            let fixture = lamp.fixture
            fixture.position = pos
            fixture.simdOrientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            fixture.geometry?.firstMaterial?.diffuse.contents = color
            if let frame {
                orient(fixture, to: frame)
                if let box = fixture.geometry as? SCNBox {
                    // The local +Z face is the authored emitting plane. Keep
                    // the housing behind it, including after aim and roll.
                    // The light source and stand retain their authored anchors.
                    fixture.localTranslate(by: SCNVector3(0, 0, -Float(box.length) / 2))
                }
            }
            // Keep equipment readable, but do not imply a powered-off fixture is emitting light.
            let emitting = light.candela > 0 && (!optics.kind.isAimed || frame != nil)
            fixture.geometry?.firstMaterial?.emission.contents = emitting ?
                UIColor.systemOrange.withAlphaComponent(0.35) : UIColor.black
            if pos.y > 0.05 {
                if lamp.stand.geometry == nil {
                    let geometry = SCNCylinder(radius: 0.015, height: 1)
                    let material = SCNMaterial(); material.diffuse.contents = UIColor.gray
                    geometry.materials = [material]
                    lamp.stand.geometry = geometry
                }
                (lamp.stand.geometry as? SCNCylinder)?.height = CGFloat(pos.y)
                lamp.stand.position = SCNVector3(pos.x, pos.y / 2, pos.z)
                if lamp.stand.parent == nil { root.addChildNode(lamp.stand) }
            } else {
                lamp.stand.removeFromParentNode()
            }
        }
    }
}

@MainActor
private struct SpatialBaseNodes {
    let head: SCNNode
    let torso: SCNNode
    let ambient: SCNNode
    let cameraBody: SCNNode
}

@MainActor
private final class SpatialLampNodes {
    let fixture = SCNNode()
    let source = SCNNode()
    let stand = SCNNode()
    let indicator = SCNNode()
    var lastLight: StudioLight?
    var lastSubject: Position?
}

/// SwiftUI may first update a zero-sized view. Choose the orbit FOV's smaller
/// viewport axis after layout without resetting the user's position or target.
private final class OrbitAwareSceneView: SCNView {
    var usesOrbitProjection = false
    private var unavailableLabel: UILabel?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            defaultCameraController.stopInertia()
            isPlaying = false
        }
    }

    func setUnavailableMessage(_ message: String?) {
        accessibilityElementsHidden = message == nil
        guard let message else {
            unavailableLabel?.isHidden = true
            return
        }
        if unavailableLabel == nil {
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .white
            label.font = .preferredFont(forTextStyle: .caption1)
            label.adjustsFontForContentSizeCategory = true
            label.accessibilityIdentifier = "spatialPreviewUnavailable"
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            unavailableLabel = label
        }
        unavailableLabel?.text = message
        unavailableLabel?.isHidden = false
    }

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
