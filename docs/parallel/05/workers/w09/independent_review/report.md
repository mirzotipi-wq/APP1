# Wave09 — final independent review

Frozen source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`.

**Disposition: no new concrete adapter defect; no production edit proposed.** I actually read all nine other complete reports: acceptance, geometry, interfaces, implementation, concurrency, resources, interactions, accessibility/privacy and platform/performance. I also read the required directives/contracts, pinned adapter/caller/test evidence, historical receipt, lifecycle matrix, owner checkpoint, synthesis, source-inputs, CI observations and resource provenance.

**Evidence corrections verified.** The lead amended synthesis/matrix after my challenge. `StudioEntityGraph.lightID` establishes current hierarchy ownership; retained RealityKit hits may still resolve after anchor detachment or coordinator dismantling. Delivery is separately blocked by rendering/enabled/current-scene/window/VoiceOver guards and callback teardown (`RealityStudioPreview.swift`). SceneKit selection also rechecks callback/window/VoiceOver; equivalent gating of framework camera gestures is unproven. Callback refresh precedes equality exits; deletion/invalidation rejects stale ownership.

SceneKit teardown clears attachments/maps while retaining coordinator content/camera nodes; RealityKit retains its graph. Neither establishes deallocation. Normal recreation constructs a fresh coordinator; manually reusing a dismantled coordinator is unsupported. For N ≤ 12 validated lights and S stands above 0.05 m, owned topology is `8 + 4N` SceneKit nodes and `55 + 24N` RealityKit entities, maximum 56/343. SceneKit attachment is `8 + 3N + S`; RealityKit attaches its full topology only while active/windowed. Counts include disabled objects/detached stands but exclude framework internals, meshes/materials and external test witnesses; they measure neither allocations nor performance.

Frozen `.id(generation)` still predicts first-save recreation. Owner `5ccfbaae` implements `workspaceResetID` plus generation/live-UUID guards; its session assertions do not establish hosted camera retention. Integration and native first-save/switch verification remain owner work.

Historical `4e694bc`, run 45838950713/job 139980771221 passed 184 native/38 spatial (28 SceneKit/10 helpers), plus Debug/Release builds. Current 60059 inventory 185/39 includes 11 helpers, without a transferred pass. Parent run 45851365897 core passed 366 Debug/366 Release/100 tooling; native 140022794410 still had a Release build in progress at 16:19:22 UTC, without a reviewed 185-pass receipt.

Direct callback/property tests and serial updates do not establish delivered gestures or renderer-thread atomicity. RealityKit runtime, hosted lifecycle, device/manual VoiceOver, FPS/RSS/thermal remain unverified. No tests, builds, toolchains, source/ref changes or CI polling performed. Token targets remain unmeasured; no milestone/release promotion.

