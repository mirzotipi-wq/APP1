# W19 — Archived benchmark arithmetic and sampler bounds

Runtime/task: `/root/wave02/platform_performance`. Input: `9c172d3e2d0c3f18636d84e8f31150236c63cbaa`.
Recreated private worktree: `/tmp/keyfill03-7f4b/workers/W19-platform-performance`; clean detached input. The earlier precreated tree was lost before this worker began. Benchmark records source `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Output: `/tmp/keyfill03-7f4b/builds/W19-platform-performance/{validate_benchmark.py,benchmark-checks.json}`. No source edit or commit.

## Result

The Python check exited 0: exact expected membership of **8 frame, 12 cancellation and 4 visibility rows**; all **84 timed samples** finite/positive; every nearest-rank p50/p95 pair reproduced exactly. With seven samples these are the fourth/seventh sorted observations. All eight frame warm-up fields are finite/positive; dimensions, declared samples and zero unsupported counts agree with their configurations.

All twelve cancellation flags are true. Each has positive callback count and `preceding < requested <= observed <= finished`; recorded deadline-to-return equals `finished-requested` within 1e-12 ms. The existing range is 0.050615–3.201887 ms. This is arithmetic on the archived diagnostic, not a new timing measurement or asynchronous UI test.

Source-derived bounds: validation permits at most twelve lights; point/directional emitters prepare one sample, rectangles 8² interactive or 32² reference. Full and clipped evaluation use at most grid² callbacks per rectangle. Thus maxima are **768 interactive / 12,288 reference** samples; benchmark point3/area3 declarations are 3/192, and crowded area12 is bounded at 768. These are static guard/loop deductions, not executed Swift budget tests.

Visibility source invokes one unmeasured warm-up operation; its JSON has no separate warm-up duration/receipt. Archived FNV strings have valid syntax, but frame bytes and repeat determinism were not replayed. The optimized-build flag was read as metadata, not independently rebuilt.

## Actual checks and limits

Read prescribed directives and bounded benchmark/Scene/ReferenceStudy source; Git status/HEAD; `agent_cycle.py check/next` exited 0 (structure/M03 queue only). Ran `TMPDIR=/home/agent/keyfill03-7f4b/tmp python3 /tmp/keyfill03-7f4b/builds/W19-platform-performance/validate_benchmark.py /tmp/keyfill03-7f4b/workers/W19-platform-performance`.

No Swift build/test/render/benchmark, native/Metal, device, RSS, thermal or sustained-FPS measurement. Fixtures and original benchmark remained unchanged.
