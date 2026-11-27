# W02R05 — mixed-rig determinism

**PASS.** Input SHA: `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b` (frozen LightingCore v1; worker HEAD agrees). One Swift probe invocation exited 0.

## Fixture

Validated schema 5 scene; subject `(0, 1.5, 0)` m, camera `(0.2, 1.6, 3)` m. Fixed UUIDs `00000000-0000-0000-0000-000000000001` through `...003`; array order point, directional, rectangle.

| Emitter | Position (m) | Intensity | Temperature | Optics |
|---|---|---|---|---|
| Point | (-1.5, 2.1, 1.2) | 900 cd | 5600 K | Explicit point |
| Directional | (1.5, 1.7, 1.5) | 300 cd | 3200 K | Aim (0.2, 1.45, 0.1) m |
| Rectangle | (-0.2, 2.6, 2) | 650 cd | 7200 K | Aim subject; 0.8 × 1.2 m; roll 23° |

Preview white balance 5000 K, exposure +0.75 stops. Full serialized fixture is in `probe.log`.

## Execution and result

Exactly **32 evaluations**, including the baseline, with no warm-up: **31 repeated-result comparisons**, **310 Double.bitPattern comparisons** (93 per-light lux; 217 preview scalars), plus **31 NeutralCardPreview Equatable comparisons**. All values finite, all three light contributions positive; **zero mismatches**.

Baseline lux: `(123.33176945138159, 49.622989354574379, 102.31789132674987)`. Total: `275.27265013270585` lx. Incident XYZ: `(271.24990392238794, 275.27265013270585, 266.61617226533178)`. Display RGB: `(0.30220847980142096, 0.30699080708419912, 0.32825798999553746)`.

Evidence: `probe.swift`, `probe.log` (32 bit-pattern rows), empty successful `compile.log`, and `commands.txt`. No production changes. This supports same-process, fixed-order determinism for this synthetic rig; it does not establish concurrency/cross-platform guarantees or physical calibration.
