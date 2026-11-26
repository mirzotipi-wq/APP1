# Narrow evidence: camera projection and native handoff

Worker: `/root/w04_acceptance/platform_performance`. Frozen input: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`. All repository content was read with `git show` at that input. No production or test source was edited; no commit was created.

## Observed source

- `App/SpatialPreview.swift:180–184,246–286`: creates an explicit camera, enables native control outside camera mode, and sets orbit near/far only in `fitOrbit`. `lastFitRequest` and mode transitions gate fitting. `OrbitAwareSceneView.layoutSubviews` changes projection direction only, after positive layout dimensions. No delegate/gesture callback updates native far clipping. Native selection waits for the existing native camera gestures.
- `App/SpatialViewportGeometry.swift`: `distanceRange = 0.45...1500`, target pan clamps of ±300, pitch clamps, and `farDistance = distance + 750` belong to the pure state consumed by RealityKit. SceneKit creates a temporary instance only when fitting.
- `App/RealityStudioPreview.swift:228–270`: invalid/zero projection returns before consuming pending Fit; an accepted layout uploads a Float vertical FOV and camera state. All three navigation callbacks call `applyCamera`, which updates far. The Float-angle guard excludes a rounded 180 degrees.
- `App/StudioEntityGraph.swift`: resources are allocated once per graph; UUID-owned entities persist and shape transforms/components update selectively. This is source evidence of reuse, not memory/frame-time evidence.
- `NativeTests/SpatialPreviewTests.swift`: existing methods inspect fitted native projection, preserve a manually substituted camera during edits, restore Fit, and inspect authored-camera framing. They do not execute distant native controller translation after actual free-camera handoff.
- `NativeTests/SpatialViewportStateTests.swift`: bounded state, pathological inputs and extreme-pan far checks exercise the pure orbit state, not SceneKit's native navigation. `SpatialInteractionTests` and `SpatialEntityUpdateTests` cover graph identity/update behavior; `SpatialEmitterGeometryTests` cover transform conventions.

## Official API evidence

Read 2026-11-26 through web retrieval; only primary Apple material informs API conclusions.

1. [allowsCameraControl](https://developer.apple.com/documentation/scenekit/scnview/allowscameracontrol?changes=l_1): enables native pan/zoom/rotation and creates a separate camera; documents pinch as FOV change, two-finger image-plane translation, and three-finger forward/backward translation. It does not document whether the free camera preserves or changes automatic depth behavior.
2. [automaticallyAdjustsZRange](https://developer.apple.com/documentation/scenekit/scncamera/automaticallyadjustszrange?changes=_3&language=objc): default false; true fits depth at render time to scene bounds; setting near/far disables it.
3. [zFar](https://developer.apple.com/documentation/scenekit/scncamera/zfar?changes=lat_5___1_4&language=objc): geometry beyond far is clipped.
4. [SCNCameraController](https://developer.apple.com/documentation/scenekit/scncameracontroller.md): exposes `pointOfView`, `target`, `beginInteraction`, `continueInteraction`, `endInteraction`, `dolly`, `translateInCameraSpaceBy(x:y:z:)` and angle limits. The API listing does not establish a native translation-distance clamp.

## Conditional arithmetic counterexample

Let d be Fit's camera distance and r the enclosing equipment radius. Its center depth starts at d. Preserve orientation and move the camera backward by Δ along its local positive Z axis. The center depth becomes d+Δ, while an unchanged far plane remains d+750. With Δ=1000, center depth exceeds far by 250. If r<250, every point of the enclosed equipment sphere is also beyond far. This says nothing about whether SceneKit moves, clones, clamps, or auto-adjusts the active camera in practice.

`witness.py` uses r=1 and the source Fit equation; it asserts the resulting far-plane violation and calculates conventional normalized depth. It also uses IEEE Float32 packing to check the source FOV guard's zero/narrow inputs. These are independent arithmetic checks, not app tests. `witness.json` is the actual output.

## Focused native verification packet — NOT EXECUTED

1. Use `LightingScene.portrait()` and the shipped `SpatialPreview.makeView/updateView` in a visible retained UIWindow at 360×280. Keep `allowsCameraControl`, `cameraControlConfiguration` and all native recognizers at production settings. Fit, lay out, flush transactions, and allow an actual rendered frame. Record the equipment bounds and baseline image.
2. Perform a genuine native orbit gesture before the depth probe to exercise SCNView's free-camera handoff. Record identities of `coordinator.camera`, `view.pointOfView` and `view.defaultCameraController.pointOfView`; record the active model/presentation transform, target, FOV, near/far, `automaticallyAdjustsZRange`, and projection matrix. Do not force camera identity or assign a replacement camera to make the probe work. If only direct controller methods are available, label that result controller-only and leave the user-event handoff unverified.
3. Stop inertia. Invoke `view.defaultCameraController.translateInCameraSpaceBy(x: 0, y: 0, z: 1000)` on the actual active controller; positive local Z is backwards for a camera looking down negative Z. Verify the measured displacement and projected center depth rather than assuming the method applied it. If the API moves the target too, use equipment world coordinates, not the new target, for depth. Do not change FOV/near/far/automatic mode in this probe.
4. Flush and render another frame. Capture the same camera diagnostics and actual image. For the eight original equipment-bounds corners, compute positive depth from the active presentation camera's world transform and call `view.projectPoint`. Check finite values and x/y containment separately from depth. A projected Z >=1 or effective projection exclusion while geometry remains in x/y confirms this failure. An automatic-range flag alone is insufficient: inspect the actual rendered projection because auto-range is evaluated at render time. A clamp or a correctly expanded projection disproves this conditional failure for the observed path and should be recorded exactly.
5. Re-run the ordinary scene update without Fit, then increment Fit and check restoration. Separately perform pinch and record whether FOV, camera distance or both changed on the tested OS; do not call FOV enlargement a dolly. Check landscape→portrait→zero→positive layout without changing orbit. Preserve normal geometry identity and authored camera-mode projection.

If failure is reproduced, constrain a repair to the SceneKit adapter and a corresponding native regression: keep the active orbit camera's effective far plane outside the finite equipment bounds after native motion, without resetting its pose/target or changing authored-camera projection. Choose automatic depth or explicit updates only after observing native ownership and the infinite SCNFloor's effect on computed bounds. A larger fixed constant cannot protect unbounded translation.

## Actual execution and limits

Actual reads used `git show 9725fb1177a5c7afbdf798ffd627e65e604c75b1:<path>` with `nl`, `head`, `sed` or `rg` for excerpts. Read AGENTS, operating protocol, handoff/state, product, architecture, roadmap, quality, design and m02-m03-code acceptance. Source digests were computed from pinned git bytes. The only behavioral computation executed was `python3 /tmp/keyfill05-be879deb/waves/w04/platform_performance/witness.py`. No Swift compilation, toolchain probe, app/native test, renderer capture, benchmark, device check, manual VoiceOver session or CI execution occurred here. Historical CI receipts do not validate this native hypothesis.
