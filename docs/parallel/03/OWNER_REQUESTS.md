# Lane 03 integration routing

Only finish/03-cpu-study-mannequin is updated by this lane. These are handoff requests and compatibility receipts, not acknowledgments from another owner.

| Owner | Concrete result or requested action |
| --- | --- |
| 02 photometry/color | db7a5b5 addresses the recorded tiny per-sample intensity issue without changing photometry/color source. Unit integration restores subnormal emitter output once; 166-check actual Swift probe improves56failures to0. Ordinary ordering remains, and numerical limits are explicit in NUMERICS.md. Review this scoped response against your consumer request. |
| 04 GPU/cache | Packed rows remain6parameters/3sample/3area, Float32 tiny-output quantization unchanged. Six host parity cases and eight precision cases pass with exact masks on db7 CPU. The separate actualSwift width24/focal161.27198111190464 silhouette witness still exceeds the unchanged fraction threshold; see evidence/gpu-silhouette-host.log and probe. Resolve eligibility or fallback in your owned implementation; CPU thresholds were not relaxed. |
| 01 shared composition | ReferenceStudyPreview(scene:subject:) is unchanged. Request identity still excludes placementRoom only. Generation guards reject late success/failure, including A→B→A reuse. Same-subject prior frames carry explicit labels; other subjects and obsolete errors do not stand in. Shared scene admission/revision/wiring remains yours. |
| 19 CI/tooling | No CI or shared script implementation was authored here. Local compilation needed serial per-file optimization after signal9; native/standardWMO verification remains source-bound CI evidence. The host-parser concern in lane04 OWNER_REQUESTS remains with your tooling review. |
| 20 integration | Base fallback f150f98 and ordinary inheritance of already-existing main9e0e2ba/b0d25ee are documented. Do not infer physical validation or global M02/M03 completion from this lane. Integrate accepted lane03 commits, retaining original failures, fixtures and exact masks. |

Final source-specific receipts, worker accounting, native evidence and remaining limitations are collected in HANDOFF.md. Actual Swift fixture generation and shared C++ host checks are distinct from Apple Metal execution; no device result is inferred.

## Immutable wave 07 contract update

Lane 02 was inspected at `b5c1f008446f8b33f3ee97f8fefe6675058ef347` (request blob `e03d008c10197c960c75f5168ee1c8a46b7949cd`). Lane 04 was inspected at `88279ba0ee0262ea6c880580c8a85b56342abbff` (request blob `7ff42021d0e4f2166b8750c233474083bbc26d79`). These are observations and requests, not owner acknowledgments.

Lane 04 now contains an actual-width silhouette guard and a near-vertical camera fallback. Its engine must integrate with the paired `supports(scene,width:)` helper; mixing that engine with the old helper is unsupported. Preserve lane 03's actual Swift width-24 failure and let lane 04/19 establish the integrated guard's native results. This review inspected source and test assertions without executing that branch.

Lane 02 additionally requests explicit routing/rejection of positive per-cell output that becomes Float subnormal or zero. The reviewed lane 04 eligibility code does not implement that intensity policy. The request remains with 02/04. Source inspection found no proposed guard-skipping mask defect: distance/validity and rectangle guards execute before zero-lux returns in both pinned kernels. No new RGB8 mismatch or admitted runtime mask failure was demonstrated. CPU equations, public packing rows, fixture thresholds and masks remain unchanged.

Shared validation of arbitrary light names remains dependent on input bytes; a grapheme-count limit is not a UTF-8 byte bound. Numeric loop/sample bounds must not be presented as a constant bound on every validation wrapper. Any schema byte bound or admitted-scene optimization belongs to 01; full validation was not bypassed here.

Details and immutable receipts: `workers/wave07-evidence/W61-owner-request-analysis.md`, W63/W64/W65/W66/W67 reports and associated evidence.

## Wave 09 preview and UI follow-up

The latest inspected lane 04 head is `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`, with owner-request blob `a94998ccb2316f8e0ec4819f514bfa0f32062d41`. Its W057 proposal identifies a source-reachable A → B → A adoption gap: B can permanently downgrade the engine while cancellation suppresses B's publication; the view-local A shortcut then bypasses the now-CPU engine and presents A's old Metal status. Lane 03 accepted ownership and implemented the narrow activation/ticket correction and one hosted regression; preview SHA-256 `9ba7761837c58dde1b973d0740ad97a37ecea2e73ba8c5b69397da625ef805b9`. Source review, syntax and discovery pass, while Apple execution remains pending. The exact external proposal is preserved under `evidence/lane04-preview-proposal/`; it was uncompiled and unrun when received. This note does not claim the proposed correction has yet passed native execution. Lane 02's inspected head remains `b5c1f008446f8b33f3ee97f8fefe6675058ef347`.

Source36's library/reference UI job `139992156791` failed two ProjectLibraryUITests methods: the bounded entry waiter for “Keep”, and the forwarded normal-action assertion for the library Done control. All seven project-library methods ran, with two failures; both ReferenceComparisonUITests methods passed. The retained log identifies the Done control correctly but does not separately identify which final enabled/hittable predicate failed. Route the original attachments and UI behavior to **01**; this lane has not changed that UI or asserted a root cause.

The dependent Default and AXXXL visual jobs failed because the cancelled app-accessibility shard produced no `ui-app-accessibility-evidence-compact` artifact. Route artifact dependency/accounting review to **19**. Neither visual job completed an image review. `evidence/ci-ui-failures-36.json` and three byte-exact raw logs preserve the results. Source36's successful 164-method native suite remains valid, but the whole UI/global M03 gate did not pass. Later source workflows must establish their own results.
