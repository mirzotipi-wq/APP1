import ARKit
import AVFoundation
import Combine
import LightingCore
import RealityKit
import UIKit
import simd

/// Owns a single, explicitly started camera session. No camera frames or world
/// maps are retained, written to disk, or sent to another service.
@MainActor
final class ARPlacementController: NSObject, ObservableObject {
    enum Phase: Equatable {
        case ready, requestingPermission, running, paused, denied, restricted, unsupported, invalidScene, failed
    }

    struct MarkerLabel: Identifiable, Equatable {
        let id: String
        let title: String
        let point: CGPoint
    }

    let scene: LightingScene
    let layout: ARPlacementLayout?
    @Published private(set) var phase: Phase = .ready
    @Published private(set) var cameraEnabled = false
    @Published private(set) var trackingNormal = false
    @Published private(set) var trackingMessage = "Move slowly and scan a textured area of the floor."
    @Published private(set) var surfaceFound = false
    @Published private(set) var hasPlacement = false
    @Published private(set) var needsPlacementReview = false
    @Published private(set) var yawDegrees = 0.0
    @Published private(set) var labels: [MarkerLabel] = []
    @Published private(set) var placementError: String?

    private weak var arView: ARView?
    private var sessionDelegate: PlacementSessionDelegate?
    private var sessionGeneration = 0
    private var floorAnchor: ARAnchor?
    private var anchorEntity: AnchorEntity?
    private var rigRoot: Entity?
    private var markerEntities: [(item: ARPlacementItem, entity: Entity)] = []
    private var visible = false
    private var foreground = true
    private var pendingStart = false
    private var permissionGeneration = 0
    private var interrupted = false
    private var lastFrameTime: TimeInterval = 0

    init(scene: LightingScene) {
        self.scene = scene
        layout = try? ARPlacementLayout(scene: scene, origin: .init(x: 0, y: 0, z: 0))
        super.init()
        if layout == nil {
            phase = .invalidScene
        } else if !Self.isSupported {
            phase = .unsupported
        }
    }

    static var isSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return ARWorldTrackingConfiguration.isSupported
        #endif
    }

    var canStart: Bool {
        layout != nil && Self.isSupported && phase != .requestingPermission && phase != .running
    }

    var canPlace: Bool {
        phase == .running && trackingNormal && !interrupted && surfaceFound && !hasPlacement
    }

    var statusTitle: String {
        switch phase {
        case .ready: return "Camera is off"
        case .requestingPermission: return "Waiting for camera access"
        case .paused: return "Camera paused"
        case .denied: return "Camera access is off"
        case .restricted: return "Camera access is restricted"
        case .unsupported: return "AR is unavailable on this device"
        case .invalidScene: return "This setup cannot be placed in AR"
        case .failed: return "AR session stopped"
        case .running:
            if !trackingNormal { return interrupted ? "AR interrupted" : "Tracking needs attention" }
            if needsPlacementReview { return "Check the recovered placement" }
            if hasPlacement { return "Setup placed · 1:1 scale" }
            return surfaceFound ? "Horizontal surface found" : "Find the floor"
        }
    }

    var statusDetail: String {
        switch phase {
        case .ready:
            return "Start the camera, scan the room, then aim the crosshair at the floor where your subject will stand."
        case .requestingPermission:
            return "Camera access is used for live placement on this device."
        case .paused:
            return "Start again and choose a new floor point. The previous placement has been cleared."
        case .denied:
            return "Allow Camera in Settings to use AR, or use manual room measurements below."
        case .restricted:
            return "Camera access is restricted by this device. Manual room measurements remain available."
        case .unsupported:
            return "Use a compatible physical iPhone or iPad for world tracking. The simulator cannot place a setup in a real room. Manual measurements work here."
        case .invalidScene:
            return "The setup is outside the supported coordinate range. Adjust its positions in the studio or use manual room measurements."
        case .failed:
            return "Start again to scan the room, or use manual room measurements."
        case .running:
            if interrupted {
                return "The camera session was interrupted. Markers are hidden. Return to the scanned area when the camera resumes, or reset."
            }
            if !trackingNormal { return trackingMessage }
            if needsPlacementReview {
                return "Tracking has recovered. Compare every marker with the room before continuing. Reset if anything shifted."
            }
            if hasPlacement {
                return "Markers show authored equipment centers. Check placement with a tape measure and a light meter."
            }
            return surfaceFound
                ? "Confirm the crosshair is on the actual floor, not a table or shelf, then place the subject here."
                : "Move slowly to find a textured, well-lit floor area. Keep the crosshair on the floor."
        }
    }

    func appeared(isActive: Bool) {
        visible = true
        foreground = isActive
    }

    func setActive(_ active: Bool) {
        foreground = active
        if !active, phase == .running {
            stop()
        } else if active, pendingStart, AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            activateCameraIfReady()
        }
    }

    func disappeared() {
        visible = false
        stop()
    }

    func start() {
        guard visible, foreground, canStart else { return }
        pendingStart = true
        placementError = nil
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            activateCameraIfReady()
        case .notDetermined:
            phase = .requestingPermission
            permissionGeneration += 1
            let generation = permissionGeneration
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.visible, self.pendingStart,
                          self.permissionGeneration == generation else { return }
                    if granted {
                        self.activateCameraIfReady()
                    } else {
                        self.pendingStart = false
                        self.phase = .denied
                    }
                }
            }
        case .denied:
            pendingStart = false
            phase = .denied
        case .restricted:
            pendingStart = false
            phase = .restricted
        @unknown default:
            pendingStart = false
            phase = .restricted
        }
    }

    private func activateCameraIfReady() {
        guard visible, foreground, pendingStart,
              AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
        pendingStart = false
        phase = .running
        trackingNormal = false
        interrupted = false
        trackingMessage = "Move slowly and scan a textured area of the floor."
        cameraEnabled = true
        // The representable attaches a view only after access is granted.
        if let arView { runSession(in: arView) }
    }

    func attach(_ view: ARView) {
        if arView === view { return }
        if let previousView = arView { detach(previousView) }
        arView = view
        guard phase == .running, visible, foreground else { return }
        runSession(in: view)
    }

    func detach(_ view: ARView) {
        view.session.delegate = nil
        view.session.pause()
        view.scene.anchors.removeAll()
        if arView === view {
            sessionGeneration += 1
            sessionDelegate = nil
            clearPlacement()
            surfaceFound = false
            trackingNormal = false
            arView = nil
        }
    }

    private func runSession(in view: ARView) {
        sessionGeneration += 1
        let delegate = PlacementSessionDelegate(owner: self, generation: sessionGeneration)
        sessionDelegate = delegate
        view.automaticallyConfigureSession = false
        view.session.delegateQueue = .main
        view.session.delegate = delegate
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = [.horizontal]
        configuration.isAutoFocusEnabled = true
        lastFrameTime = 0
        view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        permissionGeneration += 1
        sessionGeneration += 1
        pendingStart = false
        if let arView {
            arView.session.delegate = nil
            arView.session.pause()
        }
        sessionDelegate = nil
        clearPlacement()
        surfaceFound = false
        trackingNormal = false
        interrupted = false
        labels = []
        cameraEnabled = false
        if phase == .running || phase == .requestingPermission { phase = .paused }
    }

    func reset() {
        guard phase == .running, let arView else { return }
        clearPlacement()
        surfaceFound = false
        trackingNormal = false
        interrupted = false
        placementError = nil
        trackingMessage = "Scan the floor again, then choose a new subject position."
        runSession(in: arView)
    }

    private func clearPlacement() {
        if let floorAnchor { arView?.session.remove(anchor: floorAnchor) }
        anchorEntity?.removeFromParent()
        floorAnchor = nil
        anchorEntity = nil
        rigRoot = nil
        markerEntities = []
        labels = []
        hasPlacement = false
        needsPlacementReview = false
        yawDegrees = 0
    }

    func placeOnFloor() {
        guard canPlace, let view = arView, let frame = view.session.currentFrame,
              case .normal = frame.camera.trackingState,
              let result = floorHit(in: view), let layout else { return }
        // Use only translation from the horizontal hit. Gravity defines +Y;
        // the authored setup keeps meter scale and does not inherit plane tilt.
        var transform = matrix_identity_float4x4
        transform.columns.3 = result.worldTransform.columns.3
        let origin = transform.columns.3
        let camera = frame.camera.transform.columns.3
        let authored = SIMD2<Double>(scene.camera.x - scene.subject.x, scene.camera.z - scene.subject.z)
        let actual = SIMD2<Double>(Double(camera.x - origin.x), Double(camera.z - origin.z))
        let heading: Double = simd_length(authored) > 0.01 && simd_length(actual) > 0.01
            ? (atan2(actual.x, actual.y) - atan2(authored.x, authored.y)) * 180 / .pi : 0
        guard let placed = try? ARPlacementLayout(scene: scene,
            origin: .init(x: Double(origin.x), y: Double(origin.y), z: Double(origin.z)),
            yawDegrees: heading) else {
            placementError = "This floor point puts the setup outside the supported coordinates. Choose another point."
            return
        }
        let anchor = ARAnchor(name: "Key & Fill subject floor", transform: transform)
        let entity = AnchorEntity(anchor: anchor)
        let root = Entity()
        entity.addChild(root)
        buildMarkers(layout: layout, in: root)
        root.orientation = simd_quatf(angle: Float(placed.yawDegrees * .pi / 180), axis: [0, 1, 0])
        floorAnchor = anchor
        anchorEntity = entity
        rigRoot = root
        yawDegrees = placed.yawDegrees
        view.session.add(anchor: anchor)
        view.scene.anchors.append(entity)
        hasPlacement = true
        needsPlacementReview = false
        surfaceFound = false
        placementError = nil
    }

    func rotate(to angle: Double) {
        guard phase == .running, hasPlacement, trackingNormal, !interrupted,
              let anchorEntity, anchorEntity.isAnchored, let root = rigRoot else { return }
        let p = anchorEntity.position(relativeTo: nil)
        guard let placed = try? ARPlacementLayout(scene: scene,
            origin: .init(x: Double(p.x), y: Double(p.y), z: Double(p.z)), yawDegrees: angle) else {
            placementError = "This rotation exceeds the supported coordinates. The previous rotation is unchanged."
            return
        }
        // Preserve the slider's lower endpoint; -180 and +180 are the same
        // orientation, but canonicalization must not jump the thumb across it.
        yawDegrees = angle == -180 ? -180 : placed.yawDegrees
        root.orientation = simd_quatf(angle: Float(placed.yawDegrees * .pi / 180), axis: [0, 1, 0])
        placementError = nil
    }

    func confirmRecoveredPlacement() {
        guard hasPlacement, trackingNormal, !interrupted else { return }
        needsPlacementReview = false
    }

    private func floorHit(in view: ARView) -> ARRaycastResult? {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return nil }
        let hit = view.raycast(from: CGPoint(x: view.bounds.midX, y: view.bounds.midY),
                               allowing: .existingPlaneGeometry, alignment: .horizontal).first
        guard let hit, hit.worldTransform.columns.3.x.isFinite,
              hit.worldTransform.columns.3.y.isFinite, hit.worldTransform.columns.3.z.isFinite else { return nil }
        return hit
    }

    private func buildMarkers(layout: ARPlacementLayout, in root: Entity) {
        let lineColor = UIColor(white: 0.85, alpha: 1)
        for item in layout.items {
            let color: UIColor = item.role == .light
                ? UIColor(red: 1, green: 0.74, blue: 0.34, alpha: 1) : .white
            let center: ModelEntity
            if item.role == .camera {
                center = box(size: [0.12, 0.08, 0.06], color: color)
            } else {
                center = ModelEntity(mesh: .generateSphere(radius: item.role == .subject ? 0.055 : 0.04),
                                     materials: [UnlitMaterial(color: color)])
            }
            center.name = item.id
            center.position = vector(item.position)
            root.addChild(center)
            markerEntities.append((item, center))
            let floor = vector(item.floorPosition)
            let crossX = box(size: [0.15, 0.008, 0.018], color: color)
            let crossZ = box(size: [0.018, 0.008, 0.15], color: color)
            crossX.position = floor + [0, 0.008, 0]
            crossZ.position = crossX.position
            root.addChild(crossX)
            root.addChild(crossZ)
            addLine(from: floor, to: center.position, color: lineColor, in: root)
            if item.role != .subject {
                addLine(from: [0, 0.012, 0], to: floor + [0, 0.012, 0], color: lineColor, in: root)
            }
        }
    }

    private func box(size: SIMD3<Float>, color: UIColor) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateBox(size: 1), materials: [UnlitMaterial(color: color)])
        entity.scale = size
        return entity
    }

    private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor, in root: Entity) {
        let delta = end - start
        let length = simd_length(delta)
        guard length.isFinite, length > 0.005 else { return }
        let line = box(size: [0.004, length, 0.004], color: color)
        line.position = (start + end) / 2
        line.orientation = simd_quatf(from: [0, 1, 0], to: delta / length)
        root.addChild(line)
    }

    private func vector(_ p: Position) -> SIMD3<Float> { [Float(p.x), Float(p.y), Float(p.z)] }

    fileprivate func owns(_ session: ARSession, generation: Int) -> Bool {
        phase == .running && generation == sessionGeneration && arView?.session === session
    }

    fileprivate func process(frame: ARFrame, session: ARSession) {
        guard phase == .running, let view = arView, session === view.session else { return }
        updateTracking(frame.camera.trackingState)
        // Projection/raycast and SwiftUI updates are bounded to about 8 Hz.
        guard frame.timestamp - lastFrameTime >= 0.12 else { return }
        lastFrameTime = frame.timestamp
        guard trackingNormal, !interrupted else { return }
        if !hasPlacement {
            let found = floorHit(in: view) != nil
            if surfaceFound != found { surfaceFound = found }
            return
        }
        guard anchorEntity?.isAnchored == true else {
            if !labels.isEmpty { labels = [] }
            return
        }
        let next = markerEntities.compactMap { marker -> MarkerLabel? in
            let position = marker.entity.position(relativeTo: nil) + SIMD3<Float>(0, 0.10, 0)
            let cameraPosition = simd_inverse(frame.camera.transform) * SIMD4<Float>(position, 1)
            guard cameraPosition.z < -0.01,
                  let point = view.project(position), point.x.isFinite, point.y.isFinite,
                  view.bounds.insetBy(dx: 20, dy: 20).contains(point) else { return nil }
            let name = StudioDisplayName.label(marker.item.name, fallback: marker.item.role.rawValue.capitalized)
            return MarkerLabel(id: marker.item.id, title: name, point: point)
        }
        if next != labels { labels = next }
    }

    fileprivate func updateTracking(_ state: ARCamera.TrackingState) {
        guard phase == .running else { return }
        let normal: Bool
        let message: String
        switch state {
        case .normal:
            normal = !interrupted
            message = "Tracking is available."
        case .notAvailable:
            normal = false
            message = "Tracking is unavailable. Markers are hidden. Reset or use manual measurements."
        case .limited(let reason):
            normal = false
            switch reason {
            case .initializing: message = "Move slowly while the camera maps the room. Markers are hidden until tracking recovers."
            case .excessiveMotion: message = "Slow down and hold the device steady. Markers are hidden while tracking is limited."
            case .insufficientFeatures: message = "Aim at a textured, well-lit area. Markers are hidden while tracking is limited."
            case .relocalizing: message = "Return to the area you scanned and move slowly. Reset if tracking cannot recover. Markers are hidden."
            @unknown default: message = "Tracking is limited. Move slowly, or reset and scan the floor again. Markers are hidden."
            }
        }
        if !normal {
            if hasPlacement && !needsPlacementReview { needsPlacementReview = true }
            if surfaceFound { surfaceFound = false }
            if !labels.isEmpty { labels = [] }
        }
        if trackingNormal != normal { trackingNormal = normal }
        if trackingMessage != message { trackingMessage = message }
        rigRoot?.isEnabled = normal
    }

    fileprivate func interruptionBegan() {
        guard phase == .running else { return }
        interrupted = true
        updateTracking(.notAvailable)
        trackingMessage = "The camera session was interrupted. Markers are hidden. Return to the scanned area when the camera resumes, or reset."
    }

    fileprivate func interruptionEnded() {
        guard phase == .running else { return }
        interrupted = false
        updateTracking(.limited(.relocalizing))
    }

    fileprivate func sessionFailed() {
        guard phase == .running else { return }
        stop()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied: phase = .denied
        case .restricted: phase = .restricted
        default: phase = .failed
        }
    }

    fileprivate func anchorsRemoved(_ anchors: [ARAnchor]) {
        guard let floorAnchor,
              anchors.contains(where: { $0.identifier == floorAnchor.identifier }) else { return }
        // The session has already removed it; avoid requesting removal again.
        self.floorAnchor = nil
        clearPlacement()
        surfaceFound = false
        placementError = "The floor anchor was lost. Scan the floor and place the subject again."
    }
}

/// ARSession callbacks are explicitly delivered on DispatchQueue.main. The
/// bridge enters that actor synchronously, without retaining frames in tasks.
private final class PlacementSessionDelegate: NSObject, ARSessionDelegate {
    private weak var owner: ARPlacementController?
    private let generation: Int

    init(owner: ARPlacementController, generation: Int) {
        self.owner = owner
        self.generation = generation
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        MainActor.assumeIsolated {
            guard owner?.owns(session, generation: generation) == true else { return }
            owner?.process(frame: frame, session: session)
        }
    }
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        MainActor.assumeIsolated {
            guard owner?.owns(session, generation: generation) == true else { return }
            owner?.updateTracking(camera.trackingState)
        }
    }
    func sessionWasInterrupted(_ session: ARSession) {
        MainActor.assumeIsolated {
            guard owner?.owns(session, generation: generation) == true else { return }
            owner?.interruptionBegan()
        }
    }
    func sessionInterruptionEnded(_ session: ARSession) {
        MainActor.assumeIsolated {
            guard owner?.owns(session, generation: generation) == true else { return }
            owner?.interruptionEnded()
        }
    }
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        MainActor.assumeIsolated { owner?.owns(session, generation: generation) == true }
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            guard owner?.owns(session, generation: generation) == true else { return }
            owner?.sessionFailed()
        }
    }
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        MainActor.assumeIsolated {
            guard owner?.owns(session, generation: generation) == true else { return }
            owner?.anchorsRemoved(anchors)
        }
    }
}
