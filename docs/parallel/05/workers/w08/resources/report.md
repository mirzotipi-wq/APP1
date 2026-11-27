# Wave 08 resources source review

canonicalID: /root/w08_acceptance/resources
inputSHA: 4e694bc377c4825d1d2dd52fcd7900e534c75072
baselineSHA: f150f98e35dd735927075aac4d2f8b02295c6a67
status: completed_source_review
reporthash: 1ee0c18e97d4e38b34c9acbbf87e1824c316e06a85a087b42895b2b86a2da861
reporthash_scope: SHA-256 of UTF-8 Findings body, including trailing newline

## Findings
No topology defect identified in the scoped source.

- **Capacity and counts.** Validation caps authored fixtures at 12 (`Sources/LightingCore/Scene.swift:62–64`). For N fixtures and S stands above 0.05 m, SceneKit owns 5+2N+S direct content children and 6+3N+S descendants: the 12-elevated-fixture case gives **41 direct children / 54 descendants**. RealityKit owns **53+24N entities including its graph anchor**: **341 at 12**, including disabled entities; the separately owned orbit-camera anchor/camera add two. These are source-derived counts, not measurements (`SpatialPreview.swift:311–369,449–479`; `StudioEntityGraph.swift:24–66,217–246`).

- **Reuse and replacement.** Both adapters retain lamp objects by UUID. SceneKit preserves fixture/source/indicator/stand nodes; kind changes or rectangle width/height changes replace fixture and outline geometry. Pose/output edits reuse shapes; stand threshold crossings detach/reuse the same cylinder. RealityKit shares two unit meshes and two collision shapes, retaining 24 entities per lamp while changing transforms, visibility, materials and emission components (`SpatialPreview.swift:349–460`; `StudioEntityGraph.swift:100–121,169–191,249–345`).

- **Shading versus equipment.** RealityKit shades the first seven eligible lights in scene order: positive candela and a defined frame for aimed kinds. One neutral fill is separate. Powered-off, undefined-aim and over-cap fixtures retain selectable bodies; undefined-aim faces are disabled. Reordering recomputes eligibility; unshaded lamps lose point/spot components (`StudioEntityGraph.swift:10–12,55–60,106–121,265–268,313–340`).

- **Lifetime and evidence.** Deletion/invalid input detaches lamp roots and clears hit identities; recovery creates replacements. SceneKit dismantling clears geometry/caches/callbacks. RealityKit inactivity detaches anchors while retaining its graph; dismantling removes anchors/gestures/callbacks, with graph resources retained until coordinator release (`SpatialPreview.swift:95–133,232–237`; `StudioEntityGraph.swift:69–105`; `RealityStudioPreview.swift:170–225`). Tests assert unchanged **direct-child** counts over 100 ordinary updates and kind transitions, one-child stand deltas, identity reuse and stale-hit rejection (`SpatialInteractionTests.swift:50–104,143–159`; `SpatialEntityUpdateTests.swift:47–67,98–214`; `SpatialSelectionLifetimeTests.swift:119–160`). The crowded snapshot test checks image dimensions, not topology bounds. Native evidence supplied by the lead exercises SceneKit fallback; this review adds no RealityKit execution or FPS/memory/leak claim.
