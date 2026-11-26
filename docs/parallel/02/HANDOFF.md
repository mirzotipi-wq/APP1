# Lane 02 handoff — corrections published; campaign interrupted

## Status

Branch: [finish/02-photometry-color](https://github.com/mirzotipi-wq/APP1/tree/finish/02-photometry-color).

**The code and evidence below are published. The requested 100-context campaign is incomplete: 18 actual fresh contexts completed; 82 were not created.** Wave 01 completed10/10. Wave 02 completed8/10. Waves 03–10 have not started.

The execution host disconnected and its45-second recovery attempt timed out; the environment then explicitly reported unavailable. Source checkpoint `58b3ca43943e18d0fc7800189b08365f424d9c9e` had already been published and its remote SHA and identical Git tree verified. Subsequent closure documentation uses the connected GitHub tools because local execution is unavailable. Do not claim automatic continuation or100 completed workers.

Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`, the requested fallback. No lane 20 campaign baseline was published at startup. Inspected main `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318` is preserved for integration. Lane 01's inspected campaign at `db6de5841e2810fce48299fb7c00a68d284f00d6` uses the same fallback and owns Scene/composition. No public signature or scene-schema changes were made.

## Corrected mathematics

1. **Rolled rectangle normal:** normalize the cross product of the represented unit axes before evaluating plane separation and emission. Raw cross products can be shorter than one after rounding, causing valid exact-minimum-depth receivers to return unsupported. The independent matrix formerly produced120 unexpected unsupported results; the corrected matrix produces zero. A nextDown regression proves that distances strictly below the documented minimum still reject; no epsilon widens the domain.
2. **Tiny rectangle output:** below the cell-division precision boundary, integrate the geometry at1cd and apply requested intensity once. Ordinary output keeps the established sampling/summation path. A valid tiny intensity previously returned zero or16.225% relative error in the demonstrated fixture.
3. **Finite XYZ boundaries:** scale chromaticity before summing when the finite components' sum overflows. At very large display inputs, cancel their common scale analytically in the Reinhard denominator before adaptation/exposure can overflow. Normal scene-range color arithmetic and Float32 compute parameters remain unchanged.
4. **Solver explanation:** output errors now describe numerical representability as well as the candela range. Forward validation remains1e-9, maximum output100000cd, and max.nextUp rejection remains enforced. The former computational-underflow rejection fixture now verifies exact achievable lux; a separate5cm point fixture verifies rejection of a genuinely unrepresentable output. Original failed expectation and initial test compile error are retained.

Changed production files are SurfacePhotometry.swift, Colorimetry.swift and LightOutputAdjustment.swift. StudioOptics.swift was inspected and exercised without an unnecessary rewrite. Renderer, UI, export, schema, CI and canonical milestone files remain with their owners.

## Numerical evidence

Production Swift is compared to an independent spherical-edge projected-solid-angle integral, rather than the production midpoint/Gaussian area integrator.

| Model | Cases | Maximum relative error | Frozen limit |
|---|---:|---:|---:|
| Point |64|2.220446049250313e-16, or2.22e-14%|1%|
| Rectangle |1440|0.0021568264589441055, or0.2156826459%|5%|

There are zero unexpected unsupported cases after the correction. The relative-error groups contain40 positive point and1025 positive rectangle rows; the remaining nearzero/dark rows have exactly zero absolute discrepancy. See [REFERENCE-METHODS.md](REFERENCE-METHODS.md) for the complete declared dimensions, separations, rolls, offsets, normals and nearzero rule. These are measured test cases, not a proof for every possible floating input.

The worst rectangle is4×0.05m at1m separation and offset(3.2,0.025)m: reference34.08463164138468lx; Swift34.01111700601718lx. The [raw CSV rows](evidence/sweep-rows) and [summary](evidence/spherical-reference-summary.json) are retained. Root recomputed the maxima again from the published GitHub CSV after the outage and obtained the same values.

A separate oblique37°rolled partial-face fixture compares production133.78670187496377lx with independent Simpson133.78670191052524lx (relative2.65807e-10). Its regression was integrated and executed in the current full suite. Worker reports also retain analytic, geometric-invariance, nil/zero/error, determinism and consumer checks.

## Actual validation

- Baseline f150:366 Debug tests passed, zero failures.
- First candidate:372 Debug tests passed locally;10 targeted solver checks passed after the explanatory wording update.
- Current code inputs at58b3ca4:374 full Debug tests passed locally, zero failures,13.441s test execution;26 targeted photometry checks also passed. Source/test SHA256 manifests and full logs are in evidence/.
- CI at earlier f75aa27:372 Debug,372 Release,100 tooling tests and six shared-kernel parity fixtures passed. macOS core372 also passed. This is earlier-source evidence, not a substitute for revalidating the rolled-normal correction.
- Current-source [run45819324337](https://github.com/mirzotipi-wq/APP1/actions/runs/45819324337) was in progress at the outage closure. Inspect its terminal result before claiming current Release/CI acceptance.
- Earlier native job failed `UITests/StudioAppAccessibilityUITests.swift:95`, ambiguous greatestFiniteMagnitude inherited from f150. Main's b0d25ee supplies the explicit CGFloat correction; lane 20 should retain it during integration. This branch does not claim a passing native/UI run.

Local platform: Debian13 x86_64, portable Swift6.0.3. Package builds used one job and private outputs; small worker probes used an immutable compiled module, private executables and a shared build lock. No local Apple SDK, GPU execution or physical-device validation was performed.

## Workers and retained artifacts

[worker-ledger.json](worker-ledger.json) records exactly18 tool-returned canonical identities, inputs and outcomes. Per-wave ledgers retain source-specific original evidence. All initial contexts were fresh; reused followups are not additional workers.

Wave 01's10 worktrees were removed only after every recorded artifact hash matched the verified remote5579b4f checkpoint. Wave 02's remaining local state cannot be inspected after the outage. R07's complete report and probe are published. R08's returned assessment is preserved as [recovered-handoff.md](reports/w02/w02r08/recovered-handoff.md); its original local report/probe files are not claimed recovered. R09 never spawned. R10's attempted spawn returned no ID and is excluded from counts.

Working token budgets were briefing targets; exact consumption was not instrumented. Their values did not change platform context limits.

## Remaining work and resumption

1. Restore a working execution environment; clone this branch and verify remote HEAD. Measure free RAM/disk and read repository instructions. Recreate temporary private worktrees; do not assume old/tmp paths or binaries survived.
2. Inspect current CI. Retain later-main changes for lane 20 integration; push only this lane branch.
3. Finish W02R09's small platform/performance probe and W02R10's independent CIE1nm reference table. The official CSV checksum/provenance is published, but the requested worker/table is not complete.
4. Execute all ten distinct roles in each remaining wave03–10 using [WAVE-TASKS.md](WAVE-TASKS.md). Root can schedule three workers concurrently once no separate coordinator is active, respecting the four-slot total. Record actual IDs only.
5. Review the R08 request for clearer recovery actions in three generic error messages. Reconcile the [consumer requests](CONSUMER-REQUESTS.md), including the out-of-scope Scene.normalIlluminance distance overflow and renderer tiny-intensity behavior.
6. Complete current-source Debug/Release and independent challenge evidence, preserve numerical limits, then issue the final completed campaign handoff. Do not promote canonical milestones from this partial lane result.

All accuracy claims concern ideal models. No physical calibration, measured equipment/camera response, release readiness or finished100-worker campaign is claimed.
