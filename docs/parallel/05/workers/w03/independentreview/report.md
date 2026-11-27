# Wave 03 independent review

Canonical ID: `/root/w03_acceptance/independentreview`

Product: `35283bed09c609be424df80f36b42391aec19f74`

Test patch: `44550b6837656e86f4fa7b588ac4cfe7a9b1c361` (direct child; only `NativeTests/SpatialEntityUpdateTests.swift`, 217 added lines, three methods).

## Checks and finding

Read pinned AGENTS, OPERATING_PROTOCOL, lane-05 PLAN, DESIGN, ARCHITECTURE, both adapters, and related native tests through `git show`; inspected patch scope and XcodeGen discovery. No edits to product/tests, builds, native execution, or toolchain recreation.

**Recommend integrating the test patch; no blocking source or test defect found by inspection.** Continuing UUIDs retain the four SceneKit nodes through the cache at `SpatialPreview.swift:347–368,473–479`; fixture/outline geometry changes are restricted to initial creation, kind, or rectangle dimensions (`371–401`). Removal and invalid input clear the lamp cache (`95–104,230–235,348–354`). RealityKit similarly retains per-UUID entities and resets invalid/removed lifetimes (`StudioEntityGraph.swift:69–124,196–246`). This is source evidence, not runtime acceptance.

The new assertions are substantive: captured object references, live parents, lookup results, geometry identity, source type, dimensions, authored planes, and detach/reattach transitions would detect rebuilds or stale geometry. One-axis rectangle edits distinguish width/height invalidation. The single-light discovery helper asserts candidate counts before unwrapping (`SpatialEntityUpdateTests.swift:33–67`), so its identity checks are not vacuous. Internal APIs and scalar types appear compatible; `project.yml:35–44` includes the new file automatically. Compilation remains unverified.

## Targeted remaining gaps

- Existing removal/invalid recovery tests retain only the fixture (`SpatialInteractionTests.swift:50–85`). To prove the full lifetime guarantee, retain source, stand, and indicator too; assert old attachments/lookups are rejected and every newly created node differs after removal or invalidation. The three new tests do not extend this coverage.
- Add a valid aim → coincident aim → recovered aim transition. The new helper requires a live `SCNLight` and one emitting source, so it cannot exercise this case. Production retains the source **node** but removes/recreates its `SCNLight` component (`SpatialPreview.swift:411–428`); component identity must not be generalized from the current tests. Mixed-light membership/reordering remains covered only for fixture identity by existing tests.
- Minor internal consistency gap: hit registration compares Double height (`405`) while attachment compares Float height (`447`). A value such as `0.0500000001` can register a detached stand. `lightID` requires `parent === content` (`155–158`), so this is **not** a demonstrated stale-selection defect. Reusing one threshold decision and adding a boundary case would harden the map invariant; it does not block this patch.

Evidence disposition: tests authored and unrun. No native/runtime pass claimed; prior portable results or CI `45817222487` at source `68` do not validate these pinned revisions.
