# Wave09 geometry review

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree: `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`.

**Finding: no new concrete stale-transform or lifecycle defect identified in this bounded inspection.** No production changes proposed.

Read the four requested adapter files, `AGENTS.md`, architecture/design/acceptance contracts, geometry comparisons, owner requests, prior geometry reports, and the 4e694bc native receipt. Inspected focused assertions in `SpatialEntityUpdateTests`, `SpatialAimRecoveryTests`, `SpatialSelectionLifetimeTests`, `SpatialInteractionTests`, `SpatialNavigationRecoveryTests`, and `SpatialViewportStateTests`. All source/document reads used the frozen Git revision.

## Supported findings

- Continuing SceneKit UUIDs retain fixture/source/stand nodes. Kind or rectangle dimensions rebuild shapes; position, optics, output and subject changes refresh transforms. Pose resets precede housing offsets, preventing accumulated translation. Stand threshold crossings detach/reuse the cylinder. Coincident aim removes emission; recovery recomputes orientation and source pose (`SpatialPreview.swift:349–461`).
- RealityKit geometry invalidation includes position, complete optics and subject; source invalidation additionally includes output/color/shading eligibility. Shape, stand, outline and aim state refresh together. Degenerate or Float-collapsed aim segments disable both markers. Rectangle faces retain authored extents (`StudioEntityGraph.swift:249–345`).
- Invalid scenes and UUID removal discard owned lamps/hit maps; reinsertion creates fresh equipment. Parent/visibility ownership checks reject retained old hits. Unchanged-scene callbacks refresh before early returns. The applied camera-mode cache survives invalid input, preserving recovery Fit semantics.
- RealityKit background/offwindow transitions detach anchors while retaining current geometry/orbit; scene updates still refresh the graph, and reactivation reattaches it. Dismantling removes view callbacks, gesture targets and anchors. SceneKit teardown clears graph/camera ownership and caches. No stale geometry transfer was found at renderer recreation. These lifecycle conclusions are source inspection.

## Evidence limits

The 4e694bc receipt records 184/184 native passes, including 38 spatial (28 direct SceneKit, 10 helpers), plus Debug/Release builds. Current 60059 has an additional outward-Float-FOV regression: 185/39 is inventory, not an inherited pass. No tests/builds/probes were run here. Current native completion, RealityKit execution, background/reactivation gesture delivery, physical-device behavior, manual VoiceOver, FPS/RSS/thermal remain unverified; node counts establish no runtime performance result.
