import Foundation

public enum LightOutputAdjustmentError: Error, Equatable, Sendable, LocalizedError {
    case invalidTargetLux
    case invalidLight
    case unsupportedGeometry
    case outputOutOfRange

    public var errorDescription: String? {
        switch self {
        case .invalidTargetLux:
            return "Enter a finite target illuminance of zero lux or more."
        case .invalidLight:
            return "Use a nonblank light name of at most 80 characters. Check its position and emitter settings, output (0–100,000 cd), and color temperature (1,000–20,000 K), then try again."
        case .unsupportedGeometry:
            return "The model could not calculate this light's contribution. Check the scene settings and all lights. For a positive target in lux, separate the camera from the subject and try moving or re-aiming the light toward the camera-facing subject plane."
        case .outputOutOfRange:
            return "The requested lux could not be achieved within the model's 0–100,000 cd range and numerical accuracy. Try a different positive target or adjust the light's position or aim; enter 0 lux to turn this light off."
        }
    }
}

/// Adjusts one ideal source's contribution at the camera-facing subject plane.
/// This is a model calculation, not a measured lamp setting or image exposure.
/// Other lights, occlusion, reflections and real modifier losses are excluded.
public enum LightOutputAdjustment {
    /// Returns a valid light with only its candela changed. The source and scene
    /// remain unchanged, and the light need not already belong to the scene.
    /// Positive targets require a supported, nonzero contribution at one candela.
    /// Zero explicitly turns the source off without requiring a photometric sample.
    /// Invalid inputs and unrepresentable outputs throw; values are never clamped.
    public static func light(_ source: StudioLight, targetingLux targetLux: Double,
                             in scene: LightingScene) throws -> StudioLight {
        guard targetLux.isFinite, targetLux >= 0 else {
            throw LightOutputAdjustmentError.invalidTargetLux
        }
        guard source.isValid else { throw LightOutputAdjustmentError.invalidLight }
        guard let scene = try? scene.validated() else {
            throw LightOutputAdjustmentError.unsupportedGeometry
        }

        var adjusted = source
        if targetLux == 0 {
            adjusted.candela = 0
            return adjusted
        }

        // Using a unit source also supports increasing a currently off light;
        // scaling its existing zero contribution would be undefined.
        adjusted.candela = 1
        guard let unitLux = StudioPhotometry.illuminance(for: adjusted, in: scene),
              unitLux.isFinite, unitLux > 0 else {
            throw LightOutputAdjustmentError.unsupportedGeometry
        }

        // Bound the request by the forward model, not the independently
        // rounded inverse quotient. Even the next representable lux above
        // this output is outside the supported physical range.
        var maximum = source
        maximum.candela = 100_000
        guard maximum.isValid,
              let maximumLux = StudioPhotometry.illuminance(for: maximum, in: scene),
              maximumLux.isFinite, maximumLux > 0, targetLux <= maximumLux else {
            throw LightOutputAdjustmentError.outputOutOfRange
        }

        // Preserve an already exact setting before inverting the model.
        // Independently rounded division and integration can miss an exactly
        // achieved target, including subnormal values and the upper boundary.
        if source.candela > 0,
           StudioPhotometry.illuminance(for: source, in: scene) == targetLux {
            return source
        }

        adjusted.candela = targetLux / unitLux
        if adjusted.candela <= 0 || !adjusted.isValid {
            guard adjusted.candela > maximum.candela else {
                throw LightOutputAdjustmentError.outputOutOfRange
            }
            // The validated maximum is a separate forward-model candidate.
            // It must still achieve the request within the accuracy gate below.
            adjusted = maximum
        }

        // Extremely small positive outputs can underflow or lose substantial
        // precision in finite-emitter integration even when their candela is
        // representable. A nonzero result alone does not establish that the
        // requested contribution was achieved. Comparing a ratio also avoids
        // underflowing an absolute tolerance for subnormal target values.
        guard let achievedLux = StudioPhotometry.illuminance(for: adjusted, in: scene),
              achievedLux.isFinite, achievedLux > 0,
              abs(achievedLux / targetLux - 1) <= 1e-9 else {
            throw LightOutputAdjustmentError.outputOutOfRange
        }
        return adjusted
    }
}
