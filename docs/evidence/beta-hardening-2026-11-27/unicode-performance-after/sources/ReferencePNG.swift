import Foundation

/// Filters a freshly encoded, single-image PNG derivative (not an arbitrary
/// source-image decoder). Preserve original CRCs of retained chunks. Reject
/// malformed framing or unknown critical chunks; never retain textual or EXIF
/// payloads. The platform image encoder/decoder owns pixel and CRC validation.
public enum ReferencePNG {
    public enum Failure: Error { case malformed, tooLarge, unsupportedCriticalChunk }
    private static let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    private static let retained: Set<String> = [
        "IHDR", "PLTE", "IDAT", "IEND", "sRGB", "gAMA", "cHRM", "iCCP", "tRNS"
    ]

    public static func metadataFree(_ png: Data, maximumBytes: Int = 32 * 1024 * 1024) throws -> Data {
        guard png.count <= maximumBytes else { throw Failure.tooLarge }
        let bytes = [UInt8](png)
        guard bytes.count >= 8, bytes.prefix(8).elementsEqual(signature) else { throw Failure.malformed }
        var output = Data(signature)
        output.reserveCapacity(bytes.count)
        var offset = 8
        var sawHeader = false
        var sawPixels = false
        while offset < bytes.count {
            guard bytes.count - offset >= 12 else { throw Failure.malformed }
            let length = Int(bytes[offset]) << 24 | Int(bytes[offset + 1]) << 16 |
                Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
            guard length <= bytes.count - offset - 12 else { throw Failure.malformed }
            let typeBytes = bytes[(offset + 4)..<(offset + 8)]
            guard typeBytes.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) }),
                  let type = String(bytes: typeBytes, encoding: .ascii) else { throw Failure.malformed }
            let end = offset + 12 + length
            if !sawHeader {
                guard type == "IHDR", length == 13 else { throw Failure.malformed }
                sawHeader = true
            } else if type == "IHDR" {
                throw Failure.malformed
            }
            if type == "IDAT", length > 0 { sawPixels = true }
            if type == "IEND" {
                guard length == 0, sawPixels, end == bytes.count else { throw Failure.malformed }
                output.append(contentsOf: bytes[offset..<end])
                return output
            }
            if retained.contains(type) {
                output.append(contentsOf: bytes[offset..<end])
            } else if bytes[offset + 4] & 32 == 0 {
                throw Failure.unsupportedCriticalChunk
            }
            offset = end
        }
        throw Failure.malformed
    }
}
