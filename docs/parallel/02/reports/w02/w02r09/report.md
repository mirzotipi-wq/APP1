# W02R09 — photometric path timing

**PASS: 400/400 calls returned finite, nonnegative, deterministic lux.** One Swift probe timed exactly 100 calls per path through `StudioPhotometry.illuminance`.

Source: `1b286885cb803ba17e159713651515ab119e17f1`; immutable snapshot `v1`. Swift 6.0.3, x86_64 Linux, Debian 13. The coordinator supplied a default Debug snapshot; helper compilation used no `-O`. No worker package build or production edits.

| Path | Calls | Total ms | Mean µs/call | Lux |
|---|---:|---:|---:|---:|
| point | 100 | 0.345118 | 3.45118 | 250 |
| directional | 100 | 0.697738 | 6.97738 | 176.77669529664 |
| full_rectangle | 100 | 29.459310 | 294.59310 | 230.85282958802 |
| clipped_rectangle | 100 | 10.657117 | 106.57117 | 14.141865396693 |

**Inputs and branch checks:** Source `(0,0,0)` m, receiver `(0,0,2)` m, 1,000 cd, 5,600 K. Point/directional/full receiver normal `(0,0,-1)`; directional target `(1,0,1)` gives cosine `1/√2`. Rectangles are 1 × 1 m, emitting along `+Z`, with 2 m plane separation versus 0.25 m required. Full-face corner incidences are all 2 m; clipped receiver normal `(1,0,0)` gives corner incidences ±0.5 m, selecting half-face clipping. All coordinates, intensities, dimensions, and normals satisfy declared source domains; full domain details are in the log.

**Method/limits:** Monotonic `DispatchTime` batch timing; fixtures and validation outside timing, loop/result-array overhead included. One batch, no warmup or performance threshold. These are Debug host diagnostics, not optimized benchmarks, device performance, calibration, or area-accuracy evidence. Point/directional analytic references matched exactly; existing 1% point and 5% area gates remain unchanged.

**Command:**

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w02r09 /tmp/keyfill02-r2-workers/w02r09/private-output/probe.swift v1
```

Exit 0. Evidence: `probe.swift`, `probe.log`, `compile.log`, `scalar-results.json`, `commands.txt` in this directory.
