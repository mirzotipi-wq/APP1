# Wave 08 — saved image acceptance and previous-frame warning

**Ten actual fresh-context workers completed their assignments:** W71 plus exactly nine children, W72–W80. The existing W74 worker also completed an authorized source followup; it is not an eleventh worker. No followup, precreated tree or root integrator is counted.

The saved twelve-scene image evidence is accepted within its software scope. One source-level accessibility gap, **W78-AX-01**, was found and independently confirmed. W74 prepared a minimal candidate and W80 found no source blocker. Root has integrated that candidate and passed syntax/diff checks; Apple SwiftUI compilation remains pending, and no unrun test is counted as a pass.

## Identities and execution boundary

Immutable input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; documentation checkpoint at wave startup: `8ce5e464253144deccb39d838faef70f05e0c38c`. Each private detached tree was created serially from `worker-control` at that input. All ten heads were verified at closeout. Nine trees are clean; W74 contains only its authorized `App/ReferenceStudyPreview.swift` candidate. No commit, push or cleanup was performed by this wave.

| Worker | Primary report | Actual canonical runtime ID |
|---|---|---|
| W71 | [Acceptance](W71-acceptance.md) | `/root/wave08` |
| W72 | [Geometry/data](W72-geometry.md) | `/root/wave08/w72_geometry` |
| W73 | [API/encoding](W73-api.md) | `/root/wave08/w73_api` |
| W74 | [Implementation/exhibit](W74-implementation.md) | `/root/wave08/w74_implementation` |
| W75 | [Concurrency](W75-concurrency.md) | `/root/wave08/w75_concurrency` |
| W76 | [Resources](W76-resource.md) | `/root/wave08/w76_resource` |
| W77 | [Consumer/color](W77-consumer.md) | `/root/wave08/w77_consumer` |
| W78 | [Accessibility/privacy](W78-accessibility-privacy.md) | `/root/wave08/w78_accessibility_privacy` |
| W79 | [Platform/performance](W79-platform-performance.md) | `/root/wave08/w79_platform_performance` |
| W80 | [Independent review](W80-independent-review.md) | `/root/wave08/w80_independent_review` |

These IDs are the actual spawn-return task names; no separate UUID was exposed. [wave08.json](wave08.json) records assignments, paths, hashes, results and limitations. Primary reports are 236–347 words. Exact runtime token counters are unavailable; the 12,000-token target and 60% checkpoint are not measured claims.

## Image and provenance findings

W71, W72, W74, W77 and W80 directly viewed actual saved images. The [image exhibit](../IMAGE_REVIEW.md) contains exact scene settings and all twelve observations. Every original/final PNG, PPM and scene JSON pair is byte-identical. PNGs are RGB8 and decode to the PPM bytes and the RGB channels of final raw RGBA; all final alpha bytes are 255 and all **136,320 final mask bytes are zero**. Five busts are 144×96 and seven spheres are 120×80. Contact-sheet dimensions differ only as presentation layouts. The narrow crown is present in the original geometry/images.

The historical `warm` fixture means white balance 3200 K and +1 stop, with unchanged emitter temperatures. `white-balance-3200` uses 3200 K and 0 stops. `bust-roll-90` rotates the non-square key emitter. Color adaptation and exposure precede tone mapping and sRGB encoding, so display RGB does not scale proportionally with stops. These are synthetic neutral direct-light models, without calibrated skin or photographic-fidelity claims.

Original standard-fixture raw RGBA/masks were not archived; their historical raw equality is unproven. The original camera diagnostic mask is available: W80 counted **11,708** invalid positions and magenta pixels in the 0.18 m overhead no-light frame. The corrected record is **`invalidCamera`, with no clipped frame**. The 0.20 m clear PNG/PPM/mask remain identical. No corrected error screenshot was manufactured.

All 31 LightingCore inputs match the final source manifest and remain unchanged from `db7a5b5` at source36. The PNG conversion command/version was not found in the bounded retained-evidence search; the encoding claim concerns saved-file equality. The original W74 exhibit is preserved byte-for-byte in [its archive](wave08-evidence/W74-image-review-original.md); the current exhibit has an explicitly attributed later native-status update. All **43 current exhibit links** resolve.

## Resource, timing and platform findings

The twelve archived images contain **545,280 RGBA bytes + 136,320 mask bytes = 681,600 raw bytes**. These files are not twelve concurrently cached frames. Source limits remain twelve lights, 64/1,024 samples per rectangular emitter, mannequin width 144, pixel cancellation polling every eight evaluations, and four cached frames subject to 262,144 RGBA bytes plus 65,536 mask bytes. Four maximum mannequins fit those payload caps; only two maximum 192×128 sphere frames fit. These are retained-payload limits, not resident-memory measurements. Names have an 80-character limit without a UTF-8 byte cap, so numerical bounds do not bound all validation work.

W79 independently recomputed all twelve workload p50/p95 pairs: eight frame workloads provide 56 measured samples and four visibility workloads provide 28, following one warmup per workload. At n=7, nearest-rank p50/p95 select ranks four/seven. Twelve separate cancellation probes all observed cancellation; aggregate deadline-to-return p50/p95 are **0.640759/1.606625 ms**. These are historical host diagnostics. The archive retains one hash per frame workload; repeated-byte equality comes from the benchmark's checked source/run assertion, without individually archived repeated-image bytes. Raw revision `74f7584` is preserved separately from the manifest's actual compiled source `db7a5b5`.

The Linux benchmark uses the retained Swift 6.2.1/optimized methodology and its declared host. Apple evidence is separate. W78/W79/W80 verified the finalized source36 log hash and **164 unique native passes**, including all ten pipeline methods; six actual simulator Metal fixtures passed with maximum channel error 1 and exact-mask acceptance. Debug/native-bundle and Release app builds and 391 macOS portable tests succeeded. UI interaction/accessibility shards and physical-device/VoiceOver validation are not established by that receipt.

Historical pipeline accounting remains exact: nine original methods passed; the added-regression run attempted ten with one failed method/two failed assertions; the corrected run passed ten. Only three directly exercise cancellation. Current source36 preview/tests match the wave06 manifest, while the older rendering manifest contains older preview hashes.

## W78-AX-01 and the authorized candidate

A same-subject previous image remains visible when its request differs from the current request. At source36, the warning was limited to `isCurrent`, and the previous-image accessibility label omitted its unsupported count. A positive-count previous frame therefore lost its non-color invalid cue during updating or paused previous-frame states. Inactivity alone on an unchanged current request preserves its warning. This was independently confirmed by W78, W71 and W80 from source; native UI/VoiceOver reproduction was not performed.

The [W74 followup](W74-implementation-followup.md) adds a previous-frame-qualified count to the previous-image label and a compact line within the existing updating/paused status stack. It leaves current warnings, accessibility IDs, pipeline, task identity and tests unchanged. It adds no old lighting advice/backend to the new scene and no second overlapping status overlay.

Candidate SHA-256: `612e922e16a900bf69cbc1bf13d9995912db535703a4b0bd85f372de1f1d44a5`. [Patch](wave08-evidence/W74-previous-frame-warning.patch) SHA-256: `cf1a9ac9711102a7d81b3ea153a11bffaaa67cb585aa22b484af1dd65a223e05`. W74 diff/patch checks passed; W71 and W80 source review found no blocker. Source36 Apple evidence predates this candidate. Root has integrated it and recorded successful Swift syntax parsing and diff checks in [the integration receipt](../evidence/preview-previous-warning-inputs.json). Linux parsing does not typecheck SwiftUI; Apple native compilation remains pending.

## Preserved failures and handoff

No new executor reset occurred. Four historical outages remain recorded. W72's optional command-receipt write failed with **ENOSPC/errno 28**, leaving a zero-byte file; the exact failed write and surviving artifact checks are in [W72-write-failure.json](wave08-evidence/W72-write-failure.json). The empty file remains an intentional failed artifact, not valid JSON or a pass. Corrected read-only inspection errors are retained in individual receipts. No old evidence was deleted.

The [artifact manifest](wave08-evidence/W71-wave-artifact-manifest.json) hashes 39 substantive reports/evidence files, including the preserved empty failed write. All raw evidence remains separate from the short worker reports. No fresh render, benchmark, Swift/native suite or build was executed by wave08. Cross-lane tiny-Float policy and paired lane04 engine/helper requests remain owner work and were not closed by this image review.
