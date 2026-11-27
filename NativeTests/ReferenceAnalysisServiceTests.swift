import CoreGraphics
import Foundation
import ImageIO
import LightingCore
import UniformTypeIdentifiers
import XCTest
@testable import KeyAndFill

final class ReferenceAnalysisServiceTests: XCTestCase {
    // These are original, uniformly gray pixels, not portrait or calibration data.
    private func fixture(width: Int = 128, height: Int = 128, type: UTType = .png) throws -> Data {
        var bytes = [UInt8](repeating: 128, count: width * height * 4)
        for alpha in stride(from: 3, to: bytes.count, by: 4) { bytes[alpha] = 255 }
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let image = try XCTUnwrap(CGImage(width: width, height: height, bitsPerComponent: 8,
            bitsPerPixel: 32, bytesPerRow: width * 4, space: space,
            bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue |
                                    CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(
            data as CFMutableData, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let encoded = data as Data

        // Prove that format/dimension tests reach the intended service guard with
        // complete, decodable fixtures rather than accidentally malformed bytes.
        let source = try XCTUnwrap(CGImageSourceCreateWithData(encoded as CFData, nil))
        XCTAssertEqual(CGImageSourceGetType(source).map { $0 as String }, type.identifier)
        XCTAssertEqual(CGImageSourceGetStatus(source), .statusComplete)
        XCTAssertEqual(CGImageSourceGetCount(source), 1)
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        XCTAssertEqual((properties[kCGImagePropertyPixelWidth as String] as? NSNumber)?.intValue, width)
        XCTAssertEqual((properties[kCGImagePropertyPixelHeight as String] as? NSNumber)?.intValue, height)
        XCTAssertEqual((properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1, 1)
        let decoded = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertEqual(CGImageSourceGetStatusAtIndex(source, 0), .statusComplete)
        XCTAssertEqual(decoded.width, width)
        XCTAssertEqual(decoded.height, height)
        return encoded
    }

    private func assertFeaturelessOpaquePNG(_ data: Data, file: StaticString = #filePath,
                                           line: UInt = #line) throws {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil), file: file, line: line)
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil), file: file, line: line)
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB), file: file, line: line)
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { storage in
            let context = try XCTUnwrap(CGContext(data: storage.baseAddress, width: image.width,
                height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: space, bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue |
                    CGImageAlphaInfo.premultipliedLast.rawValue), file: file, line: line)
            context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        }
        XCTAssertTrue(bytes.prefix(3).allSatisfy { abs(Int($0) - 128) <= 1 },
                      "Allow only color-rounding noise around the authored mid-gray", file: file, line: line)
        XCTAssertTrue(stride(from: 0, to: bytes.count, by: 4).allSatisfy {
            bytes[$0] == bytes[0] && bytes[$0 + 1] == bytes[1] &&
                bytes[$0 + 2] == bytes[2] && bytes[$0 + 3] == 255
        }, "The decoded fixture must be uniformly gray and fully opaque", file: file, line: line)
    }

    private func assertUnsupportedManualFallback(_ result: ReferenceAnalysisResult,
                                                file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(result.support, .unsupported, file: file, line: line)
        XCTAssertEqual(result.observations, ReferenceObservations(), file: file, line: line)
        XCTAssertTrue(result.requiresManualDirection, file: file, line: line)
        XCTAssertNil(result.faceBounds, file: file, line: line)
        XCTAssertNil(result.measurements, file: file, line: line)
        XCTAssertFalse(result.explanation.isEmpty, file: file, line: line)
        XCTAssertFalse(result.limitations.isEmpty, file: file, line: line)
    }

    func testEmptyAndMalformedInputsReturnUnsupportedManualFallback() async throws {
        let empty = try await ReferenceAnalysisService.analyze(png: Data())
        assertUnsupportedManualFallback(empty)
        XCTAssertTrue(empty.explanation.contains("analysis size limit"))

        let png = try fixture()
        // A PNG signature without its required chunks must not reach Vision.
        for malformed in [Data("not an image".utf8), Data(png.prefix(8))] {
            let result = try await ReferenceAnalysisService.analyze(png: malformed)
            assertUnsupportedManualFallback(result)
            XCTAssertTrue(result.explanation.contains("sanitized reference could not be read"))
        }
    }

    func testDecodableJPEGIsRejectedAsUnsanitizedInput() async throws {
        let jpeg = try fixture(type: .jpeg)
        let result = try await ReferenceAnalysisService.analyze(png: jpeg)
        assertUnsupportedManualFallback(result)
        XCTAssertTrue(result.explanation.contains("sanitized reference could not be read"),
                      "A decodable non-PNG must fail the input-format guard")
    }

    func testByteLimitRejectsOversizedInputBeforeImageRead() async throws {
        let byteLimit = 32 * 1024 * 1024
        var bytes = Data(repeating: 0, count: byteLimit)
        let atLimit = try await ReferenceAnalysisService.analyze(png: bytes)
        assertUnsupportedManualFallback(atLimit)
        XCTAssertTrue(atLimit.explanation.contains("sanitized reference could not be read"),
                      "Exactly 32 MiB may reach the image reader, which rejects these invalid bytes")

        bytes.append(0)
        XCTAssertEqual(bytes.count, byteLimit + 1)
        let oversized = try await ReferenceAnalysisService.analyze(png: bytes)
        assertUnsupportedManualFallback(oversized)
        // The public explanation distinguishes size rejection from decoder
        // rejection; this is a guard-order check, not a decode timing measurement.
        XCTAssertTrue(oversized.explanation.contains("analysis size limit"))
        XCTAssertNotEqual(oversized.explanation, atLimit.explanation)
    }

    func testEitherOversizedSourceEdgeIsRejectedBeforeAnalysis() async throws {
        for (width, height) in [(1601, 1), (1, 1601)] {
            let png = try fixture(width: width, height: height)
            XCTAssertLessThan(png.count, 32 * 1024 * 1024)
            let result = try await ReferenceAnalysisService.analyze(png: png)
            assertUnsupportedManualFallback(result)
            XCTAssertTrue(result.explanation.contains("upright, bounded reference image"),
                          "A complete \(width) by \(height) PNG must fail the source-edge guard")
        }
    }

    func testFeaturelessPNGRequiresManualDirectionAndCannotProduceRig() async throws {
        let png = try fixture()
        try assertFeaturelessOpaquePNG(png)
        let result = try await ReferenceAnalysisService.analyze(png: png)
        assertUnsupportedManualFallback(result)
        XCTAssertTrue(result.explanation.contains("No supported face was detected"),
                      "A valid flat image should reach face detection and return no face")
        XCTAssertThrowsError(try GuidedLighting.candidates(from: result.observations, in: .portrait())) {
            XCTAssertEqual($0 as? GuidedRigError, .insufficientDirection)
        }
    }

    private actor AnalysisGate {
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

    func testPreCancelledAnalysisThrowsInsteadOfPublishingFallback() async throws {
        let png = try fixture()
        // Cover both a valid image and an input that otherwise returns a fallback.
        for input in [png, Data()] {
            let gate = AnalysisGate()
            let operation = Task {
                await gate.wait()
                return try await ReferenceAnalysisService.analyze(png: input)
            }
            operation.cancel()
            await gate.open()
            do {
                _ = try await operation.value
                XCTFail("A pre-cancelled analysis must not publish any result")
            } catch {
                XCTAssertTrue(error is CancellationError, "Unexpected cancellation error: \(error)")
            }
        }
    }

    func testRepeatedUnsupportedAnalysisKeepsObservationsStable() async throws {
        let png = try fixture()
        let first = try await ReferenceAnalysisService.analyze(png: png)
        assertUnsupportedManualFallback(first)
        for _ in 0..<3 {
            let malformed = try await ReferenceAnalysisService.analyze(png: Data("not an image".utf8))
            assertUnsupportedManualFallback(malformed)
            let repeated = try await ReferenceAnalysisService.analyze(png: png)
            assertUnsupportedManualFallback(repeated)
            XCTAssertEqual(repeated.observations, first.observations)
            XCTAssertEqual(repeated.limitations, first.limitations)
        }
    }
}
