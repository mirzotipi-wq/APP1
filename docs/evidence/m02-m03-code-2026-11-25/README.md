# M02/M03 code completion — 25 November 2026

## Owner-authorized scope

The owner explicitly requested 100 agents, sequential completion of M02 then M03, commits and pushes to main, CI repair, and removal of requirements that depend on unavailable outside factors. This changes milestone acceptance, not historical test results. Physical calibration, human reviews and real-device measurements will remain explicitly unperformed and will not be represented as code evidence.

## Execution

Baseline: `48c287c54ccaaa71fca4170615e7491551798aaa`. Three concurrent workers plus the integration lead, with separate contexts and nonoverlapping write scopes. Only the integration lead commits and publishes. Worker assignments and actual outcomes are recorded in `worker-ledger.json`.

1. Revise M02/M03 acceptance to concrete code-verifiable requirements while preserving historical records.
2. Complete M02 rendering, numerical and bounded-performance work and validate its source.
3. Complete M03 editor, persistence and accessibility implementation, resolve actionable CI failures, and validate its source.
4. Record exact tested revisions and final CI, advance the state only on evidence, commit and push all deliverable changes to main.

## Baseline verification

Local state check and next-action selector passed; next milestone is M02. All 35 Python tooling tests passed. The local executor initially has no Swift/Apple toolchain; Swift setup and existing GitHub CI are being used for executable verification.

## Current phase

M02 was accepted at source `90d36f9120289a33ff8af37d626ea959830ddd38` under `m02-m03-code-v2`, before M03 implementation began. Its [receipt](m02-acceptance.md) records338 Debug/338 Release tests,12 retained synthetic images, kernel/precision parity, bounded cache/cancellation, final optimized benchmark, and source-scoped Apple/Metal results. The initial native job is now terminal success with110 methods; subsequent historical UI outcomes are recorded in `validation/m02-additional-ui-results.json`, including both unchanged Apple audit failures.

M03 is active at candidate `40eb1de5ce8f055d52335328bfaca0a8bedb7ace`. The candidate repairs actual mode-button touch targets, large-text numeric layouts, selected-state contrast, exact fractional room-angle and spoken illuminance readouts, and stale selection callbacks. It also corrects standalone rotation and generic-mirror boundary rounding, with five regressions independently reviewed against exact arithmetic. It adds required default/largest-text app accessibility execution and native palette/readout tests, preserves all functional editing/library workflows, and accounts for every selected XCTest method. Apple full audits remain intact in explicit manual diagnostics. Preparatory simulator warm-up preserves its actual outcome and bounded same-device attempts as diagnostics; the actual selected tests, method accounting, Metal execution and finalized results remain mandatory.

The current [CI run](https://github.com/mirzotipi-wq/APP1/actions/runs/45688029379) has completed its core job successfully:343 Debug tests,343 Release tests,65 tooling tests,12 byte-identical retained images, six kernel cases, eight precision cases, optimized8/12/4 benchmark workloads, and actual Linux write-failure/interruption probes. The fresh CI filesystem type is unrecorded and is not inferred. See `validation/m03-40eb1de/core-receipt.json`. All117 native and35 required UI methods and actual default/largest-text screenshot review remain required before M03 acceptance. The [worker ledger](worker-ledger.json) records100 actual completed contexts and their individual reports/outcomes; worker completion does not substitute for pending native execution.

## Historical first implementation checkpoint

The candidate adds conservative one-sided-emitter culling, independently checked against69,126 baseline evaluations; lifecycle cancellation in the Study preview; a portable LRU cache with separate RGBA/mask limits used by the native rendering actor; and12 deterministic synthetic render fixtures with retained original-six pixels and machine-readable validation. Core Debug337/337 and Python35/35 pass. Six shared-kernel cases pass with maximum RGB error1 and matching unsupported masks. The seven-sample host benchmark retains identical output hashes and12 observed cancellation probes. Release337/337 also passed; Apple native validation is pending at checkpoint preparation. See `validation/m02-candidate.json` for exact source hashes and `renders/` for original CPU outputs and lossless PNG views.

Documentation-only updates now run a small state workflow; code changes retain native/core/UI CI. This prevents evidence publication from repeatedly scheduling unchanged simulator work. M02 andM03 are not marked complete by this checkpoint.
