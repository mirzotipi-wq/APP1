# f6 library/reference: terminal result and readiness investigation

Existing worker 100; read-only investigation. No app, test, timeout or workflow changes.

## Actual execution and inventory

Commit `f6f43dde19be7a554bc5c6924e3239c18b34d1be`; [run 45604744523 / job 139182923356](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523/job/139182923356). Hosted runner label: `macos-26-intel`; runner ID 1000000798. The job completed with failure at **12:49:58 UTC**. The build succeeded. The selected UI test step ran **12:13:09–12:45:29**, and the terminal log explicitly reports its existing **32-minute timeout** at 12:45:28.8744990Z.

All 11 declared methods were reconciled against starts and terminal method lines in both the uploaded `native-tests.log` and the final decoded job log. **4 passed, 5 failed, 1 started but has no terminal outcome, 1 never started; 0 skipped methods.** There is no full-suite completion summary.

| Class / method | Outcome | Reported duration |
|---|---|---:|
| AccessibilityAudit / ExactLightIntensityEditorAccessibilityAudit | Failed | 295.808 s |
| AccessibilityAudit / InitialLoadedPlanStudioAccessibilityAudit | Failed | 87.256 s |
| ProjectLibrary / ArchivedDeleteRequiresConfirmationAndPersistsOnlyThatRemoval | Failed | 175.004 s |
| ProjectLibrary / CreateDuplicateRenameSwitchAndRelaunch | Passed | 277.475 s |
| ProjectLibrary / FullLibraryRecoveryRequiresConfirmationAndPersistsEditedSetup | Passed | 158.451 s |
| ProjectLibrary / LargeValidLibraryCanLoadSaveBrowseAndRelaunch | Failed | 123.328 s |
| ProjectLibrary / StaleSaveRecoveryPreservesBothProjectsAcrossRelaunch | Passed | 180.722 s |
| ProjectLibrary / StaleSaveReloadRequiresConfirmation | Passed | 129.901 s |
| ProjectLibrary / UnsavedSetupMustBeSavedBeforeLibraryChanges | Failed | 126.183 s |
| ReferenceComparison / GuidedRigAbstainsThenAppliesAndUndoesWithoutSaving | Started; incomplete | No terminal duration |
| ReferenceComparison / ReferenceComparisonOpensWithRealStudyAndNoPhoto | Not started | — |

Full exact identifiers are retained in the linked receipt; table names omit the common `UITests` / `test` prefixes.

## Accessibility outcome

Both audit methods reached their intended target, added their pre-audit screenshot/hierarchy attachments, and failed at `AccessibilityAuditUITests.swift:76` with **Code=-56, “Audit failed to complete in time.”** No `AX-issue` details/element attachment was announced in the logs. This repeats the audit incompletion seen on b298 Intel; it provides no concrete new contrast, clipping or Dynamic Type defect and does not resolve the earlier ARM findings.

## Three library readiness failures

All three use the unchanged helper in `ProjectLibraryUITests`: predicate **`exists == true AND enabled == true`**, `XCTWaiter.wait(... timeout: 15)`, followed by failure diagnostics and equality with `.completed`. The raw failures report `XCTWaiterResult(rawValue: 2)` versus expected `1`. The predicate does not require hittability.

| Failing call site | Requested control / expected state | Proven timing and scope |
|---|---|---|
| Line 115, archived delete | `openProjectLibrary`, enabled after initial load | Failure occurs before tapping Projects, saving, creating or deleting anything. At t=19.79 the runner waits for app idle; at t=79.83 it reports no idle notification. Predicate begins t=81.88; existence retries t=96.37/96.56. A hierarchy request at t=96.66 is followed by its next logged work only at t=156.72, a 60.06-second gap. Diagnostic attachments t=170.19/171.55; assertion immediately before t=172.06 teardown. |
| Line 390, large library | `saveProject`, enabled after terminating and relaunching the same test library | Initial load, adding the fourth light, save, project browsing and return succeeded. Relaunch starts t=78.95; readiness query starts t=95.83. The log performs a Save query at t=97.08, captures debug information from t=98.48, and repeats hierarchy queries through t=120.50. Attachments t=121.32/121.88; assertion before t=121.91 teardown. The subsequent Saved locally / retained-light / four-light-count assertions were never reached. |
| Line 334, unsaved setup | `openProjectLibrary`, enabled after initial load | Failure occurs before opening Projects or testing save-before-library behavior. Predicate starts t=51.12; existence retries t=65.42/65.44. Hierarchy request t=65.46 has a 30.53-second gap before next logged work at t=95.99. Attachments t=113.68/115.29; assertion before t=115.31 teardown. |

Source enables both controls only when `loaded && !saveBlocked && !libraryOperation.isBusy`; loading begins from the studio task. The log does **not** show which of those states applied, whether the requested element was missing versus disabled, an actual incorrect project status, or incorrect persisted contents. Its Find/Checking existence lines describe query activity, not successful returned values.

The recorded idle/query delays are concrete. Their cause is **not established**: this evidence does not distinguish application responsiveness from simulator/XCTest behavior or other host factors, and contains no memory-pressure proof. A product-state mismatch or persistence/data-loss bug cannot be asserted from these logs. The failure diagnostics were created inside XCTest but were not exported, so their actual hierarchy and screenshot contents are unavailable.

## Missing finalized results and retained evidence

The result-export step failed at 12:45:34.9433650Z with **“No finalized XCTest result bundle; see native-tests.log.”** Full upload succeeded; compact upload reported no matching attachment files. There is no compact artifact or exported failure screenshot to inspect. The uploaded full artifact contains eight logs/metadata files, not an xcresult.

Artifact **15023320650**, 37,823 bytes, SHA256 **`181ad475e89081f7d0e8b3af6776defae4a0e8ab3109bd4ca5d5c4df60ed1d73`**, was downloaded, hash-verified and safely extracted here as `completed-step-evidence.zip` / `evidence/`. The full decoded terminal job log and ZIP remain in the original owned scratch receipt; their hashes, terminal errors, full job metadata and exact method inventory are preserved in the linked receipt. The artifact `evidence/native-tests.log` is 86,657 bytes. Its last ReferenceComparison activity is a query for `openPhotoComparison` at t=308.04; neither that method nor the suite has a terminal result.

No repair is proposed from an assumed state mismatch. The separately proposed build-before-boot scheduling change and ARM routing remain hypotheses until an actual unchanged test run completes. Existing assertions, selectors, audit handling and deadlines must remain intact. Continue the already authorized successor monitoring.

## Repository receipt and separate diagnostics candidate

- [Terminal metadata, inventory and hashes](../validation/library-f6-terminal/receipt.json)
- [Uploaded native test log](../validation/library-f6-terminal/native-tests.log)
- [Terminal job error excerpts](../validation/library-f6-terminal/terminal-log-excerpts.txt)
- [New diagnostics source-validation receipt](../validation/failure-diagnostics/source-validation.json)

A separate, unexecuted diagnostics candidate prints the library helper's existing captured state without another query. Studio status failures take one immutable snapshot, print a bounded expected/observed excerpt or caught error, and retain the original failed assertion. Predicates, 15/10-second waits, actions and all 36 UI methods remain unchanged. Both files passed Linux Swift frontend syntax parsing; the APIs match existing local snapshot usage. Root independently reviewed the diffs. This improves failure observability only; Apple compilation and actual diagnostics execution remain pending.
