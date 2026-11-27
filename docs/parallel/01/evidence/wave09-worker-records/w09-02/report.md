# W09-02 — real committed-save regressions

Implemented commit `d3946bc5369bb00459c161e4397d9364dccba2bc` on frozen `f33a399f8ba21618320ce50aed7981450a9703a7`. Owns only new `NativeTests/StudioCommittedSaveTests.swift`; worktree clean. Inspected root checkpoint `bed58c338f9f53758c611b8642241c3ec7697505` differs from frozen input only under `docs/`.

Two cases use actual `StudioSession`, real temporary `ProjectStore(arguments: [], environment: [:])`, and an injected executor that calls `store.perform` before pausing only saves. One cancels the awaiting observer; the other cancels the returned session task after disk commit. A lock-protected continuation latch is idempotent and handles release before entry; XCTest waits and failure-cleanup joins are bounded at five seconds each, with no sleeps or blocked worker threads.

Assertions inspect disk before adoption, then check task/reservation cleanup, one receipt/transaction, library/saved/disk agreement, first-save generation advance, unchanged workspace/context/selection and post-reservation editor/history, stale-generation callback rejection, continued Room edits and exact undo/redo boundaries. The existing weak-lifetime test is not duplicated.

Validation: structural `agent_cycle.py check` and `next`, staged `git diff --check`, and Swift 6.0.3 syntax parsing exited zero. No builds, runtime tests, pushes or Package.swift edits were performed. Root must register the file explicitly in Package.swift and execute the two cases; Apple compilation/runtime acceptance remains unverified. Earlier 431-case evidence does not cover these new tests.

`receipt.json` records exact source/blob hashes and command outcomes; `source.patch` preserves the scoped change. No production defect or production change is claimed.
