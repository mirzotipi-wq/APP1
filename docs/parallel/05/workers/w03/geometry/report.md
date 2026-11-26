# Wave 03 geometry/invariants

Worker: `/root/w03_acceptance/geometry` (parent `/root/w03_acceptance`).
Input SHA: `35283bed09c609be424df80f36b42391aec19f74`.

## Actual checks / outcome

Pinned `git show` reads of directives, lane plan, architecture/design, model, both adapters and all spatial tests; pinned NativeTests search for graph/mutation coverage. No concrete geometry regression found by source review.

- `App/SpatialPreview.swift:347–409`: persistent per-UUID fixture/source/stand nodes; only kind/rectangle-size changes replace meshes. Lines 410–458 reset pose before offsetting housing, preventing cumulative displacement. Source remains at authored center; fixture +Z and source −Z use the shared rolled basis (292–300, 416–440). Stand remains world-vertical.
- `App/StudioEntityGraph.swift:217–305`: persistent entities, dimension scales in meters, shared complete frame, fixed 180° emission-child rotation. Diffuser front is z=0; housing stays behind it. Stand top follows authored height; feet remain at world y=0.014. Camera lens/pose use −Z (47–53, 90–95).
- `App/SpatialViewportGeometry.swift:25–62`: bounds conservatively cover the adapters’ housings/outlines, point markers, busts, cameras, aim spheres and stands. Basis contract checked against `Sources/LightingCore/StudioOptics.swift:50–110`.

## Findings

**P2 missing mutation coverage.** `NativeTests/SpatialEmitterGeometryTests.swift:49–145` tests fresh construction/selection; `SpatialInteractionTests.swift:143–159` repeats position/output/order changes. Neither exercises same-UUID kind/size/roll/stand transitions. Add point→rectangle→directional→point, dimension endpoints, vertical/manual/follow-subject aim, coincident→valid aim and y crossing 0.05. After each update assert persistent nodes, expected mesh replacement, front-plane/source position, basis and stand detach/reattach identity.

**P2 RealityKit evidence gap.** No NativeTests references to `StudioEntityGraph` or `StudioLampEntity`; equivalent native mutation checks are absent.

## Limits / disposition

Zero builds/tests executed; no product edits. Ten pure state tests are declared, not observed passing here. Historical eight/nine-test Linux passes and CI 45817222487 at source 68… do not validate this SHA; parent reports latest ten-test build killed before execution. Recommend targeted mutation tests and exact-source native execution; source review alone does not establish acceptance.
