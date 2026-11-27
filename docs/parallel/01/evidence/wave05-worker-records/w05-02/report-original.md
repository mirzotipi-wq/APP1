# W05-02 — StudioSession feature data regressions

## Result and provenance
- Commit: `9735262426c411a6dd62380f018e77edb010a41e`.
- Frozen source: `ea83fa165916aaa2f55ddb88f6430b8a59ce5565`.
- Allowed change only: `NativeTests/StudioFeatureSessionTests.swift` (478 lines; 15 actual StudioSession test methods).
- Source SHA256: `0aae7a329fbf0b7f565868c51384e28c84ab3d6f098be46416d61a1dff73852b`.
- Isolated detached sparse tree: `/workspace/scratch/e08d5190f17c/workers/w05-02/tree`.
- Assigned unused build directory: `/workspace/scratch/e08d5190f17c/workers/w05-02/build`.
- Read updated API source at root `db3e8d9`, correction `7bf3459`, and core presentation `40f488b` through git show. Did not cherry-pick or change their implementation. Root must integrate this file and include it in Package.swift before execution; the frozen base lacks the new feature API.

## Coverage
The tests invoke actual StudioSession orchestration, not a reconstructed admission algorithm. File-local helpers provide the standard receipt suspension and one failed-load retry fixture.

1. Opening requires loaded/current state, rejects an unknown target UUID atomically, and ends a valid existing Plan gesture only after admission. A second presented feature is rejected.
2. Wrong route, duplicate scene UUID, nonfinite scene/light values, foreign light, geometry and rename payloads leave editor/history/receipt intact. Lux accepts output only for the captured UUID while preserving a different selection.
3. Scene and light valid no-ops accept once and retire; scene redo remains available. Zero-motion Plan state is preserved for invalid/no-op callbacks.
4. Changed scene, light and room feature results clear a zero-motion Plan origin; the next gesture uses its new origin/scale and undoes independently. This covers the concrete acceptance-review defect corrected by root at7bf3459.
5. Room and AR accept repeated owned edits, advance only acceptedRevision, preserve the opening snapshot, and undo the whole owned group. Invalid/no-op ordinary commands leave that group intact; unrelated typed or full-scene updates end it and create a separate undo step.
6. Edit-away/undo-back cannot revive a feature or discard redo. A retired owner cannot apply, finish, or close the next owner's room group. A fresh token with identical snapshot/generation/revision cannot impersonate the owner.
7. Busy rejection retains a feature; first save changes storage generation while retaining logical workspace context. Actual ProjectStore reload/project creation clears old contexts and rejects late callbacks.
8. Healthy repeated load throws staleSnapshot before reserving or ending a gesture. Failed initial load blocks feature opening but an explicit retry recovers.

## Actual checks
- Startup repository status/log and required directive/product/architecture/quality/design/lane documents read.
- `python3 scripts/agent_cycle.py check`: exit0, structure/references valid only.
- `python3 scripts/agent_cycle.py next`: exit0, canonical M03 editing/accessibility/persistence queue; not lane authority.
- Python source inventory:15 test methods.
- `git diff --cached --check`: passed before commit.
- `git status --short`: clean after commit.
- Source checksum recorded above.

## Limits and integration
No Swift compilation, package tests, native tests, Apple SDK/UI/Observation/AR checks, or push were executed by this worker. These tests are uncompiled against the combined candidate until root runs them serially. The historical413 Debug tests belong to the frozen predecessor, not this change. No production owners, Package.swift, canonical state, or root tree were edited. Existing reference draft consumption and arrangement/lux Void-callback dismissal remain wave6 integration limits; this work claims no fix for them. Direct didApply-after-dismiss core coverage is root-owned and intentionally not duplicated.

Checkpoint persisted before final test authoring at `/workspace/scratch/e08d5190f17c/workers/w05-02/checkpoint.md`. Preserve this tree/commit/report until root records integration. No additional source defect found in static review; runtime acceptance remains pending.
