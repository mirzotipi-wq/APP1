# Wave10 accessibility/privacy evidence

## Scope and execution

All production reads use `git show 60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a:<path>` from `/tmp/keyfill05-be879deb/repo`. Architecture, design, acceptance, AGENTS, lane handoff and prior native receipt use documentation parent `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`. Root explicitly supplied the later working capture/accounting files listed below; they are not claimed to exist at that documentation parent. No integration-checkout write, ref update, test, build, install, native execution, live CI request or optional source change occurred. Read-only Python computed SHA256 and literal-token scans; view_image displayed the original full-app PNG.

## Source versus behavior

| Surface | Source anchors | Supported conclusion and limit |
|---|---|---|
| SceneKit enabled/active | App/SpatialPreview.swift 73–88, 195–198 | SwiftUI forwards isEnabled AND active scene phase; availability and orbit mode also gate interaction, and disabling stops inertia. This is source inspection, not lifecycle-event delivery. |
| SceneKit tap selection | App/SpatialPreview.swift 136–162 | Callback, window, VoiceOver, availability and mode guard recognition and are rechecked during ended delivery. Hit resolution checks live ancestry, visibility and scene membership. These are custom tap gates. |
| SceneKit built-in navigation | App/SpatialPreview.swift 59–66, 184 | Native camera gestures are retained and selection waits for them. The custom tap VoiceOver predicate is not a guard for the built-in camera controller; its manual assistive-tech behavior remains unverified. |
| SceneKit detach | App/SpatialPreview.swift 106–133, 490–495 | Removes selection delegate/target/recognizer, clears callback and maps, removes scene and POV, stops inertia/playback. Off-window transition stops inertia/playback. This proves source cleanup, not ARC or GPU resource reclamation. |
| RealityKit active/disabled | App/RealityStudioPreview.swift 85–89, 144–187 | Active/window state governs hidden state and anchor attachment; interaction also requires enabled/valid-scene state. |
| RealityKit custom gestures | App/RealityStudioPreview.swift 154–162, 247–288 | canInteract includes isRendering, enabled, currentScene, window and no VoiceOver. Orbit, pan, zoom and tap each recheck it. No RealityKit runtime was executed here. |
| RealityKit identity | App/StudioEntityGraph.swift 69–136; App/RealityStudioPreview.swift 189–225, 273–278 | Invalid/deleted nodes lose ownership, disabled ancestry is rejected, current-scene membership precedes callback; teardown disconnects callback and view. A still-alive graph can retain objects; no deallocation claim. |
| NonAR | App/RealityStudioPreview.swift 70–80 | ARView is constructed with cameraMode .nonAR and automaticallyConfigureSession false. This constructor and a limited lexical scan are not observed no-camera/no-network behavior or a whole-app privacy audit. |
| Accessible alternative | App/SpatialPreview.swift 187–190; App/RealityStudioPreview.swift 78–80; App/StudioView.swift 926–948, 1220–1225 | Native geometry is normally hidden from the accessibility tree. Parent equipment-list buttons use a captured generation guard plus current UUID membership, selected traits and visible checkmarks, with 52-point minimum rows. |
| Parent disabled state | App/StudioView.swift 109–115 | Workspace, rack and inspector are disabled during busy library operations. Generation guards address older queued actions; these declarations do not prove delivered VoiceOver behavior. |
| Dynamic Type limits | App/SpatialPreview.swift 498–523; App/StudioView.swift 515–520, 554–565, 657–719; App/RealityStudioPreview.swift 15–25 | Unavailable UILabel uses unlimited lines and preferred dynamic font; mode choices become vertical at accessibility sizes; Fit declares minimum height 44. The visual viewport remains 280 points, and no reviewed evidence demonstrates maximum-type overlay/Fit reachability or reading order. No newly demonstrated clipping defect is inferred from declarations alone. |
| Existing AXXXL test scope | UITests/StudioAppAccessibilityUITests.swift 29–45, 103–127 | Declares default and AXXXL essential workflows, checks all mode controls with Plan selected, then changes Plan/list light selection. It does not switch to 3D and exercise Fit in that maximum-type workflow. Source existence is not a current passing execution. |

## Direct native boundaries

`NativeTests/SpatialInteractionTests.swift:8–16` builds an SCNView directly without UIWindow or callback; `testDisablingAndDismantlingRejectsSelectionAndReleasesGeometry` (88–104) asserts interaction false then true and detached state. Its negative delegate result has independently false callback/window predicates, so it cannot establish isolated disabled, window or VoiceOver gating. `NativeTests/SpatialSelectionLifetimeTests.swift:77–117` explicitly invokes callback closures; that tests callback publication/removal and retained nodes/camera, not actual gesture delivery.

The pinned `docs/parallel/05/validation/NATIVE-4e694bc.md` records the prior source's 184 native / 38 spatial passes on x86_64 iPhone17Pro/iOS26.5, with 28 direct SceneKit tests and 10 state/helper tests. The current source's 185/39 inventory is distinct. Root's historical pending cutoff at 16:40:42 UTC is preserved; its later 16:43:45 UTC report says native unit step succeeded while exact method accounting and artifact finalization were still pending. No prior pass is transferred.

## Supplemental root-supplied full-app evidence

- `docs/parallel/05/captures/receipt-full-app-60059a0.json`: SHA256 `3ff58fc17da69840350db12fca9deb4b8a69a89247711be709a9e39364bd3807`.
- `docs/parallel/05/captures/full-app-fit-feet-60059a0.png`: SHA256 `03566d550de25bb50d9c674fceefde0f503d215d2bea6cd72328e2122fadc436`; original PNG independently viewed, 1206 × 2622 pixels.
- `docs/parallel/05/validation/ui-studio-export-60059a0-accounting.json`: SHA256 `9c4592697886b591addba2dbe004e580be3067d7dd1052c8f6c201443714a7bd`.

Receipt identifies run45851365897, job140022794554, artifact15136054763 and passing `StudioSmokeTests/testSettingsFeet3DFitAndSimulatorARManualFallback()`. Exact source `UITests/StudioSmokeTests.swift:61–116` opens settings, chooses feet, enters 3D, taps Fit and checks selected mode; simulator AR declares unavailable and has neither start-camera action nor preview, then manual measurement exposes Width in feet. Later modal return preserves 3D mode. Assertions neither measure the fitted pose nor deliver orbit/pan/pinch gestures. The viewed capture shows a three-light ordinary rig with dark thin stands/small camera and a partially obscured footer/Fit behind the editing bar after scrolling back to the orbit label. The method tapped Fit before this capture. This establishes narrow full-app actions, not manual VoiceOver, AXXXL or physical-device privacy.

Accounting preserves nine passed methods and one failed export-copy method (`LightingPlanExportUITests.testFullLibraryCanPrepareUnsavedEditableCopyWithoutSavingOrChangingHistory`); shard status remains failed. The receipt records full-artifact upload timeout and successful retrieval of the compact archive.

## Disposition and owners

No new demonstrated lane05 implementation defect; no optional test additions or source edits proposed. Root owns exact current native accounting/finalization and UI evidence reconciliation. Lane01 owns `.id(session.workspaceResetID)` integration replacing inherited `.id(generation)` and hosted retention/replacement checks. Supported RealityKit runtime, manual VoiceOver/native camera behavior, maximum-type 3D controls and whole-app privacy remain unverified boundaries. The code-only M02/M03 contract removes manual audit as a milestone prerequisite; it does not turn source review into manual acceptance. Four executor interruptions and wave01 original-report loss with summary-only recovery remain explicit, not pass evidence. Planning targets have no measured token telemetry; no device FPS, deallocation or renderer-thread atomicity claim is made.
