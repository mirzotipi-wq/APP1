# Wave10 — Accessibility and privacy

Production: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`. Documentation: `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`.

**Disposition:** No new demonstrated lane05 defect; no changes proposed. Executed source/receipt reads, hashing and original PNG viewing; no tests, builds, installations, native execution or CI polling.

- `App/SpatialPreview.swift:73–162,195–240,490–523` gates disabled/inactive/unavailable input; custom selection checks callback, window and VoiceOver. SceneKit retains its built-in camera controller, whose assistive-technology behavior is unverified.
- `App/RealityStudioPreview.swift:70–89,144–225,247–288` constructs `.nonAR` with automatic session configuration disabled. Inactive/off-window transitions remove anchors; every custom navigation/selection handler rechecks rendering, enabled state, valid scene, window and VoiceOver. This supports source configuration, not observed camera/network behavior.
- `App/StudioView.swift:506–512,554–565,657–719,926–948,1220–1225` supplies guarded equipment-list selection, selected traits/checkmarks, 52-point rows and 44-point Fit. Dynamic fonts and vertical mode choices support accessibility, but maximum-type 3D Fit/overlay reachability remains unverified. `UITests/StudioAppAccessibilityUITests.swift:103–127` checks modes while staying in Plan.

`NativeTests/SpatialInteractionTests.swift:8–16,88–104` checks disabled interaction and teardown properties. Its negative delegate assertion lacks callback and UIWindow, preventing isolated disable/window/VoiceOver conclusions; callback tests invoke closures directly.

Supplemental root working `docs/parallel/05/captures/receipt-full-app-60059a0.json` and its original PNG were hashed/viewed. They support the passing 3D/Fit/simulator-manual-fallback action flow; export remains **9 passed/1 failed**. The capture partly obscures Fit at that scroll position and establishes neither manual accessibility nor resulting camera pose/navigation gestures.

Preserve native pending at **16:40:42 UTC**. Root reported unit-step success at **16:43:45 UTC**, with accounting/finalization pending; prior **184/38** cannot establish current **185/39**. Root owns that receipt; lane01 owns presentation-identity integration. Supported RealityKit runtime, manual accessibility/privacy and whole-app audits remain unverified. Four executor interruptions and wave01 summary-only recovery remain explicit. No deallocation, renderer-thread atomicity, FPS/device or measured token-compliance claim. Detailed anchors/hashes: `evidence.md`, `evidence.json`.
