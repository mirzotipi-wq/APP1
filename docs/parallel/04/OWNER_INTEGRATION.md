# Owner integration snapshot — 26 November 2026

This is a read-only compatibility inspection at 14:08 UTC, not an acknowledgment from another lane and not a merge of their changes. Lane04 remains based on the campaign f150f98 plus the existing main dependency already recorded.

| Lane | Observed branch revision | Relevant finding |
| --- | --- | --- |
| 02 | b5c1f008446f8b33f3ee97f8fefe6675058ef347 (finish/02-photometry-color) | ReferenceStudy.swift blob0ca920b1332e1042d2e3ddfe0d0fe69ccc5b46ad exactly matches this lane's base. Colorimetry.swift, SurfacePhotometry.swift and LightOutputAdjustment.swift change on that branch; repeat combined parity/precision verification after integration. |
| 03 | 74f7584b4e474c752ec0939add6b7522ba98094f (finish/03-cpu-study-mannequin) | ReferenceStudy.swift blobace5e59027b6a05484e129be233928b85a3e7a7b adds an early cancellation predicate after width validation and forwards it from the CPU renderer. Packed constructor, row layout, sphere equations and six fixture definitions are not changed by that file's diff. The preview pipeline and its native tests also change on03; adopt those owner changes through lane20. |

Lane04's new header matches the existing immutable interactive packer: six float4 parameter rows, at most768 logical samples and12 areas, grid8, and zero/one-based sample tags. Lane03's observed early CPU cancellation complements lane04's planned Metal cancellation checks. Tests that count cancellation predicate calls must derive their terminal count from actual rendering and must not assume the old setup omitted an initial check.

The width-aware eligibility API keeps the legacy supports(scene) overload (width192) and forwards actual production widths. Planned internal backend injection is restricted to lane04 rendering/lifecycle tests; default application construction continues to use actual Metal. Preview adoption and UI behavior remain03-owned. No external owner branch or global milestone state is written by this lane.

Integration gates for20/19: rerun Debug/Release core tests, six canonical host/Metal parity cases, all eight strict host/Metal precision cases, complete native method inventory without skips, and lifecycle/cache tests after combining02/03 source. Do not substitute this branch's earlier matrix results for tests of the merged source.

The accompanying lane03-reference-study.diff records the inspected CPU cancellation change. GitHub compare evidence was read for both pinned branch SHAs; no owner acknowledgment is inferred.

## Later consumer inspection

Worker 057 confirmed a source-level A→B→A sequence in the current owner preview at `finish/03-cpu-study-mannequin` head `8ce5e464253144deccb39d838faef70f05e0c38c` (preview blob `c96d5cb7a41143867efca160b309d71bfa993c96`). After A displays a Metal frame, B can confirm a backend failure and be cancelled. The engine correctly evicts Metal entries, but returning to A can take the view-local successful-frame shortcut without consulting the now-CPU engine. The old pixels may remain valid; this is a subsequent-request adoption and status-policy gap, not evidence of corrupt pixels or engine-cache leakage.

Lane 03 owns the correction and hosted regression; lane 20 owns integration. The [unapplied patch](evidence/w057/owner-preview-adoption.patch) and [exact regression proposal](evidence/w057/owner-proposal.md) target that inspected owner revision. They reconsult the engine for each activation, retain previous pixels during revalidation, and require a new pipeline ticket before presenting a frame/backend as current. Keep ordinary cancellation and precision-only fallback distinct from permanent downgrade. Verify existing automatic native test discovery/accounting; no shared build or harness change is currently required. This proposal is uncompiled and unrun, with no owner acknowledgment or merge claimed.

The earlier packed-input/oracle comparison remains pinned to its stated heads; this later inspection updates the preview dependency only. Recompare all owner source changes and rerun the complete matrices after lane20 combines them.

## Later owner refresh — wave 9

The read-only owner refresh at **2026-11-26 16:35:58 UTC** found lane 03 at `92dc7a69c0032141ee49de0b96940fccab83a33e`. Its preview now requires request and publication-ticket identity and reconsults the engine on every activation. `NativeTests/StudyPreviewAdoptionTests.swift` contains `testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade` (blob `c514f15cf000538f56d7653b7b30d85d451442ad`). The hosted source uses a controlled synthetic producer. Its retained [input receipt](https://github.com/mirzotipi-wq/APP1/blob/92dc7a69c0032141ee49de0b96940fccab83a33e/docs/parallel/03/evidence/preview-adoption-inputs.json) explicitly leaves Apple typechecking, hosted execution and the hook-only before/fail run unperformed. No owner acknowledgment or new UI runtime pass is claimed.

Lane 04's tested preview still has the earlier shortcut; the owner 03 remedy is not integrated here. The earlier owner-status paragraphs describe the wave 8 freeze and the historical w057 proposal. The current remaining work is **integration and execution**, rather than absence of a remedy in owner 03 source. The hosted assertions observe accessibility/current-status/backend/warning state; pipeline tests separately observe converted bytes and the source assigns a single paired Frame. Independent inspection of displayed CGImage bytes is a bounded coverage limit, not a newly demonstrated defect or additional mandatory gate.

Owner 03's CPU oracle also changed tiny-output integration/packing construction (blob `82e54a53f3d32d745aee1edfa297086504fb81ec`). It retains the six-parameter/three-sample/three-area float4 layout and original sample-intensity meaning. These tables execute lane 04's older oracle, so they do not establish parity of the combined revision. Lane 20 must retain lane 04's engine, width-aware eligibility and guarded shared header while integrating owner 03's oracle/consumer/test, then repeat the relevant CPU, host, native parity and adoption checks. The immutable owner comparison is blob `55bb057aecbca8210673c3f2ae85b8323bff86fb`; retained owner evidence is blob `405b9246dfc00cee189229424ed9d9fbb7bf4e7b`.
