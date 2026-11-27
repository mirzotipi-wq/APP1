# W03R06 — point/directional resource bounds

Revision: `1b286885cb803ba17e159713651515ab119e17f1`.
Worktree: `/tmp/keyfill02-r2-workers/w03r06`.

**Result: numeric paths pass; an unconditional whole-wrapper resource bound is not established.**

Inspected `Sources/LightingCore/SurfacePhotometry.swift:4–18,87–100`, `StudioOptics.swift:38–42,58–94,100–131`, and `Scene.swift:11–16,33–36,94–100`. Numeric point/directional evaluation has no loop, recursion, variable-sized collection, or geometry-dependent sampling. Per successful `StudioPhotometry.illuminance` call, point uses one normalization/two explicit square roots; directional uses at most seven normalizations/eight explicit square roots, one `hypot`, and one sine/cosine pair. Both call the point evaluator once. Position validation constructs fixed three-element arrays: at most six validations (18 component visits) for point and ten (30) for directional, including explicit aim targets and nonzero roll. These are source-level counts, not measured timings or allocation instrumentation.

**Caveat:** `StudioLight.isValid` trims and counts the supplied name before accepting its ≤80-character limit (`Scene.swift:34`). Point invokes this once; directional twice. Work can scale with arbitrary input string bytes, and ≤80 Swift Characters does not bound combining-mark bytes. Therefore the numeric O(1) claim must exclude string validation; no production change proposed here.

**Lane01 consumer request:** define bounded name admission for direct API calls, with bounded traversal before trimming and explicit Unicode/persistence compatibility decisions; retain the numeric-kernel resource claim separately.

At `2026-11-26T12:59:26Z`, allocated worktree/private-output sizes were **2,342,912/28,672 bytes**; apparent sizes **1,885,925/26,543 bytes**. Host `MemAvailable` was **2,702,952 KiB** of **10,206,472 KiB**. Cgroup v2 memory files were unavailable; no process-memory or device-performance claim. Source inventory: 31 Swift files/5,450 lines; three inspected files total 460 lines.

Reproduce: `cd /tmp/keyfill02-r2-workers/w03r06` then `python3 private-output/audit_resources.py`. Exact commands, exits, hashes, excerpts, `du`, `df`, and memory output: `private-output/commands-and-output.log`; structured counts: `private-output/resource-snapshot.json`. No build/benchmark, production edits, or gate changes; 1% point/5% area requirements retained.
