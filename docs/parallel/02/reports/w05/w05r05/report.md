# W05 R05 — immutable-input solver concurrency

**PASS — no defect observed.** One actual Swift probe evaluated 12 fixed inputs serially, then submitted independent immutable value copies in reverse order to a task group. Child tasks returned owned results; only the parent collected them. There was no shared mutable test state.

Point, directional and rolled rectangle sources each covered zero, ordinary adjustment from off, an already achieved target, and `maximumLux.nextUp` rejection. All 12 concurrent outcomes matched serial outcomes exactly, including full adjusted lights, candela/lux bit patterns and errors. All input-preservation and output-validity checks passed. Execution intervals overlapped for 38 task pairs. Total: 24 solver calls; zero mismatches or invariant failures. Maximum positive-target relative error was **6.661338147750939e-16**, within the unchanged **1e-9** gate. The 1% point and 5% area contracts remain unchanged; this is not an independent accuracy validation of those models.

Worktree HEAD: `928ca0eafa6330742114c2e0ac184789c2f17752`. Frozen module: `1b286885cb803ba17e159713651515ab119e17f1`. Production reference: `58b3ca43943e18d0fc7800189b08365f424d9c9e`. `Sources/LightingCore` has no diff from that production reference at either tested source revision; worktree docs/tests may be newer.

Command (exit 0):
`python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w05r05 /tmp/keyfill02-r2-workers/w05r05/private-output/probe.swift v1`

Evidence: `probe.swift`, `probe.log`, `raw-results.tsv`, `compile.log`, `commands.txt`, `provenance.json`, and copied references. This is fresh actual execution, not recovered earlier logs. One host scheduling sample establishes observed agreement only; no race-detector, exhaustive, device, or physical-calibration claim.
