import Foundation

/// Whole-image tonal statistics for an SDR sRGB derivative. These describe
/// encoded image appearance, not subject reflectance, exposure, light power,
/// sensor clipping, or the physical lighting setup.
public struct ReferenceTonalSummary: Equatable, Sendable {
    public static let maximumPixels = 128 * 128
    public let sampleCount: Int
    /// Luminance percentiles, expressed as equivalent neutral sRGB gray [0,1].
    public let lowGray: Double
    public let medianGray: Double
    public let highGray: Double
    /// Fractions at or below 10%, and at or above 95%, equivalent sRGB gray.
    public let deepShadowFraction: Double
    public let brightHighlightFraction: Double

    /// RGBA8 byte order, sRGB; only fully opaque samples are accepted. Partial
    /// alpha is excluded even if the input is premultiplied. No assumption
    /// about the background behind transparent pixels is made.
    public init?(rgba: [UInt8]) {
        guard !rgba.isEmpty, rgba.count % 4 == 0,
              rgba.count / 4 <= Self.maximumPixels else { return nil }
        func decode(_ x: Double) -> Double {
            x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
        }
        func encode(_ x: Double) -> Double {
            x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1 / 2.4) - 0.055
        }
        let table = (0...255).map { decode(Double($0) / 255) }
        var values: [Double] = []
        values.reserveCapacity(rgba.count / 4)
        for i in stride(from: 0, to: rgba.count, by: 4) where rgba[i + 3] == 255 {
            let y = 0.2126 * table[Int(rgba[i])] + 0.7152 * table[Int(rgba[i + 1])]
                + 0.0722 * table[Int(rgba[i + 2])]
            values.append(min(1, max(0, y)))
        }
        guard !values.isEmpty else { return nil }
        values.sort()
        func percentile(_ p: Double) -> Double {
            let index = p * Double(values.count - 1)
            let lo = Int(index.rounded(.down)), hi = Int(index.rounded(.up))
            let y = values[lo] + (values[hi] - values[lo]) * (index - Double(lo))
            return min(1, max(0, encode(y)))
        }
        let dark = decode(0.10), bright = decode(0.95)
        sampleCount = values.count
        lowGray = percentile(0.10)
        medianGray = percentile(0.50)
        highGray = percentile(0.90)
        deepShadowFraction = Double(values.lazy.filter { $0 <= dark }.count) / Double(values.count)
        brightHighlightFraction = Double(values.lazy.filter { $0 >= bright }.count) / Double(values.count)
    }
}
