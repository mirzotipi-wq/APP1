# Spatial interaction regressions

Source inventory: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`.

There are **39 spatial methods across eight classes**: 11 arithmetic/state methods and 28 direct SceneKit methods. The campaign adds 31 methods to the baseline's eight. At the time of this document, 38 passed at predecessor `4e694bc`; the current source's 39-method result is pending. An earlier source pass does not establish the changed source.

| Class | Methods | Behavior protected |
|---|---:|---|
| SpatialViewportStateTests | 11 | Full housing and marker bounds; horizontal translation; high stands, sparse and crowded fits; non-geometric stability; invalid scene/sample rejection; camera-plane pan; finite navigation limits; bounded far clipping; outward Float projection. |
| SpatialInteractionTests | 9 | Retained metadata/output/selection identity; refreshed callbacks; removed/reintroduced and invalid-scene hits; disable/dismantle; undefined camera recovery; camera −Z lens; bounded repeated node counts; actual narrow projection; real ordinary/crowded captures. |
| SpatialEntityUpdateTests | 3 | Kind transitions, independent rectangle resizing, pose/output geometry reuse, and stand threshold detach/reattach with correct hit ownership. |
| SpatialNavigationRecoveryTests | 4 | Camera-to-Orbit recovery through invalid scenes, including undefined authored camera; retained user camera/target without Fit; valid empty-scene interaction availability. |
| SpatialSelectionLifetimeTests | 3 | Identical-scene callback replacement and clearing; complete old-equipment detachment on deletion and invalidation, including UUID reuse. |
| SpatialAimRecoveryTests | 1 | Translated coincident-to-vertical rolled emitter recovery with retained nodes, source, geometry and selection. |
| SpatialPreviewTests | 3 | Actual translated projection, user-orbit preservation and explicit Fit, extreme sparse framing and authored physical camera mode. Existing baseline methods now compare the represented bounds. |
| SpatialEmitterGeometryTests | 5 | Authored front planes, roll, directional/point centers, housing/stand/selection identity and undefined aim. Existing baseline methods, unchanged by this lane. |
| **Total** | **39** | Exact method-level execution accounting is required. |

The native tests directly construct SceneKit adapters and use actual SceneKit nodes, camera controllers and projection. The capture method attaches SCNView to UIWindow. Direct method calls and snapshots do not prove delivery of touch gestures through the full SwiftUI host, parent scrolling, RealityKit runtime behavior or manual VoiceOver actions.

The current native command is the repository's unchanged unit suite selection. Its existing `scripts/native_test_shards.py verify-log unit` verifier requires exactly one ordered start/pass for every expected method and rejects failures, skips, duplicates and omissions. Logs must be checked against the corresponding source inventory.

Follow the exact execution receipts in `validation/NATIVE-*.md`. The complete final result must be recorded for source60059 before treating its new Float regression as executed.
