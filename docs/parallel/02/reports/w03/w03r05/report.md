# W03R05 — concurrent point/directional evaluations

**Result: PASS; no defect observed in this bounded check.**

Input/worktree and immutable snapshot `v1`: `1b286885cb803ba17e159713651515ab119e17f1`. Host toolchain: Swift 6.0.3, `x86_64-unknown-linux-gnu`; helper compiler invocation has no optimization flag. Read AGENTS, QUALITY, ARCHITECTURE, and relevant photometry source contracts.

Executed:

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w03r05 /tmp/keyfill02-r2-workers/w03r05/private-output/probe.swift v1
```

The immutable fixture collection contains 18 cases covering direct point and scene point/directional APIs: on-axis, off-axis, double cosine, vertical aim, back-facing, zero output, subnormal output, and unsupported geometry. Eight concurrent lanes each repeated all fixtures 256 times; odd lanes reversed evaluation order. Each lane owned a distinct lock-protected publication slot; computations and temporary arrays stayed local. No fixture or shared Swift array was mutated concurrently.

All **36,864** concurrent results exactly matched serial optional classification and `Double.bitPattern`, with **zero mismatches**. Eight distinct execution threads were observed. Serial references include 3 `nil` and 5 zero cases; positive subnormal values were preserved. The concurrent phase took 0.068060636 seconds on this host; this is execution evidence, not a performance gate.

Artifacts: `probe.swift`, `commands.txt`, `compile.log` (empty; compiler exit 0), `probe.log`, `serial-reference.csv` (decimal and hexadecimal scalar references), and `artifact-sha256.txt`. Probe exit 0. Production source was read-only; no package builds, commits, or additional workers.

Limits: one bounded host execution, no sanitizer run or exhaustive concurrency proof; serial equivalence does not independently establish analytic accuracy. The protected 1% point/5% area gates remain unchanged. No device or physical calibration claim.
