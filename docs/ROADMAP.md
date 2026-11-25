# Milestones

M02 and M03 use the owner-authorized **m02-m03-code-v2** scope dated 2026-11-25, detailed in [their acceptance contract](acceptance/m02-m03-code.md). Complete M02 from actual code evidence before promoting M03; complete M03 from its own evidence. Removed external validation is not a pass or a prerequisite transferred into another phase. Later milestones retain their existing future scope; none is completed or revised by this change.

| ID | Deliverable | Exit evidence |
|---|---|---|
| M01 | Buildable native shell, editable plan, validated domain and durable save | core tests, unsigned simulator build, save/reopen smoke |
| M02 | Lighting model contracts, interactive 3D studio, 1–3 lights and synthetic reference fixtures | analytic lux, deterministic render/parity matrix, bounded work and host benchmark; code acceptance only |
| M03 | Production editing: gestures, inspector, undo, multiple projects, migration, presets | ten repeatable editing workflows, library/relaunch flows, app accessibility checks and persistence; code acceptance only |
| M04 | Reference inference with multiple hypotheses; test-shot comparison | held-out evaluation, abstention, privacy |
| M05 | Real-room AR placement, manual fallback, diagram/PDF export | device tracking/error measurements, export checks |
| M06 | StoreKit, free/pro boundaries, privacy and pricing validation | sandbox cases, real feedback, privacy review |
| M07 | End-to-end beta, hardening, listing assets, release candidate | regression, device matrix, independent review and owner approval |

Detailed gates are in QUALITY.md. Do not mark a milestone pass by rewriting tests or checking boxes without evidence. Dependencies are machine-readable in agents/state.json. Work within available session resources. Optional extensions after 1.0: LiDAR scanning refinement, equipment library, advanced area-source rendering, crew share, additional scene types, calibrated camera workflows. Do not block the first release on optional scope.
