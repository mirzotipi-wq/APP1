# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: beta engineering work in progress; beta acceptance remains unverified.** The [current campaign](docs/evidence/beta-progress-2026-11-27-0eff52f/README.md) starts from `804c2c7` with 100 new actual subagent runs scheduled in bounded batches. Its first independently reviewed candidate fixes malformed ignored JSON numbers and insufficient large-text navigation travel, and records focused diagnostics for an unresolved library transition. Local Debug and Release each pass 599 tests. The next candidate adds focused native input tracing and a reversible CI output-location experiment; current Apple/UI execution remains required. The [tester guide](docs/BETA_TESTER_GUIDE.md), [handoff](agents/HANDOFF.md) and [release gates](docs/QUALITY.md) distinguish code evidence from device and distribution acceptance.

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

The [source manifest](docs/evidence/beta-progress-2026-11-27-0eff52f/validation/candidate-02-source.json) binds the current candidate. Local Debug and Release each passed 599 portable methods; 11 actual pure geometry XCTest methods also passed on Linux. The [local receipt](docs/evidence/beta-progress-2026-11-27-0eff52f/validation/candidate-02-local-results.json) retains commands and logs. These observations do not establish Apple UI or physical-device acceptance.

The baseline [9d18 run](https://github.com/mirzotipi-wq/APP1/actions/runs/46037214333) passed 594 Debug, 594 Release and 120 tooling tests. Its studio, optics and room UI groups passed all 24 required methods. Library/reference and PDF preview have failed accessibility queries, and app accessibility failed after 14 Default and 6 AXXXL original captures. The native suite started all 335 methods but one focus method failed two assertions, one pass event was interleaved with system output, and the command failed to finalize. The current source requires fresh affected-gate validation. Every previous failure and missing image remains explicit.

The candidate inventory is 338 native methods and 44 required UI methods across 9 groups. The 28 required Default/AXXXL originals and 8 supplemental beta originals remain required. All protected criteria, individual assertion deadlines and actual visibility requirements are unchanged. A 100-run request is tracked through real task identities in the [new ledger](docs/evidence/beta-progress-2026-11-27-0eff52f/worker-ledger.json); a planned worker is not a completed worker.

The opt-in DEBUG input trace records bounded metadata without typed text or system uptime. The [privacy inventory](docs/PRIVACY.md) describes its retention and ephemeral purchase correlation token. Signed Release inspection and configured StoreKit transactions remain unverified.

### Historical checkpoints

- Source `af6b7e5` passed **594 Debug, 594 Release, 120 tooling and 597 macOS package methods**, confirming the supported-platform decoder repair. Native test-bundle compilation then failed on a PDF metadata-key expression, leaving all 335 native and 44 UI methods unstarted. The explicit-key correction is the sole source change in `9d18`; its expected title assertion remains intact. [Core](docs/evidence/beta-hardening-2026-11-27/published-af6-core/receipt.json), [native](docs/evidence/beta-hardening-2026-11-27/published-af6-native/receipt.json) and [UI](docs/evidence/beta-hardening-2026-11-27/published-af6-ui/receipt.json) receipts preserve those separate outcomes.
- Source `2fc7647` passed **591 macOS and 327 native methods**, including actual Metal and unsigned simulator/device builds. Its 44 UI methods ended with **23 passed, seven failed, two incomplete and 12 unstarted**. [Native/build](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-native/receipt.json), [remaining UI groups](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-remaining-ui/receipt.json), [library](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-library/receipt.json) and [accessibility](docs/evidence/beta-hardening-2026-11-27/concurrent-2fc-accessibility/app-accessibility-140578197692-receipt.json) records retain exact scope. This run is terminal, not awaiting execution.
- Source `f94c0e6` passed **588 Debug, 588 Release, 104 tooling, 591 macOS and 323 native methods**, together with unsigned simulator and arm64 device builds. Required UI accounting was **22 passed, six failed, one interrupted and 15 unstarted**. Its normal library and recovered corrupt-file relaunch evidence narrowly revalidated M01 at that revision; later changed sources still require affected-gate verification. The [historical campaign](docs/evidence/beta-campaign-2026-11-27/README.md) preserves originals and failures.

The preceding hardening request recorded **100 distinct actual worker identities** in its [own ledger](docs/evidence/beta-hardening-2026-11-27/worker-ledger.json), with final CI follow-up and acceptance review in progress. It does not borrow the preceding campaign's [100-worker ledger](docs/evidence/beta-campaign-2026-11-27/worker-ledger.json). The [consolidation report](docs/evidence/branch-consolidation-2026-11-27/README.md) preserves concurrent history; no force update or branch deletion was performed. No signed device build, physical-device run or TestFlight distribution is claimed.

Code changes run the full development workflow. Documentation-only evidence updates run project-state validation and do not cancel unchanged simulator work.

## Development references

Read [AGENTS.md](AGENTS.md) and the [operating protocol](agents/OPERATING_PROTOCOL.md) before contributing. Consult the [product contract](docs/PRODUCT.md), [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) and [design standard](docs/DESIGN.md).

The [handoff](agents/HANDOFF.md), [evidence ledger](agents/evidence.json) and [historical reports](docs/evidence/) preserve revision-specific results, failures and pending work. Update evidence with each verified work package; never infer release readiness from feature presence.

All rights reserved unless the owner selects a license.
