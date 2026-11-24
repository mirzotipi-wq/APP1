# Export lifetime and slider transactions — checkpoint 9

Integrated main **`3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`**, exact tested tree **`0ff9fa32a412534af0e11629e442f0a46a1176a0`**, parent **`816e7123cafbf214bef47e09d3e14abd993a83c7`**. The lead pushed and independently read back this linear main update. The source/tree identity also matches local Git. Twelve commits have been pushed since the session baseline `968e4bb1b3932c5140b735b404c9538d909bab23`; no new branch or force-push was used.

## Implemented correction

The export control captures project name, scene value and text settings in one immutable snapshot and presents one sheet. PDF/editable-copy selection changes content inside that existing presentation. Cancel, Done, reopening and alternate formats retain their original no-save/no-history-change contracts. The full-library export path remains available. The observed source-six stalls support correcting the shared presentation boundary; no process stack proves a specific internal framework cause. [Export diagnosis and correction](export-native-correction.md).

Slider-origin writes now begin the captured owner transaction before their first changed value reaches the validated binding. The standard native begin/end callbacks still use the same owner; accessibility adjustments explicitly complete their commands. Precision entry retains its discrete binding. The original optics assertion requiring one Undo to restore0.6m remains unchanged. The baseline-equivalent early-write path reproduced0.8500000000000001m, but no native internal callback trace proves that exact ordering caused the old UI failure. [Slider correction and retained before/after evidence](slider-native-correction.md); [independent review](export-slider-review.md).

## Exact local verification

Tests ran against immutable `cycle9-source`, not the subsequently changing working tree, with Swift6.4.3 on Debian13 x86_64.

| Verification | Actual result | Scope |
| --- | --- | --- |
| Complete portable Debug |251/251 passed, zero failures;11.817s XCTest aggregate | Source9 LightingCore suite |
| Complete portable Release |251/251 passed, zero failures;5.030s XCTest aggregate | Same exact source/configuration |
| Python checks |28/28 passed | Evidence, CI and shard validation |
| Native Swift syntax, state, shards, source icon/privacy | Passed | Syntax/structural checks, not Apple SDK/native acceptance |
| Actual slider adapter plus unchanged history tests |23/23 Debug and23/23 Release passed | Separate isolated Linux suite:8 adapter methods plus15 history methods; not additional core methods |

The unchanged portable count is expected: the new eight adapter tests belong to the native app target. Static inspection of exact source9 identifies **50 native XCTest methods**, including those eight, and **22 UI scenarios in six classes**. These are authored counts; no source9 native method is represented as executed here. Linux elapsed times are not device frame-time or performance measurements. Raw host timestamps are retained despite the known offset from connector UTC.

## Current and historical native evidence

[Source9 workflow45377378521](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521) was **pending** at the direct10:44:03UTC observation on2026-11-24, associated with exact source`3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`. Its Apple SDK build/unit/UI acceptance remains **unverified**.

Source8's actual [native job138376166742](https://github.com/mirzotipi-wq/APP1/actions/runs/45373901992/job/138376166742) subsequently completed success: both unsigned builds and **42/42 native methods passed**, zero failures,24.194s aggregate; `TEST SUCCEEDED` at10:40:33.55UTC. All three SpatialPreview methods passed, including the two that failed atff8b683. The lead retrieved the complete actual log, retained as [816e712-native-job.log](816e712-native-job.log). The finalized native artifact14912690366 is63,965,426bytes with SHA-256 `6e2b9952965b939a13c84f134bc4d2bedb50bdfaf770cfaed0420bbd5133e781`; compact artifact14911681485 is separately available. These results establish the earlier scene correction at816e712, not source9 acceptance.

Source 8 core job 138374870845 passed 251/251 Debug, 251/251 Release and 28 Python. Its UI test steps were cancelled and finalized-result export failed. Subsequent inspection of the actual partial artifacts establishes both a real failure and incomplete methods:

| Shard | Actual partial execution | Evidence limits |
| --- | --- | --- |
| Room/precision | Two room methods started. `testManualRoomReportsOutOfBoundsWithoutChangingStudio` failed its initial “All 5 center positions” status predicate after 96.714s. Resize/notes then started and was interrupted. | No precision methods ran. The committed 6m note assertion passed within the incomplete second method; this does not make that method a pass. The status failure cause is unobserved because the result bundle did not finalize. |
| Library/reference | Archived deletion passed in 294.945s. Create/duplicate/rename then started and was interrupted. | Recovery/reference did not run. |
| Studio/export | Cancelled without steps. | No execution or pass claimed. |

The [room partial log](816e712-room-partial.log) and [library partial log](816e712-library-partial.log) preserve these outcomes. Room artifact 14911432315 is 23,955 bytes, SHA-256 `d11c8817e32ef490b988fdfaad49bf450798b1084bebe9758e3ee2f22e29ecff`; library artifact 14912421351 is 23,000 bytes, SHA-256 `66c327decc92979f7c3f60e8ab6a68abaae7d96851d5e1a1e3a0a801728aba61`. Each contains six text logs, without a finalized result bundle. Source 8 regression therefore includes an actual room failure; cancellation does not erase it. No complete UI pass follows from native-unit success.

Source6 `ff8b683` remains an actual failed run: native40/42, library/reference7/8, room/precision4/5. Studio/export started9, completed8 with4passed/4failed, and interrupted bust switching at its32-minute test-step limit, without a finalizedxcresult. Actual corrupt-storage, meter, recipe and study-frame passes are preserved alongside export stalls, app termination and optics Undo failures. [Checkpoint8](checkpoint-8.md) and [unaltered artifact log](ff8b683-studio-export-native-tests.log) retain that evidence.

## Progress, remaining gates and next packet

Source9 completes **19 substantive packages,37 actionable tasks,nine full local integration cycles and12 pushed commits**. Actual workforce remains **61 specialists**:60 scheduled across10 waves plus the named read-only SceneKit child review. Follow-up reuse adds no agents.

M01 remains active. Every source9 native gate is unverified until its own run supplies evidence; the historical816 build/unit pass is not transferred to it. No95/100 or release-readiness claim is made. Physical calibration, device performance/thermal/accessibility, actual sharing/provider behavior, inference, AR, commerce, customer validation, signed distribution and owner approval remain open.

KF-032 asynchronous library work is authorized and in progress with the existing performance specialist. A focused room-status accessibility/diagnostics correction and a main-workflow completion policy change are also forthcoming changes outside this source; neither is represented as tested or integrated here. It is **not part of3b2a4ce**, has no test/push result at this checkpoint and is not counted as a tenth cycle. Continue that isolated packet while checking source9's actual native results; integrate only after its own verification and explicit captured-scene/stale-result safeguards.

## Exact raw-log identities

| File | SHA-256 |
| --- | --- |
| [cycle9-debug.log](cycle9-debug.log) |`b7c812dcb86da9b478022ea6d6a19b3d0d7f37308a33d0817bbfc7f6ed5abc6d` |
| [cycle9-release.log](cycle9-release.log) |`2ccdaf1f43836c8ab9f7da2a2b39adb0bf19f9e626f78224103863ef47da1682` |
| [cycle9-python.log](cycle9-python.log) |`f213a719806c1c36d7314e966aa5e2c96f150b528d17bd47b65fbf6658a582ed` |

The retained source 8 native log SHA-256 is `a81f03ea13d284e94642925ecc8e7598a73e8b6cf62dafb2a9e694cea46f8b66`; room partial log `d0b42ff20cd11de8ce7e2438417c30275936a8f4b0e14ccf250a99729c975545`; library partial log `2bc33ee0dfb34c50a9d82c4c199f4dc45e3bf0162c55bd8eafd2d2bb1a26c23e`. These extracted log hashes differ from their containing artifact hashes.
