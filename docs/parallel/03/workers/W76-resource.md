# W76 resource review

- Canonical ID: `/root/wave08/w76_resource`; input `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`.
- Private tree: `/tmp/keyfill03-7f4b/workers/W76-resource` (detached, clean); output: `/tmp/keyfill03-7f4b/builds/W76-resource`.
- Status: **PASS: archive checks and scoped source inspection**. No Swift test, build, render or benchmark executed.
- Evidence: `wave08-evidence/W76-resource-audit.py`, `W76-resource-checks.json`; receipt SHA-256 `b38234dd29c6507942468faf34eb69a6f7120a3b778fe5f9267baa5ee2e110bd`.

## Verified resources

All twelve final manifest records match actual RGBA/mask lengths, PNG dimensions and PPM dimensions/lengths: seven spheres at 120×80; five mannequins at 144×96. A sphere contains 38,400 RGBA + 9,600 mask bytes; a mannequin 55,296 + 13,824. Aggregate: **545,280 RGBA + 136,320 mask = 681,600 bytes**, covering 136,320 pixels. Archived PPMs total 409,128 bytes; PNGs 43,588; scene JSON 12,698. These sixty fixture files total 1,147,014 bytes; the manifest adds 3,232. Raw alpha is uniformly 255 and masks zero.

Pinned source enforces mannequin width ≤144, twelve scene lights, 64/1,024 samples per rectangular emitter (≤768/12,288 scene samples per surface), and cancellation polling every eight pixels. The cache admits ≤4 frames, ≤262,144 RGBA bytes and ≤65,536 mask bytes. Four maximum mannequins need 221,184 RGBA +55,296 mask bytes; a 192×128 sphere needs 98,304 +24,576, so only two such frames fit. These are retained-payload maxima, **not measured process memory**.

Names are trimmed and counted (≤80 Swift Characters), with no UTF-8 byte cap. Cache keys remove names after validation. Numerical/sample-array bounds do not bound caller input storage or arbitrary-name validation cost; cancellation's pixel bound is not a validation-time guarantee. Lane02 owns name policy.

## Archived benchmark

Actual arrays contain **56 frame measurements (8×7), 28 visibility measurements (4×7), and 12 successful cancellation probes**. All twelve p50/p95 pairs recompute correctly; frames report zero unsupported pixels. Visibility uses 1,000 evaluations/sample over 34 receivers (28,000 measured evaluations). Eight frame warm-up timings are stored; four visibility warm-ups are source-confirmed.

Benchmark hash matches its binding; all four bound source hashes and all 31 core hashes match this input. Raw revision remains 74f7584; binding identifies compiled source db7a5b5. No concrete resource mismatch found. Native/device timing is unrun; prior failures remain untouched.
