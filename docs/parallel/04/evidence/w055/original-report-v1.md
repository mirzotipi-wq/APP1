# Worker 055 — native cache regressions

**Canonical ID:** `/root/w051/w055`  
**Role:** concurrency/native cache-resource test writer; lane 04, wave 06.  
**Input:** `5934f291b8e78e378a96ec3e4d294521c79839d0` (campaign baseline `f150f98`). The launch brief supplies the packet's null input SHA.

## Scope and implementation

Only `NativeTests/StudyRenderCacheTests.swift` changes. Six added methods bring this class from 19 to 25 tests. All original source bytes remain intact around one appended block. No engine, cache, CPU oracle, preview, harness, configuration, state or handoff changes were made.

The full-LRU regression fills A/B/C/D, cancels a hit on A at entry or immediately before lookup, then inserts E. It probes A's eviction before survivor hits. Promoting A before observing cancellation instead evicts B and fails both checks.

Four real-CPU fixtures assert engine `cacheUsage`, actual image dimensions and array lengths, both byte budgets, entry count and retained identities. Required expected RGBA/mask totals are 6,144/1,536 for four 24×16 frames; 221,184/55,296 for four 144×96 busts; 196,608/49,152 for two retained 192×128 spheres after three requests; and 208,896/52,224 for two busts plus one sphere after four requests. Bust requests also check width clamping. These are assertions, not observed measurements.

Runtime logging emits compact `KEYFILL_CACHE_RESOURCES` JSON with generic fixture, dimensions, count, pixelBytes and maskBytes. Counters come directly from the actor. The logs contain no scene names or image bytes.

The weak observer first proves it releases an explicitly cleared external reference. Its injected factory creates each backend locally and captures only the synchronized script and weak observer. Command, allocation and invalid-output failures, with and without cancellation, must release the backend exactly once while the same actor remains usable and its CPU frame survives.

## Evidence and limits

All mandatory startup documents and supporting sources were read at the exact input SHA. Actual in-session JavaScript checks confirmed complete original-source reconstruction, 25 unique methods and the final newline. GitHub accepted the full candidate blob `e264fac9e4f521a0ca61cdf9f590530f3d4678ba`. Coordinator source review found no defect; final independent review remains pending.

The planned paths `/tmp/keyfill04-2987b1ee980d/workers/w055` and `/tmp/keyfill04-2987b1ee980d/results/w055` were not created. Actual mode was immutable GitHub snapshots held in functions session state. Local status, agent_cycle, hash-object, Swift builds and tests were unavailable and unrun.

Next: root reconstructs and reviews the blob, then executes the exact focused Xcode command in [the evidence record](../evidence/w055/native-cache-source-review.json), obtains all 25 method outcomes and four actual resource rows, and runs unchanged integrated CI. Root alone integrates/pushes. Native compilation and maximum-size render cost remain unverified. Actor payload and mock lifetime evidence cannot establish driver memory, RSS, simulator Metal parity or physical-device performance.
