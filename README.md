# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: published engineering candidate; beta acceptance remains unverified.** Source [`9d18d76`](https://github.com/mirzotipi-wq/APP1/commit/9d18d762f204ed060af5309554d97841ea70ea03) is undergoing [fresh Apple validation](https://github.com/mirzotipi-wq/APP1/actions/runs/46037214333). Its core CI passed 594 Debug tests, 594 Release tests and 120 tooling tests. Apple test-bundle compilation has passed in multiple UI jobs; native/UI execution and original layout evidence are still being reconciled. The candidate hardens editable imports, largest-text rows, purchase-attempt correlation, private diagnostics and bounded UI observation. All 100 requested worker contexts are recorded in the [live campaign packet](docs/evidence/beta-hardening-2026-11-27/README.md), with final verification in progress. The [tester guide](docs/BETA_TESTER_GUIDE.md) and [handoff](agents/HANDOFF.md) state remaining work. The owner-approved [code-only M02/M03 contract](docs/acceptance/m02-m03-code.md) remains unchanged; physical-device validation, M04–M07, signing and owner distribution approval remain outstanding.

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

The active [run at exact source `9d18d76`](https://github.com/mirzotipi-wq/APP1/actions/runs/46037214333) has passed core CI: **594 distinct Debug methods and the same 594 Release methods**, each started and passed exactly once, plus **120 tooling tests**. Its [independently verified original core packet](docs/evidence/beta-hardening-2026-11-27/published-9d18-core/receipt.json) also records successful persistence failure/retry probes, six parity cases, eight selected precision cases and bounded 8/12/4 benchmark workload checks. [The source manifest and receipt](docs/evidence/beta-hardening-2026-11-27/validation/published-source-05.json) bind all 258 inputs. Native and UI outcomes must come from this run; a successful build or capture emission is not a passing workflow or an inspected original image.

The inventory is **335 native methods, 44 required UI methods, 28 Default/AXXXL layout originals and eight supplemental beta originals**. The campaign preserves all 327 upstream native methods and adds six purchase-state regressions, one PDF Unicode regression and one input-trace regression. Nine required UI groups retain every method, assertion deadline and finalized-result requirement. Two platform-audit methods remain opt-in diagnostics. The 28-image manifest has a dedicated completeness gate; the eight supplemental originals also require independent retrieval and inspection. The [contract preservation review](docs/evidence/beta-hardening-2026-11-27/contract-preservation-review/receipt.json) records the unchanged protected criteria and the separate aggregate CI budget changes.

The opt-in DEBUG input trace records bounded metadata, without typed text or system uptime. The [privacy inventory](docs/PRIVACY.md) describes its developer-log retention and the ephemeral StoreKit purchase correlation token. Signed Release inspection and actual configured StoreKit transactions remain unverified.

### Historical checkpoints

- Source `af6b7e5` passed **594 Debug, 594 Release, 120 tooling and 597 macOS package methods**, confirming the supported-platform decoder repair. Native test-bundle compilation then failed on a PDF metadata-key expression, leaving all 335 native and 44 UI methods unstarted. The explicit-key correction is the sole source change in `9d18`; its expected title assertion remains intact. [Core](docs/evidence/beta-hardening-2026-11-27/published-af6-core/receipt.json), [native](docs/evidence/beta-hardening-2026-11-27/published-af6-native/receipt.json) and [UI](docs/evidence/beta-hardening-2026-11-27/published-af6-ui/receipt.json) receipts preserve those separate outcomes.
- Source `2fc7647` passed **591 macOS and 327 native methods**, including actual Metal and unsigned simulator/device builds. Its 44 UI methods ended with **23 passed, seven failed, two incomplete and 12 unstarted**. [Native/build](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-native/receipt.json), [remaining UI groups](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-remaining-ui/receipt.json), [library](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-library/receipt.json) and [accessibility](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-accessibility/app-accessibility-140578197692-receipt.json) records retain exact scope. This run is terminal, not awaiting execution.
- Source `f94c0e6` passed **588 Debug, 588 Release, 104 tooling, 591 macOS and 323 native methods**, together with unsigned simulator and arm64 device builds. Required UI accounting was **22 passed, six failed, one interrupted and 15 unstarted**. Its normal library and recovered corrupt-file relaunch evidence narrowly revalidated M01 at that revision; later changed sources still require affected-gate verification. The [historical campaign](docs/evidence/beta-campaign-2026-11-27/README.md) preserves originals and failures.

The current request has **100 distinct actual worker identities** in its [own ledger](docs/evidence/beta-hardening-2026-11-27/worker-ledger.json), with final CI follow-up and acceptance review in progress. It does not borrow the preceding campaign's [100-worker ledger](docs/evidence/beta-campaign-2026-11-27/worker-ledger.json). The [consolidation report](docs/evidence/branch-consolidation-2026-11-27/README.md) preserves concurrent history; no force update or branch deletion was performed. No signed device build, physical-device run or TestFlight distribution is claimed.

Code changes run the full development workflow. Documentation-only evidence updates run project-state validation and do not cancel unchanged simulator work.

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
