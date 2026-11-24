# Studio/export CI completion allowance

## Change

This isolated patch changes only `.github/workflows/ios-prototype.yml`, based on source 11 `95e9c2446b7bb05e6df38d103063b4254bb07c92`. Each existing matrix row receives explicit integer `ui_test_minutes` and `job_minutes` fields:

| Shard | UI step | Entire job | Reserve beyond Metal 12 + build 25 + UI |
| --- | ---: | ---: | ---: |
| room-precision | 32 min | 85 min | 16 min |
| library-reference | 32 min | 85 min | 16 min |
| studio-export | 40 min | 93 min | 16 min |

Only studio/export gains eight minutes. Its evidence comes from the actual source-10 timeout described in `source10-studio-analysis.md`: approximately 621 seconds before the first method, 1,273.123 seconds for the first eight completed methods, and only approximately 39 seconds left for the final scenario before the explicit cutoff. The prior complete run of that final scenario took 43.555 seconds. XCTest bundle finalization also had not completed at the timeout.

This is an allowance for completing CI verification. It does not improve application speed, explain the observed app-idle warning, guarantee a future run will finish, or erase the actual optics failure. Source 11's already-running workflow is untouched.

## Mechanics

The existing three-value `shard` axis remains. One `include` record augments each matching row with both budgets. No include record introduces a new shard, and every existing row has exactly one explicit budget pair. Retaining the original axis also preserves compatibility with the existing fail-closed `native_test_shards.py` validator without changing that script.

Job timeout reads `${{ matrix.job_minutes }}` and the selected UI test step reads `${{ matrix.ui_test_minutes }}`. GitHub's current [contexts reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) permits the matrix context at both timeout keys. Its [matrix include documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstrategymatrixinclude) describes augmenting matching original rows when their axis values are not overwritten. The stored values are YAML integers, not string coercions or conditional arithmetic.

## Executed validation

- PyYAML 6.0.3 parsed the candidate. `validation.json` records the actual parser version, exact candidate hash and effective rows.
- The evidence validator checked all three exact budget pairs and `job − 12 − 25 − UI = 16` for each row.
- Removing only the authorized matrix budget fields and timeout substitutions makes the complete parsed workflow equal to the original. Commands, selectors, artifact export/upload, permissions, concurrency policy, `fail-fast: false`, `max-parallel: 2`, and every other job/step setting are unchanged.
- The unchanged selector validator passed and emitted the same six UI classes exactly once across three shards, plus the separate native-unit selector.
- All ten existing shard-validator regression tests passed. No new permanent test suite was added.
- All copied UI tests and selector/test scripts match the exact source-11 bytes. No test body, assertion, per-method wait, test command or selector was removed or weakened.

The source patch is `studio-budget.patch`. Validation commands and results are retained in `validation.json`, `existing-shard-tests.log` and the small reproducible evidence script `validate_workflow.py`. Static validation does not claim a new GitHub Actions or native pass. No live edits, staging, commits, native reruns or workflow cancellation were performed by this task.
