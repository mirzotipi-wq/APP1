# W01R04 — roll/clipping challenge

Verified base: `f150f98e35dd735927075aac4d2f8b02295c6a67`. **No defect found in the bounded ordinary-domain case.** Source was read-only. No Swift, build, installation, network mutation, commit, or child worker.

## Equation review

`Sources/LightingCore/StudioOptics.swift:61–68` constructs up = normal × right. Lines 87–93 apply a determinant-positive roll, preserving right × up = normal. Lines 132–136 pass the basis and dimensions into the rectangle.

`Sources/LightingCore/SurfacePhotometry.swift:44–49` checks orthogonality and computes that same normal. Lines 108–125 express incidence as `(emitterPoint−receiver)·receiverNormal`. Lines 141–145 clip its positive half-plane. The determinant × `(1−u)` Jacobian at lines 154–170 correctly integrates triangle area. Whole-face normalization at lines 174–175 agrees with the full-face cell convention at lines 183–194.

## One independent Python probe

Center `(0.4,1.5,−0.3)`, target `(2.4,4.5,5.7)`, roll `37°`, dimensions `1.2×0.6 m`, `1000 cd`. For rolled unit basis R/U/N, receiver = center + `0.15R−0.12U+0.6N`; receiver normal = normalize(`R+0.35U+0.18N`). Separation `0.6 m` exceeds the supported minimum `0.3 m`. Exact world coordinates are in the JSON artifact.

The independent 160×160 Simpson reference integrates world-space emission/receiver cosines on analytic slices `x+0.35y>0.216`, without production clipping or triangle integration.

- Maximum perpendicularity error `1.94e−16`; handedness `0.9999999999999998`; independent Rodrigues roll error `1.11e−16`.
- Physical area agrees with `0.72 m²`; local/world clipped areas agree with independent `0.2304 m²` within `1.4e−16 m²`.
- Transcription: `133.78670187496363 lx`; independent reference: `133.78670191052524 lx`; relative error `2.6581e−10`.
- Equivalent `127°` footprint with dimensions exchanged: relative lux difference `1.0622e−15`.

Executed once: `python3 private-output/roll_area_probe.py > private-output/roll_area_probe.json` — exit 0, six assertions passed. **Python only; not executed Swift.** Read commands: `cat`, `nl -ba`, `rg`. One exploratory `rg` returned exit 2 for an absent `StudioRender*` glob; no conclusion depends on that path. `git rev-parse HEAD && git status --short` confirmed the SHA and only `?? private-output/`.

Artifacts: `private-output/report.md`, `private-output/roll_area_probe.py`, `private-output/roll_area_probe.json`. Recommendation: no source change from this challenge. This is not an all-input or rendering-adapter verification.
