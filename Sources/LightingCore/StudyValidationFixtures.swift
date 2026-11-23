import Foundation

/// Internal numerical parity fixtures, not physical photographs or calibration data.
public enum StudyValidationFixtures {
    public static func all() -> [(name: String, scene: LightingScene)] {
        var hard = LightingScene.portrait()
        hard.camera = .init(x: 0, y: 1.66, z: 2.3)
        hard.cameraLens = .init(focalLengthMillimeters: 85)
        var soft = hard
        soft.lights[0].optics = .init(kind: .rectangle, widthMeters: 1, heightMeters: 1.2)
        soft.lights[1].optics = .init(kind: .rectangle, widthMeters: 0.8, heightMeters: 0.8)
        soft.lights[2].optics = .init(kind: .rectangle, widthMeters: 0.4, heightMeters: 0.8)
        var warm = soft
        warm.previewSettings = .init(whiteBalanceKelvin: 3200, exposureStops: 1)
        warm.lights[1].optics = .init(kind: .directional, aimTarget: .init(x: 0.1, y: 1.65, z: -0.3))
        warm.camera = .init(x: -0.8, y: 1.8, z: 2.3)
        var dark = hard
        dark.lights = []
        var near = hard
        near.lights = [.init(name: "Near-source test", position: .init(x: 0, y: 1.5, z: 0.23),
                             candela: 100, kelvin: 5600)]
        var shifted = soft
        func move(_ p: Position) -> Position { .init(x: p.x + 25, y: p.y + 12, z: p.z - 13) }
        shifted.subject = move(shifted.subject); shifted.camera = move(shifted.camera)
        for i in shifted.lights.indices { shifted.lights[i].position = move(shifted.lights[i].position) }
        return [("hard", hard), ("soft", soft), ("warm-rotated", warm), ("dark", dark),
                ("near-field", near), ("translated", shifted)]
    }
}

public struct StudyParityMetrics: Equatable, Sendable {
    public let meanChannelError: Double
    public let maximumChannelError: Int
    public let fractionAboveFour: Double
    public let invalidCountMatches: Bool

    /// Allows a small number of Float32 tangent/visibility differences while
    /// rejecting widespread color/geometry drift. These are backend consistency
    /// thresholds, not the protected physical rendering acceptance gate.
    public var passes: Bool {
        invalidCountMatches && meanChannelError <= 1 && fractionAboveFour <= 0.005
    }

    public init?(reference: StudyImage, candidate: StudyImage) {
        guard reference.width == candidate.width, reference.height == candidate.height,
              reference.rgba.count == candidate.rgba.count, !reference.rgba.isEmpty else { return nil }
        let a = [UInt8](reference.rgba), b = [UInt8](candidate.rgba)
        var total = 0, maximum = 0, outliers = 0, count = 0
        for i in a.indices where i % 4 != 3 {
            let error = abs(Int(a[i]) - Int(b[i]))
            total += error; maximum = max(maximum, error); count += 1
            if error > 4 { outliers += 1 }
        }
        meanChannelError = Double(total) / Double(count)
        maximumChannelError = maximum
        fractionAboveFour = Double(outliers) / Double(count)
        invalidCountMatches = reference.unsupportedPixels == candidate.unsupportedPixels
    }
}
