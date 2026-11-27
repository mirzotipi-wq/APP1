# Lane 04 resource and lifetime results

## Decision and source boundary

**Source7 native retry2 succeeded.** Job **140103955982**, run **45854806270**, records **178 unique native passes**, including **29 cache methods and all four source7 additions**, with zero failures/skips. The native command completed normally; the actual inline Metal guard, standalone accounting, finalized XCTest export and full/compact uploads passed. Debug app/native-bundle and Release app builds passed, and the preparatory warm-up actually succeeded. The **whole workflow remains failed because of retained UI outcomes**; native success is scoped to this job.

The retry independently emitted **19 actual CPU cache payload rows**. All retain the unchanged per-engine limits: **four completed frames, 262,144 RGBA bytes (256 KiB), and 65,536 mask bytes (64 KiB)**. Bust rendering remains CPU-only at width **≤144**. Their raw JSON payloads are byte-for-byte identical to attempt1 and their parsed values match source6. This is cache payload accounting, not a new memory experiment.

This final same-ID update uses immutable input `609e34ed777226fbfb7375038ccfe1e30c1bd1a5`; final product/test source remains `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014` (source7). Campaign baseline is `f150f98e35dd735927075aac4d2f8b02295c6a67`. Source6 `240000fd3f8cb75273eb279be9dcc7f204a5b29f` retains its normally completed 174-method execution. Source7 attempt1 retains 178 method passes followed by a failed command and unfinalized bundle. Retry2 does not relabel those historical outcomes. [Final packet](evidence/w096/final-task-packet.json), [retry metadata](evidence/w096/final-retry2-metadata.json), [source identities](evidence/w096/originals/final-source-hashes.json).

Production sources and the original 25 cache methods were unchanged between source6 and source7; four methods were appended. Both source7 attempts now have direct compilation/runtime evidence for those additions, and retry2 supplies the completed native gates. Imported upstream UI and global records remain outside lane04 authorship. The [pre-update document](evidence/w096/final-resource-results.original.md) preserves earlier checkpoints.

Payload counters, pure Swift weak references, scripted backend release, actual simulator Metal, and requested-buffer arithmetic remain separate evidence classes. None measures allocator capacity, process RSS, driver residency, physical-device memory, or GPU cancellation latency.

## Execution provenance

| Evidence | Exact retained execution | Result and scope |
|---|---|---|
| Portable cache suite | Source6, [run 45848953002 / core job 140009926092](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002/job/140009926092), Ubuntu 24.04.5 x86_64, Swift 6.4.3 | 379 Debug and 379 Release methods passed; all 16 `StudyFrameCacheTests` passed in each configuration. These retained portable results remain distinct from the new native attempt. |
| Source6 native cache/resource suite | Same source/run, [native job 140012314020](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002/job/140012314020), hosted macOS 26.6.1 Intel, Xcode 26.6, Apple Swift 6.3.3, iOS Simulator SDK 26.5 | 174 unique Debug methods passed, zero failures/skips; all 25 cache methods passed. Native command, required accounting and finalized export succeeded. Debug and Release app builds passed; Release native runtime was unperformed. |
| Source7 portable | Run 45854806270, core job 140031989526 | Retained 379 Debug/379 Release and host canonical six/strict eight passed. This follow-up did not rerun them. |
| Source7 native attempt1 | [Run 45854806270 / job 140034909086](https://github.com/mirzotipi-wq/APP1/actions/runs/45854806270/job/140034909086), attempt1, Debug | 178 starts and 178 unique passes, zero failures/skips/duplicates/omissions; all 29 cache methods passed. Both app builds and standalone method accounting passed. Native command timed out after 18 minutes; finalized export failed. **Job conclusion: failure.** Release native runtime remains unperformed. |
| Source7 native-only retry2 | [Same run / native job 140103955982](https://github.com/mirzotipi-wq/APP1/actions/runs/45854806270/job/140103955982), attempt2, same source and Debug inventory | **Success:** 178 unique passes, all 29 cache methods, zero failures/skips. Normal command, actual inline guard, accounting, finalized export, full/compact uploads, both builds and warm-up passed. macOS portable tests passed 379. Release native runtime remains unperformed. |

Source6's preparatory simulator warm-up exited **1** after bootstatus and recovery-preflight timeouts (its native raw lines 4714–4735); later required native command/accounting/export succeeded. Source7 attempt1 also has a failed warm-up diagnostic (raw line 4756). Its all-tests pass event appears at line 5660, the native command timeout at 5670, successful standalone `verify-log` accounting at 5679, and the missing-finalized-bundle error at 5704 followed by exit1 at 5705. `NativeTests.xcresult/Info.plist` was absent. The inline post-xcodebuild Metal guard was **not reached**; echoed guard source is not an executed guard pass. [Attempt1 raw log](evidence/w096/native7-attempt1.log), [metadata](evidence/w096/native7-attempt1-metadata.json), [retry receipt](evidence/w096/native7-retry2-initial.json).

Attempt1's full native artifact 15143453127 retains logs/raw unfinished-bundle evidence; it establishes neither finalized native attachments nor a native compact artifact. The [original artifact receipt](evidence/w096/native7-attempt1-artifacts.json) pins its digest. Source6's [native log](evidence/w096/originals/wave06-native-140012314020.log), [core log](evidence/w096/originals/wave06-core-140009926092.log), and [reconciliation](evidence/w096/resource-reconciliation.v1.json) remain unchanged. The attempt1 [resource/method reconciliation](evidence/w096/native7-resource-reconciliation.v1.json) independently records all source7 observations. The whole workflow remains failed due to retained UI outcomes. API-cloned core/UI envelopes in attempt2 are not new executions.

Retry2 records actual warm-up bootstatus exit0 at raw line 4711 and success outcome at 4754, normal `TEST EXECUTE SUCCEEDED` at 5672, the executed inline Metal guard's success message at 5675, and standalone 178-method accounting at 5684. Finalized export and both uploads passed. The suite reports **90.152 execution seconds / 93.407 wall seconds** at line 5630; these are suite timings, **not a GPU benchmark**. [Retry raw log](evidence/w096/final-retry2.log), [metadata](evidence/w096/final-retry2-metadata.json), [independent reconciliation](evidence/w096/final-resource-reconciliation.v1.json).

The retained artifact receipt reports both successful retry uploads with expiration **2027-02-24T18:28:51Z**. These are provider-reported byte counts and SHA-256 digests; this worker did not download and rehash the archives. [Original artifact receipt](evidence/w096/final-retry2-artifacts.json).

| Retry artifact | ID | Bytes | Reported SHA-256 |
|---|---:|---:|---|
| Full native evidence | 15147144695 | 62,001,366 | `5f9a64474f806d362309e6088c32cdcec73939e3cbef68361fce0afde7deb620` |
| Compact native evidence | 15147426870 | 332,367 | `f055e26a9e66ac3297685e0226545594a0918e67f09afeb484405ae6cf979475` |

## All observed payload rows

All three native executions independently emitted the same **19 payload tuples**: 15 request observations and four summaries that repeat the final state without another render. The table provides source6, failed source7 attempt1, and successful retry2 raw-log locations while sharing the identical values. `pixelBytes` means RGBA payload length; `maskBytes` is one byte per pixel, not the number of unsupported pixels.

Dimensions come from retained returned-image arrays. The source helper separately reads `StudyRenderEngine.cacheUsage` and asserts its count and byte totals against those arrays and fixed limits. Dimensions are therefore a cross-check, not direct cache-entry enumeration. Subsequent hit and cancelled-cold-render probes check retained identities. The arrays continue to hold returned images, including evicted images in some fixtures, so the counters do not establish image-allocation release.

| Fixture | Kind | Entries | RGBA bytes | Mask bytes | Returned-image dimensions | Source6 line | Source7 attempt1 line | Retry2 line |
|---|---|---:|---:|---:|---|---:|---:|---:|
| maximum-bust-step-1 | request | 1 | 55,296 | 13,824 | 1 × (144 × 96) | 5550 | 5564 | 5527 |
| maximum-bust-step-2 | request | 2 | 110,592 | 27,648 | 2 × (144 × 96) | 5553 | 5565 | 5528 |
| maximum-bust-step-3 | request | 3 | 165,888 | 41,472 | 3 × (144 × 96) | 5554 | 5566 | 5529 |
| maximum-bust-step-4 | request | 4 | 221,184 | 55,296 | 4 × (144 × 96) | 5555 | 5567 | 5530 |
| maximum-bust | summary | 4 | 221,184 | 55,296 | 4 × (144 × 96) | 5556 | 5568 | 5531 |
| small-bust-step-1 | request | 1 | 1,536 | 384 | 1 × (24 × 16) | 5559 | 5571 | 5534 |
| small-bust-step-2 | request | 2 | 3,072 | 768 | 2 × (24 × 16) | 5560 | 5572 | 5535 |
| small-bust-step-3 | request | 3 | 4,608 | 1,152 | 3 × (24 × 16) | 5562 | 5573 | 5536 |
| small-bust-step-4 | request | 4 | 6,144 | 1,536 | 4 × (24 × 16) | 5563 | 5574 | 5537 |
| small-bust | summary | 4 | 6,144 | 1,536 | 4 × (24 × 16) | 5564 | 5575 | 5538 |
| maximum-sphere-step-1 | request | 1 | 98,304 | 24,576 | 1 × (192 × 128) | 5568 | 5578 | 5542 |
| maximum-sphere-step-2 | request | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5569 | 5579 | 5543 |
| maximum-sphere-step-3 | request | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5570 | 5580 | 5544 |
| maximum-sphere | summary | 2 | 196,608 | 49,152 | 2 × (192 × 128) | 5571 | 5581 | 5545 |
| mixed-bust-sphere-step-1 | request | 1 | 55,296 | 13,824 | 1 × (144 × 96) | 5574 | 5586 | 5550 |
| mixed-bust-sphere-step-2 | request | 2 | 110,592 | 27,648 | 2 × (144 × 96) | 5577 | 5587 | 5552 |
| mixed-bust-sphere-step-3 | request | 3 | 165,888 | 41,472 | 3 × (144 × 96) | 5578 | 5588 | 5553 |
| mixed-bust-sphere-step-4 | request | 3 | 208,896 | 52,224 | 2 × (144 × 96) + 1 × (192 × 128) | 5579 | 5589 | 5554 |
| mixed-bust-sphere | summary | 3 | 208,896 | 52,224 | 2 × (144 × 96) + 1 × (192 × 128) | 5580 | 5590 | 5555 |

The worker independently extracted all 19 retry2 `KEYFILL_CACHE_RESOURCES` emissions. Their raw JSON payload strings exactly match attempt1; parsed payloads and line references agree with retry metadata, and payload values agree with source6. Dimension count equals actor count; summing `4 × width × height` and `width × height` reproduces RGBA and mask totals. All observations satisfy all three bounds. [Full retry rows/checks](evidence/w096/final-resource-reconciliation.v1.json), [retry raw emissions](evidence/w096/final-observed-resource-lines.log), [retained attempt1 reconciliation](evidence/w096/native7-resource-reconciliation.v1.json), [original source6 summary](evidence/w096/originals/CACHE_RESOURCES.w076.md).

| Resource method | Request and retained result | Source6 pass line | Source7 attempt1 pass line | Retry2 pass line |
|---|---|---:|---:|---:|
| `testRealCPUCacheResourcesForFourSmallFrames` | Four width-24 busts; all four 24×16 frames remain and can be reused. | 5565 | 5576 | 5539 |
| `testRealCPUCacheResourcesForFourMaximumBustFrames` | Four width-192 bust requests clamp to 144×96; later width-144 requests reuse them. | 5557 | 5569 | 5532 |
| `testRealCPUCacheResourcesForMaximumSpheresEvictOldest` | Three width-192 spheres with camera z=25 deliberately select CPU; two 192×128 frames remain and the oldest key is cold. | 5572 | 5582 | 5546 |
| `testRealCPUCacheResourcesForMixedSubjectsEvictOnlyOldestBust` | Three maximum busts followed by a maximum CPU sphere leave two busts and the sphere; only the oldest bust is evicted. | 5581 | 5591 | 5556 |

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

The [executed source6 tests](evidence/w096/originals/StudyRenderCacheTests.source6.swift) and [source7 tests](evidence/w096/originals/StudyRenderCacheTests.source7.swift) keep actor behavior distinct from GPU work. All original 25 methods have source6 passes and pass events in both source7 attempts. They cover entry/LRU and byte-budget eviction, cancelled cache hits preserving eviction order, cancelled CPU/final work not being admitted, ordinary compute cancellation preserving a validated backend/completed cache, precision-domain CPU fallback preserving the backend, and confirmed failures downgrading before concurrent cancellation. The retry reconciliation retains every one of the 29 current-source cache-method pass events.

All four appended methods have direct starts and terminal passes in both source7 attempts. Retry2 also passes the required native aggregate gates; attempt1's command/export failure remains retained:

| Appended method | Attempt1 start | Attempt1 pass | Retry2 start | Retry2 pass |
|---|---:|---:|---:|---:|
| `testStartupFailureWithCancellationPreservesPreviouslyCachedCPUFrame` | 5594 | 5595 | 5559 | 5562 |
| `testCancelledValidationPreservesCPUCacheAndRetriesOnSameEngine` | 5525 | 5526 | 5492 | 5493 |
| `testConcurrentEligibleRequestsValidateOnceAndCacheDistinctImages` | 5527 | 5528 | 5494 | 5495 |
| `testSteadyStateSceneErrorsPreserveValidatedBackendAndCachedFrames` | 5602 | 5603 | 5569 | 5570 |

`testFailedBackendReleasesWeaklyObservedInstanceWhileEngineRemainsAlive` passed at source6 line 5536, source7 attempt1 line **5548**, and retry2 line **5511**. It first falsifies accidental strong ownership by its observer. Command, allocation and invalid-compute-output failures are then each tested with and without concurrent cancellation: **six scripted cases**, unchanged across these runs. After the awaited callback unwinds, the weak backend reference is nil and the release count is one while the same engine remains usable. Completed CPU entries survive, synthetic Metal-tagged entries are evicted, and later requests stay CPU. The injected factory captures only the script and observer. This establishes `ScriptedComputeBackend` ownership in those cases; it does not measure `MetalStudyRenderer`, MTLBuffer deallocation, driver release, or GPU work.

A failed/cancelled attempted frame is not admitted. A separately successful CPU fallback can be retained after its own final cancellation check. Cancellation remains cooperative: an external flag changing after a false check can still permit submission, admission or return. Actor serialization does not make that flag atomic. [The engine source](evidence/w096/originals/MetalStudyRenderer.swift) and [fallback contract](FALLBACK_CONTRACT.md) describe routing and caller-adoption boundaries.

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

## Actual Metal, timing and consumer limits

Source6 and both source7 attempts separately executed actual simulator Metal canonical six and strict eight. Retry2 retains all **14 numerical fixture outputs**, with canonical maximum channel error ≤1 and zero outlier fractions; strict mean/maximum/outlier values are all zero. Its metadata records equality with attempt1's emitted metrics. Exact masks are established by passed assertions. Canonical printed `invalid match` alone is count equality; candidate/reference invalid totals and mask-mismatch counts are unprinted and are not invented. [Retry numerical metadata](evidence/w096/final-retry2-metadata.json) and [PARITY_TABLES](PARITY_TABLES.md) keep host execution distinct from simulator Metal.

Neither actual Metal numerical output, suite timing, CPU counters nor scripted ownership tests measures driver memory, RSS, physical-device performance or GPU completion latency. The CPU acceptance bound of at most eight further pixel evaluations after the specified external cancellation remains distinct from GPU latency. All retry native gates have passed; the retained full-workflow failure and combined-owner integration limits remain separate.

Owner03 is now observed at head `82c0e59a9adc68361378f65cdaefe23bc1d93c5d`, with corrected-observer source `dbbc264fde91bfb04a1e82fbebdf2f8d5792d761`. Successful Apple Debug app/native-bundle, Release app and full-scheme Debug build-for-testing steps establish that the corrected observer **compiles**. Root's later job API receipt reports **completed/failure**, while native-step metadata remains stale and two completed-job raw-log reads returned **404 BlobNotFound**. Actual method counts, corrected-observer outcome, command-termination details, accounting and finalized results are **unknown/unverified**. Neither a product defect nor absence of execution can be inferred from these missing results. [Owner build/refresh](evidence/w096/final-owner-refresh.json), [retained build receipt](evidence/w096/final-owner-build.json), [later root observation](evidence/w096/final-owner-observation.json).

The original hosted AX test at source `342e3280e3eb077d55e122c8bfb88b4062b431ed` remains a separate failed observation: 165 methods started, 164 passed, one failed, zero skipped; its initial AX positive control (`identifiers=[]`) failed before scene switches. Both builds and ten pipeline methods passed there. That historical observer failure does not establish a production defect.

The unchanged replacement uses public UIKit `drawHierarchy` center pixels with synthetic gray32 initial/held A and gray160 replacement, alpha255/RGB tolerance2, one host, two A/one B calls and controlled continuations. It **removes AX badge/warning assertions**. A held-frame reading is one checkpoint, not continuous visibility or proof of actual engine downgrade. Corrected-runtime results remain unknown despite established compilation; hook-only before/fail execution remains unverified. All six compared owner source hashes, including preview/oracle and the observer, are unchanged from the preceding refresh.

Combined03/20 integration remains open. It must retain lane04's engine, eligibility and guarded header when combining owner03's oracle/preview/test; no acknowledgment or combined pass is evidenced. Lane04 still retains the old preview. A UI-held image lies outside engine-cache accounting and can survive invalidation. These resource results establish neither adoption completion nor a new engine-cache leak.

## Preservation and work scope

This is a final same-ID evidence update with **zero new workers**. The primary 100 reports, including `workers/w096.md`, remain unchanged. The original document, prior source6/attempt1 evidence, supplied retry/owner receipts, all 19 new rows, candidate, checkpoint, validation and ≤350-word report are preserved under `evidence/w096/final-*`; earlier evidence paths remain intact. [Final report](evidence/w096/final-supplement.md), [validation](evidence/w096/final-validation.json), [full artifact map](evidence/w096/final-artifact-map.json).

No executor, CI poll/rerun, child, source/UI/config/ref write, threshold change, oracle/ABI change, new memory measurement or global milestone promotion occurred. Planned `/tmp/keyfill04-2987b1ee980d/workers/w096` and `/tmp/keyfill04-2987b1ee980d/results/w096` remain **UNCREATED**. Root owns integration.
