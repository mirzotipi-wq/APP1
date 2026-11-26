# Lane 03 — CPU Study and mannequin handoff

## Current review checkpoint

Branch: `finish/03-cpu-study-mannequin`. CPU rendering source is identical to `db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5`; preview publication and its ten matching tests were validated at `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`. The subsequent preview corrections preserve previous-frame validity cues and reconsult the engine on each activation. Their current preview SHA-256 is `9ba7761837c58dde1b973d0740ad97a37ecea2e73ba8c5b69397da625ef805b9`; the new hosted regression brings native discovery to 165 methods. Apple compilation/execution for this source is pending at this checkpoint. Eighty actual fresh workers have completed eight ten-worker waves. Waves 9–10 and final 100-worker acceptance remain in progress.

Campaign fallback was `f150f98e35dd735927075aac4d2f8b02295c6a67`; no lane20 baseline was published in the initial inventory. An ordinary merge retained already-existing main `9e0e2ba` and its `b0d25ee` native UITest CGFloat correction. This lane authored no CI/shared-composition/GPU/cache implementation and never pushed main. Global M02/M03 status remains with20.

## Accepted changes and why they matter

### Independent mesh visibility correction

The head mesh contains5,248 triangles. Its former absolute determinant cutoff rejected legitimate finite near-tangent rays on small polar triangles. The independent ray/plane and projected-area witness has positive barycentric weights and distance about0.0000499979073163m; the old accelerated nearest-hit and visibility queries both missed it.

The parallel cutoff now scales by triangle twice-area. Each immutable triangle caches its outward geometric normal and twice-area; vertices, BVH topology, interval/tie behavior and triangle coverage stay unchanged. Tests use an independent plane/projected-area calculation, not only the accelerated implementation against another loop calling the same intersection routine. Twenty-five actual Swift near-tangent cases pass after the fix. W22 preserves50forward/reverse and150interval checks; W30 independently solved75windows with90-digit arithmetic and confirmed seven original misses. Their Python evidence is separately labelled from Swift execution.

The additional cached scalar payload is logically164KiB across the fixed mesh; this is not a measured Swift allocation or RSS claim. See `evidence/grazing-original.json`, `wave02-original-probes.log`, and worker wave2/3 evidence.

### Camera clipping now preserves closed surfaces

A primary mannequin ray now finds its true first surface from minimum distance0 before checking the camera-depth plane. If the first head/clothing surface is closer than the minimum camera depth, the renderer throws invalidCamera. A clipped open-panel hit remains background. The correction uses one geometry traversal and does not weaken real near-emitter invalid-surface masks.

The original overhead width144 image contained11,708 unsupported pixels despite having no lights. It is retained under `evidence/camera-original/`. An initial facing-only repair missed rays whose later neck entry faced the camera. W32's held-out scan found22affected poses; of40retained renderer calls,32returned images and8already rejected the camera. The final first-surface repair rejects all40. The exact source-hash sidecar `workers/wave04-evidence/W32-depth-corrected-inputs.json` identifies the tested source; the raw probe's older path/revision labels were deliberately not rewritten.

Five camera-depth regression methods now cover close safe views, original clipped entries/exits, hidden-neck exposure and open-panel clipping. Initial incorrect test assumptions and their failed logs are retained in `evidence/camera-review.json`. A camera rejection has no new render to compare; diagnostic magenta was not painted out or relabelled valid.

### Tiny intensity is restored after each emitter's integration

Positive emitters whose rounded per-sample candela is subnormal are evaluated at unit intensity, then their lux and XYZ contributions are scaled once per emitter. Ordinary accumulation arithmetic/order stays unchanged. Point/directional and contiguous rectangle groups remain separate, preserving mixed-light addition. Rectangle sampling remains64interactive/1,024reference samples. Positive tiny sources retain near-field guards; exact-zero sources retain inactive-light behavior.

The frozen actual Swift W42 probe failed56of166checks before the correction and passed166of166afterward. Five new XCTest methods cover analytic grazing material response, full/clipped rectangles, mixed emitter order, near-field rejection and exact GPU rows. Packing restores the original candela before Float conversion; no field or row was added to the public ABI.

This is an intensity-scaling repair, conditioned on a finite nondegenerate unit evaluation. It is not universal extreme-Double accuracy. Normal sample intensity followed by an extremely grazing cosine/clipped weight can still underflow; W50 preserved copied-arithmetic half-vector and BRDF-intermediate limits separately from actual Swift results. Tiny finite contributions can still pack to Float32 zero and display as black. See [NUMERICS.md](NUMERICS.md).

### Preview lifecycle and cancellation

`ReferenceStudyPreview(scene:subject:)` remains the entry point; its render request excludes placementRoom only. The view presents loading, retryable camera/emitter/general/conversion errors, explicit same-subject previous-frame labels, and static paused status when inactive. Another subject's old image and an obsolete error cannot stand in for the requested result. Current unsupported-pixel warnings/backend badges remain tied to the current request. Wave 8 found that a retained previous frame could lose its unsupported-pixel explanation during an update or a paused different request. The accepted narrow UI correction adds a count explicitly labelled “Previous render” to that image’s accessibility label and the existing updating/paused status container. It does not apply the old frame’s lighting advice or backend badge to the new scene. The publication pipeline, view task and ten tests are byte-identical to source36; `evidence/preview-previous-warning-inputs.json` records the checks. Native compilation and manual accessibility/layout evidence for the changed UI text remain distinct from the earlier pipeline results. Retry preserves scene/cache identity; error content can scroll and its button label has a44-point minimum height.

A MainActor publication pipeline checks generation and cancellation before rendering, after rendering and after conversion. Disappearance/inactivity invalidate old work; A→B→A reactivation begins a generation and consults the engine, which owns valid cached reuse. A retained image is current only when both its request and adopted ticket match the active ticket. An already-cancelled caller now receives an unused ticket without replacing live work, and a cancelled view task returns before mutating generation/frame state.

Ten actual controlled asynchronous tests cover late success/failure, A→B→A, noncooperative completion, invalidation, retry, conversion failure and pre-cancelled entry. The added pre-cancelled-begin test failed two assertions in the original pipeline because the live result was discarded; all ten pass with the correction. This reproduces the generation-seam defect, not SwiftUI's scheduling itself. The original nine test bodies are byte-preserved. The same ten methods also passed in the finalized source36 Apple native suite. The80ms sleep is a debounce, not a cancellation-latency guarantee.

## Evidence and acceptance boundaries

| Evidence | Actual result and scope |
| --- | --- |
| Baseline portable core |366Debug and366Release tests, zero failures. |
| Final CPU local core |391Debug and391optimized per-file Release tests, zero failures. Ordinary local compilation was killed by signal9; failed/empty retry and test-compile logs are retained. |
| Standard CPU CI at db7 |391Debug/0 in13.45s,391standardRelease/0 in5.679s; core job139979301968 of run45839289363. Full log and JSON retained. |
| Final preview portable seam |Original10methods: ninepass, newmethod twoassertionfailures. Corrected10methods/0 failures. Exact production source and XCTest file in a temporary Linux package. |
| Earlier Apple native source ace9 |163native methods/0, no skipped native methods, including nine preview methods; unsigned Debug/Release app builds and six actual simulator Metal fixtures passed. Full raw log/receipt retained. This predates the later depth/tiny/paused/cancelled-begin source. |
| Latest Apple source36 |Unsigned Debug app/native bundle and Release app builds succeeded. All164native methods passed, including all10pipeline methods; finalized accounting reports no failures, skips, duplicates or omissions. The same job passed391portable tests on macOS and six actual simulator Metal fixtures (maximum channel error1, exact masks). UI interaction/accessibility shards remain separate. |
| Final image matrix |All12 frozen original scene JSONs preserved byte-for-byte; all12 PPMs byte-identical; final opaque RGBA and independent valid zero masks archived. |
| CPU/shared-Float32 host parity |Six required cases pass with exact masks; near-field retains84/84unsupported pixels. Eight required precision cases pass with maximum channel error≤1. This executes the actual Swift fixture generator and shared C++ Float32 harness, not Metal. |
| Bounded benchmark |Eight frames, twelve observed cancellations, four visibility workloads; one warm-up and seven measured samples. Raw samples and nearest-rank percentiles preserved. |

Current native evidence is in `evidence/ci-native-36.json` and the byte-exact `ci-native-36.log` (job139992156576 of run45842899560). Actual native evidence remains attached to its tested source, even if a later workflow was cancelled. CI project-state success is structural validation, not rendering/native acceptance.

The finalized source36 library/reference UI shard ran nine methods with two ProjectLibraryUITests failures; both ReferencePhotoUITests methods passed. The failures concern a project-name-entry waiter and the library Done control's normal-action assertion. Two dependent visual jobs could not obtain the compact artifact from the cancelled accessibility shard, so neither completed visual review. The original logs and exact observations are preserved in `evidence/ci-ui-failures-36.json`; shared UI and tooling work is routed to 01/19. Native success is not a whole-UI or global M03 pass.

## Image review and hashes

Original images, JSON and manifest are in `evidence/original/`; final images, JSON, RGBA and raw validity masks are in `evidence/final/`. `final-comparison.json` records individual SHA-256 values and zero changed pixels for all twelve required scenes. `final-source-manifest.json` binds the compiled CPU source; `final-parity-inputs.json` binds the fixture commands, kernel/header and binary hashes. The original twelve-scene archive had validated zero-mask counts, not separately saved raw mask files; final raw masks are now included.

The required matrix covers soft/hard/warm sphere lighting, soft/hard/side mannequin lighting, key-only/fill-only, rim-only bust, rolled rectangle, exposure−2 and3200K white balance. Root inspected the original and final contact sheets; W37 independently inspected the previous source's sheet and three paired bust images. Review sees preserved authored silhouettes, continuous neutral shading and finite-emitter shadows. Dark fill/rim cases remain deliberate direct-light scenes. The original pointed crown is authored geometry, not a newly introduced intersection artifact. Wave 8 independently viewed the saved contact sheets and paired bust/sphere diagnostics, checked encoded image data and masks, and completed [IMAGE_REVIEW.md](IMAGE_REVIEW.md). Its captions distinguish white-balance/exposure changes from emitter color and rectangle roll from camera/head rotation.

No baseline image was replaced to conceal a changed result. Ordinary images are unchanged; the repaired grazing ray, clipped-camera rejection and tiny numerical response are preserved as additional diagnostic cases with their originals/failures.

## Runtime and resource limits

Mannequin width remains≤144, per-emitter rectangle sample counts remain64/1,024, and cancellation polling remains at most eight further pixel evaluations. Engine/cache ownership stays with04; existing limits are fourframes,256KiB RGBA and64KiB masks. This lane did not alter those implementations. These are numeric/render/cache bounds. Arbitrary light-name validation still depends on input bytes; its grapheme limit is not a UTF-8 byte bound. Shared admission/schema changes remain with01.

Final shared Linux optimized diagnostics: mannequin144point3 p50/p95=8.259656/8.685065ms; mannequin144area3=181.067702/186.794669ms. All12 cancellation probes observed cancellation; maximum requested-deadline-to-return was1.606625ms. These are short shared-host measurements with scheduler noise, not iPhone frame-rate, sustained throughput, RSS, energy or thermal evidence. `final-benchmark.json` retains every workload/sample; its raw revision field names the parent while the candidate was uncommitted, and `final-benchmark-inputs.json` binds the exact later db7 source without rewriting raw data.

Four executor outages lost temporary trees/builds while persistent evidence survived. Persistent worktree indexes initially exhausted disk; later workers use a private sparse shared control clone with temporary indexes. Signal9 builds, empty-log retry, source/test compile error and unavailable native work remain explicit. `runtime-interruption-four.json` records a partial artifact upload at that moment; `runtime-four-recovery.json` confirms all51unique artifact blobs were subsequently preserved by exact Git SHA checks. Only this lane's clean trees are removed after remote preservation; no other task's files were removed.

## Coordination and remaining integration work

[OWNER_REQUESTS.md](OWNER_REQUESTS.md) and [CONTRACTS.md](CONTRACTS.md) route numerical02, shared composition01, GPU/cache04, CI19 and final integration20 responsibilities. The actual Swift width24/focal161.27198111190464 silhouette counterexample remains preserved at the unchanged parity thresholds. Wave 7 bound lane04’s width-aware eligibility guard to its inspected commit and documented that the engine and width-aware helper must integrate together. Lane02’s newest positive-tiny Float-underflow routing request remains an explicit coordination item with04; this lane does not silently expand the Float32 domain or edit its engine.

ReferencePNG is the existing imported-photo PNG sanitizer. It was not changed by this lane; Study diagnostic PPM-to-PNG conversion is separate and does not add photo metadata or a new asset source. Required fixtures and failure artifacts remain intact.

Wave 09 received lane04's newer W057 proposal at `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`. It identifies a view-local reuse path that can retain Metal status after an intermediate cancelled request permanently downgrades the engine. Lane03 accepted ownership and implemented the targeted activation/ticket correction plus a hosted regression. The view retains historical pixels during revalidation and only presents the new engine result/backend as current after guarded adoption. W84, W85, W81 and root reviewed the source; the existing ten pipeline test bodies are unchanged. The hosted test keeps one mounted view, holds B and the second A through explicit continuations, requires two A engine calls and one B call, and uses a positive accessibility-tree control before testing previous/current badges. Syntax and automatic discovery pass; native execution and an original hook-only before/fail run remain unperformed at this checkpoint. See `evidence/preview-adoption-inputs.json`.

The per-wave ledgers and primary reports are under `workers/`. Ten acceptance leaders each instantiate nine distinct fresh specialists; root is excluded, followups/precreated trees are excluded, and actual tool-returned canonical IDs are recorded. Four concurrent contexts is the platform ceiling. Exact token counters are unavailable; requested brief/working/report targets and the coordinator checkpoints are recorded without claiming unmeasured compliance. Final 100-worker ledger audit, independent final review and final branch preservation remain outstanding at this eighty-worker checkpoint.
