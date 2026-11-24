import CoreGraphics
import Foundation
import ImageIO
import LightingCore
import UniformTypeIdentifiers
import Vision

enum ReferenceAnalysisSupport: String, Equatable, Sendable {
    /// The image meets this heuristic's checks; this is not a calibrated confidence score.
    case supported, ambiguous, unsupported
}

/// Normalized to the upright image, with a top-left origin and downward-positive y.
struct ReferenceFaceBounds: Equatable, Sendable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

/// Relative, linearized sRGB pixel statistics, not illuminance or lamp settings.
struct ReferenceFaceMeasurements: Equatable, Sendable {
    let leftLuminance: Double
    let rightLuminance: Double
    /// (left - right) / (left + right), in -1...1. Positive means image-left is brighter.
    let asymmetry: Double
    /// Near-black or channel-saturated SDR samples; not proof of sensor clipping.
    let clippedFraction: Double
    let sampledPixelCount: Int
}

struct ReferenceAnalysisResult: Equatable, Sendable {
    let support: ReferenceAnalysisSupport
    let observations: ReferenceObservations
    let explanation: String
    let limitations: [String]
    let faceBounds: ReferenceFaceBounds?
    let measurements: ReferenceFaceMeasurements?

    var requiresManualDirection: Bool { observations.direction == .unknown }
}

/// Session-only, on-device analysis of the upright, sanitized PNG in ReferencePhoto.
/// Only Sendable values cross the task boundary. Pixels and Vision observations are
/// released after the request; nothing is saved, logged, identified, or uploaded.
enum ReferenceAnalysisService {
    private static let maximumBytes = 32 * 1024 * 1024
    private static let maximumSourceEdge = 1600
    private static let maximumAnalysisEdge = 640
    private static let limitations = [
        "This is a tentative cue from image brightness, not an exact reconstruction or a calibrated confidence score.",
        "Skin reflectance, makeup, hair, pose, reflections, exposure and editing can change the apparent key side.",
        "Balanced face brightness cannot distinguish a centered key from several lights. Shadow softness, fill and rim remain for you to judge.",
        "Image luminance does not measure lamp power, lux, light distance, modifier size or color temperature. Any rig settings are starting assumptions."
    ]

    /// Invalid or unsuitable images return an explicit manual-fallback result.
    /// Cancellation throws CancellationError and never returns a stale suggestion.
    nonisolated static func analyze(png: Data) async throws -> ReferenceAnalysisResult {
        try Task.checkCancellation()
        let cancellation = RequestCancellation()
        let worker = Task.detached(priority: .userInitiated) {
            try autoreleasepool {
                try analyzePixels(png, cancellation: cancellation)
            }
        }
        return try await withTaskCancellationHandler {
            let result = try await worker.value
            try Task.checkCancellation()
            return result
        } onCancel: {
            worker.cancel()
            cancellation.cancel()
        }
    }

    private static func result(_ support: ReferenceAnalysisSupport, _ explanation: String,
                               bounds: ReferenceFaceBounds? = nil,
                               measurements: ReferenceFaceMeasurements? = nil,
                               direction: ReferenceObservations.Direction = .unknown) -> ReferenceAnalysisResult {
        ReferenceAnalysisResult(support: support,
            observations: ReferenceObservations(direction: direction), explanation: explanation,
            limitations: limitations, faceBounds: bounds, measurements: measurements)
    }

    private static func analyzePixels(_ png: Data, cancellation: RequestCancellation) throws -> ReferenceAnalysisResult {
        try Task.checkCancellation()
        guard !png.isEmpty, png.count <= maximumBytes else {
            return result(.unsupported, "The reference is empty or exceeds the analysis size limit. Choose another photo or set the key side manually.")
        }
        let noCache = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(png as CFData, noCache),
              CGImageSourceGetStatus(source) == .statusComplete,
              let type = CGImageSourceGetType(source), type as String == UTType.png.identifier,
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, noCache) as? [String: Any],
              let widthNumber = properties[kCGImagePropertyPixelWidth as String] as? NSNumber,
              let heightNumber = properties[kCGImagePropertyPixelHeight as String] as? NSNumber else {
            return result(.unsupported, "The sanitized reference could not be read. Import the photo again or set the key side manually.")
        }
        // Check numeric values before converting to Int or allocating any pixels.
        let sourceWidth = widthNumber.doubleValue, sourceHeight = heightNumber.doubleValue
        let orientation = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1
        guard sourceWidth.isFinite, sourceHeight.isFinite,
              sourceWidth >= 1, sourceHeight >= 1,
              sourceWidth <= Double(maximumSourceEdge), sourceHeight <= Double(maximumSourceEdge),
              sourceWidth.rounded() == sourceWidth, sourceHeight.rounded() == sourceHeight,
              orientation == 1 else {
            return result(.unsupported, "Analysis needs an upright, bounded reference image. Import it again or choose the key side manually.")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumAnalysisEdge,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete,
              image.width > 0, image.height > 0,
              image.width <= maximumAnalysisEdge, image.height <= maximumAnalysisEdge else {
            return result(.unsupported, "The reference could not be decoded within the analysis limits. Choose another photo or use manual guidance.")
        }
        try Task.checkCancellation()

        // Apple Vision detects rectangles and pose only; no face recognition or identity model.
        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision3
        cancellation.register(request)
        defer { cancellation.clear() }
        try Task.checkCancellation()
        do {
            try VNImageRequestHandler(cgImage: image, orientation: .up, options: [:]).perform([request])
        } catch {
            try Task.checkCancellation()
            return result(.unsupported, "Face detection could not finish on this photo. You can still choose the lighting cues manually.")
        }
        try Task.checkCancellation()
        let faces = request.results ?? []
        guard !faces.isEmpty else {
            return result(.unsupported, "No supported face was detected. Use a clear portrait with one visible face, or choose the key side manually.")
        }
        guard faces.count == 1, let face = faces.first else {
            return result(.unsupported, "More than one face was detected. Choose a single-person portrait or set the key side manually.")
        }
        let box = face.boundingBox
        let components = [Double(box.minX), Double(box.minY), Double(box.width), Double(box.height)]
        guard components.allSatisfy(\.isFinite), box.width > 0, box.height > 0,
              box.minX >= 0, box.minY >= 0, box.maxX <= 1, box.maxY <= 1 else {
            return result(.unsupported, "The face bounds are incomplete. Try a portrait showing the whole face or use manual guidance.")
        }
        // Vision's origin is lower-left; CGImage cropping uses image rows from the top.
        let bounds = ReferenceFaceBounds(x: Double(box.minX), y: 1 - Double(box.maxY),
                                         width: Double(box.width), height: Double(box.height))
        guard face.confidence.isFinite, face.confidence >= 0.75 else {
            return result(.ambiguous, "The face was not detected clearly enough for a key-side suggestion. Choose the key side manually.", bounds: bounds)
        }
        guard bounds.width * Double(image.width) >= 48,
              bounds.height * Double(image.height) >= 48,
              bounds.width * bounds.height >= 0.015 else {
            return result(.unsupported, "The face is too small for reliable regional sampling. Use a closer portrait or choose the key side manually.", bounds: bounds)
        }
        guard bounds.x > 0.01, bounds.y > 0.01,
              bounds.x + bounds.width < 0.99, bounds.y + bounds.height < 0.99 else {
            return result(.unsupported, "The face touches the image edge and may be cropped. Use a complete face or choose the key side manually.", bounds: bounds)
        }
        guard let yaw = face.yaw?.doubleValue, let roll = face.roll?.doubleValue,
              let pitch = face.pitch?.doubleValue,
              yaw.isFinite, roll.isFinite, pitch.isFinite else {
            return result(.ambiguous, "The face orientation could not be established. Choose the key side manually.", bounds: bounds)
        }
        guard abs(yaw) <= 0.35, abs(roll) <= 0.26, abs(pitch) <= 0.35 else {
            return result(.unsupported, "The face is turned or tilted too far for this comparison. Use a mostly frontal portrait or choose the key side manually.", bounds: bounds)
        }

        // Three matching interior bands avoid the hairline, face outline and nose.
        // Crop first, then sample each entire patch: no bitmap row-origin assumption
        // is needed when comparing left/right or checking consistency across bands.
        var left: [PatchStatistics] = [], right: [PatchStatistics] = []
        for top in [0.25, 0.40, 0.55] {
            try Task.checkCancellation()
            guard let l = sample(image, bounds: bounds, x: 0.18, y: top),
                  let r = sample(image, bounds: bounds, x: 0.57, y: top) else {
                return result(.unsupported, "The face regions could not be sampled. Choose another photo or set the key side manually.", bounds: bounds)
            }
            left.append(l); right.append(r)
        }
        let patches = left + right
        guard patches.allSatisfy({ $0.opaqueFraction >= 0.95 && $0.count >= 24 }) else {
            return result(.unsupported, "The face contains transparent or missing pixels. Use an opaque portrait or set the key side manually.", bounds: bounds)
        }
        let leftMean = left.map(\.luminance).reduce(0, +) / 3
        let rightMean = right.map(\.luminance).reduce(0, +) / 3
        let sampledPixelCount = patches.map(\.count).reduce(0, +)
        // Patches can contain different numbers of opaque samples after cropping
        // and downsampling; a pixel fraction must weight their counts accordingly.
        let clipped = patches.reduce(0.0) { $0 + $1.clippedFraction * Double($1.count) }
            / Double(sampledPixelCount)
        let denominator = leftMean + rightMean
        let asymmetry = denominator > 0 ? (leftMean - rightMean) / denominator : 0
        let measurements = ReferenceFaceMeasurements(leftLuminance: leftMean, rightLuminance: rightMean,
            asymmetry: asymmetry, clippedFraction: clipped,
            sampledPixelCount: sampledPixelCount)
        guard [leftMean, rightMean, clipped, asymmetry].allSatisfy(\.isFinite) else {
            return result(.unsupported, "The brightness comparison was invalid. Choose the key side manually.", bounds: bounds)
        }
        guard clipped < 0.20, patches.allSatisfy({ $0.clippedFraction < 0.35 }),
              denominator / 2 >= 0.015, denominator / 2 <= 0.90 else {
            return result(.unsupported, "The sampled face regions are too dark or contain too many near-limit color values for this comparison. Try another exposure or choose the key side manually.", bounds: bounds, measurements: measurements)
        }
        let sign = asymmetry >= 0 ? 1.0 : -1.0
        let consistent = zip(left, right).allSatisfy { l, r in
            let total = l.luminance + r.luminance
            return total > 0 && sign * (l.luminance - r.luminance) / total >= 0.08
        }
        // Engineering guardrails, not learned/calibrated probabilities. A symmetrical
        // image is deliberately not labeled as a centered lamp or balanced fill.
        guard abs(asymmetry) >= 0.22, abs(leftMean - rightMean) >= 0.04, consistent else {
            return result(.ambiguous, "Face brightness is too similar or inconsistent across regions to suggest a key side. A centered key and multiple lights can look similar; choose the side manually.", bounds: bounds, measurements: measurements)
        }
        try Task.checkCancellation()
        let direction: ReferenceObservations.Direction = asymmetry > 0 ? .left : .right
        let side = asymmetry > 0 ? "image left" : "image right"
        return result(.supported, "The interior face regions are consistently brighter on \(side). This suggests a possible key side; confirm it against the photo before applying a rig.", bounds: bounds, measurements: measurements, direction: direction)
    }

    private struct PatchStatistics {
        let luminance: Double
        let clippedFraction: Double
        let opaqueFraction: Double
        let count: Int
    }

    private static func sample(_ image: CGImage, bounds: ReferenceFaceBounds,
                               x: Double, y: Double) -> PatchStatistics? {
        let rect = CGRect(x: (bounds.x + x * bounds.width) * Double(image.width),
                          y: (bounds.y + y * bounds.height) * Double(image.height),
                          width: 0.25 * bounds.width * Double(image.width),
                          height: 0.15 * bounds.height * Double(image.height))
        guard let crop = image.cropping(to: rect), crop.width > 0, crop.height > 0,
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let width = min(64, crop.width), height = min(48, crop.height)
        // At most 12 KiB per patch; the source decode was bounded before allocation.
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { storage -> Bool in
            guard let context = CGContext(data: storage.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(crop, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            return true
        }
        guard drawn else { return nil }
        var values: [Double] = []
        values.reserveCapacity(width * height)
        var clipped = 0
        for index in stride(from: 0, to: bytes.count, by: 4) {
            // Only fully opaque pixels have an appearance independent of an
            // unspecified background, matching the whole-image tonal summary.
            guard bytes[index + 3] == 255 else { continue }
            let red = Double(bytes[index]) / 255
            let green = Double(bytes[index + 1]) / 255
            let blue = Double(bytes[index + 2]) / 255
            let encodedLuma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
            // One saturated channel can lose usable brightness information even
            // when weighted luma is moderate (for example under colored light).
            // This checks the rendered SDR values, not the camera's raw sensor.
            if encodedLuma <= 0.02 || max(red, max(green, blue)) >= 0.98 { clipped += 1 }
            func linear(_ channel: Double) -> Double {
                channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
            }
            values.append(0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue))
        }
        guard !values.isEmpty else { return nil }
        values.sort()
        let trim = values.count / 10
        let middle = values[trim..<(values.count - trim)]
        let luminance = middle.reduce(0, +) / Double(middle.count)
        guard luminance.isFinite else { return nil }
        return PatchStatistics(luminance: luminance,
            clippedFraction: Double(clipped) / Double(values.count),
            opaqueFraction: Double(values.count) / Double(width * height), count: values.count)
    }

    /// The only shared mutable state. The lock protects registration and cancellation;
    /// Vision's cancel() is the sole operation invoked across the worker boundary.
    private final class RequestCancellation: @unchecked Sendable {
        private let lock = NSLock()
        private var request: VNRequest?
        private var cancelled = false

        func register(_ request: VNRequest) {
            lock.lock()
            self.request = request
            let shouldCancel = cancelled
            lock.unlock()
            if shouldCancel { request.cancel() }
        }

        func clear() {
            lock.lock()
            request = nil
            lock.unlock()
        }

        func cancel() {
            lock.lock()
            cancelled = true
            let activeRequest = request
            lock.unlock()
            activeRequest?.cancel()
        }
    }
}
