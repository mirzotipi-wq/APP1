# A078: simulator startup budget failure review

Reviewed source: `135d3b4755d97bbb8fcff993d8dfd532a8d48b93`. This was a read-only repository review with private synthetic-tool probes. No Apple simulator ran, no CI retry was requested, and no threshold or source changed.

## Actual CI failure

Run `46030746634`, core job `140613601950`, failed `test_two_postflight_timeouts_exhaust_same_budget_after_one_recovery`: `report.elapsedSeconds` was `3.4117361060000064`, failing the strict `< 3.15` assertion. The immediately preceding `< 3.5` outer wall-time assertion passed. Earlier assertions in the same test also passed: both postflights were timed out, both direct children were reaped, exactly two boot calls and one shutdown occurred, and the helper returned a failed status.

The test temporary directory discarded its command receipts. The job log preserves the failed assertion but cannot show when that runner actually killed/reaped the children or how much time it spent saving diagnostics. Therefore the specific cause of the CI overrun is not established.

## Deadline accounting

A three-second fixture allocates a 0.3-second cleanup reserve, producing one fixed work deadline at 2.7 seconds and a first-attempt deadline at 1.35 seconds. Recovery does not reset this budget. Every command clamps its deadline to the same work deadline; cleanup waits are bounded by the remaining total deadline. Production remains 580 seconds by default, at most 600 seconds accepted, with a five-second cleanup reserve and the separate workflow step bound.

`report.elapsedSeconds` is sampled during finalization, after command JSON writes, incremental report saves, attempt bookkeeping and failure reporting. It is not a direct child-stop timestamp. Synchronous reporting and host scheduling can therefore make that value exceed a command deadline without establishing that new work was started or a timeout budget was reset. The current source rejects unsuccessful/late readiness rather than granting a false ready result.

## Probes actually run

`python3 a078-evidence/probe.py` executed the exact unchanged test method twice with its existing assertions. Both passed. Final report times were 2.702612 and 2.702815 seconds; outer times were 2.801140 and 2.771841 seconds. Every command deadline was at or before 2.7 seconds and every direct child was reaped. Exact original reports, command receipts and call lists are preserved in `baseline-1/` and `baseline-2/`.

A separate, explicitly instrumented probe injected a 0.65-second delay in the final postflight's result-file write, after that command's child had already been killed and reaped. Its command finished at 2.701316 seconds, while its final report time was 3.357150 seconds. It retained the failed helper result, fixed command deadlines and reaped children. This demonstrates one possible reporting-time mechanism for the strict assertion, not the actual GitHub runner's cause. All injected results are segregated in `injected-report-delay/` and marked in `receipt.json`.

## Recommendation

Keep the observed CI failure and current deadlines unchanged. The newer source run's passed tooling stage is separate evidence, not a deletion or causal repair of this failure. No production startup-budget defect was established by this review, so a speculative timeout increase or source change is not justified.

If this timing assertion recurs, first retain the synthetic fixture's bounded per-command report/call receipts on failure, then distinguish command waiting, child cleanup and diagnostic-write time. A separate deterministic deadline-accounting test could strengthen causal coverage while the real-process cleanup tests and production deadlines remain intact. Do not call the injected reporting delay a reproduction of the CI runner's actual fault.
