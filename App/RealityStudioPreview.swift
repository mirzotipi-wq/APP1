import SwiftUI
import RealityKit
import LightingCore
import simd

/// A spatial editing aid. RealityKit shading is illustrative; the core meter
/// remains the source of photometric values and the camera tab keeps its lens.
@MainActor
struct RealityStudioPreview: View {
    let scene: LightingScene
    let selected: UUID?
    let fitRequest: Int
    let onSelect: (UUID) -> Void

    var body: some View {
        surface
            .overlay(alignment: .bottomLeading) {
                Text(previewNote)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.64), in: RoundedRectangle(cornerRadius: 7))
                    .padding(10)
                    .allowsHitTesting(false)
            }
    }

    @ViewBuilder private var surface: some View {
        #if targetEnvironment(simulator) && arch(x86_64)
        // The Intel iOS 26.5 runtime traps inside CoreRE's texture manager on
        // its first mesh, before ARView exists. A working Metal compute device
        // does not establish RealityKit support. Choose the renderer before
        // constructing its coordinator, including outside UI tests.
        SpatialPreview(scene: scene, fitRequest: fitRequest,
                       selected: selected, onSelect: onSelect)
        #else
        RealityStudioSurface(scene: scene, selected: selected,
                             fitRequest: fitRequest, onSelect: onSelect)
        #endif
    }

    private var previewNote: String {
        guard (try? scene.validated()) != nil else { return "Preview unavailable · check setup" }
        #if targetEnvironment(simulator) && arch(x86_64)
        return "Illustrative lighting · geometry in meters"
        #else
        let count = scene.lights.filter {
            $0.candela > 0 && (!$0.effectiveOptics.kind.isAimed ||
                              StudioPhotometry.frame(for: $0, subject: scene.subject) != nil)
        }.count
        return count > StudioEntityGraph.maximumShadedLights
            ? "Illustrative lighting · first \(StudioEntityGraph.maximumShadedLights) active lights shaded"
            : "Illustrative lighting · geometry in meters"
        #endif
    }
}

@MainActor
private struct RealityStudioSurface: UIViewRepresentable {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isEnabled) private var isEnabled
    let scene: LightingScene
    let selected: UUID?
    let fitRequest: Int
    let onSelect: (UUID) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> StudioOrbitARView {
        let view = StudioOrbitARView(frame: .zero, cameraMode: .nonAR,
                                     automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(red: 0.055, green: 0.064, blue: 0.078, alpha: 1))
        view.environment.lighting.intensityExponent = -1
        view.renderOptions.insert(.disableMotionBlur)
        view.renderOptions.insert(.disableDepthOfField)
        view.renderOptions.insert(.disableCameraGrain)
        // The parent's light list supplies accessible selection and editing.
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: StudioOrbitARView, context: Context) {
        context.coordinator.setInteractionEnabled(isEnabled)
        context.coordinator.setSceneActive(scenePhase == .active)
        context.coordinator.update(scene: scene, selected: selected,
                                   fitRequest: fitRequest, onSelect: onSelect)
    }

    static func dismantleUIView(_ view: StudioOrbitARView, coordinator: Coordinator) {
        coordinator.detach(from: view)
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let graph = StudioEntityGraph()
        private let cameraAnchor = AnchorEntity(world: .zero)
        private let camera = PerspectiveCamera()
        private weak var view: StudioOrbitARView?
        private var gestures: [UIGestureRecognizer] = []
        private weak var panGesture: UIPanGestureRecognizer?
        private weak var zoomGesture: UIPinchGestureRecognizer?
        private var onSelect: ((UUID) -> Void)?
        private var currentScene: LightingScene?
        private var lastFitRequest: Int?
        private var isSceneActive = true
        private var isInteractionEnabled = true
        private var isRendering = false
        private var needsFit = true
        private var orbitState = SpatialOrbitState()

        func attach(to view: StudioOrbitARView) {
            self.view = view
            camera.name = "Studio orbit camera"
            camera.camera = PerspectiveCameraComponent(near: 0.02, far: 2_000, fieldOfViewInDegrees: 48)
            cameraAnchor.addChild(camera)
            view.didLayout = { [weak self] size in self?.layout(size: size) }
            view.didChangeWindow = { [weak self] in self?.updateRenderingState() }

            let orbit = UIPanGestureRecognizer(target: self, action: #selector(orbit(_:)))
            orbit.minimumNumberOfTouches = 1
            orbit.maximumNumberOfTouches = 1
            let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
            pan.minimumNumberOfTouches = 2
            pan.maximumNumberOfTouches = 2
            let zoom = UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectLight(_:)))
            tap.require(toFail: orbit)
            tap.require(toFail: pan)
            tap.require(toFail: zoom)
            panGesture = pan
            zoomGesture = zoom
            gestures = [orbit, pan, zoom, tap]
            for gesture in gestures {
                gesture.delegate = self
                view.addGestureRecognizer(gesture)
            }
            applyCamera()
            updateRenderingState()
        }

        func setSceneActive(_ active: Bool) {
            isSceneActive = active
            updateRenderingState()
        }

        func setInteractionEnabled(_ enabled: Bool) {
            isInteractionEnabled = enabled
            updateInteractionState()
        }

        private var canInteract: Bool {
            isRendering && isInteractionEnabled && currentScene != nil &&
                view?.window != nil && !UIAccessibility.isVoiceOverRunning
        }

        private func updateInteractionState() {
            let enabled = isRendering && isInteractionEnabled && currentScene != nil
            view?.isUserInteractionEnabled = enabled
            for gesture in gestures { gesture.isEnabled = enabled }
        }

        private func cancelGestures() {
            for gesture in gestures { gesture.isEnabled = false }
            updateInteractionState()
        }

        private func updateRenderingState() {
            guard let view else { return }
            let shouldRender = isSceneActive && view.window != nil
            view.isHidden = !shouldRender
            defer { updateInteractionState() }
            guard shouldRender != isRendering else { return }
            isRendering = shouldRender
            // Keep orbit state while detaching geometry outside the active
            // window. A non-AR preview never starts an AR camera session.
            if shouldRender {
                view.scene.addAnchor(graph.anchor)
                view.scene.addAnchor(cameraAnchor)
            } else {
                view.scene.removeAnchor(graph.anchor)
                view.scene.removeAnchor(cameraAnchor)
                cancelGestures()
            }
        }

        func update(scene: LightingScene, selected: UUID?, fitRequest: Int,
                    onSelect: @escaping (UUID) -> Void) {
            // Refresh callbacks even when geometry is unchanged. A gesture must
            // never select into a previous project or a captured light array.
            self.onSelect = onSelect
            let validated = (try? scene.validated()) == nil ? nil : scene
            let previousIDs = currentScene.map { Set($0.lights.map(\.id)) }
            let currentIDs = validated.map { Set($0.lights.map(\.id)) }
            currentScene = validated
            if previousIDs != currentIDs { cancelGestures() }
            graph.update(scene: scene, selected: selected)
            if lastFitRequest != fitRequest {
                lastFitRequest = fitRequest
                needsFit = true
            }
            updateInteractionState()
            if let view { layout(size: view.bounds.size) }
        }

        func detach(from view: StudioOrbitARView) {
            view.didLayout = nil
            view.didChangeWindow = nil
            for gesture in gestures {
                gesture.delegate = nil
                gesture.removeTarget(self, action: nil)
                view.removeGestureRecognizer(gesture)
            }
            gestures.removeAll()
            panGesture = nil
            zoomGesture = nil
            view.scene.removeAnchor(graph.anchor)
            view.scene.removeAnchor(cameraAnchor)
            camera.removeFromParent()
            isRendering = false
            onSelect = nil
            currentScene = nil
            self.view = nil
        }

        private func layout(size: CGSize) {
            guard let fieldOfView = SpatialOrbitState.verticalFieldOfView(
                width: Double(size.width), height: Double(size.height)) else { return }
            // The iOS 13-compatible projection API uses a vertical FOV. Keep
            // 48 degrees on the smaller viewport axis without changing orbit.
            camera.camera.fieldOfViewInDegrees = Float(fieldOfView)
            if needsFit, let scene = currentScene, let bounds = try? SpatialViewportBounds(scene: scene) {
                orbitState.fit(bounds)
                needsFit = false
            }
            applyCamera()
        }

        private func applyCamera() {
            func vector(_ p: Position) -> SIMD3<Float> { [Float(p.x), Float(p.y), Float(p.z)] }
            camera.camera.far = Float(orbitState.farDistance)
            camera.look(at: vector(orbitState.target), from: vector(orbitState.position), relativeTo: nil)
        }

        @objc private func orbit(_ gesture: UIPanGestureRecognizer) {
            guard canInteract, let view, gesture.state == .began || gesture.state == .changed else { return }
            let movement = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            orbitState.orbit(horizontal: Double(movement.x), vertical: Double(movement.y))
            applyCamera()
        }

        @objc private func pan(_ gesture: UIPanGestureRecognizer) {
            guard canInteract, let view,
                  gesture.state == .began || gesture.state == .changed else { return }
            let movement = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            orbitState.pan(horizontal: Double(movement.x), vertical: Double(movement.y),
                           width: Double(view.bounds.width), height: Double(view.bounds.height))
            applyCamera()
        }

        @objc private func zoom(_ gesture: UIPinchGestureRecognizer) {
            guard canInteract, gesture.state == .began || gesture.state == .changed else { return }
            let scale = Double(gesture.scale)
            gesture.scale = 1
            orbitState.zoom(scale: scale)
            applyCamera()
        }

        @objc private func selectLight(_ gesture: UITapGestureRecognizer) {
            guard canInteract, gesture.state == .ended, let view,
                  let hit = view.entity(at: gesture.location(in: view)),
                  let id = graph.lightID(for: hit),
                  currentScene?.lights.contains(where: { $0.id == id }) == true else { return }
            onSelect?(id)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            (gestureRecognizer === panGesture && otherGestureRecognizer === zoomGesture) ||
            (gestureRecognizer === zoomGesture && otherGestureRecognizer === panGesture)
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            canInteract
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIPinchGestureRecognizer,
                  let scrollView = otherGestureRecognizer.view as? UIScrollView,
                  otherGestureRecognizer === scrollView.panGestureRecognizer,
                  let view, view.isDescendant(of: scrollView) else { return false }
            // Gestures that begin inside the preview edit its camera; scrolling
            // remains available everywhere else and through VoiceOver.
            return true
        }

    }
}

@MainActor
private final class StudioOrbitARView: ARView {
    var didLayout: ((CGSize) -> Void)?
    var didChangeWindow: (() -> Void)?
    private var previousSize: CGSize = .zero

    override func didMoveToWindow() {
        super.didMoveToWindow()
        didChangeWindow?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != previousSize else { return }
        previousSize = bounds.size
        didLayout?(bounds.size)
    }
}
