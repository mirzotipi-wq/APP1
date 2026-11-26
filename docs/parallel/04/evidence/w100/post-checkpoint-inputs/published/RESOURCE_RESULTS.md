# Lane 04 resource and lifetime results

## Decision and source boundary

All **19 observed CPU cache payload rows** satisfy the unchanged per-engine limits: **four completed frames, 262,144 RGBA bytes (256 KiB), and 65,536 mask bytes (64 KiB)**. Bust rendering remains CPU-only at width **≤144**. These observations establish retained payload accounting for the tested fixtures. They do not establish process RSS, allocator capacity, driver residency, physical-device memory, or GPU cancellation latency.

This report was prepared from immutable documentation input `0fa824307da13934a289a825fd6d9d4a1939241f`. Final product/test source is `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`; campaign baseline is `f150f98e35dd735927075aac4d2f8b02295c6a67`. The measured native source is `240000fd3f8cb75273eb279be9dcc7f204a5b29f` (source6). [The frozen CI manifest](evidence/w096/originals/CI_MANIFEST.frozen.json), [source identities](evidence/w096/originals/final-source-hashes.json), and [root's exhaustive tree comparison](evidence/w096/originals/root-source-identity-audit.json) pin that distinction.

Root's complete, untruncated source6→input comparison finds one changed path outside lane documentation: the native cache-test file. All production sources and all other tests are byte-identical. This worker additionally compared the retained source6 test-class prefix with the current file: all original 25 methods remain unchanged, followed by four additions. Earlier runtime evidence therefore carries forward for the unchanged implementation and methods; it does not execute those four additions. Imported upstream UI and global records are not lane04-authored changes.

## Execution provenance

| Evidence | Exact retained execution | Result and scope |
|---|---|---|
| Portable cache suite | Source6, [run 45848953002 / core job 140009926092](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002/job/140009926092), Ubuntu 24.04.5 x86_64, Swift 6.4.3 | 379 Debug and 379 Release methods passed; all 16 `StudyFrameCacheTests` passed in each configuration. |
| Native cache/resource suite | Same source/run, [native job 140012314020](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002/job/140012314020), hosted macOS 26.6.1 Intel, Xcode 26.6, Apple Swift 6.3.3, iOS Simulator SDK 26.5 | 174 unique Debug native methods passed, no failures/skips; all 25 cache methods passed. Required accounting and finalized XCTest export succeeded. Debug and Release app builds passed; Release native runtime was not performed. |
| Latest product/test source | Source7, run 45854806270; core job 140031989526 and native job 140034909086 | Portable 379 Debug/379 Release and host canonical six/strict eight passed. Native remains queued in the frozen receipt, with no assigned runner. Four appended methods are unexecuted and their Apple compilation is unperformed. |

The preparatory simulator warm-up in source6 exited **1** after bootstatus and recovery-preflight timeouts (raw native lines 4714–4735). Subsequent required native tests, accounting and export passed. This report preserves the diagnostic failure and does not claim every step or the whole workflow passed. Worker096 performed no local build, test execution, CI polling, rerun, or runner probe.

Original logs are retained as [source6 native](evidence/w096/originals/wave06-native-140012314020.log) and [source6 core](evidence/w096/originals/wave06-core-140009926092.log). The [reconciliation receipt](evidence/w096/resource-reconciliation.v1.json) records extracted rows, pass-event line numbers, arithmetic checks and source identities. Full commands and artifact provenance remain in the frozen CI manifest.

## All observed payload rows

Each row below is an actual `KEYFILL_CACHE_RESOURCES` emission from the source6 Debug native log. Fifteen rows follow individual requests; four summary rows repeat the final state without another render. `pixelBytes` means RGBA payload length; `maskBytes` is one byte per pixel, not the number of unsupported pixels.

Dimensions come from retained returned-image arrays. The source helper independently reads `StudyRenderEngine.cacheUsage` and asserts its count and byte totals against those arrays and fixed limits. The dimensions are therefore a cross-check, not direct cache-entry enumeration. Subsequent successful-hit and cancelled-cold-render probes check retained identities. Those arrays continue to hold returned images, including evicted images in some fixtures, so the counters cannot establish image-allocation release.

| Fixture | Kind | Entries | RGBA bytes | Mask bytes | Returned-image dimensions | Raw line |
|---|---|---:|---:|---:|---|---:|
| maximum-bust-step-1 | request | 1 | 55,296 | 13,824 | 1 × (144 × 96) | 5550 |
| maximum-bust-step-2 | request | 2 | 110,592 | 27,648 | 2 × (144 × 96) | 5553 |
| maximum-bust-step-3 | request | 3 | 165,888 | 41,472 | 3 × (144 × 96) | 5554 |
| maximum-bust-step-4 | request | 4 | 221,184 | 55,296 | 4 × (144 × 96) | 5555 |
| maximum-bust | summary | 4 | 221,184 | 55,296 | 4 × (144 × 96) | 5556 |
| small-bust-step-1 | request | 1 | 1,536 | 384 | 1 × (24 × 16) | 5559 |
| small-bust-step-2 | request | 2 | 3,072 | 768 | 2 × (24 × 16) | 5560 |
| small-bust-step-3 | request | 3 | 4,608 | 1,152 | 3 × (24 × 16) | 5562 |
| small-bust-step-4 | request | 4 | 6,144 | 1,536 | 4 × (24 × 16) | 5563 |
| small-bust | summary | 4 | 6,144 | 1,536 | 4 × (24 × 16) | 5564 |
| maximum-sphere-step-1 | request | 1 | 98,304 | 24,576 | 1 × (192 × 128) | 5568 |
| maximum-sphere-step-2 | request | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5569 |
| maximum-sphere-step-3 | request | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5570 |
| maximum-sphere | summary | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5571 |
| mixed-bust-sphere-step-1 | request | 1 | 55,296 | 13,824 | 1 × (144 × 96) | 5574 |
| mixed-bust-sphere-step-2 | request | 2 | 110,592 | 27,648 | 2 × (144 × 96) | 5577 |
| mixed-bust-sphere-step-3 | request | 3 | 165,888 | 41,472 | 3 × (144 × 96) | 5578 |
| mixed-bust-sphere-step-4 | request | 3 | 208,896 | 52,224 | 2 × (144 × 96) + 1 × (192 × 128) | 5579 |
| mixed-bust-sphere | summary | 3 | 208,896 | 52,224 | 2 × (144 × 96) + 1 × (192 × 128) | 5580 |

The worker independently parsed all 19 emissions from the original log. Every row exactly matches the frozen manifest, its dimension count equals the actor count, and summing `4 × width × height` and `width × height` reproduces the two payload counters. All 19 rows meet every bound. [Original resource summary](evidence/w096/originals/CACHE_RESOURCES.w076.md), [original emissions](evidence/w096/originals/observed-resource-lines.w076.log), and [original machine-readable receipt](evidence/w096/originals/cache-resources.w076.json) are preserved without modification.

| Resource method | Request and retained result | Passing native line |
|---|---|---:|
| `testRealCPUCacheResourcesForFourSmallFrames` | Four width-24 busts; all four 24×16 frames remain and can be reused. | 5565 |
| `testRealCPUCacheResourcesForFourMaximumBustFrames` | Four width-192 bust requests clamp to 144×96; later width-144 requests reuse them. | 5557 |
| `testRealCPUCacheResourcesForMaximumSpheresEvictOldest` | Three width-192 spheres with camera z=25 deliberately select CPU; two 192×128 frames remain and the oldest key is cold. | 5572 |
| `testRealCPUCacheResourcesForMixedSubjectsEvictOnlyOldestBust` | Three maximum busts followed by a maximum CPU sphere leave two busts and the sphere; only the oldest bust is evicted. | 5581 |

Eviction is explained by source-derived arithmetic, not extra measured states. Three maximum spheres would require 294,912 RGBA and 73,728 mask bytes. Three maximum busts plus one maximum sphere would require 264,192 RGBA and 66,048 mask bytes. Both combinations exceed both payload budgets even though their entry counts would be allowed; removing one oldest frame produces the observed populations. Four maximum busts fit at 221,184/55,296 bytes.

## Entry limits, recency, replacement and object lifetime

The [generic cache source](evidence/w096/originals/StudyFrameCache.swift) has immutable positive limits, promotes successful hits, leaves misses unchanged, rejects negative or individually oversized costs without mutation, and removes an admitted replacement's old charge before eviction. It evicts before append; subtraction-based comparisons avoid overflow. Selective removal preserves survivors' relative recency.

All 16 [portable cache methods](evidence/w096/originals/StudyFrameCacheTests.swift) passed in both source6 configurations. The table records terminal pass lines in the original core log; these are retained execution events, not tests rerun by this worker.

| Portable method | Debug pass line | Release pass line |
|---|---:|---:|
| `testBudgetEvictionReleasesEveryRemovedValueAndRetainsSurvivors` | 1052 | 2008 |
| `testEmptyCacheRetainsConfiguredLimitsAndMissDoesNotChangeCosts` | 1054 | 2010 |
| `testEntryLimitBoundsZeroCostValues` | 1056 | 2012 |
| `testEquivalentNonHashableKeysReplaceAndFindTheSameEntry` | 1058 | 2014 |
| `testHitPromotesRecencyAndMissDoesNotProtectOldestEntry` | 1060 | 2016 |
| `testInvalidAndOversizedCostsRejectWithoutReplacementOrRecencyChanges` | 1062 | 2018 |
| `testLargerReplacementRemovesOldChargeBeforeEvictingOtherEntries` | 1064 | 2020 |
| `testMaskBudgetIndependentlyEvictsAndSubtractsBothCosts` | 1066 | 2022 |
| `testMaximumIntegerBudgetsEvictBeforeAdditionCanOverflow` | 1068 | 2024 |
| `testOversizedReplacementRetainsOriginalLifetimeAndRecency` | 1070 | 2026 |
| `testPixelBudgetEvictsMultipleOldestEntriesBeforeCountLimit` | 1072 | 2028 |
| `testProductionPayloadBudgetsRemainBoundedAcrossMixedFrameSizes` | 1074 | 2030 |
| `testReplacementChargesNewCostsOnlyAndBecomesMostRecent` | 1076 | 2032 |
| `testSelectiveBackendRemovalPreservesSurvivorCostsAndRecency` | 1078 | 2034 |
| `testSelectiveInvalidationReleasesOnlyMatchingValuesThenReleasesSurvivors` | 1080 | 2036 |
| `testSuccessfulReplacementReleasesOnlyOriginalAndPromotesReplacement` | 1082 | 2038 |

The four lifetime methods observe weak references to pure Swift `LifetimeValue` objects while keeping the cache alive with `withExtendedLifetime`. They establish that rejected replacements release the rejected value while preserving the original and its recency; accepted replacements release the old value and promote the new one; budget eviction releases every removed value; and selective invalidation releases matches while retaining survivors until full removal. The fixture's `isMetal` Boolean is only a tag. These methods do not contain real GPU objects or measure actual image backing allocations.

## Native actor behavior and scripted backend lifetime

The [executed native test source](evidence/w096/originals/StudyRenderCacheTests.source6.swift) and [current source](evidence/w096/originals/StudyRenderCacheTests.source7.swift) keep actor behavior distinct from GPU work. Passed source6 methods cover entry/LRU eviction, byte-budget eviction, cancelled cache hits preserving eviction order, cancelled CPU/final work not being admitted, ordinary compute cancellation preserving a validated backend and completed cache, precision-domain CPU fallback preserving the backend, and confirmed failures downgrading before concurrent cancellation.

`testFailedBackendReleasesWeaklyObservedInstanceWhileEngineRemainsAlive` passed at native line 5536. It first falsifies accidental strong ownership by its observer. Then command, allocation and invalid-compute-output failures are each tested with and without concurrent cancellation: six scripted cases. After the awaited callback unwinds, the weak backend reference is nil and the release count is one, while the same engine remains usable. Completed CPU entries survive, synthetic Metal-tagged entries are evicted, and later requests stay CPU. The injected factory captures only the script and observer. This measures `ScriptedComputeBackend` ownership, not `MetalStudyRenderer`, MTLBuffer deallocation, driver release, or GPU work.

A failed/cancelled attempted frame is not admitted. A separately successful CPU fallback can be retained after its own final cancellation check. Cancellation remains cooperative: an external flag changing after a false check can still permit submission, admission or return. Actor serialization does not make that external flag atomic. [The engine source](evidence/w096/originals/MetalStudyRenderer.swift) and [fallback contract](evidence/w096/originals/FALLBACK_CONTRACT.md) retain the exact routing and caller-adoption qualifications.

## Requested Metal buffers: arithmetic rather than memory telemetry

The engine source requests four MTLBuffers per dispatch. [The packed input source](evidence/w096/originals/ReferenceStudy.swift) retains six parameter float4 rows and three rows per prepared sample or area guard. Each row occupies 16 bytes. Empty sample/area arrays still request one zero row for a valid binding.

| Buffer | Requested length |
|---|---:|
| Parameters | 6 × 16 = 96 bytes |
| Samples, S prepared samples | 16 × max(3S, 1) bytes |
| Areas, A guards | 16 × max(3A, 1) bytes |
| RGBA output, width W and height H | 4WH bytes |

Total requested buffer lengths are **`96 + 16 × max(3S, 1) + 16 × max(3A, 1) + 4WH` bytes**. At 192×128, output alone requests 98,304 bytes. The separate eight-byte dimensions argument uses `setBytes`; this code does not request a fifth MTLBuffer for it. The validity mask is reconstructed on CPU from output alpha.

This formula excludes queue/pipeline/command resources, driver granularity, CPU input arrays, conversion temporaries, allocator capacities and caller-held frames. It is neither an observed allocation total nor a peak-memory or residency bound. The cache budgets separately constrain retained payloads per engine; neither formula bounds total application memory.

Before commitment, observed cancellation prevents submission. Once committed, program order is `waitUntilCompleted`, require `.completed`, check cancellation, copy output into `Data`, construct `StudyImage`, then exit the autorelease pool. Command failure is observed before post-completion cancellation. Those source-order facts support safe output access, while ARC/Metal retention and physical resource reclamation remain distinct. No instantaneous GPU cancellation or measured completion/release deadline is inferred.

## Actual Metal and remaining limits

Source6 separately executed actual simulator Metal canonical six and strict eight: canonical maximum channel error ≤1 with zero outlier fractions, and strict mean/maximum/outlier errors all zero; both assert exact masks. Those numerical checks are listed in [PARITY_TABLES](PARITY_TABLES.md) and the frozen manifest. They are separate from the CPU resource rows and mock actor tests and provide no driver/RSS measurements. The unchanged CPU acceptance bound of at most eight further pixel evaluations after the specified external cancellation is also distinct from GPU latency.

The four source7 additions remain unexecuted in the retained native queue receipt: startup failure with cached CPU preservation, cancelled validation preserving CPU cache and retrying, concurrent eligible requests validating once, and steady-state scene errors preserving the backend/cache. Root alone monitors that job. Queue state is neither pass nor failure.

Consumer integration with owner03/20 remains open: current owner03 has a ticket-aware source remedy and hosted test, but lane04 retains the old preview and the owner receipts do not establish hosted Apple execution. A UI-held frame is outside the engine cache's payload accounting and can survive engine invalidation. This report establishes neither consumer adoption completion nor a new engine-cache leak. See [HANDOFF](HANDOFF.md) and [the frozen owner-aware handoff](evidence/w096/originals/HANDOFF.w094.v3.md).

Only documentation/evidence blobs were prepared. No source/test, threshold, oracle, ABI, UI, config, global milestone or Git ref was changed. Planned `/tmp/keyfill04-2987b1ee980d/workers/w096` and `/tmp/keyfill04-2987b1ee980d/results/w096` remain **UNCREATED**. Root owns integration. [Inputs](evidence/w096/inputs.json), [checkpoint](evidence/w096/checkpoint.json), [validation](evidence/w096/validation.json), and [artifact map](evidence/w096/artifact-map.json) retain provenance and every original/intermediate candidate.

## Root checkpoint after the independent review

The 100-worker campaign and report catalog are complete. The [17:48:36 UTC source7 receipt](evidence/ci/wave07-native-140034909086-debug-build.json) supersedes the earlier queued state: Debug app/native bundle compilation succeeded, Release app build is running, and native runtime is pending. The four added methods therefore have Apple compilation evidence but no runtime pass yet. Original frozen observations and source6 measurements above remain retained. [Current CI manifest](CI_MANIFEST.json) and [handoff](HANDOFF.md) distinguish the stages.
