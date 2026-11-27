# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active beta engineering; UI follow-up validation pending.** Core and native tests, unsigned simulator builds and the arm64 device Release build passed at `f94c0e6`. The latest source update corrects recovery-status accessibility, measures welcome-title layout directly, separates the beta UI workload and adds opt-in DEBUG input diagnostics. These changes require fresh Apple execution. The [live campaign packet](docs/evidence/beta-hardening-2026-11-27/README.md), [tester guide](docs/BETA_TESTER_GUIDE.md) and [current handoff](agents/HANDOFF.md) describe the engineering candidate and remaining checks. The [consolidation report](docs/evidence/branch-consolidation-2026-11-27/README.md) preserves earlier published work and branch history. The owner-approved [code-only M02/M03 contract](docs/acceptance/m02-m03-code.md) remains unchanged. Physical-device validation, M04–M07, signing and owner distribution approval remain outstanding.

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

The fresh [follow-up run at `2fc7647`](https://github.com/mirzotipi-wq/APP1/actions/runs/46019722045) has passed its core job: **588 Debug, 588 Release and 104 tooling checks**. Its twelve original image/scene pairs, six parity/eight precision cases and complete benchmark records are independently [reconciled](docs/evidence/beta-campaign-2026-11-27/validation/published-05-core/reconciliation.json). 327 native tests and required 44 required UI methods execution remain pending; the earlier verified native/build results below retain their exact prior-source identity.

The completed [workflow at exact source `f94c0e6`](https://github.com/mirzotipi-wq/APP1/actions/runs/46004241191) verified **588 portable Debug tests, 588 portable Release tests, 104 Python tooling checks, 591 macOS package tests and 323 native tests**, including the three required actual Metal methods. Debug/test and Release simulator builds passed, together with the separately required unsigned arm64 iPhoneOS Release compile/link and bundle checks. [Core evidence](docs/evidence/beta-campaign-2026-11-27/validation/published-03-core/reconciliation.json) and [native/build evidence](docs/evidence/beta-campaign-2026-11-27/validation/published-03-native/receipt.json) pin exact source, commands, original artifacts and limitations. These counts describe that tested revision, not an unexecuted follow-up.

At that revision, all nine library/reference UI workflows passed. Across all required UI methods, **22 passed, six failed, one was interrupted and 15 never started**. The six assertion failures concern three input-entry checks, the welcome-title measurement, recovery-status semantics and the background-state observation. Optics failed during runner initialization; the combined export/beta command reached its 40-minute cap. The corrupt-file relaunch smoke and both export workflows genuinely passed within that incomplete suite. Original outcomes and their diagnostic limits are retained in the [campaign packet](docs/evidence/beta-campaign-2026-11-27/README.md).

The required inventory remains **44 UI methods, 28 Default/AXXXL layout captures and eight separate supplemental beta captures**. Nine required UI shards now isolate the workload by class, preserving all 44 required methods, exact assertions and per-assertion deadlines. The integrated local candidate passes 594 Debug/594 Release and 120 tooling tests. Current Apple execution remains unverified. Two platform-audit methods remain opt-in diagnostics. The DEBUG input trace is explicitly enabled only for diagnosis, records no typed text and has bounded per-control and process output. Five additional native input methods verify privacy, bounds and unchanged editing behavior; a separate PDF Unicode regression brings the current native inventory to 329. Their Apple execution is pending. A test inventory or a screenshot emission is not a passing execution or a recovered image.

The preceding campaign launched **100 actual worker contexts**, with 26 original scoped implementation commits, subsequent fixes and independent review/reconciliation work. Their [historical identity ledger](docs/evidence/beta-campaign-2026-11-27/worker-ledger.json) records checkpoint completion. The current request has a separate [actual-worker ledger](docs/evidence/beta-hardening-2026-11-27/worker-ledger.json); it remains in progress and does not borrow previous identities. Earlier failed runs and prior accepted revisions remain in the campaign and [previous closeout](docs/evidence/m03-closeout-2026-11-26/README.md) packets. No signed device build, physical-device run or TestFlight distribution is claimed.

Code changes run the full development workflow. Documentation-only evidence updates run project-state validation and do not cancel unchanged simulator work.

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
