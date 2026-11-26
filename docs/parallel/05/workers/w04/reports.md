# Lane05 wave04 — ten original reports
Original input: 956a3b1d70cb3d67ba136821d9828be80aee1c3b; post-reset input: 9725fb1177a5c7afbdf798ffd627e65e604c75b1. Exactly ten completed contexts; concurrency followup reused its original context.

---

## acceptance

# Wave04 acceptance

Canonical ID: `/root/w04_acceptance`. Original input `956a3b1d70cb3d67ba136821d9828be80aee1c3b`; resumed input `9725fb1177a5c7afbdf798ffd627e65e604c75b1`. Branch `finish/05-spatial-viewports`; campaign baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. Source edits/commits by this worker: none.

## Checks and evidence

Read pinned AGENTS, operating protocol, handoff/state, product, architecture, roadmap, quality, design, code acceptance and lane plan; reviewed four owned App files and five spatial test files. `agent_cycle.py check` returned structure-valid; `next` returned M03 editing/accessibility/persistence outstanding. Those read-only commands observed live9725, not application execution.

Python source discovery using the repository's method pattern found **176 native/30 spatial methods**. An initial line-start pattern missed four inline-annotated PDF methods; corrected discovery is retained in `native-inventory.json`. Discovery is not a pass.

The executor reset removed original private artifacts. Resumed Python hashes independently matched all four owned App files to retained original956 tool-output hashes (`source-recovery-comparison.json`). Native source identity across recovery was additionally reported by root. Historical68c83 RealityStudioPreview/SpatialPreview match, but entity graph/viewport geometry changed; old171/25 native results do not establish current acceptance.

## Acceptance decision

The owned mixed-mode invalid-scene hole was confirmed by two workers: publishing orbit mode before invalid return consumed a required Fit. Reviewed exact candidate `b35671f971be2e2dd4d05d7531486a3de4ce25c2`: conditional valid-mode publication preserves both pending mode-change Fit and ordinary user orbit. The four new tests cover authored-camera recovery, nil-camera recovery, unchanged orbit and initial empty interaction. Root, concurrency and independent review checked the exact patch; no source blocker found. Root reports integration `bc5b137e9717c9e20bfaf210d798bb7e4bb3836c` and remote preservation `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`.

The regression assertions check live camera/target/projection/interaction outcomes; they are meaningful native tests but **uncompiled/unexecuted here**. Candidate inventory is180/34, derived from baseline plus four new declarations.

First-save `.id(generation)` viewpoint loss remains a separate lane01 owner request. Geometry and interaction witnesses establish sampled/bounded math only. SceneKit clipping under translated native control remains conditional pending actual controller-camera/range observation. SceneKit VoiceOver navigation asymmetry is a source gap, not demonstrated interference.

Required next evidence: current native execution; RealityKit coordinator and SceneKit controller/lifecycle behavior remain unobserved. No milestone promotion, native/build/toolchain run, device performance, manual VoiceOver, calibration or release-readiness claim. Historical and current evidence remain separate. Root owns integration and execution.

---

## geometry

# Wave 04 geometry review

Agent: `/root/w04_acceptance/geometry`  
Input SHA: `956a3b1d70cb3d67ba136821d9828be80aee1c3b`

## Result

No Fit containment or clipping defect identified for equipment within the reviewed limits. Floor/grid are deliberately excluded. Bounds include rotated 4 m housings, selection margins, aim markers and world-floor stand bases; entity dimensions agree with those margins.

The independent scalar witness found:

- Arbitrary housing offset <=2.874770 m; every equipment coordinate fits +/-102.874770 m. Bounds radius <=178.184328 m, so Fit distance <=490.652737 m, below its 1,500 m cap.
- Sphere-fit near depth >=1.402900 m versus near=0.02 m. For targets bounded to +/-300 m, target-to-equipment distance <=697.799570 m, leaving >=52.200430 m within `far=distance+750` at any orbit angle.
- Extreme-pan witness: target=(300,300,-300), distance=0.45 m, opposite authored point=(-100,-100,100): depth=693.270323 m < far=750.45 m.
- Three boxes, eight corners and four layouts produced 96 passing projection checks, including Float-rounded vertical FOVs. The 100 m stand / coincident 4 m modifier had depth=121.324908...159.856738 m < far=890.590823 m. Maximum absolute normalized screen coordinate: 0.874857551 <1.

Source review: ordinary updates/layout preserve orbit; initial/changed Fit tokens recenter. Pan uses the smaller viewport axis and preserves distance. Matching regressions cover translation, high stands, extreme rigs, gesture bounds, Fit recovery and clipping; they were not executed.

## Commands and evidence

Successful pinned `git show` reads covered AGENTS, architecture/design/acceptance, geometry/entities/adapters, core limits/frame/bounds and native tests. Exact inputs are in `commands.txt`.

`python3 /tmp/keyfill05-be879deb/waves/w04/geometry/witness.py --reviewed-only` exited 0; results are in `witness.json`. Initial invocation exited 1 after git exited 128 because executor reset removed the repo. Calculation uses already-reviewed constants; no post-reset source recheck or source hashes.

## Limits and changes

Python derivation only. No Swift build, XCTest, native rendering, screenshot, device, VoiceOver or performance evidence; no previous CI carried forward. Source changes/commits: **none**. Artifacts: this report, `witness.py`, `witness.json`, `commands.txt`.

---

## interfaces

# Wave04 interfaces

canonicalID: /root/w04_acceptance/interfaces

inputSHA: 956a3b1d70cb3d67ba136821d9828be80aee1c3b

lane01CheckpointSHA: 966c9c21adbb685d82127e7f88981b74daf47e3d

## Outcome: first-save viewpoint continuity fails by source trace

Read pinned AGENTS.md, architecture/design, four owned spatial files, composition/adoption boundaries and viewport test source. Used immutable git reads and checkpoint GitHub file reads. Actual original-pin reads predate the executor reset; no substituted live-head evidence.

**Identity transition:** Draft in 3D: projectID=nil, generation G0, workspaceResetID W0, Fit counter N, adjusted pose P. First save creates a project ID. ProjectLibraryOperation.swift:115-120,131-134 preserves scene/history/presentation but rotates G0→G1. Checkpoint StudioSession.swift:210-214 retains W0. StudioView.swift:515-520 nevertheless uses `.id(generation)` for RealityStudioPreview, replacing its representable/coordinator. Input StudioView.swift:506-511 has the same boundary: this is a retained defect.

The new checkpoint RealityKit coordinator initializes lastFitRequest=nil/needsFit=true (RealityStudioPreview.swift:105-112); update/layout resets target, distance, yaw and pitch (179-181,216-230) despite unchanged N. SceneKit fallback initializes nil lastCameraMode/lastFitRequest (SpatialPreview.swift:28-33), triggering Fit (153,187-189). P is lost without pressing Fit. This is source-derived lifecycle evidence, not an observed native result.

**Other checks:** At the input pin, retained-coordinator edits/selection refresh callbacks without refitting (RealityStudioPreview.swift:189-205; SpatialPreview.swift:204-269). Explicit Fit changes the counter; SpatialOrbitState.fit resets navigation. StudioEntityGraph updates geometry by UUID independently of viewport state. Later same-project saves/renames retain generation; switch/reload/recovery reset presentation. Camera mode follows the authored camera.

**Lane01 owner request:** In StudioView composition, key the 3D wrapper by `session.workspaceResetID`; retain captured generation for stale-selection rejection. Cover first-save G0→G1/W0→W0 retaining the native coordinator and adjusted pose, explicit Fit resetting pose, and switch/reload W0→W1 resetting identity. Existing viewport state tests cover navigation math, not this SwiftUI transition. Root integrates; no owned spatial source change is needed for this fix.

**Limits:** No builds/toolchain/native runs. Historical CI 68c83/run45817222487: 366 Debug + 366 Release core, 100 tooling, 171 native/25 spatial. Pin discovery: 176 native/30 spatial, unexecuted. No RealityKit runtime, device or VoiceOver acceptance claims.

Files/commits: report.md only; source files none; commits none.

---

## implementation

# Wave04 implementation

canonicalID: `/root/w04_acceptance/implementation` (lane05)
inputSHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`
commit: `b35671f971be2e2dd4d05d7531486a3de4ce25c2`

## Finding and authorized repair

At frozen `App/SpatialPreview.swift:212–265`, valid orbit/Fit0 → valid camera → invalid orbit/Fit0 → valid orbit/Fit0 loses the pending Fit. The invalid update publishes `lastCameraMode=false` before returning, while `lastFitRequest=0` remains. Recovery therefore computes both `modeChanged=false` and `needsFit=false`, skipping the fitted pose/lens/clipping replacement. This is a source control-flow finding; no native failure was executed.

The authorized repair publishes `lastCameraMode` only when `valid`, before deriving interaction availability. Invalid content still hides/disables/discards equipment; the last successfully applied mode survives for recovery. Ordinary same-mode invalid→valid orbit retains navigation. Only this app file and new `NativeTests/SpatialNavigationRecoveryTests.swift` changed; no Core/composition/Plan/AR/Study edits.

## Four focused native regressions, unexecuted

Each uses one360×280 coordinator/view and unchanged Fit0, flushing SceneKit transactions:

- Orbit → authored85mm camera → duplicate-UUID invalid orbit → valid orbit.
- Orbit → coincident camera/subject clearing pointOfView → duplicate-UUID invalid orbit → valid orbit.
- Manually positioned orbit camera(7,5,9), target(1,2,3) → invalid orbit → valid orbit: preserve camera identity, position and target.
- Initial valid empty orbit: enable interaction without UUID cancellation or control toggling.

Recovery asserts visible content, enabled controls/interaction, coordinator camera identity, FOV48°, near0.02, and pose/target/far matching fresh bounds Fit using existing Float tolerances. Invalid stages assert hidden content and disabled interaction; authored recovery also checks discarded hit identities.

## Actual evidence

Frozen reads used `git -C /tmp/keyfill05-be879deb/repo show 9725fb1177a5c7afbdf798ffd627e65e604c75b1:<path>` across all four app/five spatial test files and required contracts. `git ... grep` confirmed existing tests cover these transitions separately. HEAD matched input; unrelated checkout changes were untouched.

`git worktree add --detach /tmp/keyfill05-be879deb/worktrees/w04-implementation <inputSHA>` succeeded. In that checkout, `git diff --cached --check` passed; commit succeeded; `git status --short` was empty. Exact committed diff is `change.patch`, SHA256 `6b6165acef74c09df9ba709ece84e5eb390bc7123d83c825b69cd686390e0ec9`.

Original956 source unavailable; lead's unchanged-file verification accepted. No build, compiler, native run, toolchain install, RealityKit/device/VoiceOver evidence. Historical passes do not validate this commit. Root owns exact-patch independent/concurrency review, integration and execution; production UI reachability remains unestablished.

---

## concurrency

# W04 concurrency

canonicalID: `/root/w04_acceptance/concurrency`  
inputSHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

**Confirmed source-order defect:** orbit/Fit0 → camera → invalid orbit → valid orbit/Fit0 retains authored/nil POV. `SpatialPreview.swift:224` records orbit mode before invalid return; recovery computes `needsFit=false` (:212), skipping :263–265. Independently confirms the implementation worker's finding.

## Transition table

| Event | RealityKit | SceneKit |
|---|---|---|
| Initial zero layout | Fit waits for valid size (:228–237). | Fits immediately; layout corrects projection axis (:523–532). |
| Fit while invalid | Stores pending flag; waits for valid scene. | Request unconsumed; recovery fits, except mode defect above. |
| Fit while inactive/disabled | Valid scene/size consumes Fit offscreen. | Valid update consumes Fit before wrapper disables interaction. |
| Re-enable | Restores interaction with rendering/current scene; preserves orbit. | Wrapper refreshes interaction after no-op updates; preserves pose. |
| Window removal | Removes anchors/cancels gestures; reattachment restores anchors. | Stops inertia/playback; selection rejects absent window; no explicit playback resume. |
| Cancellation | ID changes/inactivity disable recognizers; cancelled handlers ignore deltas. | Invalid/ID changes cancel selection; disabling/Fit stops inertia. |
| Callback refresh | Before graph/Fit processing. | Before no-op guard; invalid/dismantle clears callback. |

**Fix review:** conditional `if valid { coordinator.lastCameraMode = cameraMode }` preserves the last applied mode through invalid input without resetting ordinary orbit recovery. Keeping this assignment before availability also preserves initial empty-orbit interaction; moving it below the guard can miss that helper-level refresh.

**Coverage:** inspected native tests cover Fit, edit preservation, orbit-only invalid recovery, callback replacement and disable/dismantle; no mixed-mode recovery, actual cancellation or RealityKit coordinator lifecycle coverage found.

**Checks:** pinned `git show SHA:path`; AGENTS/architecture/design/acceptance/lane plan and numbered source/test inspection. One mistyped architecture SHA failed; corrected read succeeded. `python3 /tmp/keyfill05-be879deb/waves/w04/concurrency/model_check.py` matched four mixed-mode and two same-mode expectations. Exact commands/hashes/model traces: `evidence.json`.

Source edits/commits: **none**. Model-only, not native execution or frame-atomicity proof. No builds, device/RealityKit/VoiceOver/performance claims; historical CI not rerun.

### Same-context exact-patch followup

# W04 exact patch review

canonicalID: `/root/w04_acceptance/concurrency` (same context)

Candidate: `b35671f971be2e2dd4d05d7531486a3de4ce25c2`  
Verified parent: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`  
Verified patch SHA256: `6b6165acef74c09df9ba709ece84e5eb390bc7123d83c825b69cd686390e0ec9`

**Disposition: no source blocker found; suitable for integration and native validation.** Exactly two files change: one conditional assignment with explanation in `SpatialPreview.swift`, and 137 lines containing four new native tests.

The conditional publishes mode before availability for valid scenes, preserving initial empty-orbit interaction. Invalid scenes still publish unavailable content and disable interaction while retaining the last applied mode. Camera → invalid orbit → valid orbit therefore keeps its Fit pending; orbit → invalid orbit → orbit retains the user's pose. Existing request accounting, callback replacement and transaction lifetime remain unchanged.

| Regression | Adequacy in source |
|---|---|
| Authored camera recovery | Establishes 85 mm camera state, invalidates, then requires orbit position/target, 48-degree FOV, clipping, visibility and interaction with Fit0 unchanged. |
| Undefined camera recovery | Establishes nil POV, then requires recovered orbit state. |
| Same-mode invalid recovery | Requires the same user camera and target, challenging unconditional refitting. |
| Initial empty orbit | Requires interaction and fitted state without UUID cancellation or control-mode refresh. |

Swift source appears consistent with existing tests: main-actor XCTest isolation, SceneKit imports, accessible helpers, Float-ULP tolerances, transaction flush and deferred dismantling. Invalid-fixture indexing is confined to nonempty portrait fixtures. Expected geometry reuses the orbit helper appropriately for this lifecycle test; numerical geometry coverage remains separate.

Actual checks: pinned `git show` full two-file diff/stat/parent; `git diff --check 9725fb1177a5c7afbdf798ffd627e65e604c75b1 b35671f971be2e2dd4d05d7531486a3de4ce25c2` exited 0; Python SHA256 verification and declaration scan found four methods. Candidate source hashes:

- SpatialPreview: `f7d90394a449c859a0fdebd98e7b11b0a5dad942d971d6a1d3a24474c9f0a585`
- New tests: `fda09865e8e15476789f5ae20a3770002d88f5003677335ead59f11cdb9ebd51`

No builds, native execution, source edits or commits by this reviewer. Test adequacy and Swift plausibility are source conclusions, not executed passes. Prior report/model remain pinned to the original input.

---

## resources

# Resource ownership review

canonicalID: `/root/w04_acceptance/resources`
inputSHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

Outcome: no accumulating navigation graph or local callback cycle identified. Counts describe application-held objects; framework/controller internals and GPU allocations are excluded.

| Ownership/transition | RealityKit | SceneKit |
|---|---|---|
| Fixed holders | 53 graph entities + orbit anchor/camera = 55; 2 shared meshes, 2 collision shapes, 4 recognizers. | 8 explicit nodes; 1 scene/camera component/ambient light, 5 fixed geometries, 1 selection recognizer. |
| Per UUID | 24 entities: 4 groups/emission, 8 models, 12 outline models. Globally at most 7 authored shading components + fixed fill. | 4 nodes: fixture/source/indicator/stand; up to 3 geometries, 1 source light. Detached stand retained for reuse. |
| Orbit/pan/zoom/Fit | Gestures mutate orbit/camera only. Fit scans bounds; graph update computes bounds before equality guard. | Native controller navigation; no app graph rebuild callback. Fit scans bounds, reuses camera; updates scan identity/selection collections. |
| Invalid; remove/readd | Clears lamps/hit maps; retains disabled fixed graph. Readdition creates fresh lamp. | Clears equipment/maps; retains hidden base/camera. Readdition creates fresh nodes. |
| Window detach/reattach | Removes/readds same anchors; retains graph/orbit. | Stops inertia/playback; retains nodes/controller. No explicit playback restart or graph reconstruction on reattach. |
| Dismantle | Clears closures, gesture targets/delegates, callbacks and view attachments. Graph/resources remain coordinator-owned until release. | Clears callback/gesture, scene/pointOfView, children/maps/base; retains empty content and camera node/component until coordinator release. |

Views are weakly held; RealityKit callbacks capture self weakly. Selection callbacks replace prior storage and clear on dismantle. External captures remain unproven. Fit/representable updates are not constant-cost navigation.

Commands/checks: `git show 9725fb1177a5c7afbdf798ffd627e65e604c75b1:<path>` reads exited 0; manual ownership/transition tracing completed. Read AGENTS/startup, architecture/design/code-acceptance docs; four assigned App files; native SpatialEntityUpdate/Interaction/Preview/EmitterGeometry/ViewportState and StudioViewportGeometry tests. Tree reads located files; report checked with `wc -w -c` and `sha256sum`.

Existing assertions cover 100 repeated updates retaining count/identity, callback refresh, geometry/node reuse, stand reattachment, stale hits after removal/invalid recovery, and SceneKit dismantle. They do not establish deallocation or RealityKit/window lifecycle behavior.

files/commits: source edits none; commits none; report only.
Limits: no build/toolchain/native/test execution, profiling, telemetry, allocation/RSS/timing or acceptance claims. Historical results not rerun/promoted.

---

## interactions

# Lane05 wave04 — interactions

**Canonical worker:** `/root/w04_acceptance/interactions`  
**Frozen input:** `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

Read pinned `AGENTS.md`, architecture, design, M02/M03 code acceptance, both preview adapters, viewport geometry, and relevant native test sources using `git show`. Repository files/commits changed: **none**.

## Actual checks and outcomes

Executed `python3 /tmp/keyfill05-be879deb/waves/w04/interactions/witness.py`; exit **0**. It reads three pinned source blobs, checks 21 implementation snippets, and reports their SHA256 values. This is a Python transcription plus independent camera-basis projection, not execution of Swift or native adapters.

- **Pan:** 144 projection cases across six yaw/pitch pairs, three portrait/landscape sizes, four signed drags, and centered/off-center fixed subjects at target depth. Camera right/up are reconstructed from position/target using cross products. UIKit-positive X/Y move the fixed subject right/down by the requested point delta; maximum error **5.684341886080802e-14 points**. Distance remains unchanged. Cases avoid target clamping.
- **Orbit/zoom/Fit:** six orbit cases preserve target and radius while applying yaw subtraction/pitch addition; two pitch-limit cases pass. Pinch scales 1.2/2 reduce RealityKit distance from 7 m to 5.833333333333334/3.5 m; scale 0.5 produces 14 m; extremes reach 0.45/1500 m bounds. Incremental factors compose correctly. Explicit Fit restores bounds center, yaw **0.56**, pitch **0.36**, and the radius-derived clamped distance.
- **Fit tokens:** source review and predicate witnesses agree. RealityKit defers its initial fit until valid layout, consumes a changed token once, and keeps pose through same-token metadata/layout updates; modeled fit counts **0,1,1,1,1,2,2**. SceneKit's stable orbit-mode predicate rejects repeated tokens and accepts a changed token; layout changes projection axis only. Initial/pending fit and SceneKit mode changes are separate triggers. SceneKit Fit reconstructs the shared orbit pose and controller target.
- **Production increments:** RealityKit orbit/pan read translation then reset to zero; zoom reads scale then resets to one; handlers consume began/changed states. SceneKit retains framework gestures; its pinch is not asserted to implement RealityKit distance zoom.

**Outcome:** no defect found in the sampled math or valid, stable orbit-mode Fit flow. No build, native interaction, rendering, toolchain, or XCTest execution claimed. Historical 171/25 passing and 176/30 discovered counts were not rerun; the separate recovery fix and its tests are outside this input/review.

**Artifacts:** this report and adjacent `witness.py`; no other outputs or commits.

---

## accessibility_privacy

# Wave 04 — accessibility/privacy

Canonical ID: `/root/w04_acceptance/accessibility_privacy`  
Input SHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

## Actual checks

Pinned `git show` reads: AGENTS; architecture/design; lane-05 and M02/M03 acceptance; privacy excerpts; RealityStudioPreview/SpatialPreview; SpatialInteractionTests/SpatialPreviewTests/SpatialEntityUpdateTests; relevant StudioView and StudioAppAccessibilityUITests sections. Discovery: `git ls-tree -r --name-only`. Inspection: `nl -ba`, `sed -n`, `rg -n`. Exact representative command:

`git -C /tmp/keyfill05-be879deb/repo show 9725fb1177a5c7afbdf798ffd627e65e604c75b1:App/SpatialPreview.swift | nl -ba | sed -n '490,650p'`

A SpatialPreview permission/session/network-symbol search returned exit 1 (no matches); this is not runtime evidence.

## Outcomes — source evidence

- Equipment alternative: StudioView:912–948 has named 52-point-minimum light buttons, values, checkmark and selected trait. Busy state disables rack/workspace (:111–113); selection validates generation (:1220–1224) and membership (:927–929). UI test source asserts list selection and targets; no VoiceOver execution occurred.
- RealityStudioPreview:149–162,247–288 gates all custom gestures on enabled/rendering, valid scene, window and VoiceOver state. SpatialPreview:73–87,136–138,195–197 gates disabled/inactive interaction and VoiceOver selection.
- **Source gap:** SceneKit native navigation lacks an explicit VoiceOver gate: orbit-mode `allowsCameraControl` stays enabled (SpatialPreview:184,246–248); the VoiceOver predicate belongs to custom selection. This asymmetry does not establish actual gesture interference.
- Unavailable feedback exists: RealityStudioPreview:43–44 invalid-setup note; SpatialPreview:223–229,496–520 multiline, Dynamic-Type-aware label with accessibility children exposed; StudioView:722–738 camera-framing error and corrective instruction. Native assertions cover hidden geometry/recovery, not spoken feedback.
- Navigation updates renderer camera state; immutable scene input and selection-only callback do not author camera edits. Camera mode disables selection/control and applies authored pose/lens (SpatialPreview:207,246–258). Fit has a 44-point labeled button/hint (StudioView:554–557). No additional missing selection/feedback control established.
- RealityStudioPreview:71–72 explicitly constructs `.nonAR` with automatic session configuration disabled; its source contains no permission request, session start or network operation. Device permission/network behavior remains unobserved.

Files changed: this report only. Source edits/commits: none. Builds, toolchain/native/UI runs, manual VoiceOver and device privacy checks: not performed. Historical/successor results are not fresh worker evidence. Known first-save identity and invalid-mode issues were not reopened.

---

## platform_performance

# Lane 05 / wave 04: platform and projection

Canonical ID: `/root/w04_acceptance/platform_performance`  
Input: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`.

**Disposition: conditional clipping counterexample; native reachability remains unverified.** SceneKit Fit assigns `zFar = fittedDistance + 750` once (`SpatialPreview.swift:272–286`). Native controls remain enabled; subsequent ordinary updates/layout do not recompute depth limits. `SpatialOrbitState` gesture clamps constrain RealityKit only. RealityKit refreshes its far distance after every gesture (`RealityStudioPreview.swift:241–270`).

For any fitted distance d, backward movement of 1,000 m makes the fitted center depth d+1,000, exceeding fixed far d+750 by 250 m. The independent Python witness also places an entire hypothetical 1 m equipment sphere beyond far. This proves clipping **if** the active native camera retains manual clipping; it does not prove SceneKit's actual camera handoff behavior.

Apple documents [pinch as FOV change and three-finger movement as translation](https://developer.apple.com/documentation/scenekit/scnview/allowscameracontrol?changes=l_1). Pinch alone therefore does not establish this depth failure. The same documentation says native control creates a separate camera. [Automatic depth adjustment defaults false, and assigning near/far resets it false](https://developer.apple.com/documentation/scenekit/scncamera/automaticallyadjustszrange?changes=_3&language=objc); the free camera's effective behavior still requires observation.

**Focused next check:** host the real preview, Fit, trigger a genuine native camera gesture, then record renderer/controller camera identities, transforms, FOV, near/far, automatic-range flag and projection. On that active controller, translate backward using `translateInCameraSpaceBy(x:y:z:)`; after a rendered frame, inspect equipment corner depths/projections and capture the image. Record any framework clamp/automatic projection update. `evidence.md` specifies the branches and Fit recovery. Do not implement a speculative repair before this check.

Projection review found the RealityKit Float-180 rejection present; math samples reject zero and 0.00001×1,000 layouts, accepting 1×1,000. Zero layout leaves RealityKit Fit pending; SceneKit chooses its smaller FOV axis after layout. Geometry resources/node identity are reused by source, without a performance measurement.

Actual checks: pinned `git show` review of directives, architecture/design/acceptance, four owned adapters and matching tests; official Apple documentation; `python3 witness.py` arithmetic assertions. No repository edits or commits. Created this report, `evidence.md`, `witness.py`, `witness.json` and source hashes. No Swift/build/native/device/VoiceOver/RealityKit/performance execution; historical CI counts are not current acceptance.

---

## independent_review

# W04 independent review

canonicalID: `/root/w04_acceptance/independent_review`

Input: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`  
Candidate: `b35671f971be2e2dd4d05d7531486a3de4ce25c2`

**Disposition: no source blocker found in the exact two-file candidate; native validation remains unperformed.**

The conditional mode publication precedes availability for valid input, retaining initial empty-orbit interaction. Invalid input hides/disables content and clears equipment without consuming the pending camera→orbit transition. Recovery then fits; same-mode orbit recovery preserves the user's camera. Repeated invalid updates and undefined authored-camera recovery introduce no contrary source path identified here. The four new tests distinguish these cases and use existing SceneKit/XCTest conventions.

## Coverage challenges

- Recovery assertions check position, target, identity, FOV and clipping, but omit orientation/projected containment. A stale rotation with otherwise corrected properties could satisfy them. Existing native projection coverage examines initial Fit, not this mixed-mode recovery. This limits the coverage claim; the candidate still calls the existing complete `fitOrbit` implementation.
- Baseline `SpatialViewportStateTests.assertFits` projects corners of the bounds produced by the implementation. It does not independently establish that every displayed mesh is inside those bounds. Separate emitter tests check selected SceneKit dimensions/transforms; RealityKit volume containment remains a source/mathematical conclusion.
- The bounded-state far-plane proof applies to `SpatialOrbitState` and its limits. It cannot establish SceneKit clipping after native free-camera handoff. The platform packet correctly leaves fixed-far failure conditional on the active camera retaining manual clipping; its gesture/translation/projection observation is still unrun. Pinch is not evidence of backward translation.
- First-save `.id(generation)` replacement remains a separate composition concern outside these two files; the retained-coordinator tests cannot cover it. SceneKit's VoiceOver selection predicate also does not prove native navigation is gated. Neither source asymmetry establishes observed device interference.

## Actual checks

Immutable `git show SHA:path` reads covered pinned AGENTS, architecture/design/acceptance, candidate diff, geometry, adapter and baseline test sources. Read all wave reports and the exact concurrency/platform packets. `git show -s --format=%P` verified the candidate parent above. `git diff --name-status INPUT CANDIDATE` returned exactly modified `App/SpatialPreview.swift` and added `NativeTests/SpatialNavigationRecoveryTests.swift`; `git diff --check INPUT CANDIDATE` exited 0. Python inspected pinned git bytes: four new test declarations; both candidate blobs equal those in integrated `bc5b137` and preserved `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`.

Files: this report only. Source edits/commits: none. No builds, toolchain, native/tests, rendering, device, VoiceOver or performance execution; inventories and historical passes are not current candidate acceptance.
