# W53 API review

Status: completed source inspection; candidate unavailable, runtime acceptance unverified.

- Runtime/canonical ID: `/root/wave06/w53_api`.
- Input SHA: `74f7584b4e474c752ec0939add6b7522ba98094f`.
- Private tree: `/tmp/keyfill03-7f4b/workers/W53-api`; output: `/tmp/keyfill03-7f4b/builds/W53-api`.
- Preview SHA256: `f609041d40414637955ff8cf1d143c3269c0305a7a0dba8d937c845e95ecf4e2`.
- Evidence: `wave06-evidence/W53-api-inspection.json` (commands, results, all source hashes); `wave06-evidence/W53-api-source.txt` (numbered source snapshots).

## Findings and correction invariants

`ReferenceStudyPreview` is internal. Its scene is required; subject defaults to `.sphere`, with `.bust` explicitly supported. Request construction copies the scene and clears only `placementRoom`; camera, subject position, optics and preview settings survive. Retry changes only the attempt UUID, leaving request/render-cache identity intact.

Keep request construction, task identity and pipeline unchanged. `begin()` must precede inactive/cached early returns; inactive phases must not render. Returning to completed A must invalidate intermediate B. Preserve same-subject previous-image reuse and exclusion of old errors/different subjects. Apply direct phase gates only to loading/updating presentation: inactive empty/stale states must describe a pause, without claiming ongoing rendering; active states retain existing progress. Preserve the nine baseline tests unchanged; no new helper/string test proposed.

Pipeline guards current ticket and task cancellation before rendering, after rendering and after conversion. CancellationError and StudyError.cancelled publish nothing. invalidCamera and invalidEmitter receive specific messages; other StudyError cases and unrelated errors receive the generic message. Nil conversion publishes an explicit display failure with nil image/backend and zero unsupported count. Valid renderer outputs are bounded; no additional conversion failure was established.

Conditional baseline edge: directly supplying a scene containing NaN makes synthesized Request equality nonreflexive. A published error snapshot then fails the current-request display guard, so its error is hidden. This is source-derived only; caller reachability and actual UI reproduction are unverified. It is outside the minimal phase-label correction.

## Actual verification and limits

Read the four required instruction files. Ran numbered source/test reads, related-API searches, Python SHA256/test inventory, `git rev-parse HEAD`, `git status --short --branch`, and `git diff --exit-code -- App/ReferenceStudyPreview.swift NativeTests/StudyPreviewPipelineTests.swift`. The detached tree matched the input and both files remained unchanged. Inventory found nine async methods; none executed. Harness-location search returned no matches (exit 1), not a test result.

Linux source inspection only: no Swift build/tests, SwiftUI execution, CoreGraphics conversion, Metal, VoiceOver or physical-device checks. No source edits, commits, pushes or cleanup. Working-token counter unavailable; no consumption figure claimed.
