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
            return "The light's settings must be valid before adjusting its output."
        case .unsupportedGeometry:
            return "This scene or light geometry cannot produce the requested illuminance on the camera-facing subject plane."
        case .outputOutOfRange:
            return "The requested illuminance requires an output outside the supported candela range."
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

        adjusted.candela = targetLux / unitLux
        if adjusted.candela <= 0 || !adjusted.isValid {
            // At the 100,000 cd boundary, independent integration rounding can
            // put the quotient just above the limit. Retain an already exact
            // setting rather than rejecting the editor's unchanged value.
            if source.candela > 0,
               StudioPhotometry.illuminance(for: source, in: scene) == targetLux {
                return source
            }
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
