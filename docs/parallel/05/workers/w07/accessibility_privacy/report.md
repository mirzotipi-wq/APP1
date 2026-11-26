# Wave07 — Accessibility and privacy

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Outcome:** No newly demonstrated lane05 defect. This was a pinned, read-only source/evidence review; no edits, builds or host probes.

## Source findings

- `App/SpatialPreview.swift:187–190,223–231,498–523`: geometry is normally AX-hidden. An unavailable message sets `accessibilityElementsHidden = false`, exposes a multiline preferred-caption label with Dynamic Type adjustment, and recovery hides both label and AX subtree. This implementation is unchanged from 9725fb1; actual announcement, reachability and large-text clipping remain unmeasured.
- `App/RealityStudioPreview.swift:70–80,154–185`: the surface uses `.nonAR` and `automaticallyConfigureSession: false`; native geometry is AX-hidden, and VoiceOver blocks custom gestures. The reviewed adapter contains no session-start, camera-permission or upload call. This establishes a source boundary, not observed camera/network privacy.
- `App/StudioView.swift:506–512,554–565,722–738,926–948,1220–1225`: spatial/list selection checks generation and live UUID membership; list rows provide a checkmark, selected trait and 52-point minimum height. Fit has a label, 44-point minimum height and reset explanation. Camera fallback instructs moving away from the subject. The existing first-save `.id(generation)` request remains lane01-owned in `OWNER_REQUESTS.md`.

## Executed assertions and limits

`validation/NATIVE-9725fb1.md` and `validation/native-9725fb1.log` record run45826141504/job139935031405: 176 native passes, including 30 spatial, plus successful Debug test-bundle and Release app builds.

- `SpatialInteractionTests.testUndefinedCameraHidesPriorViewAndRecoversAuthoredLens`: nil viewpoint/hidden content, then restored camera, visibility, FOV and forward direction.
- `SpatialInteractionTests.testRemovedAndReintroducedUUIDCannotReuseOldHitObject`: old hit rejected after deletion/reintroduction; replacement resolves the UUID.
- `SpatialPreviewTests.testOrdinarySceneEditPreservesOrbitButExplicitFitRestoresCamera`: ordinary edits preserve orbit; explicit Fit restores camera and bounds target.

These `NativeTests/` files are unchanged; `SpatialPreview.swift` changed, so results remain historical. None of the eight spatial test files asserts unavailable-label AX visibility or Dynamic Type layout.

Current 184/38 execution remains pending. The app accessibility workflow failed at `UITests/StudioAppAccessibilityUITests.swift:263`, waiting for `librarySaveCurrent`; native fallback passes do not satisfy that workflow. RealityKit execution, manual VoiceOver, delivered gestures, device/privacy observation and performance are unestablished.
