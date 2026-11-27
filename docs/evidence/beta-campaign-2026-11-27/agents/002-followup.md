# Worker 002 follow-up — shard split and recovery status review

**Identity:** `/root/a002_native_ci`; read-only review, no descendants. Original `002.md` preserved. Input `9e2313cbffb01d66249458c64087cb66c7652cca` plus four uncommitted files, subsequently committed unchanged as `c99eb6d2cd0a06c95cf9bbc4aabdf44b6ebed2b3`. Separately reviewed addendum: `3290bcce80ab2085bce91cef3e3c4b43ff50cfad`. Full method identities and file/evidence hashes are in `campaign/evidence/002/followup-review-receipt.json`.

## Verdict

**No blocking finding in the reviewed change. Accept for fresh Apple execution; no native/UI pass is inferred.** One nonblocking artifact-review omission was identified and resolved by the addendum.

## Required execution and proportionality

Independently compared exact class/method identities at the pinned base and candidate: **44 required UI methods before and after**, zero omissions, additions or duplicates. Twelve XCTest classes remain partitioned into six required shards plus one opt-in diagnostic shard. Counts are room 5, library 9, studio/export 11, beta 8, optics 10 and app accessibility 1. Beta comprises four `BetaWorkflowUITests`, three `PlanGestureUITests` and one `BetaAccessibilityUITests` method.

No `UITests` or `NativeTests` source changed in `c99eb6d`; every assertion, threshold and per-test deadline is preserved. The registry/workflow matrix agree. Both split jobs retain 40-minute command limits and 93-minute job budgets; `max-parallel: 5`, `fail-fast: false`, required execution, always-running exact accounting and finalized-result gates remain intact. The selected classes use fresh UUID test stores; splitting introduces no observed cross-class fixture dependency.

Original [run 46004241191](https://github.com/mirzotipi-wq/APP1/actions/runs/46004241191) evidence independently confirms 19 expected, 14 started, 9 passed, 4 failed, 1 incomplete, 5 unstarted and zero skipped. Its original command timed out at 40 minutes and lacked a finalized result. Splitting the enlarged workload into original 11 plus new 8 is proportionate: it adds one runner setup/build while keeping each command bounded. It cannot repair the four original assertion failures; those remain recorded and require their own evidence.

## Evidence and conditional behavior

The beta shard receives both trace start/end handling and diagnostic trace export. Generic shard-qualified full, compact and raw-xcresult artifact names prevent collisions; method accounting, raw-bundle preservation, uploads and failure propagation are unchanged. Diagnostics retain `continue-on-error`; required tests/accounting do not gain it. The original 28 app-accessibility captures remain required by the existing visual-review jobs.

Found `.github/workflows/review-xctest-evidence.yml:40` initially rejected the new beta compact artifact. Addendum `3290bcc` adds only `beta-workflows` to its anchored allowlist. Source/run identity, bounded names, original artifact selection, hash/provenance and missing/ambiguous artifact checks remain unchanged. A direct probe accepts all six required compact names and rejects four unrelated/malformed alternatives.

## Recovery label

`campaign/evidence/098/studio-export/recovery-excerpts.json` records the queried success identifier as **Image / “Selected”**, while the same hierarchy has **“Saved locally”** and the new-library save message. `App/ProjectLibraryRecoveryView.swift:185–199` changes only that Label to one accessibility element with the explicit visible message. The header trait, identifier, visible text/layout, adjacent recovery/import instructions and committed-operation lifecycle remain intact. Existing exact-label and relaunch assertions remain unchanged (`BetaWorkflowUITests.swift:213–254`). This addresses the evidenced semantic defect; visibility, relaunch durability and full runtime acceptance still require execution.

## Checks and limits

Independently ran **34/34 shard-tooling tests** and `git diff --check`, both passing; exact inventory and artifact-name probes passed. Root reports 104 full tooling tests; this reviewer did not rerun that full suite. No Apple compilation, native/UI test execution, mutation, commit, push or CI rerun performed. Worker 061’s separately integrated `071a99f` welcome-title probe and worker 096’s pending input trace are outside this review.
