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
        RealityStudioSurface(scene: scene, selected: selected,
                             fitRequest: fitRequest, onSelect: onSelect)
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

    private var previewNote: String {
        guard (try? scene.validated()) != nil else { return "Preview unavailable · check setup" }
        let count = scene.lights.filter {
            $0.candela > 0 && (!$0.effectiveOptics.kind.isAimed ||
                              StudioPhotometry.frame(for: $0, subject: scene.subject) != nil)
        }.count
        return count > StudioEntityGraph.maximumShadedLights
            ? "Illustrative lighting · first \(StudioEntityGraph.maximumShadedLights) active lights shaded"
            : "Illustrative lighting · geometry in meters"
    }
}

@MainActor
private struct RealityStudioSurface: UIViewRepresentable {
    @Environment(\.scenePhase) private var scenePhase
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
        context.coordinator.update(scene: scene, selected: selected,
                                   fitRequest: fitRequest, onSelect: onSelect)
        context.coordinator.setSceneActive(scenePhase == .active)
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
        private var isRendering = false
        private var needsFit = true
        private var target = SIMD3<Float>(0, 1, 0)
        private var yaw: Float = 0.56
        private var pitch: Float = 0.36
        private var distance: Float = 7
        private var verticalFieldOfView: Float = 48
        private let distanceRange: ClosedRange<Float> = 0.45...1_500

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

        private func updateRenderingState() {
            guard let view else { return }
            let shouldRender = isSceneActive && view.window != nil
            view.isHidden = !shouldRender
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
                for gesture in gestures {
                    gesture.isEnabled = false
                    gesture.isEnabled = true
                }
            }
        }

        func update(scene: LightingScene, selected: UUID?, fitRequest: Int,
                    onSelect: @escaping (UUID) -> Void) {
            // Refresh callbacks even when geometry is unchanged. A gesture must
            // never select into a previous project or a captured light array.
            self.onSelect = onSelect
            currentScene = (try? scene.validated()) == nil ? nil : scene
            graph.update(scene: scene, selected: selected)
            if lastFitRequest != fitRequest {
                lastFitRequest = fitRequest
                needsFit = true
            }
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
            guard size.width.isFinite, size.height.isFinite,
                  size.width > 0, size.height > 0 else { return }
            // The iOS 13-compatible projection API uses a vertical FOV. Keep
            // 48 degrees on the smaller viewport axis without changing orbit.
            let aspect = max(0.01, Float(size.width / size.height))
            verticalFieldOfView = aspect < 1
                ? 2 * atan(tan(24 * Float.pi / 180) / aspect) * 180 / Float.pi
                : 48
            camera.camera.fieldOfViewInDegrees = verticalFieldOfView
            if needsFit, let scene = currentScene, let bounds = try? StudioSceneBounds(scene: scene) {
                var low = SIMD3<Float>(Float(bounds.minimum.x), Float(bounds.minimum.y), Float(bounds.minimum.z))
                var high = SIMD3<Float>(Float(bounds.maximum.x), Float(bounds.maximum.y), Float(bounds.maximum.z))
                // Include the bust, housing and stand bases. The floor itself
                // must not dominate the fit or change it with world translation.
                low.y = min(low.y, Float(scene.subject.y) - 0.95)
                if scene.lights.contains(where: { $0.position.y > 0 }) { low.y = min(low.y, 0) }
                low -= SIMD3<Float>(repeating: 0.3)
                high += SIMD3<Float>(repeating: 0.3)
                target = (low + high) / 2
                let radius = max(0.8, simd_length(high - low) / 2)
                distance = clamp(radius / sin(24 * Float.pi / 180) * 1.12, to: distanceRange)
                yaw = 0.56
                pitch = 0.36
                needsFit = false
            }
            applyCamera()
        }

        private func applyCamera() {
            let offset = SIMD3<Float>(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
            // Authored coordinates lie in a 200 m cube. Include its diagonal
            // and equipment margins even after panning at maximum zoom-out.
            camera.camera.far = max(100, distance + simd_length(target) + 200)
            camera.look(at: target, from: target + offset, relativeTo: nil)
        }

        @objc private func orbit(_ gesture: UIPanGestureRecognizer) {
            guard let view, gesture.state == .began || gesture.state == .changed else { return }
            let movement = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            guard movement.x.isFinite, movement.y.isFinite else { return }
            yaw = (yaw - Float(movement.x) * 0.008).remainder(dividingBy: 2 * .pi)
            pitch = clamp(pitch + Float(movement.y) * 0.008, to: -1.35...1.35)
            applyCamera()
        }

        @objc private func pan(_ gesture: UIPanGestureRecognizer) {
            guard let view, view.bounds.height > 0,
                  gesture.state == .began || gesture.state == .changed else { return }
            let movement = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            guard movement.x.isFinite, movement.y.isFinite else { return }
            let metersPerPoint = 2 * distance * tan(verticalFieldOfView * .pi / 360) / Float(view.bounds.height)
            let right = camera.orientation.act(SIMD3<Float>(1, 0, 0))
            let up = camera.orientation.act(SIMD3<Float>(0, 1, 0))
            target += (-right * Float(movement.x) + up * Float(movement.y)) * metersPerPoint
            target = SIMD3<Float>(clamp(target.x, to: -300...300),
                                  clamp(target.y, to: -300...300), clamp(target.z, to: -300...300))
            applyCamera()
        }

        @objc private func zoom(_ gesture: UIPinchGestureRecognizer) {
            guard gesture.state == .began || gesture.state == .changed else { return }
            let scale = Float(gesture.scale)
            gesture.scale = 1
            guard scale.isFinite, scale > 0 else { return }
            distance = clamp(distance / scale, to: distanceRange)
            applyCamera()
        }

        @objc private func selectLight(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let view,
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
            isRendering && currentScene != nil && !UIAccessibility.isVoiceOverRunning
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

        private func clamp(_ value: Float, to range: ClosedRange<Float>) -> Float {
            min(range.upperBound, max(range.lowerBound, value))
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
