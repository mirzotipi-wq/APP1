import Foundation
import XCTest
@testable import LightingCore

final class ReferencePNGTests: XCTestCase {
    private let signature = Data([137, 80, 78, 71, 13, 10, 26, 10])
    // Synthetic framed chunks: this filter preserves bytes, not pixel decode.
    private func chunk(_ name: String, _ payload: [UInt8] = []) -> Data {
        let n = UInt32(payload.count)
        return Data([UInt8(truncatingIfNeeded: n >> 24), UInt8(truncatingIfNeeded: n >> 16),
                     UInt8(truncatingIfNeeded: n >> 8), UInt8(truncatingIfNeeded: n)])
            + Data(name.utf8) + Data(payload) + Data([0, 0, 0, 0])
    }
    private var header: Data { chunk("IHDR", Array(repeating: 0, count: 13)) }
    private var pixels: Data { chunk("IDAT", [1, 2, 3]) }
    private var end: Data { chunk("IEND") }

    func testPrivateAncillaryChunksRemovedAndColorPreserved() throws {
        let color = chunk("sRGB", [0])
        let expected = signature + header + color + pixels + end
        let source = signature + header + color + chunk("eXIf", [1, 2, 3])
            + chunk("tEXt", Array("secret".utf8)) + chunk("iTXt", [9]) + pixels + chunk("zTXt", [8]) + end
        let filtered = try ReferencePNG.metadataFree(source)
        XCTAssertEqual(filtered, expected)
        XCTAssertEqual(try ReferencePNG.metadataFree(filtered), filtered)
    }
    func testMalformedAndTrailingChunksRejected() {
        for png in [signature + header + pixels, signature + header + pixels + end + Data([0]),
                    signature + pixels + end, signature + header + header + pixels + end,
                    signature + header + end, signature + header + pixels + end.dropLast()] {
            XCTAssertThrowsError(try ReferencePNG.metadataFree(Data(png)))
        }
    }
    func testUnknownCriticalAndInputLimitRejected() {
        XCTAssertThrowsError(try ReferencePNG.metadataFree(signature + header + chunk("ABCD") + pixels + end))
        XCTAssertThrowsError(try ReferencePNG.metadataFree(signature + header + pixels + end, maximumBytes: 8))
    }
}
