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

