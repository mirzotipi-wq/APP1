# W03-10 independent review

Verified clean detached HEAD `966c9c21adbb685d82127e7f88981b74daf47e3d`. Inspected exact commits `bab813c5125b112c77ed367b184a3f5a88fae711` and `4a9f964f0b1748c883a43a2940452014767683e5`; both directly parented by frozen HEAD.

**ACCEPT both patches for integration; static review only.** Root owns target membership/execution.

**P2 defect:** frozen `StudioView.swift:1141–1146` sends end callbacks directly to `session.endEditing`, bypassing generation admission. First-save stable ownership lets an old end split a new same-control undo group. Correction forwards both phases through guarded `session.editChanged`. Verified captured generation in direct slider and `editHandler` paths. Added regression protects the session contract and already passes frozen session logic; it does not exercise View forwarding or prove native behavior.

`StudioSession.swift:113–145` rejects invalid IDs/generations/numbers before mutation, freezes origin/scale, retains height, clamps coordinates, and qualifies ends by light/generation. Selection/replacement/control handoff commit separate undo groups. `160–214` and `ProjectLibraryOperation.swift:115–134` preserve first-save control identity/history while rotating generation; reservation failure precedes gesture closure; staged adoption validates before publication. Accepted operations intentionally commit gestures even if later failing. Core cancel restores scene/history; session has no cancellation API.

EXACT04: 277 lines, six tests, actual session calls, load-only nil executor; portrait has three lights with index0 selected. Assertions meaningfully cover unchanged editor/drag, frozen cumulative scale, redo retention until commit, revisions, ownership and exact undo/redo counts. No mirrored algorithm, sleeps, apparent fixture/type/actor/autoclosure defect. No await occurs inside XCTest autoclosures.

Coverage limits: zero/out-and-back Plan, bounds/height, busy/load-blocked Plan, invalid/no-op replacement during drag, malformed receipt rollback, hosted View callback. No additional defect established.

Commit blob equals worker file SHA256 `817b934859c173ee96fa40ac374c0047636f0460bf0ca9085cb568d6f2aa6e3d`.

Actual checks: required instructions/state/docs; git HEAD/status/log/show; source tracing; hashes. No builds/tests/parsing/install/CI/push/source edits. Prior392/affected9 and syntax evidence are not transferred. Longer draft retained as `report-draft-01.md`.
