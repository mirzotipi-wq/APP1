# A082 — deployment-compatible strict UTF-8 validation

The current candidate failed Apple compilation before test execution because `String(validating:as:)` requires iOS 18 and macOS 15, while the package supports iOS 17 and macOS 14. This packet replaces that single call with Foundation’s unconditional failable `String(bytes:encoding: .utf8)` initializer. Apple’s primary API metadata declares iOS 8 and macOS 10.10 availability. No deployment target, test or gate was changed.

The unescaped ASCII fast path remains inline. Keys and escaped values still use the existing JSON decoder, and duplicate-key comparison still uses exact decoded UTF-8 bytes. The new call runs for unescaped non-ASCII strings in every tested build, so the Linux tests exercise the actual replacement rather than only a newer-platform branch.

The existing document regression suite covers malformed continuation bytes, overlong encodings, encoded surrogates, values above U+10FFFF, truncated scalars, raw controls, escaped surrogates, valid Unicode boundaries/noncharacters, duplicate keys and supported UTF-16/UTF-32 envelopes. See `receipt.json` and the original focused logs for completed configurations and exact method accounting.

The old benchmark remains evidence for its explicitly frozen source. This packet does not transfer that measurement to the Foundation decoder or claim an iPhone performance result. Fresh Apple builds and native execution remain necessary; Linux test success and API documentation are not a replacement for them.

Primary API documentation: https://developer.apple.com/documentation/swift/string/init(bytes:encoding:).md
