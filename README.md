# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active development.** M01 is complete on the recorded foundation evidence; M02 is active. Implemented features and verified release gates are tracked separately, and this is not a release candidate.

## Current implementation

- **Studio:** interactive RealityKit 3D with orbit, pan, zoom and selection, with a functional SceneKit path on Intel simulators; an editable overhead plan with light dragging; a SceneKit camera preview; subject, camera, optics and light controls; modifier roll; scene arrangement; target-lux adjustment; metric/imperial display; recipes and undo/redo.
- **Lighting studies:** ideal photometry, numerical sphere and neutral-mannequin studies, and optional Metal rendering. Preview shading is illustrative. Lux estimates describe an ideal receiving plane, not calibrated skin exposure or a measured fixture.
- **Reference workflow:** on-device Vision checks support a bounded brighter-side proposal for suitable portraits. Applying a proposed rig requires explicit acceptance; manual starting rigs remain available. Single-image analysis does not reconstruct an exact lighting setup.
- **Photo comparison:** import two actual photographs for side-by-side or wipe comparison. Reduced, metadata-stripped photo copies remain in memory for the session and are excluded from saved projects and PDF exports.
- **Room placement:** ARKit/RealityKit placement on supported devices includes equipment markers and ideal emitting faces. Manual placement provides coordinates and floor, wall and optional ceiling checks. Committed room measurements persist with the project and appear in exports.
- **Projects and export:** named projects, duplication, archive/restore, recovery, migration and conflict handling; editable project backup/import; vector PDF and text lighting plans.
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

At the recorded `38a3b52` checkpoint, [CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726) passed 261 portable tests in each of Debug and Release, 28 Python checks, both unsigned simulator builds and all 84 native tests. Simulator UI results were 24 of 27 passing: all five room/precision workflows, ten of eleven studio/export workflows and nine of eleven library/reference workflows. Every project-library and reference workflow passed, including the keyboard introduction, exact name entry, archive/delete confirmation, recovery and relaunch. Save/relaunch, corrupt-file protection, room resizing, 3D Fit, the simulator's AR/manual fallback and Arrangement presentation in feet also passed. Actual 3D and Arrangement screenshots were inspected at the preceding `29c8efe` source; the compact Arrangement feet readout fits on one line.

The run concluded failed. Both accessibility audits timed out with Code -56. The optics test captured 1.2 m while the drag was still active, then compared Redo with that intermediate value after the gesture committed 1.15 m. The captured native trace and before-Undo attachment establish this timing error; Undo restored the original 0.6 m and Redo restored the final committed width. The subsequent test synchronization correction adds one bounded 10-second wait for an actual changed width and enabled Undo before capturing the expected value. It preserves the original gesture, assertions, save/relaunch checks and application history behavior; its CI verification is pending. Earlier unchanged-width and delayed-name failures remain recorded without an inferred cause. The four measured-room PDF variants were visually reviewed at the earlier `394e28e` source. The [development checkpoint](docs/evidence/development-completion-2026-11-24.md) records exact revisions, failures, corrections and remaining verification.

Physical-device tracking, accessibility and performance, calibrated rendering, purchase sandbox scenarios, signing, customer validation and owner release approval remain outstanding. See the [quality contract](docs/QUALITY.md) and [milestone state](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
