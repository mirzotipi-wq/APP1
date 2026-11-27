# Wave08 complete role reports

These are the ten complete returned reports. Their exact file hashes and canonical contexts are in `ledger.json`. Reports retain their observation-specific execution language; `acceptance/current_execution_update.md` and `acceptance/ci_observations.json` provide later source-specific CI dispositions.

---

## acceptance — /root/w08_acceptance

Report file: `acceptance/report.md`  
Report SHA256: `670f725f36bfe0498880b0f441c6689ffde6bf1b19a6a0614eca7fbef6a95760`

# Wave08 — Acceptance

Canonical ID: `/root/w08_acceptance`  
Input source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`  
Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`  
Status: `completed_source_acceptance_review_with_portable_followup`

The seven-case matrix in `case_matrix.md` maps ordinary, translated `(80,0,75)`, coincident large modifier, empty/sparse, tall-stand, crowded and narrow/wide scenes to concrete assertions and evidence limits. The source inventory is independently reconciled with the repository's XCTest discovery pattern: **184 native / 38 spatial declarations**. This is inventory only. Source9725's receipt records actual176/30 passes and original ordinary/crowded SceneKit images; source4e's run45838950713 remains separately coordinator-owned.

The lead actually opened both original9725 PNGs with `view_image`. The ordinary rig's three point fixtures, subject, stands and camera symbol fit. Crowded panels and the selected yellow wire outline remain inside the frame; foreground panels obscure parts of the bust. The small dark camera and thin stands remain visually weak. These are SCNView XCTest snapshots, not delivered taps, whole-app interactions, RealityKit, devices or manual VoiceOver.

Current native projection tests inspect bounds corners and several actual housing/base points. A successful corner projection alone does not prove that bounds include every displayed primitive. The separate geometry derivation and portable witness therefore inspect actual primitive dimensions, outline thickness, target spheres and connecting tubes, arbitrary valid orientations and world-floor stands.

Geometry review found one exact source-only projection limit: empty scene with subject `(-100,1.5,0)`, camera `(100,1.5,0)`, layout `0.0001×3000`. Nearest Float narrows the effective horizontal half-angle to about14.054°; the camera center reaches normalized x≈1.49634. This is an extreme subpixel case, not an observed practical narrow-view failure. Root authorized a private outward-rounding candidate and one focused state regression; candidate review and portable results are recorded separately. No local native build/test or branch update occurred.

Acceptance is bounded: actual prior SceneKit evidence, current source invariants and portable calculations remain distinct. No milestone/release promotion, photometric calibration, measured FPS/memory, RealityKit execution or full-app accessibility pass follows from this wave.

---

## geometry — /root/w08_acceptance/geometry

Report file: `geometry/report.md`  
Report SHA256: `7c60fcf3cc9b10c498c9ff41c9a9d7918fa73b2800f3002b3ae72490b47403be`

# Lane05 / wave08 / geometry source review

- Canonical reviewer: `/root/w08_acceptance/geometry`
- Status: `completed_source_review`
- Frozen input: `4e694bc377c4825d1d2dd52fcd7900e534c75072`
- Baseline supplied: `f150f98e35dd735927075aac4d2f8b02295c6a67`
- Scope: spatial equipment envelopes and Fit in both adapters; immutable `git show <input>:<path>` reads only. No branch refs, shared edits, builds, toolchain or native execution. Only private review outputs are written.
- Result: no equipment-envelope counterexample in the source's real-number geometry; one extreme subpixel RealityKit projection precision limit. This is source review, not a native pass, screenshot review or measured budget-compliance claim. Telemetry is unavailable.

## Independently derived primitive envelopes

The floor and grid are deliberately outside the equipment-Fit contract: SceneKit uses an infinite SCNFloor; RealityKit uses a square floor of side max(8, core horizontal span + 6), y=[-0.045,-0.005], plus 42 grid boxes at y=[-0.004,-0.002]. They cannot be treated as enclosed equipment. Light/source and ambient/directional illumination nodes have no visible mesh.

**Subject.** SceneKit head radius 0.19; scaled capsule torso is centered 0.55 below the subject, x radius 0.276, z radius 0.1495, y=[-0.93,-0.17]. RealityKit uses radius-0.5 sphere meshes: head semiaxes (0.17,0.215,0.16); neck (0.07,0.12,0.07), center y=-0.25; torso (0.29,0.37,0.15), center y=-0.58; nose (0.0275,0.0375,0.0375), center (0,-0.02,0.155). Every horizontal facing stays within horizontal radius 0.29 and y=[-0.95,0.215]. The helper's subject box x/z ±0.36, y=[-0.96,0.24] encloses both.

**Authored camera.** SceneKit body half-extents (0.13,0.09,0.09), lens (0.0475,0.0475,0.05) at z=-0.12; RealityKit body (0.13,0.085,0.07), lens (0.0475,0.0475,0.06) at z=-0.11. All corners are less than 0.184 m from the authored camera center. Thus the helper's ±0.24 box contains them at every defined camera orientation, and at the identity used for undefined framing. Camera mode hides the SceneKit body.

**Point fixture and selection.** SceneKit radius 0.09; selected wire mesh radius 0.0954. RealityKit sphere radius 0.08; twelve edge boxes for its 0.22 selection cube have maximal coordinate ±0.1145, including 0.009 edge thickness. The ±0.12 helper box contains both. Crucially, `StudioPhotometry.frame` returns nil for points, so the RealityKit cube remains world aligned regardless of stored aim/roll.

**Directional/rectangular fixture and selection.** Use the source's emitter basis and authored center; w/h are authored rectangle dimensions or 0.22/0.18 for directional fixtures.

- SceneKit defined housing: x=±w/2, y=±h/2, z=[-L,0], where L=0.13 directional or 0.055 rectangle. Selected outline has x=±(w/2+0.02), y=±(h/2+0.02), z=[-1.03L,0.03L]. Undefined aim leaves the same housing/outline centered in identity orientation; worst z is ±0.0689.
- RealityKit housing: x=±w/2, y=±h/2, z=[-0.086,-0.006]. Face z=[-0.006,0]; rectangle uses full w/h, directional reduces each by 0.012. Selection edge union lies within x=±(w/2+0.0245), y=±(h/2+0.0245), z=[-0.1075,0.0215]. Undefined aim uses identity and hides the face.

All are subsets of the helper prism x=±(w/2+0.03), y=±(h/2+0.03), z=[-0.15,0.08]. Applying the same complete orthonormal frame preserves inclusion for arbitrary valid roll, vertical/oblique aim, and every valid dimension. Its eight transformed corners therefore give a valid enclosing world AABB. Coincident 4×4 housings are explicitly included by the identity fallback.

**Stands.** SceneKit cylinder radius 0.015, y=[0,light.y]. RealityKit shaft half-width/depth 0.012 and same vertical interval; feet reach x/z ±0.225, y=[0.0015,0.0265]. The helper's floor-base box x/z ±0.24, y=[0,0.028], plus the source envelope, encloses every shaft/base. Even the smallest oriented fixture prism contains a radius-0.055 ball around its source, enough for the shaft's upper cross section. The AABB is convex. World-floor anchoring correctly makes vertical translation change Fit; horizontal translation preserves it.

**Aim markers (RealityKit only).** The target sphere has radius 0.0275, explicitly included by the helper whenever a core frame exists. The 0.005×length×0.005 aim-line box lies on the source-target segment with perpendicular radius at most 0.0025√2 = 0.003536. Both endpoint envelopes contain this radius: ≥0.055 at source, 0.0275 at target. Convexity therefore encloses the entire line tube, including arbitrary segment orientation. Undefined or Float-space length ≤0.0001 hides both markers. Selected state never enlarges beyond these already included envelopes.

Source anchors: `App/SpatialPreview.swift` 274–288, 311–460; `App/StudioEntityGraph.swift` 31–53, 139–158, 249–365; `App/SpatialViewportGeometry.swift`; `Sources/LightingCore/StudioOptics.swift` 58–110. Native Float transforms have rounding; the derivation is not a claim of bit-exact world-coordinate containment.

## Fit result and exact precision limit

For the derived equipment AABB, its half-diagonal R encloses the geometry. Fit uses d=1.12·max(0.8,R)/sin(24°), hence angular radius asin(R/d)<24°. Valid authored coordinates and modifier sizes give R<179 m, so the 1500 m distance cap does not activate; d−R>1.4 m exceeds near=0.02, and d+R<d+750. SceneKit chooses the smaller FOV axis; RealityKit computes its equivalent vertical FOV. This proves ordinary, translated (80,75), coincident-large, sparse/empty, tall-stand and twelve-light crowded Fit for the real-number projection and ordinary narrow/wide layouts. The shading cap does not remove geometry.

**Extreme subpixel counterexample in the native-Float projection model:** empty scene subject=(-100,1.5,0), camera=(100,1.5,0), layout width=0.0001, height=3000. Bounds min=(-100.36,0.54,-0.36), max=(100.24,1.74,0.36); R=100.30244064827134; d=276.195261574031. The helper returns vertical FOV 179.99999142077152°, which rounds to Float 179.99998474121094° and passes the <180 guard. At this aspect ratio that stored angle implies horizontal half-angle 14.053987907538744°, while the authored-camera center projects at 20.53483450759005° (normalized x=1.4963415439584464). Thus universal native Fit over every accepted positive layout is not proven; the modeled camera center is outside this frustum. This is an extreme fraction-of-a-pixel layout, not an observed practical clipping defect. Calculation uses JavaScript IEEE Float32 rounding and pinhole arithmetic; no native renderer was executed. Root was notified immediately. No patch was made.

## Evidence limits

Read the required AGENTS/architecture/design/code-acceptance documents and native spatial bounds, projection, emitter geometry, aim-recovery and entity-update tests. Current source tests cover helper AABB corners for four aspect ratios including 1×1000, translated/large/coincident/high/sparse/crowded cases; native SceneKit tests inspect projection, authored planes, bases and transitions. These do not independently enumerate all RealityKit mesh extrema or execute its projection in the extreme case above. No current 38-method or CI outcome is asserted here; root owns run 45838950713 and its accounting.

Private artifacts: `report.md` and `narrow_precision_witness.json`. Full report was stored under `w08_geometry_report` before file creation.

---

## interfaces — /root/w08_acceptance/interfaces

Report file: `interfaces/report.md`  
Report SHA256: `60eaf00f65b78ba555945d6b04be512bbc7b823b7e1c2d5ec1a8b1d931f87db2`

# Wave 08 — Interfaces

Canonical ID: /root/w08_acceptance/interfaces
Input SHA: 4e694bc377c4825d1d2dd52fcd7900e534c75072
Baseline SHA: f150f98e35dd735927075aac4d2f8b02295c6a67
Status: completed_source_review

**No blocking interface defect found.** Reviewed the requested directives and immutable source. Assigned Core files are unchanged from baseline.

**Schema:** Authored coordinates/manual targets must be finite within ±100 m; dimensions are 0.05–4 m, roll ±180° (Scene.swift:4–12,62–80; StudioOptics.swift:16–42). Manual targets translate with equipment; completed transforms revalidate (SceneTransform.swift:119–129,433–435). Derived face corners may exceed ±100 m (StudioSceneBounds.swift:27–34). CameraFraming.project accepts authored positions, not arbitrary derived corners (CameraFraming.swift:71–76).

**Bounds:** Core includes centers, aimed targets and defined emitting faces; it excludes stands/housing (StudioSceneBounds.swift:3–35). App adds bust/camera, point outlines, transformed housing, aim markers and stand bases (SpatialViewportGeometry.swift:25–61). Its local envelope ±(width/2+0.03), ±(height/2+0.03), z=[−0.15,0.08] encloses both adapters’ housings/outlines under arbitrary valid aim/roll (SpatialPreview.swift:379–443; StudioEntityGraph.swift:260–305,348–365). Authored faces remain at local z=0. Floor/grid are excluded.

**Cases:** Empty/sparse rigs retain bust/camera bounds. Translation by (80,0,75) preserves radius while translating center, provided every authored position/target stays valid. Coincident 4×4 m modifiers omit the undefined Core face but retain non-emitting, identity-oriented display housing bounded by ±2.03 m. A 100 m stand includes y=0; vertical translation intentionally changes Fit. Undefined camera direction disables authored preview while orbit remains available (SpatialPreview.swift:223–231,253–265).

**Fit:** d=1.12·max(0.8,r)/sin(24°), using 48° on the smaller viewport axis (SpatialViewportGeometry.swift:88–118; SpatialPreview.swift:274–288; RealityStudioPreview.swift:228–244). Valid equipment gives r<180 m, so the 1500 m cap never truncates Fit; near/far margins encompass it.

Source review only: no builds/tests. Current 184 native/38 spatial are inventory; prior 176/30 does not certify this SHA. CI 45838950713 remains lead-owned.

---

## implementation — /root/w08_acceptance/implementation

Report file: `implementation/IMPLEMENTATION_REPORT.md`  
Report SHA256: `97b0ac4dfa76778ff82908574865b05f7daa2baaf463ba56c9d2e438d18a4a49`

# Wave 08 implementation

Canonical ID: `/root/w08_acceptance/implementation`
Status: `completed_portable_witness_and_source_review`
Input SHA: `4e694bc377c4825d1d2dd52fcd7900e534c75072`
Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`
Detached candidate: `a92b4fdc5bb8d3af75b3557949477a730462e000`

The portable witness passed 15 scenes/760 primitive instances and 240 whole-volume frustum checks per model. Maximum envelope excess: zero; minimum practical clearance: 0.321782484 m. Coverage includes ordinary, translated X80/Z75 and Y75, coincident 4 m, empty/sparse, tall stand, twelve lights, arbitrary aim/roll/camera orientations, and narrow/wide layouts.

Independent primitive support functions include bust/camera volumes, selection thickness, aim tube and floor-anchored stands. The ideal sphere proof bounds angular radius at 21.294250° against the minimum 24° half-angle, with near/far clearance. Full assumptions and primitive dimensions are in geometry_envelope_notes.md.

Original counterexample retained: empty scene, subject (−100,1.5,0), camera (100,1.5,0), viewport 0.0001×3000. Double FOV 179.99999142077152° rounds to accepted Float 179.99998474121094°; horizontal half-angle 14.053987907538744° excludes the marker center at 20.534834507590055° (normalized X 1.4963415439584467).

The two-file candidate rounds outward by at most one Float ULP, rejecting 180°. Its one focused new native regression remains unrun. No builds/native methods ran here; original 38 source spatial methods and historical 30 passes remain distinct. Float-angle-only calculations are not native projection or telemetry.

Artifacts under `/tmp/keyfill05-be879deb/waves/w08/implementation/`:

| File | SHA256 |
| --- | --- |
| portable_geometry_witness.py | 96cda16eed0d150b1494a903b88fc450859f1c71b544731491e183414988c348 |
| portable_geometry_witness.json | d5c4a9f64b59ef329cf35985309a8906aaabf7c3cb111258902b039f2a65128b |
| float_fov_candidate.patch | 8fdf2042441591771b1a19b109a2e600758f461bdfb5f33599079991ea77dcbe |
| artifact_manifest.json | 9b3028a957808af9f42094ea022c6a1a293c7612091aa86f58916692659787e4 |

Exact witness command:
```sh
python3 /tmp/keyfill05-be879deb/waves/w08/implementation/portable_geometry_witness.py --repo /tmp/keyfill05-be879deb/waves/w08/implementation/worktree --output /tmp/keyfill05-be879deb/waves/w08/implementation/portable_geometry_witness.json
```

`git diff --check` passed. Manifest records remaining commands, notes and full candidate-source paths/hashes. Full witness, JSON, patch, source/test and report are retained in functions.store. No cleanup performed.

---

## concurrency — /root/w08_acceptance/concurrency

Report file: `concurrency/report.md`  
Report SHA256: `2a63dd0b43e671944e8fa678b77832fbd2fb03ac3975232bfc67f84aee4d2399`

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

---

## resources — /root/w08_acceptance/resources

Report file: `resources/report.md`  
Report SHA256: `e63216f18b44c5d67d5faeace6d4a5601927c38c9510123b2a81fb2ac1d38b46`

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

---

## interactions — /root/w08_acceptance/interactions

Report file: `interactions/report.md`  
Report SHA256: `cf29985cc9f272ff18f91170519ad9a814acae2c97e9e69e1f104d5ee89c126c`

# Wave 08 interactions review

**Canonical ID:** /root/w08_acceptance/interactions  
**Status:** completed_visual_and_source_review  
**Frozen source:** 4e694bc377c4825d1d2dd52fcd7900e534c75072

**Finding:** No clipping defect is visible in these two fitted SceneKit scenes. Readability and interaction evidence remain limited.

I actually opened all four original PNGs with `view_image`: ordinary/crowded at 9725fb1 and 4e694bc. Both receipt files were read; PNG sizes and full SHA256 values match their receipts, and each fresh/earlier pair is byte-identical. Full provenance is retained in `provenance.json`.

Both rigs have clear viewport margins, including modifier tops and visible stand bottoms. The ordinary head/torso is recognizable, although the torso and floor have subdued separation. Its selected point light mainly reads as a yellow spot; the distinct outline is less readable than the crowded rectangle’s. The crowded scene retains a visible yellow outline on the far-right selected modifier. Foreground panels hide most of the torso and overlap other equipment. Thin gray stands fade against the dark floor. The camera body is small and dark in ordinary, and overlaps a foreground panel in crowded; lens direction is not readily legible.

Frozen `App/SpatialPreview.swift` accepts the first SceneKit hit, then resolves only live fixture/stand ancestry and current UUIDs; foreground occlusion therefore does not establish access to hidden lights. Tap recognition waits for camera recognizers. Callback publication precedes the unchanged-scene return. `App/RealityStudioPreview.swift` similarly guards active/window/current-scene selection and defines orbit, two-finger pan, pinch and tap arbitration.

`SpatialInteractionTests` and `SpatialSelectionLifetimeTests` directly check callbacks, ownership, removal/reintroduction, availability and camera state. Direct callback invocation does not prove hit delivery. The capture method embeds SCNView in UIWindow and snapshots it, without a SwiftUI/full-app host or delivered gesture.

**Still unproven:** actual taps on fixtures/stands/occluded or empty areas; selection after delivered orbit/pan/pinch/double-tap; scroll-versus-preview arbitration; Fit-button delivery; manual VoiceOver; physical-device and RealityKit runtime behavior; photometric fidelity.

`docs/parallel/05/validation/NATIVE-4e694bc.md` records run 45838950713/job 139980771221: 184 native/38 spatial passes plus Debug/Release builds on x86_64 iPhone 17 Pro, iOS 26.5/Xcode 26.6, using SceneKit fallback. I ran no native code. The later Float candidate is outside this source and receives no transferred execution or visual claim.

---

## accessibility_privacy — /root/w08_acceptance/accessibility_privacy

Report file: `accessibility_privacy/report.md`  
Report SHA256: `6fd5076e0f47f650e884172fc3fec5a9cf1ad90140f77d65330b6e578b7a2c30`

canonicalID: /root/w08_acceptance/accessibility_privacy
inputSHA: 4e694bc377c4825d1d2dd52fcd7900e534c75072
baselineSHA: f150f98e35dd735927075aac4d2f8b02295c6a67
status: completed_source_review
hash: sha256:8752e69a0085ef9cf6da64f2b6aef3910f72e579a3b7e1a8dd71888559a85011 (UTF-8 report body below metadata)

# Wave 08 — accessibility/privacy

Result: completed source review; no new actionable viewport-lane defect established.

**Semantics.** Normal SceneKit and RealityKit surfaces hide implementation children. SceneKit exposes its unavailable UILabel when needed; the RealityKit note is SwiftUI content outside the hidden native surface (SpatialPreview:187,498; RealityStudioPreview:15,78). The surrounding scrollable Lights list provides named equipment buttons, settings, selected traits and a checkmark, with current-UUID/generation guards and busy-state disabling (StudioView:87,111,926). These are source-demonstrated alternatives to visual hit testing; spoken output/order is unverified.

**Interaction and privacy.** RealityKit guards every owned gesture against VoiceOver, disabled state, missing/invalid scene and inactive/detached rendering (RealityStudioPreview:154,170,247). SceneKit guards its owned selection gesture against VoiceOver; its built-in orbit gestures are not explicitly VoiceOver-gated by this adapter. Disabled/inactive SceneKit interaction stops inertia; authored-camera mode prevents interactive selection/control, and undefined framing clears the prior point of view (SpatialPreview:83,136,197,223,248). Invalid RealityKit graphs disable the anchor and remove equipment (StudioEntityGraph:69). RealityKit explicitly uses `.nonAR` with automatic session configuration disabled (RealityStudioPreview:71); the scoped viewport code shows no camera authorization, capture, upload or network path. This is not a whole-app privacy audit.

**NARROW/UNAVAILABLE limits.** The UIKit unavailable label is multiline, centered, horizontally constrained and uses an adjusting preferred caption font (SpatialPreview:504). The SwiftUI note uses caption sizing; the authored-camera fallback supplies explanatory text (RealityStudioPreview:18; StudioView:732). Their enclosing viewport remains 280 points high and clipped (StudioView:520). No practical narrow-layout counterexample was established. Source alone does not prove largest-text visibility, actual contrast, manual VoiceOver behavior, platform audit success or 44-point 3D targets.

No tests were executed in this review. Supplied root evidence—run 45838950713/job 139980771221, 184 native/38 spatial plus Debug/Release—uses the x86_64 SceneKit fallback; it does not execute RealityKit-device behavior or the separate approved Float-FOV candidate. The lane01 first-save `.id(generation)` concern remains an owner request, outside this adapter lane.

---

## platform_performance — /root/w08_acceptance/platform_performance

Report file: `platform_performance/report.md`  
Report SHA256: `3c7c1f241fc1c2308dd49e44b7e2277d9c9c6d9425e2e15ab0fe95f30645293a`

# Wave 08 — platform/performance review

Canonical ID: `/root/w08_acceptance/platform_performance`  
Status: `completed_source_and_native_evidence_review`

**Actual execution.** Independently checked the retained log against frozen `4e694bc` source inventory and spatial receipt: exactly 184 ordered start/pass pairs, no missing, extra, duplicate, failed or skipped methods; 38 spatial = 10 helper/state methods + 28 SceneKit behavior methods. Run 45838950713/job 139980771221 also records successful Debug test-bundle and Release builds. Runtime was x86_64 iPhone 17 Pro/iOS 26.5/Xcode 26.6. The architecture guard selects SceneKit before RealityKit resource construction.

**Actual projection coverage.** Only two methods call `SCNView.projectPoint`. `SpatialPreviewTests:22–58` checks eight helper-AABB corners of a rig translated by (80,75), with a 4×3 m modifier, at 360×280 and 240×400. `SpatialInteractionTests:162–191` checks four transformed fixture-envelope samples plus the stand-base origin for a coincident 4×4 m softbox at height 20 m, at 120×600 and 600×120. These total 26 discrete projections; they do not enumerate every renderer mesh extremum. Other native tests verify transforms, camera state/recovery, identities and selection callbacks. Capture provenance establishes two original SCNView-in-UIWindow snapshots, without delivered-gesture evidence.

**Helper/source/portable coverage.** `SpatialViewportStateTests:157–186` projects helper-produced AABB corners through independent pinhole arithmetic, including 1×1000 layouts; this does not independently validate primitive containment. The separate portable witness addresses that distinction with independently defined primitive supports: 15 scenes, 760 primitives and 240 frustum checks per projection model. Its zero recorded failures remain modeled geometry/Float-angle arithmetic, excluding native matrices, tessellation and rasterization.

**Candidate and limits.** The approved outward-Float fix is published at `60059a0`; its 185-native/39-spatial inventory is EXPECTED, with no candidate pass established by this review. The 4e execution cannot transfer to changed source. Source compilation and portable proof do not establish RealityKit runtime, physical-device behavior or gesture delivery. Repeated-update node/identity bounds establish bounded structure, not FPS, memory leaks, thermal behavior or performance measurements. No additional source blocker found; retain exact-candidate native execution as outstanding.

---

## independent_review — /root/w08_acceptance/independent_review

Report file: `independent_review/report.md`  
Report SHA256: `1b5e7db62298fe6917cc1bf1ea71f7c2596eb6dac23cf68f914a9aee54f047d2`

# Wave 08 — independent review

Canonical ID: `/root/w08_acceptance/independent_review`  
Status: `completed_source_and_final_packet_review`  
Frozen source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`  
Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`

**Decision: approve the source correction and bounded evidence packet. No additional source blocker found.** Reviewed all nine other reports, synthesis, ledger, matrix, witness, execution addendum and receipts. All nine report hashes match the ledger; ten canonical IDs are unique. Early approval and final review use this same context.

Published `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a` contains exactly the approved App/test bytes; the product-source diff touches only those two files. Private `a92b4fd` and preserved `a69f625` have identical trees. Exact hashes are retained in `source_approval.md` and `published_source_identity.json`; remote verification is attributed to root.

Independent standard-library scalar checks confirm six accepted layouts and two rejections. At 0.0003×3000, outward rounding changes the modeled half-angle from 20.58084° to 36.90608°. At 0.0001×3000, the required enclosing Float is 180°, correctly rejected. The added regression discriminates old source; the sole production caller already handles nil.

The witness separates displayed-primitive supports from helper bounds: 15 scenes, 760 primitives, 240 frustum cases per model. Its zero failures remain modeled evidence. Source inspection confirms the platform report's 26 discrete native projections, not exhaustive mesh coverage.

The 4e receipt records 184 native/38 spatial passes: ten helper methods and 28 SceneKit methods, plus Debug/Release builds on the x86_64 fallback. These results do not transfer to changed source. Latest root status has candidate run 45851365897 core work in progress and **185/39 native inventory unexecuted**. Root reports prior library/accessibility/visual-review jobs cancelled by the successor; they are not passes. Historical pending language is explicitly superseded.

Interactions retains four-original inspection and receipt provenance. Camera/stand readability and occlusion limits remain; delivered gestures, maximum-text/contrast behavior, manual VoiceOver, RealityKit runtime, device performance and photographic fidelity remain unproven. This review ran no native code and promotes no milestone or release state.
