# W02R02 — independent point/cosine check

Frozen module and worktree SHA: `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b`.

One check: six point and six directional fixtures, distances 1–3.5 m, including translated receivers, tilted camera planes, and off-axis aims. Python derives scalar squared distances and raw dot products independently; no production normal/frame helper supplies expectations. Point reference is `I*cR/r²`; directional reference adds emitter cosine `cE`.

`Dp`/`Ds` below are positive point/selected-Studio reference lux and error denominators. Error is `100*abs(actual-reference)/reference`; the last column is the larger API error.

| ID | Dp (lux) | Ds (lux) | Max error (%) |
|---|---:|---:|---:|
| P01 | 120 | 120 | 0 |
| P02 | 212.5 | 212.5 | 0 |
| P03 | 128 | 128 | 2.22e-14 |
| P04 | 80.267783458 | 80.267783458 | 0 |
| P05 | 56.569175039 | 56.569175039 | 1.256e-14 |
| P06 | 21.840435333 | 21.840435333 | 0 |
| C07 | 200 | 200 | 0 |
| C08 | 160 | 128 | 4.441e-14 |
| C09 | 83.213522382 | 81.829316668 | 5.21e-14 |
| C10 | 95.033478517 | 85.228422509 | 3.335e-14 |
| C11 | 87.149592253 | 83.979060015 | 3.384e-14 |
| C12 | 132.53865689 | 130.34889167 | 2.18e-14 |

**Result:** all 24 comparisons across 12 fixtures pass the ≤1% criterion. Maximum relative error: **5.20994e-14%**. No defect observed.

Exact executed commands:

```sh
python3 /tmp/keyfill02-probe.py /tmp/keyfill02-workers/w02r02 /tmp/keyfill02-workers/w02r02/private-output/probe.swift
python3 /tmp/keyfill02-workers/w02r02/private-output/reference.py /tmp/keyfill02-workers/w02r02/private-output/probe.log /tmp/keyfill02-workers/w02r02/private-output/comparison.tsv
```

`comparison.tsv` retains full-precision actuals, denominators, squared distances, cosines, and individual errors; `probe.log` retains raw Swift output. Probe compilation/execution and Python comparison exited 0.

Limitations: ordinary finite synthetic geometry only; excludes boundaries, occlusion, rectangles, and measured equipment behavior. This is numerical software evidence, not physical calibration.
