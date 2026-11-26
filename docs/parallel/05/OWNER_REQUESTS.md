# Integration and owner requests

## Current disposition

Lane 05 owns the spatial adapters, their viewport geometry helper, and matching native tests. Source `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a` contains the latest viewport implementation. No composition, Core geometry, Plan, AR, Study, CI or milestone changes are authored by this lane.

| Owner | Request | Current disposition |
|---|---|---|
| 01 — composition | Preserve viewport identity on first save; replace it when the document presentation resets. Keep generation and live-UUID selection guards. | Implemented in owner source `5ccfbaae821a32d88c12ed8b3abf1600aef25753`; not merged into lane 05. Integrated native first-save retention and project-replacement/stale-callback acceptance remain open. |
| 06 — Core geometry | Retain meter units, right-handed coordinates, emitter +Z, camera −Z and the existing Core bounds contract. | Lane 05 consumes Core frames and extends bounds only in App for represented housings, stands, bust, camera and markers. No Core changes or owner acknowledgment claimed. |
| 07 / 01 — Plan and composition | Investigate the existing Plan light reachability and equipment-row aim-status observations. | Outside viewport ownership; historical UI failures are retained without assigning an unproven cause. |
| 19 / 20 — execution and campaign evidence | Reconcile source-specific CI, inherited main evidence and outstanding device/accessibility checks. | Existing inventory and thresholds remain intact. No milestone promotion; M03 remains active. |

## Lane 01: first-save identity

Root independently inspected the three pinned files listed in `validation/lane01-5ccfbaa-disposition.json`. A further read at `7bdea15c771d7dfeeb3f20d011b3c02e4bc5b34f` confirms the same viewport identity/guards; its session and session-test blobs are unchanged. See `validation/owner-check-60059a0.json`. At that owner revision, `StudioView` keys `RealityStudioPreview` with `session.workspaceResetID`. The callback still checks its separately captured library generation and current scene UUID membership. `StudioSession` rotates the presentation identity only when adoption requests a presentation reset.

Owner test source asserts that first save retains selection, history and `workspaceResetID`, and that creating a replacement project changes the presentation identity. These assertions and the implementation are source evidence. The owner's handoff explicitly leaves native first-save viewport retention unverified.

Lane 05's frozen source still uses `.id(generation)` in the inherited composition. First save can therefore recreate its coordinator even though the viewport adapters preserve state during ordinary updates. An adapter cannot preserve a coordinator that its parent destroys. Integrate the owner change through lane 01, then check both first-save retention and deliberate project replacement with overlapping UUIDs. Do not remove the captured-generation/live-UUID guards.

Earlier wave reports correctly describe the source available when they ran: `966c9c21adbb685d82127e7f88981b74daf47e3d` still used `.id(generation)`. The newer owner source supersedes that open implementation request; it does not retroactively establish integrated behavior.

## Lane 06: bounds and emitter semantics

`StudioSceneBounds` deliberately excludes stands, subject body and housing. `SpatialViewportBounds` extends that contract for the two native viewport representations without changing Core or Plan bounds. Rectangle dimensions describe the emitting face. The RealityKit rectangle face now uses authored width and height, removing the former 6 mm inset at each edge. The front remains at local z = 0.

Exact-prefix remote checks at 2026-11-26 14:17 UTC and again at 16:34:03 UTC returned no `finish/06` or `finish/20` branch, with complete results and no pagination cursor. The campaign baseline therefore remains the requested default `f150f98e35dd735927075aac4d2f8b02295c6a67`. This is a recorded integration request, not evidence of owner acknowledgment.

## Native evidence and historical failures

The source-specific receipts in `validation/` distinguish successful native spatial execution from UI failures, cancellations and unexecuted successors.

| Source | Native / spatial passes | Other relevant results |
|---|---:|---|
| `68c83cca` | 171 / 25 | Optics failed before UI runner initialization with AX notification timeout. App accessibility failed reaching Plan light-Key. Room precision failed draft/spoken-value checks. Library/export were cancelled. |
| `9725fb1` | 176 / 30 | Library and optics UI shards passed. App accessibility failed at its line-263 wait. Room/export were cancelled by the successor. |
| `4e694bc` | 184 / 38 | Optics, room and export UI shards passed. Library, accessibility and visual review were cancelled by the successor after native execution completed. |
| `60059a0` | 185 / 39 passed | Core 366 Debug / 366 Release / 100 tooling and both native builds passed. Export, library/reference, optics and app-accessibility UI shards failed; see current receipts and timestamped job dispositions. |

Failed and cancelled jobs are not viewport passes. Their product or harness causes are not assigned without evidence. Original failure logs, final dispositions and attachment inventories remain in this directory. No assertions are skipped or relaxed.

## Inherited main checkpoint

The first source integration retains `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318` from main as a parent. It includes the explicit-`CGFloat` UI test compilation repair and prior README, canonical agent state/handoff/evidence and historical evidence updates.

Root compared every path changed from baseline outside `App/`, `NativeTests/` and `docs/parallel/05/`: all 230 paths match that main parent exactly by Git blob identity. See `validation/INTEGRATION_SCOPE-4e694bc.json`. They are inherited work, not lane-05-authored changes or new acceptance decisions. Lane 20 owns reconciliation of canonical evidence.

## Evidence limits

RealityKit runtime/device behavior, delivered native gestures, manual VoiceOver navigation, maximum Dynamic Type layout, sustained frame rate, thermal behavior and ARC/GPU leak measurement remain unverified. Source-level privacy checks establish non-AR viewport construction without an automatic camera session; they do not constitute a whole-app privacy audit.

## Current-source UI owner follow-up

Source60059 export job140022794554 passed9/10 methods and failed reopening the format chooser after undo at LightingPlanExportUITests.swift:163. Its full evidence upload timed out; the compact archive succeeded. The existing full-app3D/Fit smoke method passed and its original capture is preserved separately.

App-accessibility job140022794912 failed the openMeter reachability check at StudioAppAccessibilityUITests.swift:340. Source inspection places that call in the Plan workflow before any3D/Camera stage. The recorded target moved through12 scroll attempts but remained partly above the visible content bounds. This describes the observation; it does not assign a product or harness cause. Composition, accessibility and CI owners should investigate with the retained logs; no assertions were relaxed or skipped.

Late final observation: library/reference passed3methods, failed1large-library save-status check at source456, left1started method unfinished and4unstarted, and hit its32-minute step timeout without a finalized bundle. Room precision remains in progress at the final cutoff. These are owner follow-ups, not viewport or full-workflow passes; see the current job snapshot and ui-library-reference-60059a0 receipts.
