# W75 — concurrency evidence reconciliation

- Canonical ID: `/root/wave08/w75_concurrency`; status: completed, inspection only.
- Input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`.
- Private tree: `/tmp/keyfill03-7f4b/workers/W75-concurrency`; outputs: `/tmp/keyfill03-7f4b/builds/W75-concurrency`.
- Evidence: `wave08-evidence/W75-reconciliation.json` contains exact methods, coverage, statuses, full SHA-256 values, workload hashes, provenance and inspection failures.

**Pipeline accounting:** saved original suite **9/9**; added-regression run **10 attempted, one failed method/two assertions**; corrected run **10/10**. These are ten pipeline tests, **three directly cancellation**. The seven others cover generation ordering/adoption/invalidation, retry and conversion failure. No Swift tests were executed by W75.

Current preview SHA-256 `45a89961…0595fc6` and tests `a68a38ab…5407c99` exactly match `preview-wave06-inputs.json`. The earlier nine-test and final-source manifests contain older preview/test hashes. Differences are cancelled-begin/task guards, paused presentation and one added regression; the original nine test bodies remain intact. The deterministic MainActor witness does not reproduce SwiftUI scheduling.

**Benchmark:** final report SHA-256 `85d66183…890b993` matches its input manifest. Its raw revision remains `74f7584…`; the manifest identifies actual compiled input `db7a5b5…`. Current LightingCore and benchmark script are unchanged from that input; all 31 core hashes match the final-source manifest. All eight saved frame hashes agree across baseline/current/final reports. Seven measured renders per workload compared equal to warm-up; zero unsupported pixels. Four visibility workloads remain recorded. All 12 saved cancellation probes cancelled; derived deadline-to-return range **0.043202–1.606625 ms**, nearest-rank p50 **0.640759 ms**. These are saved host diagnostics, not fresh timing or an eight-pixel-bound measurement.

**Review:** no concrete contradiction found in ticket adoption, retry, paused states or obsolete cancelled attempts. Engine/cache bounds were inspected without modification. W75 ran hash/log/JSON/git checks and structural `agent_cycle.py check/next`; no builds, rendering, native/Metal/device tests or commits. Two corrected read-only inspection errors are retained in the JSON. Native method accounting and SwiftUI execution remain outside this receipt. Exact token counters were unavailable.
