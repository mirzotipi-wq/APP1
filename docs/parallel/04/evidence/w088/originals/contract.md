# Study fallback and frame-adoption contract

## Scope and authority

This document describes the implementation at source `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`, read from documentation input `53d7302931ccaadd7a2ad29c55fd94a695c5997e`. Campaign baseline is `f150f98e35dd735927075aac4d2f8b02295c6a67`. It adds no source change, test result or release acceptance. The shipped Double CPU renderer remains the numerical reference. [Code acceptance](../../acceptance/m02-m03-code.md), [parity tables](PARITY_TABLES.md) and [fixture reproducibility](PRECISION_REPRODUCIBILITY.md) retain the unchanged gates and execution provenance.

The implementation is [StudyRenderEngine and MetalStudyRenderer][engine]. Its private states are `unchecked`, `metal(backend)` and `cpu`. “Deliberate CPU” below describes per-request routing; it is not another enum case. A CPU result alone does not reveal whether initialization remains retryable or the engine permanently downgraded.

## Ownership and normal startup

The actor serializes its synchronous render method, backend factory, validation, rendering and cache operations. There is no `await` inside that method. The normal initializer creates a real `MetalStudyRenderer` from `MTLCreateSystemDefaultDevice()`; an eligible, uncached sphere request must complete validation before the actor stores the backend. Validation compares all six canonical fixtures at width48 with the shipped CPU oracle and checks `StudyParityMetrics.passes`. The parity-only `renderValidationFixture` route retains input and relative-distance checks while bypassing production eligibility; production publication never calls it directly. [Engine][engine], [oracle and packed input][oracle], [canonical metrics][fixtures].

The injected factory is an explicit test seam. It must return a fresh backend for the actor's exclusive use, with no externally retained concurrent-use path. The protocol is synchronous, so Metal resources are not sent across isolation boundaries. Scripted factories and synthetic images demonstrate state handling; they do not demonstrate GPU pixels, cancellation latency or driver-resource release.

## Exact routing and error table

The table applies after an uncancelled entry and any successful cache hit. The engine's cancellation predicate is `Task.isCancelled || additionalCancellation()`; a false extra predicate cannot suppress task cancellation. “Admit” means a successfully completed frame reaches the cache only after the final cooperative check. CPU rendering can itself throw; then no frame is returned or admitted.

| Stage / event | State after event | Request outcome and cache effect |
|---|---|---|
| Cancellation observed at entry or immediately before cache lookup | Unchanged | Throw `StudyError.cancelled`; no lookup promotion, new frame or admission. |
| Valid matching cache hit | Unchanged | Promote that completed frame to most-recently-used and return its stored image/backend pair. No factory, validation or fresh rendering. |
| Bust request | Unchanged | Use `PortraitStudyRenderer` at `min(requestedWidth,144)`; completed result is CPU. The sphere kernel is never used. Remaining invalid dimensions still fail the CPU constructor. |
| Sphere is outside production Float32 eligibility | Unchanged | Use the Double CPU renderer. Invalid scene, camera or resolution still produces its original renderer error; ineligibility does not make invalid input valid. |
| `unchecked`: factory and all validation succeed, final check is false | `metal(backend)` | Store validated backend, then render this eligible sphere. |
| Startup factory/validation throws `StudyError.cancelled`, `invalidScene`, `invalidCamera`, `invalidResolution`, `invalidEmitter` or `invalidSurface` | `unchecked` | Rethrow that error. No new admission; a later eligible uncached request may retry startup. |
| Startup validation returns, but final cancellation check is true | `unchecked` | Throw `StudyError.cancelled` before storing backend. A later eligible uncached request may retry. |
| Startup factory/validation throws `MetalStudyError.precisionDomain` | `unchecked` | After another cancellation check, attempt CPU for this request; preserve existing cache. A later eligible uncached request retries startup. A hit on a retained CPU result does not retry. |
| Startup throws `StudyError.invalidComputeOutput` or any other error, including Metal unavailable/allocation/command/parity | `cpu` | Select CPU and purge Metal cache entries before the next cancellation check. Then return CPU if successful and still live; otherwise throw cancellation/CPU error. No later startup retry on this engine. |
| `metal`: backend returns an image and final check is false | Same `metal` | Admit/return the image with `.metal`. |
| `metal`: backend throws one of the six non-output `StudyError` cases listed above, or its final check observes cancellation | Same `metal` | Rethrow; preserve validated backend and all previously completed entries. Failed/cancelled request is not admitted. |
| `metal`: backend throws `MetalStudyError.precisionDomain` | Same `metal` | After a cancellation check, attempt CPU for this request. Preserve old Metal and CPU entries; later eligible uncached requests may use the same backend. |
| `metal`: backend throws `StudyError.invalidComputeOutput` or any other error | `cpu` | Purge all engine-cached Metal frames and retain CPU frames. This downgrade precedes observation of concurrent cancellation. Later eligible requests stay CPU. |
| `cpu`: uncached sphere request | `cpu` | Render with CPU; success and final cancellation check control admission. No automatic reset/revalidation exists. |

A confirmed failure concurrent with cancellation therefore has two observable consequences: the caller receives cancellation, while the actor remains permanently downgraded with Metal entries removed. Treating that event as ordinary cancellation would incorrectly retain the backend. Tests distinguish it with an uncached subsequent request and a revisit to the old Metal key.

**Injection error contract:** use `StudyError.cancelled` to model backend cancellation. Production backend cancellation checkpoints currently emit that type. A generic Swift `CancellationError` is not emitted by this backend and currently enters the catch-all failure path, selecting CPU. A consumer's broader cancellation catch does not change this engine behavior. [Engine][engine]; [scripted lifecycle tests][cache-tests].

## Deliberate CPU domain

The width-aware [eligibility predicate][eligibility] accepts only validated sphere/panel input at widths24–192 divisible by3, with valid camera clearance and bounded relative geometry. Camera distance from subject and every active light's center distance are limited to20m; zero-candela lights are exempt from that light-distance condition. Absolute world translation is not the bound: packing subtracts the subject in Double before Float conversion.

Near-field sources, conservative visible-panel bounds, silhouette-sensitive pixel grids and the narrow nonaxial near-vertical camera cone can select CPU. The 1mm surface margin and distance-scaled silhouette allowance are engineering guards, not proved error bounds for every scene or GPU. A predicate rejection never disables an already validated backend. The mannequin's distinct geometry is always CPU at width≤144. [Eligibility][eligibility], [oracle][oracle], [boundary fixture catalog](PRECISION_REPRODUCIBILITY.md#boundary-fixtures-and-routing).

The real near-field recovery test renders ordinary A/Metal, routes near-field B to CPU, then revisits cached A. It establishes that preserved cached Metal remains usable; its final access is not proof of a fresh post-fallback GPU dispatch. The real width24 silhouette test starts with CPU on an unchecked engine, then performs fresh Metal startup for another eligible request. The scripted precision-domain test also uses a fresh eligible key and checks factory/validation/render counts. [Native routing tests][renderer-tests], [cache tests][cache-tests].

## Cache identity, admission and invalidation

Every key is created only after `scene.validated()` succeeds. Only then are display names replaced with empty strings, avoiding retained arbitrary Unicode name storage without letting invalid metadata hit a previously validated frame. Identity uses exact scene equality plus effective width and subject; all other values, light order, optics, camera, exposure and room metadata remain. There is no rounded or hash-only identity. A reverted or decoded equal scene may reuse its completed frame; sphere and bust do not share entries. [Engine][engine].

Each engine retains at most **4 completed frames, 262144 RGBA bytes and 65536 mask bytes**. [StudyFrameCache][cache] evicts before appending, independently enforces count and both payload budgets, removes an admitted replacement before further eviction, rejects negative or individually oversized costs without disturbing existing entries, and preserves survivor order during selective removal. At192×128, each frame costs98304 RGBA and24576 mask bytes; the limits allow at most two such frames. These are payload accounting facts, not process-memory limits.

New CPU or Metal frames are admitted only after successful rendering and the final cooperative cancellation check. No suspension occurs between that check, insertion and return. Failed/cancelled calls never admit their unfinished result. A cancelled lookup observed before promotion leaves LRU order unchanged. Cancellation arriving externally just after the last observed false predicate is not made atomic by actor isolation; the caller must still reject an obsolete returned result.

`selectCPU()` drops actor ownership of the backend and removes every cached `.metal` frame while preserving completed CPU frames and their relative order. This does not revoke images already retained by a caller or another engine. The bounded reference tests establish object ownership/release under their controlled references, not physical GPU/driver memory reclamation. Resource logs measure only cache payload counters and exclude caller-held copies, allocator overhead and process RSS.

## Submitted GPU work and caller adoption

Before submission, cancellation prevents the command from being committed. Once committed, `waitUntilCompleted()` finishes before output is read or scope-owned buffers can be released. The renderer checks command status before the post-completion cancellation predicate, so a real command failure remains observable for downgrade even when cancellation also arrived. Successful completion followed by cancellation throws without producing a returned image. The autorelease pool scopes temporary resources; there is no claim of GPU preemption, instantaneous cancellation, bounded GPU completion time or measured driver-memory release. [Engine][engine], [kernel][kernel], [shared math][header].

The actor serializes render calls, not the UI's choice of which completed result is current. A caller must track its active request/generation, invalidate work on edit, subject change, inactivity or disappearance, and recheck cancellation/current identity after awaiting and after image conversion. Image, backend provenance, unsupported-pixel warning and error status must be adopted together. A previous frame may remain visible as previous/updating where appropriate; it must not acquire current backend/status merely because an old scene value reappears.

### Open owner03/20 consumer gap

At the inspected [lane04 preview][preview], A/Metal may remain displayed while B confirms permanent engine downgrade and is cancelled. Returning to A can take the view-local successful-frame shortcut at line113; request-only equality at line52 marks the retained frame current and exposes its stored Metal badge. The engine was not consulted, so its Metal-cache purge cannot invalidate that UI-held value. The old pixels may remain valid; this is a consumer adoption/current-status gap, not demonstrated engine-cache leakage.

[The retained owner proposal](evidence/w057/owner-proposal.md) and [unapplied patch](evidence/w057/owner-preview-adoption.patch) propose reconsulting the engine on activation and requiring both request and publication-ticket identity for current status. The [hosted regression specification](evidence/w057/owner-proposal.md#exact-regression-hosted-consumer-plus-existing-pipeline-seam) requires one mounted view through A→B confirmed failure/cancellation→A, a second A engine call, previous/updating presentation while its CPU result is held, then paired CPU image/backend adoption. A pipeline-only publication test cannot establish the view's second call or its badge.

The proposal targets lane03 HEAD `8ce5e464253144deccb39d838faef70f05e0c38c`, preview blob `c96d5cb7a41143867efca160b309d71bfa993c96`. Lane04 preview blob `1a68db0fd7782ac945b915b32b4ddd8485321ad3` differs. Applicability to lane04 is unestablished. The patch and hosted method are proposed, unapplied, uncompiled and unrun; no owner acknowledgment or UI acceptance is claimed. Owner03 owns the correction/tests and owner20 integration.

## Observed evidence and remaining limits

| Evidence | Recorded outcome and boundary |
|---|---|
| Source6 `240000fd3f8cb75273eb279be9dcc7f204a5b29f`, [run45848953002](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002), core job140009926092 | 379 Debug and379 Release passed; host shared-kernel canonical6 and strict8 passed. Host execution is separate from Metal. |
| Same source/run, native job140012314020 | [Receipt](evidence/ci/wave06-native-140012314020.json), [raw log](evidence/ci/wave06-native-140012314020.log):174 unique Debug native methods, no failures/skips, including25 cache methods; Debug/Release builds, accounting and finalized export succeeded. |
| Actual simulator Metal within source6 native | Canonical6 maximum≤1 and all >4 fractions0; exact masks asserted. Strict8 mean/max/outlier metrics all0 and exact masks asserted. These are fixture results, not a universal numerical or physical-fidelity guarantee. |
| Source6 resource/lifetime scope | 19 CPU payload rows:15 steps and4 summaries. Scripted lifecycle/release assertions remain distinct from actual GPU dispatch; weak mock release establishes actor ownership. |
| Source7 `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`, [run45854806270](https://github.com/mirzotipi-wq/APP1/actions/runs/45854806270), core job140031989526 | Retained metadata blob `6d2c5720b89e657c29803299113b522597cb3491`, raw `dc763b62d72322edade2cb45f585de78b2017336`:379/379 and host6/8 pass. This is not Apple execution of the four appended cache methods. Native job140034909086 was queued at the supplied receipt; only root monitors it. |
| Unperformed | Source7 additions have no Apple runtime pass in this contract's input. Release native runtime, physical-device behavior, RSS/driver memory, GPU cancellation latency and owner03 hosted adoption remain unperformed/unresolved. |

Required canonical parity is exact invalid-mask equality, mean RGB-channel error≤1 and fraction of channels with error>4≤0.005. Strict8 additionally requires maximum channel error≤1. Native printed count equality is not a printed numeric mask-mismatch count; the passing assertions supply exact-mask evidence. Nonzero unsupported pixels can be compatible with exact parity. These thresholds are unchanged.

The [29-method cache source][cache-tests] contains the25 source6 methods plus four appended source7 methods: startup failure/cancellation preserving CPU cache; cancelled validation preserving CPU cache and retry; concurrent eligible requests validating once; and steady-state scene errors preserving validated backend/cache. Their presence is source evidence, not execution. Existing named assertions cover permanent downgrade before cancellation, ordinary cancellation preservation, startup retry, precise-domain fallback, deferred factory, cancelled-hit LRU order, payload limits and weak backend release.

Worker084 performed immutable GitHub reads, in-memory source inspection and UTF-8 candidate blob creation only. No local executor, test/build, SDK probe, CI poll/rerun, source/ref/global-state mutation or UI change occurred. Planned local directories remain uncreated. [Worker receipt](evidence/w084/receipt.v1.json) preserves the initial candidate and input map; subsequent revisions must retain this original.

[engine]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/App/MetalStudyRenderer.swift
[eligibility]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/Sources/LightingCore/StudyFloat32Eligibility.swift
[cache]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/Sources/LightingCore/StudyFrameCache.swift
[oracle]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/Sources/LightingCore/ReferenceStudy.swift
[fixtures]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/Sources/LightingCore/StudyValidationFixtures.swift
[kernel]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/App/ReferenceStudy.metal
[header]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/App/StudyKernel.h
[cache-tests]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/NativeTests/StudyRenderCacheTests.swift
[renderer-tests]: https://github.com/mirzotipi-wq/APP1/blob/69eb9c5096c863e9c8be1c5e53d9faff0d9c3014/NativeTests/StudyRendererTests.swift
[preview]: https://github.com/mirzotipi-wq/APP1/blob/53d7302931ccaadd7a2ad29c55fd94a695c5997e/App/ReferenceStudyPreview.swift
