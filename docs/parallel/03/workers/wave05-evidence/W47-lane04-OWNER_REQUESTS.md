# Owner routes — lane04

## Lane03 (CPU oracle and preview)

CPU equations and packed row layout remain unchanged. Confirmed host-shared-kernel silhouette discrepancy: width24, focal161.27198111190464mm, subject(0,1.5,0), camera(0,1.5,3), no lights. Two pixels exceed fraction(error>4)<=0.005; the local reference is a C++ Double transcription, not a Swift run. A width-aware conservative eligibility guard is planned. Public supports(scene,width:) will preserve source compatibility with a default width. Actual production width must reach eligibility.

Keep preview adoption guarded by task cancellation after awaiting engine and immediately before state update; old errors and backend badges must only describe matching requests. Existing implementation has these checks. A valid name-only edit currently causes debounce/Updating despite cache identity stripping names: optional UI request canonicalization belongs to03, must never bypass scene validation. If request equality is changed, add actual latest-result/background/subject-switch regressions.

## Lane02 (photometry/color)

No numerical oracle, sample order, color or packed ABI changes planned. Preserve six parity fixtures and eight precision cases. Shared-kernel eligibility may conservatively route silhouette-adjacent pixels to CPU; this is not a changed photometry threshold. Coordinate any future sample/area metadata changes before integration.

## Lane19 (harness/CI)

Existing host fixture parser permits finite nonintegral/negative/huge grid/area tags before shared Float-to-UInt casts, and does not verify contiguous area-group metadata. Production StudyComputeInput is immutable and validated, so this is a harness-input concern. Reproduce under UBSan and harden parser without weakening parity criteria. New native tests should stay in already owned StudyRendererTests/StudyRenderCacheTests classes; preserve explicit actual-Metal required methods and distinguish mocked backend lifecycle tests.

## Lanes01/20 (composition/integration)

Baseline is f150f98; startup main was9e0e2ba. Later main contains unrelated native-build correction b0d25ee. Do not discard it when integrating this branch; lane04 does not change shared build configuration or the affected UI owner files. Global milestone state/handoff remains with20; lane04 supplies local evidence and does not promote M02/M03.
