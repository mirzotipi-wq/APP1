# Wave 06 — complete captured reports

Frozen input: bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9. Ten actual contexts completed. Reports below are retained verbatim; source/math evidence and native execution remain distinct.

## acceptance

# W06 acceptance

Canonical ID: /root/w06_acceptance. Frozen input: bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9.

**Accept the exact two-file candidate for source integration; native acceptance remains unexecuted.** Root alone integrates the private writer commits d112069f8c4fa4a1770c130fe6c8491fe9c21817 and e66319bf8ee54925ae2121154adfbc4a6bbd099c.

I read the lane contracts and relevant adapters/tests, ran agent_cycle.py check/next (state structure valid; M03 gates still outstanding), counted the frozen native methods, and inspected the candidate diff. The inventory is 183 native/37 spatial before and 184/38 in the candidate, including inline @MainActor declarations. project.yml includes the new test through its existing NativeTests source root. The writer worktree is clean; git diff --check passes; the aggregate changes exactly App/StudioEntityGraph.swift and NativeTests/SpatialAimRecoveryTests.swift.

The new method retains a single UUID, fixture/source/outline/stand nodes and shapes through valid→coincident→translated vertical aim. It asserts suppressed/restored actual SCNLight, live selection, front/source/stand positions and complete literal cardinal bases, independently of StudioPhotometry.frame. Existing camera recovery/lens coverage justified keeping this to one method.

Core defines rectangle dimensions as emitting-face extents, excluding housing. Root authorized the minimal RealityKit rectangle-only scale correction after this contract was independently verified. Scalar witnesses document former visible-face area shortfalls of 2.697143% at 1.2×0.7 m and 42.24% at 0.05×0.05 m; corrected extents match the authored domain. Directional inset, depth and front plane are preserved. This is geometric evidence, not calibrated lighting.

The independent reviewer approved exact patch SHA256 4c26f04190d2428a6ebc355b1ff93d7e25151d545a89f0b4026f9938ce4f95b7 without required revisions. SceneKit's chamfered housing establishes outer dimensions/front-center anchors, not sharp tessellated corner parity.

Root reports source9725 run45826141504 passed 176 native/30 spatial methods with no failures or skips and retained two genuine SceneKit captures. The candidate's eight newer methods remain unexecuted. No native compilation/type checking, RealityKit execution, device, VoiceOver, allocation or frame-rate acceptance is claimed by this wave. Core, composition, Plan, AR and Study are unchanged.


---

## geometry

# W06 geometry / invariants

Canonical ID: `/root/w06_acceptance/geometry`  
Frozen input: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`.

**Finding: one rectangle-extent contract defect; no basis/front-plane discrepancy in the bounded source/math comparison.**

Core explicitly defines emitting-face corners, excluding housing, at authored ±width/2 and ±height/2 (`Sources/LightingCore/StudioSceneBounds.swift:3–6,27–34`). Those dimensions also define the photometric emitting domain (`Sources/LightingCore/StudioOptics.swift:131–136`; `Sources/LightingCore/SurfacePhotometry.swift:118–123,185–189`). RealityKit's unit-box construction and scaling (`App/StudioEntityGraph.swift:171,177–180,270–277`) instead produce a 1.188×0.688 m face for a 1.2×0.7 m rectangle: 0.817344 versus 0.84 m², 2.697143% undersize. Each edge is inset 0.006 m; corner displacement is 0.008485281 m. At the valid 0.05×0.05 m minimum, area undersize reaches 42.24%. Recommend rectangle-only face scale `[width,height,0.006]`; retain z=-0.003, preserving front z=0 and directional presentation. The witness labels this as proposed correction.

Ran `python3 /tmp/keyfill05-be879deb/waves/w06/geometry/witness.py`: **67 scalar assertions passed**. Independent projected-world-up/Rodrigues formulas cover translated oblique 37.5°, vertical +90°/−125°, and translated vertical recovery at 37.5°. Formula error ≤1.67e−16; ideal front-center residual is zero. Recovered right=(0.793353340,0,−0.608761429), up=(−0.608761429,0,−0.793353340), normal=(0,1,0). Both source-forward mappings preserve handedness (`App/SpatialPreview.swift:294–302,418–442`; `App/StudioEntityGraph.swift:240–241,262–277`). Tested face corners remain inside the viewport envelope (`App/SpatialViewportGeometry.swift:38–52`).

Recovery is **source analysis**, not executed incremental updates: changed aim resets orientation, suppresses emission at coincidence, then restores the new frame (`App/SpatialPreview.swift:373–378,413–446`; `App/StudioEntityGraph.swift:117–121,250–268,309–343`). Coincidence has no physical direction (`Sources/LightingCore/SurfacePhotometry.swift:9–15`). A separate 1e−7 m nonzero aim at x=80 retains a Core frame but Float-rounded endpoints coincide; RealityKit hides only aim markers (`App/StudioEntityGraph.swift:292–308`).

Float32 component-cast errors were ≤2.85e−8 for axes and 9.54e−8 m for positions; these exclude native quaternion/transform arithmetic. Existing native tolerances remain 1e−6 and 2e−5 m (`NativeTests/SpatialEmitterGeometryTests.swift:34–46`). `GEOMETRY_COMPARISONS.md:13` misses the housing/face distinction; its lines14,36 correctly retain recovery as an execution gap. No native builds/tests, visual, photometric-calibration or performance claims; no production edits.

---

## interfaces

# Wave 06 — interfaces review

Reviewer: `/root/w06_acceptance/interfaces`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`; campaign baseline: `f150f98`.

**Disposition:** Core supports the authorized rectangle-only RealityKit face-scale correction. This review changed no source.

**Orientation/camera handoff.** `Sources/LightingCore/StudioOptics.swift:50–94,107–110` defines right × up = normal, local +Z emission, deterministic vertical aim and authored roll. `App/SpatialPreview.swift:294–302,424–442` consumes that complete basis and flips both right/normal for −Z spotlights. `App/StudioEntityGraph.swift:240–241,260–264` consumes the same basis once and rotates the emission child by π. Undefined aimed emission stays disabled.

`Sources/LightingCore/CameraFraming.swift:3–8,33–61` defines the 36×24 mm lens, −Z forward, shared up and nil below 0.05 m. `SpatialPreview.swift:223–264` applies vertical lens FOV/near depth/up and hides unavailable content/clears pointOfView; both camera-body adapters reset undefined orientation (`SpatialPreview:337–340`; `StudioEntityGraph:90–96`). `SpatialViewportGeometry.swift:4–6,25–52` adds display equipment bounds using the shared frame/identity fallback without changing Core bounds or authored lens.

**Dimensions.** `StudioSceneBounds.swift:3–6,27–34` explicitly defines emitting-face corners as ±W/2, ±H/2. `StudioOptics.swift:131–136` and `SurfacePhotometry.swift:118–123,185–189` use those same dimensions for emission, excluding housing.

Apple documents [generateBox(size:cornerRadius:)](https://developer.apple.com/documentation/realitykit/meshresource/generatebox%28size%3Acornerradius%3A%29) as a centered cube whose size is its full edge length in meters; [scale](https://developer.apple.com/documentation/realitykit/hastransform/scale) is relative to the parent. Thus `StudioEntityGraph.swift:171,270–277` currently makes the rectangle face 12 mm undersized per axis. Rectangle-only scale `[W,H,0.006]` restores Core’s front-corner equation, subject to Float conversion. Keeping face z = −0.003 preserves front z = 0; retain directional inset and housing placement. SceneKit’s 0.012 chamfer (`SpatialPreview:384–385`) remains a rounded illustrative envelope, so literal flat-face mesh-corner parity is not claimed.

**Remote check.** At 2026-11-26 14:17:13 UTC, authorized exact-prefix GitHub searches for `finish/06` and `finish/20` each returned `branches: [], cursor: null`. Neither branch was returned; no SHA/HANDOFF input was available. The initial `finish/` query had cursor `NQ` and was insufficient alone. No baseline change, fetch, merge, native execution, performance or calibration claim.


---

## implementation

# Wave 06 implementation report

Actual tool canonical ID: `/root/w06_acceptance/implementation`.
Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Frozen input: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`.
Test commit: `d112069f8c4fa4a1770c130fe6c8491fe9c21817`.
Production commit: `e66319bf8ee54925ae2121154adfbc4a6bbd099c`.
Private worktree: `/tmp/keyfill05-be879deb/worktrees/w06-implementation`.

## Result

Added `NativeTests/SpatialAimRecoveryTests.swift`, containing one method. It exercises the same UUID through -Z aim/+90-degree roll, coincident aim, and translated +Y aim/-90-degree roll. It retains the fixture, source node, visible outline and stand plus unchanged geometry, preserves selection, verifies the centered world-aligned undefined housing, requires actual SCNLight suppression/restoration, and checks authored front/source/stand positions and complete fixture/source bases against literal independent vectors. SceneKit has no separate aim-marker node. Existing camera recovery coverage made a second method unnecessary.

After the geometry review confirmed the contract and the lead relayed root authorization, changed only RealityKit's rectangular `face.scale` branch and its comment in `App/StudioEntityGraph.swift`. Rectangle width/height now equal the authored emitting-face dimensions; directional inset, face depth, front plane and all other source bytes are preserved. Core, shared composition, Plan, AR and Study were not edited.

## Evidence and limits

`git diff --check` passed. Bounded source checks confirm the exact two-path scope, clean private worktree and one new method. The source-bound scalar witness calculates 2.697142857% former area shortfall for 1.2×0.7 m and 42.24% for 0.05×0.05 m; both become zero. Directional dimensions remain 0.208×0.168 m and the face front remains z=0. This is transcribed decimal arithmetic, not native execution.

Native tests, compilation and type checking are **UNRUN**. Existing position/axis tolerances remain unchanged. Recommend independent aggregate-patch review and later native execution; no runtime or visual acceptance is claimed.

## Capturable artifacts

- Aggregate patch: `/tmp/keyfill05-be879deb/waves/w06/implementation/change.patch` — SHA256 `4c26f04190d2428a6ebc355b1ff93d7e25151d545a89f0b4026f9938ce4f95b7`.
- Test source: `/tmp/keyfill05-be879deb/waves/w06/implementation/SpatialAimRecoveryTests.swift` — SHA256 `17a4a59ed520298a0143fe3d6ccc1589f36af3414fcf51bf81d9c1ad491e16a0`.
- Production source: `/tmp/keyfill05-be879deb/waves/w06/implementation/StudioEntityGraph.swift` — SHA256 `a969106d321096bd2a573c1b0ddbb6b3c70192dfd86a792ec1a8a249089a783b`.
- Scalar witness: `/tmp/keyfill05-be879deb/waves/w06/implementation/face-scale-witness.json`; reproducible script alongside it.
- Source receipt: `/tmp/keyfill05-be879deb/waves/w06/implementation/source-checks.json`. Initial test-only artifacts are retained separately.

---

## concurrency

# Wave 06 — concurrency review

Worker: `/root/w06_acceptance/concurrency`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`

**Disposition:** No stale-cache defect found in the bounded sequential source-state trace. No patch proposed. Read AGENTS, architecture/design, and lane05 acceptance/geometry notes; reviewed pinned source only.

Symbolic trace (not execution): selected auto-aim valid → pose/roll edit → subject equals source, with light unchanged (coincident) → selection off/on and unchanged-scene callback replacement → subject moves away (valid) → manual target equals source (coincident) → manual target/pose/roll changes (valid).

`RealityStudioPreview.Coordinator.update` refreshes `onSelect` before graph work and replaces `currentScene` before subsequent interaction (`App/RealityStudioPreview.swift:193`). `StudioEntityGraph` compares the complete scene/selection, recalculates shading eligibility, and commits its scene cache after lamp updates (`App/StudioEntityGraph.swift:80, :117, :123`). Subject edits therefore reach unchanged lights.

`StudioLampEntity` independently keys on light, subject, selection and shading allocation. Position or effective-optics changes, including manual target/roll, and subject changes invalidate geometry; geometry invalidates source components. Coincidence resets orientation, hides the face, clears `hasAimGeometry`, disables both aim markers, and removes emission. Selection-only updates consult the current `hasAimGeometry`; recovery recomputes geometry/source before publishing lamp caches (`App/StudioEntityGraph.swift:249, :253, :297, :306, :335, :340`). Shading-budget changes also invalidate source components.

SceneKit computes `renderChanged` against previous light/subject before updating those caches; the synchronous render branch then clears or recreates the source and resets fixture transforms (`App/SpatialPreview.swift:376, :409, :429`). Selection-only updates alter indicators without reviving emission; unchanged-scene updates still refresh callbacks before their early return (`:205, :245`).

Both paths are `@MainActor` with no suspension in these updates. This establishes ordering for delivered calls, not actual native frames, SwiftUI delivery of every intermediate edit, or gesture timing. SceneKit transaction commit is deferred to function exit; presentation follows its run-loop boundary.

Candidate `e66319bf8ee54925ae2121154adfbc4a6bbd099c` changes rectangle face scale and one SceneKit test only; it has no scheduling/cache changes. Root-confirmed historical evidence remains 9725: 176 native/30 spatial passing. Candidate inventory 184/38 includes eight unexecuted methods; no RealityKit runtime evidence. No builds, tests, helpers, or shared-source edits were performed; Core06, composition01, Plan07, AR13 and Study03/04 remain untouched.

---

## resources

# Wave06 lane05 — resource lifecycle

Reviewer: `/root/w06_acceptance/resources`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`  
Candidate: `e66319bf8ee54925ae2121154adfbc4a6bbd099c`

Read AGENTS, architecture/design, both adapters and matching tests. Source review only.

**Concrete trace:** one selected rectangular UUID, fixed 1.2 × 0.7 m dimensions and 2.1 m height; valid aim → coincident aim → valid aim → zero candela.

| Resource | Coincident aim | Valid recovery | Zero candela with valid aim |
|---|---|---|---|
| SceneKit fixture/source/stand/indicator nodes and existing shapes | Retained | Retained | Retained |
| SceneKit attached `SCNLight` | Set to nil | Newly constructed | Retained, intensity zero |
| RealityKit lamp entities and shared meshes/shapes | Retained | Retained | Retained |
| RealityKit authored light components | Both types removed | New spotlight component set if shading eligible | Both types removed |

SceneKit creates lamp nodes only for a missing UUID. Fixture/outline shapes change initially, on kind changes, or rectangle dimension changes. The cylinder is created lazily above y > 0.05, detached at/below that threshold, and reused when raised. Aim/output changes mutate pose/material properties without replacing these shapes. For this single-light trace, ambient intensity also becomes zero at coincidence/off. [S]

RealityKit constructs box/sphere meshes and collision shapes once per graph; lamp construction creates the hierarchy and 12 outline entities. Aim changes mutate transforms/enabled flags; coincidence disables face/aim markers. `sourceChanged`—position/optics/subject, candela, Kelvin, or shading eligibility—constructs replacement face/point materials and sets/removes light components. Only the first seven eligible emitters receive components; the neutral display fill remains. [R]

UUID deletion or whole-scene validation failure removes lamp hierarchies in both adapters. SceneKit dismantling additionally clears base nodes; RealityKit rejection disables its anchor while retaining base resources. [S, R]

Candidate changes rectangle `face.scale` and adds one recovery test; allocation policy is unchanged. Its `SpatialAimRecoveryTests` asserts retained nodes/shapes plus nil→spot recovery. Frozen `SpatialEntityUpdateTests` covers zero-output identity and stand reuse. Assertions were inspected, not executed; RealityKit runtime remains unverified. No allocation, memory, frame-rate, or performance measurements were made.

**Source anchors:** [S] `App/SpatialPreview.swift` 95–133, 232–236, 344–460, 475–481. [R] `App/StudioEntityGraph.swift` 12–20, 55–77, 100–121, 170–343.

---

## interactions

# Wave06 lane05 — interaction source review

Reviewer: `/root/w06_acceptance/interactions`. Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`. **No interaction blocker found in this bounded trace.**

Read `AGENTS.md`, architecture, design, and current `m02-m03-code-v2` acceptance; reviewed pinned source only. References: `App/SpatialPreview.swift` (`updateView`, `updateContent`, `Coordinator.lightID`); `App/StudioEntityGraph.swift` (`update`, `lightID`, `StudioLampEntity.update`); `App/RealityStudioPreview.swift` (`canInteract`, `selectLight`).

Assuming an otherwise valid scene and selected aimed emitter:

| State | Equipment / outline | RealityKit aim markers | Source eligibility |
|---|---|---|---|
| Valid rolled aim | Selectable; outline enabled; shared frame carries roll | Enabled when Float segment exceeds 0.0001 m | Eligible |
| Undefined/coincident aim | Equipment remains selectable; outline enabled; orientation resets | Both disabled; stale geometry cannot remain enabled | SceneKit light cleared; RealityKit components removed |
| Valid recovered roll, same UUID | Existing equipment reused; orientation refreshed; outline enabled | Recomputed and enabled for sufficient segment length | Restored |
| Zero candela after recovery | Equipment remains selectable; outline enabled | Remain enabled for valid geometry | SceneKit intensity zero; RealityKit components removed |

Selection off hides/disables outlines and RealityKit markers; selection on restores the applicable flags without changing source eligibility. RealityKit eligibility still respects its seven-emitter shading limit. SceneKit has fixture, child outline, source and stand nodes, **no separate aim markers**. Its visible outline resolves through the fixture; stand resolution requires height above 0.05 m. RealityKit collision shapes belong to point/housing/stand/feet, not outline or aim markers.

Stale-hit guards are source-consistent: SceneKit rejects hidden traversed nodes/hidden content, requires registered identity, direct content attachment and current UUID; removal rebuilds maps and detaches nodes. RealityKit rejects disabled traversed entities/anchor and requires the current owned root attached to that anchor; removal clears ownership. UI-disabled/inactive/detached interaction is blocked by actual tap guards, separately from graph lookup. Both taps also guard VoiceOver-running state; this establishes no navigation result.

Candidate `e66319bf8ee54925ae2121154adfbc4a6bbd099c` changes rectangle face scale, with no interaction-code change. Source inventory supplied: frozen 183/37, candidate 184/38; root-confirmed older `9725` native 176/30 pass is historical. No builds, tests, native gestures, occlusion, visual acceptance or RealityKit runtime claim. Core06/composition01/Plan07/AR13/Study03/04 untouched.

---

## accessibility_privacy

# Wave06 — accessibility/privacy status review

Reviewer: `/root/w06_acceptance/accessibility_privacy`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`  
Candidate: `e66319bf8ee54925ae2121154adfbc4a6bbd099c`

**Finding — emitter diagnosis remains generic.** The equipment rack supplies name, emitter type, distance, Kelvin, candela, and selected trait; it defines no aim-specific accessibility label/value (`App/StudioView.swift:926–948`). The selected-light inspector maps missing illuminance to “Estimate unavailable” and asks users to check aim/separation/near-field geometry (`:989–1003`). This communicates unavailable estimation, not a diagnosis that the emitter and target coincide. “Aim at subject”/target-coordinate controls describe configuration, not aim validity (`App/OpticsInspector.swift:52–67`). On the RealityKit branch, RealityStudioPreview's note excludes undefined aimed frames from its active-light count but supplies only illustrative-lighting/count or invalid-setup wording (`App/RealityStudioPreview.swift:15–25,43–55`).

**Camera status is more specific.** For a valid scene with unavailable authored framing, native SpatialPreview hides content and requests “Camera preview unavailable. Move the camera away from the subject.” Invalid scenes receive separate setup guidance (`App/SpatialPreview.swift:223–231`). Normally native descendants are hidden (`:187–190`); a nonnil message sets `accessibilityElementsHidden` false and shows a wrapping, Dynamic-Type UILabel identified as `spatialPreviewUnavailable` (`:498–522`). The current SwiftUI camera branch checks framing first and displays its own “Camera framing unavailable”/move-camera text instead of constructing SpatialPreview when framing is unavailable (`App/StudioView.swift:722–739`); CameraInspector also gives move-camera guidance (`App/CameraInspector.swift:23–43`). These establish label semantics, not demonstrated VoiceOver speech, focus, navigation, or reachability. RealityKit's native surface remains accessibility-hidden (`App/RealityStudioPreview.swift:78–80`).

**Privacy and evidence boundary.** These status paths consume existing local scene/selection state. RealityKit constructs a non-AR view without automatic session configuration (`App/RealityStudioPreview.swift:63–72`). The inspected candidate delta only corrects rectangle `face.scale` (`App/StudioEntityGraph.swift:275–278`, candidate) and adds `NativeTests/SpatialAimRecoveryTests.swift`; it introduces no label, permission, upload, or personal-data-path change. This is scoped source inspection, not a whole-app privacy or platform-accessibility audit; no builds/native tests were run.

**Owner handoff.** Retain lane01's existing aim-status usability request (`docs/parallel/05/OWNER_REQUESTS.md:7`); its separate composition identity request (`:9`) remains intact. No composition, core, Plan, AR, or Study edits.

---

## platform_performance

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

---

## independent_review

# W06 independent exact-patch review

Reviewer: `/root/w06_acceptance/independent_review`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`  
Commits: `d112069f8c4fa4a1770c130fe6c8491fe9c21817` → `e66319bf8ee54925ae2121154adfbc4a6bbd099c`

**APPROVE for source integration. No concrete required revision to this exact patch.**

The supplied aggregate matches the commit-chain diff byte-for-byte, with exactly two changed paths and one new test method. Captured sources match the private writer tree; `git diff --check` passes. No implementation files were edited.

Independently checked Core's contract: `StudioSceneBounds.swift:3–6,27–34` defines emitting-face corners, explicitly excluding housing; `StudioOptics.swift:131–136` passes the same dimensions to the photometric rectangle. `LightOptics.dimensionRange` is 0.05…4 m, enforced before graph updates. With `generateBox(size: 1)`, the corrected rectangle scale supplies those full extents. The former 1.2×0.7 m face lost 2.697143% area; the 0.05 m square lost 42.24%. Directional inset, face depth 0.006 m, center z=−0.003, front plane, frame/roll and source orientation are byte-unchanged. The existing viewport envelope includes half-width/height plus 0.03 m and z=−0.15…0.08, enclosing the enlarged face throughout the valid dimension range.

The literal test bases are correct: −Z/+90° gives fixture right/up = +Y/+X; +Y/−90° gives +Z/+X. Source right reverses while local −Z still maps to the emitting normal. Assertions retain UUID resolution, child identities, fixture/outline/stand geometry and selection through coincidence, require actual light removal, then check restored spotlight pose/output and translated stand position. Existing 2e−5 m position and 1e−6 axis/dimension tolerances are preserved. `project.yml` includes `NativeTests` in `KeyAndFillTests` and the test scheme.

Evidence limits remain explicit: the geometry witness uses scalar formulas, its recovery trace is source interpretation, and its Float errors exclude native quaternion/transform arithmetic. The comparison table's rectangle row omits the former RealityKit housing/face distinction and SceneKit's 0.012 m chamfer: outer box dimensions/front-center anchors do not establish tessellated flat-face corner parity with Core. This SceneKit recovery test does not execute the RealityKit scale correction; historical native passes do not execute this candidate. Native tests, compilation and type checking are **UNRUN**; no RealityKit visual, calibration or performance acceptance is claimed.
