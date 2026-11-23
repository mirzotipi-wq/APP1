import CoreGraphics
import CoreTransferable
import Foundation
import ImageIO
import UniformTypeIdentifiers
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
        let output = try XCTUnwrap(CGImageSourceCreateWithData(result.png as CFData, nil))
        let after = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(output, 0, nil) as? [String: Any])
        XCTAssertEqual(CGImageSourceGetType(output).map { $0 as String }, UTType.png.identifier)
        XCTAssertNil(after[kCGImagePropertyGPSDictionary as String])
        XCTAssertNil(after[kCGImagePropertyTIFFDictionary as String])
        XCTAssertNil(after[kCGImagePropertyExifDictionary as String])
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(output, 0, nil))
        XCTAssertEqual(image.width, result.width); XCTAssertEqual(image.height, result.height)
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
        let imported = try await ReferencePhoto(importing: url, contentType: .jpeg)
        XCTAssertEqual(imported.width, 80); XCTAssertEqual(imported.height, 60)
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
}
