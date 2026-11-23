# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting studio for photographers and independent filmmakers. Import a reference, explore plausible lighting arrangements, design a scene in 3D, place equipment in a real room using AR, and export a practical lighting plan.

**Status:** interactive prototype / pre-alpha. Editable overhead plan, illustrative 3D, full-frame camera, numerical direct-light sphere study with optional Metal and CPU fallback, optics/aim, recipes, undo/redo, color/exposure and vector PDF export. Versioned local multi-project library includes create/rename/duplicate/switch, archive/restore, explicit confirmed archived-record removal, atomic saves and legacy migration. Reference comparison has session-only photo import, manual editable alternatives and descriptive SDR tones (not automatic inverse rendering). [92/92 Debug and Release, zero failures](https://github.com/mirzotipi-wq/APP1/actions/runs/45274350597/artifacts/14865369722). [Latest source CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45274350597) is not yet full native verification. [Earlier unsigned simulator build](https://github.com/mirzotipi-wq/APP1/actions/runs/45269453791/artifacts/14866090129) and [historical native tests](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/job/138016896671) verify prior builds only; current native SDK/Release, UI regression, actual PhotosPicker privacy, device GPU/performance, calibrated portraits, actual PDF share, AR, commerce and release gates remain outstanding. Name provisional pending trademark/App Store checks.

[Prototype guide](docs/PROTOTYPE.md) · [GitHub Actions](https://github.com/mirzotipi-wq/APP1/actions) · [Latest native repair and library evidence](docs/evidence/m01-native-repair-library-removal-2026-11-23.md) · [Evidence-only scorecard](docs/evidence/quality-scorecard-2026-11-23.md)

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
