# W04 R04 — tiny clipped-face regression candidate

**Result: bounded Swift probe PASS; XCTest candidate prepared, unintegrated.**

Worktree HEAD `47de6afe6afe24a7822f4276950f70bd3db9f57d`; immutable v1 production `1b286885cb803ba17e159713651515ab119e17f1`. Second executor: Swift 6.0.3, x86_64 Linux. Root rebuilt v1 from `047803c0bff16137467e751263f1c11d8aa165aa`; `git diff --stat 1b286885cb803ba17e159713651515ab119e17f1 047803c -- Sources` returned empty.

One fixture: 4×4 m XY rectangle, receiver (0,0,1) m, normal (1,0,-1)/sqrt(2), eight least-nonzero candela steps. The hemisphere contributes exactly 75% of the face, exercising clipping separately from existing full-face coverage.

Independent scalar antiderivatives give **0.11959789527956421 lx/cd**. Swift unit control returned **0.11960250634721419 lx**, **0.00385548%** error. Tiny actual and expected both equal **4.9406564584124654e-324 lx**, bit pattern 1, **0%** relative error. Dividing intensity by 16 first produces zero, establishing the regression witness. Candidate asserts positive output and <=5% relative error without an underflowed tolerance.

Exact successful command, exit 0:

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r04 /tmp/keyfill02-r2-workers/w04r04/private-output/probe.swift v1
```

Files: `TinyClippedRectangleRegressionTests.swift`, `probe.swift`, `reference.md`, `compile.log`, `probe.log`, `execution-status.log`. The latter preserves the initial transport failure and second-executor provenance. Candidate was not run as a package test. No production edits, package builds, installs, pushes or spawns. One ideal geometry only; 1% point/5% area gates unchanged. No calibration or device claim.
