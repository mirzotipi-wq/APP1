# Wave09 — lifecycle and interaction continuity

Frozen source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`. This is a bounded source/evidence review. No production change, new test, local build or native execution was performed by these workers.

## Supported result

No additional reproducible lane05 adapter defect was established. `acceptance/lifecycle-matrix.md` records valid/invalid, disabled/inactive, off-window, dismantled and recreated states. Continuing UUIDs retain equipment; deletion/invalid input removes current hit ownership before replacement. Both adapters refresh callbacks before geometry equality exits. SceneKit invalid recovery preserves existing orbit or completes a pending mode/Fit transition.

Lifecycle mechanics differ: SceneKit gates interaction/stops inertia, and off-window selection additionally requires a window. RealityKit removes anchors and cancels its recognizers while retaining graph/orbit ownership. The resources report derives explicit ownership bounds of 56 SceneKit nodes and 343 RealityKit entities at 12 lights. These source counts exclude renderer internals and are not allocation, leak or performance measurements. Hit lookup establishes graph ownership, not permission to deliver callbacks: retained RealityKit graph hits can still resolve after anchor detachment; coordinator gates and teardown block dispatch. SceneKit teardown clears attachments/maps while retaining its two coordinator-owned root/camera nodes.

## Owner integration

Frozen lane05 retains first-save `.id(generation)` recreation. Current lane01 head `5ccfbaae821a32d88c12ed8b3abf1600aef25753` instead uses `.id(session.workspaceResetID)` while preserving separate generation/live-UUID guards. Exact ref/blob/excerpt evidence is retained in `interfaces/owner-checkpoint.json`. Session tests assert identity semantics; hosted viewport retention remains unverified. The owner request is integration plus first-save camera/target retention, intentional switch/reload reset with overlapping UUIDs, and stale-callback rejection.

## Evidence boundary

Historical [source 4e694bc / run 45838950713](https://github.com/mirzotipi-wq/APP1/actions/runs/45838950713) passed 184 native/38 spatial methods: 28 direct SceneKit and 10 helpers, plus Debug/Release builds. Current 60059 changes the angle helper and adds one regression: 185/39 is inventory, with 28 direct SceneKit and 11 helpers.

Parent-reported [run 45851365897](https://github.com/mirzotipi-wq/APP1/actions/runs/45851365897) core checks passed 366 Debug/366 Release/100 tooling. At 16:19:22 UTC, native job 140022794410's Release build remained in progress; no current-source native execution receipt was yet reviewed. Later receipts must stay revision-qualified.

Direct callbacks, serial updates, property/projection assertions and UIWindow snapshots do not establish delivered gesture continuity, renderer stress, deallocation or device performance. `SpatialOrbitState` bounds constrain RealityKit controls and SceneKit Fit, not SceneKit's built-in gestures. RealityKit runtime, hosted lifecycle, manual VoiceOver, FPS/RSS/thermal and whole-app privacy/accessibility audits remain unverified.

## Review record

Final independent review read all nine other complete reports and verified the two evidence-wording clarifications above; no new code defect was found. Ten actual contexts comprise this lead plus nine fresh children; `ledger.json` records canonical IDs and hashes. Complete reports are retained before child completion. The prepared package is restricted to `docs/parallel/05/workers/w09/`; root owns integration, ref updates and the global count. No milestone/release promotion is proposed.
