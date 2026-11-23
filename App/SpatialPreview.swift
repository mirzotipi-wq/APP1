import SwiftUI
import SceneKit
import LightingCore

/// Temporary illustrative renderer; SceneKit intensity and spotlight cones are
/// not calibrated candela or area-source shading. Emitter geometry uses world meters.
struct SpatialPreview: UIViewRepresentable {
    let scene: LightingScene

    final class Coordinator {
        let content = SCNNode()
        var lastScene: LightingScene?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero, options: nil)
        let world = SCNScene()
        world.background.contents = UIColor(red: 0.075, green: 0.085, blue: 0.10, alpha: 1)
        view.scene = world
        let camera = SCNNode()
        camera.camera = SCNCamera(); camera.camera?.fieldOfView = 48
        camera.position = SCNVector3(4, 3, 6); world.rootNode.addChildNode(camera)
        camera.look(at: SCNVector3(0, 1.15, 0))
        world.rootNode.addChildNode(context.coordinator.content)
        view.pointOfView = camera
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling2X
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        let coordinator = context.coordinator
        guard coordinator.lastScene != scene else { return }
        // Keep the viewport and orbit controller alive during edits; replace only content.
        let root = coordinator.content
        root.childNodes.forEach { $0.removeFromParentNode() }
        populate(root)
        coordinator.lastScene = scene
    }

    private func vector(_ p: Position) -> SCNVector3 { SCNVector3(Float(p.x), Float(p.y), Float(p.z)) }
    private func vector(_ d: UnitDirection) -> SCNVector3 { SCNVector3(Float(d.x), Float(d.y), Float(d.z)) }
    private func object(_ g: SCNGeometry, color: UIColor, at p: SCNVector3, in root: SCNNode) -> SCNNode {
        g.firstMaterial?.diffuse.contents = color
        g.firstMaterial?.lightingModel = .blinn
        let node = SCNNode(geometry: g); node.position = p; root.addChildNode(node)
        return node
    }

    private func populate(_ root: SCNNode) {
        let floor = SCNFloor(); floor.reflectivity = 0
        _ = object(floor, color: UIColor(white: 0.19, alpha: 1), at: SCNVector3Zero, in: root)
        let p = vector(scene.subject)
        _ = object(SCNSphere(radius: 0.19), color: UIColor(red: 0.62, green: 0.48, blue: 0.39, alpha: 1), at: p, in: root)
        let torso = object(SCNCapsule(capRadius: 0.23, height: 0.76), color: UIColor(white: 0.37, alpha: 1),
                           at: SCNVector3(p.x, p.y - 0.55, p.z), in: root)
        torso.scale = SCNVector3(1.2, 1, 0.65)
        let ambient = SCNNode()
        ambient.light = SCNLight(); ambient.light?.type = .ambient; ambient.light?.intensity = 90
        root.addChildNode(ambient)
        _ = object(SCNBox(width: 0.26, height: 0.18, length: 0.18, chamferRadius: 0.02),
                   color: .darkGray, at: vector(scene.camera), in: root)
        for light in scene.lights {
            let optics = light.effectiveOptics
            let pos = vector(light.position)
            let frame = StudioPhotometry.frame(for: light, subject: scene.subject)
            let target = vector(light.target(subject: scene.subject))
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
                    emitter.look(at: target, up: vector(frame.up), localFront: SCNVector3(0, 0, -1))
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
            if let frame { fixture.look(at: target, up: vector(frame.up), localFront: SCNVector3(0, 0, 1)) }
            // Keep equipment readable, but do not imply a powered-off fixture is emitting light.
            if light.candela > 0 && (!optics.kind.isAimed || frame != nil) {
                fixture.geometry?.firstMaterial?.emission.contents = UIColor.systemOrange.withAlphaComponent(0.35)
            }
            if pos.y > 0.05 {
                _ = object(SCNCylinder(radius: 0.015, height: CGFloat(pos.y)), color: .gray,
                           at: SCNVector3(pos.x, pos.y / 2, pos.z), in: root)
            }
        }
    }
}
