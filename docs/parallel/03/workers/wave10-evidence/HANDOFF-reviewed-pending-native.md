# Lane 03 — CPU Study and mannequin handoff

## Delivery status

Lane 03 has corrected grazing mesh intersections, clipped-camera handling, tiny
emitter integration and preview publication. The twelve ordinary synthetic
fixtures retain their original scene and image bytes. Portable CPU evidence
passes for executable source **342e3280e3eb077d55e122c8bfb88b4062b431ed**.
Its Apple Debug build-for-testing also passed. The current studio-optics UI
run failed before any selected method started; native execution remains a
separate status below.

<!-- CURRENT_NATIVE_STATUS_BEGIN -->
**Current native status: PENDING.** Run **45857561126**, native job
**140042273149**, is in progress at the latest root checkpoint. Discovery finds
165 methods, including the hosted adoption regression; the native execution
result and terminal method accounting remain pending.

The same source's full-scheme Apple Debug build-for-testing succeeded in UI job
**140042273238** at 16:32:46 UTC on 2026-11-26. Its now-retained full log explicitly
compiles StudyPreviewAdoptionTests.swift and records TEST BUILD SUCCEEDED.
That UI job subsequently failed during runner initialization: **zero method
starts and ten unstarted studio-optics methods**. Build success, failed required
UI execution and pending native execution are separate outcomes. The latest
completed native suite remains the 164-method result at source
**36ed6a1455dee7ca52b55f46d1a47262f5c98cc1**. See the
[build receipt and appended terminal followup](evidence/ci-apple-build-342.json)
and [current UI terminal receipt](evidence/ci-ui-studio-optics-342.json).
<!-- CURRENT_NATIVE_STATUS_END -->

<!-- FINAL_100_WORKER_STATUS_BEGIN -->
**Final 100-worker status: COMPLETE.** W01–W100 completed their primary assignments
across ten waves, with 100 unique actual runtime IDs, ten distinct roles per wave
and 100 retained primary reports with recorded hashes. W100's primary independent
review is complete. The strict final ledger check completed without validation
errors. See the [readable aggregate ledger](WORKER_LEDGER.md) and
[machine-readable aggregate ledger](WORKER_LEDGER.json). Root, same-context
followups and unused precreated worktrees are excluded from the worker count.
This completed accounting does not establish native/UI or milestone acceptance.
<!-- FINAL_100_WORKER_STATUS_END -->

This is a lane delivery under [m02-m03-code-v2](../../acceptance/m02-m03-code.md).
Lane 20 owns integration and global milestone decisions. This document claims no
global M02/M03 completion, release readiness, physical-device performance,
photographic calibration, manual VoiceOver session or completed platform audit.

## Exact source and integration identity

| Item | Identity and meaning |
| --- | --- |
| Lane branch | finish/03-cpu-study-mannequin |
| Executable source reviewed here | 342e3280e3eb077d55e122c8bfb88b4062b431ed |
| Documentation input for this rewrite | 92dc7a69c0032141ee49de0b96940fccab83a33e; later documentation does not create a new executed source result |
| CPU implementation checkpoint | db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5 |
| Latest completed Apple native-suite source | 36ed6a1455dee7ca52b55f46d1a47262f5c98cc1 |
| Campaign fallback | f150f98e35dd735927075aac4d2f8b02295c6a67 |
| Main already present at startup | 9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318 |

The SwiftPM CPU paths—Sources/LightingCore, Tests/LightingCoreTests and the
retained CPU fixture/host-harness scripts—are unchanged from db7 to source 342.
All 31 LightingCore hashes in the [final source manifest](evidence/final-source-manifest.json)
match. **App/ReferenceStudyPreview.swift and NativeTests changed separately.**
The preview and pipeline-test entries in that older manifest are historical;
use the [preview adoption receipt](evidence/preview-adoption-inputs.json) for
current app and native-test identities. [W93's audit](workers/W93-api.md) records
the exact source and artifact comparison.

| Current file | SHA-256 |
| --- | --- |
| App/ReferenceStudyPreview.swift | 9ba7761837c58dde1b973d0740ad97a37ecea2e73ba8c5b69397da625ef805b9 |
| NativeTests/StudyPreviewAdoptionTests.swift | abd3fa97bb0cda6d45e4e9f66b068f1155ea4672b87542a081c33e6d72967f91 |
| NativeTests/StudyPreviewPipelineTests.swift | a68a38abce16baff2eee55c175bd3874664d8707d6c358d04282691455407c99 |

An ordinary merge retained the already-existing main changes, including the
b0d25ee native UITest CGFloat correction. Lane 03 authored no shared-composition,
GPU, cache or CI implementation and did not push main. No lane 20 campaign
baseline was published in the initial inventory. These facts explain the
inherited source; they do not establish acceptance of other lanes.

## What changed and why

### Grazing rays now intersect small head triangles consistently

The authored head has 5,248 triangles. The old absolute determinant cutoff could
reject a finite near-tangent hit on a small polar triangle. An independent
ray/plane and projected-area witness had positive barycentric weights and a hit
distance of about 0.0000499979073163 m, while both accelerated nearest-hit and
visibility queries missed it.

The cutoff now scales with triangle twice-area. Each immutable triangle caches
its outward geometric normal and twice-area; vertices, BVH topology, interval
rules, tie handling and triangle coverage are preserved. The extra cached
scalars represent a logical 164 KiB payload across the fixed mesh, not a measured
Swift allocation or resident-memory increase.

The retained checks have different execution scopes and must not be added
together as one test count:

| Evidence | Actual scope |
| --- | --- |
| Retained Swift probes/regressions | 25 ray cases: the original witness plus 24 constructed cases |
| W22 translated Python arithmetic | 50 forward/reverse rays and 150 distinct input windows, each evaluated by two methods; 14 original-cutoff misses |
| W30 independent high-precision Python | 25 selected-face solves on six faces, 75 windows, 90-digit arithmetic; seven original-cutoff misses |
| W92 final reconciliation | Read-only artifact/source audit; no new Swift execution |

W92 also reconciled 2,626 welded vertices, 7,872 edges and 5,248 triangles, with
paired opposing edge incidences, one component and Euler characteristic 2. This
checks combinatorial closure; it does not establish absence of self-intersection
or correctness for every possible ray. See [W92](workers/W92-geometry.md),
[W22](workers/W22-geometry.md), [W30](workers/W30-independent-review.md), the
[original witness](evidence/grazing-original.json) and the
[original probe log](evidence/wave02-original-probes.log).

### A clipped closed mannequin is rejected before an image is published

A primary mannequin ray now finds the true first surface from minimum distance
zero before checking camera depth. A closed head/clothing surface in front of
the minimum depth causes invalidCamera. A clipped open-panel hit remains
background. The correction uses one geometry traversal and retains the existing
near-emitter invalid-surface rules.

The original 144 × 96 overhead scene had no lights yet returned **11,708
unsupported pixels**. The corrected result is invalidCamera, with **no new
clipped frame**. The adjacent clear-camera image remains byte-identical.
[IMAGE_REVIEW.md](IMAGE_REVIEW.md) displays the saved diagnostic and distinguishes
magenta unsupported pixels from illumination.

An initial facing-only repair did not catch rays that entered the neck later.
W32's held-out scan found 22 affected poses. Its 40 retained renderer calls changed
from **32 returned images and eight rejections to 40 rejections** under the final
first-surface repair. The [source sidecar](workers/wave04-evidence/W32-depth-corrected-inputs.json)
is authoritative for the corrected run; older embedded path/revision labels in
the raw probe were retained.

Five camera-depth methods cover safe close views, clipped entries/exits,
hidden-neck exposure and open-panel clipping. Initial incorrect witness
assumptions and failed logs remain in the [camera review](evidence/camera-review.json).
The [original result](evidence/camera-original/result.json) and
[corrected result](evidence/camera-corrected/result.json) preserve the error/frame
distinction; no diagnostic pixels were painted out or relabelled valid.

### Tiny positive emitter output is restored after integration

When rounded per-sample candela is subnormal, a positive emitter is evaluated at
unit intensity and its lux/XYZ contribution is scaled once after that emitter's
integration. Ordinary accumulation order and arithmetic retain their existing
path. Point/directional emitters and contiguous rectangle groups remain separate,
preserving mixed-light addition. Rectangle sampling remains 64 interactive or
1,024 reference samples.

The frozen W42 probe was actually compiled and executed in Swift: it had **56
failures among 166 checks before the correction and zero afterward**. Five added
XCTest methods cover grazing material response, full/clipped rectangles, mixed
emitter order, near-field rejection and packed rows. Positive tiny emitters keep
their geometry guards; exact zero keeps the existing inactive-light behavior.
Packing restores original candela before Float conversion, with no added public
ABI field: six parameter float4 rows, three rows per sample and three per area.

The supported result requires a finite, nondegenerate unit-intensity evaluation.
Later underflow from an extremely grazing cosine or clipped weight remains
possible, as does final subnormal quantization. W50's half-vector and extreme
BRDF-intermediate witnesses use copied Python arithmetic and are not actual Swift
reproductions. Positive Double values can still pack to Float32 zero and display
as RGB8 black. The correction does not broaden the GPU domain. See
[NUMERICS.md](NUMERICS.md), [W42](workers/W42-geometry.md),
[the original Swift result](workers/wave05-evidence/W42-original-result.log),
[the corrected Swift result](workers/wave05-evidence/W42-candidate-result.log)
and [W50](workers/W50-independent-review.md).

### Preview publication tracks both request and activation

The app-facing entry remains ReferenceStudyPreview(scene:subject:), with sphere
as the default subject. Its request excludes placementRoom only. Loading,
retryable camera/emitter/general/conversion errors, same-subject retained images
and an inactive paused state remain explicit. Another subject's image or an
obsolete error cannot stand in for the requested result. Retry creates a fresh
attempt without editing the scene/cache identity; error content can scroll, and
the Retry label has a 44-point minimum height.

The MainActor publication pipeline checks generation and cancellation before
rendering, after rendering and after conversion. Disappearance and inactivity
invalidate old work. A pre-cancelled caller receives an unused ticket without
superseding live work, and a cancelled view task returns before changing state.
The retained before/fail run used the actual pipeline: the added pre-cancelled
test failed two assertions, then all ten pipeline methods passed after correction.
The original nine test bodies were preserved. Those ten methods also passed in
the source-36 Apple suite. This is evidence for the publication seam; its tests
do not reproduce SwiftUI scheduling. The 80 ms sleep is a debounce, not a
cancellation-latency guarantee.

Two later changes must be distinguished:

| Change | Behavior and evidence boundary |
| --- | --- |
| W78 previous-frame warning correction | Added the previous render's unsupported-pixel count to its image accessibility label and updating/paused status. At that step, the pipeline, view task and ten tests were unchanged from source 36. The [warning receipt](evidence/preview-previous-warning-inputs.json) records that historical comparison. |
| Response to lane 04's later W057 proposal | Changed activation/task logic to consult the engine every time, and made a frame current only when both its request and adopted ticket match. Retained pixels remain labelled previous while revalidation runs. The pipeline body and complete ten-test file remain source-36-identical, but the current view task does not. |

The W057 proposal described A → B → A: a cancelled B can downgrade the engine
while its publication is suppressed, and the former view-local shortcut could
then present A's old Metal status without asking the engine. The correction
leaves valid cache reuse to the engine and suppresses old current-frame warnings
and backend badges until guarded adoption. The previous render retains its own
unsupported-pixel explanation without applying old lighting advice to a new
request.

The added hosted test holds **one mounted view identity**, controls B and the
second A with continuations, requires two A calls and one B call, and establishes
a positive accessibility-tree observation before checking previous/current
elements. Its injected Metal/CPU-labelled outputs are synthetic. It forces an
active sphere preview and manually completes B with cancellation; it does not
execute a real GPU downgrade, pause/reattachment or actual SwiftUI cancellation
delivery. These are limits of the test, not demonstrated source defects.

An original hook-only native before/fail execution for this latest test remains
unperformed. The current Apple runtime status is in the delivery block above.
The successful Apple build, source review, syntax/discovery and earlier ten
pipeline passes do not replace that runtime result. See the
[adoption receipt](evidence/preview-adoption-inputs.json) and
[retained lane 04 proposal](evidence/lane04-preview-proposal/owner-proposal.md).

[W98's final accessibility/privacy review](workers/W98-accessibility-privacy.md)
completed 13 read-only checks without demonstrating another source defect. It
found explicit textual/status cues and a declared Retry label minimum, but did
not measure actual control geometry, scrolling reachability or rendered contrast.
VoiceOver and Reduce Motion behavior remain unexecuted. Source inspection and
synthetic renderer images do not supply those native accessibility results.

## Executed tests and their source boundaries

| Evidence | Result and interpretation |
| --- | --- |
| Baseline portable core | 366 Debug and 366 Release tests, zero failures; [baseline receipt](evidence/baseline.json). |
| Final CPU local checks | 391 Debug and 391 optimized per-file Release tests, zero failures on Swift 6.2.1/Linux. Release disabled whole-module optimization and used one compiler process after failed ordinary builds; [commands and failures](evidence/wave05-test-inputs.json). |
| Standard CPU CI at db7 | 391 Debug / 0 in 13.45 s and 391 standard Release / 0 in 5.679 s; run 45839289363, core job 139979301968; [receipt](evidence/ci-core-db7.json). |
| Current source-342 portable CI | **391 Debug / 0 in 13.234 s; 391 standard Release / 0 in 5.368 s.** Six exact-mask host parity and eight strict precision cases pass; run 45857561126, core job 140039890668; [receipt](evidence/ci-core-342.json) and [raw log](evidence/ci-core-342.log). This core job does not typecheck UIKit/SwiftUI or execute the hosted test. |
| Portable publication seam | The original ten-method run had one failed method/two assertions; corrected ten-method run had zero failures. Exact production pipeline and XCTest source were used in a temporary Linux package; [original receipt](evidence/preview-cancelled-begin-original-inputs.json), [original log](evidence/preview-cancelled-begin-original.log), [corrected log](evidence/preview-cancelled-begin-corrected.log). |
| Earlier Apple source ace9f2e | 163 native methods / 0, including nine pipeline methods, unsigned Debug/Release app builds and six actual simulator Metal fixtures. This predates later depth/tiny/paused/pre-cancelled changes; [receipt](evidence/ci-native-ace9.json). |
| Latest completed Apple native suite at 36ed6a1 | Unsigned Debug app/native bundle and Release app builds passed; 391 portable macOS tests and **164 native methods / 0** passed, including all ten pipeline methods. Final accounting has no native skips, duplicates or omissions. Six actual simulator Metal fixtures passed with maximum channel error 1 and exact masks; [receipt](evidence/ci-native-36.json), [raw log](evidence/ci-native-36.log). |
| Current source-342 Apple build and runtime | Full-scheme Debug build-for-testing passed in UI job 140042273238; the [full log](evidence/ci-ui-studio-optics-342.log) confirms compilation of the new hosted test and TEST BUILD SUCCEEDED. See CURRENT_NATIVE_STATUS above for the separate 165-method native runtime status. The earlier 164 methods do not execute the new hosted test. |
| Current source-342 studio-optics UI | Job 140042273238 failed with **zero method starts and ten unstarted methods** after simulator recovery-preflight timeout and UI runner initialization failure. No selected app-test assertion was observed; this is unsuccessful required UI execution. [Terminal receipt](evidence/ci-ui-studio-optics-342.json). |

The source-36 native job was 139992156576 in run 45842899560, using Apple Swift
6.3.3, Xcode 26.6 and x86_64 macOS 26.6.1 according to its log. Later workflow
cancellation does not erase a finalized result, and that result remains tied to
its actual source. Project-state/ledger success is structural validation, not
rendering, native, UI or milestone acceptance.

### Current source-342 UI execution failed before the selected methods started

The finalized studio-optics job 140042273238 in run 45857561126 has **zero
method starts and all ten selected methods unstarted**. Simulator
recovery-preflight timed out with exit −9. The subsequent UI runner failed to
initialize with XCTDaemonErrorDomain Code 18, timing out while waiting for the
AX-loaded notification. The test command exited 65 and method accounting exited
1. No selected product assertion ran; this evidence does not identify an app
behavior defect or count any of those methods as passed.

The [terminal receipt](evidence/ci-ui-studio-optics-342.json) and
[complete raw log](evidence/ci-ui-studio-optics-342.log) preserve the failures and
the earlier successful Debug test build. The [build receipt](evidence/ci-apple-build-342.json)
keeps its initial metadata and appends the finalized-job followup. Route the
runner initialization and exact method accounting to **19**, retaining the
original boot/host/xcresult artifacts. An initialized runner and actual selected
method results are still required. The separate native job remains pending as
recorded above.

### Historical source-36 UI and visual failures remain unresolved by this lane

The library/reference shard executed **seven ProjectLibraryUITests methods,
with two failures**, and **two ReferenceComparisonUITests methods, both passing**.
The failed observations were:

- The project-name entry waiter for “Keep” timed out in
  testArchivedDeleteRequiresConfirmationAndPersistsOnlyThatRemoval.
- The forwarded normal-action assertion for the library Done control failed in
  testCreateDuplicateRenameSwitchAndRelaunch. The log identifies the expected
  control but does not distinguish which final enabled/hittable predicate failed.

The other listed UI shards were cancelled. The Default and AXXXL visual jobs
failed because the cancelled app-accessibility shard produced no
ui-app-accessibility-evidence-compact artifact. **Neither visual job completed
an image review.** The corrected [failure receipt](evidence/ci-ui-failures-36.json)
and its three byte-exact logs preserve these outcomes and the earlier receipt's
history. Neither failure identifies the Study preview; no further causal claim
is supported. Owner 01 receives the UI observations; owner 19 receives the
artifact/dependency failure. Native success is not a whole-UI or global M03 pass.

## Saved images, parity and precision are separate evidence sets

| Set | Inventory and result |
| --- | --- |
| Ordinary synthetic images | 12 scene JSON / PPM / PNG pairs are byte-identical between the original and final archives. Every final raw RGBA alpha byte is 255 and every final raw validity-mask byte is 0. Original raw RGBA/masks were not archived; their equality cannot be proved from the manifest's zero-count report. |
| Required CPU/shared-Float32 host parity | Six cases pass the unchanged RGB tolerances with exact mask positions. The near-field case deliberately retains 84 / 84 unsupported pixels; it is not one of the ordinary zero-unsupported images. |
| Required precision | Eight far-camera/world-translation cases pass the strict maximum-channel-error limit of 1; the retained checked results have maximum error 0. |
| Additional generated diagnostics | 25 supplemental probes: nine tangent, 14 near-mask and two light-distance. Their presence is not an additional required-case pass claim. |
| Actual Metal | The six source-36 simulator fixtures are recorded in the native row above; host C++ execution is separate evidence. |

The twelve ordinary fixture names are soft, hard, warm, bust-soft, bust-hard,
bust-side, key-only-hard, fill-only-soft, bust-rim-only, bust-roll-90,
exposure-minus-two and white-balance-3200. [IMAGE_REVIEW.md](IMAGE_REVIEW.md)
links each exact scene and PNG, documents dimensions and rig settings, and
records visual observations. In particular, “warm” changes white balance and
exposure while emitter temperatures remain fixed; bust-roll-90 rotates the
non-square key emitter, not the head or camera.

Root reviewed the original/final contact sheets. W37 reviewed the earlier sheet
and paired bust images; W74 independently viewed the saved sheets and camera
diagnostics and verified the encoded image data and masks. W92/W93 subsequently
reconciled retained identities without rerendering. The authored crown, coarse
contours, dark fill/rim scenes and synthetic neutral materials remain visible
limitations. These images do not validate native Retry/paused controls, Dynamic
Type layout, photographic fidelity or skin calibration.

The [comparison manifest](evidence/final-comparison.json) records individual
hashes and zero changed ordinary-image pixels. The [source manifest](evidence/final-source-manifest.json)
and [parity inputs](evidence/final-parity-inputs.json) bind the actual CPU sources,
commands, shared kernel/header and binaries. The [W93 receipt](workers/wave10-evidence/W93-api.json)
records the final 12 / 6 / 8 inventories and separates the 25 supplemental probes.
The grazing witness, camera rejection and tiny-output checks are additional
diagnostics; unchanged ordinary images alone do not demonstrate those repairs.

## Work bounds and host performance

Mannequin width remains at most 144 pixels. Rectangle integration retains
64 / 1,024 samples per emitter. Cancellation polling allows at most eight further
pixel evaluations after an external cancellation immediately following a false
poll; the sphere renderer checks cancellation before camera/sample setup after
cheap resolution validation. Engine/cache ownership remains with lane 04:
four completed frames, at most 256 KiB RGBA plus 64 KiB validity masks, with
cancelled/failed work excluded. Lane 03 did not change those cache implementations.

These bounds describe numeric rendering and cache work. Arbitrary light-name
validation still depends on input bytes; its grapheme-count limit is not a UTF-8
byte bound. Shared admission/schema changes belong to lane 01.

The [final local benchmark](evidence/final-benchmark.json) used optimized Swift
6.2.1 on shared Linux, one warm-up and seven measured samples for each of eight
frame workloads and four visibility workloads: **84 measured timing samples**.
It also ran **12 separate cancellation probes**, all of which observed
cancellation. Repeated frame bytes agreed and supported frames had zero
unsupported pixels.

| Diagnostic | p50 | p95 |
| --- | ---: | ---: |
| mannequin144point3 | 8.259656 ms | 8.685065 ms |
| mannequin144area3 | 181.067702 ms | 186.794669 ms |

The maximum requested-deadline-to-return time among the cancellation probes was
1.606625 ms. Raw samples and nearest-rank percentiles remain in the report.
Its revision field names parent 74f7584b while the candidate was uncommitted;
the [benchmark input sidecar](evidence/final-benchmark-inputs.json) binds the
compiled code to the later db7 checkpoint without rewriting the raw report.
Source-342 CI also ran its own diagnostics in its retained log. Neither set
establishes physical iPhone frame rate, sustained throughput, RSS, energy or
thermal behavior, and there is no portable timing threshold.

## Retained failures and recovery evidence

| Historical issue | Preserved evidence and disposition |
| --- | --- |
| Grazing-ray misses | [Original witness](evidence/grazing-original.json) and [original Swift log](evidence/wave02-original-probes.log), with separate W22/W30 arithmetic challenges |
| Clipped-camera image and initial incorrect witness | [Original image/result archive](evidence/camera-original/result.json), [camera review](evidence/camera-review.json), and W32's original/corrected scan artifacts |
| Tiny-output failures | [W42 original result](workers/wave05-evidence/W42-original-result.log), unchanged probe and corrected result |
| Pre-cancelled pipeline failure | [Original ten-method run](evidence/preview-cancelled-begin-original.log); distinct from the unrun original hook-only test for the latest adoption change |
| Local compiler failures | [Wave-05 input receipt](evidence/wave05-test-inputs.json): signal-9 Debug/Release attempts, exit-1 retry with empty log, and ambiguous-pow test compilation; the explicit Double annotation corrected the test compile issue |
| Source-36 UI/visual failures | [Corrected receipt](evidence/ci-ui-failures-36.json), unchanged raw logs, and original committed receipt retained in history |
| Current source-342 studio-optics runner failure | [Terminal receipt](evidence/ci-ui-studio-optics-342.json) and [full raw log](evidence/ci-ui-studio-optics-342.log): successful test build, recovery-preflight timeout, failed runner initialization, zero method starts and ten unstarted methods |
| Runtime/storage interruptions | [Fourth interruption](evidence/runtime-interruption-four.json) records the partial upload; [recovery](evidence/runtime-four-recovery.json) confirms all 51 unique artifact blobs later matched exact Git SHAs |

Repeated executor resets lost temporary trees/build outputs while persistent
evidence survived. Historical campaign records describe four outages; the
individual wave-02/03/04/06 and upload narratives have no shared reset IDs and
were not independently deduplicated. [W96's reconciliation](workers/W96-resource.md)
preserves those records without presenting a new outage census. Persistent
worktree indexes initially exhausted disk; later workers used a private sparse
shared control clone with temporary indexes.
Completed-worker cleanup belongs to root and follows remote preservation.
The [wave-09 cleanup receipt](evidence/wave09-cleanup.json) records the later
preservation/cleanup sequence, including its first-attempt stop on W84's
intent-to-add status. No unavailable or interrupted run is counted as a pass.

ReferencePNG remains the existing imported-photo PNG sanitizer and was not
changed by this lane. Study diagnostic PPM-to-PNG conversion is a separate
artifact step; it adds neither a photo-import pathway nor a new source of assets.

## Concrete owner routes

[OWNER_REQUESTS.md](OWNER_REQUESTS.md) and [CONTRACTS.md](CONTRACTS.md) retain the
dated proposals and immutable inspection receipts. They record observations and
requests, not acknowledgments or completed work by the receiving owners.

| Owner | Next integration action and retained evidence |
| --- | --- |
| **02 — photometry/color** | Review the scoped per-emitter restoration against the positive-tiny consumer request, using NUMERICS and the 166-check Swift before/after evidence. Agree the positive per-cell Float-subnormal/zero routing policy with 04; CPU repair alone does not settle that GPU policy. The inspected 02 head was b5c1f008446f8b33f3ee97f8fefe6675058ef347. |
| **04 — GPU/cache** | Integrate the current engine and paired supports(scene,width:) helper at the exact identities below, passing the actual requested width. Establish integrated backend behavior and preserve lane 03 tiny-output/preallocation-cancellation fixes. Keep the separate width-24 silhouette counterexample and unchanged thresholds. Resolve the open 02 tiny-Float policy in owned eligibility/fallback code. W057 is addressed by lane 03 activation/ticket logic; its synthetic hosted test retains the native status above. |
| **01 — shared composition/UI** | Keep the entry point and full render-request semantics when wiring the preview. Investigate the two retained project-library UI failures with their original attachments; no root cause is asserted here. Decide any light-name byte bound or admitted-scene optimization in shared validation without bypassing full validation. |
| **19 — CI/tooling** | Resolve the source-342 studio-optics runner initialization failure while retaining zero starts / ten unstarted methods and the boot/host/xcresult artifacts. Preserve the terminal native result and exact 165-method accounting when available, with hosted adoption and actual Metal execution distinguished. Review source-36 missing compact-artifact dependencies and the lane-04 host-parser concern. No unstarted or cancelled method is a pass. |
| **20 — integration** | Use the completed worker ledger and retained evidence to integrate lane 03 with the owners' paired changes, preserving original failures/fixtures/masks and exact source IDs. Complete final artifact verification, obtain the outstanding native/UI execution evidence and verify remote preservation. Evaluate M02 before M03 under the governing contract; worker accounting and lane CPU/native successes do not settle required UI work or release gates. |

The current inspected lane 04 source is pinned by [W97's consumer receipt](workers/wave10-evidence/W97-consumer.json).
The earlier 88279ba0ee0262ea6c880580c8a85b56342abbff review remains historical.
These 22 source/receipt checks are source evidence, not integrated execution or
owner acknowledgment.

| Lane 04 input | Exact identity |
| --- | --- |
| Inspected head | 69eb9c5096c863e9c8be1c5e53d9faff0d9c3014 |
| OWNER_REQUESTS.md blob | a94998ccb2316f8e0ec4819f514bfa0f32062d41 |
| App/MetalStudyRenderer.swift engine blob | 8c1acd852d85cd99671feaba883db1808bbb5e68 |
| Sources/LightingCore/StudyFloat32Eligibility.swift helper blob | e9764da10eabbffbad6ceee8999977cf31deb197 |

The engine Git object was unavailable locally without fetching, but W97
independently verified the existing supplied copy against that exact Git blob
and SHA-256 4120854ded312ba09e801dab9e34572c400cbd004c886211650d066d4b8853dd.
The engine and width-aware helper must integrate together. The older lane 04
CPU implementation must not replace lane 03's tiny-output or early cancellation
corrections; shared cache source is identical in the inspected inputs.

The retained width-24, focal-161.27198111190464 mm witness has mean channel error
0.107639, maximum 24 and a fraction above four of 0.00520833, exceeding the
unchanged 0.005 threshold, with zero invalid-mask mismatches.
The [actual Swift silhouette probe](evidence/gpu-silhouette-probe.swift) and
[host comparison log](evidence/gpu-silhouette-host.log) preserve the lane-04
counterexample without relaxing thresholds or changing the six startup fixtures.
Source inspection found no demonstrated guard-skipping mask defect in the pinned
kernels: geometry/validity guards precede zero-lux returns. This is narrower than
proving every positive-tiny runtime input safe.

## Completed worker accounting and remaining integration

Ten fresh acceptance leaders each worked with nine distinct fresh specialists.
All 100 primary assignments and reports are complete, as recorded in the
[aggregate ledger](WORKER_LEDGER.md) and its [JSON inventory](WORKER_LEDGER.json).
Per-wave ledgers and individual reports remain under [workers](workers/).
Root, followups and unused precreated worktrees are excluded. Actual tool-returned
canonical runtime IDs identify the workers; the concurrency ceiling was four
active contexts. Exact token counters were unavailable, so requested limits and
coordinator checkpoints do not establish unmeasured token-budget compliance.

Remaining work is final verification of the frozen artifacts, the source-342
native execution result and exact 165-method accounting, successful initialized
execution of the required UI methods, paired owner integration and verification
of remote preservation. The current zero-start studio-optics failure and earlier
source-36 failures remain retained. Later source changes require a fresh
affected-gate decision; historical passes keep their original source identities.
