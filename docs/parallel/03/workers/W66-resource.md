# W66 — resource review, wave 07

**Role/assignment:** bounded Study samples, dimensions, cache and polling; lane02 name-byte distinction. **Actual runtime ID:** `/root/wave07/w66_resource`.

**Input:** `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; tree `bba62b3555a03cdbd6dcb47a419a433d996c82f7`. Private tree: `/tmp/keyfill03-7f4b/workers/W66-resource`; assigned outputs: `/tmp/keyfill03-7f4b/builds/W66-resource` (unused). Full source/test blob IDs and SHA-256s are in `wave07-evidence/W66-resource.json`; ReferenceStudy blob is `82e54a53f3d32d745aee1edfa297086504fb81ec`.

**Status: source review complete; execution acceptance unclaimed.**

- `StudyLighting` validates the entire scene before skipping zero-output lights. Scene admission caps lights at 12. Rectangle grids are 8×8 interactive and 32×32 reference: at most 768/12,288 prepared samples across twelve rectangles. Clipped sampling retains these limits; tiny-output restoration adds scalar work per emitter, no numerical loop.
- Widths are 24–192 interactive, 24–96 reference and 24–144 mannequin, divisible by three; height is two-thirds width. Largest frame: 98,304 RGBA bytes plus 24,576 mask bytes. Compute-output admission checks exact dimensions/payload before copying.
- Production constants live in `App/MetalStudyRenderer.swift`: four completed frames, 256 KiB RGBA and 64 KiB masks. `StudyFrameCache` rejects invalid costs and evicts before append using subtraction to avoid overflow. These are retained payload bounds, not resident-memory measurements. Successful render admission follows a final cancellation check.
- Both CPU pixel loops check before every pixel through the shared eight-pixel countdown, including background pixels, plus a final check. The narrow test explicitly models cancellation immediately after a false poll and expects eight further evaluations. This is a pixel-work bound, not wall-clock latency.
- `Scene.swift` still trims names and checks `name.count <= 80`; no name-byte bound exists at this pin. Text scan cost depends on input representation length; 80 graphemes does not bound UTF-8 bytes. Cache keys remove names only after validation. The codec’s 1 MiB file limit does not bound direct in-memory callers. A byte policy remains owner01 work; whole-wrapper O(1) is not established.

**Actually executed:** instruction/source/test reads, targeted searches, clean-tree/HEAD checks and hash inspection. Narrow cancellation, cache, scene-admission and dimension tests were reviewed, not run. No builds, tests or benchmarks; root’s 8/12/4 workload evidence was not rerun or reclassified. No session interruption. Token counter unavailable; no measured 60% checkpoint. No source edits or commits.
