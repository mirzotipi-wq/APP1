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

The current implementation cycle and real worker assignments are recorded in [the M03 completion packet](docs/evidence/m03-completion-2026-11-25/README.md), following the accepted [M02 code packet](docs/evidence/m02-m03-code-2026-11-25/README.md). The revised contract requires twelve deterministic synthetic images, numerical/backend parity, bounded rendering/cache/cancellation behavior, complete editing/library workflows, and app-level accessibility checks. It does not equate software checks with calibrated photography or a completed platform audit.

The current [full run at source `cd5b461`](https://github.com/mirzotipi-wq/APP1/actions/runs/45761900201) passed 359 Debug and 359 Release package tests, 92 tooling tests, both unsigned simulator builds, all three actual Metal methods, 116 contrast pairs and the actual Linux/macOS persistence probes. Required native execution failed: 135 of 137 methods passed, with two failures in the new hosted Text-layout harness. Completed UI groups passed 33 of 34 methods; one room-status query failed, and the app-accessibility method and 24 original two-size captures remain pending. The five previous large-library/studio-export failures now pass in this fresh run; no causal product repair is inferred from that observation.

A reviewed two-file test correction is executing in [focused run 45768421649](https://github.com/mirzotipi-wq/APP1/actions/runs/45768421649) at `03cfd3c`: live native views supply layout observations after layout, while ordinary Save/Cancel/Done semantics are checked through the external UI test. All 187 app/test/tooling inputs match cd5 except those two test files. Full main validation remains required. The original failed logs, room query attachment, source reviews and exact method accounting are retained in [the completion packet](docs/evidence/m03-completion-2026-11-25/README.md). All 100 requested worker contexts exist and 99 initial specialist assignments are complete; coordinator 007 and focused followups remain active. M03 remains active.

Code changes run the full development workflow. Documentation and ledger-only updates run a separate state-validation workflow so a new evidence receipt does not repeatedly queue unchanged simulator builds. Exact tested code revisions remain recorded with their results.

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
