# Resource ownership review

canonicalID: `/root/w04_acceptance/resources`
inputSHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

Outcome: no accumulating navigation graph or local callback cycle identified. Counts describe application-held objects; framework/controller internals and GPU allocations are excluded.

| Ownership/transition | RealityKit | SceneKit |
|---|---|---|
| Fixed holders | 53 graph entities + orbit anchor/camera = 55; 2 shared meshes, 2 collision shapes, 4 recognizers. | 8 explicit nodes; 1 scene/camera component/ambient light, 5 fixed geometries, 1 selection recognizer. |
| Per UUID | 24 entities: 4 groups/emission, 8 models, 12 outline models. Globally at most 7 authored shading components + fixed fill. | 4 nodes: fixture/source/indicator/stand; up to 3 geometries, 1 source light. Detached stand retained for reuse. |
| Orbit/pan/zoom/Fit | Gestures mutate orbit/camera only. Fit scans bounds; graph update computes bounds before equality guard. | Native controller navigation; no app graph rebuild callback. Fit scans bounds, reuses camera; updates scan identity/selection collections. |
| Invalid; remove/readd | Clears lamps/hit maps; retains disabled fixed graph. Readdition creates fresh lamp. | Clears equipment/maps; retains hidden base/camera. Readdition creates fresh nodes. |
| Window detach/reattach | Removes/readds same anchors; retains graph/orbit. | Stops inertia/playback; retains nodes/controller. No explicit playback restart or graph reconstruction on reattach. |
| Dismantle | Clears closures, gesture targets/delegates, callbacks and view attachments. Graph/resources remain coordinator-owned until release. | Clears callback/gesture, scene/pointOfView, children/maps/base; retains empty content and camera node/component until coordinator release. |

Views are weakly held; RealityKit callbacks capture self weakly. Selection callbacks replace prior storage and clear on dismantle. External captures remain unproven. Fit/representable updates are not constant-cost navigation.

Commands/checks: `git show 9725fb1177a5c7afbdf798ffd627e65e604c75b1:<path>` reads exited 0; manual ownership/transition tracing completed. Read AGENTS/startup, architecture/design/code-acceptance docs; four assigned App files; native SpatialEntityUpdate/Interaction/Preview/EmitterGeometry/ViewportState and StudioViewportGeometry tests. Tree reads located files; report checked with `wc -w -c` and `sha256sum`.

Existing assertions cover 100 repeated updates retaining count/identity, callback refresh, geometry/node reuse, stand reattachment, stale hits after removal/invalid recovery, and SceneKit dismantle. They do not establish deallocation or RealityKit/window lifecycle behavior.

files/commits: source edits none; commits none; report only.
Limits: no build/toolchain/native/test execution, profiling, telemetry, allocation/RSS/timing or acceptance claims. Historical results not rerun/promoted.
