# Wave07 interfaces review

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Outcome: renderer boundary confirmed by source review; no new scoped defect.**

`App/RealityStudioPreview.swift`, `RealityStudioPreview.surface`, selects SceneKit `SpatialPreview` under `#if targetEnvironment(simulator) && arch(x86_64)`. This covers every x86_64 simulator runtime, independently of test flags. Supported arm64 simulators and physical iOS devices select `RealityStudioSurface`. The conditional precedes `makeCoordinator()`, whose stored properties eagerly create `StudioEntityGraph`, anchors and camera. Consequently, the fallback never reaches `StudioGeometryResources` mesh/shape generation or ARView construction through this wrapper. Its `previewNote` branch also avoids the graph reference.

RealityKit imports and implementation declarations remain outside that conditional. `project.yml` includes all `App` sources, targets iOS 17, and specifies Swift 5 language mode: Intel native builds must still type-check RealityKit implementation sources. Inclusion does not demonstrate execution. `Package.swift` targets LightingCore only (iOS 17/macOS 14); package tests exclude App. `.github/workflows/ios-prototype.yml` performs Linux syntax parsing, then Intel simulator Debug test-bundle and Release app builds; this review ran none.

`App/StudioView.swift.workspace` passes scene/selection/Fit plus generation/live-UUID callback guards. `cameraPreview` explicitly uses SceneKit on all supported architectures. The documented lane01 first-save identity request remains with its owner.

Pinned directives, architecture/design/acceptance, OWNER_REQUESTS, GEOMETRY_COMPARISONS and `docs/parallel/05/validation/NATIVE-9725fb1.md` were read. That receipt records 176 native methods/30 spatial methods at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`, with Debug test-bundle and Release app builds. Eight later tests and the RK rectangle correction require current-source evidence. RealityKit execution, delivered gestures, device performance and manual VoiceOver remain unestablished.

## Key input blobs

- `App/RealityStudioPreview.swift`: `e4f763a15408c623912bbcdcd9b4296ec8418ae1`
- `App/SpatialPreview.swift`: `c2dd825e406c505ded8291120bc4121f7bf35b79`
- `App/StudioEntityGraph.swift`: `35723305af3242e24c63e14196def45022d0519c`
- `App/StudioView.swift`: `54ad56507484decafb467921dab801e26bfaa6dd`
- `project.yml`: `056e9d4159ca0273f812728381723b60a253000f`
- `Package.swift`: `a574497006b00a96ee33d29439b1da5be8eb9363`
- `.github/workflows/ios-prototype.yml`: `55e68ee810a4dbe72cd8bd5c4aba295958f80d7c`

GitHub connector reads only; no host probes, builds, edits or children.
