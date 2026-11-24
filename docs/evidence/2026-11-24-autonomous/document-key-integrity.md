# Editable project envelope key integrity

## Reproduced defect and correction

KF-031 follows the earlier [document import review](document-import-review.md). The baseline `LightingProjectDocument.swift` was the file at `0fce248b4e61bace88002b40f6c56fddedb19c8a`; the lead's unrelated cycle-five source was already frozen before this work began.

Foundation's keyed container collapses duplicate object keys before `allKeys` is read. The existing closed-envelope check therefore accepted two `name` values, two `scene` values, and a supported `schemaVersion` followed by an unsupported one. Escaped equivalent names also bypassed the set check. The new five-test regression fixture produced **16 failed assertions before the correction**, with zero unexpected failures after correcting one test assumption about Foundation's encoding support.

`LightingProjectDocument.decode` now performs a bounded scan of the original root object after the existing decoder has validated JSON syntax and the closed envelope. It tracks structural depth, skips complete quoted strings, and sends each root key token back through JSONDecoder for escape interpretation. A repeated decoded key is rejected as an invalid document. A document already rejected by the original version/field/scene decoding retains that earlier rejection; the scanner does not select a duplicate winner.

The scanner is iterative and bounded by the existing 8 MiB input limit. It does not parse scene values, change number rules or replace Foundation's JSON grammar. UTF-8 input uses a direct byte copy; UTF-16/32 input is identified by its BOM or leading ASCII byte pattern, transcoded with Foundation and scanned as UTF-8. JSONDecoder still decides whether a particular encoding is supported. Root closing ends the second scan because the first decoder has already validated trailing whitespace.

Canonical encoding, name storage, scene validation, fresh project creation and optimistic library writes are unchanged. Nested scene-object duplicate-key behavior is outside this narrow envelope correction and retains the existing decoder semantics.

## Actual verification

Environment: Debian 13 x86_64, Swift 6.4.3. The worker used an isolated SwiftPM directory, `/workspace/scratch/73dcd6a65726/verification/document-key-build`, without touching the lead's exact-source build.

```sh
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/document-key-build --jobs 2 --filter ProjectDocumentEnvelopeIntegrityTests
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/document-key-build --jobs 2 --filter 'ProjectDocumentEnvelopeIntegrityTests|LightingProjectDocumentTests|ProjectDocumentAdversarialTests'
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/document-key-build --configuration release --jobs 2 --filter 'ProjectDocumentEnvelopeIntegrityTests|LightingProjectDocumentTests|ProjectDocumentAdversarialTests'
```

- Corrected baseline fixture: **5 tests, 16 failed assertions**, zero unexpected failures.
- Corrected implementation: **18/18 Debug and 18/18 Release**, zero failures, including all thirteen prior document/adversarial tests.
- Five new tests cover repeated values in either order, same-value duplicates, escaped-equivalent keys, escaped unique keys, braces/brackets/quotes in names, real nested light arrays, Foundation-supported UTF encodings, deterministic canonical bytes, a large valid legacy name, exact 8 MiB input and one additional byte.
- Existing tests recheck malformed numeric/encoding data, schema migration, stale import transactions, the full library and combined library byte-limit failure with saved-byte preservation.
- The first baseline log had one unexpected failure because its test assumed the platform accepted `.utf32` with a BOM. The valid encoding matrix was corrected to compare with the existing Foundation decoder. On this Linux runtime the explicit UTF-32 byte-order forms pass while that BOM-bearing form is rejected. The original log is retained; the implementation does not claim new encoding support.
- Final source/test whitespace check passed. Two explanatory comments were clarified after the recorded test runs; executable logic and test assertions did not change. The integration lead will run the complete suite on its exact source snapshot.

No Apple SDK, native Files provider, picker, device or storage responsiveness claim follows from these portable tests. Independent scanner review and the lead's full integration verification remain required before marking the packet integrated. No staging or commits were performed by this worker.

## Raw evidence

- `document-key-before.log` SHA-256 `a4e6206af13d02ef418de9441393ffc1385478cdb2154499a29c5d3e8b55845b`.
- `document-key-before-corrected-fixture.log` SHA-256 `511f3f0976d5baf651945bb1f61ecd484afb875bcd845b7b2b150ef8c5f09261`.
- `document-key-after-debug.log` SHA-256 `ca5f9689919c3233b4f3addd99b42dcb381034cca03f7a6f2a68abf4f760eaaa`.
- `document-key-after-release.log` SHA-256 `ce7b42fa68dc6e2afdee329186178a61097ef24caa8b603a3f391d43d6730b06`.

## Delivered source hashes

- `Sources/LightingCore/LightingProjectDocument.swift` SHA-256 `54834f5dd469bcccd7683ac49a95c4efa8b73de20960bdd0fd17f283b505b478`.
- `Tests/LightingCoreTests/ProjectDocumentEnvelopeIntegrityTests.swift` SHA-256 `b5001328927bf361cfae2da14338eabef7fcd1ec73605205119c603a82f38800`.
