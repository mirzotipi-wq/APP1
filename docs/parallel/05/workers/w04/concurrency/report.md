# W04 concurrency

canonicalID: `/root/w04_acceptance/concurrency`  
inputSHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

**Confirmed source-order defect:** orbit/Fit0 → camera → invalid orbit → valid orbit/Fit0 retains authored/nil POV. `SpatialPreview.swift:224` records orbit mode before invalid return; recovery computes `needsFit=false` (:212), skipping :263–265. Independently confirms the implementation worker's finding.

## Transition table

| Event | RealityKit | SceneKit |
|---|---|---|
| Initial zero layout | Fit waits for valid size (:228–237). | Fits immediately; layout corrects projection axis (:523–532). |
| Fit while invalid | Stores pending flag; waits for valid scene. | Request unconsumed; recovery fits, except mode defect above. |
| Fit while inactive/disabled | Valid scene/size consumes Fit offscreen. | Valid update consumes Fit before wrapper disables interaction. |
| Re-enable | Restores interaction with rendering/current scene; preserves orbit. | Wrapper refreshes interaction after no-op updates; preserves pose. |
| Window removal | Removes anchors/cancels gestures; reattachment restores anchors. | Stops inertia/playback; selection rejects absent window; no explicit playback resume. |
| Cancellation | ID changes/inactivity disable recognizers; cancelled handlers ignore deltas. | Invalid/ID changes cancel selection; disabling/Fit stops inertia. |
| Callback refresh | Before graph/Fit processing. | Before no-op guard; invalid/dismantle clears callback. |

**Fix review:** conditional `if valid { coordinator.lastCameraMode = cameraMode }` preserves the last applied mode through invalid input without resetting ordinary orbit recovery. Keeping this assignment before availability also preserves initial empty-orbit interaction; moving it below the guard can miss that helper-level refresh.

**Coverage:** inspected native tests cover Fit, edit preservation, orbit-only invalid recovery, callback replacement and disable/dismantle; no mixed-mode recovery, actual cancellation or RealityKit coordinator lifecycle coverage found.

**Checks:** pinned `git show SHA:path`; AGENTS/architecture/design/acceptance/lane plan and numbered source/test inspection. One mistyped architecture SHA failed; corrected read succeeded. `python3 /tmp/keyfill05-be879deb/waves/w04/concurrency/model_check.py` matched four mixed-mode and two same-mode expectations. Exact commands/hashes/model traces: `evidence.json`.

Source edits/commits: **none**. Model-only, not native execution or frame-atomicity proof. No builds, device/RealityKit/VoiceOver/performance claims; historical CI not rerun.
