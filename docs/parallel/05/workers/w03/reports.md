# Wave03 — ten original reports

Product input: `35283bed09c609be424df80f36b42391aec19f74`. Later source68 CI success is reconciled in `ledger.json` and `synthesis.md`; original specialist reports remain unchanged.

---

## acceptance

# Wave03 acceptance trace

- Context: `/root/w03_acceptance` (acceptance specialist and queue lead).
- Input: `35283bed09c609be424df80f36b42391aec19f74`; local HEAD matched on initial read. Inspection used pinned `git show`, not moving checkout.
- Scope: stable construction and incremental updates, lane05; root owns product changes. Read AGENTS, operating protocol, plan, architecture/design and relevant renderer/tests.

## Acceptance trace

1. **Stable UUID, valid scene:** SceneKit keeps one `SpatialLampNodes` bundle per UUID. Output, temperature, name, position, aim and roll preserve fixture/source/stand/indicator node identity. Geometry changes only on kind or rectangular dimensions; name-only avoids render mutation. Evidence: `App/SpatialPreview.swift:347–460`.
2. **RealityKit identity:** one `StudioLampEntity` per UUID owns persistent point/housing/face/stand/selection children, shared meshes and collision resources. Kind and dimension changes toggle/transform children; source changes replace material/component values without replacing entity hierarchy. Evidence: `App/StudioEntityGraph.swift:100–124,169–191,217–344`.
3. **Intentional identity reset:** deleting a UUID removes nodes and maps; invalid scenes discard equipment. Reintroducing the same UUID creates fresh nodes, so retained hit objects cannot select replacements. SceneKit detach clears graph, callbacks and view; RealityKit detach disables coordinator interaction and detaches anchors. Evidence: `SpatialPreview.swift:95–163,229–244,347–355`; `StudioEntityGraph.swift:69–77,100–136`; `RealityStudioPreview.swift:208–225,273–278`.
4. **Selection and viewpoint:** selection-only changes retain geometry. Callback refresh precedes SceneKit's unchanged-scene early return and RealityKit graph updates. Ordinary edits preserve the current viewport; explicit Fit/mode changes may reset framing. Evidence: `SpatialPreview.swift:204–286`; `RealityStudioPreview.swift:189–205,228–244`.

## Existing evidence and gap

`NativeTests/SpatialInteractionTests.swift:19–105,143–159` declares metadata/output/selection identity, removed/reintroduced and invalid-scene rejection, detach, and 100-update node-count checks. `SpatialEmitterGeometryTests.swift:49–145` declares front-plane/roll and selection tests but creates independent scenes for shape cases. The new implementation worker targets repeated kind/dimension/stand transitions in one live view. Native execution and RealityKit runtime identity remain unverified in this wave; no performance, rendering or accessibility runtime pass is inferred.

## Checks actually performed

Pinned source and test inspection only. No build or native test execution. Parent's evidence packet: source68 had eight portable passes, ca3 nine; source352 declares ten but latest run was killed before execution. Later parent report: CI45817222487 succeeded at source68 with 171 tests, zero failures/skips, including 25 spatial tests, and two original SceneKit captures viewed. This does not verify source352 or testpatch44550b6. Acceptance is source-supported and regression-backed only after integration; native result must remain source-specific.

---

## geometry

# Wave 03 geometry/invariants

Worker: `/root/w03_acceptance/geometry` (parent `/root/w03_acceptance`).
Input SHA: `35283bed09c609be424df80f36b42391aec19f74`.

## Actual checks / outcome

Pinned `git show` reads of directives, lane plan, architecture/design, model, both adapters and all spatial tests; pinned NativeTests search for graph/mutation coverage. No concrete geometry regression found by source review.

- `App/SpatialPreview.swift:347–409`: persistent per-UUID fixture/source/stand nodes; only kind/rectangle-size changes replace meshes. Lines 410–458 reset pose before offsetting housing, preventing cumulative displacement. Source remains at authored center; fixture +Z and source −Z use the shared rolled basis (292–300, 416–440). Stand remains world-vertical.
- `App/StudioEntityGraph.swift:217–305`: persistent entities, dimension scales in meters, shared complete frame, fixed 180° emission-child rotation. Diffuser front is z=0; housing stays behind it. Stand top follows authored height; feet remain at world y=0.014. Camera lens/pose use −Z (47–53, 90–95).
- `App/SpatialViewportGeometry.swift:25–62`: bounds conservatively cover the adapters’ housings/outlines, point markers, busts, cameras, aim spheres and stands. Basis contract checked against `Sources/LightingCore/StudioOptics.swift:50–110`.

## Findings

**P2 missing mutation coverage.** `NativeTests/SpatialEmitterGeometryTests.swift:49–145` tests fresh construction/selection; `SpatialInteractionTests.swift:143–159` repeats position/output/order changes. Neither exercises same-UUID kind/size/roll/stand transitions. Add point→rectangle→directional→point, dimension endpoints, vertical/manual/follow-subject aim, coincident→valid aim and y crossing 0.05. After each update assert persistent nodes, expected mesh replacement, front-plane/source position, basis and stand detach/reattach identity.

**P2 RealityKit evidence gap.** No NativeTests references to `StudioEntityGraph` or `StudioLampEntity`; equivalent native mutation checks are absent.

## Limits / disposition

Zero builds/tests executed; no product edits. Ten pure state tests are declared, not observed passing here. Historical eight/nine-test Linux passes and CI 45817222487 at source 68… do not validate this SHA; parent reports latest ten-test build killed before execution. Recommend targeted mutation tests and exact-source native execution; source review alone does not establish acceptance.

---

## interfaces

# Wave 03 — interfaces

Agent: `/root/w03_acceptance/interfaces`  
Input: `35283bed09c609be424df80f36b42391aec19f74`

Files: `App/SpatialPreview.swift` (SP), `App/StudioEntityGraph.swift` (EG), `App/RealityStudioPreview.swift` (RP); `NativeTests/SpatialInteractionTests.swift` (IT), SpatialEmitterGeometryTests, SpatialViewportStateTests; core Scene/StudioSceneBounds. Read AGENTS, operating protocol, lane plan, architecture/design. Checks: pinned `git show` and `git grep`; no source edits, builds, or tests executed.

## Findings

- Continuing UUID and reorder: SP:347–367,403–405 reuses UUID-keyed lamps and rebuilds object identity mappings; EG:100–121 reuses UUID-keyed roots. Neither uses list indices. IT:143–159 covers repeated SceneKit edits/reversal.
- Deleted/reintroduced UUID: SP:150–160,347–367 removes old nodes, creates replacements and requires current object ownership plus UUID membership. EG:101–115,127–136 removes root mappings and requires cached-root identity/anchor ownership. IT:50–64 retains/rejects the removed SceneKit object after reinsertion.
- Invalid scene: SP:230–235,95–103 and EG:69–77 clear light caches/mappings. Bounds calls validation; duplicate UUIDs are rejected (`StudioSceneBounds.swift:14–15`, `Scene.swift:77`). IT:67–85 covers invalidation/recovery with fresh SceneKit objects.
- Equal scene, replacement callback: SP:204–213 refreshes the callback before its equality guard. RP:189–199 refreshes before graph update; RP:273–278 checks current UUID membership before invocation. Source supports the intended behavior.

## Concrete gaps

**P2 — unchanged-scene callback regression missing.** IT:31–47 changes name/output/Kelvin before asserting callback replacement. Moving assignment below SP's equality guard would still pass. Add two updates with identical scene/selection/mode/Fit values and different closures; resolve the same live node and assert only callback B fires. Also cover replacement by nil.

**P2 — RealityKit parity coverage missing.** Pinned grep across NativeTests/Tests found no references to StudioEntityGraph, RealityStudioSurface or RealityStudioPreview. Add a native host/test seam for the same identity, invalidation and callback chains.

Outcome: no demonstrated mapping defect; two focused test gaps. Native execution unavailable. Parent-provided source68 eight portable passes, ca3 nine passes and CI45817222487/source68 do not verify this input. Source352 has ten declarations; its latest attempt was killed before execution. No current pass claimed.

---

## implementation

# Wave 03 — implementation

- Worker: `/root/w03_acceptance/implementation`
- Input: `35283bed09c609be424df80f36b42391aec19f74`
- Commit: `44550b6837656e86f4fa7b588ac4cfe7a9b1c361`
- Private detached worktree: `/tmp/keyfill05-be879deb/worktrees/w03-implementation`
- Sole committed file: `NativeTests/SpatialEntityUpdateTests.swift` (217 lines; three test methods).
- Patch: `/tmp/keyfill05-be879deb/waves/w03/implementation/SpatialEntityUpdateTests.patch`

## Coverage

1. `testKindTransitionsReplaceShapeWithoutReplacingLiveLampNodes`: drives point → directional → rectangle → point through actual `updateView`. Requires fixture, source node, `SCNLight`, indicator, stand and cylinder identity continuity; requires fresh fixture/outline geometry for each kind transition. Checks source type, meter dimensions, housing front plane, rolled basis and source −Z direction. Stored rectangle dimensions edited while directional must preserve housing/outline geometry.
2. `testRectangleResizingReplacesGeometryWhilePoseAndOutputEditsReuseIt`: changes width and height separately between two unchanged-dimension edits. Pose, subject target, roll, name, output and temperature change concurrently. Checks selective geometry replacement/reuse, matching outline dimensions, output updates and the authored emitting plane.
3. `testStandThresholdDetachesHitsAndReattachesTheSameCylinder`: exercises 0.051 m, exactly 0.05 m, 0.049 m, 1.25 m, zero and 2.5 m. Requires detached stands to lose graph/hit membership; reattachment must reuse the original node/cylinder, update height and midpoint, and restore hit membership without accumulating nodes or replacing fixture/outline geometry.

## Actual verification and limits

Read the pinned implementation, existing spatial native tests, lane plan and project guidance. `git diff --cached --check` passed. Commit inspection confirmed exactly one added file; private worktree is clean. Root sparse-checkout and worktree-config SHA-256 values match their pre-worktree values.

**Three native tests authored; zero native tests executed.** No Swift compiler, build or replacement toolchain was invoked. The environment lacks the required toolchain after reset. Existing native CI `45817222487` refers to source `68c83cc`, not this commit; it supplies no execution evidence for these tests. This work establishes no native pass, performance result or release acceptance.

Test source SHA-256: `23c0415de68fe2a0d300ae70f0c8fdd686e27b96d828d01c14ce7601356d1cd2`.

Patch SHA-256: `c9744cf187064ad1b32345abe4516c76f7e038a96038cc1f559fec4829dd2717`.

Recommendation: independent source review, serial cherry-pick by root, then Apple CI execution with the integrated native inventory. No product/source changes are included. Rollback is removal/revert of this single added test file.

---

## concurrency

# W03 concurrency

- canonicalID: `/root/w03_acceptance/concurrency`
- inputSHA: `35283bed09c609be424df80f36b42391aec19f74`
- Actual checks: read-only pinned `git show` of required protocol/plan, architecture/design, viewport implementations, Scene validation and native test declarations; numbered inspection plus `rg` for actor/transaction/asynchronous constructs. No build, test execution, toolchain work, source edits or child delegation.

## Findings

**No concrete application-level interleaving defect found.** SpatialPreview/coordinator are main-actor isolated; update/helper paths have no await, Task or dispatch (`App/SpatialPreview.swift:8`, `:27`). Callback replacement precedes the no-op return (`:207`). Availability and current ownership gate selection (`:137`, `:150`). Re-enabling availability before reconstruction introduces no actor suspension.

**Transaction exits balance.** Update begins a transaction with zero duration/disabled actions and deferred commit (`:219`), including the invalid-scene early return (`:235`). Incremental geometry, visibility, outlines and camera setup are within that scope. Layout projection uses the same begin/defer pattern (`:526`).

**Recovery is coherent in source.** Invalid scenes hide content, disable interaction/stop inertia, clear callback/equipment maps and reset lastScene (`:223`, `:230`, `:95`). Retained base nodes stay hidden; recovery rebuilds lamps and rejects old fixture identities. Camera-unavailable valid scenes retain equipment while hiding content/clearing point-of-view; corrected framing reinstates pose/lens (`:251`, `:260`). Degenerate aimed lights retain markers but remove their light component; optics/subject changes force reevaluation (`:374`, `:411`).

**RealityKit comparison:** synchronous main-actor invalidation disables anchor and clears roots/cache (`App/StudioEntityGraph.swift:69`); surface validates currentScene before graph update (`App/RealityStudioPreview.swift:189`). No asynchronous interleaving found.

## Outcome

Source supports logical main-actor atomicity, **not demonstrated frame atomicity** across renderer, view properties and UIKit overlays. Invalid identity/camera-recovery tests exist (`NativeTests/SpatialInteractionTests.swift:67`, `:107`) but inspect final state; none ran here. Historical passes/CI do not establish execution at this SHA. Remaining native evidence: consecutive rendered frames during valid/invalid/recovered transitions under an enclosing animation. No source patch requested.

---

## resources

# Wave 03 — resources
- Canonical ID: `/root/w03_acceptance/resources`
- Input SHA: `35283bed09c609be424df80f36b42391aec19f74`
- Scope: read-only source review; no children, source edits, builds, tests or profiling.

## Evidence and checks
Read pinned AGENTS, OPERATING_PROTOCOL, lane PLAN, ARCHITECTURE and DESIGN. Inspected `SpatialPreview.swift` (95–163, 204–269, 309–479), `StudioEntityGraph.swift` (9–377), RealityStudioPreview teardown (98, 170–225), Scene validation (62–77), StudioSceneBounds (14–18), and existing SpatialInteractionTests (19–104, 143–159), using git show. Native test assertions were read, not run; new test commit 44550b6 was not re-reviewed.

## Findings
1. **Bounded retained topology.** Both adapters reconcile UUID dictionaries. Scene validation permits at most 12 unique lights. SceneKit retains four nodes per lamp; its content has five fixed direct children plus two per light and one per raised stand (at most 41 direct children). RealityKit explicitly constructs 52 base descendants and 24 entities per lamp: at most 341 including the anchor. These are source-derived application topology bounds, excluding framework internals. Reordering never constructs a replacement lamp.

2. **Reuse is qualified.** SceneKit changes transforms and existing material properties for output/pose edits. Emitter-kind changes or rectangle width/height changes replace fixture and copied outline geometry/materials. Stand geometry is lazily allocated once, retained while detached below the height threshold, and reused on return. An invalid aim clears SCNLight; recovery can allocate another. RealityKit generates two unit meshes and two collision shapes per graph; all lamp forms/outlines exist upfront and resize by transforms. Material values/arrays and light components are replaced on pose/optics/subject/output/shading changes. Reordering more than seven eligible lights can change shading assignments and trigger these replacements. Metadata/selection edits skip material replacement.

3. **Deletion and invalid recovery release application ownership.** SceneKit removes fixture/source/stand parents and selection entries, then rebuilds its identifier map. RealityKit removes root and UUID/identifier entries. Invalid input clears lamp maps and detaches lamps; valid recovery creates new roots. Identifier keys do not strongly retain hit objects. External retained hits may keep old objects alive but cannot resolve through the live maps. Base geometry/resources deliberately survive invalid input. RealityKit detach removes anchors but its coordinator retains the bounded graph until coordinator release; this is not immediate resource destruction.

4. **Stable counts do not establish allocation-free updates.** Validation/bounds, sets, arrays, colors and changed materials/components can allocate transiently; SceneKit/framework mesh-buffer behavior is unmeasured. Existing 100-update test checks direct child count and one fixture identity across edits/reordering, not heap growth, descendant counts or GPU release.

## Outcome
No application-owned unbounded growth or deleted-lamp retention defect found in this scope. Source reuse/cleanup supported; native execution and memory/performance conclusions remain unverified at the input SHA.

---

## interactions

# Wave 03 — interactions review

- Canonical ID: `/root/w03_acceptance/interactions`
- Input SHA: `35283bed09c609be424df80f36b42391aec19f74`
- Scope: read-only review of current selection/update behavior; no product edits, builds, toolchains, or test execution.
- Outcome: **no source defect identified in the scoped update paths; current native behavior remains unexecuted.**

## Findings

1. **Selection survives name/output/roll edits.** SceneKit retains the UUID-keyed lamp and indicator; name/output/roll changes do not replace the fixture node. The indicator remains its child, so the complete aim/roll basis and housing offset carry the outline. Selection visibility is reapplied after content updates. References: `App/SpatialPreview.swift:204–269,356–409,430–440`.
2. **Kind/size changes preserve selection ownership.** SceneKit replaces fixture/outline geometry only when kind or rectangular dimensions change, retaining both nodes and updating the outline margin. RealityKit retains its lamp root, fixture and selection children; shape switches alter enabled geometry and dimensions, while selection remains under the oriented fixture. References: `App/SpatialPreview.swift:371–400`; `App/StudioEntityGraph.swift:107–124,228–245,249–279,346–364`.
3. **Aim markers and source pointing are coherent by inspection.** RealityKit recomputes aim endpoints on geometry changes, disables both markers for point/degenerate/Float-short aims, and applies selection visibility even without geometry changes. Its emission child reverses local +Z for spotlights. SceneKit uses the complete frame with a right-handed -Z light conversion. References: `App/StudioEntityGraph.swift:240–241,292–308`; `App/SpatialPreview.swift:292–300,411–424`; `Sources/LightingCore/StudioOptics.swift:107–110`.
4. **Same-scene selection and viewpoint persist.** Both adapters include selection in their update guards. SceneKit refreshes callbacks before its guard and leaves orbit/controller state untouched except initial/mode/explicit Fit changes. RealityKit refreshes callbacks, retains orbit state, and only requests Fit on its fit token; ordinary edits keep the UUID set and do not cancel gestures. References: `App/SpatialPreview.swift:204–269`; `App/StudioEntityGraph.swift:69–80,306–308`; `App/RealityStudioPreview.swift:189–205,228–245`.

## Actual checks and limitations

Read pinned `AGENTS.md`, operating protocol, lane PLAN, architecture/design, three adapter files, and all four existing spatial native test files using `git show`; searched native tests and core frame definition using `git grep`. Existing assertions cover metadata/output identity, callback refresh, selection-only visibility, initial roll/aim alignment and orbit retention. Optional patch `44550b6837656e86f4fa7b588ac4cfe7a9b1c361` was read: its three tests add SceneKit kind/size transition and stand-threshold coverage, including indicator-parent/hit identity. No RealityKit graph transition tests were found in the current native suite. Neither pinned source nor patch was executed here. Parent-reported successful CI at source `68c83` is earlier-source evidence only. No native or visual pass is claimed for `35283`/`44550b`.

---

## accessibility_privacy

# Wave03 accessibility/privacy

Canonical ID: `/root/w03_acceptance/accessibility_privacy`
Input SHA: `35283bed09c609be424df80f36b42391aec19f74`
Outcome: no scoped source blocker; native acceptance unverified.

## Actual checks

Pinned `git show` review of AGENTS, operating protocol, lane05 PLAN, architecture/design, three viewport adapters, focused StudioView handlers and SpatialInteractionTests; scoped privacy-token search; adapter diff against `68c83`. No product edits/builds/native execution.

## Findings and references

- Noncolor selection survives reuse: persistent SceneKit indicators receive selection visibility outside geometry updates; an enlarged wireframe supplies the cue (SpatialPreview:243–245,348–400). RealityKit preserves UUID roots and updates selection-only changes, outline dimensions and aim availability (StudioEntityGraph:100–124,242–250,278–308). Powered-off fixtures retain selection cues.
- Disabled/lifecycle state remains guarded: SceneKit applies enabled/active state after every SwiftUI update, disables input/stops inertia, discards invalid identities and clears callbacks/gestures on teardown (SpatialPreview:73–162,195–245). RealityKit gates interactions on rendering, enabled state, current scene, window and VoiceOver; removes anchors when inactive/off-window; refreshes callbacks; tears down handlers (RealityStudioPreview:144–225,273–288). Disabled/detached entity hits fail ownership checks (StudioEntityGraph:127–136).
- Equipment-list fallback remains outside mode selection: named text buttons, settings, checkmark shape, selected accessibility trait and 52-point minimum rows; UUID/generation guards reject stale actions, and busy-state disabling covers rack/workspace (StudioView:109–115,506–512,912–949,1220–1225). Actual spoken output/reachability was not tested.
- No scoped new privacy surface: no network, telemetry, persistence or permission-request path found; non-AR view disables automatic session configuration (RealityStudioPreview:70–80). Adapter diff from `68c83` changes only aim-target scale (StudioEntityGraph:303).

## Limits

SpatialInteractionTests:19–105 contains relevant reuse/stale-hit/disable/teardown regressions; none ran here. Parent reports historical `68c83` CI `45817222487`: 171 passed, zero failed/skipped, all 25 spatial tests passed; root viewed two original SceneKit captures. Not independently verified here. Pinned `35283`, patch `44550b6`, and reported integration `956a3b1` remain without native execution established by this review. No device/VoiceOver pass claimed.

---

## platform_performance

# Wave 03 — platform/performance

- Canonical ID: `/root/w03_acceptance/platform_performance`
- Product: `35283bed09c609be424df80f36b42391aec19f74`
- Test patch: `44550b6837656e86f4fa7b588ac4cfe7a9b1c361` (direct child of product; one new 217-line file, three tests).
- Disposition: **approve by source; native compile/execution remains unverified.** No source-visible integration blocker found.

## Checks and findings

Read pinned AGENTS, protocol, lane plan, architecture/design; reviewed patch, existing tests, update paths, domain bounds, project/workflow/accounting. `git diff --check 35283bed… 44550b…` exited 0. No compiler, build, native execution, or product edits.

1. **Compile/API:** The patch follows `SpatialEmitterGeometryTests` imports, main-actor XCTest, transaction flush, and transform assertions. Internal preview/coordinator members exist (`SpatialPreview.swift:18–38,150,174,200,204`); constructors match `Scene.swift:29` and `StudioOptics.swift:28`. Three synchronous test methods have bounded loops and deferred teardown. No source-visible access/signature mismatch; SDK compilation remains unverified.

2. **Discovery:** `project.yml` includes all `NativeTests`. `native_test_shards.py:74–89,123–134,208–209` selects the unit target and inventories its methods; the new class conforms. Workflow `ios-prototype.yml:195–208,253–294` builds/runs that target and verifies method accounting. No class-list amendment needed.

3. **SceneKit:** Valid scenes cap lights at 12 (`Scene.swift:64`). UUID removal detaches nodes/indicators; maps are repopulated (`SpatialPreview.swift:347–367`). Shape changes replace geometry/materials (`371–400`); pose/output edits retain geometry/materials and reuse valid lights (`410–446`). Stand threshold crossings reuse the cylinder (`447–458`). Tests assert identities/counts, not allocations. Degenerate aimed frames remove the light (`426–427`), outside these tests' identity promise.

4. **RealityKit:** Shared meshes/shapes, fixed grid/outlines, and UUID removal bound retained structure (`StudioEntityGraph.swift:62–65,100–121,170–185,242–244`). Geometry/output changes still construct material values, replace arrays, and set/remove light components (`249–256,309–338`). Stable entities do **not** establish allocation-free updates or measured performance.

## Evidence boundary

Parent reports CI `45817222487` succeeded at `68c83`: 171 tests, zero failures/skips, 25 spatial. Product `35283bed…` and patch `44550b…` remain unexecuted. Exact integrated-source native evidence is still required.

---

## independentreview

# Wave 03 independent review

Canonical ID: `/root/w03_acceptance/independentreview`

Product: `35283bed09c609be424df80f36b42391aec19f74`

Test patch: `44550b6837656e86f4fa7b588ac4cfe7a9b1c361` (direct child; only `NativeTests/SpatialEntityUpdateTests.swift`, 217 added lines, three methods).

## Checks and finding

Read pinned AGENTS, OPERATING_PROTOCOL, lane-05 PLAN, DESIGN, ARCHITECTURE, both adapters, and related native tests through `git show`; inspected patch scope and XcodeGen discovery. No edits to product/tests, builds, native execution, or toolchain recreation.

**Recommend integrating the test patch; no blocking source or test defect found by inspection.** Continuing UUIDs retain the four SceneKit nodes through the cache at `SpatialPreview.swift:347–368,473–479`; fixture/outline geometry changes are restricted to initial creation, kind, or rectangle dimensions (`371–401`). Removal and invalid input clear the lamp cache (`95–104,230–235,348–354`). RealityKit similarly retains per-UUID entities and resets invalid/removed lifetimes (`StudioEntityGraph.swift:69–124,196–246`). This is source evidence, not runtime acceptance.

The new assertions are substantive: captured object references, live parents, lookup results, geometry identity, source type, dimensions, authored planes, and detach/reattach transitions would detect rebuilds or stale geometry. One-axis rectangle edits distinguish width/height invalidation. The single-light discovery helper asserts candidate counts before unwrapping (`SpatialEntityUpdateTests.swift:33–67`), so its identity checks are not vacuous. Internal APIs and scalar types appear compatible; `project.yml:35–44` includes the new file automatically. Compilation remains unverified.

## Targeted remaining gaps

- Existing removal/invalid recovery tests retain only the fixture (`SpatialInteractionTests.swift:50–85`). To prove the full lifetime guarantee, retain source, stand, and indicator too; assert old attachments/lookups are rejected and every newly created node differs after removal or invalidation. The three new tests do not extend this coverage.
- Add a valid aim → coincident aim → recovered aim transition. The new helper requires a live `SCNLight` and one emitting source, so it cannot exercise this case. Production retains the source **node** but removes/recreates its `SCNLight` component (`SpatialPreview.swift:411–428`); component identity must not be generalized from the current tests. Mixed-light membership/reordering remains covered only for fixture identity by existing tests.
- Minor internal consistency gap: hit registration compares Double height (`405`) while attachment compares Float height (`447`). A value such as `0.0500000001` can register a detached stand. `lightID` requires `parent === content` (`155–158`), so this is **not** a demonstrated stale-selection defect. Reusing one threshold decision and adding a boundary case would harden the map invariant; it does not block this patch.

Evidence disposition: tests authored and unrun. No native/runtime pass claimed; prior portable results or CI `45817222487` at source `68` do not validate these pinned revisions.
