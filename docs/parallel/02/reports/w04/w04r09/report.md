# W04R09 — rectangle path timing

**PASS: 300/300 results were finite, positive and bitwise deterministic within each path.** Exactly one 100-call Swift batch per path; construction, branch classification and validation were outside timing.

| Path | Calls | Total ms | Mean µs/call | Lux |
|---|---:|---:|---:|---:|
| full_rectangle | 100 | 39.066143 | 390.66143 | 230.85282958801525 |
| partially_clipped_rectangle | 100 | 15.989094 | 159.89094 | 14.141865396693397 |
| scaled_tiny_clipped_rectangle | 100 | 15.969274 | 159.69274 | 3.1466695004710004e-310 |

All fixtures use a 1 × 1 m rectangle at the origin, receiver `(0,0,2)` m, zero roll, and +Z emitter normal. The full receiver normal is `(0,0,-1)`; partial/tiny normals are `(1,0,0)`, clipping exactly half the face. Plane separation is 2 m versus the 0.25 m minimum. Ordinary output is 1,000 cd; tiny output is `Double.leastNormalMagnitude` (2.2250738585072014e-308 cd), selecting unit scaling before partial integration. The tiny result remained subnormal and exactly matched ordinary-output proportionality (0 ULP difference). This is consistency evidence, not an independent accuracy reference.

**Provenance:** worktree HEAD `47de6afe6afe24a7822f4276950f70bd3db9f57d`; immutable snapshot v1 module revision `1b286885cb803ba17e159713651515ab119e17f1`; latest production change `58b3ca43943e18d0fc7800189b08365f424d9c9e`. Relevant source files are identical across module revision and worktree HEAD. Swift 6.0.3, x86_64 Linux, Debian 13; coordinator-supplied Debug module, probe compiled without `-O`.

**Limits:** one batch, no warmup; loop/array append overhead included. Unoptimized host diagnostic only; no timing threshold or device/calibration claim. Existing 1% point/5% area gates remain unchanged and are not measured here. No production edits or package build.

**Command (exit 0):**

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r09 /tmp/keyfill02-r2-workers/w04r09/private-output/probe.swift v1
```

Evidence: `probe.swift`, `probe.log`, `compile.log`, `raw-results.json`, `provenance.json`, `commands.txt`.
