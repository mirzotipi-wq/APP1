# Wave 03 — resources
- Canonical ID: `/root/w03_acceptance/resources`
- Input SHA: `35283bed09c609be424df80f36b42391aec19f74`
- Scope: read-only source review; no children, source edits, builds, tests or profiling.

## Evidence and checks
Read pinned AGENTS, OPERATING_PROTOCOL, lane PLAN, ARCHITECTURE and DESIGN. Inspected `SpatialPreview.swift` (95–163, 204–269, 309–479), `StudioEntityGraph.swift` (9–377), RealityStudioPreview teardown (98, 170–225), Scene validation (62–77), StudioSceneBounds (14–18), and existing SpatialInteractionTests (19–104, 143–159), using git show. Native test assertions were read, not run; new test commit 44550b6 was not re-reviewed.

## Findings
1. **Bounded retained topology.** Both adapters reconcile UUID dictionaries. Scene validation permits at most 12 unique lights. SceneKit retains four nodes per lamp; its content has five fixed direct children plus two per light and one per raised stand (at most 41 direct children). RealityKit explicitly constructs 52 base descendants and 24 entities per lamp: at most 341 including the anchor. These are source-derived application topology bounds, excluding framework internals. Reordering never constructs a replacement lamp.

2. **Reuse is qualified.** SceneKit changes transforms and existing material properties for output/pose edits. Emitter-kind changes or rectangle width/height changes replace fixture and copied outline geometry/materials. Stand geometry is lazily allocated once, retained while detached below the height threshold, and reused on return. An invalid aim clears SCNLight; recovery can allocate another. RealityKit generates two unit meshes and two collision shapes per graph; all lamp forms/outlines exist upfront and resize by transforms. Material values/arrays and light components are replaced on pose/optics/subject/output/shading changes. Reordering more than seven eligible lights can change shading assignments and trigger these replacements. Metadata/selection edits skip material replacement.

3. **Deletion and invalid recovery release application ownership.** SceneKit removes fixture/source/stand parents and selection entries, then rebuilds its identifier map. RealityKit removes root and UUID/identifier entries. Invalid input clears lamp maps and detaches lamps; valid recovery creates new roots. Identifier keys do not strongly retain hit objects. External retained hits may keep old objects alive but cannot resolve through the live maps. Base geometry/resources deliberately survive invalid input. RealityKit detach removes anchors but its coordinator retains the bounded graph until coordinator release; this is not immediate resource destruction.

4. **Stable counts do not establish allocation-free updates.** Validation/bounds, sets, arrays, colors and changed materials/components can allocate transiently; SceneKit/framework mesh-buffer behavior is unmeasured. Existing 100-update test checks direct child count and one fixture identity across edits/reordering, not heap growth, descendant counts or GPU release.

## Outcome
No application-owned unbounded growth or deleted-lamp retention defect found in this scope. Source reuse/cleanup supported; native execution and memory/performance conclusions remain unverified at the input SHA.
