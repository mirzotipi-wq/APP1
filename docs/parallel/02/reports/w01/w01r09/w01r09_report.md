# W01R09 — platform/performance boundary

Assigned base: `f150f98e35dd735927075aac4d2f8b02295c6a67`; lane02wave1. Source remained read-only.

**Result:** All four accepted endpoint combinations (2000/10000 K × −6/+6 stops) produced finite, positive Float32 parameters in one Python transcription. No endpoint narrowing overflow or domain failure was observed.

**Source:** `Sources/LightingCore/Colorimetry.swift` lines 5–6 and 13–16 constrain finite settings to WB 2000–10000 K and exposure ±6. Lines 54–66 and 73–88 compute normalized blackbody XYZ and Bradford components. Lines 103–109 validate settings, require positive source components, calculate adaptation ratios, and calculate exposure. Lines 113–115 narrow these values into `SIMD4<Float>`.

| WB | Float32 adaptation x, y, z | Float32 exposure at −6 / +6 |
|---|---|---|
| 2000 K | 0.6866206527, 1.3451948166, 8.4307117462 | 0.015625 / 64 |
| 10000 K | 1.0501484871, 1.0021077394, 0.7231130004 | 0.015625 / 64 |

Endpoint Bradford denominators were positive: `(1.3710323891, 0.7734466469, 0.1292615248)` and `(0.8964248282, 1.0382480386, 1.5070488261)`. Largest parameter: 64, safely within finite binary32 magnitude.

**Commands:** `pwd && rg --files -g AGENTS.md -g Colorimetry.swift -g '*Colorimetry*'`; `cat AGENTS.md`; `cat agents/OPERATING_PROTOCOL.md`; `nl -ba Sources/LightingCore/Colorimetry.swift`; `python3 private-output/w01r09_float_endpoints.py` (exit 0).

**Evidence:** `private-output/w01r09_float_endpoints.py`, `private-output/w01r09_float_endpoints.json`, and this report, under `/tmp/keyfill02-workers/w01r09/`.

**Limits/recommendation:** Endpoint arithmetic only; interior temperatures were not sampled or proven. Python binary64 calculations and binary32 packing are not executed Swift, actual GPU validation, CPU/GPU parity, or performance evidence. No build, toolchain, network, or source changes. Accept this narrow endpoint check; retain platform gates as unverified.
