# W03-01 Acceptance and wave scheduling — checkpoint

Verified HEAD: `966c9c21adbb685d82127e7f88981b74daf47e3d`; isolated worktree initially clean.

Checks actually performed: read required directives, handoff/state and product/architecture/roadmap/quality/design contracts; `agent_cycle.py check` and `next` passed structural reporting only. Static inspected StudioSession, StudioView, KeyAndFillApp, StudioEditorState, SceneEditHistory, StudioFeatureContext, ProjectLibraryOperation, ProjectStore and existing session tests. No build, native typecheck, tests or measured performance.

## Acceptance matrix

- First save: operation adoption rotates storage generation but preserves history, selection and workspace/control identity (ProjectLibraryOperation.swift:115–134; StudioSession.swift:160–165,207–214). Switch/reload/recovery reset history/presentation by explicit policy.
- Rejected Save during cumulative Plan drag: reserve precedes ending history or clearing Plan origin (StudioSession.swift:174–184). Finite translation uses frozen origin/scale, and invalid inputs leave state untouched (113–137).
- Cancellation/receipts: session owns the operation task; consumer cancellation cannot suppress an available receipt. Store checks cancellation before synchronous persistence and does not check after commit. Completion validates prospective editor/saved state before publication and clears only matching reservation/task (184–245).

## Finding requiring correction

P2, source-confirmed: StudioView.swift:1141–1147 routes numeric end events directly to `session.endEditing(owner:)`, bypassing the generation check used for begins. Stable control identity across first save means an old-generation end has the same owner as a newer edit. Route both phases through `session.editChanged(_:owner:from:)`. Root confirmed and owns the View correction plus regression; fresh review/test evidence required.

Other retained limits: live feature route/revision admission is planned later; Apple Observation, focused text/caret lifetime and native callback ordering remain unverified.

Recommendation pending nine peer reports, exact patch inspection and root validation. Reports/real agent IDs checkpointed in sibling `w03-ledger.json`; followups do not create worker credit.
