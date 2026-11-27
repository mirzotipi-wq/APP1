# Wave07 geometry review

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.
Report path: `docs/parallel/05/workers/w07/geometry/report.md`.
Read-only GitHub review; no host probes, builds, tests, edits, or new captures.

## Findings

**No new geometry defect identified in the inspected source. Current native acceptance remains pending.**

- `App/SpatialPreview.swift` (`updateView`, `updateContent`, `orient`, `fitOrbit`) agrees with `Sources/LightingCore/CameraFraming.swift` and `Sources/LightingCore/StudioOptics.swift`: authored coordinates remain meters; camera/lens forward is local −Z; the fixture basis is right/up/+Z. Negating both right and normal for SceneKit spotlights preserves handedness while mapping local −Z onto the emitting normal. Rectangle width/height retain authored values, and the housing center moves behind the authored front plane. Undefined aims suppress the light without inventing a direction. The chamfered box establishes an outer envelope/front-center anchor, not exact sharp emitting-face corners.
- `App/SpatialViewportGeometry.swift` (`SpatialViewportBounds`, `SpatialOrbitState`) extends `Sources/LightingCore/StudioSceneBounds.swift` with represented bust/camera/housing/outline envelopes, world-floor stands and the 0.0275 m aim-marker radius. It covers the coincident 4 m housing that Core intentionally omits. Fit uses the enclosing radius with 48° on the smaller viewport axis and a 12% distance margin. SceneKit changes its projection axis on resize; RealityKit derives the corresponding vertical FOV. RealityKit navigation clamps do not constrain SceneKit’s separate camera-controller gestures.
- `App/StudioEntityGraph.swift` (`StudioLampEntity.update`) now scales the centered unit-box rectangle face to authored width/height, with its front at local z=0. This agrees with Core emitting-face semantics; it is source evidence only. `App/RealityStudioPreview.swift` selects `SpatialPreview` for Intel simulators before constructing RealityKit resources.

## Execution and carry-forward boundary

`docs/parallel/05/validation/NATIVE-9725fb1.md` records run 45826141504/job 139935031405 at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`: 176 native methods, including 30 spatial methods, plus Debug test-bundle and Release app builds. The inspected tests call the actual `SpatialPreview.makeView/updateView` used by the fallback and query SceneKit transforms/projections; this is stronger than pure helper arithmetic, but does not test real gesture delivery.

Pinned blob comparisons confirm unchanged `SpatialViewportGeometry`, `RealityStudioPreview`, `CameraFraming`, `StudioOptics`, `StudioSceneBounds`, and `NativeTests/SpatialEmitterGeometryTests.swift`, `SpatialPreviewTests.swift`, `SpatialInteractionTests.swift`, `SpatialViewportStateTests.swift` between those checkpoints.

**SpatialPreview is not wholly unchanged:** old blob `86c7260b3532e00b08f11dc67731ede95bd2fe3a`, current `c2dd825e406c505ded8291120bc4121f7bf35b79`. Its sole diff preserves `lastCameraMode` when validation fails, allowing the pending orbit Fit on recovery. Unchanged transform/Fit code supports limited carry-forward; the changed recovery branch does not inherit a pass. Inspected `NativeTests/SpatialNavigationRecoveryTests.swift` and `SpatialAimRecoveryTests.swift` supply new recovery assertions, with execution outside the old receipt. Current expected 184/38 counts are not established passes.

Also inspected `Sources/LightingCore/SurfacePhotometry.swift` and `Tests/LightingCoreTests/CameraFramingTests.swift`, `StudioOpticsTests.swift`, `StudioSceneBoundsTests.swift`. Native display shading remains illustrative: no numerical photometry, physical calibration, render parity, RealityKit execution, device performance, manual VoiceOver or real-gesture acceptance follows from this review.

## Input provenance

Read `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/acceptance/m02-m03-code.md`, `docs/parallel/05/GEOMETRY_COMPARISONS.md`, `OWNER_REQUESTS.md`, and the native receipt above.

| Input | Blob SHA |
|---|---|
| App/SpatialViewportGeometry.swift | 53f7aa8adffd379a0c7575bf2d4844e6a9d799a8 |
| App/RealityStudioPreview.swift | e4f763a15408c623912bbcdcd9b4296ec8418ae1 |
| App/StudioEntityGraph.swift | 35723305af3242e24c63e14196def45022d0519c |
| Sources/LightingCore/CameraFraming.swift | 7d2c50105bda390ca49cdaa75711380cc5047ae7 |
| Sources/LightingCore/StudioOptics.swift | 7e0d1cb3235b18c08e8b011f550ecc0ac3ca65e6 |
| Sources/LightingCore/StudioSceneBounds.swift | bb8b76a7edf803583470ff0dc3c54709baac1e2c |
| docs/parallel/05/validation/NATIVE-9725fb1.md | 87dea110343fb430fc79764abcb9ce2aa4c65ded |
