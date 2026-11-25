import Foundation

/// Session-only study subjects. They share the actual camera and lighting
/// controls; selecting a study never modifies or saves the lighting scene.
public enum StudySubject: String, CaseIterable, Sendable, Hashable {
    case sphere = "Sphere"
    case bust = "Bust"
}

/// Analytic, original neutral mannequin geometry in meters. Front faces +Z;
/// the head's center is the scene subject. This is a controlled lighting
/// target, not a reconstruction of a person or calibrated skin/fabric.
struct PortraitGeometry: Sendable {
    enum Region: Equatable, Sendable {
        case head, clothing, panel

        var material: StudyMaterial {
            switch self {
            case .head: return .dielectric(reflectance: 0.34, roughness: 0.48, f0: 0.04)
            case .clothing: return .dielectric(reflectance: 0.10, roughness: 0.85, f0: 0.025)
            case .panel: return .diffuse(reflectance: 0.24)
            }
        }
    }

    struct Hit: Sendable {
        let distance: Double
        let normal: SIMD3<Double>
        let geometricNormal: SIMD3<Double>
        let region: Region
    }

    private struct Ellipsoid: Sendable {
        let center: SIMD3<Double>
        let radii: SIMD3<Double>
        let region: Region

        func contains(_ p: SIMD3<Double>) -> Bool {
            let delta = (p - center) / radii
            return portraitDot(delta, delta) <= 1
        }

        /// Intersect the transformed unit sphere without normalizing its
        /// direction, so the ray parameter remains in world-space meters.
        func interval(origin: SIMD3<Double>, direction: SIMD3<Double>) -> (Double, Double)? {
            let o = (origin - center) / radii, d = direction / radii
            let a = portraitDot(d, d), b = portraitDot(o, d)
            let c = portraitDot(o, o) - 1
            let discriminant = b * b - a * c
            guard a.isFinite, a > 0, discriminant.isFinite, discriminant >= 0 else { return nil }
            let root = sqrt(discriminant)
            return ((-b - root) / a, (-b + root) / a)
        }

        func hit(origin: SIMD3<Double>, direction: SIMD3<Double>, minimum: Double,
                 maximum: Double) -> Hit? {
            guard let (near, far) = interval(origin: origin, direction: direction) else { return nil }
            let distance = near >= minimum ? near : far
            guard distance >= minimum, distance < maximum else { return nil }
            // Analytic gradient of the ellipsoid; inverse-square scaling is
            // essential for non-uniform radii and accurate incidence.
            let gradient = (origin + direction * distance - center) / (radii * radii)
            guard let normal = portraitUnit(gradient) else { return nil }
            return Hit(distance: distance, normal: normal, geometricNormal: normal, region: region)
        }
    }

    let center: SIMD3<Double>
    static let panelOffset = -0.565
    private static let epsilon = 1e-5
    private static let panelHalfExtent = 3.0
    private static let bound = Ellipsoid(center: .init(0, -0.20, 0),
                                         radii: .init(repeating: 0.46), region: .head)
    // Ears, neck and clothing use analytic forms; the entire facial
    // surface is a continuous, accelerated, original neutral head mesh.
    // No external asset, photograph, identity or inferred attributes.
    private static let head = PortraitHeadMesh.standard
    private static let parts: [Ellipsoid] = [
        .init(center: .init(-0.087, 0.004, -0.015), radii: .init(0.015, 0.034, 0.023), region: .head),
        .init(center: .init(0.087, 0.004, -0.015), radii: .init(0.015, 0.034, 0.023), region: .head),
        .init(center: .init(0, -0.175, -0.016), radii: .init(0.053, 0.095, 0.052), region: .head),
        .init(center: .init(0, -0.360, -0.022), radii: .init(0.203, 0.205, 0.108), region: .clothing),
        .init(center: .init(-0.129, -0.294, -0.020), radii: .init(0.107, 0.086, 0.090), region: .clothing),
        .init(center: .init(0.129, -0.294, -0.020), radii: .init(0.107, 0.086, 0.090), region: .clothing)
    ]

    init(center: Position) { self.center = portraitVector(center) }

    func contains(_ point: SIMD3<Double>) -> Bool {
        let local = point - center
        return Self.head.containsExclusionBounds(local) || Self.parts.contains { $0.contains(local) }
    }

    private func inPanel(_ local: SIMD3<Double>) -> Bool {
        abs(local.x) <= Self.panelHalfExtent && abs(local.z) <= Self.panelHalfExtent
    }

    private func canHitBust(origin: SIMD3<Double>, direction: SIMD3<Double>,
                            minimum: Double, maximum: Double) -> Bool {
        guard let (near, far) = Self.bound.interval(origin: origin, direction: direction) else { return false }
        return far >= minimum && near < maximum
    }

    /// The primary camera sees the nearest surface, preserving world scale
    /// and camera parallax. The finite neutral panel is a study background.
    func hit(origin: SIMD3<Double>, direction: SIMD3<Double>, minimum: Double) -> Hit? {
        let local = origin - center
        var nearest: Hit?
        if direction.y < -1e-12 {
            let t = (Self.panelOffset - local.y) / direction.y
            if t >= minimum, inPanel(local + direction * t) {
                nearest = .init(distance: t, normal: .init(0, 1, 0), geometricNormal: .init(0, 1, 0), region: .panel)
            }
        }
        if canHitBust(origin: local, direction: direction, minimum: minimum,
                      maximum: nearest?.distance ?? .infinity) {
            if let head = Self.head.hit(origin: local, direction: direction,
                                        minimum: minimum, maximum: nearest?.distance ?? .infinity) {
                nearest = .init(distance: head.distance, normal: head.normal,
                                geometricNormal: head.geometricNormal, region: .head)
            }
            for part in Self.parts {
                if let hit = part.hit(origin: local, direction: direction, minimum: minimum,
                                      maximum: nearest?.distance ?? .infinity) {
                    nearest = hit
                }
            }
        }
        return nearest
    }

    /// Segment visibility, not an infinite ray. Lights nearer than a later
    /// intersection are not falsely shadowed. The same geometry casts and
    /// receives shadows; a small surface-normal offset is applied by the
    /// shared direct-light evaluator before invoking this function.
    func occludes(origin: SIMD3<Double>, direction: SIMD3<Double>, distance: Double) -> Bool {
        let local = origin - center, limit = distance - Self.epsilon
        guard limit > Self.epsilon else { return false }
        if abs(direction.y) > 1e-12 {
            let t = (Self.panelOffset - local.y) / direction.y
            if t >= Self.epsilon, t < limit, inPanel(local + direction * t) { return true }
        }
        guard canHitBust(origin: local, direction: direction, minimum: Self.epsilon, maximum: limit) else { return false }
        if Self.head.occludes(origin: local, direction: direction, minimum: Self.epsilon, maximum: limit) {
            return true
        }
        return Self.parts.contains { part in
            guard let (near, far) = part.interval(origin: local, direction: direction) else { return false }
            return far >= Self.epsilon && near < limit
        }
    }
}

/// Deterministic CPU-only direct-light mannequin study. Uses the same
/// photometric samples, BRDF, white balance, tone mapping, and rectilinear
/// camera contract as the sphere oracle. Bounded small images; no skin
/// spectra, subsurface scattering, hair, textures, indirect light, or
/// physical performance/portrait-realism guarantee.
public enum PortraitStudyRenderer {
    public static let maximumWidth = 144

    public static func render(scene: LightingScene, width: Int = 120,
                              isCancelled: () -> Bool = { false }) throws -> StudyImage {
        guard (24...maximumWidth).contains(width), width.isMultiple(of: 3) else {
            throw StudyError.invalidResolution
        }
        guard !isCancelled() else { throw StudyError.cancelled }
        guard let camera = CameraFraming(scene: scene) else { throw StudyError.invalidCamera }
        let geometry = PortraitGeometry(center: scene.subject)
        let origin = portraitVector(camera.position)
        guard origin.y > geometry.center.y + PortraitGeometry.panelOffset + 0.01,
              camera.subjectDistanceMeters > 0.17,
              !geometry.contains(origin) else { throw StudyError.invalidCamera }
        let lighting = try StudyLighting(scene: scene, quality: .interactive)
        guard let transform = PreviewColorTransform(settings: scene.effectivePreviewSettings) else {
            throw StudyError.invalidScene
        }
        let forward = portraitVector(camera.forward), right = portraitVector(camera.right)
        let up = portraitVector(camera.up)
        let halfW = CameraLens.sensorWidthMillimeters / (2 * camera.lens.focalLengthMillimeters)
        let halfH = CameraLens.sensorHeightMillimeters / (2 * camera.lens.focalLengthMillimeters)
        let height = width * 2 / 3
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        var unsupportedMask = [UInt8](repeating: 0, count: width * height)
        var unsupported = 0
        var cancellation = StudyPixelCancellation()
        for y in 0..<height {
            let py = (1 - 2 * (Double(y) + 0.5) / Double(height)) * halfH
            for x in 0..<width {
                try cancellation.check(isCancelled)
                let index = 4 * (y * width + x)
                let px = (2 * (Double(x) + 0.5) / Double(width) - 1) * halfW
                guard let ray = portraitUnit(forward + right * px + up * py) else {
                    throw StudyError.invalidCamera
                }
                let minimum = CameraFraming.minimumDepthMeters / portraitDot(ray, forward)
                guard let hit = geometry.hit(origin: origin, direction: ray, minimum: minimum) else {
                    pixels[index] = 18; pixels[index + 1] = 20; pixels[index + 2] = 24
                    continue
                }
                do {
                    guard portraitDot(hit.normal, -ray) > 0 else { throw StudyError.invalidSurface }
                    let signal = try lighting.evaluate(receiver: origin + ray * hit.distance,
                                                        normal: hit.normal, view: -ray,
                                                        material: hit.region.material,
                                                        occlusionTest: geometry.occludes,
                                                        geometricNormal: hit.geometricNormal)
                    guard let color = transform.display(signal.signalXYZ) else { throw StudyError.invalidSurface }
                    pixels[index] = byte(color.red); pixels[index + 1] = byte(color.green)
                    pixels[index + 2] = byte(color.blue)
                } catch StudyError.invalidSurface {
                    unsupported += 1
                    unsupportedMask[index / 4] = 1
                    pixels[index] = 255; pixels[index + 1] = 0; pixels[index + 2] = 255
                }
            }
        }
        guard !isCancelled() else { throw StudyError.cancelled }
        return .init(width: width, height: height, rgba: Data(pixels), unsupportedPixels: unsupported,
                     unsupportedPixelMask: Data(unsupportedMask))
    }

    private static func byte(_ value: Double) -> UInt8 {
        UInt8((min(1, max(0, value)) * 255).rounded())
    }
}

private func portraitVector(_ p: Position) -> SIMD3<Double> { .init(p.x, p.y, p.z) }
private func portraitVector(_ d: UnitDirection) -> SIMD3<Double> { .init(d.x, d.y, d.z) }
private func portraitDot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
    a.x * b.x + a.y * b.y + a.z * b.z
}
private func portraitUnit(_ v: SIMD3<Double>) -> SIMD3<Double>? {
    let length = sqrt(portraitDot(v, v))
    guard length.isFinite, length > 0 else { return nil }
    return v / length
}
