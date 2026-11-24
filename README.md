# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting studio for photographers and independent filmmakers. Import a reference, explore plausible lighting arrangements, design a scene in 3D, plan measured room placement manually, and export a practical lighting plan. AR placement is a planned capability.

**Status: interactive prototype / pre-alpha.** The current app provides an editable overhead plan, illustrative 3D and camera views, a numerical sphere study with optional Metal, a CPU neutral mannequin study, precise light/optics/camera controls, recipes, undo/redo, and vector PDF/text export. Reference comparison uses a session-only photo derivative, descriptive SDR tonal statistics and manually guided starting rigs. Manual room placement supplies calculated coordinates, footprint warnings and shareable committed measurement notes; AR tracking is not implemented.

The local library supports named projects, duplication, archive/restore, explicit archived-record deletion, legacy migration, optimistic conflict protection and recovery of unsaved edits. Editable project copies preserve scene settings outside the library, including at the 64-project limit; importing creates a separate project. Reference photos, room measurements and undo history are not included in those copies.

**Current integrated source (2026-11-24):** [`3b2a4ce`](https://github.com/mirzotipi-wq/APP1/commit/3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18) passed **251/251 portable tests in Debug and Release** and **28/28 Python checks** against its exact immutable source tree. [Checkpoint9](docs/evidence/2026-11-24-autonomous/checkpoint-9.md) records source identity, counts and raw-log hashes. Its [workflow](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521) was pending at10:44:03UTC; all current native acceptance remains unverified.

The integrated export correction uses one sheet containing an immutable scene snapshot and local format selection. Slider-origin writes begin their owned edit before the first value change, preserving a whole drag as one Undo command. The actual adapter plus unchanged history tests passed **23/23 in each Linux configuration**, separately from the251 core tests; this isolated suite does not compile SwiftUI. The original native optics expectation and export preparation timeouts remain. [Export correction](docs/evidence/2026-11-24-autonomous/export-native-correction.md), [slider correction](docs/evidence/2026-11-24-autonomous/slider-native-correction.md), [independent review](docs/evidence/2026-11-24-autonomous/export-slider-review.md).

Historical source816e712 subsequently passed both unsigned builds and **42/42 native methods**, including all three SceneKit projection/transaction methods, as well as core251/251 in both configurations and28 Python. Its partial UI artifacts retain one real room-status assertion failure, one archived-deletion pass and two interrupted methods; the remaining UI scenarios did not run. There is no complete UI pass. That source-specific success does not certify3b2a4ce. The asynchronous library-work packetKF-032 is now in progress and is outside the current source and test results.

**Preserved native failures:** Historical source `ff8b683` completed [workflow 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829) with failure: native methods **40/42**, library/reference **7/8**, room/precision **4/5**. Studio/export started nine scenarios; eight completed with four passes and four failures, and bust switching was interrupted by the 32-minute test-step timeout. No finalized studio/export xcresult exists. Export stalls, app termination and optics Undo failures prompted the corrections above. Corrupt-storage, meter, recipe and actual study-frame scenarios passed. Its successful unsigned builds, native image/PDF tests and six simulator Metal parity fixtures remain scoped to that source. [Native evidence](docs/evidence/2026-11-24-autonomous/native-results-ff8b683.md), [final studio/export results](docs/evidence/2026-11-24-autonomous/checkpoint-8.md).

[Historical native source cab67417](https://github.com/mirzotipi-wq/APP1/actions/runs/45346996294) passed both unsigned simulator builds, 10/10 native unit tests and 7/7 library/reference UI tests. Its room/precision shard passed the two room tests then timed out during precision; that is not a complete regression pass. Current changes require their own native evidence. [The handoff](agents/HANDOFF.md) retains previous revisions, failures, artifacts and pending work; [the evidence ledger](agents/evidence.json) separates historical observations from current gates.

**M01 remains active.** Physical-device accessibility, GPU/performance/thermal testing, calibrated portrait rendering, automatic reference reconstruction, AR, StoreKit, customer validation, signed distribution and owner release approval remain outstanding. No App Store or physical-device release is available. The product name remains provisional.

[Prototype guide](docs/PROTOTYPE.md) · [GitHub Actions](https://github.com/mirzotipi-wq/APP1/actions) · [Backlog](agents/BACKLOG.md) · [Privacy draft](docs/PRIVACY.md) · [Current evidence-only quality review](docs/evidence/2026-11-24-autonomous/quality-review.md)

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
