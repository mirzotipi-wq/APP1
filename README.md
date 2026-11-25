# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active development.** M01 is active while current-source build/save verification is reopened; M02 and M03 remain pending dependencies. Implemented features and verified release gates are tracked separately, and this is not a release candidate.

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

Current published source **b298b13**, [workflow 45600372389](https://github.com/mirzotipi-wq/APP1/actions/runs/45600372389), has successful Linux results: **319 Debug / 319 Release portable tests, 28 Python checks, six shared-kernel comparisons, eight strict precision comparisons, eleven EFBIG checks and three process-interruption/rename scenarios**. The workflow remained in progress at **11:24:14 UTC**; all three UI bundles had built successfully and their test shards were running without terminal results.

The standard Intel runners were acquired successfully. The macOS job passed 319 portable tests, then failed while compiling its write-probe helper: direct Xcode `swiftc` without an explicit SDK reported an unavailable standard library. Its EFBIG fixture, unsigned app-build steps and 110 native methods did not execute. The bounded explicit-SDK repair passed 35 Python tests and actual Linux EFBIG/interruption probes, with independent review. Those results are bound to the working-source hashes; the seven mocked SDK tests do not establish Darwin execution, and successful repaired macOS compilation/probes remain unverified. [Current receipts and failure](docs/evidence/m02-m03-main-2026-11-25.md).

Both earlier ARM64 workflows, `45593950430` at d99c9bd and `45597735891` at 18f387a, ended in hosted-runner acquisition failure. Their Apple jobs executed no native/UI tests; successful Linux results remain valid. The Intel configuration preserves Xcode 26.6, iPhone 17 Pro/iOS 26.5, all methods and audits, and the existing deadlines. Skipped native methods or missing real Metal passes fail the job. Intel exercises the existing SceneKit fallback; current ARM RealityKit execution remains separate.

The earlier complete runtime checkpoint `9602683` passed both unsigned simulator builds, 110 native methods and 34/36 UI methods, including ten complete optics workflows. Two full accessibility audits failed with ten issues. The current implementation includes reviewed validity-mask, room/transform, inspector history, stale feet-draft and adaptive Save/Cancel/plan text corrections. Earlier failures remain recorded; portable success and prepared fixes do not establish current native/UI acceptance.

All **100 distinct workers** completed their initial assignments in batches. Reports and independent reviews remain in the [worker ledger](docs/evidence/m02-m03-2026-11-25/README.md); follow-ups reuse existing workers.

The integrated persistence probes passed locally and in Linux CI: eleven EFBIG checks and three actual rename-boundary scenarios for interruption before replacement, interruption after successful replacement and explicit rename failure. Fresh processes verified complete old/new libraries, exact bytes, active identity and unrelated records. These are controlled host results, not physical power-loss or iOS evidence. The macOS write-failure fixture still requires execution after helper compilation succeeds.

The grazing-light correction passes declared numerical/continuity and shared Float32 checks, but CPU area-frame medians increased 17.56–35.10% in a short shared-host pair. Physical performance remains unverified.

M01 requires current unsigned-build and save/reopen evidence. M02 still needs calibrated controlled scenes with independent photographer review and physical performance/thermal/memory measurements; M03 needs current editing/accessibility verification and a manual device accessibility audit, and depends on M02. The [external capture packet](docs/acceptance/m02-m03-external-evidence.md) prepares those checks without claiming execution. Protected requirements remain in the [quality contract](docs/QUALITY.md), with current status in the [milestone ledger](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
