# W03-06 — LIFETIME

Verified HEAD: `966c9c21adbb685d82127e7f88981b74daf47e3d`; isolated worktree clean before and after inspection.

**Recommendation: accept this focused static lifetime review. No blocking lifetime defect demonstrated. Native acceptance remains pending.**

Performed: `git rev-parse HEAD`, status/log inspection, required AGENTS/protocol/current handoff/state/product/architecture/roadmap/quality/design/lane contracts reading; actual session, view, store, app, sheet-task, editor/history, operation-state and relevant test inspection. No build, parsing, tests, installation, source changes, CI or status edits. Historical 392 Debug predates the control-identity fix; subsequent nine-session evidence and parsing are not transferred to this review.

## Verified ownership paths

- `StudioSession.swift:38–55,181–246`: session → operationTask → captured self is intentional while `execute(request)` settles. Success publishes the staged adoption, which clears the pending request; errors call matching `finish(request)`. The shared defer clears task and task ID on either exit. Main-actor task creation/handle assignment has no intervening suspension. The executor captures the store, not the session; `ProjectStore.swift:7–9,40–61` stores configuration/file-store state with no session callback. No reachable post-settlement cycle was found.
- Concrete cancellation trace: sheet reserves synchronously → parent task performs store transaction → sheet observer disappears/cancels → parent still adopts receipt → defer clears handle. `ProjectStore.swift:41` checks cancellation before synchronous work, with none after write; `ProjectLibraryView.swift:350–364,394–425` and `RecoveryCapacityView.swift:157–174` await the parent task. Failure likewise releases reservation/handle, preserving current edits. Retention during unresolved execution is not evidence of a leak.
- Per-window construction is explicit: `KeyAndFillApp.swift:14–17` creates `StudioView`, whose `@State` owns `StudioSession` (`StudioView.swift:6`); its default store is instance-owned. Only entitlements/preferences are app-shared here. Disk sharing uses the persistence contract; no shared editor/session singleton was found.
- Plan release: accepted reservation ends the edit and clears `planDrag` before spawning work (`StudioSession.swift:181–184`), including when execution subsequently fails. Changed selection/replacement clears it (`70–84`); another control finishes it (`99–107`); matching gesture end clears it (`140–146`). `StudioView.swift:279–284` closes it on inactive phase, mode/selection change and disappearance. Rejected stale/busy reservation intentionally preserves the frozen scene/scale. History may retain committed scenes for undo, bounded by `SceneEditHistory.swift:9,93–99,136–138`; clearing Plan is not a claim that all scene values are immediately deallocated.
- Both task fields have Darwin `@ObservationIgnored` (`StudioSession.swift:42–49`). Native macro/runtime behavior was not executed.

## Evidence limits

Tests inspected cover successful handle release, observer cancellation, load/save failures, and Plan reservation/end behavior (`StudioSessionTests.swift:39–273`). Its lifetime test uses an injected executor and asserts only weak **session** release after success; despite its name, it does not directly assert store release. Failure deallocation, actual multiwindow teardown, scene lifecycle and focus require fresh SDK/runtime evidence. These are coverage limitations, not a demonstrated leak or a new severity-ranked product defect.
