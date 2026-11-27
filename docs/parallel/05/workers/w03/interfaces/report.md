# Wave 03 — interfaces

Agent: `/root/w03_acceptance/interfaces`  
Input: `35283bed09c609be424df80f36b42391aec19f74`

Files: `App/SpatialPreview.swift` (SP), `App/StudioEntityGraph.swift` (EG), `App/RealityStudioPreview.swift` (RP); `NativeTests/SpatialInteractionTests.swift` (IT), SpatialEmitterGeometryTests, SpatialViewportStateTests; core Scene/StudioSceneBounds. Read AGENTS, operating protocol, lane plan, architecture/design. Checks: pinned `git show` and `git grep`; no source edits, builds, or tests executed.

## Findings

- Continuing UUID and reorder: SP:347–367,403–405 reuses UUID-keyed lamps and rebuilds object identity mappings; EG:100–121 reuses UUID-keyed roots. Neither uses list indices. IT:143–159 covers repeated SceneKit edits/reversal.
- Deleted/reintroduced UUID: SP:150–160,347–367 removes old nodes, creates replacements and requires current object ownership plus UUID membership. EG:101–115,127–136 removes root mappings and requires cached-root identity/anchor ownership. IT:50–64 retains/rejects the removed SceneKit object after reinsertion.
- Invalid scene: SP:230–235,95–103 and EG:69–77 clear light caches/mappings. Bounds calls validation; duplicate UUIDs are rejected (`StudioSceneBounds.swift:14–15`, `Scene.swift:77`). IT:67–85 covers invalidation/recovery with fresh SceneKit objects.
- Equal scene, replacement callback: SP:204–213 refreshes the callback before its equality guard. RP:189–199 refreshes before graph update; RP:273–278 checks current UUID membership before invocation. Source supports the intended behavior.

## Concrete gaps

**P2 — unchanged-scene callback regression missing.** IT:31–47 changes name/output/Kelvin before asserting callback replacement. Moving assignment below SP's equality guard would still pass. Add two updates with identical scene/selection/mode/Fit values and different closures; resolve the same live node and assert only callback B fires. Also cover replacement by nil.

**P2 — RealityKit parity coverage missing.** Pinned grep across NativeTests/Tests found no references to StudioEntityGraph, RealityStudioSurface or RealityStudioPreview. Add a native host/test seam for the same identity, invalidation and callback chains.

Outcome: no demonstrated mapping defect; two focused test gaps. Native execution unavailable. Parent-provided source68 eight portable passes, ca3 nine passes and CI45817222487/source68 do not verify this input. Source352 has ten declarations; its latest attempt was killed before execution. No current pass claimed.
