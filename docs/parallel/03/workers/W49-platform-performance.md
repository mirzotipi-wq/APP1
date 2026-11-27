# W49 — platform/performance

**Status:** bounded evidence review completed; no builds, Swift, benchmarks, production writes or integration. Task: `/root/wave05/w49_platform_performance`. Private tree: `/tmp/keyfill03-7f4b/workers/W49-platform-performance`. Direct `git rev-parse HEAD`: `c9ff1a71c173774e7b7c794e475f8bdf5d633853`. Read AGENTS.md, acceptance/m02-m03-code.md, parallel/03/WORKER_PROTOCOL.md and agents/OPERATING_PROTOCOL.md in that tree.

**Direct check:** persistent-checkout `docs/parallel/03/evidence/wave05-debug-corrected.log` records 391 XCTest tests/0 failures/14.265s, including five StudyTinyOutputTests; Linux x86_64, Testing Library 6.2.1. Log SHA256: `c003c2f8959f849f40c4f5a7a429a86aab6937be7c80c6d6cf7945654cdb72ff`. The trailing zero-test Swift Testing summary is separate.

**Limitation:** supplied `workers/wave05-evidence/W44-implementation.patch` and `workers/wave05-evidence/W44-StudyTinyOutputTests-root-corrected.swift` were absent under the persistent checkout. Candidate inspection/source association therefore remains attributed to the leader: production SHA256 `4ac702653392d64586d0a472576da64ebe3f68dad7339954232f7c5f6635b141`; corrected-test blob `04fbfd955802014332f57fcd9753273cd65e8304`; Debug arguments `-j 1 -Xswiftc -disable-batch-mode`; W42 Swift 6.2.1 Linux `-O`, 166 checks/56 failures before and 166/0 after. Preserve signal-9, empty-retry and ambiguous-pow failures.

## Exactly three remaining verification needs

1. **Current-source functional/Release evidence:** bind integrated source/test identities, exact commands and finalized Release results; preserve the observed Debug result and required regressions. Historical c9 core-CI pass/native-pending cannot establish candidate acceptance. Attribute any actual native/Metal execution to its tested source; Linux execution is not native evidence.

2. **Ordinary image/parity/precision preservation:** retain twelve configurations, JSON/images, baseline-versus-candidate image hashes, visual review and zero unsupported pixels. Run six CPU/shared-Float32 parity cases: exact invalid-mask positions/counts, mean channel error ≤1, fraction above 4 ≤0.005. Run eight precision cases with maximum channel error ≤1. Preserve deliberate near-field unsupported pixels; distinguish host parity from actual Metal.

3. **Optimized benchmark/resource evidence:** unchanged benchmark, `-O`, one warm-up and ≥7 measured samples per workload; all eight frame workloads, twelve cancellation probes and four visibility workloads. Retain raw samples/p50/p95 and host/compiler/source, repeated-byte agreement, supported-image zero-invalid counts and observed cancellation. Confirm ≤8 further pixel evaluations, no cancelled/failed publication/cache, ≤4 frames/256-KiB RGBA/64-KiB masks, mannequin width ≤144 and 64/1024 sample bounds. Timing is diagnostic, without portable thresholds or device claims.

**Boundary:** intensity-only guarantee; preserved normal-threshold, half-vector and extreme-BRDF limits remain outside it. Keep candidate acceptance unverified pending these three evidence groups.

## Coordinator closeout correction

W41 confirms the canonical artifacts exist under `docs/parallel/03/workers/wave05-evidence/`. The W49 brief’s shortened `workers/wave05-evidence/` paths omitted `docs/parallel/03/`; the failed reads do not indicate artifact loss, and W49’s inspection limits remain unchanged. After W49’s review, root reported optimized per-file Release **391 tests/0 failures, 6.356s**, session17319 exit0, `docs/parallel/03/evidence/wave05-release-serial.log`, with `-j1 -Xswiftc -no-whole-module-optimization -Xswiftc -disable-batch-mode`. The earlier WMO signal9 failure is retained. Standard WMO/native and final campaign render/benchmark evidence remain source-specific.
