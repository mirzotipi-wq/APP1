# M03 project library groundwork — 2026-11-23

M01 remains active; independent M03 groundwork only. Baseline 9b939bd2a711c5ea7c62f20defb633ce0f1049e6.

## Source and contract

- b8d0ef90a690e80686fd6821981ec97da163dfa4: new versioned project-library snapshot; independent UUIDs; normalized names up to 80 characters; 64 projects including archived; 8 MiB bounded reads/writes; atomic replacement, stale snapshot detection, current scene validation. Legacy portrait.json is migrated once on load, preserving exact original bytes. Invalid new library is never replaced with legacy data. Archive/restore is reversible, not permanent deletion. Optimistic write checking covers sequential app windows, not simultaneous external writers.
- 767d8b527ff2bcb266b6ca72298119b7557206e2: live binding, clear name affordance, protected-data unavailable view; UI waits and archive/restore test. Source review is not Apple SDK validation.
- Save remains explicit. While dirty, the Projects sheet permits saving but prevents mutation/switch. A successful switch resets undo/redo, edit state, selection and view mode. Exports use the active project name.

## Actual verification

[GitHub Actions core 138016895770](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/job/138016895770) at b8d0ef90a690e80686fd6821981ec97da163dfa4, Ubuntu 24.04.5 LTS x86_64, Swift 6.4.2 RELEASE. Commands:
- python3 scripts/agent_cycle.py check; python3 scripts/agent_cycle.py next — passed (M01 active, native_build/persistence_smoke outstanding).
- swiftc -frontend -parse App/*.swift UITests/*.swift NativeTests/*.swift — passed (syntax only).
- swift test --jobs 2 — 78 tests, zero failures.
- swift test --configuration release --jobs 2 — 78 tests, zero failures.
- Ten ProjectLibraryTests: first save/independent projects, legacy migration bytes, corrupt legacy, corrupt library, stale snapshots, duplicate/archive/restore, invalid names/IDs/scenes, capacity, malformed metadata/future schema, oversized/nonregular path. All passed Debug and Release.
- 3 generated study fixtures, 0 unsupported pixels each. Six host Float32 parity fixtures passed, max absolute channel difference 1, none >4, near-field invalid 84/84. No Metal device execution.
- Raw logs and fixtures: [core-test-log](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/artifacts/14862957971).

[Follow-up CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45267427132): core job 138017944413 in progress, simulator 138017945122 queued at observation. No native current build, UI results, screenshots, actual PDF sharing or device evidence. Prior [simulator artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45262428316/artifacts/14862742238) is from d6407acc324bedfc5abe946565e6b4f60cd2a3ba, not the project library revision.

## Remaining risks / release gates

Whole-library snapshot is bounded and uses atomic replacement but device interruption, low storage, multiwindow interaction and accessibility are unverified. Archive has no permanent purge yet; future explicit deletion and backup/recovery need owner-aligned privacy UX and tests. Legacy file is preserved, not synchronized backwards on downgrade. Current sheet has no search, custom thumbnails or iPad-specific layout. No calibrated portrait rendering, reference inference, AR, StoreKit, physical performance or customer evidence. No milestone completion claimed.
