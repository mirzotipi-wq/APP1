# W63 API — wave 07

**Status:** source review complete; packed layout preserved; lane04 integration remains paired.

**Identity:** API specialist; actual ID `/root/wave07/w63_api`; input `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; private tree `/tmp/keyfill03-7f4b/workers/W63-api`. Assignment: compare CPU packing, metadata and consumer signatures against lane04 `88279ba0ee0262ea6c880580c8a85b56342abbff`.

| Buffer | Contract, each row a float4 |
|---|---|
| Parameters 0–3 | subject-relative camera origin/half-width; forward/half-height; right/sphere radius; up/panel half-extent |
| Parameters 4–5 | Bradford ratios/exposure; sample count/area count/minimum depth/grid=8 |
| Sample 0–2 | subject-relative position/restored candela; emitting normal/normal-present flag; XYZ/zero or one-based area index |
| Area 0–2 | subject-relative center/minimum distance; right/half-width; up/half-height |

`StudyComputeInput` and `computeAreas` blocks exactly match the latest04 receipt. `computeSamples` differs only by `s.candela * s.outputScale`. Ordinary output retains scale 1; tiny emitter accumulation changes Double numerical policy without changing layout. Positive Double intensity may still become Float zero. Both inspected kernels check distance and validity before zero-lux return and retain rectangle guards; no mask defect established.

`StudyImage` retains dimensions, RGBA, count and separate 0/1 unsupported mask; compute alpha-zero magenta becomes opaque plus mask=1. Public `ReferenceStudyRenderer.render` and `PortraitStudyRenderer.render` signatures satisfy latest04 consumer calls. `ReferenceStudyPreview(scene:subject:)` remains available.

CPU36 exposes only `supports(scene)`; latest04 adds `supports(scene,width:)` while preserving its one-argument wrapper. Its consumer and helper must integrate together. Preserve CPU db7 tiny-output work when combining branches; width-aware routing is lane04-owned, with runtime behavior unverified here.

**Evidence:** Sources/Tests/scripts tree IDs equal db7; ReferenceStudy blob `82e54a53f3d32d745aee1edfa297086504fb81ec`. Only preview and its native test changed in compared code paths. JSON records exact source SHA256s, blob identities and checks. Executed reads, hashes and git comparisons only; private tree clean. No builds/tests/native execution, edits to production/tests, commits or pushes. Existing six parity/eight precision gates are retained, not rerun. Token/checkpoint counter unavailable.
