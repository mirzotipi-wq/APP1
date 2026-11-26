# Wave03 acceptance trace

- Context: `/root/w03_acceptance` (acceptance specialist and queue lead).
- Input: `35283bed09c609be424df80f36b42391aec19f74`; local HEAD matched on initial read. Inspection used pinned `git show`, not moving checkout.
- Scope: stable construction and incremental updates, lane05; root owns product changes. Read AGENTS, operating protocol, plan, architecture/design and relevant renderer/tests.

## Acceptance trace

1. **Stable UUID, valid scene:** SceneKit keeps one `SpatialLampNodes` bundle per UUID. Output, temperature, name, position, aim and roll preserve fixture/source/stand/indicator node identity. Geometry changes only on kind or rectangular dimensions; name-only avoids render mutation. Evidence: `App/SpatialPreview.swift:347–460`.
2. **RealityKit identity:** one `StudioLampEntity` per UUID owns persistent point/housing/face/stand/selection children, shared meshes and collision resources. Kind and dimension changes toggle/transform children; source changes replace material/component values without replacing entity hierarchy. Evidence: `App/StudioEntityGraph.swift:100–124,169–191,217–344`.
3. **Intentional identity reset:** deleting a UUID removes nodes and maps; invalid scenes discard equipment. Reintroducing the same UUID creates fresh nodes, so retained hit objects cannot select replacements. SceneKit detach clears graph, callbacks and view; RealityKit detach disables coordinator interaction and detaches anchors. Evidence: `SpatialPreview.swift:95–163,229–244,347–355`; `StudioEntityGraph.swift:69–77,100–136`; `RealityStudioPreview.swift:208–225,273–278`.
4. **Selection and viewpoint:** selection-only changes retain geometry. Callback refresh precedes SceneKit's unchanged-scene early return and RealityKit graph updates. Ordinary edits preserve the current viewport; explicit Fit/mode changes may reset framing. Evidence: `SpatialPreview.swift:204–286`; `RealityStudioPreview.swift:189–205,228–244`.

## Existing evidence and gap

`NativeTests/SpatialInteractionTests.swift:19–105,143–159` declares metadata/output/selection identity, removed/reintroduced and invalid-scene rejection, detach, and 100-update node-count checks. `SpatialEmitterGeometryTests.swift:49–145` declares front-plane/roll and selection tests but creates independent scenes for shape cases. The new implementation worker targets repeated kind/dimension/stand transitions in one live view. Native execution and RealityKit runtime identity remain unverified in this wave; no performance, rendering or accessibility runtime pass is inferred.

## Checks actually performed

Pinned source and test inspection only. No build or native test execution. Parent's evidence packet: source68 had eight portable passes, ca3 nine; source352 declares ten but latest run was killed before execution. Later parent report: CI45817222487 succeeded at source68 with 171 tests, zero failures/skips, including 25 spatial tests, and two original SceneKit captures viewed. This does not verify source352 or testpatch44550b6. Acceptance is source-supported and regression-backed only after integration; native result must remain source-specific.
