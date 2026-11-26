canonicalID: /root/w08_acceptance/accessibility_privacy
inputSHA: 4e694bc377c4825d1d2dd52fcd7900e534c75072
baselineSHA: f150f98e35dd735927075aac4d2f8b02295c6a67
status: completed_source_review
hash: sha256:8752e69a0085ef9cf6da64f2b6aef3910f72e579a3b7e1a8dd71888559a85011 (UTF-8 report body below metadata)

# Wave 08 — accessibility/privacy

Result: completed source review; no new actionable viewport-lane defect established.

**Semantics.** Normal SceneKit and RealityKit surfaces hide implementation children. SceneKit exposes its unavailable UILabel when needed; the RealityKit note is SwiftUI content outside the hidden native surface (SpatialPreview:187,498; RealityStudioPreview:15,78). The surrounding scrollable Lights list provides named equipment buttons, settings, selected traits and a checkmark, with current-UUID/generation guards and busy-state disabling (StudioView:87,111,926). These are source-demonstrated alternatives to visual hit testing; spoken output/order is unverified.

**Interaction and privacy.** RealityKit guards every owned gesture against VoiceOver, disabled state, missing/invalid scene and inactive/detached rendering (RealityStudioPreview:154,170,247). SceneKit guards its owned selection gesture against VoiceOver; its built-in orbit gestures are not explicitly VoiceOver-gated by this adapter. Disabled/inactive SceneKit interaction stops inertia; authored-camera mode prevents interactive selection/control, and undefined framing clears the prior point of view (SpatialPreview:83,136,197,223,248). Invalid RealityKit graphs disable the anchor and remove equipment (StudioEntityGraph:69). RealityKit explicitly uses `.nonAR` with automatic session configuration disabled (RealityStudioPreview:71); the scoped viewport code shows no camera authorization, capture, upload or network path. This is not a whole-app privacy audit.

**NARROW/UNAVAILABLE limits.** The UIKit unavailable label is multiline, centered, horizontally constrained and uses an adjusting preferred caption font (SpatialPreview:504). The SwiftUI note uses caption sizing; the authored-camera fallback supplies explanatory text (RealityStudioPreview:18; StudioView:732). Their enclosing viewport remains 280 points high and clipped (StudioView:520). No practical narrow-layout counterexample was established. Source alone does not prove largest-text visibility, actual contrast, manual VoiceOver behavior, platform audit success or 44-point 3D targets.

No tests were executed in this review. Supplied root evidence—run 45838950713/job 139980771221, 184 native/38 spatial plus Debug/Release—uses the x86_64 SceneKit fallback; it does not execute RealityKit-device behavior or the separate approved Float-FOV candidate. The lane01 first-save `.id(generation)` concern remains an owner request, outside this adapter lane.
