# Wave09 — complete retained reports

Frozen source `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`. Ten actual contexts; complete reports follow verbatim. Individual file hashes and canonical agent IDs are recorded in `ledger.json`. Earlier CI cutoffs in reports are preserved; later parent observations are recorded separately.

# Wave09 acceptance — lifecycle invariant review

Frozen source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`. Reviewed `SpatialPreview`, `RealityStudioPreview`, `StudioEntityGraph`, focused interaction/selection/navigation regressions, architecture/design, and the M02/M03 code contract. This is source acceptance review, with no local compilation or test execution.

The accompanying lifecycle matrix records valid, invalid, disabled, inactive, off-window, dismantled and recreated states, plus undefined authored-camera recovery. Both adapters refresh callbacks before geometry equality can suppress work. Continuing UUIDs retain equipment; deletion and invalid input remove current ownership so externally retained old hit objects cannot select a later replacement with the same UUID. Stable orbit recovery differs deliberately from a pending camera-to-orbit transition: SceneKit preserves the former and performs Fit for the latter.

SceneKit disables view interaction and stops inertia for disabled/inactive state; off-window handling stops inertia/playback while selection independently requires a window. RealityKit removes its graph/camera anchors when inactive or off-window, retains graph/orbit ownership in its coordinator, and cancels its recognizers. Detach clears callbacks and view bridges; SceneKit also empties its content graph. RealityKit graph objects can remain alive while their coordinator is externally retained; source does not establish deallocation or a leak.

The focused tests directly construct SceneKit views and exercise updates, ownership, callback publication, projections and teardown. They do not host the SwiftUI environment lifecycle or deliver user gestures. Recreation follows caller identity. Current lane01 owner head `5ccfbaae821a32d88c12ed8b3abf1600aef25753` implements `workspaceResetID` and preserves generation/live-UUID guards, while frozen lane05 retains `.id(generation)`. The remaining request is integration plus hosted first-save retention and intentional project-switch reset verification.

No new reproducible lane05 defect was established by this bounded review; no source edit or extra test is proposed. Historical source4e694bc passed184 native/38 spatial methods. Current60059 adds a helper change and regression, inventory185/39; its native execution is pending at this report's review cutoff. The root's later receipt must remain separately revision-qualified. RealityKit execution, device behavior, manual VoiceOver, delivered gestures, frame rate, resident memory and thermal measurements remain unverified. No milestone or release promotion follows from this review.


---

# Wave09 geometry review

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree: `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`.

**Finding: no new concrete stale-transform or lifecycle defect identified in this bounded inspection.** No production changes proposed.

Read the four requested adapter files, `AGENTS.md`, architecture/design/acceptance contracts, geometry comparisons, owner requests, prior geometry reports, and the 4e694bc native receipt. Inspected focused assertions in `SpatialEntityUpdateTests`, `SpatialAimRecoveryTests`, `SpatialSelectionLifetimeTests`, `SpatialInteractionTests`, `SpatialNavigationRecoveryTests`, and `SpatialViewportStateTests`. All source/document reads used the frozen Git revision.

## Supported findings

- Continuing SceneKit UUIDs retain fixture/source/stand nodes. Kind or rectangle dimensions rebuild shapes; position, optics, output and subject changes refresh transforms. Pose resets precede housing offsets, preventing accumulated translation. Stand threshold crossings detach/reuse the cylinder. Coincident aim removes emission; recovery recomputes orientation and source pose (`SpatialPreview.swift:349–461`).
- RealityKit geometry invalidation includes position, complete optics and subject; source invalidation additionally includes output/color/shading eligibility. Shape, stand, outline and aim state refresh together. Degenerate or Float-collapsed aim segments disable both markers. Rectangle faces retain authored extents (`StudioEntityGraph.swift:249–345`).
- Invalid scenes and UUID removal discard owned lamps/hit maps; reinsertion creates fresh equipment. Parent/visibility ownership checks reject retained old hits. Unchanged-scene callbacks refresh before early returns. The applied camera-mode cache survives invalid input, preserving recovery Fit semantics.
- RealityKit background/offwindow transitions detach anchors while retaining current geometry/orbit; scene updates still refresh the graph, and reactivation reattaches it. Dismantling removes view callbacks, gesture targets and anchors. SceneKit teardown clears graph/camera ownership and caches. No stale geometry transfer was found at renderer recreation. These lifecycle conclusions are source inspection.

## Evidence limits

The 4e694bc receipt records 184/184 native passes, including 38 spatial (28 direct SceneKit, 10 helpers), plus Debug/Release builds. Current 60059 has an additional outward-Float-FOV regression: 185/39 is inventory, not an inherited pass. No tests/builds/probes were run here. Current native completion, RealityKit execution, background/reactivation gesture delivery, physical-device behavior, manual VoiceOver, FPS/RSS/thermal remain unverified; node counts establish no runtime performance result.


---

# Wave09 interfaces review

**Pins.** Lane05 source `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`; campaign baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. Required directives, architecture/design, acceptance, owner requests and native evidence read.

**Lifecycle.** `App/KeyAndFillApp.swift:14–18` hosts StudioView; its 3D caller is `StudioView.swift:482–513`, authored camera `722–739`. `SpatialPreview.swift:168–272` and `RealityStudioPreview.swift:68–94,189–226` refresh callbacks even with unchanged geometry and dismantle recognizers, callbacks and scene attachments. Invalid scenes discard equipment; removed/detached objects fail ownership checks (`StudioEntityGraph.swift:69–136`). The x86_64 simulator fallback precedes RealityKit construction. No new adapter defect found.

**Concrete frozen-source reproducer, unexecuted.** Unsaved draft → 3D → orbit/pan/zoom → first Save. `ProjectLibraryOperation.swift:115–133` changes generation while `resetsPresentation=false`; caller `.id(generation)` predicts coordinator recreation and initial Fit. Adapter update retention cannot survive caller destruction.

**Current owner checkpoint.** At 2026-11-26 16:01:06 UTC, read-only GitHub ref resolved `finish/01-architecture-composition` to `5ccfbaae821a32d88c12ed8b3abf1600aef25753`, superseding inspected `966c9c21adbb685d82127e7f88981b74daf47e3d`. Pinned `App/StudioView.swift:438–443` uses `.id(session.workspaceResetID)` while preserving captured-generation/live-UUID guards. `StudioSession.swift:331–334` rotates that identity only for presentation resets. `NativeTests/StudioSessionTests.swift:132–157,344–369` asserts first-save identity retention and project-switch reset at session level. Owner HANDOFF explicitly leaves native viewport retention unverified. Exact receipt, blobs and excerpts: `owner-checkpoint.json`.

**Owner request.** Lane01/lane20: integrate the pinned correction and verify hosted first-save camera/target retention, intentional switch/reload reset with overlapping UUIDs, and rejection of old-generation callbacks. Frozen `60059a0` remains unfixed. No owner edits made.

**Evidence limits.** Source `4e694bc` run 45838950713/job 139980771221 passed 184 native/38 spatial methods (28 direct SceneKit, 10 helper), plus Debug and Release builds; this is not a current-source pass. Source `60059a0` inventory is 185/39; dispatch evidence recorded 366 Debug/366 Release/100 tooling checks passed, native job 140022794410 queued. This reviewer did not poll native execution. RealityKit runtime, delivered gestures, device/manual VoiceOver/FPS/RSS/thermal remain unverified. No builds, toolchains, tests, source edits or ref updates performed.



---

# Wave09 implementation review

Pinned source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree: `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`; baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.

**Finding: no concrete reproducible adapter defect established.** Read-only review; no source edits, tests, builds, toolchain installation or ref changes.

Inspected `App/SpatialPreview.swift`, `RealityStudioPreview.swift`, `StudioEntityGraph.swift`; native `SpatialSelectionLifetimeTests`, `SpatialInteractionTests`, `SpatialNavigationRecoveryTests`, `SpatialEntityUpdateTests` and `SpatialPreviewTests`; startup/architecture/design/acceptance documents; lane05 wave05/wave07 implementation reports, native checkpoint and exact log.

SceneKit replaces or clears `onSelect` before its unchanged-scene early return. The identical-scene regression directly invokes callbacks A/B/nil while checking equipment and orbit preservation. Invalid input hides content, disables interaction, clears callbacks/maps and detaches fixture/source/stand roots. Retained indicators may remain beneath detached fixtures. Deletion/reinsertion and invalid/recovery tests require fresh equipment identities and reject every retained stale hit.

Normal reconstruction uses a fresh `makeCoordinator`. SceneKit teardown removes gesture targets/delegates, stops inertia, clears scene/point-of-view/callbacks/caches and detaches content/camera. Manually attaching the already-dismantled coordinator is unsupported reuse, not a demonstrated reopen defect. The dismantling regression verifies cleared ownership and hit rejection; its retained nodes cannot establish deallocation. No dedicated full SwiftUI reopen test was found.

RealityKit refreshes its nonoptional callback every update. Invalid input leaves that latest closure stored but sets `currentScene` nil, blocks dispatch, and disables the graph/removes lamps. Inactive/offwindow transitions remove graph/camera anchors while retaining orbit and geometry for reattachment. Disable gates gestures without requiring graph destruction. Teardown clears view closures, gesture targets/delegates and selection callback and removes anchors; graph resources remain coordinator-owned until release. Anchor removal is not evidence of deallocation.

MainActor update ordering has no suspension between state changes. SceneKit applies environment gating after geometry; RealityKit applies enable/activity before scene update. Selection additionally checks window presence. These environment/offwindow paths were source-traced, not delivered-gesture tested.

Evidence: source `4e694bc`, run 45838950713/job 139980771221 passed 184/184 native, including 38 spatial (28 SceneKit/10 helpers), plus Debug/Release builds. Reviewed lifecycle bodies are unchanged; 60059 changes the FOV helper and adds one regression. 185/39 is inventory, not a reviewed 60059 native pass. RealityKit runtime, reopen/deallocation, device, VoiceOver, FPS/RSS/thermal remain unverified.



---

# Wave 09 — concurrency

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree: `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`. Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.

**Result:** No new reproducible adapter concurrency defect established. Review only; no source edits, builds, tests, toolchain work or ref changes.

Inspected `App/SpatialPreview.swift`, `RealityStudioPreview.swift`, `StudioEntityGraph.swift`, the frozen `StudioView.swift` caller, and `NativeTests/SpatialInteractionTests.swift`, `SpatialSelectionLifetimeTests.swift`, `SpatialNavigationRecoveryTests.swift`, `SpatialEntityUpdateTests.swift`, `SpatialAimRecoveryTests.swift`. Read AGENTS, architecture/design, M02/M03 contract, lane05 wave06/07 concurrency reports and `validation/NATIVE-4e694bc.md`.

- SceneKit refreshes `onSelect` before its unchanged-scene return; RealityKit refreshes it before validation and graph update. Unchanged geometry cannot retain the previous supplied callback.
- Invalid scenes discard equipment ownership; deletion/reinsertion replaces removed roots. Lookup requires current hierarchy ownership. UUID-set transitions cancel recognition. Recovery clears invalid caches, while SceneKit preserves the previously applied camera mode so pending mode/Fit changes survive.
- Disabled/inactive state reaches interaction gating even when geometry is unchanged. SceneKit's selection handler requires an attached window; window removal stops inertia/playback, without an explicit selection-recognizer toggle. RealityKit window/inactive transitions remove anchors and cancel recognizers. Both detach paths remove targets/delegates and clear callbacks; RealityKit retains its graph until coordinator release.
- Inspected updates are synchronous main-actor calls with no suspension or asynchronous callback dispatch. This establishes source ordering, not renderer-thread atomicity. A zero-duration SceneKit transaction does not prove arbitrary renderer concurrency safety.

Regression assertions cover serial updates, direct callback replacement/clearing, retained hit rejection and invalid/mode/aim recovery. They do not deliver recognizer events; the 100-update loop is serial, and node counts are not runtime-performance measurements.

Historical source `4e694bc`, run 45838950713/job 139980771221: 184/184 native, 38 spatial (28 direct SceneKit + 10 helpers), Debug/Release builds passed. The current angle-helper change adds one regression: 185/39 is inventory only here; current native execution remains root-tracked.

Known first-save `.id(generation)` remains in frozen composition. Lead-reported lane01 `.id(session.workspaceResetID)` plus generation/live-UUID guards is unmerged; native retention remains unverified. RealityKit runtime, renderer stress, delivered gestures, physical devices, manual VoiceOver, FPS/RSS/thermal remain unverified.



---

# Wave09 lane05 — resources

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`. Pinned source/docs review only; no edits, builds, tests or CI polling. **Result: no new concrete resource-lifecycle defect.**

## Bounded topology

Let N ≤ 12 validated UUIDs (`Sources/LightingCore/Scene.swift:validated`) and S ≤ N stands above 0.05 m. After a valid update:

| Adapter | Coordinator-owned nodes/entities | Attached to live scene |
|---|---:|---:|
| SceneKit | 8 + 4N, maximum 56 | 8 + 3N + S |
| RealityKit | 55 + 24N, maximum 343 | Same while active/on-window; zero adapter anchors while inactive/off-window |

Owned counts cover explicit source-created nodes/entities, including disabled objects and retained detached stands. They exclude framework scene roots/internals, UIKit, meshes, materials, light components and externally retained test witnesses.

`App/SpatialPreview.swift:updateContent`: base eight = content/camera plus floor/head/torso/ambient/camera-body/lens; each lamp owns fixture/source/indicator/stand. `App/StudioEntityGraph.swift`: graph base 53 = anchor, floor, subject/camera roots, six body models, fill and 42 grid lines; each lamp owns 24 entities. `App/RealityStudioPreview.swift:Coordinator` adds camera anchor/camera.

## Transitions and ownership

Insertion adds one lamp hierarchy; deletion/invalidation clears lamp ownership and hit maps; recovery recreates lamps, even for returning UUIDs. SceneKit invalidation retains eight base nodes (two before first valid update); RealityKit retains 55 entities with graph disabled. Undefined authored camera framing instead hides SceneKit content without discarding lamps.

Continuing UUIDs retain nodes; lowered SceneKit stands detach while remaining owned. Shape/material/light replacement is intentional: SceneKit changes shape for kind/rectangle dimensions, and clears/recreates SCNLight across undefined aim; RealityKit replaces source materials/components while reusing entities/shared meshes.

Background SceneKit disables interaction/stops inertia; off-window additionally stops playback, retaining topology. RealityKit removes both anchors but retains graph/resources. SceneKit teardown clears graph children/maps/callbacks and view scene/POV, retaining coordinator content/camera nodes (camera still owns SCNCamera). RealityKit teardown removes anchors/gestures/callbacks; graph ownership remains until coordinator release. Neither proves deallocation.

## Evidence and limits

`NativeTests/SpatialEntityUpdateTests.swift` asserts retained identities and intentional replacements; `SpatialSelectionLifetimeTests.swift` asserts deletion/invalid-recovery rejection using deliberately retained old nodes; `SpatialInteractionTests.swift` checks 100 updates’ immediate-child count and teardown state; `SpatialAimRecoveryTests.swift` checks retained nodes with nil→spot recovery.

`docs/parallel/05/validation/NATIVE-4e694bc.md`: source4e694bc, run45838950713/job139980771221 passed 184 native/38 spatial (28 direct SceneKit + 10 helpers), Debug/Release builds. Current185/39 is inventory only. No allocation, deallocation, RSS/FPS/thermal claim; RealityKit runtime, delivered gestures, device behavior and manual VoiceOver remain unverified.



---

# Wave09 interactions review

Source `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`, tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`; campaign baseline `f150f98`. Pinned source/document review only: no builds, tests, probes or source changes. **No new concrete lane 05 defect established.**

## Transition semantics

- **SceneKit:** `SpatialPreview.Coordinator.refreshSelectionGesture` makes selection wait for installed pan/pinch/rotation/multitap recognizers. Navigation remains SceneKit-owned. UUID changes cancel the custom selection tap; invalidity also discards equipment. Enablement/content/mode gates disable view interaction and stop inertia. Window removal stops inertia; the custom tap additionally requires a window, callback and VoiceOver-off state. These are not equivalent to app-owned cancellation of every native camera recognizer.
- **RealityKit:** `RealityStudioSurface.Coordinator` owns orbit/pan/pinch/tap. Changed UUID sets, invalidity, inactivity and window loss disable/cancel all recognizers. Tap waits for navigation; only pan/pinch can recognize simultaneously. The delegate prioritizes viewport navigation over an ancestor scroll pan. These dependency declarations do not prove delivered UIKit arbitration.
- **Continuity:** same-UUID shape edits retain live roots. Both adapters refresh callbacks; hit resolution checks current ownership, while the caller checks generation and live UUID membership (`StudioView.workspace`). Invalid SceneKit recovery preserves an existing orbit or applies a pending mode/Fit transition. Fit resets navigation state; SceneKit also stops inertia. Neither Fit path explicitly cancels ongoing navigation. Resize changes projection without recentering. Actual continued input across those transitions remains unverified. `SpatialOrbitState` bounds apply to RealityKit navigation and SceneKit Fit, not SceneKit’s built-in gestures.

## Evidence and ownership

`SpatialInteractionTests`, `SpatialSelectionLifetimeTests`, `SpatialEntityUpdateTests`, `SpatialNavigationRecoveryTests`, `SpatialPreviewTests` and `SpatialViewportStateTests` assert direct callback invocation, ownership/shape transitions, manually assigned camera properties, recovery and projection/helper math. They do not deliver orbit/pan/pinch/tap sequences through deletion, Fit, background or resize.

`validation/NATIVE-4e694bc.md` records 184/184 native passes, including 38 spatial (28 direct SceneKit, 10 helpers), and Debug/Release builds at **4e694bc**. Current **185/39 is inventory**, with current native execution pending per lead; no current pass inferred. RealityKit runtime, device/manual VoiceOver and performance remain unverified.

Frozen `.id(generation)` retains the known first-save composition issue. The lead reports owner `5ccfbaae` now uses `workspaceResetID` with separate guards; integration/native verification remains pending. No duplicate adapter repair proposed.


---

# Wave09 — Accessibility and privacy

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.

**Outcome:** No new reproducible lane05 defect. Bounded, pinned source/evidence review only; no source edits, tests, builds, device observation or CI polling.

## Source findings

- **SceneKit:** `App/SpatialPreview.swift:73–88,136–162,195–240,490–495` disables input for disabled/inactive/unavailable/camera-mode states. Custom selection checks callback presence, window attachment and VoiceOver both before recognition and on delivery; hit resolution rejects hidden, removed or stale identities. Off-window handling stops inertia/playback. These custom-selection checks do not establish equivalent VoiceOver gating for SceneKit’s retained native camera gestures.
- **RealityKit:** `App/RealityStudioPreview.swift:70–89,144–225,247–288` uses `.nonAR` with automatic session configuration disabled. Inactive/off-window transitions remove anchors and disable gestures. Every custom handler rechecks rendering, enabled state, valid-scene presence, window and VoiceOver. Callback refresh and teardown are explicit; `StudioEntityGraph.swift:69–136` rejects disabled/detached identities.
- **Accessible alternatives/status:** `SpatialPreview.swift:187–190,223–231,498–523` normally hides geometry from accessibility, exposes a multiline Dynamic Type unavailable label, then hides it on recovery. RealityKit supplies a separate unavailable note. `StudioView.swift:506–512,554–565,722–738,926–948,1220–1225` supplies generation/live-UUID guarded list selection, a checkmark/selected trait, 52-point rows, 44-point Fit, and camera recovery guidance. These source declarations do not prove delivered reading order or action reachability.
- **Privacy boundary:** The two adapters and graph contain no app-authored network/upload, permission-request or AR-session-start calls. This is a surface source finding, not observed no-network/camera behavior or a whole-app privacy audit.

## Evidence limits

`docs/parallel/05/validation/NATIVE-4e694bc.md` records run45838950713/job139980771221: 184/184 native, including 38 spatial (28 direct SceneKit plus 10 helpers), and Debug/Release builds. Reviewed adapters, graph, callers and selection/interaction tests are unchanged since that receipt; the current helper/regression successor has 185/39 inventory and no current native pass. Root tracks pending execution.

Earlier audit/UI failures and cancellations remain unchanged. RealityKit runtime, manual VoiceOver, delivered gestures, accessibility layout/contrast, device privacy, FPS/RSS/thermal remain unverified. No additional coverage-only tests proposed. Planning targets are not measured token telemetry.


---

# Wave09 — platform/performance

**Scope:** frozen `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; pinned source, acceptance contract, native log and capture receipt only. **Finding:** no additional reproducible defect identified; no edit proposed.

**Execution versus inventory.** Re-accounting `docs/parallel/05/validation/native-4e694bc.log` reproduced its recorded SHA256 `b538e299ef327f66ae9307d1f8c590bc178ff5782fafd6b04e801668961281ed`: 184 historical methods each have one ordered start/pass, without missing, unexpected, failed, skipped or duplicate methods. Run 45838950713 / job 139980771221 used x86_64 iPhone 17 Pro / iOS 26.5 / Xcode 26.6; Debug native execution, Debug test-bundle build and unsigned Release simulator build succeeded. Its 38 spatial methods comprise 28 direct SceneKit tests and 10 Swift state/helpers.

Current inventory is 185 native/39 spatial: 28 SceneKit plus 11 helpers. The only subsequent App/native delta is outward Float FOV rounding in `App/SpatialViewportGeometry.swift` and its added `SpatialViewportStateTests` regression. Historical execution does not establish that regression or current-source execution.

**What assertions establish.** `SpatialInteractionTests`, `SpatialSelectionLifetimeTests`, `SpatialNavigationRecoveryTests` and `SpatialAimRecoveryTests` exercise teardown cleanup, disabled interaction, stale hit rejection, deletion/invalid-scene replacement, callback refresh/clearing, retained orbit, undefined-camera recovery and translated emitter recovery. `SpatialPreviewTests` and narrow-projection assertions query actual SceneKit projection. Callback tests invoke closures directly; 100 repeated updates establish bounded attached-node count and retained identity, without measuring allocations, leaks or frame timing.

The original images in `docs/parallel/05/captures/receipt-4e694bc.json` came from SCNView snapshots inside UIWindow during XCTest. They establish captured SceneKit output, not delivered app gestures. The Intel fallback bypasses RealityKit construction; renderer compilation does not establish RealityKit lifecycle, hit-testing or rendering.

**Remaining evidence.** Root reported current core 366 Debug / 366 Release / 100 tooling passes; native job 140022794410 had reached Generate project at 16:10:46 UTC, without a 185-pass receipt reviewed here. Historical optics/room/export UI passed; library/accessibility/visual were cancelled by the successor. RealityKit runtime, physical-device interaction, manual VoiceOver, FPS/RSS/thermal measurements remain unverified. The code-only contract removes external milestone prerequisites without converting these gaps into passes. Worker telemetry targets are unmeasured.


---

# Wave09 — final independent review

Frozen source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`.

**Disposition: no new concrete adapter defect; no production edit proposed.** I actually read all nine other complete reports: acceptance, geometry, interfaces, implementation, concurrency, resources, interactions, accessibility/privacy and platform/performance. I also read the required directives/contracts, pinned adapter/caller/test evidence, historical receipt, lifecycle matrix, owner checkpoint, synthesis, source-inputs, CI observations and resource provenance.

**Evidence corrections verified.** The lead amended synthesis/matrix after my challenge. `StudioEntityGraph.lightID` establishes current hierarchy ownership; retained RealityKit hits may still resolve after anchor detachment or coordinator dismantling. Delivery is separately blocked by rendering/enabled/current-scene/window/VoiceOver guards and callback teardown (`RealityStudioPreview.swift`). SceneKit selection also rechecks callback/window/VoiceOver; equivalent gating of framework camera gestures is unproven. Callback refresh precedes equality exits; deletion/invalidation rejects stale ownership.

SceneKit teardown clears attachments/maps while retaining coordinator content/camera nodes; RealityKit retains its graph. Neither establishes deallocation. Normal recreation constructs a fresh coordinator; manually reusing a dismantled coordinator is unsupported. For N ≤ 12 validated lights and S stands above 0.05 m, owned topology is `8 + 4N` SceneKit nodes and `55 + 24N` RealityKit entities, maximum 56/343. SceneKit attachment is `8 + 3N + S`; RealityKit attaches its full topology only while active/windowed. Counts include disabled objects/detached stands but exclude framework internals, meshes/materials and external test witnesses; they measure neither allocations nor performance.

Frozen `.id(generation)` still predicts first-save recreation. Owner `5ccfbaae` implements `workspaceResetID` plus generation/live-UUID guards; its session assertions do not establish hosted camera retention. Integration and native first-save/switch verification remain owner work.

Historical `4e694bc`, run 45838950713/job 139980771221 passed 184 native/38 spatial (28 SceneKit/10 helpers), plus Debug/Release builds. Current 60059 inventory 185/39 includes 11 helpers, without a transferred pass. Parent run 45851365897 core passed 366 Debug/366 Release/100 tooling; native 140022794410 still had a Release build in progress at 16:19:22 UTC, without a reviewed 185-pass receipt.

Direct callback/property tests and serial updates do not establish delivered gestures or renderer-thread atomicity. RealityKit runtime, hosted lifecycle, device/manual VoiceOver, FPS/RSS/thermal remain unverified. No tests, builds, toolchains, source/ref changes or CI polling performed. Token targets remain unmeasured; no milestone/release promotion.

