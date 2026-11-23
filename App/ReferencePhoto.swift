import CoreGraphics
import CoreTransferable
import Foundation
import ImageIO
import LightingCore
import UniformTypeIdentifiers

enum ReferenceImportError: LocalizedError, Equatable {
    case tooLarge, unsupported, unreadable
    var errorDescription: String? {
        switch self {
        case .tooLarge: return "Choose a photo under 32 MiB and 100 megapixels."
        case .unsupported: return "Choose a single JPEG, PNG or HEIF still image."
        case .unreadable: return "The selected image could not be read. Try another photo."
        }
    }
}

/// Session-only derivative. No asset identifier, source URL, EXIF or GPS is retained.
/// A system-owned temporary file is consumed inside the transfer callback.
struct ReferencePhoto: Transferable, Sendable {
    static let byteLimit = 32 * 1024 * 1024
    static let pixelLimit = 100_000_000
    static let maxEdge = 1600
    let png: Data
    let width: Int
    let height: Int
    let tones: ReferenceTonalSummary?

    static var transferRepresentation: some TransferRepresentation {
        // Prefer the exact types accepted by the bounded decoder. A provider
        // may also advertise the abstract image type; inspect its actual bytes.
        FileRepresentation(importedContentType: .jpeg) { try Self.read(file: $0.file) }
        FileRepresentation(importedContentType: .png) { try Self.read(file: $0.file) }
        FileRepresentation(importedContentType: .heic) { try Self.read(file: $0.file) }
        FileRepresentation(importedContentType: .heif) { try Self.read(file: $0.file) }
        FileRepresentation(importedContentType: .image) { try Self.read(file: $0.file) }
    }

    static func read(file: URL) throws -> Self {
        try Task.checkCancellation()
        let info = try file.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard info.isRegularFile == true else { throw ReferenceImportError.unreadable }
        if let size = info.fileSize, size > byteLimit { throw ReferenceImportError.tooLarge }
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var data = Data()
        while true {
            try Task.checkCancellation()
            let remaining = byteLimit + 1 - data.count
            guard remaining > 0 else { throw ReferenceImportError.tooLarge }
            guard let chunk = try handle.read(upToCount: min(256 * 1024, remaining)),
                  !chunk.isEmpty else { break }
            data.append(chunk)
            guard data.count <= byteLimit else { throw ReferenceImportError.tooLarge }
        }
        return try sanitize(data)
    }

    static func sanitize(_ data: Data) throws -> Self {
        try Task.checkCancellation()
        guard data.count <= byteLimit else { throw ReferenceImportError.tooLarge }
        let noCache = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, noCache),
              CGImageSourceGetStatus(source) == .statusComplete,
              let identifier = CGImageSourceGetType(source) else { throw ReferenceImportError.unreadable }
        let allowed = [UTType.jpeg.identifier, UTType.png.identifier, UTType.heic.identifier, UTType.heif.identifier]
        guard allowed.contains(identifier as String), CGImageSourceGetCount(source) == 1 else {
            throw ReferenceImportError.unsupported
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, noCache) as? [String: Any],
              let w = (properties[kCGImagePropertyPixelWidth as String] as? NSNumber)?.intValue,
              let h = (properties[kCGImagePropertyPixelHeight as String] as? NSNumber)?.intValue,
              w > 0, h > 0 else { throw ReferenceImportError.unreadable }
        guard w <= pixelLimit, h <= pixelLimit / w else { throw ReferenceImportError.tooLarge }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxEdge,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              thumb.width > 0, thumb.height > 0,
              max(thumb.width, thumb.height) <= maxEdge,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let canvas = CGContext(data: nil, width: thumb.width, height: thumb.height,
                                     bitsPerComponent: 8, bytesPerRow: thumb.width * 4,
                                     space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw ReferenceImportError.unreadable }
        guard CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            throw ReferenceImportError.unreadable
        }
        try Task.checkCancellation()
        // Draw only pixels into a new sRGB bitmap; never propagate source metadata.
        canvas.draw(thumb, in: CGRect(x: 0, y: 0, width: CGFloat(thumb.width), height: CGFloat(thumb.height)))
        guard let pixels = canvas.makeImage() else { throw ReferenceImportError.unreadable }
        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(encoded as CFMutableData, UTType.png.identifier as CFString, 1, nil)
        else { throw ReferenceImportError.unreadable }
        CGImageDestinationAddImage(destination, pixels, nil)
        guard CGImageDestinationFinalize(destination), encoded.length <= byteLimit else {
            throw ReferenceImportError.unreadable
        }
        try Task.checkCancellation()
        // ImageIO may emit ancillary metadata even for a newly drawn bitmap.
        // Retain only structural, transparency and color-management PNG chunks.
        let clean: Data
        do { clean = try ReferencePNG.metadataFree(encoded as Data, maximumBytes: byteLimit) }
        catch { throw ReferenceImportError.unreadable }
        return Self(png: clean, width: pixels.width, height: pixels.height, tones: Self.measure(pixels))
    }

    /// Fixed, aspect-preserving thumbnail, explicit RGBA8 byte order. No source
    /// file or pixels are retained by the statistics value.
    private static func measure(_ image: CGImage) -> ReferenceTonalSummary? {
        let scale = min(1, 128.0 / Double(max(image.width, image.height)))
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            return true
        }
        return drawn ? ReferenceTonalSummary(rgba: bytes) : nil
    }
}
