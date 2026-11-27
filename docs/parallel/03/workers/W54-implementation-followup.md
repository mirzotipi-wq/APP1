# W54 — implementation follow-up (same worker)

- Runtime/canonical ID: `/root/wave06/w54_implementation`; no additional worker.
- Input SHA: `74f7584b4e474c752ec0939add6b7522ba98094f`.
- Private tree/output: `/tmp/keyfill03-7f4b/workers/W54-implementation` / `/tmp/keyfill03-7f4b/builds/W54-implementation`.
- Source SHA256: `45a899619938e4a9c719f42af9c37d79e685c3a98d51465ca1995cc260595fc6`.
- Tests SHA256: `a68a38abce16baff2eee55c175bd3874664d8707d6c358d04282691455407c99`.

Root explicitly expanded this worker's scope to canceled pre-start attempts. After runtime reset removed the private tree, root recreated worker-control and W54 recreated its detached tree sequentially. The persisted original paused patch was reapplied and its original hash verified; it remains unchanged.

`begin()` now returns a fresh unused ticket when the caller is already cancelled, preserving the live current ticket. The SwiftUI task returns before `begin()` and frame clearing when already cancelled. One new ControlledRender test holds a live request, cancels a MainActor attempt before yielding, awaits that attempt, then finishes the live request. It asserts cancellation was present, the cancelled renderer never ran and the live result published exactly once. All nine original tests remain byte-preserved.

`git diff --check` and reverse-application checks for supplemental/combined patches exited 0. Source comparison confirmed only the cancellation comment and two guard lines were added beyond the original paused candidate. No test or build ran. Baseline failure and candidate success remain expected, UNRUN outcomes; root owns execution. This is a pipeline-seam regression, not an observed SwiftUI scheduling reproduction. Initial missing-tree lookup failed before successful recovery; token counter unavailable.

- [Supplement after original paused patch](wave06-evidence/W54-cancelled-attempt.patch).
- [Combined patch against input SHA](wave06-evidence/W54-paused-and-cancellation.patch).
- [Test-only patch for baseline witness](wave06-evidence/W54-cancelled-attempt-test.patch).
- [Hashes and command receipts](wave06-evidence/W54-followup-receipts.json).
