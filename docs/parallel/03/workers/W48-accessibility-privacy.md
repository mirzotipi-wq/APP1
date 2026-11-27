# W48 — accessibility/privacy

**Scoped ACCEPT by source review; no native test pass claimed.**

Input/private HEAD: `c9ff1a71c173774e7b7c794e475f8bdf5d633853` (initially clean).
Candidate `wave05-evidence/W44-ReferenceStudy.swift` SHA-256: `4ac702653392d64586d0a472576da64ebe3f68dad7339954232f7c5f6635b141`.
Patch SHA-256: `b6f355709bbf68f51c738c95ba15770c6d4f01c5a2133e1c35f283afd983c3a8`.

Read all four required directives; compared original/candidate and reviewed Colorimetry, masks, and ReferenceStudyPreview. Findings:

- Exact-zero candela remains inactive; positive subnormal emitters retain samples and near-field rejection. Rectangle guards precede shortcuts; scalar distance checks precede illumination. Private outputScale changes accumulation only.
- Finite nonnegative XYZ remains valid, including zero-luminance black. Positive Double signals can round to black in RGBA8. Compute packing restores intensity before Float32 conversion; tiny Float32 zero is expected.
- CPU unsupported pixels retain mask 1 and magenta; valid darkness retains mask 0. Compute alpha flags unsupported pixels, verifies diagnostic magenta, then retains a separate mask; RGB alone does not determine validity. Existing count/text warning, labels, retry/update semantics and task routes remain unchanged.
- The diff adds no persistence field, network/photo access, permission, identifier, public payload or UI route. No new data exposure or accessibility claim follows from this repair.

**Actual arithmetic:** ran `python wave05-evidence/W48-quantization-witness.py wave05-evidence/W48-quantization-witness.json`: 12 checks, 0 failures. Four finite analytic point/directional examples produced positive binary64 XYZ, zero packed Float32 candela and RGB8 `[0,0,0]`. This transcribes arithmetic, not Swift execution. JSON records host/Python and values; private copies are in the assigned build output.

**Limits:** W42 baseline 166/56 failures and candidate 166/0 are root-reported Swift results. W50’s inherited extreme geometric/BRDF limitations remain outside this fix; universal positive output is not established. Swift/build/render/Metal/UI/native accessibility/physical checks were unrun by W48. No production edits, commits, cleanup or resets occurred. Initial nonexistent rg globs exited 2; corrected reads supplied the sources. Earlier combined reads were truncated; bounded reads recovered required sections.

**User-facing sentence:** “The correction preserves very small CPU lighting contributions in supported finite cases while keeping valid darkness distinct from unsupported geometry; those contributions can still display as black.”
