# Lane 04 coordinator checkpoint — five waves complete

Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Wave 5 input: `88279ba0ee0262ea6c880580c8a85b56342abbff`. Only `finish/04-metal-cache` may be updated. The unchanged upstream native-build correction remains separately identified in ENVIRONMENT_RECOVERY.md.

## Actual work and preserved source

Fifty distinct fresh contexts completed five waves of ten. Each wave has one acceptance worker and nine role-specific workers; at most two children ran alongside the root and wave scheduler. The ledger records exact returned agent IDs. Planned worktrees, recoveries and same-ID follow-ups are not additional workers. Brief/report/context limits are workflow targets; the platform does not expose enforceable live token counters.

Final wave 5 source blobs:

- `App/MetalStudyRenderer.swift`: `8c1acd852d85cd99671feaba883db1808bbb5e68`.
- `NativeTests/StudyRenderCacheTests.swift`: `2af764b51023dc66a9cc0070d8d49f5bd7de334e`.

Confirmed backend failures now select CPU and evict Metal entries before observing simultaneous cancellation. Ordinary cancellation and scene errors propagate; precision-domain fallback remains per request. The original initializer is preserved, with a separate required-factory overload for deterministic lifecycle tests. Production remains actor-confined, without an unchecked Sendable claim. The injection contract requires a fresh backend for exclusive actor use.

Cancellation reaches Metal packing, allocation, submission and completion checks. Submitted commands complete before buffers are released; command failure is inspected before cancellation. Per-frame autorelease pools bound temporary Objective-C ownership. Cache admission follows the final cooperative cancellation check; consumers still guard latest-result adoption after awaiting the engine.

## Verification and limits

The final independent review found no concrete source blocker. Pre-interruption scope checks found 184 protected files unchanged. The original eleven cache tests remain byte-preserved; eight new methods define 45 scripted lifecycle configurations. Native declaration accounting increased from 160 to 168; declarations are not executed tests. Root also passed scoped whitespace and existing shard-assignment checks before the interruption.

At the preceding wave 4 revision, Linux CI job 139971277479 / run 45837392344 passed 375 Debug and 375 Release core tests, six shared-kernel parity cases and eight strict precision cases. All masks matched; six-case maximum RGB error was 1 with zero outlier fraction; strict maximum was 0. Raw logs, parsed rows and optimized CPU host timings are preserved under evidence/ci/. The Apple job 139973865345 is in progress at checkpoint assembly; its results cannot certify the later wave 5 renderer changes. Baseline actual Metal evidence remains separately pinned to 5bf9da7. No native execution of the wave 5 changes is yet claimed.

Four frames, 262144 RGBA bytes and 65536 mask bytes remain the cache limits. The bust remains CPU-only at width 144 maximum, and the untouched CPU renderer retains its eight-further-pixel cancellation bound. Numerical thresholds, fixtures, CPU oracle and packed ABI remain unchanged. Payload/buffer arithmetic is not process or driver memory measurement.

## Environment and next work

The fourth execution interruption occurred during review, with no wave 5 Swift build. Frozen code, completed reports and CI evidence were already durable Git blobs. Later reviewers used exact Git snapshots with their unavailable physical worktrees clearly identified. Final local object reconciliation is pending recovery; no unavailable command is counted as successful. Root can assemble the immutable checkpoint through Git objects while preserving earlier raw evidence.

Wave 6 will test LRU recency under cancellation, weak-reference lifetimes and actual cache payload counters. Wave 7 will fill remaining startup/concurrent-request coverage without duplicating the wave 5 matrix. Waves 8–10 will finalize parity/precision/resource evidence, recovery challenges and the lane handoff. Owner routes remain in OWNER_REQUESTS.md and OWNER_INTEGRATION.md; no external acknowledgment is claimed.
