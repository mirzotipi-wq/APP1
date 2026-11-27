# Wave 08 interactions review

**Canonical ID:** /root/w08_acceptance/interactions  
**Status:** completed_visual_and_source_review  
**Frozen source:** 4e694bc377c4825d1d2dd52fcd7900e534c75072

**Finding:** No clipping defect is visible in these two fitted SceneKit scenes. Readability and interaction evidence remain limited.

I actually opened all four original PNGs with `view_image`: ordinary/crowded at 9725fb1 and 4e694bc. Both receipt files were read; PNG sizes and full SHA256 values match their receipts, and each fresh/earlier pair is byte-identical. Full provenance is retained in `provenance.json`.

Both rigs have clear viewport margins, including modifier tops and visible stand bottoms. The ordinary head/torso is recognizable, although the torso and floor have subdued separation. Its selected point light mainly reads as a yellow spot; the distinct outline is less readable than the crowded rectangle’s. The crowded scene retains a visible yellow outline on the far-right selected modifier. Foreground panels hide most of the torso and overlap other equipment. Thin gray stands fade against the dark floor. The camera body is small and dark in ordinary, and overlaps a foreground panel in crowded; lens direction is not readily legible.

Frozen `App/SpatialPreview.swift` accepts the first SceneKit hit, then resolves only live fixture/stand ancestry and current UUIDs; foreground occlusion therefore does not establish access to hidden lights. Tap recognition waits for camera recognizers. Callback publication precedes the unchanged-scene return. `App/RealityStudioPreview.swift` similarly guards active/window/current-scene selection and defines orbit, two-finger pan, pinch and tap arbitration.

`SpatialInteractionTests` and `SpatialSelectionLifetimeTests` directly check callbacks, ownership, removal/reintroduction, availability and camera state. Direct callback invocation does not prove hit delivery. The capture method embeds SCNView in UIWindow and snapshots it, without a SwiftUI/full-app host or delivered gesture.

**Still unproven:** actual taps on fixtures/stands/occluded or empty areas; selection after delivered orbit/pan/pinch/double-tap; scroll-versus-preview arbitration; Fit-button delivery; manual VoiceOver; physical-device and RealityKit runtime behavior; photometric fidelity.

`docs/parallel/05/validation/NATIVE-4e694bc.md` records run 45838950713/job 139980771221: 184 native/38 spatial passes plus Debug/Release builds on x86_64 iPhone 17 Pro, iOS 26.5/Xcode 26.6, using SceneKit fallback. I ran no native code. The later Float candidate is outside this source and receives no transferred execution or visual claim.
