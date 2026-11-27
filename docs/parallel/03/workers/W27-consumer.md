# W27 — consumer contract

Runtime/task ID: `/root/wave03/consumer`. Input: `1cefc654630a86ab320e58283957f4e91d6cbce6`. Initial private tree: `/tmp/keyfill03-7f4b/workers/W27-consumer`; verified detached, clean. No source changes/commit.

## Executed checks

`git rev-parse HEAD`, `git status --short`, `git log -4 --oneline`, production `git show`; required directives and relevant fixture/harness/recovery reads; Python SHA256, PPM-length and manifest reconciliation. Temporary detailed JSON disappeared before copying; its completed terminal outcomes are preserved here. Report persistence was verified separately.

All 25 original receipts match: twelve JSON scenes, twelve PPMs, manifest. All twelve PPM dimensions/RGB lengths match; all scenes exist. The historical manifest records twelve passes, zero unsupported pixels, expected RGBA/mask lengths. Fixture, parity, precision, benchmark and acceptance definitions plus CI selectors are byte-identical to `f150f98e35dd735927075aac4d2f8b02295c6a67`.

## Preserved contracts

Twelve: soft, hard, warm, bust-soft, bust-hard, bust-side, key-only-hard, fill-only-soft, bust-rim-only, bust-roll-90, exposure-minus-two, white-balance-3200. Sphere: 120×80; bust: 144×96.

Six parity: hard, soft, warm-rotated, dark, near-field, translated; width 96. Counts and every invalid-mask position must match; mean RGB error ≤1; fraction above 4 ≤0.005. Near-field deliberately permits unsupported pixels.

Eight selected precision cases: `area-camera-{19.0,19.999999,20.0}-lens-{85,200}` and `world-translation-{77,-77}`, width 192, maximum channel error ≤1. The generator also contains other probes; CI selects these eight.

RGBA remains opaque, with separate binary one-byte validity flags. Binary harness alpha transports flags. PPM retains RGB only: its hash cannot recheck alpha/masks. PNG conversions are outside the 25 receipts. Benchmark FNV hashes cover RGBA; repeated full `StudyImage` equality checks more metadata.

## Impact and disposition

Mesh intersection/normal changes can affect all five bust fixtures, primary hits, shadows, four bust frame workloads, twelve cancellation probes and four visibility workloads. Early cancellation changes sphere polling/preparation and timing; default-false fixture paths retain sphere pixel math. Six parity/eight precision cases never use the mesh.

**Scoped acceptance:** fixture/threshold and original-artifact preservation verified. Recovery retains observed `allTwelveUnchanged:true`/`supported:true`; its comparison file is missing. This cannot independently establish current byte equality. Fresh twelve-image output/visual review, parity/precision execution or explicit unchanged-path justification, and optimized benchmark remain integration evidence requirements. Historical bytes/timings do not establish those passes. No Swift build, render, benchmark, visual review or native/Metal execution here. Later camera changes are outside this fixed-input review; W21 owns test-log reconciliation.
