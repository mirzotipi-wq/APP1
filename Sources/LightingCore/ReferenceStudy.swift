import Foundation

public enum StudyQuality: Sendable {
    /// 8×8 midpoint samples per rectangle. Intended for a small diagnostic image.
    case interactive
    /// 32×32 midpoint samples per rectangle, matching the diagnostic meter for fully
    /// front-facing receivers. The meter clips partial faces at grazing incidence;
    /// this precomputed, occlusion-capable renderer retains its fixed sample grid.
    case reference
    fileprivate var grid: Int { self == .interactive ? 8 : 32 }
}

public enum StudyError: Error, Equatable {
    case invalidScene, invalidCamera, invalidEmitter, invalidResolution, invalidSurface, invalidComputeOutput, cancelled
}

/// Achromatic, spectrally flat materials. Dielectric uses a direct-light GGX/Smith/Schlick
/// approximation; no measured skin/fabric, subsurface, multi-scattering or indirect lighting.
public enum StudyMaterial: Equatable, Sendable {
    case diffuse(reflectance: Double)
    case dielectric(reflectance: Double, roughness: Double, f0: Double)

    fileprivate var isValid: Bool {
        switch self {
        case .diffuse(let r): return r.isFinite && (0...1).contains(r)
        case .dielectric(let r, let rough, let f0):
            return r.isFinite && (0...1).contains(r) && rough.isFinite && (0.05...1).contains(rough) && f0.isFinite && (0...0.08).contains(f0)
        }
    }

    /// Returns π·BRDF, making a pure diffuse material equal to its reflectance.
    /// The caller supplies incident irradiance (lux), including N·L.
    fileprivate func response(normal n: SIMD3<Double>, light l: SIMD3<Double>, view v: SIMD3<Double>, nl: Double) -> Double {
        switch self {
        case .diffuse(let r): return r
        case .dielectric(let r, let rough, let f0):
            let nv = max(0, dot3(n, v))
            guard nv > 0, let h = normalized3(l + v) else { return 0 }
            let nh = min(1, max(0, dot3(n, h)))
            let vh = min(1, max(0, dot3(v, h)))
            let alpha = rough * rough, a2 = alpha * alpha
            let d = nh * nh * (a2 - 1) + 1
            let distributionTimesPi = a2 / (d * d)
            // Height-correlated Smith visibility: stable at grazing angles.
            let denominator = 2 * (nl * sqrt(nv * nv * (1 - a2) + a2) + nv * sqrt(nl * nl * (1 - a2) + a2))
            let fresnel = f0 + (1 - f0) * pow(1 - vh, 5)
            let specular = denominator > 0 ? distributionTimesPi * fresnel / denominator : 0
            return r * (1 - fresnel) + specular
        }
    }
}

/// Diagnostic geometry: neutral sphere resting on a finite horizontal reference panel.
/// This plane is at subject height minus radius; it is not the actual room floor.
public struct StudyGeometry: Equatable, Sendable {
    public let center: Position
    public let radius: Double
    public let panelHalfExtent: Double
    public var panelY: Double { center.y - radius }

    public init?(center: Position, radius: Double = 0.22, panelHalfExtent: Double = 3) {
        guard center.isValid, radius.isFinite, (0.05...1).contains(radius),
              panelHalfExtent.isFinite, (1...10).contains(panelHalfExtent), panelHalfExtent >= radius else { return nil }
        self.center = center; self.radius = radius; self.panelHalfExtent = panelHalfExtent
    }

    fileprivate func inPanel(_ p: SIMD3<Double>) -> Bool {
        abs(p.x - center.x) <= panelHalfExtent && abs(p.z - center.z) <= panelHalfExtent
    }

    /// Positive ray/sphere intersection; a receiver's shadow ray is offset separately.
    fileprivate func sphereHit(origin: SIMD3<Double>, direction: SIMD3<Double>, minimum: Double) -> Double? {
        let offset = origin - vec(center)
        let b = dot3(offset, direction), c = dot3(offset, offset) - radius * radius
        let discriminant = b * b - c
        guard discriminant >= 0 else { return nil }
        let root = sqrt(discriminant)
        let near = -b - root, far = -b + root
        if near >= minimum { return near }
        if far >= minimum { return far }
        return nil
    }

    fileprivate func occludes(from origin: SIMD3<Double>, to direction: SIMD3<Double>, distance: Double) -> Bool {
        let epsilon = 1e-5
        if let hit = sphereHit(origin: origin, direction: direction, minimum: epsilon), hit < distance - epsilon { return true }
        if abs(direction.y) > 1e-12 {
            let t = (panelY - origin.y) / direction.y
            if t >= epsilon, t < distance - epsilon, inPanel(origin + direction * t) { return true }
        }
        return false
    }
}

public struct StudySurfaceSignal: Equatable, Sendable {
    /// Incident illuminance including visibility, before any material or exposure.
    public let visibleLux: Double
    public let unoccludedLux: Double
    /// Relative scene-linear XYZ; π·outgoing radiance / 1000 lx reference.
    public let signalXYZ: RelativeXYZ
}

/// Prepared light samples are shared across surface evaluations. Rectangular sources
/// use area-weighted midpoint samples; sample intensity sums to on-axis candela.
public struct StudyLighting: Sendable {
    private struct Sample: Sendable {
        let position: SIMD3<Double>
        let emittingNormal: SIMD3<Double>?
        let candela: Double
        let xyz: SIMD3<Double>
    }
    private struct AreaGuard: Sendable {
        let center: SIMD3<Double>
        let right: SIMD3<Double>
        let up: SIMD3<Double>
        let halfWidth: Double
        let halfHeight: Double
        let minimumDistance: Double

        func containsNearReceiver(_ p: SIMD3<Double>) -> Bool {
            let delta = p - center
            let x = min(halfWidth, max(-halfWidth, dot3(delta, right)))
            let y = min(halfHeight, max(-halfHeight, dot3(delta, up)))
            let separation = delta - right * x - up * y
            return dot3(separation, separation) < minimumDistance * minimumDistance
        }
    }
    private let samples: [Sample]
    private let areaGuards: [AreaGuard]

    public init(scene: LightingScene, quality: StudyQuality = .interactive) throws {
        guard (try? scene.validated()) != nil else { throw StudyError.invalidScene }
        var result: [Sample] = []
        var guards: [AreaGuard] = []
        for light in scene.lights where light.candela > 0 {
            guard let color = PreviewColorimetry.blackbody(kelvin: light.kelvin) else { throw StudyError.invalidEmitter }
            let xyz = SIMD3<Double>(color.x, color.y, color.z)
            let optics = light.effectiveOptics, center = vec(light.position)
            if optics.kind == .point {
                result.append(.init(position: center, emittingNormal: nil, candela: light.candela, xyz: xyz))
            } else {
                guard let frame = StudioPhotometry.frame(for: light, subject: scene.subject) else { throw StudyError.invalidEmitter }
                let axis = vec(frame.normal)
                if optics.kind == .directional {
                    result.append(.init(position: center, emittingNormal: axis, candela: light.candela, xyz: xyz))
                } else {
                    let grid = quality.grid, right = vec(frame.right), up = vec(frame.up)
                    let perCell = light.candela / Double(grid * grid)
                    guards.append(.init(center: center, right: right, up: up,
                                        halfWidth: optics.widthMeters / 2, halfHeight: optics.heightMeters / 2,
                                        minimumDistance: max(0.05, max(optics.widthMeters, optics.heightMeters) / 4)))
                    for row in 0..<grid {
                        let y = ((Double(row) + 0.5) / Double(grid) - 0.5) * optics.heightMeters
                        for col in 0..<grid {
                            let x = ((Double(col) + 0.5) / Double(grid) - 0.5) * optics.widthMeters
                            result.append(.init(position: center + right * x + up * y, emittingNormal: axis, candela: perCell, xyz: xyz))
                        }
                    }
                }
            }
        }
        samples = result; areaGuards = guards
    }

    public var sampleCount: Int { samples.count }

    // Structure-of-vectors contract: three aligned float4 rows per sample and area.
    // Translate positions to the subject center to reduce Float32 roundoff.
    fileprivate func computeSamples(relativeTo center: SIMD3<Double>) -> [SIMD4<Float>] {
        samples.flatMap { s in
            [pack(s.position - center, s.candela), pack(s.emittingNormal ?? .zero, s.emittingNormal == nil ? 0 : 1), pack(s.xyz, 0)]
        }
    }

    fileprivate func computeAreas(relativeTo center: SIMD3<Double>) -> [SIMD4<Float>] {
        areaGuards.flatMap { a in
            [pack(a.center - center, a.minimumDistance), pack(a.right, a.halfWidth), pack(a.up, a.halfHeight)]
        }
    }

    /// Evaluates one arbitrary receiver. Geometry nil means no visibility/occlusion.
    /// A point sample nearer than 5 cm, or a receiver within the declared finite-area
    /// near-field guard (max of 5 cm and one quarter longest side), is unsupported.
    public func evaluate(receiver: Position, normal: UnitDirection, view: UnitDirection,
                         material: StudyMaterial, geometry: StudyGeometry? = nil) throws -> StudySurfaceSignal {
        guard receiver.isValid, material.isValid, dot3(vec(normal), vec(view)) > 0 else { throw StudyError.invalidSurface }
        return try evaluate(receiver: vec(receiver), normal: vec(normal), view: vec(view), material: material, geometry: geometry)
    }

    /// Internal direct-light evaluator shared by the sphere and mannequin
    /// diagnostics. The additional visibility function is CPU-only; the sphere
    /// and its fixed-grid Metal oracle retain the original sampling contract.
    func evaluate(receiver: SIMD3<Double>, normal: SIMD3<Double>, view: SIMD3<Double>,
                  material: StudyMaterial, geometry: StudyGeometry? = nil,
                  occlusionTest: ((SIMD3<Double>, SIMD3<Double>, Double) -> Bool)? = nil,
                  geometricNormal: SIMD3<Double>? = nil) throws -> StudySurfaceSignal {
        if areaGuards.contains(where: { $0.containsNearReceiver(receiver) }) { throw StudyError.invalidSurface }
        var total = 0.0, visible = 0.0, xyz = SIMD3<Double>.zero
        let shadowOrigin = receiver + (geometricNormal ?? normal) * 1e-5
        for sample in samples {
            let delta = sample.position - receiver
            let r2 = dot3(delta, delta)
            guard r2 >= 0.0025 else { throw StudyError.invalidSurface }
            let distance = sqrt(r2), wi = delta / distance
            // Mesh shading normals must not admit light from below the actual face.
            // Analytic sphere and planar receivers retain their original path.
            if let geometricNormal, dot3(geometricNormal, wi) <= 0 { continue }
            let nl = min(1, max(0, dot3(normal, wi)))
            if nl == 0 { continue }
            let emitted = sample.emittingNormal.map { min(1, max(0, -dot3($0, wi))) } ?? 1
            if emitted == 0 { continue }
            let lux = sample.candela * emitted * nl / r2
            total += lux
            // Offset origin while keeping the shadow ray aimed at the actual source sample.
            if geometry != nil || occlusionTest != nil {
                let segment = sample.position - shadowOrigin
                let length = sqrt(dot3(segment, segment))
                let shadowDirection = segment / length
                if geometry?.occludes(from: shadowOrigin, to: shadowDirection, distance: length) == true ||
                    occlusionTest?(shadowOrigin, shadowDirection, length) == true { continue }
            }
            visible += lux
            let scale = lux * material.response(normal: normal, light: wi, view: view, nl: nl) / 1000
            xyz += sample.xyz * scale
        }
        return .init(visibleLux: visible, unoccludedLux: total, signalXYZ: .init(x: xyz.x, y: xyz.y, z: xyz.z))
    }
}

/// Packed, opaque RGBA8, top-to-bottom rows, 3:2 frame. Invalid near-emitter
/// receivers are marked diagnostic magenta and counted, never passed off as shadows.
public struct StudyImage: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let rgba: Data
    public let unsupportedPixels: Int

    /// Compute buffer uses alpha 0 exclusively as an invalid-surface flag. Restore
    /// opaque alpha and count flags, without guessing from the visible RGB color.
    public static func fromComputeRGBA(width: Int, height: Int, data: Data) throws -> StudyImage {
        guard (24...192).contains(width), width.isMultiple(of: 3), height == width * 2 / 3,
              data.count == width * height * 4 else { throw StudyError.invalidComputeOutput }
        var bytes = [UInt8](data), unsupported = 0
        for i in stride(from: 0, to: bytes.count, by: 4) {
            if bytes[i+3] == 0 {
                guard bytes[i] == 255, bytes[i+1] == 0, bytes[i+2] == 255 else { throw StudyError.invalidComputeOutput }
                unsupported += 1; bytes[i+3] = 255
            } else if bytes[i+3] != 255 { throw StudyError.invalidComputeOutput }
        }
        return .init(width: width, height: height, rgba: Data(bytes), unsupportedPixels: unsupported)
    }
}

/// Optional GPU backend input, generated from the same validated source samples,
/// camera, and display transform as the CPU oracle. Every row is a 16-byte float4.
/// Parameters: 0 origin/halfW, 1 forward/halfH, 2 right/radius, 3 up/panelHalfExtent,
/// 4 Bradford ratio/exposure, 5 sample count/area count/minimum depth/reserved.
public struct StudyComputeInput: Sendable {
    public let width: Int
    public let height: Int
    public let parameters: [SIMD4<Float>]
    public let samples: [SIMD4<Float>]
    public let areas: [SIMD4<Float>]

    public init(scene: LightingScene, width: Int = 192) throws {
        let setup = try StudySetup(scene: scene, width: width, quality: .interactive)
        let c = vec(setup.geometry.center), camera = setup.camera
        let origin = vec(camera.position) - c
        let samples = setup.lighting.computeSamples(relativeTo: c)
        let areas = setup.lighting.computeAreas(relativeTo: c)
        self.width = width; self.height = setup.height
        self.samples = samples; self.areas = areas
        parameters = [pack(origin, setup.halfW), pack(vec(camera.forward), setup.halfH),
                      pack(vec(camera.right), setup.geometry.radius), pack(vec(camera.up), setup.geometry.panelHalfExtent),
                      setup.transform.computeParameters,
                      .init(Float(samples.count / 3), Float(areas.count / 3), Float(CameraFraming.minimumDepthMeters), 0)]
    }
}

private struct StudySetup {
    let camera: CameraFraming
    let geometry: StudyGeometry
    let lighting: StudyLighting
    let transform: PreviewColorTransform
    let height: Int
    let halfW: Double
    let halfH: Double

    init(scene: LightingScene, width: Int, quality: StudyQuality) throws {
        let maximum = quality == .reference ? 96 : 192
        guard width >= 24, width <= maximum, width.isMultiple(of: 3) else { throw StudyError.invalidResolution }
        guard let camera = CameraFraming(scene: scene), let geometry = StudyGeometry(center: scene.subject),
              camera.position.y > geometry.panelY + 0.01,
              camera.subjectDistanceMeters > geometry.radius + CameraFraming.minimumDepthMeters else { throw StudyError.invalidCamera }
        let light = try StudyLighting(scene: scene, quality: quality)
        guard let transform = PreviewColorTransform(settings: scene.effectivePreviewSettings) else { throw StudyError.invalidScene }
        self.camera = camera; self.geometry = geometry; lighting = light; self.transform = transform
        height = width * 2 / 3
        halfW = CameraLens.sensorWidthMillimeters / (2 * camera.lens.focalLengthMillimeters)
        halfH = CameraLens.sensorHeightMillimeters / (2 * camera.lens.focalLengthMillimeters)
    }
}

/// Deterministic CPU oracle/diagnostic preview. Direct light only; deliberately small
/// bounded images. Not a real-time production GPU renderer or photographic ground truth.
public enum ReferenceStudyRenderer {
    public static func render(scene: LightingScene, width: Int = 120, quality: StudyQuality = .interactive,
                              isCancelled: () -> Bool = { false }) throws -> StudyImage {
        let setup = try StudySetup(scene: scene, width: width, quality: quality)
        let camera = setup.camera, geometry = setup.geometry, light = setup.lighting, transform = setup.transform
        let height = setup.height, origin = vec(camera.position)
        let forward = vec(camera.forward), right = vec(camera.right), up = vec(camera.up)
        let halfW = setup.halfW, halfH = setup.halfH
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        var unsupported = 0
        let sphere: StudyMaterial = .dielectric(reflectance: 0.18, roughness: 0.32, f0: 0.04)
        let panel: StudyMaterial = .diffuse(reflectance: 0.30)
        for y in 0..<height {
            if isCancelled() { throw StudyError.cancelled }
            let py = (1 - 2 * (Double(y) + 0.5) / Double(height)) * halfH
            for x in 0..<width {
                let px = (2 * (Double(x) + 0.5) / Double(width) - 1) * halfW
                guard let ray = normalized3(forward + right * px + up * py) else { throw StudyError.invalidCamera }
                let minT = CameraFraming.minimumDepthMeters / dot3(ray, forward)
                let sphereT = geometry.sphereHit(origin: origin, direction: ray, minimum: minT)
                var planeT: Double?
                if ray.y < -1e-12 {
                    let t = (geometry.panelY - origin.y) / ray.y
                    if t >= minT, geometry.inPanel(origin + ray * t) { planeT = t }
                }
                let index = 4 * (y * width + x)
                var p: SIMD3<Double>, n: SIMD3<Double>, material: StudyMaterial
                if let t = sphereT, t < (planeT ?? .infinity) {
                    p = origin + ray * t
                    guard let unit = normalized3(p - vec(geometry.center)) else { throw StudyError.invalidSurface }
                    n = unit; material = sphere
                } else if let t = planeT {
                    p = origin + ray * t; n = .init(0, 1, 0); material = panel
                } else {
                    pixels[index] = 18; pixels[index + 1] = 20; pixels[index + 2] = 24
                    continue
                }
                do {
                    let signal = try light.evaluate(receiver: p, normal: n, view: -ray, material: material, geometry: geometry)
                    guard let color = transform.display(signal.signalXYZ) else { throw StudyError.invalidSurface }
                    pixels[index] = byte(color.red); pixels[index + 1] = byte(color.green); pixels[index + 2] = byte(color.blue)
                } catch StudyError.invalidSurface {
                    unsupported += 1
                    pixels[index] = 255; pixels[index + 1] = 0; pixels[index + 2] = 255
                }
            }
        }
        if isCancelled() { throw StudyError.cancelled }
        return .init(width: width, height: height, rgba: Data(pixels), unsupportedPixels: unsupported)
    }

    private static func byte(_ v: Double) -> UInt8 { UInt8((min(1, max(0, v)) * 255).rounded()) }
}

private func vec(_ p: Position) -> SIMD3<Double> { .init(p.x, p.y, p.z) }
private func vec(_ d: UnitDirection) -> SIMD3<Double> { .init(d.x, d.y, d.z) }
private func dot3(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x * b.x + a.y * b.y + a.z * b.z }
private func normalized3(_ v: SIMD3<Double>) -> SIMD3<Double>? {
    let length = sqrt(dot3(v, v))
    guard length.isFinite, length > 0 else { return nil }
    return v / length
}

private func pack(_ v: SIMD3<Double>, _ w: Double) -> SIMD4<Float> {
    .init(Float(v.x), Float(v.y), Float(v.z), Float(w))
}
