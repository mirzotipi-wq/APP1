import CoreGraphics
import CoreTransferable
import Foundation
import ImageIO
import LightingCore
import UniformTypeIdentifiers
import UIKit
import XCTest
@testable import KeyAndFill

final class ReferencePhotoTests: XCTestCase {
    private func fixture(width: Int, height: Int, orientation: Int = 1) throws -> Data {
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let image = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let target = try XCTUnwrap(CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil))
        let props: [CFString: Any] = [
            kCGImagePropertyOrientation: orientation,
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFArtist: "private test artist"],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 45.0, kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 63.0, kCGImagePropertyGPSLongitudeRef: "W"
            ]
        ]
        CGImageDestinationAddImage(target, image, props as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(target))
        return data as Data
    }

    func testRotatesReducesAndRemovesSourceMetadata() throws {
        let original = try fixture(width: 2400, height: 1200, orientation: 6)
        let input = try XCTUnwrap(CGImageSourceCreateWithData(original as CFData, nil))
        let before = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(input, 0, nil) as? [String: Any])
        XCTAssertEqual((before[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue, 6)
        XCTAssertNotNil(before[kCGImagePropertyGPSDictionary as String])
        let result = try ReferencePhoto.sanitize(original)
        XCTAssertEqual(result.width, 800)
        XCTAssertEqual(result.height, 1600)
        let tones = try XCTUnwrap(result.tones)
        XCTAssertEqual(tones.sampleCount, 64 * 128)
        XCTAssertGreaterThan(tones.medianGray, 0.1)
        XCTAssertLessThan(tones.medianGray, 0.9)
        let output = try XCTUnwrap(CGImageSourceCreateWithData(result.png as CFData, nil))
        let after = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(output, 0, nil) as? [String: Any])
        XCTAssertEqual(CGImageSourceGetType(output).map { $0 as String }, UTType.png.identifier)
        XCTAssertNil(after[kCGImagePropertyGPSDictionary as String])
        XCTAssertNil(after[kCGImagePropertyTIFFDictionary as String])
        // ImageIO may synthesize dimensions and color space when reading a PNG;
        // prove no stored EXIF/text chunks and permit only these generated values.
        XCTAssertEqual(try ReferencePNG.metadataFree(result.png), result.png)
        if let exif = after[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            let generated = Set([kCGImagePropertyExifColorSpace as String,
                                 kCGImagePropertyExifPixelXDimension as String,
                                 kCGImagePropertyExifPixelYDimension as String])
            XCTAssertTrue(Set(exif.keys).isSubset(of: generated), "Unexpected EXIF fields: \(exif.keys)")
        }
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(output, 0, nil))
        XCTAssertEqual(image.width, result.width); XCTAssertEqual(image.height, result.height)
    }

    /// Explicit RGBA image-data rows keep the fixture independent of Quartz's
    /// drawing coordinate system. The first row is the encoded top row.
    private func rgbaImage(width: Int, height: Int, bytes: [UInt8]) throws -> CGImage {
        XCTAssertEqual(bytes.count, width * height * 4)
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        return try XCTUnwrap(CGImage(width: width, height: height, bitsPerComponent: 8,
            bitsPerPixel: 32, bytesPerRow: width * 4, space: space,
            bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue |
                                    CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    }

    private func encode(_ image: CGImage, as type: UTType, orientation: UInt32 = 1) throws -> Data {
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(
            data as CFMutableData, type.identifier as CFString, 1, nil))
        let properties: [CFString: Any] = [kCGImagePropertyOrientation: orientation,
                                         kCGImageDestinationLossyCompressionQuality: 1.0]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }

    /// CGImage cropping uses image-data rows, not view coordinates. Draw only
    /// one cropped pixel so no vertical-context flip can alter the probe.
    /// https://developer.apple.com/documentation/coregraphics/cgimage/cropping(to:)
    private func pixel(_ image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        let crop = try XCTUnwrap(image.cropping(to: CGRect(x: CGFloat(x), y: CGFloat(y), width: 1, height: 1)))
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        var bytes = [UInt8](repeating: 0, count: 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4, space: space,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return bytes
    }

    func testAllEightExifOrientationsPreserveIntendedLeftRightAndTopBottom() throws {
        let width = 96, height = 64
        // Encoded quadrants: A red, B green / C blue, D yellow.
        let palette: [[UInt8]] = [[235, 35, 35, 255], [35, 220, 55, 255],
                                  [35, 55, 230, 255], [235, 220, 35, 255]]
        var bytes: [UInt8] = []
        bytes.reserveCapacity(width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                bytes += palette[(y < height / 2 ? 0 : 2) + (x < width / 2 ? 0 : 1)]
            }
        }
        let image = try rgbaImage(width: width, height: height, bytes: bytes)
        // Output TL/TR/BL/BR indices, derived from the EXIF display transforms:
        // identity, horizontal mirror, 180°, vertical mirror, transpose,
        // clockwise 90°, transverse, counter-clockwise 90°.
        // These are ImageIO/EXIF values, not UIImage.Orientation raw values.
        // https://developer.apple.com/documentation/imageio/cgimagepropertyorientation
        let expected = [[0, 1, 2, 3], [1, 0, 3, 2], [3, 2, 1, 0], [2, 3, 0, 1],
                        [0, 2, 1, 3], [2, 0, 3, 1], [3, 1, 2, 0], [1, 3, 0, 2]]
        for orientation in 1...8 {
            let encoded = try encode(image, as: .jpeg, orientation: UInt32(orientation))
            let input = try XCTUnwrap(CGImageSourceCreateWithData(encoded as CFData, nil))
            let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(input, 0, nil) as? [String: Any])
            XCTAssertEqual((properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue, orientation)
            let sourcePixels = try XCTUnwrap(CGImageSourceCreateImageAtIndex(input, 0, nil))
            XCTAssertEqual(sourcePixels.width, width)
            XCTAssertEqual(sourcePixels.height, height)

            let result = try ReferencePhoto.sanitize(encoded)
            XCTAssertEqual(result.width, orientation >= 5 ? height : width, "EXIF \(orientation)")
            XCTAssertEqual(result.height, orientation >= 5 ? width : height, "EXIF \(orientation)")
            let output = try XCTUnwrap(CGImageSourceCreateWithData(result.png as CFData, nil))
            let outputProperties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(output, 0, nil) as? [String: Any])
            let outputOrientation = (outputProperties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue
            XCTAssertTrue(outputOrientation == nil || outputOrientation == 1,
                          "The transform must be baked into pixels, not left as EXIF \(orientation)")
            let transformed = try XCTUnwrap(CGImageSourceCreateImageAtIndex(output, 0, nil))
            for corner in 0..<4 {
                let xPart = corner % 2 == 0 ? 1 : 3
                let yPart = corner < 2 ? 1 : 3
                let sourcePixel = try pixel(sourcePixels, x: width * xPart / 4, y: height * yPart / 4)
                let actual = try pixel(transformed, x: result.width * xPart / 4, y: result.height * yPart / 4)
                for channel in 0..<3 {
                    // Probe well inside each quadrant, away from JPEG chroma
                    // boundaries; tolerance permits codec/color-rounding noise.
                    XCTAssertEqual(Double(sourcePixel[channel]), Double(palette[corner][channel]), accuracy: 24,
                                   "Fixture pixels changed before orientation \(orientation)")
                    XCTAssertEqual(Double(actual[channel]), Double(palette[expected[orientation - 1][corner]][channel]),
                                   accuracy: 24, "EXIF \(orientation), corner \(corner), channel \(channel)")
                }
                XCTAssertEqual(actual[3], 255, "EXIF \(orientation) must preserve opaque pixels")
            }
        }
    }

    func testTransparentAndPartialAlphaRemainExcludedFromReferenceTones() throws {
        let width = 64, height = 32
        var bytes: [UInt8] = []
        for _ in 0..<height {
            for x in 0..<width {
                // Opaque neutral gray, half-transparent white, transparent.
                // Values are premultiplied to match the explicit image format.
                bytes += x < 32 ? [128, 128, 128, 255] : x < 48 ? [128, 128, 128, 128] : [0, 0, 0, 0]
            }
        }
        let image = try rgbaImage(width: width, height: height, bytes: bytes)
        let result = try ReferencePhoto.sanitize(encode(image, as: .png))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(result.png as CFData, nil))
        let derivative = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertEqual(try pixel(derivative, x: 16, y: 16)[3], 255)
        XCTAssertEqual(try pixel(derivative, x: 40, y: 16)[3], 128)
        XCTAssertEqual(try pixel(derivative, x: 56, y: 16)[3], 0)
        let tones = try XCTUnwrap(result.tones)
        XCTAssertEqual(tones.sampleCount, 32 * height)
        XCTAssertEqual(tones.medianGray, 128.0 / 255, accuracy: 0.01)
        XCTAssertEqual(tones.deepShadowFraction, 0)
        XCTAssertEqual(tones.brightHighlightFraction, 0)
    }

    func testRejectsMalformedAndOversizedInputs() throws {
        XCTAssertThrowsError(try ReferencePhoto.sanitize(Data("not an image".utf8)))
        let truncated = try fixture(width: 200, height: 100)
        XCTAssertThrowsError(try ReferencePhoto.sanitize(Data(truncated.prefix(truncated.count / 2))))
        XCTAssertThrowsError(try ReferencePhoto.sanitize(Data(count: ReferencePhoto.byteLimit + 1))) {
            XCTAssertEqual($0 as? ReferenceImportError, .tooLarge)
        }
    }

    func testFileRepresentationConsumesOnlyItsTemporaryFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("reference.jpg")
        let original = try fixture(width: 80, height: 60)
        try original.write(to: url)
        // The FileRepresentation callback calls read(file:) on every supported OS.
        // Transferable's public URL initializer is only available from iOS 18.2.
        let imported = try ReferencePhoto.read(file: url)
        XCTAssertEqual(imported.width, 80); XCTAssertEqual(imported.height, 60)
        if #available(iOS 18.2, *) {
            let transferred = try await ReferencePhoto(importing: url, contentType: .jpeg)
            XCTAssertEqual(transferred.width, imported.width)
            XCTAssertEqual(transferred.height, imported.height)
            XCTAssertNotNil(CGImageSourceCreateWithData(transferred.png as CFData, nil))
            XCTAssertNotNil(transferred.tones)
        }
        XCTAssertEqual(try Data(contentsOf: url), original)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["reference.jpg"])
        XCTAssertThrowsError(try ReferencePhoto.read(file: directory))
        try FileManager.default.removeItem(at: url)
        XCTAssertNotNil(CGImageSourceCreateWithData(imported.png as CFData, nil))
    }

    func testFileSizeBoundBeforeDecode() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data().write(to: url)
        let handle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: UInt64(ReferencePhoto.byteLimit + 1))
        try handle.close()
        XCTAssertThrowsError(try ReferencePhoto.read(file: url)) {
            XCTAssertEqual($0 as? ReferenceImportError, .tooLarge)
        }
    }

    private actor ImportGate {
        private var opened = false
        private var continuation: CheckedContinuation<Void, Never>?

        func wait() async {
            if opened { return }
            await withCheckedContinuation { continuation = $0 }
        }

        func open() {
            opened = true
            continuation?.resume()
            continuation = nil
        }
    }

    func testCancelledImportRejectsBeforeReadingOrDecodingAndKeepsSourceBytes() async throws {
        let original = try fixture(width: 80, height: 60)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try original.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        for readFromFile in [true, false] {
            let gate = ImportGate()
            let operation = Task {
                await gate.wait()
                if readFromFile { return try ReferencePhoto.read(file: url) }
                return try ReferencePhoto.sanitize(original)
            }
            operation.cancel()
            await gate.open()
            do {
                _ = try await operation.value
                XCTFail("A cancelled import must not publish a derivative")
            } catch {
                XCTAssertTrue(error is CancellationError, "Unexpected cancellation error: \(error)")
            }
            XCTAssertEqual(try Data(contentsOf: url), original)
        }
    }

    @MainActor
    func testTemporaryDisappearanceRetainsSessionUntilRepresentableRemoval() {
        let controller = ComparisonSessionDismissalObserver.Controller()
        var closes = 0
        controller.update(onDismiss: { closes += 1 })
        controller.loadViewIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        // A covering picker does not dismiss the comparison's UIKit ancestors.
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(closes, 0)
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(closes, 0)

        // SwiftUI removal can happen without any ancestor being dismissed.
        ComparisonSessionDismissalObserver.dismantleUIViewController(controller, coordinator: ())
        XCTAssertEqual(closes, 1)
    }

    @MainActor
    func testRemovalClosesOnceReleasesCaptureAndRejectsLateCallbackUpdates() {
        final class SessionResource { var closed = false }
        let controller = ComparisonSessionDismissalObserver.Controller()
        controller.loadViewIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        var closes = 0
        weak var retainedSession: SessionResource?
        do {
            let session = SessionResource()
            retainedSession = session
            controller.update(onDismiss: {
                session.closed = true
                closes += 1
                // Cleanup may reenter through a parent's dismissal.
                ComparisonSessionDismissalObserver.dismantleUIViewController(controller, coordinator: ())
            })
        }
        XCTAssertNotNil(retainedSession)

        ComparisonSessionDismissalObserver.dismantleUIViewController(controller, coordinator: ())
        XCTAssertEqual(closes, 1)
        XCTAssertNil(retainedSession)

        weak var staleSession: SessionResource?
        do {
            let session = SessionResource()
            staleSession = session
            controller.update(onDismiss: {
                session.closed = true
                closes += 1
            })
        }
        XCTAssertNil(staleSession, "A removed observer must not retain a new session callback")
        ComparisonSessionDismissalObserver.dismantleUIViewController(controller, coordinator: ())
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(closes, 1)
    }
}
