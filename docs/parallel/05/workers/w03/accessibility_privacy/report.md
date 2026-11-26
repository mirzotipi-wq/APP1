# Wave03 accessibility/privacy

Canonical ID: `/root/w03_acceptance/accessibility_privacy`
Input SHA: `35283bed09c609be424df80f36b42391aec19f74`
Outcome: no scoped source blocker; native acceptance unverified.

## Actual checks

Pinned `git show` review of AGENTS, operating protocol, lane05 PLAN, architecture/design, three viewport adapters, focused StudioView handlers and SpatialInteractionTests; scoped privacy-token search; adapter diff against `68c83`. No product edits/builds/native execution.

## Findings and references

- Noncolor selection survives reuse: persistent SceneKit indicators receive selection visibility outside geometry updates; an enlarged wireframe supplies the cue (SpatialPreview:243–245,348–400). RealityKit preserves UUID roots and updates selection-only changes, outline dimensions and aim availability (StudioEntityGraph:100–124,242–250,278–308). Powered-off fixtures retain selection cues.
- Disabled/lifecycle state remains guarded: SceneKit applies enabled/active state after every SwiftUI update, disables input/stops inertia, discards invalid identities and clears callbacks/gestures on teardown (SpatialPreview:73–162,195–245). RealityKit gates interactions on rendering, enabled state, current scene, window and VoiceOver; removes anchors when inactive/off-window; refreshes callbacks; tears down handlers (RealityStudioPreview:144–225,273–288). Disabled/detached entity hits fail ownership checks (StudioEntityGraph:127–136).
- Equipment-list fallback remains outside mode selection: named text buttons, settings, checkmark shape, selected accessibility trait and 52-point minimum rows; UUID/generation guards reject stale actions, and busy-state disabling covers rack/workspace (StudioView:109–115,506–512,912–949,1220–1225). Actual spoken output/reachability was not tested.
- No scoped new privacy surface: no network, telemetry, persistence or permission-request path found; non-AR view disables automatic session configuration (RealityStudioPreview:70–80). Adapter diff from `68c83` changes only aim-target scale (StudioEntityGraph:303).

## Limits

SpatialInteractionTests:19–105 contains relevant reuse/stale-hit/disable/teardown regressions; none ran here. Parent reports historical `68c83` CI `45817222487`: 171 passed, zero failed/skipped, all 25 spatial tests passed; root viewed two original SceneKit captures. Not independently verified here. Pinned `35283`, patch `44550b6`, and reported integration `956a3b1` remain without native execution established by this review. No device/VoiceOver pass claimed.
