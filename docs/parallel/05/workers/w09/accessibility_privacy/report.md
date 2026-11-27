# Wave09 — Accessibility and privacy

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.

**Outcome:** No new reproducible lane05 defect. Bounded, pinned source/evidence review only; no source edits, tests, builds, device observation or CI polling.

## Source findings

- **SceneKit:** `App/SpatialPreview.swift:73–88,136–162,195–240,490–495` disables input for disabled/inactive/unavailable/camera-mode states. Custom selection checks callback presence, window attachment and VoiceOver both before recognition and on delivery; hit resolution rejects hidden, removed or stale identities. Off-window handling stops inertia/playback. These custom-selection checks do not establish equivalent VoiceOver gating for SceneKit’s retained native camera gestures.
- **RealityKit:** `App/RealityStudioPreview.swift:70–89,144–225,247–288` uses `.nonAR` with automatic session configuration disabled. Inactive/off-window transitions remove anchors and disable gestures. Every custom handler rechecks rendering, enabled state, valid-scene presence, window and VoiceOver. Callback refresh and teardown are explicit; `StudioEntityGraph.swift:69–136` rejects disabled/detached identities.
- **Accessible alternatives/status:** `SpatialPreview.swift:187–190,223–231,498–523` normally hides geometry from accessibility, exposes a multiline Dynamic Type unavailable label, then hides it on recovery. RealityKit supplies a separate unavailable note. `StudioView.swift:506–512,554–565,722–738,926–948,1220–1225` supplies generation/live-UUID guarded list selection, a checkmark/selected trait, 52-point rows, 44-point Fit, and camera recovery guidance. These source declarations do not prove delivered reading order or action reachability.
- **Privacy boundary:** The two adapters and graph contain no app-authored network/upload, permission-request or AR-session-start calls. This is a surface source finding, not observed no-network/camera behavior or a whole-app privacy audit.

## Evidence limits

`docs/parallel/05/validation/NATIVE-4e694bc.md` records run45838950713/job139980771221: 184/184 native, including 38 spatial (28 direct SceneKit plus 10 helpers), and Debug/Release builds. Reviewed adapters, graph, callers and selection/interaction tests are unchanged since that receipt; the current helper/regression successor has 185/39 inventory and no current native pass. Root tracks pending execution.

Earlier audit/UI failures and cancellations remain unchanged. RealityKit runtime, manual VoiceOver, delivered gestures, accessibility layout/contrast, device privacy, FPS/RSS/thermal remain unverified. No additional coverage-only tests proposed. Planning targets are not measured token telemetry.
