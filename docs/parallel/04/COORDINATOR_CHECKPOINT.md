# Lane 04 coordinator checkpoint — 70 of 100 workers complete

Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Wave 7 input: `240000fd3f8cb75273eb279be9dcc7f204a5b29f`. Publication is restricted to `finish/04-metal-cache`.

## Workers and source

Seventy distinct fresh contexts completed seven waves of ten. Each wave retains all ten required roles, with at most two active children beside root and the wave lead. Exact canonical IDs, input revisions, reports and same-ID follow-ups are in worker-ledger.json and the per-wave ledgers. Budget figures remain workflow targets rather than platform-enforced counters. Planned paths are never counted as workers.

Wave 7 changes only NativeTests/StudyRenderCacheTests.swift (blob `dd068965cf56312ea0feb90578ca9461ba6b1054`). Four methods are appended; all 25 previous methods and helpers are preserved verbatim. They cover cached CPU preservation across startup failure plus cancellation, cancelled validation followed by retry, distinct concurrent request identities with one startup validation, and steady-state scene-error propagation without cache admission or backend downgrade. Independent worker 070 and root found no required source correction. These additions have not yet compiled or executed.

## Exact evidence

At source `240000fd3f8cb75273eb279be9dcc7f204a5b29f`, core job 140009926092 / run 45848953002 passed 379 Debug and 379 Release tests. All four new core cache lifetime tests passed in both configurations. The six host shared-kernel canonical cases and eight strict precision cases passed with zero mask mismatches. Raw log and parsed receipt are under evidence/ci/wave06-core-140009926092.

Native job 140012314020 for that source has passed the Debug app/native-bundle and Release app builds. Simulator warmup/runtime/accounting remain pending at checkpoint preparation. Build success is not a native runtime pass. Root will preserve its terminal outcome before publishing the next source checkpoint.

Historical source `88279ba0ee0262ea6c880580c8a85b56342abbff` passed actual simulator Metal job 139973865345: 160 native tests, no skips, canonical 6 max channel error at most one with zero outliers and exact masks; strict 8 zero channel errors and exact masks. Its 37 malformed dispatches and two valid controls passed. These results do not execute the later renderer lifecycle changes. Superseded wave 5 native job 139999727724 is confirmed cancelled; its cancellation receipt is retained without claiming a native pass.

The pending wave 6 native resource tests emit fifteen per-request observations and four summaries from actor payload counters. Expected cache populations are not measurements until observed. Four entries, 262144 RGBA bytes and 65536 mask bytes remain unchanged; bust stays CPU-only at maximum width 144. Cache payload and buffer arithmetic are not allocator capacity, process RSS, driver memory or device performance.

## Fallback and consumer obligations

CPU remains authoritative. Precision eligibility is an engineering routing guard, not a universal floating-point error proof. Ordinary StudyError.cancelled leaves startup retryable and never admits a frame; confirmed compute failure permanently selects CPU and evicts Metal frames before honoring concurrent cancellation. Existing completed CPU frames survive. Scripted backend tests are lifecycle evidence, not GPU execution. A custom injected backend must use StudyError.cancelled; generic Swift CancellationError currently enters catch-all and no production caller emitting it was found.

The known lane 03/20 consumer dependency remains unresolved: after A/Metal is displayed and B confirms downgrade plus cancellation, returning to A can bypass the engine via a UI-held successful frame. Old pixels may remain valid; subsequent current status/adoption must agree with the engine policy. The unapplied patch and hosted regression proposal under evidence/w057 are routed to lane 03, with lane 20 responsible for combined integration. No UI edit, owner acknowledgment, compilation or hosted regression pass is claimed.

## Execution and continuation

Local execution remains unavailable. Wave 7 used immutable Git snapshots and separate session state; no physical worktree, local command, Swift build or native execution ran in its worker contexts. Earlier interrupted/failed attempts and candidates remain preserved; no unavailable work is cleaned up.

Wave 8 consolidates exact parity and precision fixtures; wave 9 challenges recovery and documents the fallback contract; wave 10 delivers HANDOFF.md, resource results, CI manifest and final independent review. No global milestone or release state is promoted.
