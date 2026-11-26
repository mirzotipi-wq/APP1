# Lane 04 coordinator checkpoint — 80 of 100 workers complete

Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Wave 8 input and final source checkpoint: `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`. Only `finish/04-metal-cache` is authorized for publication.

## Completed work

Eighty distinct fresh contexts completed eight waves of ten. Exact worker IDs, fresh-context flags, per-wave input revisions, reports and same-ID follow-ups are retained in worker-ledger.json and each wave ledger. No planned path, retry, follow-up or coordinator action is counted as a new worker. Budget values are workflow targets; platform-enforced token counters are unavailable.

Wave 8 changes documentation and evidence only. PARITY_TABLES.md preserves baseline/current host and simulator results with exact source/job identity, thresholds, commands and mask-evidence basis. precision-fixtures.json and its reproducibility note preserve exact constructors, source blobs, routing expectations and invalid-input errors. Per-worker evidence retains original candidates, raw receipts, corrected labels and independent reviews.

The current production renderer remains blob `8c1acd852d85cd99671feaba883db1808bbb5e68`. Source 7 only appends four native cache methods (29 total), preserving all 25 previous methods and helpers. No production, CPU oracle, packed ABI, shared build configuration, canonical harness or preview source changed in this wave.

## Executed evidence

Source `240000fd3f8cb75273eb279be9dcc7f204a5b29f`, run 45848953002:

- Core job 140009926092 passed 379 Debug and 379 Release methods; six host shared-kernel canonical and eight strict precision cases passed with zero mask mismatches.
- Native job 140012314020 succeeded: 174 unique Debug native methods, zero failures/skips; unsigned Debug and Release builds, required-method accounting and finalized XCTest export all passed. Release native runtime was not executed.
- Actual simulator Metal canonical six had maximum channel error at most one and zero outlier fractions, with exact masks asserted. Strict eight had zero mean/max/outlier errors and printed/asserted exact mask equality. Native numerical unsupported/mismatch counts were not printed.
- All 25 cache methods passed. Scripted backend failure/cancellation tests remain distinct from actual Metal dispatch and real CPU cache tests.

Source `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`, run 45854806270:

- Core job 140031989526 passed 379 Debug and 379 Release methods and the same host six/eight matrices.
- Native job 140034909086 is queued at checkpoint preparation. Its four appended methods have no native execution receipt yet. Root continues to monitor it; documentation-only commits do not trigger/cancel this workflow.

Raw logs, parsed receipts, exact test methods and uploaded artifact identities are retained under evidence/ci/. Earlier cancelled jobs remain recorded without a pass. Historical simulator Metal at source 88279ba and the post-upstream-fix baseline 5bf9da7 are separate rows; neither is relabelled as direct f150 execution.

## Measured resource scope

All nineteen expected KEYFILL_CACHE_RESOURCES rows were observed in native job 140012314020: fifteen per-request observations and four final summaries. These measure real CPU images and actor cache payload counters:

| Population after requests | Entries | RGBA bytes | Mask bytes |
|---|---:|---:|---:|
| Four 24×16 bust frames | 4 | 6144 | 1536 |
| Four 144×96 bust frames | 4 | 221184 | 55296 |
| Three 192×128 sphere requests, two retained | 2 | 196608 | 49152 |
| Three bust requests then one sphere, two bust + one sphere retained | 3 | 208896 | 52224 |

Every observation remained within four entries, 262144 RGBA bytes and 65536 mask bytes. Mask byte size is not the number of unsupported pixels. Generic cache weak-reference tests measure Swift ownership; scripted backend release tests measure actor ownership; requested MTLBuffer lengths are arithmetic. None measures process RSS, allocator capacity, driver memory, physical-device behavior or GPU cancellation latency.

## Evidence corrections and limits

The historical silhouette reproduction compared the host C++ Float32 kernel with an independent C++ Double geometry transcription. Its printed invalid=0 counts candidate invalid pixels only; it is not a two-mask comparator. The retained command establishes O2, not an independently located O0 receipt. Later Swift tests establish two black reference pixels, not whole-frame Swift/Metal metrics for that reproduction.

The precision script generates 33 probes, while standard strict CI selects 8. No pass is claimed for the other 25. Native validation fixtures intentionally bypass production eligibility; their dispatch success does not establish normal Metal routing. Invalid camera-clearance equality remains an invalid-camera error, not a successful CPU fallback frame. The near-field recovery test revisits a cached normal key; it does not prove a fresh GPU dispatch there.

## Remaining owner dependency and continuation

The lane 03/20 preview adoption gap remains unresolved: after A/Metal is shown, B confirms permanent downgrade plus cancellation, and returning to A may bypass the engine via a UI-held frame. Old pixels may remain valid; subsequent current status/adoption must reflect the engine decision. The proposal targets lane 03 preview blob c96d5cb7; the current input preview is a different blob 1a68db0f. Applicability must be checked at the owner revision. No UI edit, owner acknowledgment, compilation or hosted A→B→A regression pass is claimed.

Local execution remains unavailable. This wave used isolated immutable Git snapshots/session states and Git blobs. Planned physical worktrees/results were not created; local builds, shell probes, hash-object and cleanup were not performed. Earlier available worktrees, failures, interrupted attempts and preserved recovery artifacts remain documented.

Wave 9 challenges retention and recovery, refreshes owner interfaces, and writes the fallback contract. Wave 10 seals HANDOFF.md, RESOURCE_RESULTS.md, CI_MANIFEST.json, precise owner routes and the 100-worker ledger after the final independent review. Global milestone/release state remains unchanged.
