# A085 — compatible UTF-8 decoder cost

This is a bounded, matched Linux measurement of the one-call availability repair. It runs the full production project-document decode with the old strict initializer from `135d3b4755d97bbb8fcff993d8dfd532a8d48b93` and the compatible Foundation initializer in one optimized binary. The old type is renamed only to allow both implementations in the same module. No repository source, test or acceptance threshold changed.

Current parser SHA-256: `f82fa22d3f3018919ddaea22c22de148268b1a3f1bff43d7232c2a58e90481ce`.

## Actual results

Three process samples per variant and fixture, alternating order. Every full decode checked the expected name, migrated scene version, subject, camera and empty lights. The 192-byte Unicode input used 10 warmups and 1,000 timed decodes per process; each 8 MiB input used one warmup and one timed decode. Input reads were outside the decode timer. All 18 process samples exited zero and passed output checks.

| Workload | Old median ms | Compatible median ms | Ratio |
|---|---:|---:|---:|
| ordinary_unicode | 0.040321 | 0.042631 | 1.057× |
| unicode_value_8mib | 29.897563 | 33.302675 | 1.114× |
| ascii_value_8mib | 20.326719 | 21.862185 | 1.076× |

The maximum-size non-ASCII value's old raw samples were **33.820394, 29.897563, 28.718390 ms**; compatible samples were **33.302675, 29.815880, 67.550330 ms**. The slow 67.550330 ms sample remains in the data. Its median difference was **3.405112 ms**, with only three samples. The unchanged ASCII path also varied, so these observations do not isolate causal initializer cost or establish statistical equivalence, a regression threshold, or tail latency.

An early parent message mistakenly characterized the single 67.55 ms sample as representative after truncated progress output. The complete-sample correction was sent immediately: the actual compatible median is 33.30 ms versus 29.90 ms, not approximately 67 ms versus 29 ms. Use only the complete raw records and summary.

## Provenance and limits

`source-hashes.json` binds all production dependencies to the base revision plus the exact current parser, and records the original and renamed old-parser hashes. `build.json` records the exact Swift 6.0.3 optimized whole-module command, platform, executable and harness hashes. `fixtures.json` binds the two new Unicode inputs and the original frozen 8 MiB ASCII long-string fixture. `raw.jsonl` retains every sample; `summary.json` retains the exact calculations.

The original 14.70× dense-empty-array comparison was not repeated or transferred to this source. The current comparison contains no dense-array workload. Linux Foundation does not establish Apple Foundation timing, iPhone memory, responsiveness, frame rate or beta acceptance. No malformed-input coverage is claimed from this performance witness; A082/A083 own that separate correctness evidence. Additional task-local storage is below 19 MB, within the requested 80 MB limit. No shared SwiftPM build or repository file was changed.

For compact evidence integration, retain this README, receipt, `build.json`, `source-hashes.json`, `fixtures.json`, `raw.jsonl`, `summary.json`, `main.swift`, `run.py`, `old-original.swift`, and build logs. Inputs, duplicate dependency snapshots and the executable are reproducible private working material; do not commit the executable. The runner reconstructs inputs and verifies frozen hashes; run in a fresh task directory with the expected repository source and toolchain.
