# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: active development.** M01 remains active pending native build validation; its latest completed app source revalidates save/relaunch and corrupt-file protection. M02 and M03 remain pending dependencies. Implemented features and verified release gates are tracked separately, and this is not a release candidate.

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

The latest completed application checkpoint **b298b13**, [workflow 45600372389](https://github.com/mirzotipi-wq/APP1/actions/runs/45600372389), finished with **34/36 UI methods passing and zero skipped**: studio/export 20/20, room/precision 5/5 and library/reference 9/11. All ten complete optics gesture→Undo→Redo→save→relaunch runs passed, as did all seven project-library and two reference workflows. Actual Recipe/edit/save/relaunch and corrupt-file protection revalidate that source's persistence smoke.

The two failed methods were complete accessibility audit calls that returned Apple `Code=-56` timeouts. The CI step deadline did not expire, and no issue-handler attachments were produced. These outcomes leave the prior ten concrete accessibility findings unverified; they do not show that the findings are fixed.

Linux b298 passed **319 Debug / 319 Release / 28 Python**, six shared-kernel and eight strict precision comparisons, eleven EFBIG checks and three process-interruption/rename scenarios. Its Intel macOS job passed 319 portable tests, then failed write-probe helper compilation before the EFBIG fixture, required unsigned app-build steps or **110 native methods** could execute. The workflow is not green. [Terminal receipts and limits](docs/evidence/m02-m03-main-2026-11-25.md).

The reviewed explicit-macOS-SDK repair is published at **f6f43dd**. At 11:51:17 UTC, [workflow 45604744523](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523) remained in progress with successful **319 Debug / 319 Release / 35 Python**, eleven EFBIG checks, three interruption/rename scenarios, six kernel and eight precision comparisons. The actual macOS diagnostic step also passed; independent artifact verification matched all 31 Swift sources and two diagnostics to exact f6 and confirmed successful SDK selection/compilation plus eleven passing EFBIG checks. Full native/UI outcomes remain unverified; no cancellation is inferred. A separately reviewed workflow candidate routes only library/reference to standard ARM macOS to obtain completed full audits; other native/UI jobs remain Intel, with all checks, deadlines and artifacts preserved. That candidate still needs publication and execution.

All **100 distinct workers** completed their initial assignments in batches. Reports remain in the [worker ledger](docs/evidence/m02-m03-2026-11-25/README.md); follow-ups reuse existing workers. Earlier ARM acquisition failures, the helper failure, accessibility findings and failed audit attempts remain recorded.

Controlled host persistence proofs verify complete old/new libraries, exact bytes, active identity and unrelated records after real EFBIG and three rename-boundary scenarios. They do not establish physical power-loss or iOS durability. The macOS diagnostic now has actual passing execution, while native app-build/unit results remain unverified.

M01 still needs native-build evidence; exact f6 core has passed. Full editing acceptance remains unverified until current native ownership/regression tests execute, despite the proven UI runs. M02 still requires calibrated controlled scenes with independent photographer review and physical performance/thermal/memory measurements. M03 also requires complete accessibility evidence and a manual device audit, and depends on M02. The [external capture packet](docs/acceptance/m02-m03-external-evidence.md) is unexecuted. The prior 17.56–35.10% host area-frame median slowdown remains diagnostic; physical performance is unverified. Protected requirements remain in the [quality contract](docs/QUALITY.md), with status in the [milestone ledger](agents/state.json).

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
