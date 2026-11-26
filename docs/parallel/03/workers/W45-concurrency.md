# W45 — cancellation and evaluation work bounds

**Recommendation: ACCEPT, scoped to W44’s preservation of cancellation/work bounds and publication boundaries.** No concrete counterexample was found. This is static review and arithmetic evidence, not an executed Swift/concurrency pass.

- Input: `c9ff1a71c173774e7b7c794e475f8bdf5d633853`; private detached tree `/tmp/keyfill03-7f4b/workers/W45-concurrency` was clean at inspection.
- Reviewed actual candidate: `wave05-evidence/W44-ReferenceStudy.swift`, SHA-256 `4ac702653392d64586d0a472576da64ebe3f68dad7339954232f7c5f6635b141`; patch SHA-256 `b6f355709bbf68f51c738c95ba15770c6d4f01c5a2133e1c35f283afd983c3a8`.
- Persistent evidence: `wave05-evidence/W45-static-checks.json`, including exact baseline ReferenceStudy, PortraitStudy and cancellation-test hashes. No temporary-tree artifact is required to retain the result.

## Falsification findings

Positive-emitter inclusion, sample allocation loops, geometry and sample dispatch remain unchanged. Point/directional sources still evaluate one sample; rectangles still evaluate at most 8² = 64 interactive or 32² = 1024 reference samples. Clipped columns emit at most `grid` rows each. Normalization changes intensity arithmetic only. In particular, `accumulate` has no lux-zero early exit: old underflow did not skip visibility/material evaluations. Thus tiny and ordinary positive intensities follow the same geometry-dependent sample/visibility evaluation counts, including early surface rejection. There is no recursive render, replay, extra pixel, or extra sampling pass. Constant per-emitter arithmetic increases; an unchanged time budget is not claimed.

The new `defer` belongs to each `while` iteration. Point/directional `continue`, rectangle back-face `continue`, empty clipping and normal completion all restore `previous + scaled group` exactly once. Empty/skipped groups add zero. Throws also run the defer, then discard the evaluator’s local accumulators; no partial signal escapes. Rectangle samples remain contiguous and the unchanged index advances consume their complete group. Ordinary scale-one groups never reset or rescale totals.

`outputScale` is a value field in private `Sample`; prepared samples and guards remain private `let` arrays. Evaluation reads `let sample` and mutates only call-local totals. No shared mutation, escaping task or new synchronization boundary appears.

Both renderers retain preparation cancellation, a checkpoint before every pixel and final cancellation before returning an image. The mannequin maximum remains 144. W44 introduces no cache access or publication path and does not catch a render cancellation/failure. Cache/publisher behavior was not executed here; this acceptance concerns absence of a newly introduced bypass.

## Executed evidence and remaining verification

Ran Python byte comparisons of unchanged `accumulate`, clipped sampler, sample dispatch through EOF, and public image/renderer/cancellation sections: all matched. Ran an integer model at 32 successive false-poll positions: exactly eight further pixels each; this is arithmetic, not Swift execution. Checked unchanged relevant call-site counts and 64/1024 loop bounds.

Read existing `StudyCancellationTests.swift`. **Swift, builds and runtime cancellation/publication/cache tests: UNRUN by W45.** The parent’s reported W42 166-check baseline/candidate result is external attribution, not a worker pass. Minimal root verification: run existing `StudyCancellationTests` on this exact integrated candidate and retain its final-checkpoint no-frame result; preserve the existing failed/cancelled cache admission verification. No new test churn requested.
