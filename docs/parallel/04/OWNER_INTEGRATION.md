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
