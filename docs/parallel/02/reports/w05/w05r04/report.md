# W05 R04 — attainable-target round-trip candidate

**Result:** One bounded Swift probe passed all three fixtures; no concrete defect found.

Candidate: `LightOutputAttainableRoundTripTests.swift`, one XCTest method covering oblique point, manually aimed directional (initially off), and a nonsquare rectangle rolled 37°. Existing boundary tests only cover a centered rectangle's ordinary interior target; these fixture geometries and interior intensities are distinct.

| Emitter | Reference cd | Target lux | Candela relative error | Lux relative error |
|---|---:|---:|---:|---:|
| Point | 37.25 | 1.8374731518250644 | 0 | 0 |
| Directional | 1875.5 | 94.58700531404861 | 0 | 0 |
| Rectangle | 12345.75 | 912.5383698968942 | 0 | 0 |

Targets come from the actual forward model at known valid interior intensities. The candidate verifies targets are below each forward-model maximum, adjusts from a different initial output, recovers reference candela, and reevaluates achieved lux. Both relative-error assertions retain `1e-9`.

Executed command:

```text
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w05r04 /tmp/keyfill02-r2-workers/w05r04/private-output/probe.swift v1
```

Exit 0; Swift 6.0.3, x86_64 Linux. Frozen module: `1b286885cb803ba17e159713651515ab119e17f1`; production revision: `58b3ca43943e18d0fc7800189b08365f424d9c9e`; worktree docs/tests HEAD: `928ca0eafa6330742114c2e0ac184789c2f17752`. Read-only diff confirmed unchanged LightingCore production sources.

Evidence: `probe.swift`, actual `probe.log`, `compile.log`, `raw-results.tsv`, `commands.txt`, `provenance.json`.

Limits: XCTest candidate is unrun pending parent integration. This is solver/forward-model consistency evidence; unchanged 1% point / 5% area accuracy gates require independent references. No device or calibration claim. Production files were not edited.
