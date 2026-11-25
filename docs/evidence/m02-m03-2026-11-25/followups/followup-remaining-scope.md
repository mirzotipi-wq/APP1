# M02/M03 remaining scope — final narrow audit

Read-only requirement/implementation review. No builds, runtime execution, network or new agents. Publication `d99c9bdfc1b3c1a185d87079efcc62cd34049279` and running workflow `45593950430` are parent-supplied facts, not independently queried here.

## Prioritized finding

**No additional mandatory Linux-executable acceptance gap was identified beyond the assigned abrupt-interruption/rename probes and the pending source-specific CI.** This is a scoped requirements conclusion, not a claim that the implementation is defect-free or that M02/M03 pass. Finish actual CI/probe outcomes, repair concrete failures, and retain exact revision/environment/raw evidence. Do not repeat broad host audits merely to expand activity.

| Protected requirement | Current implementation/evidence and remaining work |
|---|---|
| M02 photometry | `Tests/LightingCoreTests/SurfacePhotometryTests.swift` directly checks point cosine/inverse-square, analytic rectangles and independent off-axis numerical reference; the latter retains `<0.05` relative error. `PhotometryInvariantTests.swift` adds coordinate/scaling invariants. SI/domain limits are documented. Existing portable suites plus the current CI cover this host-executable requirement. |
| M02 rendering | `docs/QUALITY.md` requires twelve rights-cleared controlled scenes, calibrated comparison, independent photographer review, and no clipping/flicker/obvious geometry errors in required cases. Synthetic Study fixtures and CPU/GPU parity do not supply that evidence. Actual reference capture/calibration and human review remain external. A protocol/manifest can be prepared locally now. |
| M02 performance | Actual physical iPhone 13 or agreed baseline, release, three-light standard portrait: 60-fps target, p95 frame time ≤20 ms after warmup over five minutes; fifteen-minute thermal run, peak resident memory ≤350 MB, no critical thermal state. Host benchmark cost remains diagnostic. No device frame-time/thermal/resident-memory capture harness was found in App/NativeTests/UITests; a measurement procedure is useful preparation, not a new acceptance gate. |
| M03 editing | Precise units, undo/redo, stable selection, valid transforms and no lost edits have portable/native/UI coverage. `UITests/StudioSmokeTests.swift` contains ten separately named complete gesture→Undo→Redo→save→relaunch runs, plus recipe/selection flows; `PrecisionEditingUITests.swift` and `ProjectLibraryUITests.swift` cover exact editing and library lifecycle. Current-source Apple execution is the remaining assigned evidence. The contract does not additionally demand ten different workflow types. |
| M03 accessibility | Automatic `.all` audits remain in CI; latest fixes still require their actual outcomes. The protected manual real-device audit must cover VoiceOver, Dynamic Type, contrast, non-color cues, numeric editing and reduced motion. `App/StudioView.swift` honors reduced-motion navigation, but source inspection cannot replace the manual audit. |
| M03 persistence | Existing portable/native/UI suites cover migration, malformed/oversized input, round-trip, deletion/recovery, concurrent/stale writes and byte preservation. Existing EFBIG plus assigned abrupt/rename probes address real write-failure/interruption evidence. This gate has **no physical-device requirement**. |

## Host work still useful now

1. **Reconcile status once results are available.** `agents/HANDOFF.md`, `agents/state.json`, `agents/evidence.json`, and `docs/evidence/m02-m03-main-2026-11-25.md` still describe the prior main or preparing publication. Preserve `9602683` failures as historical, record `d99c9bd` publication/running outcome separately, and promote only exact-source results actually observed. This is evidence maintenance, not a newly missing product gate.
2. **Correct one stale implementation statement.** `docs/ARCHITECTURE.md` says the Study renderer retains its fixed grid “including at grazing angles.” `Sources/LightingCore/ReferenceStudy.swift` and `App/StudyKernel.h` now use continuous clipped-area column weights/centroids for partial faces, retaining fixed full-face samples and bounded sample counts. Update the description while retaining approximate-shadow/Float32/physical-calibration limitations. This supports accurate model documentation; it does not require another broad numerical test run.
3. **Prepare the external kit below.** Existing `docs/DESIGN.md` contains only a benchmark-plan paragraph; no complete twelve-scene manifest, calibration/reviewer form, device measurement procedure/sample schema or manual-accessibility checklist was found.

## Concrete external kit, without duplicating existing files

The proposed `docs/acceptance/m02-m03-external-evidence.md` plus JSON capture manifest is sufficient as one cohesive kit:

- Twelve planned scene IDs mapped to key/fill/rim, soft/hard, skin/material and shadow coverage. Leave rights, actual subjects, camera/exposure/profile, light positions/distances/output/modifier dimensions, measured calibration, source assets/hashes and outcomes empty until supplied. Include gray sphere/plane/chart calibration references and consistent exposure/tone-mapping procedure from `docs/DESIGN.md`.
- A per-scene paired simulated/physical comparison and independent-photographer review record: reviewer, revision, case, geometry/clipping/flicker observations, defects and disposition. Do not invent new numerical image-similarity thresholds or imply aesthetic inspiration is ground truth.
- Exact performance workload/build/device settings, warmup and recording durations, raw sample artifact locations, frame-time definition, resident-memory units, thermal observations and unchanged pass criteria. App-frame measurements must be distinguished from standalone Study render latency. If platform tools cannot export a required quantity, record the gap before adding instrumentation.
- Manual accessibility task checklist covering all six protected capabilities across launch/projects/plan/inspector/exact numeric edit/history/save/relaunch/recovery. Record device/OS/settings, actual observations, issues and evidence; initial status is unrun.

## Recommended extras, not new M02/M03 obligations

Permission-denied, true ENOSPC, additional OS/device matrices, broader randomized fault campaigns and extra performance tuning may be valuable follow-up to concrete evidence. Do not present them as separately enumerated M03 gates. `docs/QUALITY.md` assigns physical low-storage/interruption/device-matrix coverage to M07. Optional LiDAR, equipment libraries, advanced area rendering, crew sharing and calibrated camera workflows remain optional per `docs/ROADMAP.md`. Neither optional work nor a prepared kit closes the external gates.
