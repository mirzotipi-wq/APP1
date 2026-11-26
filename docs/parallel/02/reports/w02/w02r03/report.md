# W02R03 — nil / zero / thrown-error table

Input/module snapshot: `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b` (frozen LightingCore v1; worker HEAD matches).

One Swift probe, **11/11 expected classifications matched**. No compilation, runtime, or assertion failures. An initial source read used a nonexistent `Photometry.swift`; `rg` located `SurfacePhotometry.swift` (recorded in commands).

| API / fixture | Expected | Actual |
|---|---|---|
| Photometry.normal: −1 cd, 2 m | nil | nil |
| Photometry.normal: 0 cd, 2 m | zero lux | zero lux |
| Photometry.point: 0.049 m | nil | nil |
| Photometry.point: coincident source | nil | nil |
| StudioPhotometry: coincident camera/subject | nil | nil |
| StudioPhotometry: point behind receiver, 2 m | zero lux | zero lux |
| StudioPhotometry: 0.6×0.9 m rectangle, depth 0.1 m | nil | nil |
| Adjustment: target −1 lux | invalidTargetLux | invalidTargetLux |
| Adjustment: invalid source −1 cd, target 0 | invalidLight | invalidLight |
| Adjustment: near point, target 1 lux | unsupportedGeometry | unsupportedGeometry |
| Adjustment: valid source/scene, near point and coincident camera, target 0 | returns 0 cd | returns 0 cd |

Adjustment error names denote thrown `LightOutputAdjustmentError` cases. Zero target validates the source and scene, then returns zero candela without requiring supported photometric geometry.

Exact execution:

```sh
python3 /tmp/keyfill02-probe.py /tmp/keyfill02-workers/w02r03 /tmp/keyfill02-workers/w02r03/private-output/probe.swift
```

Artifacts: `probe.swift`, raw `probe.log`, `compile.log`, `commands.txt`. No production changes. Limits: one finite table at one snapshot; no exhaustive emitter/input sweep or physical calibration. Numerical software evidence only.
