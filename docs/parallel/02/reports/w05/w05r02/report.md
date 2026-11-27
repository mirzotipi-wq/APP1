# W05 R02 — target-lux source preservation

**PASS: 16/16 actual Swift cases; no defect found.** One helper invocation compiled and executed successfully (exit 0; empty compile diagnostics) using Swift 6.0.3, x86_64 Linux.

Compiled module: `1b286885cb803ba17e159713651515ab119e17f1`. Worker HEAD: `928ca0eafa6330742114c2e0ac184789c2f17752`. Latest production-source revision: `58b3ca43943e18d0fc7800189b08365f424d9c9e`. Actual git diff confirmed no LightingCore differences between snapshot and worker HEAD. Production was unchanged.

## Check and result

Four fixtures (nil-optics point, explicit point, directional, rolled rectangle) each exercised zero, changed positive, already-exact, and initially-off targets. Sources both belonging to and absent from the scene were covered.

Every returned non-output field matched: UUID, exact name UTF-8, position and Kelvin bit patterns; optics presence, kind, aim position, width, height and optional roll. Signed-zero roll and nil values survived. Restoring only candela made each result equal to the original source. Incoming source and the complete scene matched their pre-call values and sorted JSON encodings, including unrelated lights, camera lens, preview settings and placement room.

Maximum relative forward-target error: **2.220446049250313e-15**, below the unchanged **1e-9** gate. The 1% point and 5% area gates remain unchanged; this role did not independently remeasure those accuracy gates.

## Exact probe command

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w05r02 /tmp/keyfill02-r2-workers/w05r02/private-output/probe.swift v1
```

Executed once through `run_probe.py`, which captured subprocess output directly. This bounded preservation check did not force the maximum-output fallback or audit error branches. No device/calibration claim.

## Evidence

All artifacts are under `/tmp/keyfill02-r2-workers/w05r02/private-output/`: `probe.swift`, `probe.log`, `compile.log`, `raw.log`, `commands.log`, `provenance.log`, `reference.log`, and reproducible capture driver `run_probe.py`. Logs are actual execution evidence, not reconstructed output.
