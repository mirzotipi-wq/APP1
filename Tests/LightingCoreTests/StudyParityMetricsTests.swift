import Foundation
import XCTest
@testable import LightingCore

final class StudyParityMetricsTests: XCTestCase {
    private let width = 48
    private let height = 32

    func testIdenticalImagesAndExplicitMasksPass() throws {
        for unsupported in [[], [17]] {
            let reference = try image(unsupported: unsupported, opaqueMagenta: [18])
            let metrics = try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: reference))
            XCTAssertEqual(reference.unsupportedPixelMask.count, width * height)
            XCTAssertEqual(reference.unsupportedPixels, unsupported.count)
            XCTAssertEqual(reference.unsupportedPixelMask[18], 0)
            XCTAssertTrue(stride(from: 3, to: reference.rgba.count, by: 4).allSatisfy { reference.rgba[$0] == 255 })
            XCTAssertEqual(metrics.meanChannelError, 0)
            XCTAssertEqual(metrics.maximumChannelError, 0)
            XCTAssertEqual(metrics.fractionAboveFour, 0)
            XCTAssertTrue(metrics.invalidCountMatches)
            XCTAssertTrue(metrics.invalidMaskMatches)
            XCTAssertTrue(metrics.passes)
        }
    }

    func testSwappedInvalidPixelsFailDespitePassingAggregateRGBLimits() throws {
        let reference = try image(unsupported: [17])
        let candidate = try image(unsupported: [18])
        let metrics = try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: candidate))
        XCTAssertEqual(reference.unsupportedPixels, 1)
        XCTAssertEqual(candidate.unsupportedPixels, 1)
        XCTAssertEqual(metrics.meanChannelError, 1020.0 / Double(width * height * 3), accuracy: 1e-12)
        XCTAssertEqual(metrics.fractionAboveFour, 4.0 / Double(width * height * 3), accuracy: 1e-12)
        XCTAssertLessThanOrEqual(metrics.meanChannelError, 1)
        XCTAssertLessThanOrEqual(metrics.fractionAboveFour, 0.005)
        XCTAssertTrue(metrics.invalidCountMatches)
        XCTAssertFalse(metrics.invalidMaskMatches)
        XCTAssertFalse(metrics.passes)
    }

    func testOpaqueMagentaCannotHideSwappedInvalidFlags() throws {
        let reference = try image(unsupported: [17], opaqueMagenta: [18])
        let candidate = try image(unsupported: [18], opaqueMagenta: [17])
        XCTAssertEqual(reference.rgba, candidate.rgba)
        XCTAssertEqual(reference.unsupportedPixelMask[17], 1)
        XCTAssertEqual(reference.unsupportedPixelMask[18], 0)
        XCTAssertEqual(candidate.unsupportedPixelMask[17], 0)
        XCTAssertEqual(candidate.unsupportedPixelMask[18], 1)
        let metrics = try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: candidate))
        XCTAssertEqual(metrics.meanChannelError, 0)
        XCTAssertEqual(metrics.fractionAboveFour, 0)
        XCTAssertTrue(metrics.invalidCountMatches)
        XCTAssertFalse(metrics.invalidMaskMatches)
        XCTAssertFalse(metrics.passes)
    }

    func testSparseMaximumRGBErrorRemainsDiagnostic() throws {
        let reference = try image()
        var rgba = reference.rgba
        rgba[0] = 255
        let candidate = replacing(reference, rgba: rgba)
        let metrics = try XCTUnwrap(StudyParityMetrics(reference: reference, candidate: candidate))
        XCTAssertEqual(metrics.maximumChannelError, 255)
        XCTAssertLessThanOrEqual(metrics.meanChannelError, 1)
        XCTAssertLessThanOrEqual(metrics.fractionAboveFour, 0.005)
        XCTAssertTrue(metrics.invalidMaskMatches)
        XCTAssertTrue(metrics.passes)
    }

    func testEquallyTruncatedAndExtendedBuffersAreRejected() throws {
        let baseline = try image()
        var extended = baseline.rgba
        extended.append(contentsOf: [0, 0, 0, 255])
        let buffers = [Data(baseline.rgba.dropLast(4)), Data(baseline.rgba.dropLast()), extended, Data()]
        for rgba in buffers {
            let malformed = replacing(baseline, rgba: rgba)
            XCTAssertNil(StudyParityMetrics(reference: malformed, candidate: malformed), "Byte count \(rgba.count)")
            XCTAssertNil(StudyParityMetrics(reference: baseline, candidate: malformed), "Byte count \(rgba.count)")
        }
    }

    func testNonpositiveOverflowingAndDifferentDimensionsAreRejected() throws {
        let baseline = try image()
        let dimensions = [(0, height), (width, 0), (-width, height), (width, -height),
                          (Int.min, Int.min), (Int.max, 2), (Int.max / 4 + 1, 1)]
        for (w, h) in dimensions {
            let malformed = replacing(baseline, width: w, height: h)
            XCTAssertNil(StudyParityMetrics(reference: malformed, candidate: malformed), "\(w) × \(h)")
        }
        // Equal byte counts do not make different row layouts comparable.
        let differentShape = replacing(baseline, width: width / 2, height: height * 2)
        XCTAssertNil(StudyParityMetrics(reference: baseline, candidate: differentShape))
    }

    func testMissingMalformedAndInconsistentMasksAreRejected() throws {
        let baseline = try image()
        var invalidByte = baseline.unsupportedPixelMask
        invalidByte[17] = 2
        var unreportedInvalid = baseline.unsupportedPixelMask
        unreportedInvalid[17] = 1
        var extended = baseline.unsupportedPixelMask
        extended.append(0)
        let missing = StudyImage(width: width, height: height, rgba: baseline.rgba, unsupportedPixels: 0)
        let invalid = try image(unsupported: [17])
        let missingPositive = StudyImage(width: width, height: height, rgba: invalid.rgba, unsupportedPixels: 1)
        let images = [
            ("missing", missing),
            ("missing with positive count", missingPositive),
            ("short", replacing(baseline, mask: Data(baseline.unsupportedPixelMask.dropLast()))),
            ("long", replacing(baseline, mask: extended)),
            ("nonbinary", replacing(baseline, mask: invalidByte)),
            ("unreported flag", replacing(baseline, mask: unreportedInvalid)),
            ("count mismatch", replacing(baseline, unsupportedPixels: 1)),
            ("negative count", replacing(baseline, unsupportedPixels: -1)),
            ("excess count", replacing(baseline, unsupportedPixels: width * height + 1))
        ]
        for (name, malformed) in images {
            XCTAssertNil(StudyParityMetrics(reference: malformed, candidate: malformed), name)
            XCTAssertNil(StudyParityMetrics(reference: baseline, candidate: malformed), name)
        }
    }

    func testDisplayRGBAWithNonopaqueAlphaIsRejected() throws {
        let baseline = try image()
        for alpha in [UInt8(0), 1, 254] {
            var rgba = baseline.rgba
            rgba[3] = alpha
            let malformed = replacing(baseline, rgba: rgba)
            XCTAssertNil(StudyParityMetrics(reference: malformed, candidate: malformed))
        }
    }

    func testCPURenderersRetainTheirUnsupportedPixelMasks() throws {
        var sphere = LightingScene.portrait()
        sphere.lights = [.init(name: "Near rectangle", position: sphere.subject, candela: 1000, kelvin: 5600,
                               optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 1.5, z: 1),
                                             widthMeters: 1, heightMeters: 1))]
        var portrait = LightingScene.portrait()
        portrait.camera = .init(x: 0, y: 1.60, z: 1.7)
        portrait.cameraLens = .init(focalLengthMillimeters: 70)
        portrait.lights = [.init(name: "Near point", position: .init(x: 0, y: portrait.subject.y,
                                                                   z: portrait.subject.z + 0.10),
                                 candela: 500, kelvin: 5600)]
        let images = [try ReferenceStudyRenderer.render(scene: sphere, width: 48),
                      try PortraitStudyRenderer.render(scene: portrait, width: 72)]
        for rendered in images {
            XCTAssertGreaterThan(rendered.unsupportedPixels, 0)
            XCTAssertEqual(rendered.unsupportedPixelMask.count, rendered.width * rendered.height)
            XCTAssertEqual(rendered.unsupportedPixelMask.filter { $0 == 1 }.count, rendered.unsupportedPixels)
            XCTAssertTrue(try XCTUnwrap(StudyParityMetrics(reference: rendered, candidate: rendered)).passes)
            for (pixel, flag) in rendered.unsupportedPixelMask.enumerated() where flag == 1 {
                XCTAssertEqual(Array(rendered.rgba[(pixel * 4)..<(pixel * 4 + 4)]), [255, 0, 255, 255])
            }
        }
    }

    private func image(unsupported: [Int] = [], opaqueMagenta: [Int] = []) throws -> StudyImage {
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        for offset in stride(from: 3, to: rgba.count, by: 4) { rgba[offset] = 255 }
        for pixel in unsupported + opaqueMagenta {
            rgba[pixel * 4] = 255; rgba[pixel * 4 + 2] = 255
        }
        for pixel in unsupported { rgba[pixel * 4 + 3] = 0 }
        return try StudyImage.fromComputeRGBA(width: width, height: height, data: Data(rgba))
    }

    private func replacing(_ image: StudyImage, width: Int? = nil, height: Int? = nil,
                           rgba: Data? = nil, unsupportedPixels: Int? = nil, mask: Data? = nil) -> StudyImage {
        .init(width: width ?? image.width, height: height ?? image.height, rgba: rgba ?? image.rgba,
              unsupportedPixels: unsupportedPixels ?? image.unsupportedPixels,
              unsupportedPixelMask: mask ?? image.unsupportedPixelMask)
    }
}
