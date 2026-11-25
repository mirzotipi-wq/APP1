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

## First implementation checkpoint

The candidate adds conservative one-sided-emitter culling, independently checked against69,126 baseline evaluations; lifecycle cancellation in the Study preview; a portable LRU cache with separate RGBA/mask limits used by the native rendering actor; and12 deterministic synthetic render fixtures with retained original-six pixels and machine-readable validation. Core Debug337/337 and Python35/35 pass. Six shared-kernel cases pass with maximum RGB error1 and matching unsupported masks. The seven-sample host benchmark retains identical output hashes and12 observed cancellation probes. Release337/337 also passed; Apple native validation is pending at checkpoint preparation. See `validation/m02-candidate.json` for exact source hashes and `renders/` for original CPU outputs and lossless PNG views.

Documentation-only updates now run a small state workflow; code changes retain native/core/UI CI. This prevents evidence publication from repeatedly scheduling unchanged simulator work. M02 andM03 are not marked complete by this checkpoint.
