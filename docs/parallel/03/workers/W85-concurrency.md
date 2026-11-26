# W85 — concurrency review

Actual worker: `/root/wave09/w85_concurrency`; input `a7c93be58a04154748c951b3d485b05300e9692c`; clean private tree `/tmp/keyfill03-7f4b/workers/W85-concurrency`. Exact hashes/commands are in `wave09-evidence/W85-concurrency-source.json`.

**Followup changes the disposition:** W057 exposes a reachable view-local cache adoption/status defect. The original completed review is preserved verbatim in `wave09-evidence/W85-original-concurrency.md`; its overall no-actionable-defect conclusion is superseded. Detailed source schedule and proposal review: `wave09-evidence/W85-w057-followup.json`.

A completes on Metal and remains in view state while B renders. B encounters a backend failure and executes `selectCPU`, purging engine Metal entries. Because the view awaits the separate render actor, MainActor can return to A before B publishes. Cancelling B leaves the permanent CPU decision intact. A's task then returns at preview line211 using its local successful frame, bypassing the engine; request-only currentness displays the historical Metal badge. Ticket checks correctly suppress B but cannot revoke that local A. This is a subsequent-request policy defect, not evidence of corrupt pixels or engine-cache leakage.

The owner proposal removes local reuse, consults the engine on every activation, and requires both request and active ticket for current status. It retains historical pixels as previous until guarded adoption. The a7 previous-frame warning must be preserved. W84 owns adaptation; root owns native execution. Candidate source review found no blocker; see `W85-concurrency-followup.md`. Native execution remains pending. The required hosted regression must keep one host identity, hold second A, and prove the renewed engine call plus previous/current status transition; a pipeline-only test cannot catch the view shortcut.

Other inspected schedules—cancelled late completion, pre-cancelled begin, conversion invalidation and ticket-based A→B→A suppression—remain guarded. The earlier final-poll/cache-admission schedule concerns completed output and remains a qualified engine completion-boundary limit, not a demonstrated prohibited pre-completion insertion.

Execution: source/hash inspection and report writing only; no Swift tests, builds, renders, benchmarks, copied models or production edits. Native passes/failures supplied as context are not this worker's execution. Qualitative 60% checkpoint sent; token counters unavailable. This followup is the same actual worker, not a new count.
