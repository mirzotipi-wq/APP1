# W93 — API and final fixture correspondence

Worker `/root/wave10/w93_api`, parent `/root/wave10`; private tree
`/tmp/keyfill03-7f4b/workers/W93-api`, clean at
`342e3280e3eb077d55e122c8bfb88b4062b431ed`. Exact token counters unavailable.

## Findings

No source/API or retained-artifact mismatch found within this audit. The app-facing
`ReferenceStudyPreview(scene:subject:)` entry and default sphere remain intact at both
ordinary call sites. The Swift type is internal; its renderer injection remains an
internal hosted-test seam. Source inspection is not a native typecheck.

All 31 portable-core hashes match `final-source-manifest.json`, including Scene,
SceneCodec, SceneFileStore, LightingProjectDocument and ProjectLibrary. The core,
fixture generators and shared host harness have no diff from
`db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5`. Packed input remains six parameter
float4 rows, three rows per sample and three per area. The historical preview and
pipeline-test hashes differ as expected; their evidence is separate.

The exact inventories and every checked hash are in `wave10-evidence/W93-api.json`:

- Twelve ordinary synthetic images: all final RGBA alpha bytes are 255; all raw
  mask bytes are zero. Final PNG/PPM/scene JSON bytes match their saved originals.
  Original raw RGBA/masks are absent; their byte equality is unestablished.
- Six host parity cases: retained logs pass with zero mask-position mismatches;
  near-field deliberately has 84/84 unsupported pixels. These are not ordinary
  zero-unsupported image fixtures.
- Eight required precision cases: retained strict logs pass, maximum RGB error
  zero against limit one. The other 25 generated probes (9 tangent, 14 near-mask,
  2 light-distance) remain a separate diagnostic inventory without a pass claim.

## Verification and boundary

Ran `python3 docs/parallel/03/workers/wave10-evidence/W93-audit.py` using its absolute
report-root path from the private tree: exit 0, **487 artifact/source assertions**,
no execution errors. JSON SHA-256:
`6c3a7d493d2c87d672c4375b60b4b483e74a06b728682b8d0b784af74c669815`.
Commands, source hashes, binary headers, scene mappings and log hashes are retained.

Root-owned `ci-core-342.json/.log` independently records 391 Debug/0 and 391
Release/0 plus 6+8 host successes. Current native 165 remains pending at this
receipt; prior source `36ed6a1`'s 164 passes do not execute the added hosted test.
No build, render, Swift/native test, cleanup or production edit ran here. Retained
CPU evidence carries forward because its source is unchanged; no milestone or
native acceptance is promoted.
