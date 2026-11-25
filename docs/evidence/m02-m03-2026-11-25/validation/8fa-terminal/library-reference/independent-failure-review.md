# Independent 8fa library failure review

**Recommendation: retain the failed/incomplete result and the original assertions. No specific source or configuration repair is established by this evidence.** Read-only review of source `8fa4399f50554836ce70ec2929a28534f70ba4b0`, run 45649843650, library job 139341046382.

## Actual accounting

I independently parsed both complete logs and compared the uploaded log's eleven unique method starts with the three classes declared at git8fa.

| Evidence scope | Starts | Passed | Failed | Skipped | Started without outcome | Not started |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Terminal console through timeout | 10 | 5 | 4 | 0 | 1 | 1 |
| Uploaded native log, including later tail | 11 | 6 | 4 | 0 | 1 | 0 |

The console's open method is `ReferenceComparisonUITests.testGuidedRigAbstainsThenAppliesAndUndoesWithoutSaving`. The artifact later records its pass in 193.475 seconds, followed by `ReferenceComparisonUITests.testReferenceComparisonOpensWithRealStudyAndNoPhoto` starting at native 17:00:24.498 and stopping during automation setup. The timeout annotation is 17:00:22.929726; the sixth pass/final start belong to the later artifact tail, not a successful command completion. No finalized xcresult exists; export explicitly reports that at 17:00:26.964427. Preserve both scopes.

## Failures and source checks

The first concrete failure is `testExactLightIntensityEditorAccessibilityAudit`, which reached the loaded Plan/numeric-editor assertions and then threw accessibility-audit Code=-56 at line 76. The initial-Plan full audit subsequently throws the same error. Both fail before the outer step limit. Their app/test source is unchanged from 6f3; numeric success there does not establish success here.

Archived-delete executes the revised keyboard helper SHA256 `b2153c08e683875d3a0ac929993e4a1abf87ca2b206c24abd9206235b91f2a64`. Its Continue existence check at t151.76 is followed by q/Q lookup at t160.15, an 8.39-second interval; no repeated Find Continue retries appear. The original ten-second readiness assertion still fails before Keep typing or deletion. The complete 142-node failure snapshot contains q at node 105, normal frame/enabled, and no Continue. It does not measure q hittability or prove either condition was satisfied within the wait.

Create/duplicate/rename passes exact Editorial and Campaign input checks and finds Options for Campaign. It then fails the original active-row label wait after tapping Open Editorial (line 89). No actual row-label/error snapshot was retained. The test uses its original any-descendant identifier query; the resolved Other label in the log does not demonstrate a selector-type defect.

I inspected ProjectNameEditor focus and draft state: focus=true on appearance and the clear action, focus=false after validated submission, and a bounded direct draft binding. No explicit polling, onChange refocus loop or repeated submission path explains the observed delay. Archived-delete never reaches submission. ProjectLibraryView, ProjectLibraryUITests and AccessibilityAuditUITests bytes match 6f3; only the reviewed shared keyboard helper differs among these four inspected files.

A slow query and a lost idle notification do not establish app-busy or host-pressure causation. The active-project failure also lacks the state needed to distinguish an unapplied selection, displayed error, or delayed accessibility resolution. Further corrective work needs that specific observation; this record supports no assertion waiver, speculative focus/predicate change, or deadline modification.

## Evidence

- Complete console: `8fa-terminal-triage/library-reference/complete-terminal-decoded.log`, 516,410 bytes, SHA256 `809227ad66d145bc9e4c23d0997087f3fce27bb9ddf32d6b3758c34726659484`.
- Uploaded native log: `8fa-terminal-triage/library-reference/artifact/native-tests.log`, 96,444 bytes, SHA256 `61e314311255921d5630bdea70e48362fd541a8f08fe49c641976469024e797f`.

Paths are relative to `/var/tmp/keyfill-c0abc39c4f18/`. A100 owns the shared artifact/terminal packet. No source, workflow, test, deadline, execution or repository changes were made for this review.
