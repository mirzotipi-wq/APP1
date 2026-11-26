# W05 R06 — target-lux evaluation and memory bound

**Result:** PASS for one static bound check; no target-solver defect found.

**Provenance:** Worktree HEAD `928ca0eafa6330742114c2e0ac184789c2f17752` includes newer documentation/tests. The inspected source matches frozen snapshot `1b286885cb803ba17e159713651515ab119e17f1` byte-for-byte and production revision `58b3ca43943e18d0fc7800189b08365f424d9c9e`. All LightingCore production source remains unchanged since that production revision. This is an original execution, not reconstructed evidence.

**Check:**

```sh
python3 /tmp/keyfill02-r2-workers/w05r06/private-output/check_bounds.py > /tmp/keyfill02-r2-workers/w05r06/private-output/check.log 2>&1
```

Exit **0**. Source assertions confirm four ordered photometry callsites without solver loops/recursion: unit, maximum, optional existing setting, achieved output. Zero target uses **0** calls; an initially off source uses at most **3**; any solve uses at most **4**.

Each rectangle call performs at most **1,024** midpoint or **432** clipped-triangle evaluations: at most **4,096/1,728** per solve. Independent enumeration of 32 feasible mixed affine sign patterns confirms at most five clipped vertices. Tiny-output recursion has depth two, returns before outer integration/allocation, and adds no integration pass; at most six rectangle function entries occur per solve.

Numeric storage is fixed: four corners, four incidence vertices, five clipped vertices, twelve global quadrature tuples, scalar accumulators, and light/scene value copies. Scene validation separately rejects more than twelve lights before iteration and allocates at most twelve UUIDs each for map/Set. Name trimming/counting remains input-length-dependent; eighty Swift Characters does not cap encoded bytes. No uniform whole-solver memory/time bound follows.

**Evidence:** `check_bounds.py`, `check.log`, `bound-result.json`, `source-excerpts.txt`, `provenance.json` in this directory.

**Limits:** Static analysis only; no measured allocations, benchmark, device, or calibration claim. Production unchanged; **1e-9 target / 1% point / 5% area** thresholds preserved.
