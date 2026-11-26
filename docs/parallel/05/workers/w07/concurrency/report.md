# Wave 07 — concurrency

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Outcome:** no new concrete lane 05 concurrency defect established. Read-only review; no edits, builds or host probes.

## Source constraints

- `App/SpatialPreview.swift`: `SpatialPreview.updateView` and `Coordinator` are main-actor isolated. Callback refresh precedes the unchanged-scene return. Updates have no suspension; the zero-duration `SCNTransaction` is not proof of arbitrary renderer-thread atomicity. Invalid scenes discard equipment/hit maps; preserving `lastCameraMode` permits pending mode recovery.
- `App/RealityStudioPreview.swift`: `RealityStudioSurface.Coordinator.update` refreshes callbacks before synchronous validation/graph publication. `App/StudioEntityGraph.swift` is also `@MainActor`; its `lightID(for:)` requires current root ownership and enabled ancestry. Neither adapter introduces tasks, queues or renderer callbacks.
- SceneKit propagates disabled/inactive state through `updateUIView`; availability and camera mode also disable interaction. Its selection delegate and handler require a callback, attached window and VoiceOver off. RealityKit's `canInteract` gates all four gesture handlers; active/window transitions remove anchors and cancel recognition. These are source constraints, not delivered-interaction results.
- UUID-set changes cancel recognition; deleted/invalid equipment loses hit ownership. Both `detach` methods remove recognizers/targets/delegates and clear callbacks. SceneKit clears scene/nodes; RealityKit removes anchors/layout/window hooks and clears current scene, retaining its graph until coordinator release.

## Executed evidence and limits

`docs/parallel/05/validation/NATIVE-9725fb1.md` records run 45826141504/job 139935031405: 176 native methods, including 30 spatial, and Debug/Release builds passed at 9725fb1.

`NativeTests/SpatialInteractionTests.swift` covers callback replacement, stale identities, invalid recovery, disable/dismantle properties and 100 **serial** updates. Callback assertions invoke closures directly; these tests establish neither concurrent scheduling nor gesture delivery. `SpatialSelectionLifetimeTests.swift` adds 3 direct callback/equipment-lifetime methods; `SpatialNavigationRecoveryTests.swift` adds 4 camera methods; `SpatialAimRecoveryTests.swift` adds 1 aim method. Those 8 methods and the later RealityKit rectangle correction require a current-source receipt (expected 184 native/38 spatial).

RealityKit execution, renderer-thread stress, physical devices, manual VoiceOver and performance remain unestablished. The lane 01 first-save `.id(generation)` integration request remains external; no adapter fix is proposed.
