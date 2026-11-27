# W04 R05 — partial-face concurrency determinism

**PASS on the second executor:** 256/256 concurrent results bitwise equal their serial baselines; zero mismatches, missing results, or duplicate result keys. Maximum absolute and relative differences: **0**.

Worktree: `47de6afe6afe24a7822f4276950f70bd3db9f57d`. Snapshot `v1/READY`: `1b286885cb803ba17e159713651515ab119e17f1`. Swift 6.0.3; Linux 6.18.57, x86_64. Coordinator reported rebuilding v1 from `047803c`, whose Sources match the frozen production revision. Relevant AGENTS, QUALITY, and ARCHITECTURE contracts were read.

Exact probe command, exit **0**:

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r05 /tmp/keyfill02-r2-workers/w04r05/private-output/probe.swift v1
```

Four immutable fixtures received 64 concurrently scheduled evaluations each. Children returned independent values; only the parent task collected results. Scalar corner signs confirmed mixed positive/negative incidence for every fixture.

| Fixture | Serial lux |
|---|---:|
| 1 mm strip | 0.00048664642096451474 |
| 10 µm corner | 1.2252598519164359e-13 |
| Five-vertex clipped face | 3385.7101112805362 |
| Rolled partial face | 391.96416828637234 |

Evidence: `probe.swift`, empty successful `compile.log`, `probe.log`, `scalars.csv` (4 serial + 256 concurrent rows, including bit patterns), `environment.log`, and `artifact-check.log`.

The initial executor's identical command failed before compilation (exit 2, missing helper after temporary-environment erasure); `helper-attempt.log` retains that failure.

Limits: one bounded host run; serial values are determinism references, not independent accuracy references. No sanitizer, performance, device, calibration, or general race-freedom claim. Production stayed read-only; the 1% point/5% area gates remain unchanged and unassessed.
