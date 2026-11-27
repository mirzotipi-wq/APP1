# Wave09 implementation review

Pinned source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree: `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`; baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.

**Finding: no concrete reproducible adapter defect established.** Read-only review; no source edits, tests, builds, toolchain installation or ref changes.

Inspected `App/SpatialPreview.swift`, `RealityStudioPreview.swift`, `StudioEntityGraph.swift`; native `SpatialSelectionLifetimeTests`, `SpatialInteractionTests`, `SpatialNavigationRecoveryTests`, `SpatialEntityUpdateTests` and `SpatialPreviewTests`; startup/architecture/design/acceptance documents; lane05 wave05/wave07 implementation reports, native checkpoint and exact log.

SceneKit replaces or clears `onSelect` before its unchanged-scene early return. The identical-scene regression directly invokes callbacks A/B/nil while checking equipment and orbit preservation. Invalid input hides content, disables interaction, clears callbacks/maps and detaches fixture/source/stand roots. Retained indicators may remain beneath detached fixtures. Deletion/reinsertion and invalid/recovery tests require fresh equipment identities and reject every retained stale hit.

Normal reconstruction uses a fresh `makeCoordinator`. SceneKit teardown removes gesture targets/delegates, stops inertia, clears scene/point-of-view/callbacks/caches and detaches content/camera. Manually attaching the already-dismantled coordinator is unsupported reuse, not a demonstrated reopen defect. The dismantling regression verifies cleared ownership and hit rejection; its retained nodes cannot establish deallocation. No dedicated full SwiftUI reopen test was found.

RealityKit refreshes its nonoptional callback every update. Invalid input leaves that latest closure stored but sets `currentScene` nil, blocks dispatch, and disables the graph/removes lamps. Inactive/offwindow transitions remove graph/camera anchors while retaining orbit and geometry for reattachment. Disable gates gestures without requiring graph destruction. Teardown clears view closures, gesture targets/delegates and selection callback and removes anchors; graph resources remain coordinator-owned until release. Anchor removal is not evidence of deallocation.

MainActor update ordering has no suspension between state changes. SceneKit applies environment gating after geometry; RealityKit applies enable/activity before scene update. Selection additionally checks window presence. These environment/offwindow paths were source-traced, not delivered-gesture tested.

Evidence: source `4e694bc`, run 45838950713/job 139980771221 passed 184/184 native, including 38 spatial (28 SceneKit/10 helpers), plus Debug/Release builds. Reviewed lifecycle bodies are unchanged; 60059 changes the FOV helper and adds one regression. 185/39 is inventory, not a reviewed 60059 native pass. RealityKit runtime, reopen/deallocation, device, VoiceOver, FPS/RSS/thermal remain unverified.

