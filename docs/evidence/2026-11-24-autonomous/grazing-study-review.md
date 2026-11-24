# KF-025 grazing study candidate — independent critical review

**Decision: HOLD; do not integrate this candidate.** The false-zero correction is supported by actual numerical results, but the candidate introduces a measured discontinuity at an internal grid-cell boundary. Its ordinary-path rendering cost is also unresolved. Passing existing tests and selected host image comparisons does not override either finding. Live renderer/core source remains unchanged, and KF-025 remains open.

Review completed on 2026-11-24 by the reused `/root/w09_ios_critical_review` specialist. No additional reviewer was spawned. The reviewer inspected source, test/probe implementations, raw results and the frozen evidence manifest; the reviewer did not compile, benchmark, stage, commit or modify executable source. The author ran the one bounded continuity experiment requested during this review after root explicitly authorized it. This report is the reviewer's only written artifact for this task.

## Exact scope and evidence integrity

The candidate is an isolated archive of base **`3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`**, tree **`0ff9fa32a412534af0e11629e442f0a46a1176a0`**. It is not the live source-10 revision `5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`. Review covered the eight files below and the unchanged renderer, material, geometry, cancellation and packing consumers they call. Unrelated async-library differences between the archive and live source were excluded.

The [author report](grazing-study-report.md), [complete reconstructable patch](grazing-study-candidate.patch), and [manifest](grazing-study-manifest.json) preserve the held candidate. The reviewer independently checked all **77 manifest entries** comprising eight candidate source files, the patch/report, and 67 retained raw files against their byte lengths and SHA-256 values; there were no mismatches. The four modified preexisting live files still match their base bytes, and the four new candidate source files are absent from the live tree. This verifies that the experiment remains isolated; it is not an integration test.

| Reviewed candidate file | SHA-256 |
| --- | --- |
| `Sources/LightingCore/ReferenceStudy.swift` | `45c6d2345d1ca57981f62e1381d52b921aa4bfe9f4dc456b66f7140c039cb2fd` |
| `Sources/LightingCore/StudyAreaClipping.swift` | `83771339db2bd94d4df82ea843a9547edf03bdb5bc6919aca779c414725def51` |
| `App/StudyKernel.h` | `c3e1f6cf840465c17877cb27ab854444ed1214fab4e20b1d840dd56189f2c09a` |
| `Tests/LightingCoreTests/StudyComputeInputTests.swift` | `e6ee7a578480c9f54d371651a916f67130053145972c66e8c9eca2c38fac8fb0` |
| `Tests/LightingCoreTests/StudyGrazingTests.swift` | `d540d5168d251eb994879fc9a7ce256c51f228828d1094c1a8472f9d7fbb5a26` |
| `scripts/verify-kernel-host.cpp` | `5190602a1e16f76a2a2c59a1c998a012086b39a9dc650cc53759c37dcb9a1e2b` |
| `scripts/grazing-study-probe.swift` | `69368e0d1f5a1bda0ff34bd24d334102b400c63259ac4c7cba4de39da178eb45` |
| `scripts/verify-study-grazing.cpp` | `1181fcd830ec39d1eac8ab81e97b15128f63cf6885cbfa81e684a8648280f925` |

Frozen packet hashes independently verified: patch **`cf6d3737b9fa2e59b1eedb6fc502d5ffaf766924b6be0a41114fbce7f6712bcc`**; author report **`67534f6095d6722bde7118a797dc263ff0bb38ad113798f294ab587794269747`**; manifest **`c16fe9daa35bc7a18c7ab48345f758560227fd8e9a4392ad8c8770c889e48e5b`**.

## Finding 1 — confirmed internal-cell continuity regression

The candidate keeps one midpoint for a completely illuminated cell but uses triangle quadrature as soon as the cell is clipped. Those two quadrature rules need not converge to the same value as the clipped area approaches the full cell. The existing whole-emitter transition test covers a different boundary; it cannot establish continuity at each internal cell edge.

Review identified this concrete risk from the already observed broad-corner Double/Float32 difference. The author then ran exactly one three-cut experiment using the existing interactive fixture: a 1 m × 0.6 m rectangular emitter at the origin, a receiver at `(0, 0, 0.25)`, intensity 1,000 cd, and receiver normal proportional to `(1, 1, cut / 0.25)`. Only the cut parameter changed. The [Swift probe](grazing-study-raw/grazing-study-continuity.swift), [Float32 helper probe](grazing-study-raw/grazing-study-continuity.cpp) and [raw output](grazing-study-raw/grazing-study-continuity.log) are retained.

| Cut | Baseline Double lux | Candidate Double lux | Independent Simpson lux |
| --- | ---: | ---: | ---: |
| 0.5999999899999999 | 1.7651909651029574 | 1.9710135102369204 | 1.8821461933566823 |
| 0.6 | 1.7651906408809135 | 1.9710131637547668 | 1.8821458452128712 |
| 0.60000001 | 1.7651903166588767 | 1.8836090427411123 | 1.8821454970691125 |

Across the two adjacent cuts, the candidate changes by **0.0874044674958081 lx**, or **4.4344943556%** of its central value. The baseline changes by **6.484440806531211 × 10⁻⁷ lx**, and the independent reference changes by **6.962875698235393 × 10⁻⁷ lx**. The candidate's large step is therefore a measured new numerical regression, despite each of these candidate samples remaining within the declared 5% area-reference criterion. The experiment establishes a lighting-output discontinuity; it does not establish visible on-screen flicker or native GPU behavior.

All three Float32 helper inputs produce the same **1.8831355571746826 lx** value at this very small perturbation. That is finite-precision quantization of this particular probe, not proof that the Float32 implementation is continuous at other representable boundaries. At the central cut, Double and Float32 differ by about **4.46% relative to Double**. Their arbitrary-receiver lux results are separate inputs from the six original and eight strict tone-mapped image fixtures. Those image passes neither measure nor exclude this counterexample.

**Required disposition:** retain this three-cut result as a failing regression for the next numerical design. A future correction must make the transition consistent while retaining narrow-region positivity, correct area weights and existing visibility/material checks. Do not discard the counterexample, relabel it as a pass, or infer continuity from the current whole-face test. No replacement algorithm is approved by this review.

Continuity log SHA-256: **`0f67dce937ae7521bf128354eba3867f098a924661c178b94c3f0177508c89d3`**.

## Finding 2 — rendering cost and cancellation latency remain unresolved

The author made one bounded fully-lit fast-path attempt. It requires every rectangular source to be in both the shading and, when supplied, geometric hemispheres before restoring the old midpoint-only loop. Source inspection supports that condition; it does not establish an acceptable performance cost.

The [first CPU-clear paired sequence](grazing-study-raw/paired-before-fast-path/summary.json) showed area-frame median increases from about **7.0% to 35.1%**. The [final paired sequence](grazing-study-raw/paired/summary.json) showed about **13.6% to 61.1%** for area frames, while point-frame controls also changed substantially. Representative final medians were:

| Workload | Baseline ms | Candidate ms | Change |
| --- | ---: | ---: | ---: |
| Sphere, 3 area lights, width 72 | 22.6285 | 29.1740 | +28.9% |
| Sphere, 3 area lights, width 144 | 59.9094 | 96.5262 | +61.1% |
| Bust, 3 area lights, width 72 | 32.5487 | 47.2884 | +45.3% |
| Bust, 3 area lights, width 144 | 157.6058 | 179.0553 | +13.6% |
| Bust, 3 point lights, width 72 | 1.7876 | 5.2592 | +194.2% |

The report preserves every raw sample. These shared-host observations cannot reliably separate code overhead from run-to-run scheduling or other execution effects, and they do not demonstrate acceptable ordinary-path overhead. The [earlier overlapping run](grazing-study-raw/paired-load-overlap/SCOPE.md) is explicitly excluded because root's source-10 compilation/tests were active. No favorable run was substituted for the full history, and this review requested no repeated performance run.

There is also a definite work-count increase independent of timing noise. A partial cell can emit up to **nine** points with one clipping plane or **twelve** with shading and geometric planes. Each point still performs lighting/material work and, where applicable, a visibility query. `StudyLighting.sampleCount` and the benchmark's `lightSamplesPerSurface` continue to count prepared midpoint cells, not this receiver-dependent executed work. Comparing those fields alone would understate the candidate's cost. See the [candidate patch](grazing-study-candidate.patch) and [unchanged benchmark driver](grazing-study-raw/paired-benchmarks.py).

The shared cancellation scheduler still checks before at most every **eight pixel evaluations**, including background/unsupported pixels, in both CPU renderers. The render actor's cancellation/adoption policy is unchanged. The candidate can do more work within each of those pixels, however; an eight-pixel bound is not a fixed ray count or a wall-clock cancellation guarantee. No device frame-time, thermal, energy or Metal performance acceptance follows from these host measurements. The protected [performance contract](../../QUALITY.md) remains unchanged and unfulfilled by this experiment.

## Source checks with no new blocker found

These are source-review conclusions supported by the frozen patch and relevant focused tests, not claims of Apple SDK or device execution.

**Area weights and storage bounds.** Local cell coordinates cover a square of area four. A triangle's determinant magnitude divided by 24 gives its area divided by the cell area and by three equal quadrature points. Partial-region weights retain their actual area fraction; they are not renormalized to a whole cell's candela. Rectangle half-width/half-height divided by the grid count correctly supplies the local half-cell extents. One affine clipping plane produces at most five polygon vertices; two produce at most six. The CPU has two distinct eight-element buffers within a 16-element temporary allocation; only initialized vertices up to the returned count are read. The shared kernel's one-plane buffer has five entries. Both triangle loops guard empty/degenerate results. No concrete buffer-overrun or weight-normalization defect was found.

**Geometric hemisphere and visibility.** The CPU clips mannequin cells against both the shading and actual geometric hemisphere and retains the final geometric-normal check for every contribution. The analytic sphere and panel use the same geometric/shading normal and require only the one shader plane. The `allAreasFull` fast path checks the geometric hemisphere as well as the shading hemisphere. Every partial point is traced to its actual source position from the same offset shadow origin; it does not reuse the old midpoint's visibility or an infinite shadow ray. Unoccluded and visible lux remain distinct. Material evaluation receives the point's actual light direction. These paths are exercised by the focused visibility/hemisphere/scaling tests, but they do not resolve the continuity defect.

**Near-field, backface and material behavior.** The existing nearest-emitter-face guard runs before clipping or dark-cell rejection, and the per-point 5 cm guard remains in the contribution routine. Emitting-normal cosine, receiver cosine, candela scaling, blackbody XYZ, diffuse/GGX response and finite shadow-segment handling remain present. Skipping a wholly dark area does not bypass the up-front near-field rejection. The existing Float32 eligibility and CPU fallback policy were not modified. Source inspection found no new invalid-surface, material or occlusion bypass.

**Packed producer/consumer contract.** The three float4 rows per prepared sample and three per area are unchanged in size. Sample color `.w` now holds zero for non-area samples or a one-based area-record index; `parameters[5].w` holds the grid count. The changed values are renderer metadata, not a persisted scene/project format. `StudyComputeInput` generates them; `MetalStudyRenderer` uploads them without reinterpretation; `ReferenceStudy.metal` delegates to `kfStudyPixel`; both binary fixture writers serialize the new producer's rows. Host validation rejects obsolete/invalid grid and area-index metadata. Existing multi-area soft/translated fixtures and the mixed directional warm fixture exercise source-index transitions, while packing tests assert area/non-area encodings. No missed in-repository consumer or stale user-data migration requirement was found.

## What the tests establish, and what remains failed

The existing [photometry contract](../../QUALITY.md) permits at most 5% area-model error on declared reference cases. That threshold predates this candidate and is also present in the unchanged `ReferenceStudyTests`. The new 0.2% exploratory target is stricter and its failures must remain visible.

| Evidence | Observed result | Scope and limit |
| --- | --- | --- |
| [Baseline grazing probe](grazing-study-raw/baseline/grazing-regressions.log) | 16/16 fail exploratory 0.2%; 12 exact zeros | Actual old implementation, independent Simpson reference |
| [Candidate Double probe](grazing-study-raw/candidate/grazing-regressions.log) | 12 false zeros become positive; 13/16 meet 0.2%; all 16 below 5% | Retained failures: 4.7216%, 1.0796%, 0.5666%; no general convergence/continuity claim |
| [Portable Float32 probe](grazing-study-raw/candidate/grazing-float32.log) | 16 declared checks pass, with full-cell/scaling/dark controls | Direct `kfClipStudyCell`/`kfStudyIncident` calls; 10 µm cases have a separately disclosed 2% bound; this is not a native Metal dispatch or complete pixel-path test |
| [Final optimized XCTest run](grazing-study-raw/candidate/release/tests.log) | 259/259 pass: 251 existing plus 8 new methods | Standalone Swift 6.4.3 Linux build/runner, not a new Apple or SwiftPM Debug/Release gate |
| [Original host image fixtures](grazing-study-raw/candidate/kernel-parity.log) | 6/6 pass; maximum channel difference at most 1 | Shared C++ header execution; matching unsupported counts, including 84/84 near-field pixels |
| [Strict host image controls](grazing-study-raw/candidate/precision-parity.log) | 8/8 pass at unchanged maximum-channel-error 1 | Seven byte-exact; one one-channel delta; matching unsupported counts |
| [Additional zero-error exploration](grazing-study-raw/candidate/precision-byte-exact-exploratory.log) | One of eight fails | Preserved failure; the existing one-channel gate was not weakened |
| [Three-cut continuity probe](grazing-study-raw/grazing-study-continuity.log) | New 4.43449% Double jump confirmed | Measured numerical counterexample; no observed on-screen/native behavior |

The reviewer read the standalone [build/test driver](grazing-study-raw/build-release.py) and generated runner procedure, the eight new test methods, and the actual result logs. The final 259-test log hash is **`ab2581bbc1244d581c2fc2556ae02b8b556d4217947cb2a75d48eae99a5f9b88`**. Its green result predates discovery of the continuity counterexample and cannot certify that missing assertion.

The [initial new-test failure](grazing-study-raw/candidate/release/tests-initial.log) also remains preserved: a geometric-half-domain test assumed near-exact symmetry of finite triangle quadrature. The final test compares against the independent half-domain reference at the declared 0.2% narrow-region criterion and asserts each actual ray's positive geometric hemisphere. No preexisting assertion or protected tolerance was removed. This correction to a new test's premise does not authorize changing the separate continuity result.

## Acceptance before reconsidering integration

Preserve the held patch and all failures. The next scoped design must remove the reproduced internal-boundary jump while retaining the narrow positive-strip/corner behavior, actual area weights, geometric hemisphere, visibility and near-field contracts. Its tests must include this internal boundary in addition to the already tested whole-emitter boundary. Any performance assessment must distinguish prepared-cell metadata from executed quadrature work and establish the ordinary-path cost on a controlled comparison; these measurements do not supply that acceptance.

Actual Apple type checking/Metal compilation, shared-kernel execution on the native backend, and physical-device performance remain unverified for this candidate. Prior native successes at other revisions cannot be transferred to it. No rendering, photometry, performance, accessibility or release gate is promoted by this review. The supported outcome is the reproducible evidence package and a justified **HOLD**, with production renderer/core source preserved.
