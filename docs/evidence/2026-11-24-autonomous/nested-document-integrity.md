# Nested editable-document integrity

## Observed ambiguity

This extends the narrow [root-envelope correction](document-key-integrity.md). The baseline document decoder at `ff8b683098a720b4c7abdddf212f85a79f3cfd39` rejected duplicate root keys but still accepted repeated fields inside the scene and its children. The lead froze its native candidate before this worker changed the document source; all changes in this packet remained unstaged.

Six new raw-wire tests produced **27 failed rejection assertions** before the correction, with zero unexpected failures. Accepted ambiguous inputs included a scene with versions 4 and 3, positions with x values 0 and 5, a light named both Key and Fill, candela values 900 and 200, rectangle versus point optics, widths 0.6 and 1.2 m, focal lengths 50 and 85 mm, and white balances 5600 and 6500 K. Escaped-equivalent fields and duplicates inside unknown nested metadata were also accepted. This establishes interchange ambiguity; it does not establish a saved-library overwrite or data loss.

[RFC 8259 section 4](https://www.rfc-editor.org/rfc/rfc8259.html#section-4) recommends unique object member names and describes differing duplicate handling among implementations. [Section 8.3](https://www.rfc-editor.org/rfc/rfc8259.html#section-8.3) explains interoperable comparison after decoding escapes. The app now enforces uniqueness throughout an externally imported project as a document-integrity policy. This is not a claim that the JSON grammar universally forbids repeated names.

## Correction and compatibility

The scanner now keeps an iterative stack of container scopes. Each object owns an independent key set and key/value state; array scopes never interpret their string elements as keys. Entering a child pushes its own state, and closing it removes that state so a sibling may use the same field names. The scanner mutates each stored set in place, avoiding a copy-on-write of all previous names for every member in a wide object.

Key tokens are decoded by JSONDecoder, then their exact UTF-8 sequences are stored in `Set<Data>`. A literal key and an escaped spelling of the same decoded sequence collide, including surrogate-pair spellings. Distinct scalar sequences, such as precomposed é versus e followed by a combining acute, remain distinct. Using `Set<String>` here would have introduced Swift's canonical-equivalence behavior into unknown nested field names.

The existing decoder still accepts the envelope, JSON representation and field types before this scan. Encoding detection and normalization, the exact 8 MiB input limit, schema migration, scene validation and canonical export code are unchanged. An earlier decoding or validation rejection remains a rejection. Duplicate key tokens that cannot decode to a Unicode string are mapped to the existing invalid-document error.

Only `LightingProjectDocument.decode` uses the stricter policy. `ProjectLibrary`, its file store and `SceneCodec` were not modified. Existing stored-library decoding and optimistic write rules retain their implementation. No schema version was changed, and no protected requirement was weakened.

The scan uses no recursive traversal. Work is bounded by the accepted input; live key sets belong only to open containers, and a closed container's set is released before traversing its sibling. This is an implementation bound, not a measured device-memory or latency guarantee.

## Actual verification

Environment: Debian 13 x86_64, Swift 6.4.3. The worker reused its existing isolated SwiftPM build directory to avoid allocating another complete build on the nearly full volume.

```sh
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/document-key-build --jobs 2 --filter ProjectDocumentNestedIntegrityTests
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/document-key-build --jobs 2 --filter 'ProjectDocumentNestedIntegrityTests|ProjectDocumentEnvelopeIntegrityTests|LightingProjectDocumentTests|ProjectDocumentAdversarialTests'
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/document-key-build --configuration release --jobs 2 --filter 'ProjectDocumentNestedIntegrityTests|ProjectDocumentEnvelopeIntegrityTests|LightingProjectDocumentTests|ProjectDocumentAdversarialTests'
```

| Run | Actual result |
| --- | --- |
| Before correction | 6 tests, 27 failed assertions, zero unexpected failures. |
| Corrected Debug | 24/24 tests passed, zero failures. |
| Corrected Release | 24/24 tests passed, zero failures. |

The six new tests cover the actual scene/light/optics fields, escaped-equivalent keys, duplicates in unknown objects, repeated names across sibling objects, arrays of strings and objects, quoted delimiters, canonical document bytes, NFC/NFD distinction, BMP/surrogate-pair/backslash/quote escape equivalence, six supported Unicode encodings, 64 nested container layers, and a 5,000-member object. The eighteen existing document tests recheck root duplicates, Foundation encoding compatibility, the exact byte limit, large legacy names, scene migration, malformed data and failure-preserving import transactions.

Source/test whitespace checks passed. The entire native app and all portable tests still require the lead's exact-source integration verification. The independent parser reviewer is conducting separate differential/adversarial probes; those results are recorded separately when available. No native provider, physical-device, storage responsiveness or release gate is claimed by this packet.

## Raw logs

Raw host timestamps differ from the connector clock and are preserved without alteration.

- `document-nested-before.log` SHA-256 `baefa18863e4845be295d822b8ed5d4de8474dcde473bf908c3a03be05ab5430`.
- `document-nested-after-debug.log` SHA-256 `6a6111c8a3a2dd989b1cc1e4728f701b7b3de14d9f70302ff1a1d809a9900f64`.
- `document-nested-after-release.log` SHA-256 `e8385a851cb721db0bedbe3c57055a9949f55eb8a0f40e3cbaa16683f331ccc0`.

## Stable source hashes

- `Sources/LightingCore/LightingProjectDocument.swift` SHA-256 `bf79fd894a96c7640bbc3802a2f631bcce98c6c2a90167e72e1ef22e05b31938`.
- `Tests/LightingCoreTests/ProjectDocumentNestedIntegrityTests.swift` SHA-256 `1b0516742f38200c7336fcdf69d14eb4aada12f3a5b8afc130f71bef034270f0`.
