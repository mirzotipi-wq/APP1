# W06-07 — producer/integration review

**Accept source/document consistency, with the existing producer limitation retained.** Reviewed root `785d458`, frozen `791fa58`, proposed document `205f6a0`, and lane05 request `63d4676`; full commits and file hashes are in receipt.json.

Reference calls `closeSession()` before Void `onApply`, discarding its photo/candidates. Arrangement sets `didFinish` and lux sets `didApply` before their Void callbacks; each then dismisses. Parent rejection cannot preserve those drafts. StudioFeatureSheets states this honestly and limits feedback to the matching presented owner; only accepted Reference results switch to Study.

The proposed document accurately marks `onAccept` Bool as future-only. Its rejection branches precede cleanup/completion/dismissal, retain draft/error, and reset a separate submission guard. Explicit `onAccept:` calls and prohibition of same-label Void/Bool overloads address ambiguity; the legacy bridge cannot claim retention.

Manual room accepts synchronously before updating kept state; rejection retains displayed measurements. AR forwards Bool results under nested-owner guards. Nested manual Done does not retire the outer AR owner. Host room/AR inputs use live session.scene.

Both Study and 3D wrappers use workspaceResetID. Captured storage-generation/live-UUID selection guards remain. Reality updateUIView refreshes onSelect even without geometry changes. The lane05 request was independently retrieved from its exact git blob; no new remote status is inferred.

Checks: agent_cycle check/next succeeded; five producer blobs match the captured comparison and frozen source; host matches the document’s cited host blob. No builds/tests/native runtime ran. First-save viewport retention, SwiftUI presentation, and AR behavior remain unverified.
