# W03-10 independent review

Frozen HEAD verified: `966c9c21adbb685d82127e7f88981b74daf47e3d`; detached, clean read-only tree. Inspected exact commits `bab813c5125b112c77ed367b184a3f5a88fae711` and `4a9f964f0b1748c883a43a2940452014767683e5`, both direct children of frozen HEAD.

**Recommendation: ACCEPT both patches for integration, subject to root-owned target membership and execution. Static acceptance only.** Frozen View requires the correction below.

## Verified behavior and defect

- `StudioSession.swift:113–145`: admission precedes mutation; unknown/unselected IDs, stale generation, nonfinite translation and invalid scale preserve editor/drag. Origin and scale are captured once; cumulative offsets use that source, retain height and clamp coordinates. Light/generation-qualified ends cannot close another drag. Selection/replacement/control handoff commit separate history groups.
- `StudioSession.swift:160–164,181–214` and `ProjectLibraryOperation.swift:115–134`: first save changes generation while preserving control owner/history/selection. Reservation failure occurs before closing the gesture. Adoption stages operation/editor/saved validation before publication; validation failure retains live state and clears only its matching reservation. Accepted operations intentionally commit the open gesture; failure does not resume it. Core cancel restores scene and history together (`StudioEditorState.swift:74–80`), but there is no session cancellation API.
- **P2, frozen `StudioView.swift:1141–1146`:** a delayed end with the old generation bypasses admission via `session.endEditing(owner:)`. Stable first-save owner permits it to split a new same-control edit. Exact correction forwards both phases through `session.editChanged`, whose line100 rejects stale generations. Captured generation survives the direct slider path and `editHandler`; reviewed corrected call path statically.

## Test challenge

EXACT04 adds only the stated 277-line/six-method file. Commit blob and worker file SHA256 both equal `817b934859c173ee96fa40ac374c0047636f0460bf0ca9085cb568d6f2aa6e3d`.

Tests call real session orchestration, with a load-only nil executor; portrait really has three lights and selects index0. They check full editor components, frozen drag, cumulative scale, redo retention until commit, owner rejection, revision identity, exact undo/redo sequences and absence of duplicate entries. No mirrored algorithm, sleeps, asynchronous XCTest autoclosures, or apparent actor/type errors found by inspection. MainActor helper/assertions and awaited load follow existing conventions.

Correction's added regression correctly verifies stable owner, changed generation and two updates in one undo. It **already passes the frozen session contract**; it does not exercise the faulty View forwarding. Native adapter behavior remains unverified.

Coverage gaps: zero/out-and-back Plan, bounds/height, busy/load-blocked Plan admission, invalid/no-op replacement during drag, malformed-receipt rollback, hosted View callback. These are limits, not observed new defects.

Actual checks: required instructions/state/docs, git HEAD/status/log/show, source tracing, and SHA256 comparison. No source edits, builds, tests, parsing, installs, CI, or pushes. Prior392/affected9 and syntax-only evidence are not transferred.
