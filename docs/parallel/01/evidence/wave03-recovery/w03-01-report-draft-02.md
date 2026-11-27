# W03-01 — Acceptance and scheduler

**Accept corrected composition and focused tests; continue wave4. Native acceptance remains unverified.**

Verified frozen HEAD `966c9c21adbb685d82127e7f88981b74daf47e3d`; separately inspected restored correction `6fe2cfab49f1b087553f65341f4471f786b309f9`. Required directives/contracts read; structural agent-cycle checks and static source/diff/hash review performed. No builds/tests executed by this reviewer.

## Acceptance

- First save rotates storage generation while preserving history, selection and workspace/control identity; switch/reload/recovery explicitly reset history/presentation (`ProjectLibraryOperation.swift:110–134`; `StudioSession.swift:160–214`).
- Rejected reservations precede gesture closure, preserving frozen Plan origin/scale and one undo group (`StudioSession.swift:113–145,174–184`). Selection, discrete replacement and owner handoff close coherent groups.
- Session owns asynchronous work through settlement; store cancellation is checked before synchronous persistence, with no postcommit cancellation suppression. Prospective editor/saved validation precedes publication; cleanup matches request IDs (`StudioSession.swift:184–245`; `ProjectStore.swift:40–61`).

**P2 corrected:** frozen `StudioView.swift:1141–1147` bypassed generation admission on numeric end events. Stable first-save owner could let an old end split a newer edit. The corrected View routes both phases through guarded session admission. The added session regression protects that contract; it does not execute View forwarding.

Independently inspected all six actual-session Plan tests, exact patch scope, package membership and new two-window real-store conflict/recovery test. Original04 source SHA256 `817b934859c173ee96fa40ac374c0047636f0460bf0ca9085cb568d6f2aa6e3d` matches restored integrated bytes.

## Evidence and remaining work

Read root's retained `evidence/wave03-restored` receipts/log: **400 Debug passed, 0 failures**, including11 session and6 Plan method passes. All169 manifest input hashes match6fe source. Native Swift syntax exit0 proves parsing only. Old pre-reset logs remain lost; they were not relabeled recovered.

P2 additional full-scene/name validation on scalar edits is source-backed; latency is unmeasured and typed commands remain wave4. Native Observation, sheet callback refresh, actual first-save focus/caret/drafts, VoiceOver and gesture delivery remain unverified. Full injected-executor envelope validation and sequential `.load` admission are nonblocking API boundaries, without demonstrated current production reachability.

## Worker provenance

Exactly10 fresh contexts: scheduler plus nine peers. Followups and one capacity-rejected spawn receive zero credit. Every report hash was checked; reports02–06/10 and earlier drafts were recovered/copied with matching receipts after tmpfs loss. Source04 recovered exactly. ENOSPC was retained; only authorized, verified-clean07/08 trees were removed. `w03-ledger.json` contains all canonical IDs, exact report paths/hashes, failures and recovery provenance. Campaign total after this wave:30 actual contexts.
