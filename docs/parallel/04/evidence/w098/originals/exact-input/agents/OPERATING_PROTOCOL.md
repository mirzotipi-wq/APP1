# Evidence-driven recursive development protocol v1.0

## Bounded execution loop

OBSERVE -> PRIORITIZE -> SPECIFY -> IMPLEMENT -> VERIFY -> CHALLENGE -> INTEGRATE -> LEARN -> HANDOFF -> OBSERVE.

Each iteration should deliver a user-visible improvement or retire a material risk. Do not spin on repetitive audits, rewrite documentation endlessly, or run unbounded retries. A work package should fit the available session; after two unsuccessful attempts at the same hypothesis, change approach, isolate a reproduction, or record a blocker. Prefer a working small slice to a large unverified change.

### Observe and prioritize
- Fetch main without discarding changes; inventory actual files, build settings, tests, logs, and current milestone.
- Rank work by customer value, release-blocking severity, dependency readiness, risk reduction, and estimated effort. P0 security/data-loss/crash defects outrank optional features.
- Use the state file as a queue, not as proof. Confirm dependency and evidence integrity. Record newly discovered gaps rather than hiding them.

### Work packet
ID, base revision, owner/role, allowed file paths, problem/reproduction, scope/non-goals, acceptance tests, dependencies, budget/timebox, expected artifacts, rollback and independent review plan. Each worker returns a patch/commit, tests and actual results, unresolved issues, and a recommendation; report whether it actually ran. Use isolated worktrees or nonoverlapping file ownership if supported; integration lead resolves conflicts without overwriting work.

### Verify and challenge
Run targeted tests plus applicable full suite. Compare before/after using identical fixture, hardware, settings, build configuration and workload. Record sample size and p50/p95 or raw data; do not confuse subjective ratings with physical measurements. Review adversarial inputs, cancellations, permissions, persistence, accessibility and capability fallbacks. A reviewer must attempt to falsify the implementation. If no independent reviewer is available, record self-review and leave release review pending.

### Integrate
Review diff and git status; commit code, tests, relevant docs, state and evidence together. No secrets, binaries, unrelated formatting, copyrighted references without rights, or generated caches. Integrate through approved branch workflow. Re-run checks on integrated revision. A code change may invalidate an old gate; set it back to unverified and schedule revalidation. Do not fabricate a pass to satisfy automation.

### Learn
Append observations to LEARNINGS.md with failure, root cause, countermeasure, evidence and follow-up. Propose process updates as separate reviewable changes; test against held-out cases and prior requirements. Never tune gates on the same evidence used to pass them. Owner approval is required for changes to protected product, quality, financial, privacy and master directives. Version the mutable protocol and retain history via git. Delete neither failed evidence nor regressions.

### Handoff
Update HANDOFF.md, state.json and evidence.json together. Include current milestone, completed work, baseline/source revision (use prior revision or exact test revision, not an invented future SHA), actual commands, outcomes, blockers and next executable packet. Record artifact checksums or paths when applicable. A later agent must be able to resume without chat history.

### Operational limits
No external compute, paid APIs, purchases, credential changes, App Store releases, recurring tasks, or autonomous schedules without authorization. Honor tool limits, budgets and cancellation. The scripts select/check work but do not execute AI or launch processes; an external agent session is required. Stop at release gate for owner review, or at a blocked dependency after recording useful independent work.
