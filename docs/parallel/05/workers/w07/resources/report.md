# Wave07 — resources

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree `0f090891cb010ca03ef105fad808878b23f2eb16`. Pinned GitHub reads only; no edits or execution. **Outcome: no new concrete resource-lifecycle blocker found.**

## Retention and fresh resources

- `App/SpatialPreview.swift:updateContent` retains UUID-owned fixture/source/indicator/stand nodes. Unchanged modifier dimensions preserve geometry; ordinary valid updates reuse `SCNLight`. Kind/rectangle-size changes create geometry, an outline copy and materials. Stand geometry is created lazily and retained while detached. Undefined aim clears the light; recovery creates another `SCNLight`. Insertion, deletion/reintroduction and invalid-scene recovery create lamp resources.
- `App/StudioEntityGraph.swift` shares unit meshes/collision shapes through `StudioGeometryResources`; `StudioLampEntity.update` scales/enables retained entities. Source changes—including pose/optics/subject changes—construct material and light-component values. Temporary collections and framework work also remain outside identity assertions. This does not establish allocation-free updating.

## Ownership and teardown

Both adapters remove deleted/invalid lamp roots and hit-map entries; hit resolution verifies current parent ownership and visibility. Callbacks refresh before unchanged-scene returns. `SpatialPreview.Coordinator.detach` removes gesture targets/delegates, clears callbacks/maps/equipment/base, stops camera inertia and clears the view’s scene/camera.

`App/RealityStudioPreview.swift:Coordinator` uses weak view/layout/window captures, cancels gestures on UUID-set changes, and removes gestures, callbacks and scene anchors on detach. Its graph/resources remain coordinator-owned until coordinator release; detachment is not measured deallocation. Lane01’s first-save wrapper-identity request remains external.

## Evidence and limits

`NativeTests/SpatialEntityUpdateTests.swift` checks exact node/light/cylinder identities, intentional geometry replacement and stand hit removal. `SpatialInteractionTests.swift` checks 100 updates’ immediate-child count/live fixture identity, callback replacement and teardown. Both test files are unchanged from the executed checkpoint; current adapter source differs.

`SpatialSelectionLifetimeTests.swift` adds direct callback refresh/clear and retained-old-equipment rejection after deletion/invalidation. These three methods remain unexecuted.

`docs/parallel/05/validation/NATIVE-9725fb1.md` records source `9725fb1177a5c7afbdf798ffd627e65e604c75b1`, run45826141504/job139935031405: 176 methods/30 spatial passed, Debug test-bundle and Release app builds passed. Current 184/38 expectations and eight added methods require a new receipt.

No reviewed test measures allocations, RSS, deallocation, frame time or thermal behavior. RealityKit execution, delivered gestures, physical-device performance and manual VoiceOver remain unestablished.
