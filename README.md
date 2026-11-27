# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active beta engineering; required UI acceptance pending.** Current core and native tests, unsigned simulator builds and the arm64 device Release build pass at `f94c0e6`. The [live campaign packet](docs/evidence/beta-campaign-2026-11-27/README.md), [tester guide](docs/BETA_TESTER_GUIDE.md) and [current handoff](agents/HANDOFF.md) describe the engineering candidate and remaining checks. The [consolidation report](docs/evidence/branch-consolidation-2026-11-27/README.md) preserves earlier published work and branch history. The owner-approved [code-only M02/M03 contract](docs/acceptance/m02-m03-code.md) remains unchanged. Physical-device validation, M04–M07, signing and owner distribution approval remain outstanding.

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
set -e
for configuration in Debug Release; do
  xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill \
    -configuration "$configuration" \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO build
done
```

Run camera, AR and thermal acceptance on supported physical devices. Simulator results do not establish device behavior.

## Verification and current work

The current [workflow at exact source `f94c0e6`](https://github.com/mirzotipi-wq/APP1/actions/runs/46004241191) has verified **588 portable Debug tests, 588 portable Release tests, 104 Python tooling checks, 591 macOS package tests and 323 native tests**, including the three required actual Metal methods. Debug/test and Release simulator builds pass, together with the separately required unsigned arm64 iPhoneOS Release compile/link and bundle checks. [Core evidence](docs/evidence/beta-campaign-2026-11-27/validation/published-03-core/reconciliation.json) and [native/build evidence](docs/evidence/beta-campaign-2026-11-27/validation/published-03-native/receipt.json) pin exact source, commands, original artifacts and limitations.

All nine library/reference UI workflows pass. Required UI acceptance is still incomplete: the first attempt failed an exact-value entry in the default-size accessibility workflow and a room-measurement entry. These failures, actual original screenshots and their diagnostic limits are retained in the [campaign packet](docs/evidence/beta-campaign-2026-11-27/README.md). The required inventory is **44 UI methods, 28 Default/AXXXL layout captures and eight separate supplemental beta captures**; two platform-audit methods remain opt-in diagnostics. A test inventory or a screenshot emission is not a passing execution or a recovered image.

All **100 actual worker contexts** have been launched in this campaign, with 26 scoped writer commits and independent review/reconciliation work. Their [identity ledger](docs/evidence/beta-campaign-2026-11-27/worker-ledger.json) records the actual completion state. Earlier failed runs and prior accepted revisions remain in the campaign and [previous closeout](docs/evidence/m03-closeout-2026-11-26/README.md) packets. No signed device build, physical-device run or TestFlight distribution is claimed.

Code changes run the full development workflow. Documentation-only evidence updates run project-state validation and do not cancel unchanged simulator work.

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
