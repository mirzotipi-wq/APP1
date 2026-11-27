# w059 — platform/performance review

Canonical ID: `/root/w051/w059`; wave06/lane04; campaign `f150f98`.
Input: `5934f291b8e78e378a96ec3e4d294521c79839d0` (brief authoritative).

Planned directories `/tmp/keyfill04-2987b1ee980d/workers/w059` and `/tmp/keyfill04-2987b1ee980d/results/w059` were not created. Actual work used immutable Git snapshots and session state. All ten mandatory exact-ref documents were read; current lane scope governs stale main handoff.

Executed: one narrow source falsification pass plus JavaScript arithmetic. Local status/HEAD/history, agent_cycle check/next, hash-object, probes, builds, native/runtime checks and benchmarks were unavailable/unrun.

## Findings

No mismatch found. ReferenceStudy.swift packs six 16-byte parameter rows, three rows per sample and three per area. For twelve positive rectangles at interactive 8×8 and 192×128 output:

- Parameters: 6×16 = 96 bytes.
- Samples: 12×64×3×16 = 36,864 bytes.
- Areas: 12×3×16 = 576 bytes.
- Output: 192×128×4 = 98,304 bytes.
- Requested buffers: 135,840 bytes; dimensions add eight, totaling 135,848.

Metal bindings match shader slots 0–4. Empty bindings receive a dummy row; this workload has none.

Engine Data counts and generic LRU subtraction checks support these RGBA/mask totals:

- Four 24×16: 6,144/1,536.
- Four 144×96 busts: 221,184/55,296.
- Three 192×128 spheres retain two: 196,608/49,152.
- Three busts then one sphere retain two busts plus sphere: 208,896/52,224.

Before mixed eviction, 264,192/66,048 exceeds both limits. One oldest bust suffices.

Candidate `6e811837c87ff3a8a0d8c87c4b0f877c752aae89` plans 15 per-step plus four summary rows from live cacheUsage, independently cross-checked against image counts. Zero rows executed here.

These are source-derived payload calculations, not observed native allocations, driver memory or RSS. Host kernel, mocks, simulator Metal and device evidence remain distinct.

Next: root obtains the existing native run’s 19 actual rows. No source/test/UI/ref/commit changes.

Evidence: `docs/parallel/04/evidence/w059/arithmetic-review.json`, blob `e0234d199f8940ffa3565a36132f1ab3c1d160f4`.
