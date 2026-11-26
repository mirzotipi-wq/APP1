# W05 R03 — solver error classification

**Result:** PASS for this bounded check: one compiled Swift case-table execution, 24 cases, zero mismatches. No concrete defect found.

Validation order is target → source light → scene → positive-target geometry → representable output. Negative/NaN/infinite targets produce `invalidTargetLux` (5 rows, including precedence). Invalid source settings produce `invalidLight` (4). Invalid scenes—including unrelated invalid lights, duplicate IDs, invalid coordinates and unsupported schema—map to `unsupportedGeometry`; valid scenes with undefined receiver normal, sub-5-cm point separation, zero back-facing contribution, degenerate aim or unsupported rectangle separation use the same error (10 total rows including zero-target invalid scene).

Zero bypasses photometric sampling only: a valid scene with coincident camera/subject returns 0 cd, while invalid scene/source still throws. Positive ordinary/off-source requests returned 1,000/10 cd and exactly 250/2.5 lx: relative errors 0, satisfying the unchanged 1e-9 target gate.

Both numeric failures correctly return `outputOutOfRange`: 25,000 lx.nextUp exceeds the exact 100,000 cd point maximum at 2 m; least-nonzero positive lux at 5 cm requires candela below the smallest positive Double. Count totals: invalidTargetLux 5; invalidLight 4; unsupportedGeometry 10; outputOutOfRange 2; success 3.

**Provenance:** detached worktree HEAD `928ca0eafa6330742114c2e0ac184789c2f17752`; linked frozen module `1b286885cb803ba17e159713651515ab119e17f1`. LightingCore source matches both that snapshot and production `58b3ca43943e18d0fc7800189b08365f424d9c9e`; worktree docs/tests may differ. Swift 6.0.3, x86_64 Linux. Compile/probe exit 0. Only private-output changed.

Evidence: `probe.swift`, original `compile.log`/`probe.log`, `cases.tsv`, `commands.md`, `provenance.json`, literal source/contract copies in `references/`.

Limits: classification fixtures only; no package suite, device, calibration, or broad accuracy claim. Unchanged 1% point/5% area gates were not remeasured.
