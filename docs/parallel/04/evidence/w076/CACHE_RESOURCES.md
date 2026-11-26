# Observed CPU cache payloads and lifetime boundaries

## Provenance and interpretation

These are **OBSERVED** readings from [native job 140012314020](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002/job/140012314020), run 45848953002, tested source `240000fd3f8cb75273eb279be9dcc7f204a5b29f`. They were emitted by Debug XCTest, using the real CPU renderers and `StudyRenderEngine.cacheUsage`. Release only built the app. The pinned native test blob is `6e811837c87ff3a8a0d8c87c4b0f877c752aae89`; input source7 preserves these methods and appends four outside this run.

Raw native evidence is blob `48500c2b0d1ef8ed6ac2bae8e0a12e4f7e07614d`, integrated at [wave06-native-140012314020.log](../ci/wave06-native-140012314020.log). The original 19 emission lines are also retained in [observed-resource-lines.log](observed-resource-lines.log). [cache-resources.json](cache-resources.json) preserves their raw order, timestamps, exact arrays and containing methods. Their payload objects match receipt blob `006f0a8f6546adb58e09b9a3942f3d624a842ac3` exactly: 15 per-request rows and four summary rows.

RGBA and mask values are retained payload **lengths in bytes**. Mask bytes are one byte per pixel, not a count of unsupported pixels. Dimensions come from the test's returned-frame array; the helper compares its lengths and count with actual actor counters. They are not direct cache-entry enumeration. Subsequent hit and cancelled-cold-render probes check retained identities and eviction. Caller-held images, transient copies, allocation capacities, process RSS and driver resources are excluded.

## All 19 raw observations

Each row is observed; summary rows repeat the final state without an additional render. Log lines are one-based in the retained raw native log. Dimension entries mean frame count × (width × height).

| Fixture | Kind | Cache count | RGBA bytes | Mask bytes | Returned-image dimensions for cross-check | Log line |
|---|---|---:|---:|---:|---|---:|
| maximum-bust-step-1 | per-request | 1 | 55,296 | 13,824 | 1 × (144 × 96) | 5550 |
| maximum-bust-step-2 | per-request | 2 | 110,592 | 27,648 | 2 × (144 × 96) | 5553 |
| maximum-bust-step-3 | per-request | 3 | 165,888 | 41,472 | 3 × (144 × 96) | 5554 |
| maximum-bust-step-4 | per-request | 4 | 221,184 | 55,296 | 4 × (144 × 96) | 5555 |
| maximum-bust | summary | 4 | 221,184 | 55,296 | 4 × (144 × 96) | 5556 |
| small-bust-step-1 | per-request | 1 | 1,536 | 384 | 1 × (24 × 16) | 5559 |
| small-bust-step-2 | per-request | 2 | 3,072 | 768 | 2 × (24 × 16) | 5560 |
| small-bust-step-3 | per-request | 3 | 4,608 | 1,152 | 3 × (24 × 16) | 5562 |
| small-bust-step-4 | per-request | 4 | 6,144 | 1,536 | 4 × (24 × 16) | 5563 |
| small-bust | summary | 4 | 6,144 | 1,536 | 4 × (24 × 16) | 5564 |
| maximum-sphere-step-1 | per-request | 1 | 98,304 | 24,576 | 1 × (192 × 128) | 5568 |
| maximum-sphere-step-2 | per-request | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5569 |
| maximum-sphere-step-3 | per-request | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5570 |
| maximum-sphere | summary | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5571 |
| mixed-bust-sphere-step-1 | per-request | 1 | 55,296 | 13,824 | 1 × (144 × 96) | 5574 |
| mixed-bust-sphere-step-2 | per-request | 2 | 110,592 | 27,648 | 2 × (144 × 96) | 5577 |
| mixed-bust-sphere-step-3 | per-request | 3 | 165,888 | 41,472 | 3 × (144 × 96) | 5578 |
| mixed-bust-sphere-step-4 | per-request | 3 | 208,896 | 52,224 | 2 × (144 × 96) + 1 × (192 × 128) | 5579 |
| mixed-bust-sphere | summary | 3 | 208,896 | 52,224 | 2 × (144 × 96) + 1 × (192 × 128) | 5580 |

All 19 rows satisfy count ≤ 4, RGBA ≤ 262,144 bytes and mask ≤ 65,536 bytes. Independently recomputed sums of width × height × 4 and width × height agree with the observed payload counters. These arithmetic checks reconcile emitted dimensions; successful XCTest assertions establish the source's additional cache checks.

## Methods and requested dimensions

All source references below are in `NativeTests/StudyRenderCacheTests.swift` at source6. The resource helper is at lines 748–798.

| Fixture family | Method | Request and output | Source start | Passing raw line |
|---|---|---|---:|---:|
| small-bust | `testRealCPUCacheResourcesForFourSmallFrames` | Four bust requests at width 24; 24 × 16 output | 801 | 5565 |
| maximum-bust | `testRealCPUCacheResourcesForFourMaximumBustFrames` | Four bust requests at width 192; clamped to 144 × 96 | 828 | 5557 |
| maximum-sphere | `testRealCPUCacheResourcesForMaximumSpheresEvictOldest` | Three sphere requests at width 192; 192 × 128; camera z = 25 forces CPU eligibility fallback | 855 | 5572 |
| mixed-bust-sphere | `testRealCPUCacheResourcesForMixedSubjectsEvictOnlyOldestBust` | Three 144 × 96 busts, then one 192 × 128 CPU sphere; oldest bust evicted | 892 | 5581 |

Each method passed once. A third maximum sphere cannot coexist within either payload budget, although the four-entry limit is not full. Three maximum busts plus the sphere would require 264,192 RGBA bytes and 66,048 mask bytes; eviction of one bust leaves the observed 208,896 and 52,224 bytes. Those pre-eviction totals are explanatory arithmetic, not additional observed cache states.

## Retained lifetime tests

The Linux source6 job 140009926092 passed 379 core methods in each of Debug and Release. All 16 `StudyFrameCacheTests` methods passed in each configuration. Raw evidence is blob `b99b8d092e34a136b6e00e14e4b8e83b1ecd98e8`; source test blob is `af6a0a4d81bb7bf9ebaeffb717f8f0871f7981de`. The four lifetime methods below use weak references to pure Swift `LifetimeValue` instances. Their `isMetal` field is a fixture Boolean, not a GPU object.

| Core lifetime method | Established scope | Debug pass line | Release pass line |
|---|---|---:|---:|
| `testOversizedReplacementRetainsOriginalLifetimeAndRecency` | Rejected value releases; original and unrelated values survive; rejection preserves oldest position | 1070 | 2026 |
| `testSuccessfulReplacementReleasesOnlyOriginalAndPromotesReplacement` | Replaced value releases; replacement becomes most recent; unrelated survivor releases only on later eviction | 1082 | 2038 |
| `testBudgetEvictionReleasesEveryRemovedValueAndRetainsSurvivors` | Both pixel and mask budget cases release every removed value and preserve survivors | 1052 | 2008 |
| `testSelectiveInvalidationReleasesOnlyMatchingValuesThenReleasesSurvivors` | Matching fixture values release; nonmatches survive until full invalidation | 1080 | 2036 |

The helper returns only a weak observer, and `withExtendedLifetime(cache)` keeps the cache alive during relevant assertions. These are reference-ownership results, not process-memory measurements.

Native `testFailedBackendReleasesWeaklyObservedInstanceWhileEngineRemainsAlive` passed at raw line 5536. It first checks that its weak observer cannot retain a standalone `ScriptedComputeBackend`. It then exercises command, allocation and invalid-compute-output failures with cancellation both false and true (six cases). After each awaited callback unwinds, the backend weak reference clears and its release count is one while the same engine remains usable. Completed CPU frames survive; Metal-tagged synthetic frames are evicted; later requests remain CPU. The factory captures only the script and observer. No real `MetalStudyRenderer` or MTL-buffer deallocation is measured by this method.

## Requested Metal buffer arithmetic — separate from observations

Source `App/MetalStudyRenderer.swift` blob `8c1acd852d85cd99671feaba883db1808bbb5e68` requests four buffers per dispatch: parameters, samples, areas and RGBA output. `StudyComputeInput` in `ReferenceStudy.swift` blob `0ca920b1332e1042d2e3ddfe0d0fe69ccc5b46ad` packs six 16-byte parameter rows and three rows per sample or area guard. An empty input row buffer still requests one zero row.

For S prepared samples, A area guards, image width W and height H, requested buffer lengths sum to:

`96 + 16 × max(3S, 1) + 16 × max(3A, 1) + 4WH bytes`.

At 192 × 128, output alone requests 98,304 bytes. The separate 8-byte dimension argument uses `setBytes`; it is not a separately requested MTLBuffer in this code. The validity mask is reconstructed on the CPU from output alpha. Pipeline, queue, commands, driver allocation granularity, CPU input arrays and conversion temporaries are outside this formula. These are source-derived requested lengths, not measured allocation, residency, release timing or peak memory.

The source waits for submitted commands to complete before reading output, then checks cancellation. Ordinary cancellation preserves the validated backend; confirmed permanent failure selects CPU and evicts its Metal-tagged cache entries. Cancelled/failed attempted frames are not admitted, while a separately successful CPU fallback can be retained after its own final check. The passed cancellation methods and scripted failure methods support those ownership/admission paths, not GPU latency.

## Evidence boundary

The input is `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`; the tested engine, core cache and core cache-test blobs are unchanged. All original 25 native cache methods are unchanged and passed in source6. Four source7 additions have no supplied results in this packet; run 45854806270 was pending at handoff and was not polled.

Owner03/20's A/Metal → B downgrade plus cancellation → return A through a UI-held frame remains an open consumer adoption dependency. It is not established engine-cache leakage, nor a UI pass. Near-field final Metal return is a cache hit, and startup cancellation stops CPU validation before GPU submission; neither provides GPU memory or latency evidence. Full commands, environments, source identities, raw method events, artifact IDs/digests and the corrected failed blob read appear in [source-command-receipt.json](source-command-receipt.json).
