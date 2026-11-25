# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active development.** M01 is complete on verified build/core/save evidence; M02 is active. M03 remains dependency pending; editing validation has reopened after newer UI failures, persistence retains scoped passing evidence, and accessibility remains open. Implemented features and release gates are tracked separately; this is not a release candidate.

## Current implementation

- **Studio:** interactive RealityKit 3D with orbit, pan, zoom and selection, with a functional SceneKit path on Intel simulators; an editable overhead plan with light dragging; a SceneKit camera preview; subject, camera, optics and light controls; modifier roll; scene arrangement; target-lux adjustment; metric/imperial display; recipes and undo/redo.
- **Lighting studies:** ideal photometry, numerical sphere and neutral-mannequin studies, and optional Metal rendering. Preview shading is illustrative. Lux estimates describe an ideal receiving plane, not calibrated skin exposure or a measured fixture.
- **Reference workflow:** on-device Vision checks support a bounded brighter-side proposal for suitable portraits. Applying a proposed rig requires explicit acceptance; manual starting rigs remain available. Single-image analysis does not reconstruct an exact lighting setup.
- **Photo comparison:** import two actual photographs for side-by-side or wipe comparison. Reduced, metadata-stripped photo copies remain in memory for the session and are excluded from saved projects and PDF exports.
- **Room placement:** ARKit/RealityKit placement on supported devices includes equipment markers and ideal emitting faces. Manual placement provides coordinates and floor, wall and optional ceiling checks. Committed room measurements persist with the project and appear in exports.
- **Projects and export:** searchable named projects with saved-rig thumbnails, duplication, archive/restore, disambiguated recovery, migration and conflict handling; editable project backup/import; vector PDF and text lighting plans.
- **Purchases:** StoreKit 2 product loading, purchase, restore and entitlement handling are implemented. The product identifier defaults to unconfigured; no owner-approved feature gates are enabled.

## Build and run

The portable `LightingCore` package requires Swift 5.9 or later. The native app requires macOS, Xcode with an iOS 17+ SDK, and XcodeGen. The Xcode project is generated from `project.yml`.

```sh
swift test
swift test -c release
python3 scripts/agent_cycle.py check
python3 scripts/agent_cycle.py next

# macOS:
xcodegen generate
open KeyAndFill.xcodeproj
```

Unsigned simulator builds:

```sh
for configuration in Debug Release; do
  xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill \
    -configuration "$configuration" \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO build
done
```

Run camera, AR and thermal acceptance on supported physical devices. Simulator results do not establish device behavior.

## Verification and remaining gates

Actual **f6f43dd** simulator execution passed both unsigned Debug/Release builds and **110 native methods with zero failures or skips**, including all three required Metal tests. The room/precision shard also passed **5/5**. Exact f6 core passed **319 Debug / 319 Release / 35 Python**, numerical fixtures and Linux persistence probes; the real macOS SDK/EFBIG diagnostic passed independently. [Native receipt](docs/evidence/m02-m03-2026-11-25/followups/followup-f6-native-terminal.md), [room receipt](docs/evidence/m02-m03-2026-11-25/followups/followup-f6-room-terminal.md).

The final **f6** workflow failed at **12:53:33 UTC**. Its 36-method UI inventory reconciles to **23 passed, 6 failed, 2 started but incomplete, and 5 not started; zero skipped**. Library/reference recorded four passes, two full audit `Code=-56` failures, three readiness-wait failures and incomplete reference coverage before its 32-minute deadline. Studio/export recorded 14 passes, one failed post-relaunch status wait, one interrupted Recipe method and four unstarted methods before its 40-minute deadline. Neither shard produced a finalized XCTest result bundle. [Library evidence](docs/evidence/m02-m03-2026-11-25/followups/followup-library-f6-terminal.md), [studio evidence](docs/evidence/m02-m03-2026-11-25/followups/followup-f6-studio-terminal.md).

**Editing validation is reopened.** Nine of ten f6 optics workflows passed; the tenth failed the post-relaunch “Saved locally” wait. Initial save succeeded and the new process restored emitter width 2.1 m, so the available evidence does not prove disk loss or explain the status failure. The earlier b298 run's ten complete optics passes and 34/36 total UI passes remain preserved. Its two audit timeouts, and the prior ten concrete accessibility findings, remain unresolved. Complete new workflows under unchanged checks are required before restoring the editing gate.

**M01 remains complete** on actual core/build evidence and completed smoke flows. f6 passed library create/duplicate/rename/switch/relaunch, camera and meter save/relaunch, nine full optics workflows, and corrupt-file protection. These completed results support the narrower smoke gate while full editing reliability remains unverified. Application, core, tests, resources and project/package inputs are identical across b298, f6, a1ef and published **214ca90**; working diagnostic changes require separate validation.

At the **13:04:55 UTC** observation, last published main was **214ca90** and [workflow 45613203857](https://github.com/mirzotipi-wq/APP1/actions/runs/45613203857) was in progress with actual **319 Debug / 319 Release / 35 Python** core success. Native was building Release after Debug success; Intel room/studio were building UI. Its ARM library job **139221045245** was queued without a runner since 12:57:40; that earlier snapshot did not establish a capacity failure or audit result. The prior pending a1ef run was actually cancelled at 12:22:57 after publication under normal concurrency; active f6 was not cancelled. Published 214ca90 routes only library/reference to ARM, with native/room/studio on Intel and all checks and limits retained. [Captured progress and core receipt](docs/evidence/m02-m03-2026-11-25/validation/checkpoint8-progress.json).

The later [terminal ARM receipt](docs/evidence/m02-m03-2026-11-25/followups/followup-library-arm-214-nonexecution.md), observed **13:13:38.170 UTC**, records that library job as **cancelled at 13:12:42**, after 15m 02s without a runner or any step. All eleven library/reference methods remain unrun at 214ca90. The earlier cause was unattributed until the [official annotations](docs/evidence/m02-m03-2026-11-25/validation/library-arm-214-terminal/annotations.json), retained at **13:17:43**, established hosted-runner acquisition failure with three ARM capacity notices. No global outage or application result is inferred.

The [reviewed candidate](docs/evidence/m02-m03-2026-11-25/followups/followup-ui-host-diagnostics.md) returns library/reference to standard Intel, moves UI simulator boot after compilation, adds bounded optional host snapshots and records the actual GitHub test-step outcome separately from the shell trap value. Bounded error-path logging in two UI-test files is also prepared and source-reviewed. All required checks and deadlines remain; actual Apple compilation/execution is pending. The [timing comparison](docs/evidence/m02-m03-2026-11-25/followups/followup-ui-build-boot-order.md) found identical compiler commands/source work and longer pre-compilation delays, without measured resource-pressure evidence. Speedup and repair of the observed failures remain unproven; no future commit or CI pass is claimed.

All **100 distinct workers** completed their initial assignments; [reports](docs/evidence/m02-m03-2026-11-25/README.md) preserve their work and follow-ups. Earlier runner-acquisition failures, the repaired helper failure and all failed/incomplete UI evidence remain recorded.

**M02 is active:** twelve rights-cleared calibrated scenes, independent photographer review and physical iPhone performance/thermal/memory evidence remain missing. **M03 is dependency pending:** editing is unverified, accessibility is failed/incomplete, and persistence retains its scoped host and completed-app evidence. The [external capture packet](docs/acceptance/m02-m03-external-evidence.md) is unexecuted. The 17.56–35.10% host area-frame median slowdown remains diagnostic. Protected requirements remain in the [quality contract](docs/QUALITY.md), with source-bound conclusions in the [integration report](docs/evidence/m02-m03-main-2026-11-25.md) and [milestone ledger](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
