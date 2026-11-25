# M02 code revalidation — 25 November 2026

M02 remains accepted under `m02-m03-code-v2`. Current source is `5d8b065ec935faa2d85671725cd9b20adc1b035f`; its [core job](https://github.com/mirzotipi-wq/APP1/actions/runs/45720754048/job/139579558459) passed. M03 remains separate and unaccepted while its required native/UI checks run.

## Evidence by gate

| Gate | Actual evidence | Result |
|---|---|---|
| Photometry | 357 Debug and 357 Release tests passed at 5d8, retaining analytic point/cosine, declared area-reference, invalid-input, transform, color and range fixtures and their original tolerances. | Pass |
| Rendering | Twelve deterministic image/scene fixtures produced zero unsupported pixels. Every original image byte matches the already reviewed C855 matrix. All six CPU/shared-Float32 cases and eight strict precision cases passed. Actual native Metal execution is separately bound below. | Pass |
| Performance | Existing cache/cancellation/domain regressions passed in both configurations. The optimized benchmark executed eight frame workloads, twelve cancellation probes and four visibility workloads, with one warm-up and seven samples per timed workload. All cancellation probes observed cancellation. | Pass |

The [core receipt](validation/source-5d8b065/ci-core/receipt.json), original artifact archives, raw test/kernel/precision logs, complete scene JSON and image outputs, [image comparison](validation/source-5d8b065/ci-core/render-comparison.json), and [visual review binding](validation/source-5d8b065/ci-core/visual-review.json) are retained together. Fixtures and thresholds were not changed to produce these results.

Shared-Float32 parity had maximum channel error **1**, largest mean channel error **0.0000542535**, no channels above error 4, and zero invalid-mask mismatches. The near-field fixture intentionally returned **84 unsupported pixels in both paths**. All eight precision cases had maximum channel error **0**, within the unchanged maximum of 1, with matching intentionally unsupported masks. Those unsupported boundary fixtures are distinct from the twelve fully supported rendered scenes.

All three actual Metal methods passed at exact C855: initial parity cancellation/retry, available-device CPU/Metal comparison, and near-field routing without permanent downgrade. [Raw native logs and exact accounting](validation/source-c85544f/native-ui/native/receipt.json) preserve their execution. [Exact Git blob comparison](validation/source-5d8b065/source-equivalence.json) proves the renderer, shared kernel, core fixtures, native Metal tests, workflow and project inputs unchanged at 5d8. This is explicit source-equivalent carry-forward, not a claim that the queued 5d8 native job has executed. The unrelated C855 text-field test failure is retained and is not relabeled as a full native pass.

Required deterministic limits remain at most **four completed frames**, **256 KiB RGBA plus 64 KiB validity masks**, mannequin width **144 pixels**, and at most **eight further pixel evaluations** after the specified external cancellation. Cancelled or failed work cannot publish or enter the cache. Passing the regression suite establishes these tested code contracts; timing samples are diagnostic.

## Actual host benchmark

Ubuntu 24.04.5 LTS, Linux x86_64, Swift 6.4.2, Python 3.12.3, **AMD EPYC 9V74 80-Core Processor**, four active/reported processors. The script used `-O`, fixed fixtures, one warm-up and seven measured samples; raw samples and workload definitions remain in [study-benchmark.json](validation/source-5d8b065/ci-core/study-benchmark.json).

| Frame workload | p50 milliseconds | p95 milliseconds |
|---|---:|---:|
| sphere-point3-72 | 0.623473 | 0.648230 |
| sphere-point3-144 | 2.408173 | 2.438078 |
| sphere-area3-72 | 17.391281 | 17.435117 |
| sphere-area3-144 | 69.405856 | 69.467398 |
| bust-point3-72 | 1.724910 | 1.774785 |
| bust-point3-144 | 6.504232 | 6.510151 |
| bust-area3-72 | 38.050171 | 38.108939 |
| bust-area3-144 | 149.222289 | 149.317421 |

These are short-run host measurements with no timing acceptance threshold. They establish no physical iPhone frame rate, thermal behavior or resident-memory result. External photographic calibration and human/device validation were removed from M02/M03 by the owner's revised scope; they were not performed or reported as passes. Later milestones retain their separate scope.
