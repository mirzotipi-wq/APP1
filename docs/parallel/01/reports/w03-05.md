# W03-05 — concurrency

**ACCEPT, bounded static scope: no reachable concurrency blocker found.**

Verified detached HEAD `966c9c21adbb685d82127e7f88981b74daf47e3d`; clean tree. Required instructions/state/contracts read. No descendants, source edits, builds, tests, installs, pushes or CI changes.

## Trace and findings

- `App/StudioSession.swift:174–246`: MainActor reservation precedes ending edits. Task creation and handle/ID installation cannot interleave with task execution. Busy/stale attempts leave gestures intact. Mutation gates stay closed during `execute`.
- Cancel before `App/ProjectStore.swift:40–42` runs: check throws before storage preparation; session catch/defer finish the matching reservation and release its task. Cancel after synchronous persistence starts: no later cancellation check suppresses the receipt; session adopts it. Cancelling a sheet observer does not cancel the owned task (`App/ProjectLibraryView.swift:350–364,409–415`).
- No imagined store suspension: production persistence is synchronous; the process-wide lock covers load/migration, compare-and-replace and recovery through atomic write (`Sources/LightingCore/ProjectLibrary.swift:151–225`).
- Receipt ID/generation/project must match (`App/ProjectLibraryOperation.swift:103–106`). Validation precedes publication; failures/cleanup affect only matching requests/tasks. Adoption/cleanup contain no await. Inspected native consumers have no synchronous mutation callback reentering publication; native Observation remains unverified.

**Nonblocking API boundary:** load → edit → another current-generation `.load` succeeds and replaces dirty scene/history (`StudioSession:174–181`; `ProjectLibraryOperation:110–114`). UI reachability is unproved: `StudioView:276` requires `!loaded`; Retry appears only while blocked (`93–106`), with busy/generation guards. Recommend session admission restricted to initial load/blocked retry plus a sequential duplicate-load regression. Concurrent duplicate load is already rejected.

## Evidence limits and commands

Inspected `NativeTests/StudioSessionTests.swift`, `NativeTests/ProjectStoreOperationTests.swift:152–292`, and core parallel-store tests. Session tests cancel an observer; store tests cancel operations. Add session+real-store cancellation coverage. No runtime result claimed. Historical 392 Debug predates identity change; affected nine followed; native syntax was parsing only. No later result transferred. Injected malformed receipts remain separate hardening; production validates envelopes.

Commands: `git rev-parse HEAD`; `git status --short`; `git branch --show-current`; `git log -3 --oneline`; `rg --files`, `rg -n`, `cat`, `nl -ba`, `sed -n`, `wc -l`. `python3 scripts/agent_cycle.py check` reported valid references; `python3 scripts/agent_cycle.py next` reported M03 gates outstanding. Structural checks establish no runtime result.
