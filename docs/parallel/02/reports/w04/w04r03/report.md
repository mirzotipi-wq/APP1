# W04 R03 — exact rectangle separation boundary

**Second-executor evidence recovery, same context.** Initial execution passed; an executor reset erased its /tmp artifacts. These raw logs come from a genuine new execution of the recreated original probe, not reconstructed output. Probe and scalar SHA-256 values match those recorded before the reset.

**Provenance:** production `1b286885cb803ba17e159713651515ab119e17f1`; immutable `v1` rebuilt by root from `047803c0bff16137467e751263f1c11d8aa165aa`, Swift 6.0.3, x86_64 Linux. Root verified the complete Sources diff empty; this recovery independently confirms identical SurfacePhotometry source. Worker HEAD: `47de6afe6afe24a7822f4276950f70bd3db9f57d`.

**Exact commands:**
```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r03 /tmp/keyfill02-r2-workers/w04r03/private-output/probe.swift v1
/tmp/keyfill02-r2-toolchain/usr/bin/swiftc --version > private-output/environment.txt
python3 private-output/restore_evidence.py
```

**Result: PASS, 24/24; exit 0.** Centered 0.1 m and 1 m squares were tested at 0.05 m and 0.25 m separation boundaries and immediate floating-point neighbors, on both emitter-plane sides with both receiver-facing directions. Eight below-limit cases returned nil; twelve supported back-facing cases returned exact zero; four illuminated cases returned finite positive lux. Maximum analytic-reference error: **0.025708464%**, within the unchanged 5% area gate. The unchanged 1% point gate was not exercised. No defect found.

**Evidence:** probe.swift, compile.log, probe.log, scalars.tsv, environment.txt, provenance.json, commands.txt, restore_evidence.py.

**Limits:** unchanged fixed samples; no additional role, expanded checks, package build, production change, device measurement or calibration claim.
