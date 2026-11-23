# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting studio for photographers and independent filmmakers. Import a reference, explore plausible lighting arrangements, design a scene in 3D, place equipment in a real room using AR, and export a practical lighting plan.

**Status:** foundation / pre-alpha. The current starter implements an editable overhead lighting plan and a small tested-domain-design lighting model; physical 3D rendering, reference inference, AR, purchases and release readiness are NOT implemented or verified. The name is provisional pending trademark and App Store checks.

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
