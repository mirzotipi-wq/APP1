# Worker 096 follow-up — bounded native input trace

**Same identity:** `/root/a096_numeric_entry_causal_review`; no new worker. **Base:** `f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5`. **Private worktree:** `worktrees/096`. **Commits:** `52fbadd` then `85f428e4395a2435f639c60fe4ab8c88300af62d`. Original `reports/096.md` is preserved.

## Reason and scope

Root supplied further original failures at the same source on three independent current runners: precision text remained 900; a room input stayed empty; and a beta project-name input stayed empty/focused before a later name workflow passed. This supersedes the earlier one-rerun-first recommendation without claiming a source cause. Root authorized the contingent diagnostic alongside independently justified source/configuration repairs.

The five owned files are `App/StudioTextField.swift`, its existing native test file, and the three assigned accessibility/manual-room/beta-workflow UI suites. No BetaAccessibility, recovery, title-layout, shard or workflow files were changed by worker096. Existing actions, values, assertions, deadlines, keyboard behavior and screenshots remain intact.

## Implemented diagnostic

The recorder and all instrumentation compile only in DEBUG and require `KEYFILL_UI_TEXT_INPUT_TRACE=1`. The assigned UI launches opt in. Ordered stdout JSON reports monotonic/epoch times, process-local control/lifecycle identity, fixed event names, allowlisted field names, guard/focus state, bounded UTF-16 lengths and bounded equality. Unexpected identifiers become `other`; raw drafts, replacement characters, labels, hints and project names never enter the record type. Both-long comparisons remain unknown rather than traversing arbitrary input.

Delegate/editingChanged, accepted binding/readback, external reset, native replacement, identity/disposal and actual focus transitions are retained. Unchanged configuration and scheduled/unchanged focus checks emit nothing. Repeated focus requests while missing a window coalesce. Initial/external text configuration and actual keyboard-type/enabled changes remain observable.

Limits remain **512 records per process and 256 per control**, including their terminal markers. A capacity check precedes UIKit state collection; the recorder's lazy state provider also skips disabled/capped calls and limit markers. The existing full xcresult retains app stdout, independently recovered in worker095; compact screenshots alone do not provide this transport. Logging itself can affect scheduling, so a future instrumented result remains source-specific evidence.

## Verification and review

Four new native methods check private-canary/schema exclusion, exact caps plus state-provider suppression, accepted/rejected/external-reset behavior and binding getter/setter equality with tracing on/off, and 100 unchanged reconfigurations followed by a retained native edit. These tests **have not run on Apple**; inherited native obligation rises 323→327 before other integration changes.

Swift 6.4.3 Linux DEBUG and non-DEBUG parsing and cumulative `git diff --check` pass. Shard structure passes at the private base's five required UI shards; root owns the separate split. The first parse invocation incorrectly placed `-D DEBUG` before `-frontend` and emitted an unknown-argument error; corrected standalone calls exited 0. This was command syntax, not a source compile failure. No package/native build or keyboard execution was performed.

Root identified that the initial trace's repeated configure/focus noise could exhaust its budget and that state collection continued after caps. Follow-up `85f428e` repairs both without lifting caps; the initial commit is retained. Independent worker001 reviewed Release token equivalence, privacy, guards and ownership, with its separate recorder witness receipt authoritative for any host execution it performs.

**Recommendation:** integrate both commits after001's review; require the new Apple run to typecheck and execute all 327 native methods and the unchanged required UI checks. The trace is a diagnostic, not an input repair or evidence that the earlier failures passed.
