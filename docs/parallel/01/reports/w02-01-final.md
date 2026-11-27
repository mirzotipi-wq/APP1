# W02-01 — final scheduler addendum

Frozen specialist input: `30e52b8c277cfd15d5edeb872ff7a53d274f9b16`. Scheduler resumed at `7b37b79f5d399942b9dd226667fcd67f2ba705f6`; its original context remains counted once.

## Completion and provenance

Wave two contains exactly ten distinct canonical contexts: this acceptance scheduler and nine specialist peers. All nine child spawn calls explicitly used `fork_turns:none`; the scheduler's own parent-side creation arguments are not visible here. Followups and recovery added no workers. After recovery, only07 ran until it finished, then08;09 started only after root released the second child slot. All nine specialists returned final reports.

Every report was inspected and its available artifact hash verified. Original provisional01 remains unchanged at SHA256 `37ca3f929dd503970c44cb5cc804484194702ccba30bdb0c5b712e7fa6b44ddc`. Recovery provenance remains explicit:02–05 match original pre-outage hashes;06 was first saved from its returned report;10 lacks an original checksum. New07–09 originals and hashes are recorded in `w02-ledger.json`. Current scheduler and07–09 worktrees are clean at their declared revisions.

Worker04's one-file test commit is `e359c773865f3e1f237cb59e356dc28a2879b832`; worker10 independently accepted its eight tests with the declared adoption-fix dependency. Workers ran no Swift builds/tests. Root's later implementation and test receipts are separate evidence. Brief/report limits were requested; provider context-token accounting was unavailable. New report-plus-checksum outputs were below800 tokens under the execution tool's reported counts.

## Contracts and accepted followups

- Validation rejection preserves scene, selection, revision, open edit and redo. Non-reset adoption accepts unchanged validated content only; stage receipt operation and editor before committing either.
- Native room/AR Bool reports acceptance; valid no-ops remain accepted. Consult the live presentation owner and apply synchronously before advancing its receipt. Retire and clear only the matching owner; guard ownerless rollback against delayed callbacks.
- First save changes the active project ID used by frozen ordinary control ownership, potentially remounting pending draft/focus. Keep document/control lifetime identity stable across first save and scene revisions; root accepted this for subsequent integration.
- Reference Apply clears local content before its Void callback, so rejection can protect the scene without preserving that consumed reference session. Distinguish cancelled replacement, cancelled dismissal and completed teardown; keep photos, focus, drafts and tokens outside scene persistence/export.
- Closed typed field commands may avoid repeatedly scanning unchanged imported names. Preserve UUID/schema/count, validate payloads and coupled room values before mutation, and retain optional representation/history/revision behavior. Arbitrary candidates, replacement, adoption and import retain full validation. No constant-time or measured-speedup claim.

Native callback routing, draft/caret/composition/focus, photo dismissal and platform behavior require verification on the integrated source. Frozen-source reviews do not verify root's newer implementations. Root owns code changes and publication; this scheduler made no repository source or branch changes.
