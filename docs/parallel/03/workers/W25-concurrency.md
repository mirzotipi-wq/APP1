# W25 — cancellation/concurrency

Runtime/task: `/root/wave03/concurrency`; actual worker W25. Host: Linux x86_64; inspected 2026-11-26 UTC.
Input: `1cefc654630a86ab320e58283957f4e91d6cbce6`.
Private tree: `/tmp/keyfill03-7f4b/workers/W25-concurrency` (detached).

## Execution

Read the four assigned instruction/contract files. Actual checks: `git rev-parse HEAD`, `git status --short`, `git log -3 --oneline`, `git show --stat --oneline HEAD`, targeted `nl -ba`/`sed`/`rg` source reads and the target-file diff. Unchanged engine/preview handling was inspected only for cancellation propagation.

## Findings

- Sphere now matches mannequin ordering: resolution validation → preparation poll → camera/lighting/transform setup and buffers → pixel polls → final poll. Invalid resolution performs zero callbacks; precancelled valid resolution throws before camera setup. A false preparation poll still allows all setup/buffer work, or a setup error, before the next poll. StudyComputeInput retains its default-false setup callback.
- The shared countdown polls before pixels 0, 8, 16… across rows, including background/unsupported pixels. A false pixel poll permits eight evaluations before the next poll; a request at a completed-pixel boundary permits at most seven additional evaluations. This bounds pixels, not elapsed time, preparation, or per-pixel sample work.
- Successful CPU renders make `ceil(pixelCount/8)+2` callbacks. Sphere cancellation on callback 3 shifts from before pixel 16 to before pixel 8, matching mannequin. These are source-derived counts, not measurements.
- CPU callbacks are synchronous, nonescaping parameters; neither setup nor the countdown stores them. The first true poll throws immediately, with no subsequent renderer callback. The caller must synchronize externally mutated cancellation state. Direct renders default to false; the engine supplies task cancellation OR its retained additional callback.
- Cancellation throws outside the invalid-surface recovery block. Final cancellation prevents returning even completed pixels. Unchanged engine guards reject observed cancellation before cache admission; preview guards after await/before assignment suppress cancelled output and cancellation errors. A request arriving after the last relevant false guard can race with return/cache/publication: this is cooperative checking, not an atomic exclusion guarantee.

## Evidence, limits, disposition

Inspected tests cover three-mode setup precedence, eight-pixel boundaries, unchanged images, terminal callbacks and final rejection. No Swift build/test or simulation ran here. Root's existing logs, checked using `rg -n 'Executed 380 tests'`, separately record 380 Debug and 380 Release tests with zero failures; these are external executions, not W25 results. Native publication races were not exercised.

No blocking defect found. Final private status: `git status --porcelain=v1` empty; `git diff --exit-code` and `git diff --cached --exit-code` returned 0. No source edits or commit; only this assigned report was written for integration.
