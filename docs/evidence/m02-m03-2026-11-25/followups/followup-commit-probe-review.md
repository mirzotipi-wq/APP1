# Independent commit/interruption probe review

**Scoped source approval. No unresolved integration blocker found in the reviewed files.** Reviewed the C interposer, Python driver, and root's wrapper/CI changes. This is independent of the Swift helper, which this reviewer authored and does not certify independently here. No builds, runtime tests or source edits were performed by this reviewer.

## Frozen sources

- C interposer: `e412914f9bb4c9d83d760e5327c618d5f70772d2111907ecbc8cc917c82fdc2a`.
- Python driver: `a1d5344fded8681209d39c6723a8a20d25b3b31966eedef03ad1ca160feabd1b`.
- Wrapper reviewed: `5b4da7e737b39d689f175a77c7c236743bb124698aa0d7e70df69129ef3b3a1e`.

## Findings and disposition

1. **Exact-target aliasing, fixed.** Initial `realpath(destination)` could intercept a different final symlink entry pointing at the target. Final code rejects final-component symlinks before canonical comparison. The actual symlink-negative receipt confirms an unrelated entry was replaced normally, zero hooks fired, and target bytes remained identical; its interposer binary matches the passing scenario binary.
2. **Nested-session cancellation, fixed within stated scope.** Root identified outer driver termination escaping its separately created child sessions. Independent review confirmed this. The driver now registers children while cancellation is blocked, restores the child mask before exec, handles SIGTERM/SIGINT through a dedicated exception, and performs local/fallback group cleanup. An actual SIGTERM during a recorded test-only pause after the real helper's SIGSTOP produced exit 1, absent helper group and fresh prior verification in 0.015 seconds. Uncatchable driver SIGKILL cleanup is explicitly excluded.
3. **Cancellation outcome, fixed.** The final one-line change explicitly resets status to failed when cancellation is caught, preventing a late termination record from retaining passed status.

## Evidence and limits

Read actual `commit-interruption-2/result.json`, `commit-cancellation-1/result.json`, and `commit-symlink-negative-1/result.json` under `/dev/shm/keyfill-c0abc39c4f18-*`. Runtime driver scope is preceding hash `f6102479a242254e1572881aac611357193f2492f3ad550b787c7b12c5718be4`; root is rerunning the integrated wrapper on final bytes.

All three recorded cases passed: witnessed real `renameat` boundaries, full staged candidate before rename, observed stop/owned SIGKILL, strict old/new fresh-process snapshots, and witnessed EIO plus caught save errno 5. Exact bytes, active identity, unrelated records and unrestricted controls are required. Missing/incorrect hooks fail closed. Every Swift input and helper/interposer binary is hash-bound; fixture, witness and phase/deadline limits are explicit.

Linux CI opt-in is additive. Existing EFBIG/macOS behavior remains; the wrapper includes both new sources in provenance and reserves TERM grace inside the shared 140-second probe budget. This evidence covers Linux process interruption and rename failure, not power loss, ENOSPC, Darwin/iOS/device execution or milestone completion.
