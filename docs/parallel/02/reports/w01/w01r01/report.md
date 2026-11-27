# W01R01 — acceptance audit

Input: `f150f98e35dd735927075aac4d2f8b02295c6a67`; worktree `/tmp/keyfill02-workers/w01r01`; agent `/root/w01r01`.

## Formula and supported-domain map

- `SurfacePhotometry.swift:9–15`: direction uses max-component scaling before length normalization; finite nonzero vectors accepted without overflow from magnitude squaring. Positions are finite ±100 m (`Scene.swift:3–12`).
- Point meter (`SurfacePhotometry.swift:85–91`, `Scene.swift:94–100`): E = I·max(0,n·direction)/r², cd to lx, r ≥ 0.05 m, I in [0,100000] cd. Directional (`StudioOptics.swift:120–130`) adds max(0,emitterNormal·ray); it is a local cosine source with inverse-square falloff.
- Rectangle (`SurfacePhotometry.swift:39–49,94–175`): sides 0.05–4 m; orthogonal normalized axes; right×up emits; radiance I₀/(width·height). E = ∫L cosθe cosθr/r² dA. Plane separation ≥ max(0.05 m,longestSide/4), backface zero, unsupported near plane nil. Full face uses 1024 midpoint samples; partial face clips one hemisphere and integrates ≤3 triangles×144 Gaussian samples. No lumen/watt conversion exists.
- `StudioOptics.swift:58–93,100–104`: receiver points subject→camera; emitter points source→aim/subject, roll ±180° about its normal; coincident definitions return nil. No exposure is folded into lux.
- `Colorimetry.swift:54–65,103–139,151–164`: ideal 1000–20000 K Planck spectra at 81 wavelengths, photopic Y=1; lux-weighted XYZ sums before 18%/1000 lx relative scaling, Bradford WB (2000–10000 K), 2^stops (±6), luminance Reinhard, gamut compression, sRGB encoding. This is relative diagnostic color, not calibrated camera/spectral output.
- `LightOutputAdjustment.swift:34–93`: validated scene/source, target≥0; zero turns off; positive target inverts unit-cd response, checks forward maximum and achieved relative error≤1e-9. Unsupported geometry and unrepresentable output throw; no silent clamp.

## Concrete acceptance evidence

Read AGENTS/protocol/quality/architecture and relevant source/tests using `cat`, `nl -ba`, `rg`; confirmed exact input via `git rev-parse HEAD` and clean tracked status. Ran `python3 private-output/acceptance_probe.py`: eight independent Simpson comparisons, maximum relative error **0.000520765729 (0.0521%)**, reference refinement <1e-5, four additional boundary/normalization assertions. Fixtures include min-depth square, 80:1 rectangle, off-axis tilt, 10µm strip/corner and partial/full transition. Script and JSON retained. This independently transcribes production math; it does not execute Swift.

No concrete P0/P1/P2 defect established in this bounded acceptance audit. Existing source tests cover analytic point/cosine, area references, color additivity/WB/exposure, transform invariants and output boundaries; they were inspected, not run. Root owns Debug/Release/native validation; physical calibration remains unverified. Initial ledger write failed transiently with ENOSPC during root toolchain extraction; root freed its own capacity and retry succeeded. Source remains unchanged.
