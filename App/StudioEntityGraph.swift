import RealityKit
import UIKit
import LightingCore
import simd

/// Owns persistent geometry in world meters. Updates mutate transforms,
/// materials and light components; only UUID insertion/removal changes the rig.
@MainActor
final class StudioEntityGraph {
    // Reserve one of the baseline eight dynamic lights for neutral studio fill.
    // All authored fixtures remain visible/selectable beyond this shading limit.
    static let maximumShadedLights = 7
    let anchor = AnchorEntity(world: .zero)
    private let resources = StudioGeometryResources()
    private let subject = Entity()
    private let cameraBody = Entity()
    private let floor: ModelEntity
    private var grid: [ModelEntity] = []
    private var lights: [UUID: StudioLampEntity] = [:]
    private var lightRoots: [ObjectIdentifier: UUID] = [:]
    private var lastScene: LightingScene?
    private var lastSelection: UUID?

    init() {
        floor = resources.box(color: UIColor(white: 0.19, alpha: 1))
        anchor.name = "Studio geometry in meters"
        anchor.addChild(floor)
        anchor.addChild(subject)
        anchor.addChild(cameraBody)

        let head = resources.sphere(color: UIColor(white: 0.65, alpha: 1))
        head.scale = [0.34, 0.43, 0.32]
        subject.addChild(head)
        let neck = resources.sphere(color: UIColor(white: 0.59, alpha: 1))
        neck.scale = [0.14, 0.24, 0.14]
        neck.position = [0, -0.25, 0]
        subject.addChild(neck)
        let torso = resources.sphere(color: UIColor(white: 0.39, alpha: 1))
        torso.scale = [0.58, 0.74, 0.3]
        torso.position = [0, -0.58, 0]
        subject.addChild(torso)
        let nose = resources.sphere(color: UIColor(white: 0.65, alpha: 1))
        nose.scale = [0.055, 0.075, 0.075]
        nose.position = [0, -0.02, 0.155]
        subject.addChild(nose)

        let body = resources.box(color: UIColor(white: 0.3, alpha: 1))
        body.scale = [0.26, 0.17, 0.14]
        cameraBody.addChild(body)
        let lens = resources.box(color: UIColor(white: 0.12, alpha: 1))
        lens.scale = [0.095, 0.095, 0.12]
        lens.position = [0, 0, -0.11]
        cameraBody.addChild(lens)

        // A restrained fill keeps equipment readable when authored lights are
        // off. It is display lighting and is never included in meter values.
        let fill = DirectionalLight()
        fill.light.color = .white
        fill.light.intensity = 180
        anchor.addChild(fill)
        fill.look(at: .zero, from: [-3, 6, 4], relativeTo: nil)
        for _ in 0..<42 {
            let line = resources.box(color: UIColor(white: 0.23, alpha: 1), unlit: true)
            grid.append(line)
            anchor.addChild(line)
        }
    }

    func update(scene: LightingScene, selected: UUID?) {
        guard let bounds = try? StudioSceneBounds(scene: scene) else {
            anchor.isEnabled = false
            for lamp in lights.values { lamp.root.removeFromParent() }
            lights.removeAll()
            lightRoots.removeAll()
            lastScene = nil
            lastSelection = nil
            return
        }
        anchor.isEnabled = true
        guard scene != lastScene || selected != lastSelection else { return }

        if scene != lastScene {
            subject.position = vector(scene.subject)
            let facing = vector(scene.camera) - vector(scene.subject)
            if hypot(facing.x, facing.z) > 0.0001 {
                subject.orientation = simd_quatf(angle: atan2(facing.x, facing.z), axis: [0, 1, 0])
            } else {
                subject.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            }
            cameraBody.position = vector(scene.camera)
            if let framing = CameraFraming(scene: scene) {
                cameraBody.look(at: vector(framing.target), from: vector(framing.position),
                                upVector: vector(framing.up), relativeTo: nil)
            } else {
                cameraBody.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            }
            updateFloor(bounds: bounds)
        }

        let ids = Set(scene.lights.map(\.id))
        for id in Array(lights.keys) where !ids.contains(id) {
            guard let removed = lights.removeValue(forKey: id) else { continue }
            lightRoots.removeValue(forKey: ObjectIdentifier(removed.root))
            removed.root.removeFromParent()
        }
        var shadedCount = 0
        for light in scene.lights {
            let lamp: StudioLampEntity
            if let existing = lights[light.id] {
                lamp = existing
            } else {
                lamp = StudioLampEntity(id: light.id, resources: resources)
                lights[light.id] = lamp
                lightRoots[ObjectIdentifier(lamp.root)] = light.id
                anchor.addChild(lamp.root)
            }
            let canEmit = light.candela > 0 && (!light.effectiveOptics.kind.isAimed ||
                                              StudioPhotometry.frame(for: light, subject: scene.subject) != nil)
            let shades = canEmit && shadedCount < Self.maximumShadedLights
            if shades { shadedCount += 1 }
            lamp.update(light: light, subject: scene.subject, selected: selected == light.id, shades: shades)
        }
        lastScene = scene
        lastSelection = selected
    }

    func lightID(for entity: Entity) -> UUID? {
        guard lastScene != nil, anchor.isEnabled else { return nil }
        var current: Entity? = entity
        while let item = current {
            guard item.isEnabled else { return nil }
            if let id = lightRoots[ObjectIdentifier(item)],
               lights[id]?.root === item, item.parent === anchor { return id }
            current = item.parent
        }
        return nil
    }

    private func updateFloor(bounds: StudioSceneBounds) {
        let center = vector(bounds.center)
        let span = max(8, Float(max(bounds.maximum.x - bounds.minimum.x,
                                   bounds.maximum.z - bounds.minimum.z)) + 6)
        floor.scale = [span, 0.04, span]
        floor.position = [center.x, -0.025, center.z]
        let step = max(1, ceil(span / 20))
        let gridCenterX = (center.x / step).rounded() * step
        let gridCenterZ = (center.z / step).rounded() * step
        for index in 0..<21 {
            let offset = Float(index - 10) * step
            let xLine = grid[index * 2]
            xLine.position = [gridCenterX + offset, -0.003, center.z]
            xLine.scale = [0.007, 0.002, span]
            xLine.isEnabled = abs(xLine.position.x - center.x) <= span / 2
            let zLine = grid[index * 2 + 1]
            zLine.position = [center.x, -0.003, gridCenterZ + offset]
            zLine.scale = [span, 0.002, 0.007]
            zLine.isEnabled = abs(zLine.position.z - center.z) <= span / 2
        }
    }

    private func vector(_ position: Position) -> SIMD3<Float> {
        [Float(position.x), Float(position.y), Float(position.z)]
    }
    private func vector(_ direction: UnitDirection) -> SIMD3<Float> {
        [Float(direction.x), Float(direction.y), Float(direction.z)]
    }
}

@MainActor
private final class StudioGeometryResources {
    let boxMesh = MeshResource.generateBox(size: 1)
    let sphereMesh = MeshResource.generateSphere(radius: 0.5)
    let boxShape = ShapeResource.generateBox(size: SIMD3<Float>(repeating: 1))
    let sphereShape = ShapeResource.generateSphere(radius: 0.5)
    let selectionColor = UIColor(red: 1, green: 0.70, blue: 0.29, alpha: 1)

    func box(color: UIColor, unlit: Bool = false, selectable: Bool = false) -> ModelEntity {
        let entity = ModelEntity(mesh: boxMesh, materials: [material(color: color, unlit: unlit)])
        if selectable { entity.collision = CollisionComponent(shapes: [boxShape]) }
        return entity
    }

    func sphere(color: UIColor, selectable: Bool = false) -> ModelEntity {
        let entity = ModelEntity(mesh: sphereMesh, materials: [material(color: color)])
        if selectable { entity.collision = CollisionComponent(shapes: [sphereShape]) }
        return entity
    }

    func material(color: UIColor, unlit: Bool = false) -> any Material {
        if unlit { return UnlitMaterial(color: color) }
        return SimpleMaterial(color: color, roughness: 0.78, isMetallic: false)
    }
}

@MainActor
private final class StudioLampEntity {
    let root = Entity()
    private let fixture = Entity()
    private let emission = Entity()
    private let selection = Entity()
    private let point: ModelEntity
    private let housing: ModelEntity
    private let face: ModelEntity
    private let stand: ModelEntity
    private let footX: ModelEntity
    private let footZ: ModelEntity
    private let aimLine: ModelEntity
    private let aimTarget: ModelEntity
    private var outline: [ModelEntity] = []
    private let resources: StudioGeometryResources
    private var lastLight: StudioLight?
    private var lastSubject: Position?
    private var lastSelected = false
    private var lastShades = false
    private var hasAimGeometry = false

    init(id: UUID, resources: StudioGeometryResources) {
        self.resources = resources
        let dark = UIColor(white: 0.25, alpha: 1)
        point = resources.sphere(color: dark, selectable: true)
        housing = resources.box(color: dark, selectable: true)
        face = resources.box(color: .white)
        stand = resources.box(color: UIColor(white: 0.32, alpha: 1), selectable: true)
        footX = resources.box(color: dark, selectable: true)
        footZ = resources.box(color: dark, selectable: true)
        aimLine = resources.box(color: resources.selectionColor, unlit: true)
        aimTarget = resources.sphere(color: resources.selectionColor)
        root.name = "Studio light \(id.uuidString)"
        root.addChild(fixture)
        root.addChild(stand)
        root.addChild(footX)
        root.addChild(footZ)
        root.addChild(aimLine)
        root.addChild(aimTarget)
        fixture.addChild(point)
        fixture.addChild(housing)
        fixture.addChild(face)
        fixture.addChild(selection)
        fixture.addChild(emission)
        // Core emitter frames point along +Z; RealityKit spotlights emit -Z.
        emission.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        for _ in 0..<12 {
            let edge = resources.box(color: resources.selectionColor, unlit: true)
            outline.append(edge)
            selection.addChild(edge)
        }
    }

    func update(light: StudioLight, subject: Position, selected: Bool, shades: Bool) {
        guard light != lastLight || subject != lastSubject || selected != lastSelected || shades != lastShades else { return }
        let optics = light.effectiveOptics
        let frame = StudioPhotometry.frame(for: light, subject: subject)
        let geometryChanged = light.position != lastLight?.position || optics != lastLight?.effectiveOptics || subject != lastSubject
        // Display names do not change meshes, materials or light components.
        let sourceChanged = geometryChanged || light.candela != lastLight?.candela ||
            light.kelvin != lastLight?.kelvin || shades != lastShades
        if geometryChanged {
            let position = vector(light.position)
            root.position = position
            // This basis carries the exact authored roll, including vertical
            // aims, without look-at singularities or a second roll operation.
            fixture.orientation = frame.map {
                simd_quatf(simd_float3x3(columns: (vector($0.right), vector($0.up), vector($0.normal))))
            } ?? simd_quatf(angle: 0, axis: [0, 1, 0])
            let isPoint = optics.kind == .point
            point.isEnabled = isPoint
            housing.isEnabled = !isPoint
            face.isEnabled = !isPoint && frame != nil
            point.scale = [0.16, 0.16, 0.16]
            let width: Float = optics.kind == .rectangle ? Float(optics.widthMeters) : 0.22
            let height: Float = optics.kind == .rectangle ? Float(optics.heightMeters) : 0.18
            housing.scale = [width, height, 0.08]
            // Stop the housing behind the diffuser to avoid coplanar surfaces.
            housing.position = [0, 0, -0.046]
            // Rectangle dimensions describe the full emitting area.
            face.scale = optics.kind == .rectangle ? [width, height, 0.006] :
                [max(0.01, width - 0.012), max(0.01, height - 0.012), 0.006]
            // The emitting face is exactly at the authored position, z = 0.
            face.position = [0, 0, -0.003]
            selection.position = isPoint ? .zero : [0, 0, -0.043]
            updateOutline(size: isPoint ? [0.22, 0.22, 0.22] : [width + 0.04, height + 0.04, 0.12])

            let hasStand = position.y > 0.05
            stand.isEnabled = hasStand
            footX.isEnabled = hasStand
            footZ.isEnabled = hasStand
            stand.scale = [0.024, max(0.01, position.y), 0.024]
            stand.position = [0, -position.y / 2, 0]
            footX.scale = [0.45, 0.025, 0.035]
            footZ.scale = [0.035, 0.025, 0.45]
            footX.position = [0, -position.y + 0.014, 0]
            footZ.position = footX.position

            let delta = vector(light.target(subject: subject)) - position
            let length = simd_length(delta)
            // A finite core frame can exist even when source and target are
            // too close to form a visible Float-space segment. Hide both aim
            // markers then, including after an earlier, longer aim was cached.
            hasAimGeometry = frame != nil && length > 0.0001
            if hasAimGeometry {
                aimLine.position = delta / 2
                aimLine.scale = [0.005, length, 0.005]
                aimLine.orientation = simd_quatf(from: [0, 1, 0], to: delta / length)
                aimTarget.position = delta
                aimTarget.scale = SIMD3<Float>(repeating: Float(2 * SpatialViewportBounds.aimTargetRadiusMeters))
            }
        }
        selection.isEnabled = selected
        aimLine.isEnabled = selected && hasAimGeometry
        aimTarget.isEnabled = selected && hasAimGeometry
        if sourceChanged {
            let color = sourceColor(kelvin: light.kelvin)
            let active = light.candela > 0 && (!optics.kind.isAimed || frame != nil)
            let material = resources.material(color: active ? color : UIColor(white: 0.26, alpha: 1), unlit: active)
            face.model?.materials = [material]
            point.model?.materials = [material]
            // Deliberate display mapping, NOT a candela-to-lumen calibration.
            // Rectangles use a broad spotlight, not area-source soft shadows.
            let intensity = Float(min(4_000, light.candela * 2))
            let radius = Float(min(350, max(12, light.position.distance(to: subject) * 2 + 4)))
            if shades, optics.kind == .point {
                emission.components.remove(SpotLightComponent.self)
                var source = PointLightComponent()
                source.color = color
                source.intensity = intensity
                source.attenuationRadius = radius
                emission.components.set(source)
            } else if shades, frame != nil {
                emission.components.remove(PointLightComponent.self)
                var source = SpotLightComponent()
                source.color = color
                source.intensity = intensity
                source.innerAngleInDegrees = 35
                source.outerAngleInDegrees = 85
                source.attenuationRadius = radius
                emission.components.set(source)
            } else {
                emission.components.remove(PointLightComponent.self)
                emission.components.remove(SpotLightComponent.self)
            }
        }
        lastLight = light
        lastSubject = subject
        lastSelected = selected
        lastShades = shades
    }

    private func updateOutline(size: SIMD3<Float>) {
        var index = 0
        for axis in 0..<3 {
            let otherA = (axis + 1) % 3
            let otherB = (axis + 2) % 3
            for signA in [Float(-1), Float(1)] {
                for signB in [Float(-1), Float(1)] {
                    var scale = SIMD3<Float>(repeating: 0.009)
                    var position = SIMD3<Float>.zero
                    scale[axis] = size[axis]
                    position[otherA] = signA * size[otherA] / 2
                    position[otherB] = signB * size[otherB] / 2
                    outline[index].scale = scale
                    outline[index].position = position
                    index += 1
                }
            }
        }
    }

    private func sourceColor(kelvin: Double) -> UIColor {
        guard let xyz = PreviewColorimetry.blackbody(kelvin: kelvin),
              let rgb = PreviewColorimetry.display(xyz, settings: .init(whiteBalanceKelvin: 5600)) else { return .white }
        return UIColor(red: CGFloat(rgb.red), green: CGFloat(rgb.green), blue: CGFloat(rgb.blue), alpha: 1)
    }

    private func vector(_ position: Position) -> SIMD3<Float> {
        [Float(position.x), Float(position.y), Float(position.z)]
    }
    private func vector(_ direction: UnitDirection) -> SIMD3<Float> {
        [Float(direction.x), Float(direction.y), Float(direction.z)]
    }
}
