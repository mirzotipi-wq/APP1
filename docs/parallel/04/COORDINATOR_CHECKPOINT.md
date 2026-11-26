# Lane 04 coordinator checkpoint — 60 of 100 workers complete

Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Wave 6 input: `5934f291b8e78e378a96ec3e4d294521c79839d0`. Only `finish/04-metal-cache` is authorized for publication.

## Worker and source checkpoint

Sixty distinct fresh contexts completed six waves of ten. Each wave retained all ten required roles, with at most two active children beside root and the wave lead. Exact canonical IDs, source inputs, reports and same-ID follow-ups are recorded in worker-ledger.json and the per-wave ledgers. Context/token budgets remain workflow targets rather than platform-enforced counters. Planned paths and recovery attempts are never counted as workers.

No cache implementation defect was established in wave 6. The core cache retains its existing LRU, exact-key and separate byte-budget behavior. Four new core tests check reference lifetime during rejected replacement, admitted replacement, byte eviction and selective invalidation; all twelve original methods remain intact.

Six new native methods cover cancelled-hit recency, four actual-CPU cache populations and weak backend ownership after failure. All nineteen original methods remain intact. The candidates expect fifteen per-request resource observations and four final summaries from live actor counters; these are unexecuted expectations until CI runs the new tests.

Final test blobs:

- Core cache tests: `af6a0a4d81bb7bf9ebaeffb717f8f0871f7981de`.
- Native cache tests: `6e811837c87ff3a8a0d8c87c4b0f877c752aae89`.

## Executed evidence now preserved

Wave 4 revision `88279ba0ee0262ea6c880580c8a85b56342abbff` has actual hosted iOS-simulator Metal evidence: job 139973865345 / run 45837392344 passed both simulator build configurations and all 160 native tests, with no skips. Finalized XCTest export and required method accounting passed. The raw metadata method passed its 37 malformed dispatches and two controls. All eight strict Metal precision cases had mean/max/outlier error zero and exact masks. Six canonical Metal cases had a maximum channel error of one, zero outliers and exact masks. Exact rows, raw logs and artifact digests/expiry are in evidence/ci/wave04-native-139973865345.json and its raw log.

Wave 5 revision `5934f291b8e78e378a96ec3e4d294521c79839d0` passed Linux job 139997195555 / run 45844671107: 375 Debug and 375 Release tests, six shared-kernel parity cases and eight strict host precision cases. This is not Apple type checking or runtime execution of its new engine lifecycle tests. Its native job was queued at checkpoint assembly. The new wave 6 tests also await execution.

Four frames, 262144 RGBA bytes and 65536 mask bytes remain fixed limits. Bust rendering remains CPU-only at width 144 maximum; the unchanged CPU pixel loop retains its eight-further-evaluation cancellation bound. CPU authority, packed ABI, fixture definitions and numerical thresholds are unchanged. Cache counters and requested buffer sizes are not RSS, allocator capacity or driver-memory measurements.

## Remaining consumer integration dependency

Worker 057 independently confirmed the preview's A→B→A reuse sequence at lane 03 head `8ce5e464253144deccb39d838faef70f05e0c38c`: after B confirms downgrade plus cancellation, returning to A may reuse a UI-held frame without consulting the now-CPU engine. Old pixels may remain valid; the issue is aligning subsequent adoption/current status with the permanent backend decision, not engine-cache leakage.

The unapplied owner patch and exact hosted regression proposal are preserved under evidence/w057/. Lane 03 owns implementation and execution; lane 20 owns combined integration. No owner acknowledgment, UI edit, compilation or hosted pass is claimed. Existing automatic native discovery should account for the eventual method without a shared harness change.

## Execution limits and next steps

The execution environment remained unavailable throughout wave 6. Workers used separate immutable source snapshots and content-addressed Git blobs; no physical worktrees, local commands, builds or native measurements ran. Local reconstruction/verification remains pending; no cleanup of unavailable work is attempted. Earlier failed/interrupted attempts and original candidates remain preserved.

Wave 7 fills remaining startup, concurrent-request and scene-error coverage without duplicating the matrices already added. Waves 8–10 consolidate exact parity/precision/resource evidence, challenge recovery and finalize HANDOFF.md. The unresolved UI-owner dependency remains explicit. Global milestone/release state is unchanged.
