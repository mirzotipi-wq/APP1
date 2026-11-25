# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active development.** M01 is complete on verified build/core/save evidence; M02 is active. M03 remains dependency pending, with editing and persistence verified but accessibility still open. Implemented features and release gates are tracked separately; this is not a release candidate.

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

Actual **f6f43dd** simulator execution passed both unsigned Debug/Release builds and **110 native methods with zero failures or skips**, including all three required Metal tests. The room/precision shard also passed **5/5**. Exact f6 core passed **319 Debug / 319 Release / 35 Python**, numerical fixtures and Linux persistence probes; the real macOS SDK/EFBIG diagnostic passed independently. [Native receipt](docs/evidence/m02-m03-2026-11-25/followups/followup-f6-native-terminal.md), [room receipt](docs/evidence/m02-m03-2026-11-25/followups/followup-f6-room-terminal.md).

The preceding **b298b13** application UI run completed **34/36 methods, zero skipped**, including all ten complete optics gesture→Undo→Redo→save→relaunch workflows, all seven library and two reference workflows, and actual corrupt-file protection. Its two full accessibility audits returned Apple `Code=-56` timeouts. The missing issue-handler attachments do not establish a clean audit. The prior ten concrete findings remain unverified.

These native/core/UI results revalidate **M01 and the editing gate**. Independent comparisons show identical application, core, test, resource and project/package inputs across b298, f6 and observed **a1ef72f**. Each result retains its executed revision; this source equivalence is not a claimed a1ef CI pass. Exact units, history/ownership, stable selection, valid transforms, edit preservation and ten complete core workflow runs are supported. M03 still depends on unfinished M02 and its separate accessibility gate.

At the **12:19:13 UTC** capture, the last observed published source was **a1ef72f**. Its [workflow 45609587344](https://github.com/mirzotipi-wq/APP1/actions/runs/45609587344) was **pending at the captured time** behind active [f6 workflow 45604744523](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523). f6 has terminal core/native/room success; library/reference and studio/export were both running their selected UI shards at that capture. No explicit run cancellation occurred. The published a1ef workflow routes only library/reference to standard ARM macOS; all other native/UI jobs remain Intel, with all tests, audits, deadlines and artifacts retained.

All **100 distinct workers** completed their initial assignments; [reports](docs/evidence/m02-m03-2026-11-25/README.md) preserve their work and follow-ups. Earlier runner-acquisition failures, the now-repaired helper failure and failed accessibility audits remain recorded.

**M02 is active:** twelve rights-cleared calibrated scenes, independent photographer review and physical iPhone performance/thermal/memory evidence remain missing. **M03 is dependency pending:** editing and persistence pass, while automatic and manual device accessibility remain open. The [external capture packet](docs/acceptance/m02-m03-external-evidence.md) is unexecuted. The 17.56–35.10% host area-frame median slowdown remains a diagnostic cost, not a device result. Protected requirements remain in the [quality contract](docs/QUALITY.md), with source-bound conclusions in the [integration report](docs/evidence/m02-m03-main-2026-11-25.md) and [milestone ledger](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
