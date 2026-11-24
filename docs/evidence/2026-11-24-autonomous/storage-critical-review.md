# Independent storage critical review — 2026-11-24

## Conclusion and scope

No new demonstrated P0/P1 data-loss defect was found in the reviewed persistence, recovery and editable-import paths. This is a source and existing-evidence review, not a native acceptance test, hardware durability result, or release approval.

Reviewer: actual specialist `w07_storage_review`, independently assigned by the integration lead. Review base: main `5ac2d1e2e8e8762c84ababa93e1982ec914fbef8`, plus the pending shared bounded-reader and adversarial-import changes identified by the source hashes below. Other workers were active in separate files; this report does not attribute their changes to the reviewer. Only this report was written; no production change, staging, commit or repeat test execution was performed.

## End-to-end findings

| Boundary | Reviewed behavior | Evidence and limit |
| --- | --- | --- |
| First save | A new library is proposed in memory. The store compares the actual loaded snapshot with the caller's expected nil under one process-wide lock before writing. Studio updates `library` and `saved` only after that write returns. | Existing concurrent-first-save regression verifies exactly one winner. The initial default scene is not exported or edited if loading existing data fails. |
| Corrupt, unsupported or nonregular saved data | An existing `projects.json` is read and validated before any legacy fallback. Decode/validation failure propagates, and the protected UI disables editing, saving and export until Retry succeeds. | Existing malformed legacy, corrupt library, unsupported schema, duplicate IDs, oversized and nonregular tests preserve bytes. Private store paths are not hardened against arbitrary external-process replacement; that is outside the declared transaction contract. |
| Legacy migration | Missing `projects.json` permits migration from a valid retained `portrait.json`. The original is never deleted, and the same lock gives simultaneous load/migration calls one stable identity. | This does not distinguish a genuine first migration from disappearance of a previously migrated library. Ordinary load/recovery may migrate a retained legacy file if the current library is missing. The confirmed archived-replacement path deliberately requires the existing library and cannot trigger migration. Do not describe every missing-library operation as unconditionally rejected. |
| Ordinary save and library operations | Create, rename, duplicate, archive, restore, select and deletion work on a value copy. `StudioView.applyLibrary` requires a clean editor and writes before adopting the new library, active scene or history reset. | A stale snapshot preserves the latest saved record and leaves this window's scene open. Whole-library comparison also protects a previously selected deletion candidate against intervening changes. |
| Full-capacity recovery | The replacement path re-reads the latest valid library under the lock. A newly available slot causes a nondestructive append. At capacity, the complete confirmed archived record must still match and be inactive. Removal and new-ID insertion remain local until one bounded atomic write succeeds. | Existing nine-case capacity suite includes changed/restored/removed candidates, active/unarchived rejection, fresh-capacity preservation, oversize failure after local removal, missing/corrupt library, and eight concurrent confirmations with one winner. |
| No archived capacity escape | Editable export snapshots the current name/scene independently of a free library slot. It does not save or switch the editor. Import still requires an available slot and a clean editor. | Core document/native FileDocument source and prepared snapshot reviewed. Actual system exporter, destination overwrite confirmation and the full-capacity UI escape remain native verification tasks. A source error does not produce a false saved status. |
| Editable import | The validated document contains no library identity. The UI calls `create` without an ID, producing a fresh record, then uses the ordinary optimistic store transaction. It sets success only after `onApply` returns. | The new adversarial tests prove stale rejection, retry with a fresh ID, retained competing changes, full-capacity failure, and a valid individual copy rejected when the combined library exceeds 8 MiB. Failed save leaves stored bytes unchanged in those exercised cases. |
| Provider access and cancellation | Security scope covers file coordination and the coordinated accessor. The helper checks the opened descriptor, rejects final symlinks/FIFOs/directories, limits actual bytes despite growth, and checks both task and caller cancellation. Results require the current UI request token before adoption. | Nine helper tests passed in a Linux POSIX adaptation. Apple SDK compilation, NSFileCoordinator/provider behavior, dismissal and late-result lifecycle remain pending; the adaptation is not Apple verification. |
| Explicit destructive actions | Archived deletion is confirmed; active/unarchived records are protected. Conflict reload explicitly confirms discarding only this window's unsaved edits. Recovery adoption happens only after successful read/write. | No code in these paths deletes external exports, Photos originals or retained migration backups. The UI does not promise secure erasure or control over copies owned by another app. |

## Existing execution evidence inspected

The reviewer read the actual logs rather than treating test source as an executed result:

- `verification/cycle3-exact-debug.log`: exact-tree **201/201** portable tests passed; the relevant suites include **19/19 ProjectLibraryTests** and **9/9 ProjectRecoveryCapacityTests**. Durable integration copy: [cycle3-debug.log](cycle3-debug.log).
- `verification/project-document-adversarial-debug.log`: **6/6** new document/import tests passed, zero failures, 2.126 seconds of test execution. These tests were still pending the next integration at review time.
- `verification/bounded-reader-posix.log`: **9/9** helper tests passed, zero failures, 0.112 seconds. The worker used scratch copies with only Darwin imports/qualifiers changed to Glibc; repository native code was not compiled against an Apple SDK.

The focused tests use real temporary files, actual optimistic transactions and byte comparisons. The combined-size case deliberately creates an individually valid approximately 4.2 MB copy whose addition exceeds the independent 8 MiB library limit. No test was removed or weakened by this review.

## Residual issues and required verification

1. **Native provider/UI lifecycle remains unverified.** Run the current Apple unit and UI jobs, including coordinated read cancellation, actual system exporter/importer cancellation, sheet dismissal, full-capacity export, recovery and relaunch. Request-token/source inspection is useful but does not prove SwiftUI's real presentation callback sequence.
2. **Low-space, interruption and durable commit require device evidence.** Source uses bounded encoding and Foundation atomic replacement; tested size rejection preserves existing bytes. This does not prove power-loss durability, disk-full behavior at every filesystem phase, data-protection availability while locked, or OS backup behavior.
3. **Duplicate JSON envelope keys remain ambiguous.** The other specialist's exact decoder probe established first-wins behavior on the tested Foundation version. Canonical exports have unique keys, decoded values still validate, and import creates a separate project. No custom parser was added and no first-wins behavior is promised as a stable file-format contract. This is a documented format limitation, not demonstrated overwrite or data loss.
4. **Transaction scope is one app process.** The shared lock serializes app windows/store instances. It is not a filesystem lock for independent processes, and it does not promise an immutable snapshot if another process writes the same inode directly. App-owned Application Support paths and user-selected provider files have different trust boundaries; the latter now use descriptor validation and coordination.
5. **Long legacy data remains a performance consideration.** Grapheme-compatible legacy names can contain many scalars, with the encoded library capped at 8 MiB. Display paths are bounded and persistent values are preserved. Native import/save memory, responsiveness and thermal behavior are still release-gate work, not proven by correctness tests.

These limits do not justify weakening protected quality gates. M01 and applicable persistence/privacy/release acceptance remain pending actual current native and device results.

## Reviewed source fingerprint

These hashes identify the exact files inspected, including pending changes, without claiming that a later main commit was tested by this reviewer.

| File | SHA-256 |
| --- | --- |
| `Sources/LightingCore/ProjectLibrary.swift` | `0b6689015a9102d5b5ca6f309553455b48c047534432bc2c2b99726a242d73c4` |
| `Sources/LightingCore/LightingProjectDocument.swift` | `90336f0dec27880ecde5783dae89041c2e9e4aa3ea00c4d39388c4eea62808fd` |
| `App/ProjectStore.swift` | `332a68434f50448db206632d03dfb35f969324513977c176a802184ffe731f2b` |
| `App/ProjectLibraryView.swift` | `db89c09d25fa1f912b8f2fad3a454ab60d24e93c23fe9bded05e546723c96cc8` |
| `App/RecoveryCapacityView.swift` | `57223bde6282d8ecd878f3cf9cf4a71830e59e6c72703478302842b07d3f51f4` |
| `App/ProjectDocumentIO.swift` | `a8f5b7f0be19e81c9f25e1f2a0e022cddb75ec9756e6ae6e0d9a2e99d2d3bf7c` |
| `App/BoundedFileReader.swift` | `5dfe622ec85576878db1888f9420b808c7dd9784d86ec78c84ddbbca950102f3` |
| `App/StudioView.swift` | `d35e1297ebd7760a3d0574a527076ebfc7ddc7b689b2fbcc8f00fe17a6aa429c` |
