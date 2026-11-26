# Worker085 concurrency challenge — immutable source review

## Identity and scope

- Actual worker: `/root/w081/w085`; parent: `/root/w081`.
- Input: `53d7302931ccaadd7a2ad29c55fd94a695c5997e`.
- Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
- Production source: `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`.
- Reviewed contract original: blob `11cbd4278db167fa50e5c93ba5cc99f03687074f`. This original is retained by identity, not replaced.
- No source or test changes. Root alone integrates. Planned `/tmp/keyfill04-2987b1ee980d/workers/w085` and `/tmp/keyfill04-2987b1ee980d/results/w085` are UNCREATED.

## Source findings

The [engine](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/App/MetalStudyRenderer.swift) is blob `8c1acd852d85cd99671feaba883db1808bbb5e68`. The [cache](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/Sources/LightingCore/StudyFrameCache.swift) is blob `0731ab93a924572ccacd3dd66e334a85dc7c06e7`. Exact-input fetch_file reads independently confirmed both associations.

| Obligation | Inspected source | Finding and limit |
|---|---|---|
| Hit cancellation before LRU mutation | Engine 224–234; cache 34–40 | Poll at entry and immediately before value(for:). A hit removes/appends synchronously and returns early. No third poll or routing follows a hit. |
| New frame admission | Engine 239–242, 269–271, 285–287, 297–304 | Each successful fresh CPU/Metal path checks cancellation immediately before retain. retain synchronously inserts and returns. A thrown cancellation never admits that call's result. |
| Actor serialization | Engine protocol 21–24, actor 153–304 | Backend creation, validation, rendering and cache mutations are synchronous actor work. No await appears in the frozen engine or cache. Blocking waitUntilCompleted does not introduce an actor suspension. |
| Failure precedence | Engine 254–265, 272–284, 290–295 | Delivered non-scene/non-cancellation failures, including invalidComputeOutput, select CPU and purge Metal before the subsequent predicate. Merely armed failures are not observed if an earlier guard returns cancellation. |
| Cooperative cancellation | Engine 225–227 | Task.isCancelled is evaluated first. If true, OR short-circuits and the additional predicate is not invoked. A false extra result cannot negate a task cancellation already observed true. |
| GPU ordering | Engine 107–115 | Observed pre-commit cancellation throws before commit. After commit the renderer waits; command status is checked before cancellation. This establishes program ordering, not GPU preemption or atomic external cancellation. |

The [baseline engine](https://github.com/mirzotipi-wq/APP1/blob/f150f98e35dd735927075aac4d2f8b02295c6a67/App/MetalStudyRenderer.swift) is blob `a1d60cd94d0b016bb7e06e5e1a8ad7231135865d`. In-memory string comparison found its entry/hit/bust block (175–194) byte-identical to current 224–243. Its complete selectCPU/retain tail is also byte-identical. Both engines contain zero await tokens; inspection confirms synchronous declarations/calls at the relevant boundaries. This is static source evidence only.

## Concrete falsification attempts

1. **Cancelled hit changes LRU.** With A/B/C/D cached, cancellation observed at either entry or pre-lookup guard must throw without touching A. Inserting E then evicts A. The actual regression probes cold A before accessing survivors, so successful survivor lookups cannot conceal a prior promotion. No counterexample survives the source and this assertion sequence.

2. **Task cancellation defeated by the extra false predicate.** If Task.isCancelled is already true when evaluated, the guard throws without evaluating the extra predicate. The real self-cancelled Task test uses an always-false extra closure and asserts StudyError.cancelled. No override exists.

3. **Atomic predicate/return claim.** Consider a new Task whose entry predicate is false. During the hit's second predicate invocation, Task.isCancelled reads false; the extra closure then calls withUnsafeCurrentTask to cancel that Task and returns false. The expression returns false, and promotion/return can proceed. Equivalently, cancellation may arrive externally immediately after any false final poll. These are unexecuted source-level boundary examples, not reported runtime failures. They refute an atomic-cancellation claim, not the cooperative contract. Caller current-request checks remain necessary.

4. **Armed failure plus pre-cancellation must purge.** Seed CPU and Metal entries, arm a backend failure for a new key, then cancel before the entry guard. The guard exits without calling the backend, so no failure is delivered and no downgrade occurs. By contrast, the tested callback that both arms cancellation and throws a confirmed failure reaches selectCPU before the next cancellation check. “Failure wins” must be limited to the delivered-error path.

5. **Another actor request inserts between final check and retain.** No suspension exists in that interval. Cross-actor awaits occur in the caller, not inside this synchronous method. The supplied backend must remain exclusively actor-owned; retaining an external concurrent-use path would violate the injection contract, not demonstrate a production reentrancy defect.

No demonstrated engine defect remained. The independently changing caller's current generation and any UI-held frame are outside this actor's cache invalidation guarantee. This review does not grant UI acceptance or adjudicate the separate owner03 remedy.

## Real test coverage and execution boundary

[Native source](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift), blob `dd068965cf56312ea0feb90578ca9461ba6b1054`, contains 29 methods. The source6 file `6e811837c87ff3a8a0d8c87c4b0f877c752aae89` contains 25; removing only its final class brace leaves an exact prefix of current source. [Portable cache tests](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/Tests/LightingCoreTests/StudyFrameCacheTests.swift), blob `af6a0a4d81bb7bf9ebaeffb717f8f0871f7981de`, contain 16 methods and directly cover promotion, budget eviction, replacement rejection and selective-removal order.

| Native test | Assertions inspected | Source6 raw terminal line |
|---|---|---|
| testCancelledCacheLookupCannotPublishOrDiscardCompletedFrame | Polls 1/2 throw; completed frame remains reusable | 5514 |
| testCancelledHitLeavesFullCacheEvictionOrderUnchanged | Fresh full cache per poll; cold A; B/C/D/E survive | 5520 |
| testCancelledTaskCannotReturnCachedFrame | Current Task cancelled explicitly; extra predicate always false | 5522 |
| testCancelledCPUWorkAndFinalCancellationAreNeverCached | Measured last check and mid-render check; interrupted key remains cold | 5517 |
| testConfirmedComputeFailuresDowngradeBeforeConcurrentCancellation | CPU survives, Metal removed, failed/old keys later CPU, backend released | 5524 |
| testOrdinaryComputeCancellationRetainsBackendAndCompletedCache | Thrown cancellation and completed-render/final-check cancellation; next fresh render Metal | 5542 |
| testStartupFinalCancellationLeavesInitializationRetryable | No admission; backend released; later factory/validation retry | 5585 |

Raw log blob `48500c2b0d1ef8ed6ac2bae8e0a12e4f7e07614d` belongs to source6 `240000fd3f8cb75273eb279be9dcc7f204a5b29f`, run45848953002/job140012314020. Independent extraction found 25 cache pass terminal events, zero failed/skipped cache terminal events. Exact lines are retained in `source6-cache-terminals.log`; metadata `006f0a8f6546adb58e09b9a3942f3d624a842ac3` records the containing 174-method Debug run.

The appended source7 group method (1128–1187) adds three eligible widths before collecting results, checks exactly one factory/validation and three backend calls, compares dimension-distinct images, then arms a throwing backend and probes reverse-order hits. Its checks do not depend on scheduling order and cannot be satisfied by same-image rerenders. It does not force simultaneous execution, prove actor queue fairness, establish cancellation while waiting in the queue, or measure physical GPU concurrency. Source presence is not runtime execution. None of the four appended methods has an Apple runtime result in this review's supplied evidence; root alone monitors that job.

## Corrections requested for original contract

1. Introduce the table as starting at entry, with successful hits returning before remaining routing rows.
2. Say “Cancellation observed at the pre-submission check prevents commit.”
3. Say “Once a confirmed failure is delivered to the engine, downgrade/purge occurs before the next cancellation check.” Qualify the subsequent cancellation outcome on that check actually observing cancellation.
4. Replace “Failed/cancelled calls never admit their unfinished result” with “Calls that throw cancellation or a rendering error do not admit that call's result.” The final check can discard fully completed pixels; an externally cancelled task can still return successfully if cancellation is later than the observed false poll.
5. Say “A false extra predicate cannot override Task.isCancelled when it is observed true.” Retain the explicit non-atomicity/caller-adoption qualification.

These are documentation precision changes; no source edit or broader test expansion is requested. Actor serialization does not guarantee invocation-order execution, external-cancellation atomicity, caller adoption, cancellation latency, or driver-memory reclamation.

## Work actually performed

Immutable GitHub fetch_file/fetch_blob reads, in-memory JavaScript source comparisons and terminal extraction, followed by UTF-8 create_blob artifacts. No executor/shell/SDK probe, builds/tests, physical worktree, cleanup, CI poll/rerun, ref/global-state/source/UI mutation, or oracle/packed-ABI/harness mutation occurred. The supplied source6 log is retained evidence, not a run performed by this worker. Existing numerical, payload and cancellation gates are unchanged.
