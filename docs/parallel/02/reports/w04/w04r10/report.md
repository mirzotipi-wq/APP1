# W04R10 — independent rolled grazing rectangle

**PASS for one held-out fixture; no defect found.** Fresh execution in the resumed campaign; no historical logs reconstructed.

Worktree HEAD: `47de6afe6afe24a7822f4276950f70bd3db9f57d`. Actual frozen Swift v1 module: `1b286885cb803ba17e159713651515ab119e17f1`; relevant production revision: `58b3ca43943e18d0fc7800189b08365f424d9c9e`. Relevant source matches the module revision. Toolchain: Swift 6.0.3, x86_64 Linux.

Fixture: **−63° roll, 1.6 × 0.9 m, 1375 cd**, separation **0.405 m** (minimum 0.4 m). Positive incidence `x − 0.55y > 0.72` yields a triangular corner containing **6.77123%** of the face; distinct from the prior 37° fixture.

Independent reference: direct world-space cosine factors, nested composite Simpson over analytic slices. No production clipping, triangle mapping, Gaussian quadrature, or expected-value normal helper.

| Simpson intervals per dimension | Reference lux |
|---:|---:|
| 256 | 10.232645080776454 |
| 512 | 10.232645081164865 |

Fixed refinements 32/64/128/256/512: 351,173 evaluations. Final relative change: **3.79580e−11**. Actual Swift: **10.232645081190737 lx**; absolute error **2.58726e−11 lx**, relative error **2.52844e−12**.

Commands (both exit 0):

```sh
python3 private-output/reference.py
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r10 /tmp/keyfill02-r2-workers/w04r10/private-output/probe.swift v1
```

Artifacts: `reference.py`, `reference.json`, `probe.swift`, `probe.log`, empty `compile.log`, `provenance.json`, and combined `raw-results.json`.

**5% area gate unchanged; 1% point gate unchanged/unexercised.** One software fixture and observed convergence only; no global bound, package tests, device/calibration claims, or production edits.
