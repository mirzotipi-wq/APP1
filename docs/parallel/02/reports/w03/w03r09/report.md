# W03R09 — 5 cm point boundary and 1–3-light additivity

**PASS:** 80 assertions across 20 scene cases; maximum scalar-relative error 0, within the unchanged 1% point gate.

Revision/snapshot: `1b286885cb803ba17e159713651515ab119e17f1` / `v1`. Host: Linux 6.18.57 x86_64; Swift 6.0.3, x86_64-unknown-linux-gnu. Production files remained read-only.

The probe exercised `0.05.nextDown`, exact `0.05`, and `0.05.nextUp` through normal illuminance, oriented point illuminance, and `NeutralCardPreview.totalLux`. Expected values used scalar `n / (distance * distance)` with axis-aligned sources and no production expected-value helpers.

At nextDown, front/back scenes remained unsupported for 1–3 nonzero lights. Exact/nextUp were supported: front-facing totals scaled 1×/2×/3× (approximately 400/800/1200 lx at 1 cd each), while back-facing totals were exactly zero. All totals matched individual contribution sums. A positive 7 lx contribution plus an unsupported near source remained unsupported; plus a supported back-facing source remained 7 lx. Direct zero-candela point evaluations also retained unsupported geometry below the cutoff.

**Command:** `python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w03r09 /tmp/keyfill02-r2-workers/w03r09/private-output/probe.swift v1` (exit 0).

**Evidence:** `probe.swift`, `probe.log`, `compile.log`, `scalar-reference.tsv`, and `commands.txt` contain actual source/results, expected scalar values, and expanded command/platform details.

**Limits:** Axis-aligned Double host check only; no timing, physical calibration, device, oblique-coordinate, area-source, or broader-suite claim. The 5% area gate was not exercised or changed. No production change proposed.
