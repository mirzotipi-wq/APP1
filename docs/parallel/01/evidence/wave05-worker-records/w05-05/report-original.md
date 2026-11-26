# W05-05 — asynchronous ownership and reconciliation review

## Provenance and scope

- Worker: W05-05, one context, zero children, zero followups.
- Detached sparse tree base: `ea83fa165916aaa2f55ddb88f6430b8a59ce5565` (published).
- Exact integrated source inspected: `721186e93d4f4a511823d4f3013414929e54a56d` through read-only `git show`/`git diff`; unpublished code was never checked out.
- Tree: `/workspace/scratch/e08d5190f17c/workers/w05-05/tree`.
- Code commit: none. No implementation edits, builds, runtime tests, root-tree changes, pushes, or cleanup.

## Verdict

**No concrete concurrency or receipt-ordering defect found in the assigned integrated source.** This is an independent static review, not an execution pass. Existing native feature-host wiring remains future work and is outside this verdict.

## Falsification findings

1. **Reservation precedes edit-state changes.** `App/StudioSession.swift:298` reserves before ending the edit or clearing Plan state. Busy/stale rejection therefore cannot split a current transaction. Healthy repeated `.load` rejects at line 294 before reservation; failed initial-load retry remains admissible. MainActor serialization prevents another callback from interleaving the synchronous admission, mutation and receipt update.

2. **Save continuity and reset policies are coherent.** Feature admission uses `workspaceResetID`; storage generation independently fences project/control callbacks. First save rotates storage generation while no-reset editor adoption preserves scene revision and active feature. Metadata keeps these identities; successful switch/reload/recovery resets presentation and clears the feature. Pending operations reject feature results without consuming the parent-owned context. Accepted reservations deliberately close any existing room/AR transaction, including when the subsequent write fails.

3. **Failure and cancellation settle the correct owner.** Adoption stages operation state, editor validation and saved-scene validation before publishing at `StudioSession.swift:312`. If validation/execution fails, the original matching reservation is finished, while editor, library, feature and workspace identity remain intact. Conflict/blocking flags follow the operation type. Request-ID checks protect both busy state and task cleanup from old completions. The parent owns its Task, and `ProjectStore.perform` checks cancellation before synchronous storage work only; Session does not discard a committed receipt because an observer was cancelled.

4. **Feature ownership and ABA rejection hold.** Live parent admission checks presentation ID, logical generation, current revision and busy state. Actual mutations and undo/redo rotate revision. Scene and exact-UUID/candela-only light results retire synchronously after valid acceptance, including no-ops. A retired A cannot apply or finish B. Repeated room/AR results advance only their own accepted receipt; unrelated valid updates split their undo group only after actual mutation. Invalid/no-op proposals preserve group/editor state. Changed feature mutations clear zero-motion Plan state; unchanged proposals retain it.

## Coverage and limits

Read all 15 new methods in `NativeTests/StudioFeatureSessionTests.swift`, the existing 12 Session methods, operation policies, store execution and editor/history implementations. New coverage directly exercises paused-save busy rejection and first-save continuity, load rejection/retry, reload/switch invalidation, owner replacement, wrong route/foreign owner, undo ABA, no-ops, repeated room/AR grouping and Plan-origin repair.

**Remaining coverage limit:** no new method combines an open feature with a failing save/reload, cancellation, metadata completion or recovery completion. Existing Session tests cover cancellation, stale-save failure, metadata and recovery without an open feature. Static inspection supports the combinations, but those combinations have no direct execution claim in this report. Native SwiftUI observation, Apple compilation, AR and feature draft retention remain unverified here. Reference currently consumes its draft before a Void callback, and arrangement/lux dismiss after Void callbacks; the new parent session cannot establish native draft retention until host/owner integration.

## Actual checks

- Read required AGENTS/protocol/handoff/state/product/architecture/roadmap/quality/design and lane handoff/interfaces.
- On the frozen tree, `python3 scripts/agent_cycle.py check`: exit 0, state structure/evidence references valid; explicitly not test truth or release readiness.
- On the frozen tree, `python3 scripts/agent_cycle.py next`: exit 0, M03 with editing/accessibility/persistence outstanding.
- `git --no-optional-locks status --porcelain=v1`: empty after inspection.
- Swift builds/tests and native execution: **not run by this worker**. No earlier 413-test outcome transferred. Root's separately reported fresh integrated execution requires its own retained evidence.

Recommendation: accept this static ownership review with the stated coverage/native limits. No additional optional audit or builds requested.
