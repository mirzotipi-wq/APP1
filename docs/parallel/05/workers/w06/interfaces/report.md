# Wave 06 — interfaces review

Reviewer: `/root/w06_acceptance/interfaces`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`; campaign baseline: `f150f98`.

**Disposition:** Core supports the authorized rectangle-only RealityKit face-scale correction. This review changed no source.

**Orientation/camera handoff.** `Sources/LightingCore/StudioOptics.swift:50–94,107–110` defines right × up = normal, local +Z emission, deterministic vertical aim and authored roll. `App/SpatialPreview.swift:294–302,424–442` consumes that complete basis and flips both right/normal for −Z spotlights. `App/StudioEntityGraph.swift:240–241,260–264` consumes the same basis once and rotates the emission child by π. Undefined aimed emission stays disabled.

`Sources/LightingCore/CameraFraming.swift:3–8,33–61` defines the 36×24 mm lens, −Z forward, shared up and nil below 0.05 m. `SpatialPreview.swift:223–264` applies vertical lens FOV/near depth/up and hides unavailable content/clears pointOfView; both camera-body adapters reset undefined orientation (`SpatialPreview:337–340`; `StudioEntityGraph:90–96`). `SpatialViewportGeometry.swift:4–6,25–52` adds display equipment bounds using the shared frame/identity fallback without changing Core bounds or authored lens.

**Dimensions.** `StudioSceneBounds.swift:3–6,27–34` explicitly defines emitting-face corners as ±W/2, ±H/2. `StudioOptics.swift:131–136` and `SurfacePhotometry.swift:118–123,185–189` use those same dimensions for emission, excluding housing.

Apple documents [generateBox(size:cornerRadius:)](https://developer.apple.com/documentation/realitykit/meshresource/generatebox%28size%3Acornerradius%3A%29) as a centered cube whose size is its full edge length in meters; [scale](https://developer.apple.com/documentation/realitykit/hastransform/scale) is relative to the parent. Thus `StudioEntityGraph.swift:171,270–277` currently makes the rectangle face 12 mm undersized per axis. Rectangle-only scale `[W,H,0.006]` restores Core’s front-corner equation, subject to Float conversion. Keeping face z = −0.003 preserves front z = 0; retain directional inset and housing placement. SceneKit’s 0.012 chamfer (`SpatialPreview:384–385`) remains a rounded illustrative envelope, so literal flat-face mesh-corner parity is not claimed.

**Remote check.** At 2026-11-26 14:17:13 UTC, authorized exact-prefix GitHub searches for `finish/06` and `finish/20` each returned `branches: [], cursor: null`. Neither branch was returned; no SHA/HANDOFF input was available. The initial `finish/` query had cursor `NQ` and was insufficient alone. No baseline change, fetch, merge, native execution, performance or calibration claim.

