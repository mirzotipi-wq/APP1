# M02 code acceptance revalidated

Contract: [m02-m03-code-v2](../../acceptance/m02-m03-code.md). Tested source: `75e827f2ee3f99798d619aff62f3a5188b509428`. [Workflow 45751931160](https://github.com/mirzotipi-wq/APP1/actions/runs/45751931160). This record completes current M02 revalidation before the remaining M03 UI acceptance.

## Gate decisions

| Gate | Current evidence | Decision |
|---|---|---|
| Photometry | 359 Debug and 359 Release portable tests on Linux, plus 359 portable tests on macOS. Existing analytic/numerical, units, transform, geometry, invalid-input, color and photometric invariant cases passed under the unchanged 1% point/cosine and 5% area-reference acceptance limits. | Pass |
| Rendering | All 12 actual synthetic image fixtures rendered with zero unsupported pixels; every PPM SHA-256 equals the retained, visually reviewed matrix. All six CPU/shared-Float32 parity cases and all eight strict precision cases passed. Actual native Metal execution also passed. | Pass |
| Performance | The core and native suites passed the bounded cache, cancellation, sample-budget, mannequin-width and backend-routing regressions. The optimized benchmark completed all eight frames, twelve cancellation probes and four visibility workloads, retaining one warm-up and seven measured samples per workload. | Pass |

The accepted implementation and supported approximation boundaries remain described in the [original M02 acceptance](../m02-m03-code-2026-11-25/m02-acceptance.md) and the contract. The four-frame cache, 256 KiB RGBA plus 64 KiB validity-mask bounds, maximum 144-pixel mannequin width, and eight-pixel external-cancellation bound were retained. No fixture, tolerance, required method or input bound was relaxed to obtain this result.

## Original images and numeric comparisons

The current image names are soft, hard, warm, bust-soft, bust-hard, bust-side, key-only-hard, fill-only-soft, bust-rim-only, bust-roll-90, exposure-minus-two and white-balance-3200. The [current core summary](validation/source-75e827f/ci-core/summary.json) records each configuration size, unsupported count and SHA-256 emitted over its freshly rendered PPM.

The actual image/scene outputs remain in the current core CI artifact. The identical reviewed image set is also retained in the [M02 renders directory](../m02-m03-code-2026-11-25/renders/). Current hashes were compared with the [5d8 original image comparison](../m03-final-2026-11-25/validation/source-5d8b065/ci-core/render-comparison.json), whose [actual visual review](../m03-final-2026-11-25/validation/source-5d8b065/ci-core/visual-review.json) therefore applies without regenerating or substituting an image.

The six shared-Float32 cases have maximum channel error 1, maximum mean error 0.0000542535, zero channels with error greater than 4, and exactly matching invalid masks. The near-field parity case deliberately has 84 unsupported pixels in both implementations; it is separate from the twelve zero-unsupported image fixtures. All eight strict precision cases have maximum channel error 0 and exactly matching invalid masks, including their declared unsupported positions.

## Native integration and actual Metal

[Native job 139682754688](https://github.com/mirzotipi-wq/APP1/actions/runs/45751931160/job/139682754688) passed all 134 expected native methods, each exactly once from start to pass, with no missing, unexpected, duplicated, failed or skipped method. Both unsigned Debug and Release simulator builds and finalized XCTest export succeeded. The [native receipt](validation/source-75e827f/native/verification.json) and full log retain the inventory.

These three methods actually exercised Metal and passed:

- `StudyRendererTests.testCancelledInitialParityValidationCanRetryMetalOnSameEngine`
- `StudyRendererTests.testMetalMatchesCPUOnAvailableDevice`
- `StudyRendererTests.testNearFieldRoutingDoesNotPermanentlyDowngradeValidatedMetal`

The portable shared-kernel harness is reported separately from those Apple runtime checks. The native host was macOS 26.6.1 / Xcode 26.6 / Apple Swift 6.3.3, x86_64, with the iOS 26.5 simulator SDK. Its preparatory simulator warm-up reported a recovery-preflight timeout; the later actual test command, exact accounting and finalized result export succeeded. The diagnostic timeout remains in the raw log and is not renamed a successful preparation.

## Optimized host benchmark

The benchmark ran on Ubuntu 24.04.5, Swift 6.4.2, x86_64 Intel Xeon 6975P-C. Compilation used `swiftc -O`; the measured sample count was seven after one warm-up. The [raw benchmark report](validation/source-75e827f/ci-core/benchmark-from-ci.json) retains all samples, deterministic image checks, twelve observed cancellations and four visibility workloads.

| Frame workload | p50 milliseconds | p95 milliseconds |
|---|---:|---:|
| sphere-point3-72 | 0.522659 | 0.539097 |
| sphere-point3-144 | 2.008561 | 2.043645 |
| sphere-area3-72 | 13.194632 | 13.278828 |
| sphere-area3-144 | 52.417967 | 52.590741 |
| bust-point3-72 | 1.488863 | 1.526474 |
| bust-point3-144 | 5.449021 | 5.524732 |
| bust-area3-72 | 31.049518 | 31.707172 |
| bust-area3-144 | 122.178125 | 122.951640 |

These timings are host diagnostics. No physical-device frame-rate, thermal, resident-memory or photographic-calibration result is claimed. External requirements removed by the owner remain outside M02/M03 acceptance, as recorded in the contract.

## Provenance and independent checks

The [190 non-documentation blob inventory](validation/source-75e827f/source-manifest.json) ties the application, resources, tests, scripts and workflows to the tested source. Documentation-only integration preserves those inputs. Worker 058 independently reconciled all 359 methods in both Linux configurations; worker 059 independently reconciled the numeric, benchmark and persistence payloads. Their reports are retained in the worker ledger. Source reviews do not count as runtime execution.

M03 requires its own complete editing, library, accessibility and persistence workflows. M02 acceptance does not promote unfinished M03 UI checks or start M04.
