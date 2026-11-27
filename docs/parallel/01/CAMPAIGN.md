# Lane 01 — architecture and app composition

## Scope and baseline

- Destination: `finish/01-architecture-composition` only. Lane 20 owns canonical status and final integration; lane 19 owns CI.
- Inspected campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`, as requested pending lane 20's published BASE_SHA.
- Initial remote main: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`. Its later native accessibility-test correction and evidence are preserved on main for integration, not overwritten by this lane.
- Owned sources: `Sources/LightingCore/Scene.swift`, `App/StudioView.swift`, `App/KeyAndFillApp.swift`, `Package.swift`, `project.yml`, narrow new composition/contracts and corresponding tests.
- Read startup directives, current handoff/state, and PRODUCT/ARCHITECTURE/ROADMAP/QUALITY/DESIGN. `python3 scripts/agent_cycle.py check` passed structural validation; `next` reports M03 with editing/accessibility/persistence outstanding. These commands do not validate runtime acceptance.

## Work hypothesis

StudioView currently owns scene mutation, history, selection, project I/O reconciliation and feature presentation. Extract a tested scene/session boundary without changing photometry, persistence formats, feature algorithms, pricing or permissions. Commands must validate before mutation, maintain stable light UUIDs and SI units, preserve supported legacy schema migration and make undo coherent. Feature callbacks need both document identity and active presentation ownership; scene equality alone does not reject edit-away/undo-back results.

## Execution

Ten waves of ten real fresh-context workers. The acceptance worker in each wave also queues its nine specialist peers within the actual capacity of four concurrent agents (root, acceptance scheduler, two peers). It is counted once, not in addition to the ten. Every worker receives an isolated sparse Git worktree and private build directory. Reports are at most 800 tokens; briefs at most 2,000 tokens; the requested 12,000-token worker and 24,000-token coordinator contexts are working targets, not changes to platform limits. Checkpoint before context pressure.

Wave roles: acceptance, data invariants, API compatibility, implementation, concurrency, resource lifetime, feature integration, accessibility/privacy, platform/performance, independent review. The worker ledger records returned canonical IDs, actual tasks, input revisions, reports and outcomes. Reused followups do not increase counts. Root integrates serially, runs expensive builds serially, commits/pushes coherent checkpoints and verifies the remote branch SHA before removing preserved worktrees.

1. Trace composition/state ownership and concrete defects.
2. Publish invariants and minimal feature contracts.
3. Extract a cohesive StudioView responsibility with behavior checks.
4. Separate scene commands from rendering/presentation.
5. Reject stale project and asynchronous results.
6. Integrate available adapters through contracts.
7. Verify reference/room/comparison/AR/export/purchase navigation.
8. Verify portable and generated-target configuration.
9. Independently challenge duplicate state, lifecycle and undo.
10. Deliver precise integration handoff and evidence.

## Initial CI observation

Main's source run [45807031966](https://github.com/mirzotipi-wq/APP1/actions/runs/45807031966), source `b0d25eece01a3edb4c46e89cd487105d4d5a8cdd`, was inspected through GitHub on 26 November 2026. Core, simulator build/native tests and studio-optics jobs completed successfully; app-accessibility failed (`StudioAppAccessibilityUITests.swift:340`, light-Fill scrolling reachability). Room-precision, library-reference and studio-export were in progress at inspection. These observations belong to that source and are not acceptance of this branch. Baseline f150's separate native test compilation failure is retained in main's existing evidence.

## Resource and verification limits

Linux/Debian 13 host; no Apple SDK/Xcode is available locally. Initial `/workspace` volume had about 106 MiB free, so this lane uses `/tmp/keyfill-01-e08d`. Other work is left intact. A private portable Swift toolchain is being prepared separately; report actual results when available. Apple compilation, native UI execution, physical AR/StoreKit and device behavior remain unverified unless exact branch-source CI evidence is recovered. No prior pass transfers automatically to changed composition.

## Restored environment checkpoint

The initial environment was replaced. Current work uses `/tmp/keyfill-01-recovered`;
source and reports were preserved remotely and revalidated after restoration.
Two complete waves now account for 20 actual contexts. A full fresh Debug run
passed 392 tests, followed by nine affected session tests after the control
identity fix. See HANDOFF.md for exact source-specific evidence and remaining work.
