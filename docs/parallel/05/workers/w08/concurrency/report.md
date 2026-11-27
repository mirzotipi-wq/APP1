# Wave 08 concurrency review

canonicalID: /root/w08_acceptance/concurrency
inputSHA: 4e694bc377c4825d1d2dd52fcd7900e534c75072
baselineSHA: f150f98e35dd735927075aac4d2f8b02295c6a67
status: completed_source_review

No new adapter ordering defect identified. A retained adapter preserves viewpoint across ordinary scene/selection/aspect changes. Entering Orbit intentionally Fits; coordinator recreation is another boundary.

**SceneKit:** computes needsFit before publishing valid mode. Invalid input hides/discards equipment and clears callbacks without consuming mode/Fit changes: ordinary orbit recovery preserves viewpoint, pending transitions/Fit still apply. First valid Orbit and explicit Fit publish camera/target/clipping together; only successful Fit advances its token. Undefined authored camera clears pointOfView. Resize changes projection axis only (App/SpatialPreview.swift:204–288, 525–532).

**RealityKit:** refreshes callbacks, validates, cancels gestures for changed UUID sets, then updates geometry. Initial or requested Fit stays pending until usable dimensions and valid scene bounds coexist; ordinary layout only updates FOV and reapplies retained orbit (App/RealityStudioPreview.swift:111–112, 189–205, 228–244; App/SpatialViewportGeometry.swift:88–118).

**Ownership/lifecycle:** MainActor serializes updates. Both adapters validate current graph identity/ancestry and live UUIDs; disabled/hidden roots cannot select. Removed/reintroduced UUIDs cannot revive detached hits. Disabled/inactive interaction is gated. Window removal stops SceneKit inertia or detaches RealityKit anchors while retaining navigation. Dismantling clears callbacks/gesture targets (App/SpatialPreview.swift:73–163, 193–201, 490–495; App/RealityStudioPreview.swift:154–225, 273–278; App/StudioEntityGraph.swift:69–136).

**Limits:** Native tests mutate cameras/call callbacks directly; pure tests exercise navigation math, not delivered gestures or RealityKit runtime (NativeTests/SpatialPreviewTests.swift:60–90; SpatialSelectionLifetimeTests.swift:77–116; SpatialNavigationRecoveryTests.swift:58–134; SpatialViewportStateTests.swift:91–140). No toolchain/tests ran here. 184/38 is inventory; run 45838950713 remains unverified here. Owner .id(generation) recreation and the separately tracked Float-FOV boundary remain outside this conclusion. No patch.

hashes: source/baseline hashes are in input_sha256.json; manifest SHA256 e1eb191d5121568d1aec6b0bb816a7a0900b03c1fca84a7e679ff9ecc27cc675. Report hash: report.sha256.

