# Wave 05 — geometry/invariants

Reviewer: /root/w05_acceptance/geometry  
Frozen source: deffb5e3c93b507ceb4189a414a4ff0e3cf19395

**Verdict:** No source-proven violation of the accepted stale-hit contract found. This is source review, not native acceptance.

**SceneKit:** `SpatialPreview.Coordinator.lightID(for:)` (`App/SpatialPreview.swift:150–162`) requires available, visible orbit content; rejects hidden nodes along the ancestor walk; then requires registered object identity, immediate parent equal to current content, and UUID membership in the current scene. Attached fixture descendants and visible outlines resolve through their registered fixture. Detached descendants have no such ancestor. `updateContent` (349–407) removes deleted fixtures and rebuilds registrations; `discardEquipment` (95–103) clears invalid-scene identities. Reintroducing a removed UUID therefore does not authorize the retained old fixture, outline or stand. Stand registration and attachment track height (405–407,449–460).

**RealityKit:** `StudioEntityGraph.lightID(for:)` (`App/StudioEntityGraph.swift:127–136`) requires an enabled graph and enabled ancestry, registered root identity, `lights[id]?.root === item`, and direct parent equal to the current anchor. `update` (69–79,100–115) unregisters/removes deleted roots and clears invalid graphs. Selection and stand visibility use `isEnabled` (281–284,306). The resolver itself does not verify anchor attachment to a rendered scene; production selection additionally requires `RealityStudioPreview.Coordinator.canInteract` (154–157), rendering state (170–186), and current-scene membership in `selectLight` (273–278).

**Geometry:** `SpatialViewportBounds.init(scene:)` (`App/SpatialViewportGeometry.swift:12–62`) includes housing, outline and stand bounds; it supplies no hit-identity authorization.

**Concrete evidence gap:** `SpatialInteractionTests` (50–85) covers old fixture rejection after same-UUID replacement/invalid recovery. `SpatialEntityUpdateTests` (47–63,187–215) covers current outline/stand hits and stand detachment. `SpatialEmitterGeometryTests` (126–131) checks outline hiding, but never asserts that the hidden outline resolves to nil. Reviewed tests also lack direct negative assertions for hidden/reparented intermediate descendants and old outline/stand objects after replacement; RealityKit behavior here remains source-only.

Evidence boundary: deff inventory is 180 native/34 spatial methods, discovered but unexecuted. Historic 68c8 results (171 native, including 25 spatial) do not validate deff. No repository changes or execution claims.

