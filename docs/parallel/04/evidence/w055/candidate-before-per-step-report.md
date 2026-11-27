# Worker 055 — native cache tests

**Canonical ID:** `/root/w051/w055`; concurrency/native cache-resource test writer, lane 04, wave 06.  
**Input SHA:** `5934f291b8e78e378a96ec3e4d294521c79839d0` (campaign `f150f98`).

Only `NativeTests/StudyRenderCacheTests.swift` changes. Six additions preserve all 19 original methods and yield 25:

- Full A/B/C/D LRU cancellation at polls 1/2, followed by E insertion, proves A remains the eviction target.
- Four real-CPU fixtures check actual dimensions, image arrays, actor `cacheUsage`, budgets and retained identities. They cover small frames, maximum busts, maximum spheres and mixed subjects.
- A weak observer checks release after command, allocation and invalid-output failures with/without cancellation. An explicit nil control checks observer ownership; the factory creates locally and captures no backend. The same actor remains usable afterward.

Compact runtime `KEYFILL_CACHE_RESOURCES` rows contain only generic fixture names and numeric dimensions/counts. All expected totals remain assertions awaiting execution.

Actual checks: exact-SHA startup/source reads; in-session JavaScript reconstruction reproduces the complete original source, confirms 25 unique methods and preserves the final newline. Coordinator source review found no defect; final independent review is pending. Source blob: `e264fac9e4f521a0ca61cdf9f590530f3d4678ba`.

Planned paths `/tmp/keyfill04-2987b1ee980d/workers/w055` and `/tmp/keyfill04-2987b1ee980d/results/w055` remain uncreated. Actual work used immutable GitHub snapshots in functions session state. Local status, agent_cycle, hash-object, Swift compilation and tests were unavailable/unrun.

Next: root reconstructs/reviews the blob, executes the focused Xcode command in [the evidence](../evidence/w055/native-cache-source-review.json), captures all 25 outcomes and four actual rows, then runs unchanged integrated CI. Root alone integrates/pushes. Compilation, ARC behavior and added render cost remain unverified. These checks address actor payload/mock lifetime; driver memory, RSS, simulator Metal and physical results remain separate.

The longer initial report is retained as [original-report-v1.md](../evidence/w055/original-report-v1.md).
