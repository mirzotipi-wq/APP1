# Development completion checkpoint — 2026-11-24

**Active development; M01 remains active and M02–M07 remain pending.** This is a dated source and evidence checkpoint, not a release declaration. Protected milestone dependencies, acceptance thresholds and owner approvals are unchanged.

## Source and session identity

- Branch: `development/completion-20261124`.
- Session base: `d816a95714c3a8b5cb31c16f0be73e3c4c1982c2`.
- Recorded HEAD: `394e28e163be345b9db135d8a10a3a1dfafe6617`; tree: `842a26c25ed28d8a2a40fa3b3d81e97adcb438c4`.
- This session has **100 distinct specialist assignments**, including the records specialist and the final integration reviewer, as confirmed by the integration lead. Reusing an agent adds no assignments. The older repository checkpoint's 61 specialists belong to a separate session and are not added to this count.
- The prior `95e9c24` checkpoint, its counts, logs, failed evidence and handoff remain historical. No historical pass certifies the working changes after `394e28e`.

| Integrated commit | Implemented work |
|---|---|
| `57393463263635e3758c66e237b0e7f369863577` | Direct overhead-plan editing, subject controls and light management. |
| `10ba0ef9868a053142e31dda5b5bcad81dd6b769` | Native placement, photo comparison, measured-room exports and studio controls. |
| `394e28e163be345b9db135d8a10a3a1dfafe6617` | Editing transaction guards, geometry and export corrections, photo lifecycle handling, native workflow coverage and accurate implementation documentation. |

The implementation includes interactive RealityKit 3D; ARKit/RealityKit placement with a manual fallback; metric/imperial controls; modifier roll and scene arrangement; target-lux adjustment; bounded on-device reference proposals and explicit acceptance; session-only comparison photographs; persisted room measurements and PDF/text export; and StoreKit purchase/restore/entitlement code. These are implementation statements, not acceptance of physical tracking, calibration, inference quality or purchases. The StoreKit product identifier remains unconfigured and owner-approved feature gates are absent. See [README](../../README.md) for the current feature description.

## Exact-source CI observations

The integration lead supplied the observations below. This records packet independently read source/history and reconciled the ledgers; it did not rerun tests, poll CI, download additional artifacts or perform native/device validation.

| Source and workflow | Actual known results | Outstanding observation |
|---|---|---|
| `394e28e`, [run 45465026704](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704), [core job 138698953169](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138698953169) | **261/261 Debug, 261/261 Release and 28 Python passed.** | This pass belongs to the exact committed SHA and tree above. It does not establish a pass for later working source. |
| `394e28e`, [native job 138700428174](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428174) | Both unsigned Debug and Release builds succeeded. | Native tests were still running at **19:19 UTC**. **84 is the expected method inventory, not a passed or executed count.** No terminal native result is claimed. |
| `394e28e`, UI jobs [library 138700428157](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428157), [room 138700428256](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428256), [studio 138700428187](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428187) | At **19:16 UTC**, library/reference and room/precision were running; studio/export was queued. | No finalized current UI counts or full regression/persistence acceptance are available in this checkpoint. |
| `10ba0ef`, [run 45456830724](https://github.com/mirzotipi-wq/APP1/actions/runs/45456830724) | **257/257 Debug, 257/257 Release, 28 Python, both unsigned builds and 83/83 native methods passed.** Room UI completed **4/5**; library/reference completed **7/11**. | The five failed UI methods remain failed evidence at that source. No terminal studio or whole-workflow conclusion is inferred from these partial results. |

## Demonstrated failures and pending corrections

**Later native observation:** the finalized test log records **84 tests, zero failures**, with `All tests` passed at **19:22:31.329 UTC** and `TEST SUCCEEDED` at **19:24:15.669 UTC**. The measured-room PDF method passed (1.770 s); all four native PDF methods passed. Compact artifact **14956731360** contains the actual four measured-room exports. The artifact reviewer rendered and inspected all 32 pages at 95 dpi; no visible text clipping, row overlap, missing fixture labels or Letter footer collision was found. The lead separately inspected Letter/imperial page 5. These later observations supplement the earlier pending snapshot above; they do not certify physical devices or the working source after `394e28e`.

- **Room saved-state expectation:** the sole `10ba0ef` room failure expected the old saved state after changing room measurements. Room measurements now persist with the project. `394e28e` updates the scenario to require dirty state, Undo back to saved state without changing the saved modifier width, Redo, and a committed save. Actual native acceptance of the updated scenario is pending.
- **Library/reference:** four methods failed at `10ba0ef`. Two AX `Code=-56` timeouts remain unresolved. The project Keep flow was blocked by the iOS keyboard tutorial, demonstrated by the actual video. A stale “Other” button became disabled after broad UI scrolling moved Backlight to `-100 m`; the reviewed artifacts strongly support that explanation, but it is not a native event trace.
- **Working changes after `394e28e`:** queued NeutralCard cancellation, navigation from screen edges that preserves all acceptance assertions, and a test-only handler for the exact keyboard tutorial are being integrated/reviewed. Their source CI is pending. Do not invent the next commit SHA or reuse `394e28e` results as proof of these changes.

The current working-tree gates are therefore unverified. The ledger retains exact-SHA core/build passes separately and preserves historical failed evidence. Integration must obtain results for its own source, including original edit/Undo/Redo/save/relaunch expectations and actual reachable controls.

## Minimal added coverage

The `10ba0ef` → `394e28e` source diff adds **four portable test methods**, **one native PDF method covering four paper/unit combinations**, and **one simulator UI workflow**. Existing room and reference scenarios receive assertion updates; these are not extra test methods.

| Coverage | Scope and status |
|---|---|
| Four `DevelopmentGeometryTests` methods | Schema-five room/roll round trip and legacy schema four; quarter-turn AR geometry with authored heights and one-to-one distances; rolled downward-face transforms; floor/ceiling contact, crossing and unknown ceiling. Included in the exact-source 261-pass core totals. |
| `testMeasuredRoomPDFRetainsEveryRowInBothPaperSizesAndUnits` | One method, four combinations of paper and units; checks all room rows, pagination, modifier roll and extracted text. Passed within the 84 native methods at `394e28e`; genuine exports were subsequently rendered and visually reviewed. |
| `testSettingsFeet3DFitAndSimulatorARManualFallback` | One UI workflow covering unit preference, 3D fit and simulator fallback into manual measurements. Authored coverage only until its actual UI result is available. |
| Existing assertions | Room persistence/Undo/Redo/save and nested photo-comparison return preserve the original workflow checks. Native results pending. |

## Remaining gates and next packet

No configured commerce SKU, signed build, physical AR/Metal/performance evidence, calibrated rendering or held-out inference acceptance, customer validation, or owner release approval is supplied by this checkpoint. Older simulator Metal evidence remains historical and does not establish physical-device behavior. Feature presence and passing portable tests do not close those gates.

The cancellation, navigation and tutorial corrections have now received independent source review. The next integration also runs the three existing UI shards concurrently: the prior run left studio/export queued behind the other two. Selectors, assertions and per-step deadlines are unchanged.

Next: record the actual integrated source and tree; inspect finalized `394e28e` UI outcomes without rewriting the earlier observation; then verify the new source with its applicable core, unsigned build, native and UI checks. Preserve failures and original acceptance requirements. Update current counts and provenance only from actual results. M01 cannot close until all of its gates pass at an applicable source.
