# W06-08 — Accessibility and privacy

**Bounded source-review acceptance:** no introduced regression found at `785d458` against frozen `791fa58`.

- StudioView preserves all 72 accessibility-bearing lines, 19 explicit 44-point frame lines, and 20 existing disabled-state lines in order. Reference/Room labels and identifiers, menu action names, and tool/light routes remain intact. The new host disables feature contents during a library operation.
- Rejected legacy results receive actionable “Reopen this editor and try again” feedback. The matching presented-owner guard prevents an old owner from replacing a later owner's message. Room rejection still displays its existing error; nested manual-room closure leaves the outer AR owner active.
- Both preview wrappers and broad editor dismissal now follow `workspaceResetID`; first save retains that identity. Captured storage-generation/light-UUID guards remain. This establishes source intent, not native focus or caret retention.
- The five producers are byte-identical to baseline. Changed wiring introduces no upload, persistent photo storage, new permission request, or purchase gate. AR camera permission remains behind its existing Start action.

**Limits:** Reference, Arrangement, and Lux consume drafts before/after their Void callbacks even when the parent rejects them; no rejected-draft/focus retention is claimed. Bool acceptance proposals remain future work. Native Apple compilation, Dynamic Type layout, VoiceOver, actual hit geometry, focus/caret, and sheet lifetime remain unverified. No builds, tests, or native execution ran. Read-only `agent_cycle check/next` succeeded; M03 still lists editing, accessibility, and persistence outstanding. Exact hashes and checks are in `receipt.json`.
