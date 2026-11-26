# W07-04 — Settings access under protected storage

**Ready to integrate:** `cb0b3b7511c6f3b33f5354fe3873526a98d2088d`.

Only `App/StudioView.swift` changed: 10 insertions, 3 deletions. Subject, Arrange and AR each retain loaded/protected/busy disabling. The parent Menu retains active-edit protection, allowing Settings to open when storage is protected. Labels, identifiers, the 44-point target, Save/export guards and existing feature routes remain intact.

Subject's Menu callback now captures storage generation and checks `session.allowsMutation` plus active-edit state before presenting. This prevents a queued menu tap from opening after a project/storage change. The separate Plan-marker path is unchanged; protected storage hides its workspace.

**Actual checks:** startup state/reference check and next-work selection succeeded; `git diff --check` passed; Swift 6.0.3 frontend parse passed (syntax only). Committed worktree is clean. One initial lookup used an absent path; the corrected read confirmed the busy/generation guard.

**Limits:** no build, unit/UI tests, Apple typecheck or native runtime verification. No camera, photo, purchase or restore operation. Legacy Reference/Arrangement/Lux Void-callback draft loss remains unresolved.

**Artifacts:** `source.patch`, `report.original.md`, `report.md`, `receipt.json` outside the worktree. Recommend integration with the manager's protected-storage native acceptance work; root alone pushes.
