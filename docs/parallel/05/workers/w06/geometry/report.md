# W06 geometry / invariants

Canonical ID: `/root/w06_acceptance/geometry`  
Frozen input: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`.

**Finding: one rectangle-extent contract defect; no basis/front-plane discrepancy in the bounded source/math comparison.**

Core explicitly defines emitting-face corners, excluding housing, at authored ±width/2 and ±height/2 (`Sources/LightingCore/StudioSceneBounds.swift:3–6,27–34`). Those dimensions also define the photometric emitting domain (`Sources/LightingCore/StudioOptics.swift:131–136`; `Sources/LightingCore/SurfacePhotometry.swift:118–123,185–189`). RealityKit's unit-box construction and scaling (`App/StudioEntityGraph.swift:171,177–180,270–277`) instead produce a 1.188×0.688 m face for a 1.2×0.7 m rectangle: 0.817344 versus 0.84 m², 2.697143% undersize. Each edge is inset 0.006 m; corner displacement is 0.008485281 m. At the valid 0.05×0.05 m minimum, area undersize reaches 42.24%. Recommend rectangle-only face scale `[width,height,0.006]`; retain z=-0.003, preserving front z=0 and directional presentation. The witness labels this as proposed correction.

Ran `python3 /tmp/keyfill05-be879deb/waves/w06/geometry/witness.py`: **67 scalar assertions passed**. Independent projected-world-up/Rodrigues formulas cover translated oblique 37.5°, vertical +90°/−125°, and translated vertical recovery at 37.5°. Formula error ≤1.67e−16; ideal front-center residual is zero. Recovered right=(0.793353340,0,−0.608761429), up=(−0.608761429,0,−0.793353340), normal=(0,1,0). Both source-forward mappings preserve handedness (`App/SpatialPreview.swift:294–302,418–442`; `App/StudioEntityGraph.swift:240–241,262–277`). Tested face corners remain inside the viewport envelope (`App/SpatialViewportGeometry.swift:38–52`).

Recovery is **source analysis**, not executed incremental updates: changed aim resets orientation, suppresses emission at coincidence, then restores the new frame (`App/SpatialPreview.swift:373–378,413–446`; `App/StudioEntityGraph.swift:117–121,250–268,309–343`). Coincidence has no physical direction (`Sources/LightingCore/SurfacePhotometry.swift:9–15`). A separate 1e−7 m nonzero aim at x=80 retains a Core frame but Float-rounded endpoints coincide; RealityKit hides only aim markers (`App/StudioEntityGraph.swift:292–308`).

Float32 component-cast errors were ≤2.85e−8 for axes and 9.54e−8 m for positions; these exclude native quaternion/transform arithmetic. Existing native tolerances remain 1e−6 and 2e−5 m (`NativeTests/SpatialEmitterGeometryTests.swift:34–46`). `GEOMETRY_COMPARISONS.md:13` misses the housing/face distinction; its lines14,36 correctly retain recovery as an execution gap. No native builds/tests, visual, photometric-calibration or performance claims; no production edits.
