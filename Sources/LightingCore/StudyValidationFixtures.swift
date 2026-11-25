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
    public let invalidMaskMatches: Bool

    /// Allows a small number of Float32 tangent/visibility differences while
    /// rejecting widespread color/geometry drift. These are backend consistency
    /// thresholds, not the protected physical rendering acceptance gate.
    public var passes: Bool {
        invalidCountMatches && invalidMaskMatches && meanChannelError <= 1 && fractionAboveFour <= 0.005
    }

    public init?(reference: StudyImage, candidate: StudyImage) {
        guard reference.width > 0, reference.height > 0,
              reference.width == candidate.width, reference.height == candidate.height else { return nil }
        let (pixelCount, pixelOverflow) = reference.width.multipliedReportingOverflow(by: reference.height)
        guard !pixelOverflow else { return nil }
        let (byteCount, byteOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
        guard !byteOverflow, reference.rgba.count == byteCount, candidate.rgba.count == byteCount else { return nil }

        func hasValidMask(_ image: StudyImage) -> Bool {
            guard image.unsupportedPixelMask.count == pixelCount,
                  (0...pixelCount).contains(image.unsupportedPixels) else { return false }
            var unsupported = 0
            for flag in image.unsupportedPixelMask {
                if flag == 1 { unsupported += 1 }
                else if flag != 0 { return false }
            }
            return unsupported == image.unsupportedPixels
        }
        guard hasValidMask(reference), hasValidMask(candidate) else { return nil }
        let a = [UInt8](reference.rgba), b = [UInt8](candidate.rgba)
        var total = 0.0, maximum = 0, outliers = 0
        for pixel in 0..<pixelCount {
            let offset = pixel * 4
            guard a[offset + 3] == 255, b[offset + 3] == 255 else { return nil }
            for channel in 0..<3 {
                let error = abs(Int(a[offset + channel]) - Int(b[offset + channel]))
                total += Double(error); maximum = max(maximum, error)
                if error > 4 { outliers += 1 }
            }
        }
        let count = Double(pixelCount) * 3
        meanChannelError = total / count
        maximumChannelError = maximum
        fractionAboveFour = Double(outliers) / count
        invalidCountMatches = reference.unsupportedPixels == candidate.unsupportedPixels
        invalidMaskMatches = reference.unsupportedPixelMask == candidate.unsupportedPixelMask
    }
}
