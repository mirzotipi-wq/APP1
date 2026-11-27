# W73 — API and encoding provenance

Canonical ID: `/root/wave08/w73_api`; parent `/root/wave08`.
Input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`.
Private tree: `/tmp/keyfill03-7f4b/workers/W73-api`.
Private output: `/tmp/keyfill03-7f4b/builds/W73-api`.
Exact token counters unavailable; 12k working target.

## Result

**PASS for saved-artifact correspondence:** the bounded Python audit exited 0; 232 assertions passed. These are artifact checks, not Swift tests. All twelve final PNGs, PPMs and scene JSON files are byte-identical to their saved originals. All 25 baseline artifact hashes and the stored final-comparison hashes match actual files.

PNGs are RGB8, with only IHDR/IDAT/IEND and valid chunk CRCs. Pillow 13.0.0 decoded RGB equals each PPM payload. Final raw RGBA projects to those RGB bytes, with alpha 255 throughout; final masks contain only zero and match manifest sizes/counts. Original raw RGBA/masks are absent: their byte equality is unestablished.

The fixture writer uses fixed light IDs, sorted-key JSON and deterministic P6 packing that drops alpha. Its reproducibility statement requires unchanged renderer/toolchain. The final probe copies original scene JSON bytes and archives RGBA/masks; original/final manifests intentionally differ in schema. Scene equality therefore verifies preservation, not independent re-encoding.

All 31 LightingCore hashes match `final-source-manifest.json`; App preview and its native tests differ and require their separate evidence. The final source manifest hash is `106dbea66efbcd46b5ebcb0f88610a581c997d962528f7fe3037f6be28f9a78e`.

`ReferencePNG.metadataFree` filters an already encoded imported-photo derivative. `App/ReferencePhoto.swift` calls it after ImageIO encoding. It preserves retained chunks/CRCs; platform code owns pixel/CRC validation. It neither renders fixtures nor canonicalizes alternate PNG encoders.

Saved PNG equality does not establish arbitrary encoder/toolchain equality. The bounded retained-evidence search found conversion described in HANDOFF and W27, but no exact historical encoder command/version. No conversion was rerun.

## Evidence and limits

`wave08-evidence/W73-byte-provenance.json` contains every checked hash, fixture association, source comparison and limit. `W73-verify.py` preserves the executed script; `W73-command-receipt.json` preserves invocation/result and focused provenance search. Initial absent-path/truncated-read events are retained separately.

No production edits, rerenders, benchmarks, builds, Swift/native/Metal/device or physical tests. Root's execution results remain separately owned; this review does not promote a milestone or native acceptance.
