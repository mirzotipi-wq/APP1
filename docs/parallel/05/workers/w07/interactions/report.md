# Wave07 interactions review

Source: `mirzotipi-wq/APP1@4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree `0f090891cb010ca03ef105fad808878b23f2eb16`. Read-only review; no builds, probes or edits. No new concrete lane 05 interaction failure established.

## Ownership and transitions

- `App/SpatialPreview.swift`: `allowsCameraControl` delegates navigation to SceneKit. `Coordinator.refreshSelectionGesture` makes selection wait for installed pan, pinch, rotation and multi-tap recognizers; mode toggles refresh those dependencies. This is source ordering, not demonstrated UIKit arbitration.
- `updateInteractionState` gates the view for enablement, content availability and orbit mode, stopping inertia when disabled. `gestureRecognizerShouldBegin` additionally checks callback, window and VoiceOver for the custom selection recognizer; those checks do not gate every built-in camera gesture. Window removal stops inertia; dismantling removes callback, recognizer, scene and ownership maps.
- `updateView` refreshes callbacks before its unchanged-input return. Invalid input hides content and discards equipment while retaining the last applied mode. Undefined authored camera clears point-of-view. Recovery preserves an existing orbit or fits when returning from camera mode. Live ownership/membership checks reject stale hit nodes.
- `fitOrbit` resets camera, target, projection and clipping on initial orbit, mode return or changed Fit request. Ordinary edits preserve camera/target; `OrbitAwareSceneView.layoutSubviews` changes projection axis without recentering.

## Evidence boundary

`NativeTests/SpatialInteractionTests.swift`, `NativeTests/SpatialPreviewTests.swift`, `NativeTests/SpatialNavigationRecoveryTests.swift`, `NativeTests/SpatialViewportStateTests.swift` and `NativeTests/SpatialSelectionLifetimeTests.swift` cover direct callbacks, node identities, camera-property mutations, recovery, helper math and SceneKit projections. They do not deliver UIKit gestures or establish whole-app workflows. Captures use `SCNView.snapshot()` in UIWindow.

`App/RealityStudioPreview.swift` uses `SpatialOrbitState` for its custom gestures; its gesture clamps and all-gesture window/VoiceOver gate do not apply to SceneKit’s built-in controls.

`docs/parallel/05/validation/NATIVE-9725fb1.md` records run 45826141504/job 139935031405: 176 methods/30 spatial passed plus Debug/Release builds. Current expected 184/38, eight later methods and the RK rectangle correction await native receipt. RealityKit execution, delivered gestures, manual VoiceOver and device performance remain unestablished.

Lane 01’s first-save `.id(generation)` request remains external in `docs/parallel/05/OWNER_REQUESTS.md`; no speculative fix proposed.
