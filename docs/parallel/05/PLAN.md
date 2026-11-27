# Lane 05 — native spatial viewports

## Scope and baseline

Branch: `finish/05-spatial-viewports` only. Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67` (the owner-specified default; no lane-20 branch was published at startup). Observed main: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`. No changes to main are authorized by this packet.

Own `App/RealityStudioPreview.swift`, `App/StudioEntityGraph.swift`, `App/SpatialPreview.swift`, viewport-only helper code, and corresponding spatial/native regressions. Core geometry, shared composition, AR, Study rendering and Plan UI stay with their owners. The current M02/M03 acceptance contract and all numerical thresholds remain intact.

## Acceptance

- Authored meter-space positions, emitter aim/roll/shape and camera -Z convention agree with represented equipment.
- Non-geometric edits preserve useful viewpoint, live geometry identity and valid selection.
- Deleted, invalid, detached or prior-scene hit objects cannot select equipment.
- Orbit, pan, zoom and explicit Fit stay finite and include declared spatial bounds in narrow and wide layouts.
- SceneKit fallback remains functional where RealityKit is unavailable. Report native execution separately from portable tests, source review and historical evidence.

## Ten-wave execution

Each wave has ten actual fresh contexts: an acceptance specialist who also queues nine workers, plus geometry/invariants, interfaces, implementation, concurrency, resources, interactions, accessibility/privacy, platform/performance and independent review. Root integrates sequentially. At most root, one wave lead and two child workers run concurrently (four platform slots). Wave leads are included in the 100; root is not. Each worker records its actual canonical ID, input SHA, task, files, output and disposition.

1. Reproduce navigation, selection and geometry defects.
2. Verify right-handed coordinates, meter scale and camera conventions.
3. Improve stable entity construction and incremental updates.
4. Repair orbit/pan/zoom/Fit and preserve useful viewpoints.
5. Harden hit selection against deleted or replaced identities.
6. Correct emitter aim, roll, shapes and camera representation.
7. Preserve SceneKit fallback on unsupported runtimes.
8. Inspect translated, crowded, sparse and narrow-layout scenes.
9. Challenge lifecycle, entity retention and interaction continuity.
10. Review polished behavior, exact source evidence and integration handoff.

Brief target: <=2,000 tokens; worker working target: 12,000; report target: <=800. Root working target: 24,000, checkpoint at approximately 60%. These are task budgets, not changes to platform context limits. Actual token telemetry is unavailable; record fresh-context creation and observed outputs without inventing context counts. Every active source writer uses a private temporary worktree and output directory. Review-only workers use pinned `git show` reads and private reports.

## Resources and verification

Startup Linux host: approximately 9.7 GiB RAM; workspace volume initially full; `/tmp` initially 2.6 GiB available, subsequently fluctuating with concurrent work. This lane uses `/tmp/keyfill05-be879deb`, a sparse checkout (37 MiB after excluding historical evidence) and private outputs. No Swift or Apple SDK found at startup. HTTPS Git and public GitHub Actions metadata are available. Use existing branch-triggered CI for Apple builds and native tests when available; do not claim local native execution. Preserve pushed checkpoints and verify remote SHAs before deleting lane-owned temporary work.

Startup `python3 scripts/agent_cycle.py check` passed structure validation only. `next` reports M03 active with editing/accessibility/persistence outstanding; lane 20 owns canonical milestone state. No milestone promotion is performed in this lane.
