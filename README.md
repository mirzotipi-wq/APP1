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

The latest verified Linux checkpoint `18f387a` has [319 Debug / 319 Release portable tests, 28 Python checks, six shared-kernel comparisons, eight strict precision comparisons, eleven write-failure checks and three process-interruption/rename scenarios passing](https://github.com/mirzotipi-wq/APP1/actions/runs/45597735891). Its four Apple jobs are queued at the recorded observation; all 110 native and 36 UI methods still require current-source execution.

The previous app checkpoint's Apple jobs failed to acquire hosted ARM64 runners and executed no tests. The reviewed CI repair selects the supported standard Intel pool with the same pinned Xcode 26.6 and iPhone 17 Pro/iOS 26.5 environment. All tests remain; skipped native methods or missing real Metal passes fail the job. Intel verifies the existing SceneKit fallback, and current ARM RealityKit execution remains separate.

The earlier completed main checkpoint `9602683` passed both unsigned simulator builds, 110 native methods and 34/36 UI methods, including ten complete optics workflows. Two complete accessibility audits failed with ten issues. The current implementation repairs exact validity-mask comparison, room/cardinal and composed-transform boundaries, discrete inspector Undo ownership, stale feet drafts, and adaptive Save, Cancel and plan text. Earlier failures remain recorded; current native success is not inferred from portable tests.

All **100 distinct workers** completed their initial assignments, in batches. Reports and independent reviews are retained in the [worker ledger](docs/evidence/m02-m03-2026-11-25/README.md); follow-ups reuse existing workers.

The final integrated persistence command passed locally and in exact-main Linux CI: all eleven EFBIG checks plus three actual rename-boundary scenarios: interruption before replacement, interruption after successful replacement, and explicit rename failure. Fresh processes verified complete old/new libraries, exact bytes, active identity and unrelated records. Linux CI now includes those probes; macOS retains the write-failure probe. These are controlled host results, not physical power-loss or iOS evidence. See [receipts and limitations](docs/evidence/m02-m03-main-2026-11-25.md).

The grazing-light correction passes declared numerical/continuity and shared Float32 checks, but CPU area-frame medians increased 17.56–35.10% in a short shared-host pair. Physical performance remains unverified.

M02 still needs calibrated controlled scenes and independent photographer review, plus physical performance/thermal/memory measurements. M03 still needs current-source editing/accessibility verification and manual device accessibility, and depends on M02. Current build/save verification is also pending. The [external capture packet](docs/acceptance/m02-m03-external-evidence.md) prepares these checks without claiming execution. Protected requirements remain in the [quality contract](docs/QUALITY.md) and actual state in the [milestone ledger](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
