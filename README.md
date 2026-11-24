# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting studio for photographers and independent filmmakers. Import a reference, explore plausible lighting arrangements, design a scene in 3D, plan measured room placement manually, and export a practical lighting plan. AR placement is a planned capability.

**Status: interactive prototype / pre-alpha.** The current app provides an editable overhead plan, illustrative 3D and camera views, a numerical sphere study with optional Metal, a CPU neutral mannequin study, precise light/optics/camera controls, recipes, undo/redo, and vector PDF/text export. Reference comparison uses a session-only photo derivative, descriptive SDR tonal statistics and manually guided starting rigs. Manual room placement supplies calculated coordinates, footprint warnings and shareable committed measurement notes; AR tracking is not implemented.

The local library supports named projects, duplication, archive/restore, explicit archived-record deletion, legacy migration, optimistic conflict protection and recovery of unsaved edits. Editable project copies preserve scene settings outside the library, including at the 64-project limit; importing creates a separate project. Reference photos, room measurements and undo history are not included in those copies.

**Current integrated source (2026-11-24):** [`95e9c24`](https://github.com/mirzotipi-wq/APP1/commit/95e9c2446b7bb05e6df38d103063b4254bb07c92) passed **257/257 portable tests in each configuration and 28/28 Python checks**, both locally and remotely, plus **both unsigned simulator builds and all 83 native methods**. Those native results include **15 tracking, three UIKit slider and 15 project-operation methods**. The native build gate now passes at this exact source; **persistence smoke, the actual optics gesture and complete UI acceptance remain unverified**. At the approximately12:57UTC observation, library and room UI were running and studio/export was queued. The **23 UI scenarios** remain an authored inventory. [Checkpoint11](docs/evidence/2026-11-24-autonomous/checkpoint-11.md) preserves the earlier pending snapshots and local results; [actual source11 native evidence](docs/evidence/2026-11-24-autonomous/native-result-95e9c24.md) records the later pass.

Source 11 introduces explicit native slider touch sessions with captured owners and project identities, final-value ordering and lifecycle closure. The original optics Undo expectation remains **0.6m**, with stronger control-identity and enabled-state checks. It also separates overhead captions from fixed equipment markers, preserves their projected centers and supplies a bounded fallback for crowded scenes. Both packets were independently reviewed; actual gesture completion and native crowded/large-text/accessibility output still need verification. Projects-readiness diagnostics run only after the original **15-second** enabled check fails; its predicate and deadline are unchanged. [Slider evidence/review](docs/evidence/2026-11-24-autonomous/slider-tracking-review.md), [plan evidence/review](docs/evidence/2026-11-24-autonomous/plan-label-review.md).

**Historical source 10 finalized with failure.** [`5cd7eb4`](https://github.com/mirzotipi-wq/APP1/commit/5cd7eb4181251d22a3a182c2cb3b04968cf26dd6) passed both unsigned builds and **65/65 native methods**, including all **15 project-operation methods**. Its UI shards started 23 scenarios and completed 22: **20 passed, two failed and one was interrupted**. Library/reference passed 8/9, failing the initial Projects-readiness wait before delete work; room/precision passed 5/5. Studio/export completed eight with seven passes and one original optics failure (**expected0.6m, observed2.25m**); bust switching was progressing when the 32-minute step deadline interrupted it. No finalized studio result bundle exists. Both export scenarios, camera, corrupt-storage, meter, recipe and study-frame passed. [Full source-10 results](docs/evidence/2026-11-24-autonomous/native-result-5cd7eb4.md), [retained final studio evidence](docs/evidence/2026-11-24-autonomous/source10-studio-final/result.md).

The retained asynchronous library implementation performs complete read, migration, validation, conflict comparison, encoding and atomic write operations on a serial worker. Parent-owned operations capture the expected library and scene, guard stale callbacks and reconcile committed results after a requesting sheet disappears. First ordinary saves retain history. Its **15 Debug / 12 Release focused tests** and later **15/15 actual Apple operation methods** remain separate from full core counts. The actual source-10 large-library load/save/browse/relaunch scenario passed, while the first Projects-readiness failure remains unexplained. These observations establish no device speedup or universal presented-sheet/cancellation guarantee. [Implementation evidence](docs/evidence/2026-11-24-autonomous/async-library-correction.md), [independent review](docs/evidence/2026-11-24-autonomous/async-library-review.md).

**Finalized historical source-9 result: failure.** [`3b2a4ce`](https://github.com/mirzotipi-wq/APP1/commit/3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18) passed both unsigned builds, **50/50 native methods**, core **251/251 each configuration plus28 Python**, and **21/22 UI scenarios**: library/reference8/8, room/precision5/5 and studio/export8/9. The sole failure was the unchanged optics Undo assertion: **expected0.6m, observed1.3m**. Both export scenarios and camera, corrupt-storage, meter, recipe, study-frame and bust-switch scenarios passed. All eight adapter unit methods also passed, so their helper coverage did not establish the actual dragged-control behavior. The earlier room failure remains unexplained: source9 passed without source10's later explicit status label. These historical results do not certify source 11. [Final source9 results](docs/evidence/2026-11-24-autonomous/native-result-3b2a4ce.md), [actual studio log](docs/evidence/2026-11-24-autonomous/3b2a4ce-studio-job.log).

The retained export uses an immutable snapshot in one sheet; slider writes capture their owner before the first changed value. The original native optics Undo, export and relaunch assertions remain. [Export correction](docs/evidence/2026-11-24-autonomous/export-native-correction.md), [slider correction](docs/evidence/2026-11-24-autonomous/slider-native-correction.md). Earlier source `816e712` passed both unsigned builds and 42/42 native methods, but its partial UI artifacts contain a real room-status failure, an archived-deletion pass and interrupted methods. Historical failures remain visible.

**Unintegrated follow-ups:** KF-025 remains **on HOLD** after the confirmed 4.43449% internal-cell linear-light jump across a 2e-8 cut change; noisy paired timing also failed to establish acceptable cost. This is a numerical counterexample, not observed native flicker. Its [report](docs/evidence/2026-11-24-autonomous/grazing-study-report.md), [review](docs/evidence/2026-11-24-autonomous/grazing-study-review.md), patch and raw failures are retained. The guide and CI-budget working changes, and a separate two-screen native accessibility-audit candidate under review, remain outside tested source11 and its counts. KF-036 is now integrated in source 11 as P21/T41, with native visual/selection/accessibility acceptance still open.

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
