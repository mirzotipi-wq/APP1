# Independent review: cancellation, performance and Float32 precision

## Decision and scope

The CPU cancellation change has a precise, useful work bound and measured improvement on the declared synchronous host probes. The reciprocal-direction BVH experiment was correctly rejected after the larger measurement sequence failed to establish a stable improvement. The Float32 sphere correction repairs a substantial far-camera defect, but its acceptance must include verified conservative CPU routing for the remaining cutoff-mask failures. Neither the six established parity fixtures nor the eight strict far-camera controls establishes correctness across the whole previously eligible Float32 domain.

This review inspected implementation, tests, raw JSON, raw parity logs, complete image bytes and the three experiment reports. It did not repeat benchmarks or rerun the precision corpus. One additional deterministic cancellation regression was necessary to resolve a specific boundary in the work-bound claim; only its four-test Debug suite was run. No production source was edited by this reviewer.

The experiment baseline was main `0fce248b4e61bace88002b40f6c56fddedb19c8a`, with independent working-tree changes in progress. The BVH experiment separately identifies its earlier base and exact source snapshots. Source hashes below identify the reviewed implementations; this report does not represent the entire concurrent worktree as an exact checkout of one commit.

| Work | Review disposition | Evidence limit |
| --- | --- | --- |
| CPU pixel cancellation | Accept the production checkpoint; correct the general claim to **at most eight pixel evaluations between polls** | Cooperative work bound; measured synchronous cancellation, not a hard time limit |
| Cached BVH reciprocals | Keep the candidate reverted | Shared-host measurements do not establish a stable whole-frame improvement |
| Stable Float32 sphere intersection | Strong targeted correction; retain strict controls and the complete diagnostic failures | Host execution of the shared kernel, not Metal execution |
| Float32 eligibility guard | Require the separate routing acceptance packet before declaring the cutoff issue contained | Implementation was present during review; its completed validation is outside this report |

## Cancellation: one important wording correction

`StudyPixelCancellation` starts with an immediate poll, resets its counter to eight following a false result, and decrements once for each pixel checkpoint. If an external cancellation request arrives immediately after that false result, the guarded pixel has not executed yet. That pixel and seven subsequent pixels can execute before the next callback observes cancellation. The precise general statement is therefore **at most eight pixel evaluations between polls**, including background and diagnostic pixels.

The original deterministic test uses a different trigger: it asks whether the number of already completed pixels has reached a threshold. Its fewer-than-eight result is correct for those completed-pixel boundaries. It cannot support a strict fewer-than-eight claim for all external request timings. The distinction was reported to the coordinating agent before any edit, then corrected under explicit authorization in the test wording and `render-cancellation.md`.

The added `testCancellationImmediatelyAfterFalsePollStopsAfterEightPixelEvaluations` sets the request after a callback returns false and before its guarded pixel executes. It verifies exactly eight completed evaluations, followed by cancellation on the second callback. It uses no thread timing, sleeps or wall-clock threshold. All four `StudyCancellationTests` passed in the follow-up Debug run; the original 19/19 Debug and 19/19 Release results remain separately attributed to their earlier three-test cancellation source. The additional regression has no separate Release result in this review.

Both renderer loops use the shared checkpoint before each pixel, and final checks still prevent publication after a cancellation observed at frame completion. Setup, lazy geometry initialization, one expensive pixel, host scheduling and asynchronous task delivery are not given a hard duration bound by this counter. A false final poll also cannot guarantee what happens after that poll; the evidence concerns observed cooperative cancellation, not atomic publication against an independently changing flag.

### What the actual timing records establish

The raw files contain nine cancellation probes per mode and implementation, at requested deadlines of 2, 15 and 50 ms: 54 probes in total. They run after a complete render warms code and geometry. All return cancellation. Recomputed maxima from the raw records match the report:

| Mode | Before deadline-to-return maximum, ms | After deadline-to-return maximum, ms | After maximum interval in the first complete render, ms |
| --- | ---: | ---: | ---: |
| Mannequin interactive, 144 × 96 | 51.111 | 1.713 | 29.471 |
| Sphere interactive, 192 × 128 | 5.186 | 0.234 | 1.957 |
| Sphere reference, 96 × 64 | 45.068 | 3.466 | 25.790 |

The larger complete-render intervals are retained, not filtered away. The experiment does not isolate initialization from scheduling in each outlier; attributing every large interval to either cause would overstate the data. The warm probe maxima are observations for a declared twelve-light close-up, not universal limits. Full-frame durations are also retained, but do not establish a throughput improvement.

The reviewer compared all three baseline and corrected RGBA files directly: every byte agrees, and every image has zero unsupported pixels. The original raw logs contain the reported 19-test success totals. These checks support unchanged image output for the measured fixtures, not all possible scenes.

## BVH reciprocal cache: rejection is supported

The rejected candidate cached reciprocal ray directions and parallel-axis flags once per traversal. It did not change triangle geometry, the oracle, source sampling or finite segment limits. Initial development timing suggested a 19% mannequin improvement, but the canonical baseline → candidate → candidate → baseline sequence did not reproduce it.

Independent aggregation of the four raw JSON reports confirms 14 samples per implementation and workload. For the 144 × 96 mannequin with three area lights, nearest-rank p50 moves from 146.460 to 175.280 ms. The 72 × 48 version moves from 41.758 to 36.322 ms. These mixed results, plus the large excursions in the unchanged sphere control, do not support a reliable whole-frame speedup or an isolated causal slowdown. With only fourteen observations, nearest-rank p95 is the maximum; it is not a well-resolved tail estimate.

The raw reports contain 224 measured complete frames with zero unsupported pixels and 48 successful cancellation probes. Direct comparison of the eight stored baseline/candidate image pairs confirms byte equality. The experiment report separately retains the 17/17 Debug and Release correctness results. Correctness did not justify accepting an optimization whose benefit was unproven.

The current `PortraitHeadMesh.swift` hash matches the documented restored baseline, preserving the independently verified silhouette tie correction and removing the reciprocal cache. The report correctly explains that the JSON base revision alone is not an exact source identifier because both snapshots include that then-pending tie correction. No claim should reuse the initial 19% result as an accepted gain.

## Float32: strong correction with a remaining routing requirement

The relative-distance limit is 20 m from the subject for the camera and lights. It is not a limit on absolute world coordinates. The input packer subtracts the subject in Double before conversion, so large valid world translations remain meaningful controls.

The old sphere discriminant subtracts two large squared terms to recover a small radius-scale result. The closest-approach formulation avoids that subtraction and accounts for `dot(d,d)` rather than assuming a Float32 normalized direction is exactly unit length. Source inspection confirms that the Double oracle and the physical cutoff were not relaxed.

The actual host logs show:

- The six established runtime fixtures pass before and after. The corrected maximum RGB channel difference is one, and the near-field invalid count remains 84/84.
- With the explicit maximum-channel-error criterion of one, the eight ordinary far-camera/translation controls change from **0/8 passing to 8/8 passing**. All eight corrected RGB outputs have zero error. Their invalid counts match; some controls intentionally have nonzero invalid counts.
- Under the original aggregate criteria, the complete diagnostic corpus changes from **29/33 passing to 28/33 passing**. The five corrected failures remain visible in the raw log and the full report table.

The aggregate criterion previously allowed a maximum channel error of 187 in an ordinary far-camera fixture because the affected sphere occupied a small portion of the image. The stricter controls are therefore material regression evidence, not redundant copies of the six established fixtures. Tangent cases still have boundary-pixel differences; exact Float32/Double silhouette agreement has not been established.

The five remaining corrected failures all report Float32 invalid count zero where Double reports one: camera 1 m at cutoff offsets −1e−8 and zero, and camera 20 m at offsets −1e−6, −1e−8 and zero. Changing which side disagrees is expected when discontinuous classifications consume quantized inputs, but it does not make the failures acceptable. A kernel-only acceptance claim would leave an observed supported-domain mismatch unresolved.

### Conditions for accepting the eligibility work

The separately owned `StudyFloat32Eligibility` implementation introduces a one-millimetre engineering margin around discontinuous surface/source cutoffs while retaining relative-distance limits. Its sphere separation and conservative visible-panel bounds are an appropriate routing approach. The margin is an engineering choice, not a proved Float32 error bound across every GPU and scene.

Before closing this issue, the routing evidence must show that the retained ambiguous fixtures, including all five actual failures and the full fourteen-case cutoff family, use the Double CPU path. It must also demonstrate the intended ordinary eligible controls, translated/rotated cases and finite-panel behavior. Public renderer entry points must enforce the guard; any raw-kernel path used to preserve established parity fixtures must remain internal to validation. Engine routing should recover to Metal for a subsequent eligible scene rather than permanently disabling it after one CPU-routed scene.

This report does not claim those conditions have already passed. Their tests and implementation changes were being completed by the separate guard owner during review. Native integration execution remains a distinct requirement even after portable routing tests pass.

## Reviewed records and reproducibility

The authoritative experiment detail is retained in `render-cancellation.md`, `bvh-optimization.md` and `float32-boundary.md` in this directory. This review recomputed selected statistics and compared existing outputs; it created no new performance samples. Relevant inspected source fingerprints:

| File | SHA-256 at review |
| --- | --- |
| `Sources/LightingCore/PortraitStudy.swift` | `74c4a484b6aee550808110db98b81f4ef725b62fc0b38a542dc35170f5dc54f6` |
| `Sources/LightingCore/ReferenceStudy.swift` | `da3f54a8dab3683b7f9cbbdadd924739a332fb6d4405e6c78c12dc0d512a42b9` |
| Restored `Sources/LightingCore/PortraitHeadMesh.swift` | `2d43056a7eab9371126188e6b161000ca3696e812eca51f69945f19d2cf5740f` |
| `App/StudyKernel.h` | `ec67e54f98698741c15fddf543967bdeb1596aa183b488e7414cde4b397e33f7` |
| `scripts/verify-kernel-host.cpp` | `02a5f31856ad5ffbd8299da25a348b3e92ff9608f7ca6b39b2d5b9bec52d2e01` |
| Updated `Tests/LightingCoreTests/StudyCancellationTests.swift` | `9814bc07ca04ecd34d4046dc59a87990305f71a581dca48375aa6c8fcc5c4806` |

The added regression log is `verification/w08-cancellation/review-tests-debug.log` under the session scratch root, SHA-256 `82277329fffe8109d634e71c79570c77352a17f646e95d4b848f967a86f42663`. The source reports retain the original log and raw-output hashes; those hashes were preserved rather than rewritten to imply a new run.

No Apple SDK or actual Metal execution was available to this review. Host kernel parity, portable Swift tests and synchronous CPU measurements do not establish native shader compilation, UI responsiveness, device FPS, battery use, thermal behavior or physical photographic accuracy. No such release gate is promoted here.
