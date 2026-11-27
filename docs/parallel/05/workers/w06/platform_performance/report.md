# Wave06 lane05 — platform/performance boundary

Canonical ID: `/root/w06_acceptance/platform_performance`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`.

## Finding

Validated authored inputs keep the inspected upload arithmetic finite. Coordinates, including explicit aim targets, must be finite within ±100 m; rectangle dimensions are 0.05–4 m and roll is finite within ±180°. SceneKit gates content on scene validation; RealityKit gates its graph through validating `StudioSceneBounds`. Thus Float endpoint deltas are bounded by 200 m per component. Sources: `Sources/LightingCore/Scene.swift:12,74`; `Sources/LightingCore/StudioOptics.swift:38`; `Sources/LightingCore/StudioSceneBounds.swift:15`; `App/SpatialPreview.swift:208`; `App/StudioEntityGraph.swift:70`.

Both adapters upload the Core emitter basis, preserving authored roll rather than reconstructing source orientation from Float endpoints (`App/SpatialPreview.swift:294,424,436`; `App/StudioEntityGraph.swift:262`). Core normalization rejects zero direction, with no minimum emitter distance (`Sources/LightingCore/SurfacePhotometry.swift:9`; `Sources/LightingCore/StudioOptics.swift:58`).

One Python `struct.pack/unpack` IEEE32 witness, not native execution: source x=80, target x=80+1e−7 gives Double delta `9.9999994063182385e−08` and normalized +X; both Float endpoints equal 80, so Float length is zero. RealityKit requires `frame != nil && length > 0.0001`, hiding both aim markers before division; the fixture/source basis remains Core-derived. This confirms the existing guard covers the collapse witness (`App/StudioEntityGraph.swift:297,307`). `SpatialViewportBounds` may conservatively retain the Core-valid target (`App/SpatialViewportGeometry.swift:31`). Independently, `CameraFraming` requires distance ≥0.05 m; that is a camera contract, not an emitter threshold (`Sources/LightingCore/CameraFraming.swift:36,49`).

## Source/platform matrix

| iOS route | 3D renderer |
|---|---|
| x86_64 simulator | SceneKit fallback |
| ARM simulator/device | RealityKit |

The conditional precedes RealityKit coordinator construction (`App/RealityStudioPreview.swift:30`). `project.yml` includes all `App` sources in the iOS 17+ application; source inclusion does not establish RealityKit execution. Architecture retains SceneKit for authored-camera preview (`docs/ARCHITECTURE.md:10`).

## Evidence limits

Lead-supplied candidate `e66319bf8ee54925ae2121154adfbc4a6bbd099c` changes rectangle face scale and one SceneKit recovery test; no guard/navigation edit. Historical receipt 9725/run 45826141504 reports 176 total/30 spatial passes. Candidate inventory 184/38 includes eight unexecuted methods; queued run 45838950713 supplies no result to this review. No builds, native runs, or source edits here. RealityKit runtime, device, VoiceOver, and performance remain unverified; no FPS, latency, or allocation claim.
