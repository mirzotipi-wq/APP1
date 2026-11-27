# W04R07 — renderer consumer request

Fresh source trace after executor reset; not recovered original logs. HEAD `47de6afe6afe24a7822f4276950f70bd3db9f57d`; comparison baseline `f150f98`. No compiled snapshot used.

**Confirmed:** `ReferenceStudy.swift:249` divides rectangle candela by 64/1024 before CPU evaluation (`316`); the meter now integrates at 1 cd below `Double.leastNormalMagnitude * 1024`, then scales (`SurfacePhotometry.swift:125–132`). GPU packing further converts each cell to Float (`ReferenceStudy.swift:274,549`); `App/StudyKernel.h:133,238,258` consumes that value. `StudyFloat32Eligibility.supports` checks geometry, with no positive-output representability guard. Thus fixing CPU division alone cannot establish GPU support for Double subnormals.

**Concrete owner request:** CPU rendering owner should integrate tiny rectangle contributions at unit intensity, applying original candela once per light separately to unoccluded lux, visible lux and material-weighted XYZ. Preserve visibility/clipping/near-field validation. GPU owner should extend `StudyFloat32Eligibility.swift` to route positive rectangle outputs whose per-cell Float value is subnormal/zero to the corrected CPU path, unless a separately validated scaling representation is implemented. Existing fallback is `App/MetalStudyRenderer.swift:212–229`.

**Acceptance:** centered 0.05×0.05 m rectangle at 0.05 m, facing receiver, least-positive candela: reference CPU lux must equal unit-output CPU lux multiplied once by candela and remain positive. Cover both qualities, clipped face, mixed rig and boundary neighbors. Test geometry-eligible tiny scenes route to CPU. Retain exact invalid masks, ordinary-frame regression/parity thresholds, and 1% point/5% area gates; meter agreement alone is insufficient. Sub-display-quantization values need not produce nonblack RGBA.

**Ordinary order:** all renderer/packing/kernel files and the meter midpoint body are byte-identical to baseline; rows remain outermost, columns innermost. The separate emitter-normal normalization change prevents claiming every ordinary meter result is bit-identical.

Command: `python3 private-output/trace_source.py > private-output/source-trace.log` (exit 0). Evidence: script and log. Source-only result; no renderer edits, native execution or calibration claim.
