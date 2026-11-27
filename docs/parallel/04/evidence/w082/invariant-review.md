# w082 invariant challenge evidence

## Scope and method

This is a read-only source challenge of the immutable lane04 input `53d7302931ccaadd7a2ad29c55fd94a695c5997e`, baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. Source freeze supplied by the parent: `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`. Packet blob: `25bb71b558fa0ea579ca895c918e2e87e3ab87a5`.

The renderer, cache and native test contents fetched by blob were subsequently confirmed byte-for-byte against their paths at the input commit. All ten mandatory project/acceptance files were read. See [source-manifest.json](source-manifest.json) for all 15 successful path-to-blob identities. The failed speculative `AppTests/StudyRenderCacheTests.swift` read returned GitHub 404 and is retained in the operation receipt; the authoritative path is `NativeTests/StudyRenderCacheTests.swift`.

No Swift, XCTest, build, shell command, CI query or physical experiment ran. The traces below are manual source deductions, not executable models or observed test outcomes. Existing run outcomes supplied by the parent were not independently polled. No implementation change is proposed.

## Source invariant

[The actor render method](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/App/MetalStudyRenderer.swift#L224) is synchronous. It creates the combined task/predicate cancellation check, checks before cache promotion, and has no suspension between final guards, retain and return. The only backend state transitions are unchecked to metal after successful validation, and unchecked/metal to CPU through selectCPU. Once CPU is selected, no route resets it to unchecked or metal.

[selectCPU](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/App/MetalStudyRenderer.swift#L290) assigns CPU and removes every frame labeled Metal. It leaves CPU values and their keys untouched. [Selective removal](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/Sources/LightingCore/StudyFrameCache.swift#L71) visits indices in reverse, subtracts each removed entry's costs and preserves survivor order.

The .invalidComputeOutput and catch-all failure paths call selectCPU before the subsequent cancellation guard. StudyError.cancelled propagates without downgrade. A success followed by observed cancellation throws before retain. A precision-domain exception routes only that request through CPU while preserving the existing backend state.

“Failure plus cancellation” requires the error actually to be delivered. An entry/pre-dispatch cancellation prevents the callback from running; an armed but unobserved failure does not justify downgrade. Submitted Metal work waits for completion, checks command failure before cancellation and retains its buffers until then. This establishes neither GPU preemption nor physical memory release.

## Real assertion inventory

The native file has 29 test methods. The portable cache file has 16. These are source inventories, not executed counts.

| Challenge | Assertions actually present | Boundary |
|---|---|---|
| CPU cached + Metal cached + confirmed failure/cancel | [Native confirmed-compute regression](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift#L454): command, allocation and invalidComputeOutput; only CPU usage remains; CPU hit survives; failed key and previous Metal key return CPU-oracle equality; factory/validation/render counts stay 1/1/2. | One CPU and one Metal entry in this native method. |
| Ordinary compute cancellation | [Native ordinary-cancellation regression](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift#L494): thrown StudyError.cancelled and successful return with cancellation; original Metal hit remains; release count stays zero; interrupted key requires a third render without new factory/validation. | Scripted lifecycle backend, not actual GPU pixels. |
| Startup known failure/cancel | [Startup matrix](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift#L600) checks factory/validation stages, five failure outcomes and both cancellation choices; a distinct live key remains CPU. [Appended CPU-preservation method](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift#L1030) additionally probes the cancelled key cold. | Appended methods have no new runtime claim from this worker. |
| Startup ordinary cancellation with CPU cache | [Appended retry method](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift#L1077): CPU hit survives; distinct fresh key validates Metal; original interrupted key then requires its own render; both factory and validation counters reach two. | Covers thrown cancellation and post-validation cancellation. |
| Cancelled hit does not promote LRU | [Native full-cache method](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift#L708): cancellation at poll 1 or 2, then fifth admission evicts the original oldest frame; survivors and byte counters checked. | Cancellation racing after the last false poll is outside an atomic guarantee. |
| CPU survivor ordering after purge | [Portable selective removal](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/Tests/LightingCoreTests/StudyFrameCacheTests.swift#L166): refresh CPU first, remove Metal, admit two later entries, require CPU second to be evicted while refreshed CPU first remains. | Generic cache behavior, composed with native backend predicate. |
| Purge more than one Metal value | [Portable selective lifetime method](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/Tests/LightingCoreTests/StudyFrameCacheTests.swift#L268): two CPU and two Metal values; both weak Metal observers clear while both CPU values survive. | Value ownership only; no RSS or Metal-driver claim. |
| Scene errors do not masquerade as failure | [Appended scene-error method](https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/NativeTests/StudyRenderCacheTests.swift#L1189): five StudyError values preserve CPU/Metal entries; a repeated failed key stays cold; successful retry increments render count without reinitialization. | Generic Swift CancellationError is outside the documented injected-backend cancellation contract. |

The fake renderer returns all-white images, so equality alone would be insufficient to prove cache reuse. These regressions also use cache count/costs, backend labels, factory/validation/render counts and still-armed failing callbacks. Those independent checks prevent a same-image rerender from masquerading as the relevant cache hit. They do not establish numerical Metal parity.

## Held-out combined sequence A: downgrade before ordinary cancellation

Use distinct valid keys C1/C2 for CPU busts at 24×16 and M1/M2 for eligible scripted Metal spheres at 48×32. No successful lookup is interleaved during the ordering portion. CPU cost is 1,536 RGBA + 384 mask bytes; sphere cost is 6,144 + 1,536. Keys differ by subject or valid exposure values.

| Operation | Source-derived state | LRU order after operation | Count / RGBA / mask bytes |
|---|---|---|---|
| Seed C1, M1, C2, M2 | Metal validated | C1, M1, C2, M2 | 4 / 15,360 / 3,840 |
| New eligible F reports command failure and toggles cancellation in that callback | CPU; throws cancelled | C1, C2 | 2 / 3,072 / 768 |
| New Q cancelled during CPU work | CPU; throws cancelled | C1, C2 | 2 / 3,072 / 768 |
| Clear cancellation; new live R completes | CPU; reference image | C1, C2, R | 3 / 9,216 / 2,304 |
| Revisit old Metal key M1 | CPU; fresh reference image | C1, C2, R, M1-CPU | 4 / 15,360 / 3,840 |
| New CPU bust S completes | CPU | C2, R, M1-CPU, S | 4 / 15,360 / 3,840 |

F and Q never enter the cache. M1/M2 cannot return their previous Metal values because the purge removed them. C1 is preserved by the downgrade and only later evicted by ordinary count-based LRU. “Preserves CPU” does not promise indefinite retention despite subsequent successful admissions.

## Held-out combined sequence B: ordinary cancellation before downgrade

Starting from the same four entries, a new eligible F that throws StudyError.cancelled (or returns successfully after toggling cancellation) must preserve state Metal and all four entries. A later successful retry of F is an ordinary fifth admission: C1 may be evicted, yielding M1/C2/M2/F and 19,968 RGBA + 4,992 mask bytes. A subsequently delivered known failure plus cancellation removes all three Metal values and leaves C2 at 1,536 + 384 bytes. A new live sphere request then produces CPU and yields 7,680 + 1,920 bytes.

These complete permutations are not a single existing native test. The observed source structure and the component assertion inventory justify a bounded composition argument. A future combined native method could strengthen integration coverage, but no source counterexample or missing acceptance assertion was found here; code churn and a new uncompiled test are not justified by this review.

## Limits and handoff

Cancellation remains cooperative. An external cancellation can arrive after the last check; the absence of suspension does not make task cancellation and return atomic. Callers still control latest-request adoption. The parent-reported lane03/20 A→B downgrade/cancel→A held-frame bypass occurs outside this actor cache and is neither disproved nor repaired by these invariants.

The injected backend must use StudyError.cancelled. A generic Swift CancellationError would take catch-all and select CPU; the production renderer shown here does not emit that error. Cache budgets count retained frame payload, excluding caller-held copies, allocator overhead and driver resources.

Only unattached UTF-8 documentation/evidence blobs are created. Planned physical worker and result paths remain uncreated. Root alone may integrate the returned map and update refs.
