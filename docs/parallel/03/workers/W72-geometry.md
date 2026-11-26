# W72 — geometry/data review

**Status:** accepted for this scoped archived-image review; no production changes or rerender requested.

**Identity/input:** actual `/root/wave08/w72_geometry`, parent `/root/wave08`; input `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`. Private tree `/tmp/keyfill03-7f4b/workers/W72-geometry`; outputs `/tmp/keyfill03-7f4b/builds/W72-geometry`.

**Executed:** directly viewed both original/final contact sheets and all ten bust PNGs: soft, hard, side, rim-only and roll-90. Ran the archived-byte Python parser, read the mesh, compared baseline profile/surface implementation, and ran repository `agent_cycle.py check`/`next` (structure/queue only).

**Findings:** no new silhouette or shading defect observed. Crown, ears, jaw, neck and shoulders agree visually. The narrow crown is authored: original/current profile and `surfacePoint` bytes match; width 0.032 m at y=0.130 m tapers to zero at y=0.143 m. The whole mesh file has changed intersection/normal handling. Roll-90 rotates the emitter, not the bust.

All twelve PPMs and scene JSONs are byte-identical original→final; zero changed pixels. PNGs decode as 8-bit RGB, exactly matching PPM and final raw RGBA RGB. All final alpha bytes are 255; all 136,320 mask bytes are zero. Five busts: 144×96, 55,296 RGBA bytes and 13,824 mask bytes each; seven sphere images: 120×80. Contact sheets differ only as presentation artifacts (1840×975 versus 1120×660); individual fixture dimensions agree.

All 31 LightingCore inputs match the final-source manifest; no LightingCore diff from `db7a5b5`. Mesh SHA-256: `2f4be2a16daf9758d38bb184e735c9ae130797d01327cf78a1563b783826c637`.

**Evidence:** `wave08-evidence/W72-parser-receipt.json` (per-file hashes, dimensions, checks), `W72-source-receipt.json`, `W72-visual-receipt.json`, `W72-verify.py`, and `W72-artifact-hashes.json`.

**Limits:** original raw RGBA/masks are not archived; original opacity/mask claims are manifest-only. No build, benchmark, native/Metal/device execution, physical fidelity or milestone-completion claim. Existing camera-clipping diagnostics remain separate. No runtime reset; optional command-receipt write failed ENOSPC, leaving a zero-byte file. Failure is preserved in `W72-write-failure.json`; earlier artifacts survived. Historical failures untouched. Exact token counters unavailable; working target 12k, no precise 60% checkpoint asserted.
