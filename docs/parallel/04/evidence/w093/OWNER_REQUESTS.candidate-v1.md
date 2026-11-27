# Owner requests — lane 04 final wave

## Scope and retained owner state

This handoff uses immutable input `0fa824307da13934a289a825fd6d9d4a1939241f`, product/test source `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`, and campaign baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. It updates owner routes only. The prior document is preserved in [OWNER_REQUESTS.original.md](evidence/w093/OWNER_REQUESTS.original.md); exact read identities and the final review are in [inputs.json](evidence/w093/inputs.json) and [validation.json](evidence/w093/validation.json).

The retained read-only refresh at **2026-11-26 16:35:58 UTC** observed owner02 at `b5c1f008446f8b33f3ee97f8fefe6675058ef347` and owner03 at `92dc7a69c0032141ee49de0b96940fccab83a33e`. These are pinned observations, not fresh branch polling or direct owner acknowledgment. Owner03 now contains the ticket-aware preview remedy and controlled hosted regression. Lane04 still contains the older preview. Apple compilation/typechecking, hosted execution and the hook-only original before/fail comparison remain unperformed in the retained owner receipts. No combined merge or runtime pass is claimed. [Owner comparison](evidence/w083/source-review.v1.json), [owner input receipt][owner-inputs], [fallback contract](FALLBACK_CONTRACT.md).

## Precise owner routes

| Owner | Requested action and boundary | Evidence required for closure |
| --- | --- | --- |
| **02 — photometry/color** | Review combined numerical behavior with03/04. Coordinate sample order, color, camera-basis and area metadata changes before integration. Retain the separate positive-tiny-output Float32 quantization policy request as an owner decision; the reviewed source comparison established no new eligible-frame RGB/mask mismatch. | Combined-revision CPU, canonical-six and strict-eight results at the existing thresholds. A source-level policy concern is not a measured failure. |
| **03 — CPU oracle/preview** | Supply the existing ticket/reconsultation remedy, hosted test and tiny-output oracle work to20. Preserve guarded adoption, prior-frame labels, warning/error pairing and ordinary cancellation versus precision-only fallback versus permanent downgrade. The remedy is already present in the pinned owner source. | Apple compile and hosted execution of `testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade`, plus the retained hook-only before/fail comparison and existing pipeline checks. Preserve actual failures/skips/unrun states. |
| **01 — shared composition** | Retain ordinary scene/subject call sites and shared scene admission. Any schema byte bound or validated-scene optimization belongs here; cache-name omission must not bypass full validation. Preserve the inherited native UI measurement correction and unrelated composition work. | Source compatibility of the combined app and relevant shared workflow checks. Global state is not promoted by lane04 evidence. |
| **19 — harness/CI** | Validate host fixture metadata at the parser boundary; verify automatic native discovery and complete terminal accounting on the combined source. Preserve actual-Metal checks separately from mocks and host math. No shared build/harness edit is presently needed merely to discover the new native class. | Metadata negative cases/UBSan where available; exact source, command, toolchain, method inventory, outcomes and raw artifacts. Parser hardening must retain fixtures, masks and thresholds. |
| **20 — integration** | Combine03 oracle/consumer/test with04 engine, width-aware eligibility and guarded header. Resolve overlapping files deliberately; do not replace04 implementations wholesale with older02/03 copies. Preserve imported upstream fixes and original evidence. | Rerun affected CPU, host, actual-Metal, lifecycle/cache and adoption gates on the actual combined revision. Own final global milestone decisions and publication; root alone integrates this lane. |

These are requests and responsibilities, not messages sent to other owners. [Owner integration history](OWNER_INTEGRATION.md) retains earlier observations without converting them into acknowledgments.

## API compatibility and unchanged lane04 contracts

| Surface | Compatibility contract |
| --- | --- |
| Engine construction | `StudyRenderEngine()` remains valid; `shared` uses the ordinary initializer and real default-device Metal construction. Optional `cancellationRequested` is additive and ORed with task cancellation. |
| Rendering | `render(scene:width:subject:)` retains width192 and sphere defaults, throwing `StudyRenderedFrame` behavior. External actor callers await it; the actor method itself has no suspension. |
| Eligibility | Both `MetalStudyRenderer.supports(scene)` and `StudyFloat32Eligibility.supports(scene)` retain the width192 compatibility overload. Production rendering uses `supports(scene,width:)` with its actual grid; merge engine and helper together. |
| Backend injection | The factory initializer is opt-in. It must return a fresh backend for exclusive actor use. Synchronous methods alone do not enforce exclusive ownership; the seam does not turn ordinary app rendering into a mock. |
| Preview | `ReferenceStudyPreview(scene:subject:)` remains the ordinary call shape. Owner03's optional internal `renderStudy` closure defaults to `StudyRenderEngine.shared`; source compatibility still needs the combined Apple build. |
| CPU/packed ABI | Lane04 leaves `ReferenceStudy.swift`, `ReferenceStudy.metal` and packed row meaning unchanged. Parameters remain six float4 rows; each sample and area uses three float4 rows, stride16 bytes. Sample position/candela, emitting normal/presence and XYZ/zero-or-one-based area tag keep their meanings. |

The Double CPU renderer remains authoritative. Exact invalid-mask equality is required; canonical-six mean RGB-channel error stays ≤1 and fraction of channels with error>4 stays ≤0.005; strict-eight additionally requires maximum channel error≤1. Per-engine cache bounds remain four frames,262144 RGBA bytes and65536 mask bytes; mannequin CPU width remains≤144. A per-request CPU route does not by itself mean permanent downgrade. Generic injected `CancellationError` currently enters catch-all downgrade; production backend cancellation uses `StudyError.cancelled`. [Engine](../../../App/MetalStudyRenderer.swift), [eligibility](../../../Sources/LightingCore/StudyFloat32Eligibility.swift), [fallback contract](FALLBACK_CONTRACT.md), [code acceptance](../../acceptance/m02-m03-code.md).

Owner03's oracle `82e54a53f3d32d745aee1edfa297086504fb81ec` differs from lane04's `0ca920b1332e1042d2e3ddfe0d0fe69ccc5b46ad`: tiny-output unit-intensity integration restores emitter output once; packing restores per-sample candela before Float conversion. This changes construction arithmetic, while six/three/three row layout and intensity meaning remain. Very small values can still become Float32 zero. Its early CPU setup cancellation check also changes. Lane04's previous oracle results therefore cannot establish combined parity. Owner20 must retain these lane04 blobs while resolving the merge:

| Required lane04 implementation | Git blob |
| --- | --- |
| `App/MetalStudyRenderer.swift` | `8c1acd852d85cd99671feaba883db1808bbb5e68` |
| `Sources/LightingCore/StudyFloat32Eligibility.swift` | `e9764da10eabbffbad6ceee8999977cf31deb197` |
| `App/StudyKernel.h` | `f60258402a96f58b62607d5cefec5e41c7ec4137` |

Owner02/03 retain older renderer/header implementations. The newer04 header guards dimensions, sample/area counts, grid and finite integer area tags before conversion; these are validation changes, not ABI changes. [Source manifest](evidence/root/final-source-hashes.json), [owner comparison](evidence/w083/source-review.v1.json).

## Preview adoption and remaining verification

The lane04 sequence remains source-reachable: A displays Metal; B confirms permanent backend failure and is cancelled; returning to A can reuse a view-held frame without consulting the now-CPU engine. Engine cache eviction cannot revoke UI-held copies. This is an adoption/current-status gap; the evidence does not establish corrupt pixels or engine-cache leakage.

Owner03 preview `999b590b7eaad2bed75d417690856004300568b2` requires request **and** active-ticket identity and removes the successful-frame shortcut. Each active request that proceeds through debounce reconsults the engine. Cancellation/generation checks surround rendering and conversion, and one Frame assignment adopts image, backend, unsupported-pixel warning and error state. Retained pixels remain previous/updating or paused until the new ticket is adopted. [Current owner source][owner-preview].

The hosted test `c514f15cf000538f56d7653b7b30d85d451442ad` keeps one mounted view through controlled A→B→A, requires two A calls and one B, holds intermediate completion, observes previous/updating without a current Metal badge, then adopts CPU status. Its producer is synthetic; it proves no actual GPU dispatch or engine failure until separate engine evidence is considered. The retained earlier native164/ten-pipeline pass predates this added method; discovered165 is inventory, not execution. [Hosted source][owner-hosted], [owner receipt][owner-inputs].

Hosted assertions observe accessibility state/backend/warning; they do not independently inspect displayed CGImage bytes. Existing pipeline byte tests and the single Frame assignment support paired storage. A bounded displayed-image byte check would improve coverage, but this is neither a demonstrated new defect nor an additional mandatory gate. Preserve the [historical w057 proposal](evidence/w057/owner-proposal.md) and [patch](evidence/w057/owner-preview-adoption.patch) as unapplied/uncompiled history at their original target; use the later owner03 source for integration.

## Harness metadata recommendation and evidence limits

The current [host parser](../../../scripts/verify-kernel-host.cpp) checks finite input floats, bounded dimensions, row counts, sample/area count agreement, reference length and exact invalid-mask outcomes. It does not independently validate grid/tag semantics or every contiguous area group before dispatch. The guarded04 header already rejects an invalid grid and nonfinite/nonintegral/out-of-range area tags before the relevant casts. The older request must not be read as proof that current04 still performs those unchecked conversions.

Owner19 should reject malformed metadata at the parser boundary: require grid8; require every sample tag to be integer zero or a valid one-based area index; validate that each rectangle consumes a complete contiguous64-sample group with consistent area metadata and sufficient rows. Retain truncated/trailing-input checks and test negative, nonintegral, huge, out-of-range and inconsistent-group cases under a suitable sanitizer. This is a harness-validation recommendation; no UBSan execution or demonstrated production-packer defect is claimed. Production `StudyComputeInput` remains immutable and validated.

For combined verification, retain Debug/Release core tests; canonical-six and strict-eight host checks; actual simulator Metal parity/precision and raw-metadata dispatch; lifecycle/cache/error-ordering tests; and03's pipeline/hosted adoption checks with complete native accounting. The strict generator emits33 fixtures but selects8; it supplies no pass for the25 unselected probes.

Source6 run45848953002/native140012314020 passed174 unique Debug methods, all25 cache methods and actual Metal6/8, with zero failures/skips. Both app configurations built; Release native runtime was not performed. Preparatory warm-up exit1 remains separate from later successful required tests/accounting/export. Source7 run45854806270/core140031989526 passed379 Debug/379 Release and host6/8; native140034909086 remains queued without an assigned runner in the supplied snapshot, leaving four appended methods unexecuted. Only root monitors it. [CI manifest](CI_MANIFEST.json), [parity tables](PARITY_TABLES.md), [precision reproducibility](PRECISION_REPRODUCIBILITY.md).

No local executor/build/test, CI poll, external owner message, source/UI/config/harness edit, ref change or global milestone change occurred in this update. Physical worker/result paths remain uncreated. CPU payload counters, weak-object/mock tests, host math, simulator Metal and unmeasured driver/RSS quantities remain separate. [Handoff](HANDOFF.md), [resource results](RESOURCE_RESULTS.md).

[owner-preview]: https://github.com/mirzotipi-wq/APP1/blob/92dc7a69c0032141ee49de0b96940fccab83a33e/App/ReferenceStudyPreview.swift
[owner-hosted]: https://github.com/mirzotipi-wq/APP1/blob/92dc7a69c0032141ee49de0b96940fccab83a33e/NativeTests/StudyPreviewAdoptionTests.swift
[owner-inputs]: https://github.com/mirzotipi-wq/APP1/blob/92dc7a69c0032141ee49de0b96940fccab83a33e/docs/parallel/03/evidence/preview-adoption-inputs.json
