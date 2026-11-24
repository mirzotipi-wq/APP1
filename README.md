# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting studio for photographers and independent filmmakers. Import a reference, explore plausible lighting arrangements, design a scene in 3D, place equipment in a real room using AR, and export a practical lighting plan.

**Status: interactive prototype / pre-alpha.** The current app provides an editable overhead plan, illustrative 3D and camera views, a numerical sphere study with optional Metal, a CPU neutral mannequin study, precise light/optics/camera controls, recipes, undo/redo, and vector PDF/text export. Reference comparison uses a session-only photo derivative, descriptive SDR tonal statistics and manually guided starting rigs. Manual room placement supplies measured coordinates and footprint warnings; AR tracking is not implemented.

The local library supports named projects, duplication, archive/restore, explicit archived-record deletion, legacy migration, optimistic conflict protection and recovery of unsaved edits. Editable project copies preserve scene settings outside the library, including at the 64-project limit; importing creates a separate project. Reference photos, room measurements and undo history are not included in those copies.

**Current verified source (2026-11-24):** [`5ac2d1e`](https://github.com/mirzotipi-wq/APP1/commit/5ac2d1e2e8e8762c84ababa93e1982ec914fbef8) passed **201/201 portable tests in Debug and Release**, plus **24/24 Python validation tests** in an isolated exact-source checkout. [Evidence and raw logs](docs/evidence/2026-11-24-autonomous/checkpoint-3.md). Its [native workflow](https://github.com/mirzotipi-wq/APP1/actions/runs/45354563409) is pending at this checkpoint. Native syntax parsing does not establish SDK compilation or system-picker behavior.

[Historical native source cab67417](https://github.com/mirzotipi-wq/APP1/actions/runs/45346996294) passed both unsigned simulator builds, 10/10 native unit tests and 7/7 library/reference UI tests. Its room/precision shard passed the two room tests then timed out during precision; that is not a complete regression pass. Current changes require their own native evidence. [The handoff](agents/HANDOFF.md) retains previous revisions, failures, artifacts and pending work; [the evidence ledger](agents/evidence.json) separates historical observations from current gates.

**M01 remains active.** Physical-device accessibility, GPU/performance/thermal testing, calibrated portrait rendering, automatic reference reconstruction, AR, StoreKit, customer validation, signed distribution and owner release approval remain outstanding. No App Store or physical-device release is available. The product name remains provisional.

[Prototype guide](docs/PROTOTYPE.md) · [GitHub Actions](https://github.com/mirzotipi-wq/APP1/actions) · [Backlog](agents/BACKLOG.md) · [Privacy draft](docs/PRIVACY.md) · [Evidence-only scorecard](docs/evidence/quality-scorecard-2026-11-23.md)

## Start here

| File | Purpose |
|---|---|
| [AGENTS.md](AGENTS.md) | Mandatory master instructions for all development agents |
| [agent operating protocol](agents/OPERATING_PROTOCOL.md) | Repeatable work, review, learning and handoff loop |
| [agent roles](agents/ROLES.md) | Specialist workstreams and independent review |
| [agent state](agents/state.json) | Machine-readable milestone queue and evidence status |
| [product specification](docs/PRODUCT.md) | Customer workflow, scope and monetization |
| [architecture](docs/ARCHITECTURE.md) | Native stack and technical boundaries |
| [roadmap](docs/ROADMAP.md) | Sequenced milestones and exit gates |
| [quality contract](docs/QUALITY.md) | Non-negotiable acceptance tests and measurement |
| [visual direction](docs/DESIGN.md) | UI and rendering design standard |
| [launch plan](docs/LAUNCH.md) | Validation and first-month revenue plan |
| [handoff](agents/HANDOFF.md) | Current known state and next task |

## Getting started

Requirements: Swift 5.9 or later for the portable domain package; macOS with Xcode supporting iOS 17+ and XcodeGen for the native app. The project file is generated, not committed.

```sh
swift test
python3 scripts/agent_cycle.py check
python3 scripts/agent_cycle.py next
# macOS only:
xcodegen generate
open KeyAndFill.xcodeproj
```

For an unsigned simulator build after generation:

```sh
xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

Use a physical supported iPhone for camera/AR and thermal tests. Do not represent simulator output as real-device evidence.

## Contribution

Read AGENTS.md before changes. Keep main releasable; integrate small, reviewed, tested commits, respect branch protections and never force-push. Maintain the state, handoff and evidence with each completed work package. No background agent service is enabled by this repository: an authorized developer or coding agent must invoke each session. No credentials or paid services are required by the starter.

All rights reserved unless the owner explicitly selects a license.
