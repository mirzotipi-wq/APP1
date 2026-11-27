# Worker 093 — proposed privacy draft updates

These are exact proposed edits to `docs/PRIVACY.md` at `f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5`. Root owns integration. No product behavior or acceptance criterion changes are requested.

1. Change the draft date from `2026-11-24` to `2026-11-27`, retaining all of its unpublished/unreviewed qualifications.

2. In the projects bullet, replace `not prior exports, OS backups, or legacy migration copies` with `not prior exports, OS backups, legacy migration copies, or preserved recovery copies`.

3. Add this bullet immediately after the projects bullet:

> Explicit recovery of an unreadable library preserves byte-for-byte copies of its available saved files in a separate local recovery folder before creating a new library. These originals are not sanitized or repaired; they retain whatever data was already in those files. Failed recovery attempts can leave partial preserved copies. The legacy source remains untouched, and deleting a project from the current library does not erase these copies. The app provides no recovery-folder browse, restore or deletion control and does not automatically remove the copies. Their retention and device-backup behavior require review before release. Recovery does not collect reference photos or upload the preserved files.

4. Add this bullet immediately before Optional StoreKit support:

> Beta feedback contains optional notes entered by the user plus app version/build, OS version and a coarse device family. Drafts and the reviewed report remain in memory while the feedback sheet is open; closing a populated draft asks whether to discard it. The app adds no photographs, project or scene contents, account details, network or hardware identifiers, or logs. User-entered private information is not automatically redacted. Review shows the exact text passed to the user-initiated system share action; the user chooses the destination or cancels. Nothing is sent automatically, and previously shared copies remain under the destination's control.

5. Replace the preferences bullet with:

> Measurement-unit, appearance and welcome-dismissal preferences persist in the app's `UserDefaults` through `StudioPreferences`. They contain no photo, feedback-note or purchase entitlement data.

6. Replace the CA92.1 table row with:

| Reason | Current purpose | Source |
| --- | --- | --- |
| CA92.1 (UserDefaults) | Persist the app's measurement-unit, appearance and welcome-dismissal preferences. | StudioPreferences; StudioWelcomeView; Resources/PrivacyInfo.xcprivacy |

This updates the existing row's explanation only. The declared reason code and manifest do not change; this source review is not Apple policy approval.

7. At the start of Remaining release work, replace `Review legacy backup deletion UX and iOS backups` with `Review legacy and recovery-copy retention/deletion UX and iOS backups, and verify feedback review, discard and system-sharing behavior`.

## Exact source basis and limits

- `ProjectLibraryFileStore.preserveRecoverySnapshot` writes `Application Support/KeyAndFill/Recovery/<UUID>/projects.json` and/or `portrait.json`, using only already-observed saved bytes. Neither store nor app source contains a cleanup, browse or share route for those folders. `deleteArchived` only removes a record from the current validated library.
- `BetaFeedbackView` owns note drafts and a frozen reviewed value in `@State`; `BetaFeedbackPreview` displays and shares the same `report.plainText`. Explicit discard resets all three notes and the reviewed value. Optional user text is not content-redacted.
- `StudioWelcomeView` stores only the explicit dismissal Boolean through `StudioPreferences.welcomeDismissedKey`.
- No user-facing PNG export is implemented in the reviewed source. `ReferencePhoto` creates an in-memory sanitized PNG derivative; the export menu offers vector PDF, editable JSON and text.
- Native memory/provider behavior, device backup/deletion, network observation and actual share destinations were not executed by this review. Do not present these static findings as the release privacy gate passing.
