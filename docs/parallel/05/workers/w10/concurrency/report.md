# WAVE10 — concurrency

**Disposition:** no new concrete adapter defect demonstrated; no source changes.

Inspected `App/{RealityStudioPreview,StudioEntityGraph,SpatialPreview,StudioView}.swift` and `NativeTests/{SpatialInteractionTests,SpatialSelectionLifetimeTests}.swift` at production `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`. Read AGENTS, architecture/design/current acceptance and lane handoff/regression/owner documentation at `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`; campaign baseline is `f150f98e35dd735927075aac4d2f8b02295c6a67`. Exact paths, anchors and input hashes accompany this report in `evidence.json`. Executed pinned reads and hashing only; no builds, installations or native execution.

Both adapters refresh callbacks before unchanged-scene shortcuts. Invalidity/removal discard old equipment ownership; later UUID reuse cannot validate retained old roots. Current ancestry, visibility and live ownership gate lookup. Disabled/inactive/offwindow delivery guards were inspected in source.

RealityKit lookup can still resolve retained coordinator-owned graph objects after anchor/view detachment; handler/current-scene/window/rendering/callback gates separately block delivery. SceneKit dismantling clears maps, children and view attachments while retaining its two fixed `let` nodes. RealityKit retains its graph until coordinator release. Normal recreation constructs a new coordinator. These are ownership/disconnection findings, without deallocation proof.

Inspected tests directly invoke callback, lookup, delegate and teardown methods. The disable test has neither callback nor UIWindow, so its negative delegate result does not isolate disabled/offwindow behavior; view flags and teardown assertions are narrower. MainActor isolation and nonanimated SCNTransaction do not establish renderer-thread atomicity. Delivered touch gestures, scene-phase delivery, RealityKit runtime, device/FPS and manual-accessibility acceptance remain unproved.

**Owner dependency:** integrate lane 01's documented presentation identity, then verify hosted/native first-save retention and project replacement with overlapping UUIDs. Frozen `StudioView` still uses `.id(generation)` and captured-generation/live-UUID guards.

Root-supplied status: current 185/39 remains pending at **16:30:01 UTC**; predecessor 184/38 is not transferred. Export UI has one failure and nine passes; its passing 3D/Fit/manual-fallback action does not establish camera pose or orbit/pan/pinch delivery, and viewport causality for failure is unestablished. Four executor outages and wave01 summary-only recovery remain explicit; newer receipts supersede historical cutoffs separately.
