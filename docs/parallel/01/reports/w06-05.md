# W06-05 Concurrency review

**Accept bounded source wiring at 785d458; no new concurrency defect found.**

Reviewed the integrated host, Studio routes, session/storage orchestration, producer callbacks and actual two-window regression. Tracked source was clean; root had untracked `docs/parallel/01/evidence/wave06/`. Exact commits and reviewed-file hashes are in receipt.json.

- `StudioFeatureSheets.swift:15,26,79` retires the matching owner on binding dismissal, finishes only that owner and suppresses stale rejection messages. Room/AR close callbacks retire before calling dismiss; nested manual close preserves the outer AR owner.
- `StudioSession.swift:128,149,204` synchronously guards opening/results against busy, stale and retired ownership. Accepted scene/lux results retire immediately; repeated room results advance their own receipt.
- `StudioView.swift:200,1123` captures storage identity for opening and resets editors only on workspaceResetID changes. First-save adoption preserves that identity and feature payload (`ProjectLibraryOperation.swift:115`).
- `StudioSession.swift:298` reserves before ending edits or launching its retained task. Sheet observers await that task; closing/import cancellation does not cancel a committed parent operation. Receipt adoption has no post-write cancellation check.
- `StudioFeatureWindowTests.swift:12` uses two actual sessions and a real shared file store to challenge cross-window callbacks, competing saves and recovery; it does not reproduce the production algorithm.

**Checks:** agent_cycle check passed structural references; next remains M03. Reviewed-file bytes match HEAD.

**Not run:** builds, tests, native typechecking or UI. SwiftUI/Observation dismissal lifecycle remains unverified. Legacy Void producers still consume rejected drafts. The prior 430 core tests do not validate this native host.
