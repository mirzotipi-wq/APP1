# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting studio for photographers and independent filmmakers. Import a reference, explore plausible lighting arrangements, design a scene in 3D, plan measured room placement manually, and export a practical lighting plan. AR placement is a planned capability.

**Status: interactive prototype / pre-alpha.** The current app provides an editable overhead plan, illustrative 3D and camera views, a numerical sphere study with optional Metal, a CPU neutral mannequin study, precise light/optics/camera controls, recipes, undo/redo, and vector PDF/text export. Reference comparison uses a session-only photo derivative, descriptive SDR tonal statistics and manually guided starting rigs. Manual room placement supplies calculated coordinates, footprint warnings and shareable committed measurement notes; AR tracking is not implemented.

The local library supports named projects, duplication, archive/restore, explicit archived-record deletion, legacy migration, optimistic conflict protection and recovery of unsaved edits. Editable project copies preserve scene settings outside the library, including at the 64-project limit; importing creates a separate project. Reference photos, room measurements and undo history are not included in those copies.

**Current integrated source (2026-11-24):** [`5cd7eb4`](https://github.com/mirzotipi-wq/APP1/commit/5cd7eb4181251d22a3a182c2cb3b04968cf26dd6) has actual remote **251/251 Debug,251/251 Release and28/28 Python passes**, **both unsigned simulator builds**, and **65/65 native methods**, including **15/15 project-library operation tests**. [Checkpoint10](docs/evidence/2026-11-24-autonomous/checkpoint-10.md) preserves the separate exact local verification. The one job observation at11:54:07–11:54:14 UTC found library/reference and room/precision UI still running and studio/export queued. **Persistence smoke and complete UI regression remain unverified.** [Actual source10 logs and results](docs/evidence/2026-11-24-autonomous/native-result-5cd7eb4.md).

The new library implementation moves complete read, migration, validation, conflict comparison, encoding and atomic write operations to a serial worker. Parent-owned operations capture the expected library and edited scene, guard stale callbacks, show progress and adopt committed results even if a requesting sheet disappears. First ordinary saves retain edit history; successful project switches adopt their new scene deliberately. Independent review reproduced and corrected a missing/malformed UI-test UUID isolation regression. **15 Debug / 12 Release focused tests** passed separately from the 251 core tests; three fixture/isolation methods are DEBUG-only. Those15 operation methods subsequently passed on the Apple runner as part of65/65 native tests. Controlled barriers establish ordering and adoption, not device latency or presented SwiftUI behavior. [Implementation and actual evidence](docs/evidence/2026-11-24-autonomous/async-library-correction.md), [independent review](docs/evidence/2026-11-24-autonomous/async-library-review.md).

Source 10 also makes the room status's accessibility text explicit, retains diagnostic details in UI failure logs, and preserves an active main verification run while the newest source waits. At the observed source-10 push, source 9 remained active and source 10 was pending. Current room behavior and asynchronous save/relaunch still require completed UI acceptance. The65 native methods now have actual passing results; **23 authored UI scenarios** remain an inventory while the shards run.

**Finalized historical source-9 result: failure.** [`3b2a4ce`](https://github.com/mirzotipi-wq/APP1/commit/3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18) passed both unsigned builds, **50/50 native methods**, core **251/251 each configuration plus28 Python**, and **21/22 UI scenarios**: library/reference8/8, room/precision5/5 and studio/export8/9. The sole failure was the unchanged optics Undo assertion: **expected0.6m, observed1.3m**. Both export scenarios and camera, corrupt-storage, meter, recipe, study-frame and bust-switch scenarios passed. All eight adapter unit methods also passed, so their helper coverage did not establish the actual dragged-control behavior. The earlier room failure remains unexplained: source9 passed without source10's later explicit status label. These historical results do not certify the new actor. [Final source9 results](docs/evidence/2026-11-24-autonomous/native-result-3b2a4ce.md), [actual studio log](docs/evidence/2026-11-24-autonomous/3b2a4ce-studio-job.log).

The retained export uses an immutable snapshot in one sheet; slider writes capture their owner before the first changed value. The original native optics Undo, export and relaunch assertions remain. [Export correction](docs/evidence/2026-11-24-autonomous/export-native-correction.md), [slider correction](docs/evidence/2026-11-24-autonomous/slider-native-correction.md). Earlier source `816e712` passed both unsigned builds and 42/42 native methods, but its partial UI artifacts contain a real room-status failure, an archived-deletion pass and interrupted methods. Historical failures remain visible.

**Unintegrated follow-ups:** KF-025 is **on HOLD** after a confirmed4.43449% internal-cell linear-light jump across a2e-8 cut change; noisy paired timing also failed to establish acceptable cost. This is a numerical counterexample, not observed native flicker. Its [report](docs/evidence/2026-11-24-autonomous/grazing-study-report.md), [review](docs/evidence/2026-11-24-autonomous/grazing-study-review.md), patch and raw evidence are retained. KF-036 addresses the actual source9 Light1/Fill plan-label overlap documented in the [visual review](docs/evidence/2026-11-24-autonomous/source9-library-visual-review.md); its isolated candidate passed6/6 Debug and6/6 Release plus syntax only, and is now independently approved and applied in the working tree, uncommitted for the next source packet. Native acceptance and integration remain outstanding. Neither candidate adds a completed package or task.

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
