# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting workspace for photographers and filmmakers: explore a reference, edit a plausible rig, preview its geometry, place it in a room, and export a practical plan.

**Status: beta engineering in progress; distribution readiness remains unverified.** The [current development packet](docs/evidence/beta-development-2026-11-27-16f31723/README.md) tracks a new 100-agent request with actual identities and completion states. Reviewed changes preserve rejected reference/arrangement/lux drafts, keep save feedback accurate and reachable, prevent stale AR sheet reopening, adapt PDF controls, clear retired photo sessions, retain unsigned device artifacts, and identify builds by their source revision. See the [tester guide](docs/BETA_TESTER_GUIDE.md), [handoff](agents/HANDOFF.md), and [release gates](docs/QUALITY.md) for the distinction between implemented features and verified beta acceptance.

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

Published source `c19d5f8` has independent review and passing repository structure, UI class partition, privacy-manifest, app-icon and whitespace checks. Its completed portable CI job passed **604 distinct Swift methods in Debug, the same 604 in Release, and 120 tooling tests**. Original logs, twelve rendering fixtures, bounded performance samples and Linux persistence-failure evidence are retained in [the current packet](docs/evidence/beta-development-2026-11-27-16f31723/README.md). Actual inspection of the compiled simulator app then found omitted custom source metadata. A [reviewed repair candidate](docs/evidence/beta-development-2026-11-27-16f31723/build-metadata-repair.md) supplies explicit plist inputs and early built-bundle checks; fresh native propagation, device packaging and Default/AXXXL layout verification remain required. Swift and Xcode are unavailable in this local environment. Source inspection and portable tests do not establish native or physical-device acceptance.

Baseline `14d33cd` passed its portable CI job and built the first five UI bundles before this checkpoint; other baseline jobs were pending when inspected. Its results remain specific to that source. [Current implementation and worker evidence](docs/evidence/beta-development-2026-11-27-16f31723/README.md) records fresh outcomes as they become available. [The earlier campaign](docs/evidence/beta-progress-2026-11-27-0eff52f/README.md) retains its 599-test local results, failures, diagnostics and previous worker identities separately.

M01 remains active while the combined source is revalidated. Physical-device behavior, held-out inference review, configured StoreKit transactions, customer validation, signing and owner distribution approval remain outstanding under the existing contracts. Unsaved edits still require Save; a separate process-crash recovery journal has been designed but is not implemented.

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
