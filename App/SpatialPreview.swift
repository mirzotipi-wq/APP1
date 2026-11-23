import SwiftUI
import SceneKit
import LightingCore

/// Temporary illustrative renderer; SceneKit intensity is not calibrated candela.
struct SpatialPreview: View {
    let scene: LightingScene
    var body: some View { SceneView(scene: makeScene(), options: [.allowsCameraControl]) }
    private func vector(_ p: Position) -> SCNVector3 { SCNVector3(Float(p.x), Float(p.y), Float(p.z)) }
    private func object(_ g: SCNGeometry, color: UIColor, at p: SCNVector3, in world: SCNScene) -> SCNNode {
        g.firstMaterial?.diffuse.contents = color
        g.firstMaterial?.lightingModel = .blinn
        let node = SCNNode(geometry: g); node.position = p; world.rootNode.addChildNode(node)
        return node
    }
    private func makeScene() -> SCNScene {
        let world = SCNScene()
        world.background.contents = UIColor(red: 0.075, green: 0.085, blue: 0.10, alpha: 1)
        let camera = SCNNode()
        camera.camera = SCNCamera(); camera.camera?.fieldOfView = 48
        camera.position = SCNVector3(4, 3, 6); world.rootNode.addChildNode(camera)
        camera.look(at: SCNVector3(0, 1.15, 0))
        _ = object(SCNFloor(), color: UIColor(white: 0.19, alpha: 1), at: SCNVector3Zero, in: world)
        let p = vector(scene.subject)
        _ = object(SCNSphere(radius: 0.19), color: UIColor(red: 0.62, green: 0.48, blue: 0.39, alpha: 1), at: p, in: world)
        let torso = object(SCNCapsule(capRadius: 0.23, height: 0.76), color: UIColor(white: 0.37, alpha: 1),
                           at: SCNVector3(p.x, p.y - 0.55, p.z), in: world)
        torso.scale = SCNVector3(1.2, 1, 0.65)
        let ambient = SCNNode()
        ambient.light = SCNLight(); ambient.light?.type = .ambient; ambient.light?.intensity = 90
        world.rootNode.addChildNode(ambient)
        _ = object(SCNBox(width: 0.26, height: 0.18, length: 0.18, chamferRadius: 0.02),
                   color: .darkGray, at: vector(scene.camera), in: world)
        for light in scene.lights {
            let pos = vector(light.position)
            let emitter = SCNNode(); emitter.position = pos
            emitter.light = SCNLight(); emitter.light?.type = .omni
            emitter.light?.temperature = CGFloat(light.kelvin)
            emitter.light?.intensity = CGFloat(min(4000, light.candela * 1.5))
            emitter.light?.attenuationStartDistance = 0; emitter.light?.attenuationEndDistance = 10
            world.rootNode.addChildNode(emitter)
            let fixture = object(SCNSphere(radius: 0.09), color: .systemOrange, at: pos, in: world)
            fixture.geometry?.firstMaterial?.emission.contents = UIColor.systemOrange
            if pos.y > 0.05 {
                _ = object(SCNCylinder(radius: 0.015, height: CGFloat(pos.y)), color: .gray,
                           at: SCNVector3(pos.x, pos.y / 2, pos.z), in: world)
            }
        }
        return world
    }
}
