# Lane 02 handoff — code verified; worker campaign interrupted

## Status and published source

Branch: [finish/02-photometry-color](https://github.com/mirzotipi-wq/APP1/tree/finish/02-photometry-color).
Latest implementation checkpoint: **87dd5ad55a6cb5ee8c40cc430952ef577bc8fce7**.
The branch ref was verified through GitHub after local execution failed.
Subsequent closure commits change documentation/evidence only.

**The requested 100-context campaign is incomplete: 49 actual fresh contexts
were created; 47 assignments completed, two are blocked, and 51 contexts were
not created.** Waves 01–04 completed ten roles each. Wave 05 has seven completed
roles, two blocked roles and one uncreated role. Waves 06–10 have not started.
See [worker-ledger.json](worker-ledger.json) for all actual canonical IDs.

The executor disconnected during wave 05. Its recovery attempt timed out after
45 seconds, and the environment explicitly reported unavailable. All dispatches
and execution attempts stopped. Code, tests, the six-completed-role checkpoint
and completed reports were already published. Cloud GitHub tools preserved
this closure and verified current-source CI. There is no automatic continuation
claim and no passing result assigned to blocked or uncreated work.

Baseline remains **f150f98e35dd735927075aac4d2f8b02295c6a67**, the requested
fallback because no lane 20 BASE_SHA was published at the inspected checkpoints.
Last inspected main was9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318. Lane 01's
966c9c21adbb685d82127e7f88981b74daf47e3d composition contract was inspected;
its target-lux admission uses exact light UUID/snapshot and live
presentation/generation/revision ownership. No shared signature/schema change
is required. Native route admission remains that owner's work.

## Corrections and regression coverage

1. **Rolled rectangle normal.** Normalize the represented right×up cross
   product before treating its projection as a distance. A short rounded normal
   formerly rejected valid exact-minimum-depth receivers. The independent
   1,504-row matrix previously contained120 unexpected unsupported outcomes;
   it now contains zero. Regression cases retain strict nextDown rejection.
   No separation epsilon or acceptance-domain widening was introduced.

2. **Tiny rectangle output.** Integrate at unit intensity below the cell-division
   precision boundary, then multiply by requested intensity once. This preserves
   representable lux that premature per-cell or radiance division erased.
   Ordinary integration and summation order remain unchanged. Normal
   normalization intentionally changes some rotated rounding, so there is no
   universal bitwise-equivalence claim. Both full and clipped-face independent
   boundary regressions execute.

3. **Finite XYZ boundaries.** Normalize chromaticity before summation when
   finite components overflow their sum. For enormous finite display inputs,
   cancel their common scale analytically in the Reinhard denominator before
   adaptation/exposure products overflow. Ordinary scene-range arithmetic and
   Float32 compute parameters remain unchanged. These API boundary repairs do
   not expand the GPU's supported Float32 domain.

4. **Target-lux recovery guidance.** Three existing error descriptions now give
   concrete setting/scene/target recovery actions. The four error cases,
   signature,100000cd cap and1e-9 forward-ratio accuracy gate remain unchanged.
   A different positive target covers both excessive and extremely small
   unrepresentable requests;0lux explicitly turns the selected source off.
   New oblique point/directional/rolled-rectangle round trips verify the
   inverse/forward contract. Earlier updates distinguish now-achievable tiny
   rectangle targets from genuinely unrepresentable point targets.

Changed production files are SurfacePhotometry.swift, Colorimetry.swift and
LightOutputAdjustment.swift. StudioOptics.swift was inspected and exercised.
Renderer, UI, export, scene schema, CI and canonical milestone files remain
with their owners. The latest source differs from tested58b3ca4 only in the
LightOutputAdjustment error strings; all other30 LightingCore file blobs match.
The exact comparison is retained in evidence/ci-87dd5ad/source-equivalence.json.

## Numerical results and supported domains

Requirements remain **≤1% supported point** and **≤5% declared rectangle**.

| Independent comparison | Cases | Maximum relative error | Percent |
|---|---:|---:|---:|
| Scalar point inverse-square/cosine |64|2.220446049250313e-16|2.22045e-14%|
| Spherical-edge rectangle reference |1440|0.0021568264589441055|0.2156826459%|
| Independent directional double cosine |1|0|0%|
| Arbitrary off-axis directional scalar reference |1|2.8716355540e-16|2.87164e-14%|
| Rolled oblique37° Simpson reference |1|2.65807e-10|2.65807e-8%|
| Held-out−63° grazing Simpson reference |1|2.528440804957476e-12|2.52844e-10%|
| Clipped-face antiderivative, unit intensity |1|3.8554755827258091e-5|0.0038554756%|

The rectangle maximum is a4×0.05m face at1m depth, offset(3.2,0.025)m:
reference34.08463164138468lx, Swift34.01111700601718lx. Relative aggregation
uses40 positive point and1025 positive rectangle rows. The24+415 dark/nearzero
rows have exactly zero absolute discrepancy. These are declared cases, not an
exhaustive floating-point proof.

The point sweep covers0.05–50m and receiver angles0–180°. The rectangle matrix
covers0.05–4m sides, aspect ratios up to80:1, rolls0/37/90/179°, multiple offsets
and receiver tilts0/35/80/100/130°. Required plane separation remains at least
max(0.05m,longestSide/4). Invalid active photometric samples return unsupported; valid back-facing
geometry returns zero. Aggregate previews may skip off sources; a zero target
turns off a validated source without requiring a photometric sample. Full input lists and nearzero rules are in
[REFERENCE-METHODS.md](REFERENCE-METHODS.md), with raw rows and independent
programs under evidence/sweep-rows and reference/.

The held-out−63° grazing fixture uses0.405m depth with a0.4m minimum and only
6.77123% of its face contributing. Fixed Simpson refinement converges to
10.232645081164865lx; Swift returns10.232645081190737lx. The tiny clipped
fixture preserves one least-nonzero lux step from eight least-nonzero candela
steps. That is a numerical-boundary witness, not a practical lamp claim.

### Color reference limitation

Actual Swift blackbody output was compared at eight temperatures with official
CIE1931 2° data,1nm Planck integration and verified dataset hashes. Maximum
Euclidean xy difference is0.0153932977184 at1000K; at3200K it is0.001411992226,
and at5600K0.000400943957. The documented analytic observer approximation
dominates; wavelength cutoff and5nm sampling are separately characterized.
This is not an invented color-accuracy gate or physical calibration.
The full table, component differences, provenance and CC BY-SA4.0 attribution
are in reports/w02/w02r10 and [NUMERICAL-RESULTS.md](NUMERICAL-RESULTS.md).

## Actual validation

Current-source [CI run45831513382](https://github.com/mirzotipi-wq/APP1/actions/runs/45831513382),
core job139949454379, completed successfully at87dd5ad with Swift6.4.2,
x86_64 Linux:

| Check | Actual result |
|---|---|
| Full Debug package suite |377 passed,0 failures;11.163s test execution|
| Full Release package suite |377 passed,0 failures;4.595s test execution|
| Tooling suite |100 passed|
| CPU/shared-kernel parity fixtures |6 passed; no actual GPU execution claim|
| Precision fixtures |8 passed|
| Original generated PPM hashes |12/12 identical to58b3ca4|

Full original CI log parts, exact parity lines, image hashes, source comparison
and summary are retained in evidence/ci-87dd5ad. CI artifact15121304631 has
zip SHA256 f6b1173a07bd21f3f158dcbc9ecd939c9ba3e1d7dc618459a6f83e8ac5e9b3c9.

Local Swift6.0.3 targeted checks also passed: the independent directional test
1/1, tiny clipped-face test1/1, and latest solver suite11/11. The latter command
took7.472s including build/lock wait, with171808KiB maximum child RSS measured
on Linux. These are host process diagnostics. One-job package builds and locked
private probe compilations stayed within measured RAM/disk; there were four
agent slots total.

Earlier source58b3 passed374 Debug/374 Release tests. Current-source native/UI
jobs were queued at the latest inspection and are **not passed**. Earlier58b3
simulator/app-accessibility builds failed the inherited ambiguous
greatestFiniteMagnitude at UITests/StudioAppAccessibilityUITests.swift:95.
Lane 20 should retain main's b0d25ee CGFloat fix during integration.
No local Apple SDK/device run or physical calibration was performed.

## Workers, preservation and exact interruption

Every actual worker received an isolated detached sparse Git worktree and
private output. All initial contexts were fresh. Recovery followups reused the
same IDs and never increased counts. Brief/report limits and12000/24000 working
budgets were targets; exact working-token consumption was not instrumented.
Six-completed checkpoints and coordinator budget checkpoints are retained.

The second executor replacement erased temporary wave04 outputs. R01–R05
regenerated real evidence in their original contexts. All ten wave04 roles
eventually completed. Its63 recorded artifact hashes matched verified remote
3889f09 before only those ten completed owned worktrees were removed; the
shared SDK was retained. Wave01 preservation/cleanup was verified earlier.
Historical losses and failed attempts remain documented.

Wave05 closure:

- R01 acceptance and R02/R03/R04/R05/R06/R08 assignments completed; original
  reports and raw evidence are published.
- R07 is a **blocked partial** consumer audit. Its returned findings are saved
  in reports/w05/w05r07/recovered-partial.md. Original App captures were not
  inspected, report.md was never written, and original raw survival is
  unverified. Its provenance-field mistake is disclosed.
- R09 is **blocked/unexecuted**: the first exec failed before reads, checks or
  writes. Its actual creation is counted.
- R10 was not spawned; waves06–10 were not spawned.
- Planned v2-module/wave06-worktree creation did not execute after the failed
  session wait. Do not assume those paths or any old/tmp outputs exist.

## Consumer requests and next executable work

[CONSUMER-REQUESTS.md](CONSUMER-REQUESTS.md) records concrete owner paths and
acceptance requirements: lane01's unreachable-in-scenes public distance-overflow
helper and input-string bounds; CPU per-cell tiny-output scaling; explicit
Float32 packing eligibility; editor identity/admission and error presentation;
single-light target versus total-rig lux; export receiver/ideal-model wording;
and native baseline correction for lane19/20. No owner acknowledgement or
completed consumer patch is claimed.

1. Restore execution, clone this branch, verify remote HEAD, inspect instructions
   and current lane20/lane01/main state, and measure RAM/disk.
2. Recreate private worktrees/toolchain/module. tools/resumed-* retain the
   state/harvest/probe/publish helpers and bounded briefs. Build a new snapshot
   from the actual current source; do not assume an old READY file exists.
3. Finish existing W05R07/R09 contexts when available, then launch fresh W05R10.
   Preserve exact counts and disclose any unavoidable context replacement.
4. Execute all ten fresh roles in each remaining wave06–10 using WAVE-TASKS.md:
   color/exposure, consumer contracts, reproducible sweeps, independent
   challenges and final delivery. Do not call completed baseline tests those
   still-unperformed campaign assignments.
5. Revalidate any future edits, preserve artifacts before cleanup, push only
   this branch and verify remote SHAs. Update the completed handoff only when
   actual execution supports it.

All numerical accuracy claims concern ideal models. The campaign and full
native/UI acceptance remain incomplete; release readiness is not claimed.
