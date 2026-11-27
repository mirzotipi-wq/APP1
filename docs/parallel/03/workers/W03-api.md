# W03-api

Runtime/canonical ID: `/root/wave01/api`. Assignment: lane03/wave01 validation/mask API inspection.
Input: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Private detached worktree: `/tmp/keyfill03-7f4b/workers/W03-api` (clean).

Actual commands: `git status --short`, `git branch --show-current`, `git rev-parse HEAD`, `git log -3 --oneline`; bounded `rg`, `wc`, `cat`, `nl`/`sed` source/directive/test reads; `python3 scripts/agent_cycle.py check` and `next`. Checker: structurally valid evidence/M03 outstanding, not acceptance. Absent guessed filenames resolved with `rg`; assigned TMPDIR used.

Status: inspection complete; no tests/builds/renders/downloads/source edits. No commit. Historical evidence preserved.

## Contracts

- `LightingScene.validated()` rejects schema/field-version mismatch, >12 lights, invalid scene/light fields and duplicate IDs; migrates success to v5 (`Scene.swift:62–80`).
- `StudyGeometry.init?` checks bounds. `StudyLighting.init` validates scene before sample arrays; active degenerate aims throw `invalidEmitter`, zero-candela sources are skipped. Public `evaluate` rejects invalid receiver/material/view and near-source surfaces (`ReferenceStudy.swift:62–65,232–265,288–307`).
- `ReferenceStudyRenderer.render`/`StudyComputeInput.init`: width≥24, divisible by3, max192 interactive/96 reference; invalid camera/geometry/depth throws (`ReferenceStudy.swift:423–454`). `PortraitStudyRenderer.render`: max144 plus body/panel exclusion (`PortraitStudy.swift:162–176`). All reject invalid scenes before framebuffer allocation; portrait may initialize mesh first (`:77,89–91,173–174`), handed to resource review.
- Exact properties: `unsupportedPixels`, `unsupportedPixelMask`. Whole-frame rejection throws; partial `invalidSurface` becomes opaque magenta+mask1+count. Valid unlit surfaces are black; missed geometry is opaque `[18,20,24]` (`ReferenceStudy.swift:489–533`; `PortraitStudy.swift:183–220`). `StudyImage.fromComputeRGBA` permits alpha0 only for magenta, records flag then restores255; other nonopaque bytes fail (`ReferenceStudy.swift:393–407`). `StudyParityMetrics.init?` validates sizes/masks/counts/opacity; `passes` requires exact mask/count and aggregate RGB thresholds (`StudyValidationFixtures.swift:41–80`).

## Coverage gap

Add shared malformed-scene entry tests (schema, 13 lights, duplicate IDs, invalid inactive-light data) for both renderers/compute. Existing focused negative tests chiefly cover resolution, camera, cancellation, near field (`ReferenceStudyTests.swift:103–156`; `PortraitStudyTests.swift:123–139`; `StudyComputeInputTests.swift:57–65`).

No current mask/black/transparent inconsistency identified by inspection; runtime behavior remains unverified.
