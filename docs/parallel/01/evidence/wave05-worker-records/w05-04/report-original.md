# W05-04 — Studio feature presentation core

## Delivery

- Frozen input: `ea83fa165916aaa2f55ddb88f6430b8a59ce5565`.
- Commit: `40f488bcc4f603c33c95cac78ee038b7c5cabd3e`.
- Worktree: `/workspace/scratch/e08d5190f17c/workers/w05-04/tree` (detached, retained).
- Assigned build directory: `/workspace/scratch/e08d5190f17c/workers/w05-04/build`; unused.
- One real worker context; no children, root edits, builds, or pushes.

Implemented the agreed public `StudioFeatureDestination` cases and
`StudioFeaturePresentation` value. The presentation owns its destination and
`StudioFeatureSession`, exposes the immutable context and receipt projections,
and delegates admission, revision acknowledgment, and dismissal to the existing
session policy. It imports Foundation only and introduces no schema, Codable,
UI, Observation, photo, network, or purchase behavior.

Documentation requires callbacks to consult the live parent-owned value. Value
copies retain their state; dismissing or replacing one value cannot revoke
another copy. The logical workspace identity survives first save. Dismissal
retains the snapshot until the parent clears the matching optional payload,
checking identity so old teardown cannot clear a newer presentation.

## Concrete defect fixed

Frozen `StudioFeatureSession.didApply` changed `acceptedRevision` after
`dismiss()`. A narrow `isPresented` guard now preserves a retired receipt. The
earlier behavior did not restore `isPresented` and was not a callback-admission
revival. The presentation delegates this protection rather than duplicating it.

Only these assigned files changed:

- `Sources/LightingCore/StudioFeaturePresentation.swift` (new).
- `Sources/LightingCore/StudioFeatureContext.swift` (guard and its comment).

## Actual checks

Read AGENTS, operating protocol, canonical state/handoff, product, architecture,
roadmap, quality, design, and lane 01 handoff/interfaces. The required canonical
documents read in the shared checkout had no diff from the frozen input.
Inspected existing core feature/editor tests and the frozen StudioSession API.

Commands executed in the detached worktree:

- `python3 scripts/agent_cycle.py check`: passed state structure/evidence-reference
  validation only; explicitly not test-truth or release verification.
- `python3 scripts/agent_cycle.py next`: reported historical canonical M03 and
  editing/accessibility/persistence gates; not used as lane authority.
- `git diff --cached --check`: passed before commit.
- `git diff HEAD^ HEAD --check`: passed after commit.
- `git status --short`: clean after commit.

No Swift compilation, parsing, package tests, native tests, or Apple runtime
checks ran in this worker, as instructed. Prior 413 Debug results remain
frozen-source historical evidence, not evidence for this commit. Root owns the
serial integrated build and tests.

## Coverage and limitations

Peer02 was notified to cover live owner admission, immutable snapshots, logical
first-save identity, busy rejection, and stale receipts through StudioSession.
Peer02 keeps its file focused on orchestration; direct post-dismissal
`didApply` receipt immutability still needs a core-level assertion by the
integration owner. No test files were added outside this worker's scope.

The value alone cannot prove that a callback consults the live parent, that the
parent supplies `workspaceResetID`, or that route-specific target-lux validation
is correct. Those are the root-owned composition contracts. Native routing is
deferred to wave 6. Reference still consumes its draft before its Void callback;
arrangement/lux still dismiss after Void callbacks. This core patch does not
repair those owner limitations. Apple UI/Observation, AR, and native lifecycle
behavior remain unverified.

## Source hashes

- Presentation SHA256: `220a85ac575460d54e0a39c5a9ada9f894556b849018ee5e21a2099cf6a472f0`.
- Context SHA256: `d41a1a24be70ca09ce51c2f97f5ec47cea480d58a10ab88ef40b121c65358704`.

Recommendation: integrate this commit with the root session implementation and
peer02 tests, then run the agreed serial checks. Retain this tree until the
integration owner has preserved the commit and report.
