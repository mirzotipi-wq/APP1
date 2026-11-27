# W03R01 — point/orientation acceptance

**PASS, bounded matrix:** 18/18 actual production Swift evaluations: nine positive results, five exact zeros, four unsupported (`nil`) results. Maximum relative error among positive references was **0**, satisfying the unchanged **≤1%** point gate. The **≤5% area gate is preserved and not evaluated here**.

Input: immutable snapshot `v1`, source `1b286885cb803ba17e159713651515ab119e17f1`, matching worker HEAD. Toolchain: Swift 6.0.3, `x86_64-unknown-linux-gnu`. No source edits or package builds.

Independent reference: `I/r² × max(0, receiver cosine)`, additionally multiplied by `max(0, emitter cosine)` for directional lights. Fixtures prescribe cosine components directly; reference generation does not call production normalization or photometry helpers. The positive-case denominator is `abs(expected_lux)`; zero and unsupported cases require exact classification.

Coverage: normal and 60° incidence; near-grazing receiver cosine 0.01; inverse-square at 2/4 m; 100,000 cd at 0.5 m; double-cosine directional output; tangent/back-facing receiver or emitter; zero intensity. Unsupported cases: 0.049 m separation, coincident camera/subject, coincident directional source/aim, 100,001 cd.

Source contracts require valid light metadata, finite positions within ±100 m, 0–100,000 cd, distance ≥0.05 m, a nonzero subject-to-camera direction, and a nonzero directional aim. Supported nonpositive cosine yields zero, not `nil`. This is diagnostic incident lux, without visibility or physical calibration claims.

Reproduce from this worktree:

```sh
python3 private-output/matrix.py
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w03r01 /tmp/keyfill02-r2-workers/w03r01/private-output/probe.swift v1
python3 private-output/matrix.py --verify
```

Artifacts: `probe.swift`, `matrix.py`, `references.json`, `probe.log`, `results.csv`, `summary.json`, `compile.log`, `provenance.txt`. This small matrix does not establish exhaustive-domain, area, renderer, device, or calibration acceptance.
