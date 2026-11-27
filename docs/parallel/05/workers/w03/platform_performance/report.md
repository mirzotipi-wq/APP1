# Wave 03 — platform/performance

- Canonical ID: `/root/w03_acceptance/platform_performance`
- Product: `35283bed09c609be424df80f36b42391aec19f74`
- Test patch: `44550b6837656e86f4fa7b588ac4cfe7a9b1c361` (direct child of product; one new 217-line file, three tests).
- Disposition: **approve by source; native compile/execution remains unverified.** No source-visible integration blocker found.

## Checks and findings

Read pinned AGENTS, protocol, lane plan, architecture/design; reviewed patch, existing tests, update paths, domain bounds, project/workflow/accounting. `git diff --check 35283bed… 44550b…` exited 0. No compiler, build, native execution, or product edits.

1. **Compile/API:** The patch follows `SpatialEmitterGeometryTests` imports, main-actor XCTest, transaction flush, and transform assertions. Internal preview/coordinator members exist (`SpatialPreview.swift:18–38,150,174,200,204`); constructors match `Scene.swift:29` and `StudioOptics.swift:28`. Three synchronous test methods have bounded loops and deferred teardown. No source-visible access/signature mismatch; SDK compilation remains unverified.

2. **Discovery:** `project.yml` includes all `NativeTests`. `native_test_shards.py:74–89,123–134,208–209` selects the unit target and inventories its methods; the new class conforms. Workflow `ios-prototype.yml:195–208,253–294` builds/runs that target and verifies method accounting. No class-list amendment needed.

3. **SceneKit:** Valid scenes cap lights at 12 (`Scene.swift:64`). UUID removal detaches nodes/indicators; maps are repopulated (`SpatialPreview.swift:347–367`). Shape changes replace geometry/materials (`371–400`); pose/output edits retain geometry/materials and reuse valid lights (`410–446`). Stand threshold crossings reuse the cylinder (`447–458`). Tests assert identities/counts, not allocations. Degenerate aimed frames remove the light (`426–427`), outside these tests' identity promise.

4. **RealityKit:** Shared meshes/shapes, fixed grid/outlines, and UUID removal bound retained structure (`StudioEntityGraph.swift:62–65,100–121,170–185,242–244`). Geometry/output changes still construct material values, replace arrays, and set/remove light components (`249–256,309–338`). Stable entities do **not** establish allocation-free updates or measured performance.

## Evidence boundary

Parent reports CI `45817222487` succeeded at `68c83`: 171 tests, zero failures/skips, 25 spatial. Product `35283bed…` and patch `44550b…` remain unexecuted. Exact integrated-source native evidence is still required.
