# Wave09 interactions review

Source `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`, tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`; campaign baseline `f150f98`. Pinned source/document review only: no builds, tests, probes or source changes. **No new concrete lane 05 defect established.**

## Transition semantics

- **SceneKit:** `SpatialPreview.Coordinator.refreshSelectionGesture` makes selection wait for installed pan/pinch/rotation/multitap recognizers. Navigation remains SceneKit-owned. UUID changes cancel the custom selection tap; invalidity also discards equipment. Enablement/content/mode gates disable view interaction and stop inertia. Window removal stops inertia; the custom tap additionally requires a window, callback and VoiceOver-off state. These are not equivalent to app-owned cancellation of every native camera recognizer.
- **RealityKit:** `RealityStudioSurface.Coordinator` owns orbit/pan/pinch/tap. Changed UUID sets, invalidity, inactivity and window loss disable/cancel all recognizers. Tap waits for navigation; only pan/pinch can recognize simultaneously. The delegate prioritizes viewport navigation over an ancestor scroll pan. These dependency declarations do not prove delivered UIKit arbitration.
- **Continuity:** same-UUID shape edits retain live roots. Both adapters refresh callbacks; hit resolution checks current ownership, while the caller checks generation and live UUID membership (`StudioView.workspace`). Invalid SceneKit recovery preserves an existing orbit or applies a pending mode/Fit transition. Fit resets navigation state; SceneKit also stops inertia. Neither Fit path explicitly cancels ongoing navigation. Resize changes projection without recentering. Actual continued input across those transitions remains unverified. `SpatialOrbitState` bounds apply to RealityKit navigation and SceneKit Fit, not SceneKit’s built-in gestures.

## Evidence and ownership

`SpatialInteractionTests`, `SpatialSelectionLifetimeTests`, `SpatialEntityUpdateTests`, `SpatialNavigationRecoveryTests`, `SpatialPreviewTests` and `SpatialViewportStateTests` assert direct callback invocation, ownership/shape transitions, manually assigned camera properties, recovery and projection/helper math. They do not deliver orbit/pan/pinch/tap sequences through deletion, Fit, background or resize.

`validation/NATIVE-4e694bc.md` records 184/184 native passes, including 38 spatial (28 direct SceneKit, 10 helpers), and Debug/Release builds at **4e694bc**. Current **185/39 is inventory**, with current native execution pending per lead; no current pass inferred. RealityKit runtime, device/manual VoiceOver and performance remain unverified.

Frozen `.id(generation)` retains the known first-save composition issue. The lead reports owner `5ccfbaae` now uses `workspaceResetID` with separate guards; integration/native verification remains pending. No duplicate adapter repair proposed.
