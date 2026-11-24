# BVH reciprocal-direction experiment — 2026-11-24

## Decision

**Rejected for integration: no stable whole-frame improvement established on the shared host.** The candidate cached three reciprocal ray directions and a near-parallel-axis mask once per BVH traversal. It replaced per-node slab divisions with multiplication; bounds padding, the near-parallel threshold, triangle intersections, finite segment limits, mesh topology, sampling, and the preceding silhouette tie correction were preserved.

An initial development run suggested a 19% reduction for the 144×96 mannequin with three area lights (151.810→123.036 ms median). That was not confirmed by the controlled before/after/after/before sequence: the combined nearest-rank medians were **146.460→175.280 ms**, a 19.7% increase. The unchanged sphere-area control ranged from 54.967 to 137.184 ms across the same batches, so host variability materially confounded attribution. The data do not support claiming either a reliable speedup or an isolated causal slowdown. The candidate was reverted; the independently verified silhouette tie correction remains.

## Correctness and provenance

- All eight complete raw RGBA files were compared byte for byte between the baseline and candidate; **8/8 identical**. Capturing these bytes used scratch-only copies of the harness, writing each warm-up image after its timing interval. The timed benchmark binaries used the unchanged committed harness source.
- All 224 canonical measured complete renders matched their own warm-up exactly and reported zero unsupported pixels. FNV fingerprints also agree across all four runs; those noncryptographic fingerprints are supplementary to the direct byte comparison.
- The candidate passed **17/17 targeted tests in Debug and Release**: six independent BVH-oracle/regression tests, seven existing portrait tests, and four photometry invariant tests. These passed before the candidate was rejected on performance evidence.
- Reversion restored exactly the handed-off silhouette-fix source hash. No post-reversion rerun is needed to establish source identity; that exact source already passed the oracle specialist’s Debug/Release checks.

| Input | SHA-256 |
|---|---|
| Baseline and restored `PortraitHeadMesh.swift` | `2d43056a7eab9371126188e6b161000ca3696e812eca51f69945f19d2cf5740f` |
| Rejected cached-direction candidate | `1974d4db8f4cb187002fea376a6b10f87d5a74bd4d7ad5766b9bd152625f5916` |
| Unmodified `scripts/benchmark-study.swift` | `e3fbbcea0e5b02bfb105298045b69d1727e26f7104765904d715484c471a3a9f` |
| Candidate Debug test log | `f56ca862de2a2b183f69502bc3a637d491b58a025a34fe750302a44e98513c89` |
| Candidate Release test log | `284f74d91042aeaf712d1df9960fd2d533d3afcd08e99294113302d317e62abb` |

The JSON `sourceRevision` field names base commit `e45a1c8b0c1b01468f9f9f52812e118db18928fa`. **Neither benchmark source set is an exact checkout of that commit**: both include the pending silhouette tie correction, and the candidate additionally includes the reciprocal cache. The source hashes above distinguish the tested implementations. Independent frozen source copies prevented later shared-worktree edits from entering the benchmark.

Environment: Debian 13, x86_64, exposed AMD EPYC 9V74 CPU with nine logical processors, Swift 6.4.3, `swiftc -O`. No CPU affinity or frequency control was available. Root held its planned large compile during the final measurement interval, but the shared environment could not be made exclusive. These are CPU diagnostics, not iPhone, GPU, FPS, energy or thermal results. No performance release gate is promoted.

## Final comparison

There were two complete runs per implementation, seven timed samples per workload per run after one warm-up. The execution order was baseline → candidate → candidate → baseline. The table pools all 14 samples per workload and implementation without excluding outliers. p50 and p95 use nearest rank; p95 with n=14 is the maximum sample. Positive change is slower.

| Workload | Baseline p50 ms | Candidate p50 ms | Change | Baseline p95 ms | Candidate p95 ms |
|---|---:|---:|---:|---:|---:|
| sphere-point3-72 | 0.558 | 0.559 | +0.1% | 1.287 | 6.726 |
| sphere-point3-144 | 2.395 | 2.239 | -6.5% | 5.292 | 2.966 |
| sphere-area3-72 | 14.566 | 14.241 | -2.2% | 25.045 | 23.802 |
| sphere-area3-144 | 61.745 | 65.466 | +6.0% | 137.184 | 79.462 |
| bust-point3-72 | 1.776 | 2.039 | +14.8% | 2.119 | 2.485 |
| bust-point3-144 | 7.788 | 7.603 | -2.4% | 21.001 | 15.272 |
| bust-area3-72 | 41.758 | 36.322 | -13.0% | 66.184 | 47.877 |
| bust-area3-144 | 146.460 | 175.280 | +19.7% | 191.450 | 231.547 |

## Raw frame measurements

All values are milliseconds, in execution order. Each row retains every sample, including the large timing excursions.

| Run | Workload | Seven measured samples |
|---|---|---|
| 1: before | sphere-point3-72 | 0.612268, 0.546951, 0.561122, 0.545498, 0.610145, 0.576624, 0.544157 |
| 1: before | sphere-point3-144 | 2.394730, 2.212180, 2.492776, 2.434139, 2.572985, 2.241503, 2.513867 |
| 1: before | sphere-area3-72 | 13.796694, 13.894999, 14.019474, 14.566064, 13.815331, 14.476421, 13.881389 |
| 1: before | sphere-area3-144 | 55.856467, 55.590572, 57.559641, 55.089309, 56.321906, 54.966787, 61.745236 |
| 1: before | bust-point3-72 | 1.820559, 1.776434, 1.744556, 1.742854, 1.748332, 1.706219, 1.731217 |
| 1: before | bust-point3-144 | 16.698755, 6.700844, 6.798599, 6.896645, 6.734794, 6.842253, 6.784418 |
| 1: before | bust-area3-72 | 41.758296, 31.228906, 33.986975, 66.183736, 41.066990, 62.724627, 54.773190 |
| 1: before | bust-area3-144 | 139.104579, 188.270906, 164.238369, 191.449553, 178.507417, 147.097206, 164.996483 |
| 2: after | sphere-point3-72 | 0.643805, 0.597706, 0.554652, 0.584376, 0.542023, 1.053161, 0.546951 |
| 2: after | sphere-point3-144 | 2.912608, 2.146302, 2.172251, 2.212640, 2.279289, 2.463381, 2.379468 |
| 2: after | sphere-area3-72 | 14.932137, 14.539213, 13.856803, 14.048336, 13.856091, 14.240622, 14.349283 |
| 2: after | sphere-area3-144 | 72.085590, 65.263262, 56.888756, 57.773387, 59.607176, 62.464202, 66.054163 |
| 2: after | bust-point3-72 | 1.739749, 1.616336, 1.723755, 1.678869, 1.690175, 1.817164, 2.039113 |
| 2: after | bust-point3-144 | 6.306159, 6.382191, 7.603282, 6.268062, 6.617360, 6.905127, 6.212741 |
| 2: after | bust-area3-72 | 30.482109, 37.363450, 31.433299, 29.250083, 30.947784, 41.679839, 36.601601 |
| 2: after | bust-area3-144 | 175.280007, 142.913526, 129.634933, 134.185263, 149.797019, 132.909031, 131.577508 |
| 3: after | sphere-point3-72 | 0.609573, 0.551277, 0.564697, 0.547892, 0.558517, 0.557005, 6.725731 |
| 3: after | sphere-point3-144 | 2.966288, 2.239690, 2.438114, 2.239250, 2.182886, 2.126954, 2.147774 |
| 3: after | sphere-area3-72 | 14.395741, 14.626423, 13.662214, 23.802106, 13.604689, 14.068176, 14.478194 |
| 3: after | sphere-area3-144 | 55.575500, 65.466468, 70.393644, 74.337624, 79.461902, 72.994253, 69.878384 |
| 3: after | bust-point3-72 | 2.398266, 2.441078, 2.484783, 2.416172, 2.303375, 2.409061, 2.399768 |
| 3: after | bust-point3-144 | 9.161202, 9.103405, 9.393376, 15.271731, 9.422018, 9.554305, 9.401989 |
| 3: after | bust-area3-72 | 36.255618, 45.415939, 45.986214, 47.877077, 36.321617, 39.514419, 28.881436 |
| 3: after | bust-area3-144 | 186.604469, 201.337806, 194.553251, 179.300758, 231.546662, 179.061865, 198.354585 |
| 4: before | sphere-point3-72 | 0.585508, 0.547201, 0.557697, 1.287188, 0.560211, 0.542093, 0.553621 |
| 4: before | sphere-point3-144 | 2.192740, 2.194112, 2.145421, 2.556239, 5.291925, 2.243746, 2.657159 |
| 4: before | sphere-area3-72 | 24.915687, 16.685536, 14.618461, 19.522381, 19.809398, 20.866363, 25.044618 |
| 4: before | sphere-area3-144 | 124.316215, 131.376992, 137.184042, 128.235165, 128.320182, 62.806689, 66.036208 |
| 4: before | bust-point3-72 | 2.118901, 1.882490, 1.856011, 1.775863, 1.844554, 2.016229, 1.754812 |
| 4: before | bust-point3-144 | 13.375749, 11.756789, 15.875135, 18.118740, 7.788406, 18.817796, 21.001303 |
| 4: before | bust-area3-72 | 43.853031, 46.837816, 36.105491, 31.893351, 55.145031, 49.661592, 41.091106 |
| 4: before | bust-area3-144 | 151.871861, 124.747921, 132.043561, 139.520175, 146.459947, 144.410169, 131.830971 |

## Receiver microbenchmark

Same 34 actual mannequin receivers and 1,000 evaluations per sample as the baseline harness. Visibility-disabled measurements act as a control; visibility-enabled measurements include other analytic geometry and material work, so they are not an isolated BVH instruction profile.

| Run | Workload | Visibility | Seven measured milliseconds |
|---|---|---|---|
| 1: before | bust-point3-receivers | False | 0.100329, 0.099969, 0.312183, 0.099908, 0.100079, 0.122992, 0.099367 |
| 1: before | bust-point3-receivers | True | 0.386563, 0.374626, 0.427103, 0.412862, 0.479571, 0.416878, 0.372933 |
| 1: before | bust-area3-receivers | False | 5.569737, 5.072249, 5.007584, 5.053561, 5.056536, 5.253248, 5.277574 |
| 1: before | bust-area3-receivers | True | 26.805078, 25.894017, 27.746112, 29.291785, 24.551768, 24.725114, 27.322816 |
| 2: after | bust-point3-receivers | False | 0.113769, 0.097144, 0.097134, 0.097174, 0.101571, 0.147048, 0.098045 |
| 2: after | bust-point3-receivers | True | 0.350600, 0.476076, 0.350239, 0.351721, 0.373233, 0.350520, 0.350099 |
| 2: after | bust-area3-receivers | False | 5.177546, 4.986923, 5.398233, 5.125459, 5.119950, 5.030688, 5.109965 |
| 2: after | bust-area3-receivers | True | 22.481128, 21.705749, 21.029086, 31.311770, 22.956783, 21.525051, 20.971671 |
| 3: after | bust-point3-receivers | False | 0.098726, 0.098506, 0.125046, 0.098486, 0.112076, 0.097966, 0.161900 |
| 3: after | bust-point3-receivers | True | 0.371540, 0.350500, 0.356388, 0.568433, 0.349869, 0.364680, 0.349037 |
| 3: after | bust-area3-receivers | False | 5.896961, 4.961005, 5.058689, 5.008606, 5.026421, 4.975817, 5.502347 |
| 3: after | bust-area3-receivers | True | 34.383713, 22.531572, 29.045509, 37.888128, 29.092338, 52.861105, 46.986697 |
| 4: before | bust-point3-receivers | False | 0.097675, 0.110654, 0.097966, 0.098115, 0.099318, 0.097925, 0.098025 |
| 4: before | bust-point3-receivers | True | 0.373414, 0.371741, 0.384170, 0.371721, 0.389838, 0.392682, 0.371781 |
| 4: before | bust-area3-receivers | False | 5.037208, 4.978050, 5.133981, 5.485843, 5.167711, 5.343041, 5.093560 |
| 4: before | bust-area3-receivers | True | 34.719040, 36.324160, 32.986611, 30.718920, 35.738311, 34.177978, 25.267608 |

## Output equality

| Workload | Raw RGBA bytes | SHA-256 of both files |
|---|---:|---|
| bust-area3-144 | 55296 | `07dc5703644cb791e7706335b9d981ef7de5821effde412128075fe01c990cad` |
| bust-area3-72 | 13824 | `deed58fa6dce770da19175fe683d7bdb75ca5ff9e2e8cdb8665d59b272bf8c4e` |
| bust-point3-144 | 55296 | `3a404d9d5186463f4cad9a19143b187385e9e5799cf68657d4183d4b90c3c80c` |
| bust-point3-72 | 13824 | `fe0a1fad2692e42a6b3e62905a5fa220451a0ff8290c97f185699cca46133e12` |
| sphere-area3-144 | 55296 | `e3adadddfbd6d4a1fb25e1b72fe2d7c785f67db050ddfe064fd8045844086363` |
| sphere-area3-72 | 13824 | `e73248114e89355641b54986bda1c339843d1f8b9dbc84c43c9f7c7ea6e3daa5` |
| sphere-point3-144 | 55296 | `bc25794e861ec02fd5ff8969940df974d9d2b694cd8b35ff396f5ba3dc5d209f` |
| sphere-point3-72 | 13824 | `78ae4c6c6acdcb4ba2ab12505d1fdbdfbeb81a2618ce8dc67581dea02d8e727f` |

## Cancellation checks

All 48 canonical probes (12 per run) returned the expected cancellation error. These use synchronous monotonic-time callback checks, not UI task delivery.

| Run | Largest requested-deadline-to-return ms |
|---|---:|
| 1: before | 1.726993 |
| 2: after | 5.262965 |
| 3: after | 4.876196 |
| 4: before | 8.804264 |

## Reproduction and retained records

Build an exact source copy for each implementation before changing the shared worktree:

```sh
swiftc -O before/*.swift -o before-benchmark
swiftc -O after/*.swift -o after-benchmark
before-benchmark --samples 7 --revision <base-sha> > canonical-1-before.json
after-benchmark --samples 7 --revision <base-sha> > canonical-2-after.json
after-benchmark --samples 7 --revision <base-sha> > canonical-3-after.json
before-benchmark --samples 7 --revision <base-sha> > canonical-4-before.json
swift test --jobs 2 --filter 'PortraitHeadMeshTests|PortraitStudyTests|PhotometryInvariantTests'
swift test -c release --jobs 2 --filter 'PortraitHeadMeshTests|PortraitStudyTests|PhotometryInvariantTests'
```

`before/` and `after/` each contained all `Sources/LightingCore/*.swift` inputs plus the unchanged benchmark harness. The rejected candidate added a `BoundsRay` containing the original origin, three reciprocals (`1/d` only when `abs(d) >= 1e-14`), and a three-bit parallel mask. Both `hit` and `occludes` constructed this value once; every box used the cached reciprocals with the original `1e-10` bounds padding. Restoring the baseline file removes only that experiment.

The source copies, unmodified and image-capture executables, raw RGBA files and full JSON reports were generated under `/workspace/scratch/73dcd6a65726/verification/bvh-optimization/`. This repository report preserves all canonical frame and receiver samples plus file fingerprints; it does not depend on those transient binaries to communicate the result.

| Raw report | SHA-256 |
|---|---|
| `canonical-1-before.json` | `bcdeaa5a4cb670e45b19a3b230163413b0bb3f9e8bfc67d00cc9976f262a1cff` |
| `canonical-2-after.json` | `e3d3323bac4a09a3933cbc4a726662442123371d8050a73de5878f7832d98be8` |
| `canonical-3-after.json` | `155cd8a106de967f8b511945410ede2cb204fa423271479b7d3522206874634e` |
| `canonical-4-before.json` | `fafaea8107b10e0ade0e9f91399aeec2192ffa638b3c2056d732bd152948c1b3` |

## Next useful experiment

Use an exclusive physical device or controlled runner and a paired per-ray BVH microbenchmark before retrying this arithmetic change. Measure allocation, recursion and child ordering as well as division cost; the previous visibility toggle identifies the broader path, not a proven dominant instruction. Preserve the independent oracle and full byte comparisons as acceptance checks. Do not claim the original preliminary speedup.
