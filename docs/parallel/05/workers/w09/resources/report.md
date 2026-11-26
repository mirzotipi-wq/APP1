# Wave09 lane05 — resources

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`. Pinned source/docs review only; no edits, builds, tests or CI polling. **Result: no new concrete resource-lifecycle defect.**

## Bounded topology

Let N ≤ 12 validated UUIDs (`Sources/LightingCore/Scene.swift:validated`) and S ≤ N stands above 0.05 m. After a valid update:

| Adapter | Coordinator-owned nodes/entities | Attached to live scene |
|---|---:|---:|
| SceneKit | 8 + 4N, maximum 56 | 8 + 3N + S |
| RealityKit | 55 + 24N, maximum 343 | Same while active/on-window; zero adapter anchors while inactive/off-window |

Owned counts cover explicit source-created nodes/entities, including disabled objects and retained detached stands. They exclude framework scene roots/internals, UIKit, meshes, materials, light components and externally retained test witnesses.

`App/SpatialPreview.swift:updateContent`: base eight = content/camera plus floor/head/torso/ambient/camera-body/lens; each lamp owns fixture/source/indicator/stand. `App/StudioEntityGraph.swift`: graph base 53 = anchor, floor, subject/camera roots, six body models, fill and 42 grid lines; each lamp owns 24 entities. `App/RealityStudioPreview.swift:Coordinator` adds camera anchor/camera.

## Transitions and ownership

Insertion adds one lamp hierarchy; deletion/invalidation clears lamp ownership and hit maps; recovery recreates lamps, even for returning UUIDs. SceneKit invalidation retains eight base nodes (two before first valid update); RealityKit retains 55 entities with graph disabled. Undefined authored camera framing instead hides SceneKit content without discarding lamps.

Continuing UUIDs retain nodes; lowered SceneKit stands detach while remaining owned. Shape/material/light replacement is intentional: SceneKit changes shape for kind/rectangle dimensions, and clears/recreates SCNLight across undefined aim; RealityKit replaces source materials/components while reusing entities/shared meshes.

Background SceneKit disables interaction/stops inertia; off-window additionally stops playback, retaining topology. RealityKit removes both anchors but retains graph/resources. SceneKit teardown clears graph children/maps/callbacks and view scene/POV, retaining coordinator content/camera nodes (camera still owns SCNCamera). RealityKit teardown removes anchors/gestures/callbacks; graph ownership remains until coordinator release. Neither proves deallocation.

## Evidence and limits

`NativeTests/SpatialEntityUpdateTests.swift` asserts retained identities and intentional replacements; `SpatialSelectionLifetimeTests.swift` asserts deletion/invalid-recovery rejection using deliberately retained old nodes; `SpatialInteractionTests.swift` checks 100 updates’ immediate-child count and teardown state; `SpatialAimRecoveryTests.swift` checks retained nodes with nil→spot recovery.

`docs/parallel/05/validation/NATIVE-4e694bc.md`: source4e694bc, run45838950713/job139980771221 passed 184 native/38 spatial (28 direct SceneKit + 10 helpers), Debug/Release builds. Current185/39 is inventory only. No allocation, deallocation, RSS/FPS/thermal claim; RealityKit runtime, delivered gestures, device behavior and manual VoiceOver remain unverified.

