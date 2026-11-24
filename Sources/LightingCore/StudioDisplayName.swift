import Foundation

/// Limits text passed to native layout without changing names in saved projects.
/// A Character count alone does not bound a long sequence of combining marks.
public enum StudioDisplayName {
    public static let maximumCharacters = 80
    public static let maximumScalars = 320
    public static let maximumUTF8Bytes = 1280

    public enum NameError: Error, Equatable, LocalizedError {
        case empty, tooLong, unsupportedCharacter

        public var errorDescription: String? {
            switch self {
            case .empty: return "Enter a name."
            case .tooLong: return "Use a shorter name of up to 80 characters."
            case .unsupportedCharacter: return "Names cannot contain line breaks, control characters or directional formatting codes."
            }
        }
    }

    /// Entry validation only. Do not apply this stricter policy while decoding
    /// a legacy library: retain its original name and use display(_:) in labels.
    public static func newInput(_ input: String) throws -> String {
        var scalars = String.UnicodeScalarView()
        var bytes = 0
        for scalar in input.unicodeScalars {
            let nextBytes = bytes + utf8Length(scalar)
            guard scalars.count < maximumScalars, nextBytes <= maximumUTF8Bytes else {
                throw NameError.tooLong
            }
            scalars.append(scalar)
            bytes = nextBytes
        }
        let name = String(scalars).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw NameError.empty }
        guard name.count <= maximumCharacters else { throw NameError.tooLong }
        guard !name.unicodeScalars.contains(where: isUnsafe) else { throw NameError.unsupportedCharacter }
        guard hasDisplayContent(name) else { throw NameError.empty }
        return name
    }

    /// A bounded label, not a renamed stored value. This inspects at most 321
    /// source scalars, even when one grapheme contains megabytes of marks.
    /// Ordinary accented/RTL text, joining controls and emoji remain intact.
    public static func display(_ input: String, maximumCharacters requested: Int = maximumCharacters) -> String {
        let characterLimit = min(Self.maximumCharacters, max(0, requested))
        guard characterLimit > 0 else { return "" }
        var scalars = String.UnicodeScalarView()
        var bytes = 0
        var truncated = false
        for source in input.unicodeScalars {
            let scalar: Unicode.Scalar = isUnsafe(source) ? " " : source
            let nextBytes = bytes + utf8Length(scalar)
            guard scalars.count < maximumScalars, nextBytes <= maximumUTF8Bytes else {
                truncated = true
                break
            }
            scalars.append(scalar)
            bytes = nextBytes
        }
        let cleaned = String(scalars).trimmingCharacters(in: .whitespacesAndNewlines)
        // Preserve stored legacy names, but let callers display their visible
        // fallback and identity for a name consisting only of invisible marks.
        // A truncated prefix cannot establish what is in the unseen suffix.
        guard hasDisplayContent(cleaned) else { return truncated ? "…" : "" }
        guard truncated || cleaned.count > characterLimit else { return cleaned }

        // Reserve space for the truncation mark in every limit. Stop at a whole
        // grapheme instead of cutting a normal joined emoji or accented letter.
        var result = ""
        var resultCharacters = 0
        var resultScalars = 0
        var resultBytes = 0
        for character in cleaned {
            let part = String(character)
            let scalarCount = part.unicodeScalars.count
            let byteCount = part.utf8.count
            guard resultCharacters < characterLimit - 1,
                  resultScalars + scalarCount <= maximumScalars - 1,
                  resultBytes + byteCount <= maximumUTF8Bytes - 3 else { break }
            result.append(character)
            resultCharacters += 1
            resultScalars += scalarCount
            resultBytes += byteCount
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    /// A contextual UI label for retained names that have no visible content.
    /// The caller supplies a visible fallback; both paths retain layout bounds.
    /// This does not change the source value or the editable project document.
    public static func label(_ input: String, fallback: String) -> String {
        let bounded = display(input)
        return bounded.isEmpty ? display(fallback) : bounded
    }

    private static func hasDisplayContent(_ name: String) -> Bool {
        // Joining controls and variation selectors remain valid within a
        // visible script or emoji sequence; alone they do not supply a label.
        name.unicodeScalars.contains {
            !$0.properties.isWhitespace && !$0.properties.isDefaultIgnorableCodePoint
        }
    }

    private static func isUnsafe(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .control, .lineSeparator, .paragraphSeparator: return true
        default: break
        }
        // Explicit bidi embedding/override/isolate controls can make labels
        // misleading. Natural right-to-left scripts do not require these codes.
        switch scalar.value {
        case 0x061C, 0x200E, 0x200F, 0x202A...0x202E, 0x2066...0x2069: return true
        default: return false
        }
    }

    private static func utf8Length(_ scalar: Unicode.Scalar) -> Int {
        switch scalar.value {
        case 0..<0x80: return 1
        case 0..<0x800: return 2
        case 0..<0x10000: return 3
        default: return 4
        }
    }
}
