# W62 — geometry/data

**Status:** complete; Python byte checks passed. No implementation change.

**Assignment:** verify six saved parity fixtures, unsupported-mask serialization, all 84 near-field positions, and twelve final scene masks. **Actual runtime ID:** `/root/wave07/w62_geometry`. **Input SHA:** `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`. **Private tree:** `/tmp/keyfill03-7f4b/workers/W62-geometry`; **output:** `/tmp/keyfill03-7f4b/builds/W62-geometry`.

## Results

All six binaries are 96 × 64 and match their SHA256 entries in `final-parity-inputs.json`. Six little-endian UInt32 fields occupy 24 bytes, followed by 16-byte Float32 rows and exactly 24,576 RGBA bytes. Every header, offset, file length and sample/area count is valid; float rows are finite.

The near-field binary contains exactly 84 alpha-zero pixels, matching its unsupported count. Every one is `(255,0,255,0)`; their bounding box is x=43…52, y=28…38. The other five binaries contain zero invalid positions. Every alpha is 0 or 255. CPU source retains opaque RGBA plus a separate 0/1 mask; serialization transfers that mask into alpha. Python conversion/re-encoding preserved every byte.

All twelve `final/*.mask` files contain only zeros: 136,320 bytes checked, with lengths matching PNG header dimensions (120 × 80 or 144 × 96). These synthetic scenes are separate from the intentionally unsupported near-field case.

## Evidence and limits

Executed: Python `struct`/`hashlib` assertions and Git identity checks. Exact indices/coordinates are in `wave07-evidence/W62-near-field-invalid-indices.csv`; source blobs/hashes, offsets and individual results are in `W62-fixture-metadata.json` and `W62-geometry.json`. Sources/Tests/scripts trees match fixture source `db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5`.

No Swift, kernel, native Metal, render, build or physical test ran. Existing six-plus-eight host passes remain root's evidence; the width24 silhouette witness was not re-evaluated. No source/tests/scripts edits, commits or refs changed. Sampling counter unavailable; 12k/60% budgeting was qualitative. One nonexistent guessed source-path read exited 2 and was corrected; JSON preserves it.
