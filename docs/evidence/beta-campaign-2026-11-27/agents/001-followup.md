# Worker 001 follow-up — independent native input trace review

**Recommendation: no blocking source-visible findings; proceed to fresh Apple CI.** Reviewed exact worker 096 commit `85f428e4395a2435f639c60fe4ab8c88300af62d`, parent `52fbadd55ff67ef2e9eabbf8ef7e103228536c11`, against `f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5`. Five files; private worktree clean. Reviewer made no repository changes and ran no full package suite.

## Findings

- Initial trace noise and continued post-cap state observation are corrected. Unchanged configuration/scheduling/focus checks produce no records. Initial/external/identity changes, actual keyboard/enabled/focus transitions, and all delegate/edit/publish/reset/lifecycle events remain observable. Repeated missing-window diagnostics are coalesced; this state controls logging only.
- The helper checks capacity before native-state collection. The recorder also guards both budgets and invokes its lazy state provider only for retained non-marker records. Caps are **512/process and 256/control, including terminal markers**.
- Original accepted/rejected edits, selection restoration, external resets, lifecycle guards, focus actions and product callbacks are unchanged. All nine binding-access expressions remain in their original order. Trace arguments reuse already-read binding values. The bounded equality observation never traverses beyond 257 UTF-16 units.
- Output contains only numeric/Boolean state, event names, fixed field allowlist labels, and locally generated correlation values. Unknown identifiers become `other`; drafts, replacements, labels, hints, project/user/device identifiers are absent.
- All production trace declarations/calls/storage are inside `#if DEBUG`. Removing those blocks yields baseline Release tokens after only formatting/semicolon normalization and the equivalent weak-self/lifecycle guard split.
- Four new native methods meaningfully cover privacy/oversize handling, marker-inclusive budgets and lazy state collection, traced/untraced accepted/rejected/reset/focus callback behavior and getter counts, plus 100 unchanged updates followed by a real edit. They inject local recorders/sinks, invalidate controls, and do not mutate shared recorder/environment state. Existing methods are retained. Three UI files add only four explicit opt-in flags.

## Actual validation

On Linux Swift 6.4.3: both DEBUG and Release syntax parses of all five files passed. The **exact extracted Foundation-only recorder** compiled in declared Swift 5 language mode with strict concurrency and warnings-as-errors. Its executable witness passed both caps, distributed-control saturation, unknown-identifier redaction, schema, disabled behavior and provider-call accounting: 510 state collections for two capped controls, 511 for distinct controls, zero for markers/disabled/exhausted attempts. Final commit hashes match those checked inputs. `git diff --check` and the private worktree shard check passed.

**Limits:** UIKit/SwiftUI SDK typechecking and all four new native tests remain unrun locally. No native keyboard, responder, accessibility or UI runtime pass is claimed. Fresh Apple CI must establish those results.

Receipt and reproducible witness: `campaign/evidence/001/followup/followup-review-receipt.json` and adjacent source/log files. Original `001.md` is preserved.
