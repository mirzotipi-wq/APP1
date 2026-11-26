# Lane 05 / wave 04: platform and projection

Canonical ID: `/root/w04_acceptance/platform_performance`  
Input: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`.

**Disposition: conditional clipping counterexample; native reachability remains unverified.** SceneKit Fit assigns `zFar = fittedDistance + 750` once (`SpatialPreview.swift:272–286`). Native controls remain enabled; subsequent ordinary updates/layout do not recompute depth limits. `SpatialOrbitState` gesture clamps constrain RealityKit only. RealityKit refreshes its far distance after every gesture (`RealityStudioPreview.swift:241–270`).

For any fitted distance d, backward movement of 1,000 m makes the fitted center depth d+1,000, exceeding fixed far d+750 by 250 m. The independent Python witness also places an entire hypothetical 1 m equipment sphere beyond far. This proves clipping **if** the active native camera retains manual clipping; it does not prove SceneKit's actual camera handoff behavior.

Apple documents [pinch as FOV change and three-finger movement as translation](https://developer.apple.com/documentation/scenekit/scnview/allowscameracontrol?changes=l_1). Pinch alone therefore does not establish this depth failure. The same documentation says native control creates a separate camera. [Automatic depth adjustment defaults false, and assigning near/far resets it false](https://developer.apple.com/documentation/scenekit/scncamera/automaticallyadjustszrange?changes=_3&language=objc); the free camera's effective behavior still requires observation.

**Focused next check:** host the real preview, Fit, trigger a genuine native camera gesture, then record renderer/controller camera identities, transforms, FOV, near/far, automatic-range flag and projection. On that active controller, translate backward using `translateInCameraSpaceBy(x:y:z:)`; after a rendered frame, inspect equipment corner depths/projections and capture the image. Record any framework clamp/automatic projection update. `evidence.md` specifies the branches and Fit recovery. Do not implement a speculative repair before this check.

Projection review found the RealityKit Float-180 rejection present; math samples reject zero and 0.00001×1,000 layouts, accepting 1×1,000. Zero layout leaves RealityKit Fit pending; SceneKit chooses its smaller FOV axis after layout. Geometry resources/node identity are reused by source, without a performance measurement.

Actual checks: pinned `git show` review of directives, architecture/design/acceptance, four owned adapters and matching tests; official Apple documentation; `python3 witness.py` arithmetic assertions. No repository edits or commits. Created this report, `evidence.md`, `witness.py`, `witness.json` and source hashes. No Swift/build/native/device/VoiceOver/RealityKit/performance execution; historical CI counts are not current acceptance.
