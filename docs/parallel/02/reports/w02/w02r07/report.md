# W02R07 — ordinary meter / Study samples

**PASS: 2/2 fixtures; no defect found within this check.** Source and frozen LightingCore v1 module: `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b`. One standalone Swift probe completed with exit 0 on Linux x86_64, Swift 6.0.3, debug module.

Both fixtures use receiver `(0.15, 1.2, -0.2)` m and camera-derived normal `(0.1951800145897066, -0.09759000729485329, 0.9759000729485331)`. `StudioPhotometry.illuminance` and `StudyLighting.evaluate` receive that same surface; Study uses `.reference`, view equal to normal, diffuse reflectance 1, and `geometry: nil`. Only unoccluded lux is compared.

| Fixture | Samples | Meter lux | Study unoccluded lux | Relative difference |
|---|---:|---:|---:|---:|
| Directional, 1375 cd | 1 | 150.8124227415794 | 150.81242274157938 | 1.8846e-16 |
| Rectangle, 900 cd, roll 37° | 1024 | 92.99538655692136 | 92.99538655692137 | 1.5281e-16 |

Both meet the probe's `1e-12` relative agreement tolerance. The 0.9 × 0.6 m rectangle is fully front-facing: minimum corner projection is 1.803319 m, and emitter-plane depth is 2.702314 m versus the 0.225 m guard.

**Retained distinction:** full faces share 32×32 midpoint conventions. Partial-face meter integration clips the rectangle and uses Gaussian quadrature; Study uses bounded clipped-domain sampling. Their grazing results can differ. This check establishes no grazing parity, shadow/frame behavior, GPU/device result, or physical calibration. Source: `StudioOptics.swift:113–136`, `SurfacePhotometry.swift:92–214`, `ReferenceStudy.swift:5–9,288–365`.

Evidence: `probe.swift`, raw `probe.log`, empty successful `compile.log`, `commands.txt`, and `provenance.json` (source/module/helper/artifact hashes). No production edits.
