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

At the recorded `fb643b1` checkpoint, [CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115) passed 261 portable tests in each of Debug and Release, 28 Python checks, both unsigned simulator builds and all 84 native tests. All eleven studio/export and five room/precision UI workflows passed. The original optics workflow passed its real gesture, Undo, Redo, save, relaunch and exact restored-width assertions. Its trace and attachment record an initial 0.6 m and a final saved 0.8 m. At the 2026-11-25 02:19 UTC observation, the library/reference job had reached UI execution; its eleven cases and the overall run had no terminal result.

The optics correction adds one bounded 10-second wait for an actual changed width and enabled Undo before capturing the expected value. This addresses the demonstrated premature capture at `38a3b52`, while preserving the gesture, all original assertions and application history behavior. The earlier run's two accessibility audits failed with Code -56 timeouts; their cause remains unknown. Earlier unchanged-width and delayed-name failures remain recorded without an inferred cause. The four measured-room PDF variants were visually reviewed at `394e28e`, and actual 3D and Arrangement screenshots at `29c8efe`.

A subsequent compiler correction snapshots only a Boolean on the main actor before constructing the photo-picker label, avoiding a direct actor-isolated image-property read inside that sendable closure. Its Apple verification is pending and requires a new normal CI run. The [development checkpoint](docs/evidence/development-completion-2026-11-24.md) records exact revisions, failures, corrections and remaining verification.

Physical-device tracking, accessibility and performance, calibrated rendering, purchase sandbox scenarios, signing, customer validation and owner release approval remain outstanding. See the [quality contract](docs/QUALITY.md) and [milestone state](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
