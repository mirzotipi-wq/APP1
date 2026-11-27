# Wave 09 — CPU Study, masks and preview adoption

**Source review checkpoint:** final executable `342e3280e3eb077d55e122c8bfb88b4062b431ed`, tree `629fc14bf911700b924e4d9b2515ed3c9ddc794d`. Root integrated and remotely verified this source. Preview SHA-256 is `9ba7761837c58dde1b973d0740ad97a37ecea2e73ba8c5b69397da625ef805b9`; the new hosted regression is `abd3fa97bb0cda6d45e4e9f66b068f1155ea4672b87542a081c33e6d72967f91`. CPU source remains db7. **Native validation for run 45857561126 is pending; 165 is discovered inventory, not an executed pass.**

## Concrete finding and correction

W057 exposed a view-local backend-policy bypass. Metal frame A could remain in the view while B permanently selected CPU and purged the engine's Metal cache. If B was cancelled before publication and the user returned to A, the preview's local shortcut skipped the engine and presented A's historical Metal badge as current.

W84 adapted the owner proposal in its private tree: each activation reconsults the engine; currentness requires request and active ticket; successful retained pixels stay previous until guarded adoption. The existing previous-frame unsupported count remains visible and present in the image label. Root's final wording refinement says “previous render,” accurately covering same-scene revalidation. W85 and W90 independently reviewed the actual correction; W88 checked status/privacy implications. The unchanged ten pipeline methods retain their evidence.

A new native hosted regression preserves one window/host/view identity through controlled A→B→A. It requires two A invocations and one B, holds intermediate completion, uses actual accessibility positive controls and bounded traversal/waits, checks previous/updating with no current badge, then verifies CPU adoption. Continuation cleanup is explicit. Synthetic producer labels do not establish real Metal or engine failure behavior. SDK typecheck, actual hosted execution and baseline before/fail remain unrun at this checkpoint.

## Independent challenges

- W82's disclosed Python mesh-data check finds a connected welded mesh with V2626/E7872/F5248, Euler characteristic2 and two opposing incidences per edge. Original crown/topology remain unchanged. This is not a new Swift BVH run or a self-intersection proof.
- W82/W83 verified retained archive/ABI data. Twelve original/final images and scenes are identical; final raw masks are zero. Original standard raw masks are absent, preventing original-mask equality claims. The separate clipped-camera diagnostic preserves all11,708 marked positions; corrected rejection has no replacement image.
- W83 found no admitted mask consumer defect; opaque display RGBA must retain its separate validity mask. W86 confirmed bounded logical cache payload and safe numeric accounting, without an RSS/device-memory claim. Unicode validation remains dependent on input bytes.
- W85 distinguishes an external cancellation after the final completed-render poll from pre-completion cancelled publication. That completion-boundary question is not a demonstrated new defect. W057 was a separate, source-reachable subsequent-activation bypass and was corrected.
- W87 bound current02/04 requests and engine bytes. Preserve03 tiny-output scaling and preallocation cancellation when integrating04. Current04 runtime/kernel changes need their own validation; tiny-Float routing remains an owner policy request, not a new observed mask failure.
- W89 found a receipt class-name error: the two passed UI methods are ReferenceComparisonUITests. Root corrected the summary with original provenance retained. Two ProjectLibrary failures and dependent missing-artifact visual failures remain unchanged.

## Acceptance and accounting

All31 LightingCore manifest hashes and the original pipeline test file remain unchanged at final source. W81/W89 reconcile retained source36 native164/0, ten pipeline methods, six actual simulator Metal cases with exact-mask assertions, separate host parity6/precision8, and optimized benchmark8frames/12cancellations/4visibility workloads. No new build/render/benchmark was run by this wave. The1.606625ms cancellation maximum is a short shared-host diagnostic.

Exactly ten actual contexts were created: W81 plus nine fresh W82–W90 children. W84/W85 followups reuse their contexts. `wave09.json` records canonical runtime IDs, source identities, reports, execution status and artifact hashes. All ten primary reports and the two same-context followup reports are complete. Original reports/failures are retained; no HANDOFF or root production file was edited by W81.

This is lane-scoped source review. Current native/UI acceptance remains pending, global M03 is not promoted, and physical calibration, device performance, manual VoiceOver and release readiness are not claimed. Exact token counters were unavailable; qualitative checkpoints and requested targets are recorded without certifying exact usage.
