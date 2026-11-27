# W05-06 — Feature lifetime review

## Provenance and disposition

**No new core lifetime defect found. Native integration remains incomplete.**

Detached sparse tree base: `ea83fa165916aaa2f55ddb88f6430b8a59ce5565`, at `/workspace/scratch/e08d5190f17c/workers/w05-06/tree`.

Production and original fifteen actual Session regressions inspected through exact `git show`/`git diff`: `721186e93d4f4a511823d4f3013414929e54a56d`. Final source inspected: `363a7149e4eb6f195f478b3ce0210e33e8ac7ed0`. The latter changes only `NativeTests/StudioFeatureSessionTests.swift`, adding the 35-line failed-operation regression; production is unchanged. No code commit, source edits, builds, or pushes by this worker. Assigned build directory unused; final worktree status clean.

## Lifetime challenge

- `StudioSession.openFeature` checks loaded/writable/idle/current storage generation, existing presentation, and target UUID before closing gestures. The real admission regression verifies rejected opening preserves the editor and Plan state.
- Admission consults the live, parent-owned optional presentation. Context identity uses `workspaceResetID`, so first-save storage adoption preserves the logical owner. Scene revision tokens reject edit-away/undo-back even when content becomes equal. Captured presentation values remain independently active: the direct retired-receipt regression explicitly demonstrates why adapters cannot use copied receipts for admission.
- Main-actor scene/lux application validates synchronously, acknowledges its own revision, then retires before returning, including valid no-ops. Retirement preserves the snapshot and ends only its owner's group. Matching finish clears the optional; external captured values can still retain their snapshots.
- The actual `testRetiredOwnerCannotApplyOrFinishTheNextPresentedRoomGroup` exercises A retirement, B reopening/application, and late A retire/finish/application. B's receipt and editing group survive. Foreign equal-snapshot owners also fail atomically. Successful reload/project creation clears ownership; old completion cannot clear the reopened feature.
- Repeated room/AR changes advance only their own accepted revision and share their active undo transaction. Invalid/no-op unrelated changes preserve that transaction; accepted unrelated edits separate it and stale the receipt. Rejected feature proposals preserve the editor and receipt.
- Changed feature results clear a zero-motion Plan origin. Actual scene, room, and lux paths verify the next drag uses the accepted scene and new scale. Invalid and no-op paths retain the unchanged origin. No mirrored Session implementation was used.
- The final real Session regression suspends failing save/reload/recover requests, rejects busy feature application, then verifies retained context/editor/storage generation, cleared task/busy state, and a later successful application using the same context.

## Native boundaries

These remain wave 6 work, not failures newly introduced here. `StudioView` still uses independent legacy contexts: `acceptsSceneResult` checks storage generation and scene equality without live owner/revision admission. Equal content after undo, or a retained old callback after closing/reopening, is therefore not fenced by the new core policy. Its generation-change observer still dismisses all editors on first save.

Reference Apply closes its local session and clears images/candidates before its Void parent callback. Arrangement/lux dismiss after their Void callback, including rejection. Room/AR Bool callbacks preserve rejected draft state; their owner checks retire callbacks before asynchronous dismissal and protect newer owners during teardown. AR separately invalidates permission/session generations, pauses/detaches views, and rejects old delegates. Reference's dismissal observer distinguishes dismissal from nested coverage in source. None of this source inspection establishes Apple lifecycle behavior, focus retention, Observation, or AR runtime acceptance.

## Actual verification and limits

Read all required project/protocol/state/interface documents. In the frozen tree, `python3 scripts/agent_cycle.py check` exited 0 with structural-only validity; `python3 scripts/agent_cycle.py next` exited 0 and reported M03 editing/accessibility/persistence outstanding.

Inspected root's retained exact-source receipts/logs: `docs/parallel/01/evidence/wave05` records 429/0 at `721186e…`, including all fifteen Session methods and the retired-receipt test. `wave05-final` records 430/0 at `363a714…`, including all sixteen Session methods. These were root executions, not worker reruns. Acceptance manager separately verified all 173 final source hashes against disk and exact Git blobs. Final native parse receipt covers 80 files, exit 0, syntax only. Apple compilation/UI/Observation, actual disposal/reopen presentation behavior, and AR device execution were not run.
