# Wave 09 — concurrency

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree: `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`. Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.

**Result:** No new reproducible adapter concurrency defect established. Review only; no source edits, builds, tests, toolchain work or ref changes.

Inspected `App/SpatialPreview.swift`, `RealityStudioPreview.swift`, `StudioEntityGraph.swift`, the frozen `StudioView.swift` caller, and `NativeTests/SpatialInteractionTests.swift`, `SpatialSelectionLifetimeTests.swift`, `SpatialNavigationRecoveryTests.swift`, `SpatialEntityUpdateTests.swift`, `SpatialAimRecoveryTests.swift`. Read AGENTS, architecture/design, M02/M03 contract, lane05 wave06/07 concurrency reports and `validation/NATIVE-4e694bc.md`.

- SceneKit refreshes `onSelect` before its unchanged-scene return; RealityKit refreshes it before validation and graph update. Unchanged geometry cannot retain the previous supplied callback.
- Invalid scenes discard equipment ownership; deletion/reinsertion replaces removed roots. Lookup requires current hierarchy ownership. UUID-set transitions cancel recognition. Recovery clears invalid caches, while SceneKit preserves the previously applied camera mode so pending mode/Fit changes survive.
- Disabled/inactive state reaches interaction gating even when geometry is unchanged. SceneKit's selection handler requires an attached window; window removal stops inertia/playback, without an explicit selection-recognizer toggle. RealityKit window/inactive transitions remove anchors and cancel recognizers. Both detach paths remove targets/delegates and clear callbacks; RealityKit retains its graph until coordinator release.
- Inspected updates are synchronous main-actor calls with no suspension or asynchronous callback dispatch. This establishes source ordering, not renderer-thread atomicity. A zero-duration SceneKit transaction does not prove arbitrary renderer concurrency safety.

Regression assertions cover serial updates, direct callback replacement/clearing, retained hit rejection and invalid/mode/aim recovery. They do not deliver recognizer events; the 100-update loop is serial, and node counts are not runtime-performance measurements.

Historical source `4e694bc`, run 45838950713/job 139980771221: 184/184 native, 38 spatial (28 direct SceneKit + 10 helpers), Debug/Release builds passed. The current angle-helper change adds one regression: 185/39 is inventory only here; current native execution remains root-tracked.

Known first-save `.id(generation)` remains in frozen composition. Lead-reported lane01 `.id(session.workspaceResetID)` plus generation/live-UUID guards is unmerged; native retention remains unverified. RealityKit runtime, renderer stress, delivered gestures, physical devices, manual VoiceOver, FPS/RSS/thermal remain unverified.

