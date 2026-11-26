# W04 R02 — rectangle roll invariance, evidence recovery

**Result:** PASS on the second executor; no defect found in this bounded check.

**Recovery:** Executor reset erased the original raw artifacts. This is a genuine rerun in the same worker context, not another role. Recreated probe SHA-256 exactly matches the original: `83b0ae7a78b2cdc2e71eae5829efc7cb9787fca571a451e61288f2f28c1095c0`. Logs and scalars were freshly generated, not reconstructed.

**Input:** `v1`, production SHA `1b286885cb803ba17e159713651515ab119e17f1`. Root rebuilt the module from `047803c0bff16137467e751263f1c11d8aa165aa`; LightingCore source diff against production is empty (independently rechecked). Worker HEAD is `47de6afe6afe24a7822f4276950f70bd3db9f57d`.

**Exact command:**

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r02 /tmp/keyfill02-r2-workers/w04r02/private-output/probe.swift v1
```

Exit 0; Swift 6.0.3, Linux x86_64. No package build.

The unchanged fixture uses an oblique 1000 cd, 1.2 × 0.6 m rectangle, 0.6 m plane separation, and full/partial receiver orientations. Compare 37° baseline with 127° plus swapped dimensions, and −143° with unchanged dimensions. Corner-incidence signs confirm midpoint/clipped paths.

| Receiver | Baseline lx | 90° + swap relative delta | 180° relative delta |
|---|---:|---:|---:|
| Full | 1470.9875060737158 | 1.0820049263034756e−15 | 6.182885293162718e−16 |
| Partial | 133.78670187496377 | 0 | 3.1866070056387325e−15 |

Six evaluations; maximum absolute delta 1.5916157281026244e−12 lx. Unchanged 5% area gate passes; 1% point gate remains unexercised. This is a declared-fixture symmetry check, not independent absolute accuracy, device validation, or calibration.

**Artifacts:** `probe.swift`, `compile.log`, `probe.log`, `scalars.json`, `provenance.json`. Provenance includes exact inspection argv, hashes, and second-executor history. Production untouched; no patch needed.
