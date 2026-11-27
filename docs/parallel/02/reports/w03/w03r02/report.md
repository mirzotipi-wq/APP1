# W03R02 — rigid-transform point/directional invariance

**PASS; no defect found in this bounded check.** Actual Swift production APIs were exercised against immutable snapshot `v1`, source `1b286885cb803ba17e159713651515ab119e17f1`.

One off-axis fixture contains a point source and manually aimed directional source. Subject, camera, both sources and aim target receive the same full 3D proper rotation `R=[[-10,2,11],[10,-5,10],[5,14,2]]/15` and translation `(7,-11,13)` meters. Independent Python rational arithmetic verifies `RRᵀ=I`, determinant `1`, and unchanged distance/dot-product scalars. Decimal arithmetic computes 70-digit illuminance references without production geometry helpers.

| Mode | Original lux | Transformed lux | Reference lux |
|---|---:|---:|---:|
| Point | 65.60418166347888 | 65.60418166347891 | 65.60418166347888 |
| Directional | 49.624872310312796 | 49.62487231031278 | 49.62487231031281 |

Maximum relative transform change: **4.332301495077723e-16**. Maximum reference-relative error: **5.727311347559385e-16**. Maximum receiver-normal component error against the independently rotated normal: **1.665334536937735e-16**. All satisfy the probe's `1e-12` tolerance and unchanged **1% point-model gate**. The **5% area gate** is unchanged and untested here.

Reproduce with the exact commands in `commands.txt`. Both exited `0`; `probe.log` records all results and `compile.log` is empty. `probe.swift`, `reference.py`, `scalar_references.json`, and `provenance.json` preserve inputs, independent references, toolchain and source/library hashes.

Limits: one synthetic host Double fixture, two emitter modes; no sweep, package build, production edits, area evaluation, device result or physical-calibration claim.
