# W05 platform/performance — acquisition boundary

Worker: `/root/w05_acceptance/platform_performance`  
Frozen input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`  
Disposition: source/API review complete; native behavior unexecuted. No source edits, builds, installations, or tests.

## Finding

RealityKit’s tap handler acquires one entity with `entity(at:)`, then walks ancestors through `StudioEntityGraph.lightID(for:)`. Resolution requires enabled ancestors, a current indexed light root, and that root’s direct ownership by the graph anchor; the handler additionally checks the current scene’s light IDs. Apple documents that acquisition ignores entities lacking a collision component.[1]

Only point, housing, stand, and feet receive collisions. Face, outline, aim markers, subject, camera, floor, and grid do not. Consequently, manually resolving a decorative descendant verifies ownership, not its acquisition by a screen tap. A tap over the face may still intersect housing behind it.

SceneKit calls `hitTest(..., options: nil).first` and resolves only that result’s node. The resolver checks visible ancestry, current identity, direct content ownership, and current-scene membership. Apple documents hit testing as geometry search along the screen-point segment.[2] If the first result is non-equipment, this handler returns without considering later results.

**Source/API inference:** non-colliding scenery cannot intercept RealityKit acquisition, while a non-equipment first SceneKit result blocks selection. This is an acquisition-contract difference; actual projection, gesture delivery, and occlusion behavior remain unmeasured.

## Runtime/evidence limits

The `targetEnvironment(simulator) && arch(x86_64)` surface branch returns `SpatialPreview` before constructing the RealityKit surface/coordinator/graph. This establishes fallback routing for that entry path, not RealityKit support.

Parent-supplied inventory: frozen `deff` has 180 native/34 spatial tests discovered, unexecuted; the separate three-test addition gives 183/37, also unexecuted. Historical `68c83` 171/25 passing evidence covers the SceneKit fallback, not RealityKit or `deff`. No device, latency, thermal, frame-rate, or leak conclusions follow.

One remaining native check: on a RealityKit-capable runtime, project a housing/foot and overlap it with subject geometry; record acquired entity and resolved UUID, then compare SceneKit’s first result at equivalent taps.

Source anchors: `App/RealityStudioPreview.swift` (surface/selectLight), `App/StudioEntityGraph.swift` (lightID/resources/lamp construction), `App/SpatialPreview.swift` (selectLight/lightID), read via pinned `git show`.

[1]: https://developer.apple.com/documentation/realitykit/arview/entity(at:).md
[2]: https://developer.apple.com/documentation/scenekit/scnscenerenderer/hittest(_:options:).md

