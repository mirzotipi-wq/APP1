# Wave07 — complete retained reports

Each individual report is retained byte-for-byte at its ledger path. Reports reflect their observation times; later CI status is recorded in `ci-observations.json` and the synthesis. Relative artifact links below are adjusted only for this aggregate file’s location. No earlier queued observation has been rewritten into an execution pass.

## Retained report: acceptance

# Wave 07 — Acceptance

Worker: `/root/w07_acceptance` (`fork_turns:none`). Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Disposition:** SceneKit has successful native fallback evidence at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`. Current `4e694bc` has source review and Apple Debug compilation; its eight later methods and RealityKit correction require execution evidence.

| Evidence | Supported conclusion | Limit |
|---|---|---|
| Source | `RealityStudioPreview.surface` chooses SceneKit on x86_64 iOS simulators before constructing the RealityKit coordinator/graph. | Compile-time architecture choice; other architectures select RealityKit. |
| Native, 9725 | Run 45826141504/job 139935031405 passed 176 methods/30 spatial, Debug test-bundle and Release app builds. | The 30 mix pure viewport state and direct SceneKit tests; no delivered-gesture claim. |
| Captures, 9725 | Receipt records two original `SCNView.snapshot()` images in `UIWindow`, artifact 15123617978, hashes and prior visual review. | This worker did not independently inspect images. |
| Portable | Historical helper math and core package evidence are separately attributable. | Core CI/scalar witnesses cannot execute native renderers. |
| Current compile | Run45838950713/job139980771431: Debug build-for-testing succeeded, observed 14:58:23 UTC. | Native184-method execution queued; no current Release pass claimed. |
| Current inventory | Eight spatial files declare 38 methods: ten state and 28 SceneKit methods. Four navigation, three selection and one aim-recovery method postdate 9725. | Inventory is not execution. |
| Unestablished | RealityKit rendering, physical devices, manual VoiceOver, delivered gestures, allocation/RSS/FPS/thermal behavior and calibrated lighting. | No substitute pass. |

`SpatialPreview.updateView` refreshes callbacks before its unchanged-scene return and publishes geometry/camera changes synchronously with disabled SceneKit actions. Stable identities, stale-hit rejection, unavailable feedback and recovery have explicit source/tests. First-save `.id(generation)` reset remains lane01’s documented owner request.

Inspected pinned master/operating instructions, architecture/design/product/quality/roadmap, state/handoff, acceptance contract, lane05 geometry/owner/native/capture receipts, adapter source and spatial declarations. No wave07 production edit, source-ref update, threshold change or milestone promotion is proposed. Owner-scope differences inherited from main `9e0e2ba` are not lane05-authored. No builds, tests, host probes, new screenshots or image review occurred. Startup commands were unavailable when this wave began; later host recovery was parent-reported. The packet preserves exact inputs and ten real worker IDs.


---

## Retained report: geometry

# Wave07 geometry review

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.
Report path: `docs/parallel/05/workers/w07/geometry/report.md`.
Read-only GitHub review; no host probes, builds, tests, edits, or new captures.

## Findings

**No new geometry defect identified in the inspected source. Current native acceptance remains pending.**

- `App/SpatialPreview.swift` (`updateView`, `updateContent`, `orient`, `fitOrbit`) agrees with `Sources/LightingCore/CameraFraming.swift` and `Sources/LightingCore/StudioOptics.swift`: authored coordinates remain meters; camera/lens forward is local −Z; the fixture basis is right/up/+Z. Negating both right and normal for SceneKit spotlights preserves handedness while mapping local −Z onto the emitting normal. Rectangle width/height retain authored values, and the housing center moves behind the authored front plane. Undefined aims suppress the light without inventing a direction. The chamfered box establishes an outer envelope/front-center anchor, not exact sharp emitting-face corners.
- `App/SpatialViewportGeometry.swift` (`SpatialViewportBounds`, `SpatialOrbitState`) extends `Sources/LightingCore/StudioSceneBounds.swift` with represented bust/camera/housing/outline envelopes, world-floor stands and the 0.0275 m aim-marker radius. It covers the coincident 4 m housing that Core intentionally omits. Fit uses the enclosing radius with 48° on the smaller viewport axis and a 12% distance margin. SceneKit changes its projection axis on resize; RealityKit derives the corresponding vertical FOV. RealityKit navigation clamps do not constrain SceneKit’s separate camera-controller gestures.
- `App/StudioEntityGraph.swift` (`StudioLampEntity.update`) now scales the centered unit-box rectangle face to authored width/height, with its front at local z=0. This agrees with Core emitting-face semantics; it is source evidence only. `App/RealityStudioPreview.swift` selects `SpatialPreview` for Intel simulators before constructing RealityKit resources.

## Execution and carry-forward boundary

`docs/parallel/05/validation/NATIVE-9725fb1.md` records run 45826141504/job 139935031405 at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`: 176 native methods, including 30 spatial methods, plus Debug test-bundle and Release app builds. The inspected tests call the actual `SpatialPreview.makeView/updateView` used by the fallback and query SceneKit transforms/projections; this is stronger than pure helper arithmetic, but does not test real gesture delivery.

Pinned blob comparisons confirm unchanged `SpatialViewportGeometry`, `RealityStudioPreview`, `CameraFraming`, `StudioOptics`, `StudioSceneBounds`, and `NativeTests/SpatialEmitterGeometryTests.swift`, `SpatialPreviewTests.swift`, `SpatialInteractionTests.swift`, `SpatialViewportStateTests.swift` between those checkpoints.

**SpatialPreview is not wholly unchanged:** old blob `86c7260b3532e00b08f11dc67731ede95bd2fe3a`, current `c2dd825e406c505ded8291120bc4121f7bf35b79`. Its sole diff preserves `lastCameraMode` when validation fails, allowing the pending orbit Fit on recovery. Unchanged transform/Fit code supports limited carry-forward; the changed recovery branch does not inherit a pass. Inspected `NativeTests/SpatialNavigationRecoveryTests.swift` and `SpatialAimRecoveryTests.swift` supply new recovery assertions, with execution outside the old receipt. Current expected 184/38 counts are not established passes.

Also inspected `Sources/LightingCore/SurfacePhotometry.swift` and `Tests/LightingCoreTests/CameraFramingTests.swift`, `StudioOpticsTests.swift`, `StudioSceneBoundsTests.swift`. Native display shading remains illustrative: no numerical photometry, physical calibration, render parity, RealityKit execution, device performance, manual VoiceOver or real-gesture acceptance follows from this review.

## Input provenance

Read `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/acceptance/m02-m03-code.md`, `docs/parallel/05/GEOMETRY_COMPARISONS.md`, `OWNER_REQUESTS.md`, and the native receipt above.

| Input | Blob SHA |
|---|---|
| App/SpatialViewportGeometry.swift | 53f7aa8adffd379a0c7575bf2d4844e6a9d799a8 |
| App/RealityStudioPreview.swift | e4f763a15408c623912bbcdcd9b4296ec8418ae1 |
| App/StudioEntityGraph.swift | 35723305af3242e24c63e14196def45022d0519c |
| Sources/LightingCore/CameraFraming.swift | 7d2c50105bda390ca49cdaa75711380cc5047ae7 |
| Sources/LightingCore/StudioOptics.swift | 7e0d1cb3235b18c08e8b011f550ecc0ac3ca65e6 |
| Sources/LightingCore/StudioSceneBounds.swift | bb8b76a7edf803583470ff0dc3c54709baac1e2c |
| docs/parallel/05/validation/NATIVE-9725fb1.md | 87dea110343fb430fc79764abcb9ce2aa4c65ded |


---

## Retained report: interfaces

# Wave07 interfaces review

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Outcome: renderer boundary confirmed by source review; no new scoped defect.**

`App/RealityStudioPreview.swift`, `RealityStudioPreview.surface`, selects SceneKit `SpatialPreview` under `#if targetEnvironment(simulator) && arch(x86_64)`. This covers every x86_64 simulator runtime, independently of test flags. Supported arm64 simulators and physical iOS devices select `RealityStudioSurface`. The conditional precedes `makeCoordinator()`, whose stored properties eagerly create `StudioEntityGraph`, anchors and camera. Consequently, the fallback never reaches `StudioGeometryResources` mesh/shape generation or ARView construction through this wrapper. Its `previewNote` branch also avoids the graph reference.

RealityKit imports and implementation declarations remain outside that conditional. `project.yml` includes all `App` sources, targets iOS 17, and specifies Swift 5 language mode: Intel native builds must still type-check RealityKit implementation sources. Inclusion does not demonstrate execution. `Package.swift` targets LightingCore only (iOS 17/macOS 14); package tests exclude App. `.github/workflows/ios-prototype.yml` performs Linux syntax parsing, then Intel simulator Debug test-bundle and Release app builds; this review ran none.

`App/StudioView.swift.workspace` passes scene/selection/Fit plus generation/live-UUID callback guards. `cameraPreview` explicitly uses SceneKit on all supported architectures. The documented lane01 first-save identity request remains with its owner.

Pinned directives, architecture/design/acceptance, OWNER_REQUESTS, GEOMETRY_COMPARISONS and `docs/parallel/05/validation/NATIVE-9725fb1.md` were read. That receipt records 176 native methods/30 spatial methods at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`, with Debug test-bundle and Release app builds. Eight later tests and the RK rectangle correction require current-source evidence. RealityKit execution, delivered gestures, device performance and manual VoiceOver remain unestablished.

## Key input blobs

- `App/RealityStudioPreview.swift`: `e4f763a15408c623912bbcdcd9b4296ec8418ae1`
- `App/SpatialPreview.swift`: `c2dd825e406c505ded8291120bc4121f7bf35b79`
- `App/StudioEntityGraph.swift`: `35723305af3242e24c63e14196def45022d0519c`
- `App/StudioView.swift`: `54ad56507484decafb467921dab801e26bfaa6dd`
- `project.yml`: `056e9d4159ca0273f812728381723b60a253000f`
- `Package.swift`: `a574497006b00a96ee33d29439b1da5be8eb9363`
- `.github/workflows/ios-prototype.yml`: `55e68ee810a4dbe72cd8bd5c4aba295958f80d7c`

GitHub connector reads only; no host probes, builds, edits or children.


---

## Retained report: implementation

# Wave07 implementation review

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`. Read-only pinned-source review; no builds, probes or edits.

**Finding: no additional reproducible defect established.**

`App/SpatialPreview.swift:updateView` differs from tested 9725 only in guarding the early `lastCameraMode` assignment. Source tracing supports the existing repair: Orbit/Fit=0 → Camera (defined or unavailable) → invalid Orbit → valid Orbit/Fit=0 retains the last applied Camera mode until recovery, so `needsFit` remains true. `SpatialNavigationRecoveryTests` covers both variants, preserved user camera/target after same-mode invalid recovery, and initial empty-rig interaction.

Reviewed invariants:

- Invalid input hides content, disables interaction, clears callbacks/hit maps and detaches equipment; it consumes neither mode nor Fit. Valid recovery rebuilds equipment.
- Valid Orbit publishes its mode before deriving availability, including an empty rig. Same-mode recovery without a new Fit preserves the active camera/target. Camera mode suppresses interaction; unavailable framing clears `pointOfView`; valid framing restores the authored pose/lens.
- Identical scene/mode/selection/Fit refreshes or clears `onSelect` before the early return, preserving equipment and Orbit. Deletion/invalidity followed by the same UUID creates new nodes; `Coordinator.lightID(for:)` rejects detached old nodes. `SpatialSelectionLifetimeTests` directly exercises these boundaries, not delivered gestures.
- `updateContent` retains same-shape equipment through coincident aim, removes `source.light`, then restores its position/orientation/light on valid aim. `SpatialAimRecoveryTests` checks translated cardinal axes independently of the frame helper.

Evidence: `docs/parallel/05/validation/NATIVE-9725fb1.md` records 176 native/30 spatial passes and Debug/Release builds at 9725. The newer four navigation, three selection and one aim methods remain unexecuted in reviewed evidence. No RealityKit, device, VoiceOver, gesture-delivery or performance conclusion follows. Existing lane01 identity request remains unchanged.

Input blob SHAs:

- `App/SpatialPreview.swift`: `c2dd825e406c505ded8291120bc4121f7bf35b79` (9725: `86c7260b3532e00b08f11dc67731ede95bd2fe3a`).
- `NativeTests/SpatialNavigationRecoveryTests.swift`: `b3077e5f6c3d10e129dce4af78e71550419ed25a`.
- `NativeTests/SpatialSelectionLifetimeTests.swift`: `dcd46df3662461dc6ea3ec9a52c6a12fd1ad2635`.
- `NativeTests/SpatialAimRecoveryTests.swift`: `6fe6d784ed999ca193bea7cac1d946d2486dfa9d`.


---

## Retained report: concurrency

# Wave 07 — concurrency

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Outcome:** no new concrete lane 05 concurrency defect established. Read-only review; no edits, builds or host probes.

## Source constraints

- `App/SpatialPreview.swift`: `SpatialPreview.updateView` and `Coordinator` are main-actor isolated. Callback refresh precedes the unchanged-scene return. Updates have no suspension; the zero-duration `SCNTransaction` is not proof of arbitrary renderer-thread atomicity. Invalid scenes discard equipment/hit maps; preserving `lastCameraMode` permits pending mode recovery.
- `App/RealityStudioPreview.swift`: `RealityStudioSurface.Coordinator.update` refreshes callbacks before synchronous validation/graph publication. `App/StudioEntityGraph.swift` is also `@MainActor`; its `lightID(for:)` requires current root ownership and enabled ancestry. Neither adapter introduces tasks, queues or renderer callbacks.
- SceneKit propagates disabled/inactive state through `updateUIView`; availability and camera mode also disable interaction. Its selection delegate and handler require a callback, attached window and VoiceOver off. RealityKit's `canInteract` gates all four gesture handlers; active/window transitions remove anchors and cancel recognition. These are source constraints, not delivered-interaction results.
- UUID-set changes cancel recognition; deleted/invalid equipment loses hit ownership. Both `detach` methods remove recognizers/targets/delegates and clear callbacks. SceneKit clears scene/nodes; RealityKit removes anchors/layout/window hooks and clears current scene, retaining its graph until coordinator release.

## Executed evidence and limits

`docs/parallel/05/validation/NATIVE-9725fb1.md` records run 45826141504/job 139935031405: 176 native methods, including 30 spatial, and Debug/Release builds passed at 9725fb1.

`NativeTests/SpatialInteractionTests.swift` covers callback replacement, stale identities, invalid recovery, disable/dismantle properties and 100 **serial** updates. Callback assertions invoke closures directly; these tests establish neither concurrent scheduling nor gesture delivery. `SpatialSelectionLifetimeTests.swift` adds 3 direct callback/equipment-lifetime methods; `SpatialNavigationRecoveryTests.swift` adds 4 camera methods; `SpatialAimRecoveryTests.swift` adds 1 aim method. Those 8 methods and the later RealityKit rectangle correction require a current-source receipt (expected 184 native/38 spatial).

RealityKit execution, renderer-thread stress, physical devices, manual VoiceOver and performance remain unestablished. The lane 01 first-save `.id(generation)` integration request remains external; no adapter fix is proposed.


---

## Retained report: resources

# Wave07 — resources

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree `0f090891cb010ca03ef105fad808878b23f2eb16`. Pinned GitHub reads only; no edits or execution. **Outcome: no new concrete resource-lifecycle blocker found.**

## Retention and fresh resources

- `App/SpatialPreview.swift:updateContent` retains UUID-owned fixture/source/indicator/stand nodes. Unchanged modifier dimensions preserve geometry; ordinary valid updates reuse `SCNLight`. Kind/rectangle-size changes create geometry, an outline copy and materials. Stand geometry is created lazily and retained while detached. Undefined aim clears the light; recovery creates another `SCNLight`. Insertion, deletion/reintroduction and invalid-scene recovery create lamp resources.
- `App/StudioEntityGraph.swift` shares unit meshes/collision shapes through `StudioGeometryResources`; `StudioLampEntity.update` scales/enables retained entities. Source changes—including pose/optics/subject changes—construct material and light-component values. Temporary collections and framework work also remain outside identity assertions. This does not establish allocation-free updating.

## Ownership and teardown

Both adapters remove deleted/invalid lamp roots and hit-map entries; hit resolution verifies current parent ownership and visibility. Callbacks refresh before unchanged-scene returns. `SpatialPreview.Coordinator.detach` removes gesture targets/delegates, clears callbacks/maps/equipment/base, stops camera inertia and clears the view’s scene/camera.

`App/RealityStudioPreview.swift:Coordinator` uses weak view/layout/window captures, cancels gestures on UUID-set changes, and removes gestures, callbacks and scene anchors on detach. Its graph/resources remain coordinator-owned until coordinator release; detachment is not measured deallocation. Lane01’s first-save wrapper-identity request remains external.

## Evidence and limits

`NativeTests/SpatialEntityUpdateTests.swift` checks exact node/light/cylinder identities, intentional geometry replacement and stand hit removal. `SpatialInteractionTests.swift` checks 100 updates’ immediate-child count/live fixture identity, callback replacement and teardown. Both test files are unchanged from the executed checkpoint; current adapter source differs.

`SpatialSelectionLifetimeTests.swift` adds direct callback refresh/clear and retained-old-equipment rejection after deletion/invalidation. These three methods remain unexecuted.

`docs/parallel/05/validation/NATIVE-9725fb1.md` records source `9725fb1177a5c7afbdf798ffd627e65e604c75b1`, run45826141504/job139935031405: 176 methods/30 spatial passed, Debug test-bundle and Release app builds passed. Current 184/38 expectations and eight added methods require a new receipt.

No reviewed test measures allocations, RSS, deallocation, frame time or thermal behavior. RealityKit execution, delivered gestures, physical-device performance and manual VoiceOver remain unestablished.


---

## Retained report: interactions

# Wave07 interactions review

Source: `mirzotipi-wq/APP1@4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree `0f090891cb010ca03ef105fad808878b23f2eb16`. Read-only review; no builds, probes or edits. No new concrete lane 05 interaction failure established.

## Ownership and transitions

- `App/SpatialPreview.swift`: `allowsCameraControl` delegates navigation to SceneKit. `Coordinator.refreshSelectionGesture` makes selection wait for installed pan, pinch, rotation and multi-tap recognizers; mode toggles refresh those dependencies. This is source ordering, not demonstrated UIKit arbitration.
- `updateInteractionState` gates the view for enablement, content availability and orbit mode, stopping inertia when disabled. `gestureRecognizerShouldBegin` additionally checks callback, window and VoiceOver for the custom selection recognizer; those checks do not gate every built-in camera gesture. Window removal stops inertia; dismantling removes callback, recognizer, scene and ownership maps.
- `updateView` refreshes callbacks before its unchanged-input return. Invalid input hides content and discards equipment while retaining the last applied mode. Undefined authored camera clears point-of-view. Recovery preserves an existing orbit or fits when returning from camera mode. Live ownership/membership checks reject stale hit nodes.
- `fitOrbit` resets camera, target, projection and clipping on initial orbit, mode return or changed Fit request. Ordinary edits preserve camera/target; `OrbitAwareSceneView.layoutSubviews` changes projection axis without recentering.

## Evidence boundary

`NativeTests/SpatialInteractionTests.swift`, `NativeTests/SpatialPreviewTests.swift`, `NativeTests/SpatialNavigationRecoveryTests.swift`, `NativeTests/SpatialViewportStateTests.swift` and `NativeTests/SpatialSelectionLifetimeTests.swift` cover direct callbacks, node identities, camera-property mutations, recovery, helper math and SceneKit projections. They do not deliver UIKit gestures or establish whole-app workflows. Captures use `SCNView.snapshot()` in UIWindow.

`App/RealityStudioPreview.swift` uses `SpatialOrbitState` for its custom gestures; its gesture clamps and all-gesture window/VoiceOver gate do not apply to SceneKit’s built-in controls.

`docs/parallel/05/validation/NATIVE-9725fb1.md` records run 45826141504/job 139935031405: 176 methods/30 spatial passed plus Debug/Release builds. Current expected 184/38, eight later methods and the RK rectangle correction await native receipt. RealityKit execution, delivered gestures, manual VoiceOver and device performance remain unestablished.

Lane 01’s first-save `.id(generation)` request remains external in `docs/parallel/05/OWNER_REQUESTS.md`; no speculative fix proposed.


---

## Retained report: accessibility_privacy

# Wave07 — Accessibility and privacy

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Outcome:** No newly demonstrated lane05 defect. This was a pinned, read-only source/evidence review; no edits, builds or host probes.

## Source findings

- `App/SpatialPreview.swift:187–190,223–231,498–523`: geometry is normally AX-hidden. An unavailable message sets `accessibilityElementsHidden = false`, exposes a multiline preferred-caption label with Dynamic Type adjustment, and recovery hides both label and AX subtree. This implementation is unchanged from 9725fb1; actual announcement, reachability and large-text clipping remain unmeasured.
- `App/RealityStudioPreview.swift:70–80,154–185`: the surface uses `.nonAR` and `automaticallyConfigureSession: false`; native geometry is AX-hidden, and VoiceOver blocks custom gestures. The reviewed adapter contains no session-start, camera-permission or upload call. This establishes a source boundary, not observed camera/network privacy.
- `App/StudioView.swift:506–512,554–565,722–738,926–948,1220–1225`: spatial/list selection checks generation and live UUID membership; list rows provide a checkmark, selected trait and 52-point minimum height. Fit has a label, 44-point minimum height and reset explanation. Camera fallback instructs moving away from the subject. The existing first-save `.id(generation)` request remains lane01-owned in `OWNER_REQUESTS.md`.

## Executed assertions and limits

`validation/NATIVE-9725fb1.md` and `validation/native-9725fb1.log` record run45826141504/job139935031405: 176 native passes, including 30 spatial, plus successful Debug test-bundle and Release app builds.

- `SpatialInteractionTests.testUndefinedCameraHidesPriorViewAndRecoversAuthoredLens`: nil viewpoint/hidden content, then restored camera, visibility, FOV and forward direction.
- `SpatialInteractionTests.testRemovedAndReintroducedUUIDCannotReuseOldHitObject`: old hit rejected after deletion/reintroduction; replacement resolves the UUID.
- `SpatialPreviewTests.testOrdinarySceneEditPreservesOrbitButExplicitFitRestoresCamera`: ordinary edits preserve orbit; explicit Fit restores camera and bounds target.

These `NativeTests/` files are unchanged; `SpatialPreview.swift` changed, so results remain historical. None of the eight spatial test files asserts unavailable-label AX visibility or Dynamic Type layout.

Current 184/38 execution remains pending. The app accessibility workflow failed at `UITests/StudioAppAccessibilityUITests.swift:263`, waiting for `librarySaveCurrent`; native fallback passes do not satisfy that workflow. RealityKit execution, manual VoiceOver, delivered gestures, device/privacy observation and performance are unestablished.


---

## Retained report: platform_performance

# Wave07 — platform and performance

**Disposition:** retained native execution passes at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`; current `4e694bc377c4825d1d2dd52fcd7900e534c75072` has verified Apple compilation, with native execution pending.

## Executed evidence

Independent parsing of [the preserved log](../../validation/native-9725fb1.log), blob `c75a9a6aceb854eee77fd0c9b5ffa242ce2fd250`, finds 542 XCTest passes: 366 macOS package methods and **176 native methods**, each native method starting/passing exactly once. Native failures, skips, duplicates and omissions: zero.

| Spatial class | Passes |
|---|---:|
| SpatialEmitterGeometryTests | 5 |
| SpatialEntityUpdateTests | 3 |
| SpatialInteractionTests | 9 |
| SpatialPreviewTests | 3 |
| SpatialViewportStateTests | 10 |
| **Total** | **30** |

Actual environment: Intel x86_64 macOS 26.6.1/25G76; Xcode 26.6/17F113; Apple Swift 6.3.3; XcodeGen 2.46.0; iPhone 17 Pro simulator, iOS 26.5. Debug test-bundle and Release app builds succeeded. The log records `** TEST EXECUTE SUCCEEDED **`, “Required Metal methods executed and passed; no native methods skipped.” and exact 176-method accounting. Dedicated job steps confirm finalized XCTest export succeeded.

The 100-update node-count/identity regression passed; this measures neither allocations nor frame rate. Two SceneKit attachment names and the archive digest match [the retained capture receipt](../../captures/receipt-9725fb1.json). This reviewer checked provenance, not the PNGs visually.

## Current source boundary

At **2026-11-26 14:58:23 UTC**, run 45838950713 core job 139978271046 succeeded; native job 139980771221 remained queued. Dedicated steps for studio-optics job 139980771431 independently show **Build native UI test bundle: completed/success**; selected UI execution remained in progress.

Pinned project/workflow inspection establishes Debug `KeyAndFill`, `CODE_SIGNING_ALLOWED=NO`, unfiltered `build-for-testing`, with app, native and UI test targets. Independent source inventory is **184 native/38 spatial**: eight additions, zero removed prior methods. Compilation does not execute those additions. Retain their pending status and the RealityKit rendering boundary. No FPS, allocation, physical-device, gesture-delivery or VoiceOver result follows from this evidence.


---

## Retained report: independent_review

# Wave07 — Independent review

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

Reviewed all nine complete peer reports, including the platform evidence object, pinned directives/contracts, owner requests, geometry comparisons and native receipt; spot-checked adapter sources and all eight new test declarations. No edits, builds, tests, host probes or image inspection.

**Disposition: support bounded wave07 documentation integration. Current native acceptance remains pending; no additional reproducible lane05 defect established.**

| Evidence | Defensible conclusion |
|---|---|
| [9725 receipt](../../validation/NATIVE-9725fb1.md) and platform log accounting | 176 native/30 spatial passes, Debug test-bundle and Release app builds; zero missing, duplicate, failed or skipped native methods. |
| Current source | 184 native/38 spatial is inventory. Four navigation, three selection and one aim-recovery methods need execution. |
| Independent check, 2026-11-26 15:07:05 UTC | Run 45838950713/job 139980771431: UI bundle build succeeded; UI execution continued. Native job 139980771221 was in macOS package preparation; native build/test/accounting remained pending. No current Release pass established. |

The complete old/current `SpatialPreview.swift` comparison confirms only the guarded `lastCameraMode` assignment/comment changed. Unchanged geometry code permits scoped historical carry-forward; recovery cannot inherit that pass. The RealityKit rectangle face uses authored dimensions in source; compilation does not establish rendering.

SceneKit built-in camera controls are separate from RealityKit's helper navigation/clamps. SceneKit's custom selection gate does not establish VoiceOver/window gating for every built-in gesture. Direct callbacks, property mutations and projections establish no delivered gestures. Portable math and simulator Study Metal results establish no RealityKit execution. Retained snapshots have actual SceneKit provenance; this reviewer did not inspect PNGs. The 100 serial updates establish node identity/count, without allocation, RSS, FPS or thermal measurements.

Preserve historical 9725 accessibility failure at line 263 and cancelled room/export outcomes separately. Manual VoiceOver and physical-device results remain unestablished.

Lane01 owns first-save identity repair. Root-provided verification finds all 230 outside-lane changed paths match main `9e0e2ba` blobs, including inherited CGFloat, README and agents/evidence changes. Equality with campaign `f150` is not claimed. Root owns scope records. Restrict wave07 writes to its documentation subtree; retain M03 active without milestone promotion.
