import Foundation

/// Preview settings are relative controls, not camera ISO/aperture/shutter calibration.
public struct PreviewSettings: Codable, Equatable, Sendable {
    public static let whiteBalanceRange: ClosedRange<Double> = 2000...10000
    public static let exposureRange: ClosedRange<Double> = -6...6
    public var whiteBalanceKelvin: Double
    public var exposureStops: Double

    public init(whiteBalanceKelvin: Double = 5600, exposureStops: Double = 0) {
        self.whiteBalanceKelvin = whiteBalanceKelvin; self.exposureStops = exposureStops
    }
    public var isValid: Bool {
        whiteBalanceKelvin.isFinite && Self.whiteBalanceRange.contains(whiteBalanceKelvin) &&
        exposureStops.isFinite && Self.exposureRange.contains(exposureStops)
    }
}

extension LightingScene {
    public var effectivePreviewSettings: PreviewSettings { previewSettings ?? .init() }
}

/// Relative CIE XYZ tristimulus coordinates; not absolute spectral radiance.
public struct RelativeXYZ: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
    public init(x: Double, y: Double, z: Double) { self.x = x; self.y = y; self.z = z }
    public var chromaticity: Chromaticity? {
        let sum = x + y + z
        guard sum.isFinite, sum > 0, x >= 0, y >= 0, z >= 0 else { return nil }
        return .init(x: x / sum, y: y / sum)
    }
    fileprivate var vector: SIMD3<Double> { .init(x, y, z) }
    fileprivate init(_ v: SIMD3<Double>) { self.init(x: v.x, y: v.y, z: v.z) }
}

public struct Chromaticity: Equatable, Sendable {
    public let x: Double
    public let y: Double
}

/// Display-encoded sRGB components in [0, 1], after tone/gamut mapping.
public struct DisplayRGB: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
}

public enum PreviewColorimetry {
    /// Approximate Planckian blackbody; color temperature alone cannot describe LED SPDs,
    /// camera sensitivities or color rendering. CIE XYZ normalized to Y = 1.
    /// 380–780 nm, 5 nm trapezoidal samples; Wyman/Sloan/Shirley (JCGT 2013), Eq. 4.
    public static func blackbody(kelvin: Double) -> RelativeXYZ? {
        guard kelvin.isFinite, (1000...20000).contains(kelvin) else { return nil }
        var total = SIMD3<Double>.zero
        for nm in stride(from: 380, through: 780, by: 5) {
            let wavelength = Double(nm)
            // Planck law, scaled by an arbitrary wavelength^5 factor (cancels at Y normalization).
            // Second radiation constant in nm·K.
            let spectrum = pow(560 / wavelength, 5) / expm1(1.438776877e7 / (wavelength * kelvin))
            let weight = (nm == 380 || nm == 780) ? 0.5 : 1.0
            total += matchingFunctions(wavelength) * (spectrum * weight)
        }
        guard total.y.isFinite, total.y > 0 else { return nil }
        return RelativeXYZ(total / total.y)
    }

    public static func display(_ xyz: RelativeXYZ, settings: PreviewSettings) -> DisplayRGB? {
        PreviewColorTransform(settings: settings)?.display(xyz)
    }

    private static func matchingFunctions(_ wavelength: Double) -> SIMD3<Double> {
        func lobe(_ center: Double, _ left: Double, _ right: Double) -> Double {
            let t = (wavelength - center) * (wavelength < center ? left : right)
            return exp(-0.5 * t * t)
        }
        let x = 1.056 * lobe(599.8, 0.0264, 0.0323) + 0.362 * lobe(442.0, 0.0624, 0.0374)
                - 0.065 * lobe(501.1, 0.0490, 0.0382)
        let y = 0.821 * lobe(568.8, 0.0213, 0.0247) + 0.286 * lobe(530.9, 0.0613, 0.0322)
        let z = 1.217 * lobe(437.0, 0.0845, 0.0278) + 0.681 * lobe(459.0, 0.0385, 0.0725)
        return .init(max(0, x), max(0, y), max(0, z))
    }

    fileprivate static func bradford(_ v: SIMD3<Double>) -> SIMD3<Double> {
        .init(0.8951 * v.x + 0.2664 * v.y - 0.1614 * v.z,
              -0.7502 * v.x + 1.7135 * v.y + 0.0367 * v.z,
              0.0389 * v.x - 0.0685 * v.y + 1.0296 * v.z)
    }
    fileprivate static func inverseBradford(_ v: SIMD3<Double>) -> SIMD3<Double> {
        .init(0.9869929 * v.x - 0.1470543 * v.y + 0.1599627 * v.z,
              0.4323053 * v.x + 0.5183603 * v.y + 0.0492912 * v.z,
              -0.0085287 * v.x + 0.0400428 * v.y + 0.9684867 * v.z)
    }
}

/// Prepared, reusable display transform for a fixed white balance and exposure.
/// Retains signed linear RGB through tone/gamut mapping. No camera profile.
public struct PreviewColorTransform: Sendable {
    private let adaptationRatio: SIMD3<Double>
    private let exposure: Double

    public init?(settings: PreviewSettings) {
        guard settings.isValid, let white = PreviewColorimetry.blackbody(kelvin: settings.whiteBalanceKelvin) else { return nil }
        let d65 = SIMD3<Double>(0.3127 / 0.3290, 1, (1 - 0.3127 - 0.3290) / 0.3290)
        let src = PreviewColorimetry.bradford(white.vector), dst = PreviewColorimetry.bradford(d65)
        guard src.x > 0, src.y > 0, src.z > 0 else { return nil }
        adaptationRatio = dst / src
        exposure = pow(2, settings.exposureStops)
    }

    /// Explicit shared parameters for the optional Float32 compute implementation.
    public var computeParameters: SIMD4<Float> {
        .init(Float(adaptationRatio.x), Float(adaptationRatio.y), Float(adaptationRatio.z), Float(exposure))
    }

    /// Bradford adaptation, relative exposure, luminance Reinhard tone mapping and
    /// neutral-axis gamut compression into display-encoded sRGB.
    public func display(_ xyz: RelativeXYZ) -> DisplayRGB? {
        guard xyz.x.isFinite, xyz.y.isFinite, xyz.z.isFinite, xyz.x >= 0, xyz.y >= 0, xyz.z >= 0 else { return nil }
        let adapted = PreviewColorimetry.inverseBradford(PreviewColorimetry.bradford(xyz.vector) * adaptationRatio) * exposure
        let rgb = SIMD3<Double>(3.24096994 * adapted.x - 1.53738318 * adapted.y - 0.49861076 * adapted.z,
                                -0.96924364 * adapted.x + 1.87596750 * adapted.y + 0.04155506 * adapted.z,
                                0.05563008 * adapted.x - 0.20397696 * adapted.y + 1.05697151 * adapted.z)
        guard rgb.x.isFinite, rgb.y.isFinite, rgb.z.isFinite, adapted.y.isFinite, adapted.y >= 0 else { return nil }
        if adapted.y == 0 { return .init(red: 0, green: 0, blue: 0) }
        let luminance = adapted.y / (1 + adapted.y)
        let tone = rgb / (1 + adapted.y)
        var t = 1.0
        for component in [tone.x, tone.y, tone.z] {
            let delta = component - luminance
            if delta > 0 { t = min(t, (1 - luminance) / delta) }
            if delta < 0 { t = min(t, -luminance / delta) }
        }
        func encode(_ v: Double) -> Double {
            let linear = min(1, max(0, luminance + t * (v - luminance)))
            return linear <= 0.0031308 ? 12.92 * linear : 1.055 * pow(linear, 1 / 2.4) - 0.055
        }
        return .init(red: encode(tone.x), green: encode(tone.y), blue: encode(tone.z))
    }
}

/// Camera-facing neutral test card. Uses summed direct illuminance and an ideal spectrally flat
/// 18% diffuse reflectance. No occlusion, bounce, actual materials or camera response.
/// 1000 lx is an explicit relative-exposure reference; the result is a display preview, not EV100.
public struct NeutralCardPreview: Equatable, Sendable {
    public let totalLux: Double
    public let incidentXYZ: RelativeXYZ
    public let display: DisplayRGB

    public init?(scene: LightingScene) {
        guard (try? scene.validated()) != nil, StudioPhotometry.receiverNormal(in: scene) != nil else { return nil }
        var xyz = SIMD3<Double>.zero
        var totalLux = 0.0
        for light in scene.lights {
            guard light.isValid else { return nil }
            if light.candela == 0 { continue }
            guard let lux = StudioPhotometry.illuminance(for: light, in: scene),
                  let color = PreviewColorimetry.blackbody(kelvin: light.kelvin) else { return nil }
            totalLux += lux; xyz += color.vector * lux
        }
        let signal = RelativeXYZ(xyz * (0.18 / 1000))
        guard let display = PreviewColorimetry.display(signal, settings: scene.effectivePreviewSettings) else { return nil }
        self.totalLux = totalLux; self.incidentXYZ = RelativeXYZ(xyz); self.display = display
    }
}
