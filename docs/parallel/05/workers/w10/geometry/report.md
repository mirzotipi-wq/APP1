# Wave 10 geometry review

**Disposition:** No concrete geometry defect or false comparison claim demonstrated; no source changes requested.

**Pins and scope:** source `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; documentation parent `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`. Inspected `App/SpatialViewportGeometry.swift`, `App/SpatialPreview.swift`, `App/StudioEntityGraph.swift`, `App/RealityStudioPreview.swift`, Core frames/bounds, relevant NativeTests, and `docs/parallel/05/GEOMETRY_COMPARISONS.md`. Read AGENTS, architecture, design, acceptance and HANDOFF. Exact input paths/hashes and anchors are in `evidence.json`.

SI meters, full right/up/normal bases, native negative-Z emission adaptation, defined front-plane offsets, authored roll and full rectangle-face dimensions match the comparisons. Core geometry files inspected are unchanged from baseline. Display bounds include bust, camera/lens, housing/outline, floor-anchored stands and aim-marker volume; floor/grid remain excluded.

Outward Float conversion selects `nextUp` only when nearest rounding narrows the ideal angle, then rejects enclosing angles reaching 180°. The regression declares six accepted and two rejected layouts. Native matrix construction and RealityKit runtime remain unverified by this review.

Native coverage is **26 projection checks**: eight bounds corners across two layouts, plus five housing/stand points across two layouts. Independently tallying the preserved wave-08 receipt gives **15 scenes, 760 primitive instances and 240 modeled frustum cases per model** (15 × 4 × 4). That receipt pins preceding source4e694bc and uses ideal/Float-angle-only models; it is not native rendering or a current-source execution.

**Executed:** read-only Git inspection/diffs and Python receipt-count/hash inspection. No builds, installs, native tests or witness scripts executed.

**Dependencies/history:** At the pinned **2026-11-26 16:23:18Z** cutoff, current 185/39 remains inventory; preceding 184/38 does not transfer. Acceptance must append any newer exact-source receipt separately. Lane 01 presentation identity integration and supported RealityKit execution remain owner dependencies; Core remains lane 06-owned. Four executor outages and wave-01 summary-only recovery remain explicit. No deallocation, renderer-thread atomicity, FPS/device or manual-accessibility acceptance claim.
