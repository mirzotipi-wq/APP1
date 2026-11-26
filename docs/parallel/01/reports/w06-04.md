# W06-04 — Feature sheet host

Implemented new `App/StudioFeatureSheets.swift` in detached commit `9e5b363`; no other tracked changes.

API: `.modifier(StudioFeatureSheets(session: session, onReferenceApplied: { ... }))`.

One owner-keyed background sheet reads live owner/presentation state, retires immediately on false, ignores true writes, and finishes only its matching owner. Reference/arrangement/lux use captured snapshots; lux resolves its captured light UUID. The reference callback runs only after acceptance. Room/AR receive the live scene and Bool callbacks. Nested manual dismissal stays locally owned by AR. Busy UI never cancels storage work. Legacy rejection feedback affects only the matching active owner.

Checks passed: agent-cycle check/next; Swift 6.0.3 single-file syntax parse; staged diff whitespace check. M03 remains active. Manager source review found no scoped defect. Detached worktree is clean.

No builds, test suites, native runtime, CI, or remote writes ran. Apple SDK typecheck, SwiftUI Observation, and presentation/lifecycle behavior remain unverified. Existing Void producers consume rejected drafts; this adapter cannot preserve them.

Root integrates the modifier and Package exclusion. Producer files remain unchanged. Full hashes, commands, checks, limits, and report metrics are in `receipt.json`.
