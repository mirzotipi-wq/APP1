# Key & Fill

**Plan the light. Recreate the shot.**

Key & Fill is a native iOS lighting studio for photographers and independent filmmakers. Import a reference, explore plausible lighting arrangements, design a scene in 3D, place equipment in a real room using AR, and export a practical lighting plan.

**Status:** interactive prototype / pre-alpha. Editable overhead plan, illustrative 3D, full-frame camera, numerical direct-light sphere and CPU neutral mannequin study (sphere has optional Metal and CPU fallback), optics/aim, recipes, undo/redo, color/exposure and vector PDF export. Versioned local multi-project library includes create/rename/duplicate/switch, archive/restore, explicit confirmed archived-record removal, atomic saves, legacy migration and explicit stale-save recovery as a new project ([99/99 portable tests](https://github.com/mirzotipi-wq/APP1/actions/runs/45277494136/artifacts/14868592104)). Manual room placement provides 1:1 center coordinates and bounds warnings, with precise session-only measurement entry (not AR). [104/104 portable room-source tests](https://github.com/mirzotipi-wq/APP1/actions/runs/45277775880/artifacts/14867622512); [105/105 precise-input portable tests](https://github.com/mirzotipi-wq/APP1/actions/runs/45278179961/artifacts/14868727773). Original 1024px app icon and privacy manifest verified in the unsigned Debug simulator bundle at f1933917; Release and device appearance pending. Exact source f1933917 passed 9/9 native unit tests and 14/15 native UI scenarios; reference import, project rename, guided confirmation, camera undo, recovery and manual room tests passed. A remaining meter reachability failure was reproduced from genuine simulator recording; a Scene Meter shortcut and scroll-to-panel repair are integrated pending native revalidation. In-process library transactions are serialized across store instances ([95/95 tests in Debug and Release on the latest UI source](https://github.com/mirzotipi-wq/APP1/actions/runs/45276657447/artifacts/14867307590); current visual refinement native verification pending). Reference comparison has session-only photo import, manual editable alternatives and descriptive SDR tones (not automatic inverse rendering). [Latest completed source CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45280053852) passed 109/109 portable Debug and Release and macOS package tests, with one native UI failure; [unsigned Debug artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45280053852/artifacts/14871393366). [Meter repair exact-source CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45330974433) passed 109/109 portable Debug/Release and unsigned Debug app; UI/Release pending. [Precision light editing CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45331531250) passed 114/114 portable Debug/Release and [unsigned Debug simulator build](https://github.com/mirzotipi-wq/APP1/actions/runs/45331531250/artifacts/14891548535); exact XYZ/cd/K entry with validated full domain, cancel/apply and undo integration; native UI/Release pending. [Projected modifier room geometry CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45331816997) passed 120/120 portable Debug and Release, zero failures: manual room placement now includes projected rectangular emitting-face boundaries, wall overhang and unavailable-aim warnings, not full equipment collision or AR sensing. Latest native source UI/Release checks pending. A scoped [privacy manifest and draft privacy review](docs/PRIVACY.md) are included with package integrity checks, not a completed privacy audit. [Earlier unsigned simulator build](https://github.com/mirzotipi-wq/APP1/actions/runs/45269453791/artifacts/14866090129) and [historical native tests](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/job/138016896671) verify prior builds only; current native SDK/Release, UI regression, actual PhotosPicker privacy, device GPU/performance, calibrated portraits, actual PDF share, AR, commerce and release gates remain outstanding. Name provisional pending trademark/App Store checks.


**Current checkpoint (2026-11-24):** [Executable revision ceeb4e98](https://github.com/mirzotipi-wq/APP1/commit/ceeb4e9880da6d0b9c5eb41613f6adc82a31e821) passed [139/139 portable Debug and Release](https://github.com/mirzotipi-wq/APP1/actions/runs/45347986031), all six actual render fixtures zero unsupported and six sphere shared-kernel parity fixtures passed. Optional session-only CPU neutral mannequin uses a 5248-triangle continuous face, direct-light BRDF, camera/lens, relative exposure and finite-source shadow visibility. Frontal and oblique renders inspected; [evidence](https://github.com/mirzotipi-wq/APP1/blob/main/docs/evidence/m02-mannequin-study-2026-11-24.md). Not calibrated human likeness or physical GPU performance. [Historical native](https://github.com/mirzotipi-wq/APP1/actions/runs/45337859919) Debug/Release and 10/10 native unit passed but serial UI timed out. [Interaction repair](https://github.com/mirzotipi-wq/APP1/commit/ad837f2e69898c6956f21519dee5a4795cdb4d32) and [three native UI shards](https://github.com/mirzotipi-wq/APP1/commit/cab674175233249e8785797d283e414da23765fd) integrated; current native verification pending. M01 remains active, no device-installable or App Store release. See [handoff](agents/HANDOFF.md) and [backlog](agents/BACKLOG.md).

**Previous photometry checkpoint (2026-11-24):** [Integrated source a13d8c96](https://github.com/mirzotipi-wq/APP1/commit/a13d8c96aabee2ef2ffd7a38c4119efcfb197d41) passed [132/132 portable Debug and Release](https://github.com/mirzotipi-wq/APP1/actions/runs/45337859919), zero failures. Room resizing preserves explicit subject position, supports localized entry and signed sub-millimeter readouts. Diagnostic lux correctly integrates partially front-facing softbox regions while retaining exact fully lit reference-grid agreement; [bounded numerical evidence](docs/evidence/m02-grazing-photometry-2026-11-24.md), not calibrated photography. [Historical camera precision native](https://github.com/mirzotipi-wq/APP1/actions/runs/45332530580) 9/9 native unit, 17/18 UI; all three new exact precision workflows passed, only older room-opening failed. [Unsigned historical Release](https://github.com/mirzotipi-wq/APP1/actions/runs/45332530580/artifacts/14893674637) verified bundle integrity. Latest SDK/UI/Release gates pending. See [handoff](agents/HANDOFF.md) and [backlog](agents/BACKLOG.md). M01 active; not a device-installable release.

**Previous integrated checkpoint (2026-11-24):** [Integrated source b859324f](https://github.com/mirzotipi-wq/APP1/commit/b859324f39e46d97622d066c7b8de5440c42e064) preserves precision in PDF/plain text and makes room placement a primary studio action. [Exact-source core](https://github.com/mirzotipi-wq/APP1/actions/runs/45334846248) passed 125/125 tests in Debug and Release. Current native SDK/UI/Release verification in progress. [Historical meter-source native](https://github.com/mirzotipi-wq/APP1/actions/runs/45330974433) passed meter interaction, 9/9 unit, 13/15 UI and both unsigned builds. Room/optics failures motivated latest fixes. [Historical unsigned Release bundle](https://github.com/mirzotipi-wq/APP1/actions/runs/45330974433/artifacts/14892951921) downloaded and archive/icon/privacy integrity checked. See [handoff](agents/HANDOFF.md) and [backlog](agents/BACKLOG.md). M01 active; not a device-installable or App Store release.

**Previous precision checkpoint (2026-11-24):** [Source 6eb42e2a](https://github.com/mirzotipi-wq/APP1/commit/6eb42e2ad23b6e139507c995b70cfc4f2cbcbba6) adds exact camera, optics and meter editing. [Core CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45332530580) passed 123/123 portable tests in both Debug and Release. [Unsigned Debug simulator build](https://github.com/mirzotipi-wq/APP1/actions/runs/45332530580/artifacts/14892328550) compiled and bundle inspection passed; native UI and Release verification remain pending. M01 remains active; this is not a device-installable release.

[Prototype guide](docs/PROTOTYPE.md) · [GitHub Actions](https://github.com/mirzotipi-wq/APP1/actions) · [Transaction and visual review evidence](docs/evidence/m01-transaction-visual-review-2026-11-23.md) · [Evidence-only scorecard](docs/evidence/quality-scorecard-2026-11-23.md)

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
