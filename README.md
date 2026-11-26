# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active code development.** M01 and M02 are complete; M03 implementation is in native validation under the owner's [code-only acceptance contract](docs/acceptance/m02-m03-code.md), approved on 25 November 2026. Unavailable physical calibration, human reviews and device measurements are removed from those two development milestones; they remain unperformed and are not claimed. M04–M07 and release acceptance remain separate.

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

## Verification and current work

M02 is complete under the code acceptance contract. The reviewed layout and fixture corrections are published at `f150f98e35dd735927075aac4d2f8b02295c6a67` and are running in [run 45805136256](https://github.com/mirzotipi-wq/APP1/actions/runs/45805136256). Required execution is **154 native methods, 35 UI methods and 28 original Default/AXXXL layout captures**. The ten optics methods repeat the same editing workflow. M03 remains active until all required results and image review pass.

The [closeout packet](docs/evidence/m03-closeout-2026-11-26/README.md) records exactly 100 completed worker contexts, Unicode and history boundaries, room precision, camera selection/slider contrast, native measurement/focus fixtures and CI ownership/retention repairs. Fresh f150 CI independently verified 366 Debug, 366 Release and 100 tooling tests, twelve original render matches, the numerical and benchmark matrices, and actual ext4 write-failure/interruption probes. Local tmpfs observations remain separately retained; Apple runtime execution remains required.

The preceding 9fa run passed all 366 Debug/366 Release/100 tooling checks, 153/154 native methods and 34/35 UI methods. The native fixture containment and largest-text caption assertions failed; recovered original images also identified a cramped Scene/Meter header. These failures and the preceding 02797 outcomes remain in the packet. The new repair keeps every minimum-fit, containment, growth and hit-target requirement and adds two header captures.

Code changes run the full development workflow. Documentation-only evidence updates run project-state validation and do not cancel unchanged simulator work.

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
