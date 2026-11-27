# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active code development.** All five published finish workstreams have been consolidated into `main`, with all eight audited non-main branch tips and their development history retained and remotely verified. The combined source is undergoing fresh native validation; earlier M01/M02 acceptance remains tied to its original revisions. See the [27 November consolidation report](docs/evidence/branch-consolidation-2026-11-27/README.md) and [current handoff](agents/HANDOFF.md). The owner-approved [code-only M02/M03 contract](docs/acceptance/m02-m03-code.md) remains unchanged. M04–M07 and release acceptance remain separate.

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

The consolidated source passes **482 portable Debug tests, 482 portable Release tests and 100 Python tooling tests**. All twelve CPU reference images retain their original hashes; six canonical shared-kernel comparisons, eight strict precision cases and the bounded rendering/cancellation benchmark pass. Native Swift syntax and source partition/icon/privacy checks pass. The combined native suite declares **261 methods and 36 required UI methods**; [fresh Apple CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45979992218) is running. Results, logs, branch pins and the independent preservation audit are in the [consolidation packet](docs/evidence/branch-consolidation-2026-11-27/README.md).

The prior [b0d25ee workflow](https://github.com/mirzotipi-wq/APP1/actions/runs/45807031966) completed with core/native success and UI failures. It is no longer running. Those failures and earlier acceptance evidence remain in the [previous closeout packet](docs/evidence/m03-closeout-2026-11-26/README.md) and each [workstream handoff](docs/parallel/). Fresh combined-source native, Metal, UI and image-review evidence is required before acceptance is advanced.

Code changes run the full development workflow. Documentation-only evidence updates run project-state validation and do not cancel unchanged simulator work.

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
