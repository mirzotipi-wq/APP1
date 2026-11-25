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

The latest completed main checkpoint, `9602683`, has [287 Debug / 287 Release portable tests, 28 Python checks, both unsigned simulator builds, and 110 native tests passing](https://github.com/mirzotipi-wq/APP1/actions/runs/45582259076). Studio/export passed 20/20, including ten complete optics workflows; room/precision passed 5/5. Library/reference passed 9/11. The workflow failed because two full accessibility audits reported ten issues. Those failures remain recorded.

The reviewed follow-up adds exact validity-mask checks, strict boundary and composed-transform corrections, independent Undo ownership for discrete inspector actions, underlying-value guards for feet editing, and adaptive Save, Cancel and plan text. Local **319 Debug / 319 Release tests and 28 Python checks pass**. All 110 native and 36 UI methods require execution at the new source. All 100 requested distinct workers completed their initial assignments; their reports and independent reviews are retained in the [worker ledger](docs/evidence/m02-m03-2026-11-25/README.md).

A bounded Linux write-failure probe observed actual EFBIG and verified exact prior bytes, unrelated records, and fresh-process reopening, with an unrestricted successful control. Its source-bound wrapper is included in Linux and macOS CI. This does not replace abrupt-interruption, rename-only, ENOSPC or device evidence.

The grazing-light correction passes declared numerical/continuity and shared Float32 checks, but CPU area-frame medians increased 17.56–35.10% in a short shared-host pair. Physical performance remains unverified. See the [current session report](docs/evidence/m02-m03-main-2026-11-25.md) for exact source scopes, failed attempts and remaining acceptance.

M02 still needs calibrated controlled scenes and independent photographer review, plus physical performance/thermal/memory measurements. M03 still needs current-source editing/accessibility verification, manual device accessibility and remaining persistence interruption coverage, and depends on M02. Broader release requirements remain in the [quality contract](docs/QUALITY.md) and [milestone state](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
