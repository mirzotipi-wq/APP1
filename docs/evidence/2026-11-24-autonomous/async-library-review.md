# KF-032 asynchronous library: independent critical review

Date: 2026-11-24 UTC. Reviewer: `/root/w09_ios_critical_review`.

## Decision

The review found and independently reproduced a data-isolation regression in the first candidate: a Debug UI-test launch with a missing or malformed test UUID could read and overwrite normal saved projects. The author corrected it, and the unchanged independent probe now passes both cases. Two initial-load UI-test readiness gaps were also found and corrected by root without increasing their deadlines.

**No remaining source-level blocker was identified in the corrected packet at the hashes below.** It is ready for integration and corrective native verification. Apple SDK compilation, actual SwiftUI sheet/callback behavior and candidate native UI execution remain pending. Neither the host checks nor prior source-9 native results promote those gates for KF-032.

The review covered the seven author-owned files and four additional integration-test files owned by root. The implementation baseline is `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`; HEAD during review was the later documentation checkpoint `4d531e5dc669e4eab852b766cdb9739a5d70c67d`. The reviewed App/NativeTests/UITests baseline did not change between those commits. Review began against an unstaged candidate; the file hashes below identify the reviewed source independently of subsequent root-owned staging. Room-status and CI-policy changes are excluded.

The reviewer made no application/test-source edits, staged or committed nothing, and spawned no new agent. Root separately authorized preserving the small independent probe and raw logs alongside this report. Correction work reused the existing `/root/w08_history_ownership` author.

## Findings and corrections

### Resolved blocker: invalid UI-test configuration reached normal saved data

The original synchronous `ProjectStore` selected `KeyAndFill-UITests` whenever `-ui-testing` was present, then optionally appended a valid UUID. The first actor candidate stored only the parsed optional UUID. A missing or malformed `KEYFILL_UI_TEST_ID` therefore became indistinguishable from an ordinary launch in `prepareStore`, which selected `KeyAndFill`. UUID checks still protected fixture injection, but no longer protected ordinary test-launch loads and saves.

The reviewer used a standalone executable with byte-identical copies of the candidate actor/helper and the real LightingCore package. Each case created a genuine saved project in a fresh temporary normal directory, launched the actor with `-ui-testing`, loaded, then performed an ordinary save. It compared the normal library and original file bytes. No actual user directory was accessed.

With worker SHA-256 `34e413a82fc88eecabe0d9fc321bf55553c8eb10eb7b4e251e44057347558132`, the [before log](async-library-isolation-before.log) records exit **1** and:

```text
case=missing loadedNormalUserLibrary=true changedNormalUserFile=true
case=malformed loadedNormalUserLibrary=true changedNormalUserFile=true
isolationViolationCases=2
```

The author retained `isUITesting` independently of the parsed UUID. Every Debug `-ui-testing` launch again selects `KeyAndFill-UITests`; a valid UUID optionally adds its scoped child directory. All four fixture flags still require a valid UUID. The correction restores the prior directory policy and leaves Release behavior unchanged.

Only the worker snapshot was replaced for the second run. The [probe source](async-library-isolation-probe.swift) was unchanged, SHA-256 `17538ea4b8fb619ac0401a92ba61722cf3015c1d7ad787c92a50ae697926f97a`. With corrected worker SHA-256 `8bcd11b1e521d16609857110f954898db2200c841d382022ee453307e7555c9b`, the [after log](async-library-isolation-after.log) records exit **0** and:

```text
case=missing loadedNormalUserLibrary=false changedNormalUserFile=false
case=malformed loadedNormalUserLibrary=false changedNormalUserFile=false
isolationViolationCases=0
```

The added DEBUG regression in `ProjectStoreOperationTests` covers both invalid configurations with every fixture flag enabled. It requires an initially empty fallback test library, performs two actual saves in that test directory, checks its saved scene/count, and checks that the normal project and normal file bytes remain unchanged. The second save also checks that the conflict fixture does not activate without a valid UUID. This closes a real gap in the initial 14/12 passing packet; those earlier passes are preserved as historical evidence rather than represented as having covered this case.

### Resolved readiness gaps: existence did not establish completed initial load

With asynchronous loading, the Recipes toolbar button and Export header button exist while loading, but are disabled. The initial project-status text also already says `Unsaved changes` because the saved baseline is nil. Consequently, the old initial checks in `StudioSmokeTests.testRecipeEditSaveAndReopen` and `LightingPlanExportUITests.testExportPreviewOpensWithoutSavingOrChangingScene` could pass before their first button could accept a tap.

Root replaced only those two initial existence checks with the shared `waitForEnabledStudioControl`, requiring `exists && enabled` using the same **15-second** limit. The downstream recipe, chooser, cancellation, document and scene assertions remain unchanged. This is a source-defined readiness race; no native failure is attributed to it without execution evidence. Scene controls rendered only after `loaded` have a different readiness boundary and were not changed merely because they use existence checks.

## Transaction, state and lifetime review

### Complete work crosses the actor boundary

`ProjectStore` is retained in Studio's `@State`, so the editor uses one actor. Initialization captures configuration only. Directory selection, fixture creation, load/migration, command application, scene/name/library validation, expected-snapshot comparison, encoding and atomic writing happen in actor-isolated synchronous methods. There is no suspension within `perform`, `recoveryCandidates` or their storage transaction calls.

The UI sends Sendable commands and captured values. It no longer constructs and validates a complete replacement library before calling storage. The bounded name-entry check remains local to the editor; potentially large library and imported-scene validation occurs on the worker. The existing Core process-wide lock and file format are unchanged. In Core, normal save still compares the loaded library with the expected snapshot under the transaction lock; recovery still validates the full confirmed archived record and rechecks capacity before deletion. Confirmed replacement still requires the current library file and does not fall back to legacy migration.

This addresses the source path responsible for performing the previously measured storage work on the UI executor. It does not establish a device latency reduction, a frame-time target, or a guarantee that all rendering work for large content is inexpensive.

### Reservation and adoption are explicit

`beginLibraryOperation` reserves synchronously before creating its task. It captures operation identity, editor generation, active project ID, expected library and scene, then closes the current gesture. A second request is rejected before it can end another gesture or enqueue storage work. The completion verifies request identity/generation/project identity. A delayed completion cannot clear a newer reservation.

| Operation | Reviewed adoption behavior |
| --- | --- |
| Initial load | Adopts the loaded active scene after success, or retains the captured initial draft when no library exists; resets initial history. A failed load enters the protected state. |
| Ordinary save | Preserves the current scene/history and sets the saved baseline from the worker's written scene. A first save changes generation while retaining history, selection and mode. |
| Metadata or organization with the same active project | Preserves scene/history/presentation and updates the saved library only after persistence succeeds. |
| Create/import/select that changes active project | Adopts the confirmed active scene and resets history/presentation after success. |
| Confirmed reload or recovery | Adopts the confirmed active scene and invalidates old controls, including reload of the same project ID. Failures retain current edits and history. |
| Recovery-candidate read | Returns only archived choices to the recovery sheet; it does not enter Studio adoption or reset the unsaved editor. |

The ordinary-save branch also preserves a hypothetical newer current scene while marking only the returned written scene saved, preventing a future relaxation of the busy policy from silently marking later edits persisted. In the current UI, busy/generation checks reject scene mutations while an operation is reserved.

The relevant setters and actions were traced directly: light values and optics, camera position/lens, preview settings, recipe/guided replacement, add/remove, selection and undo/redo. They use the operation gate in addition to disabled controls. Generation is part of control ownership and identity. Gesture-end callbacks retain owner-specific history checks, so an old control's end cannot close another owner's edit.

### Parent-owned commits and cancellable reads

The storage task is created by Studio and returned to children as a handle. The child creates an observer that awaits `task.value`; closing that observer does not call `cancel` on the parent task. Studio performs adoption inside its own task and does not discard the result based on a child request token or a post-write cancellation check. The actor checks cancellation before beginning work, and does not throw cancellation after a completed atomic write.

Import retains a cancellable provider-read phase. After a read succeeds, it rechecks local state and reserves the parent operation while the read gate is still closed, then changes to commit progress. Closing/cancelling during the read invalidates its token and cancels the read; after accepted commit, the token controls only obsolete child messages. The parent receipt still reconciles the library. Import construction and persistence errors leave the original displayed library and editor in place.

Name entry reserves synchronously, rejects repeated submit/button activation while submitting, waits for persistence before dismissal, and retains the draft/error on failure. Confirmed recovery uses the same receipt boundary and refreshes stale choices after an error. Both explain their temporary commit-stage dismissal restriction. Recovery-choice loading remains separately cancellable and never adopts over dirty edits.

Studio does not cancel a reserved operation when scene phase changes; it closes the current gesture. Background suspension, forced process termination and actual SwiftUI dismissal timing were not executed in this review. The code and host checks support the ownership model, but do not replace those native lifecycle observations.

## Test evidence and its limits

The reviewer inspected the raw logs and independently compared the harness copies with repository source. The harness compiles the real `ProjectStore.swift`, `ProjectLibraryOperation.swift` and `ProjectStoreOperationTests.swift` under a small target named `KeyAndFill`, linked to the repository's real LightingCore package. It does not compile the SwiftUI views. Debug and Release use Swift 6.4.3 on Linux; the native project also remains in Swift 5 language mode, but Apple SDK type checking is still separate.

| Evidence | Observed result | Scope |
| --- | --- | --- |
| Original isolated actor/helper suite | 14/14 Debug; 12/12 Release | Historical initial candidate; did not cover invalid test-launch isolation. |
| Corrected isolated actor/helper suite | **15/15 Debug; 12/12 Release** | Final byte-identical worker/helper/tests; three fixture/configuration methods compile only with DEBUG. |
| Independent normal-directory isolation probe | Before: 2 violating cases, exit 1. After: 0 violating cases, exit 0. | Same executable logic, real temporary files, only actor snapshot changed. |
| Reviewer syntax parse | **11 files, exit 0**, no diagnostics | Swift parsing only; no Apple frameworks were type-checked. |
| Scoped whitespace check | Exit 0 | Reviewed source/test paths. |
| KF-032 Apple build/native UI run | **Pending** | No native pass claimed by this report. |

The controlled barriers meaningfully test queued cancellation before file work, availability of the main-actor continuation while the worker is occupied, competing real saves, and delivery of a receipt after cancellation following a real atomic write. Actual temporary-file tests cover stale CAS, invalid commands, corrupt saved bytes, candidate replacement and newly freed capacity. The large fixture test checks real bytes above 8,000,000 and within the 8 MiB cap, then validates save/relaunch preservation.

The boundaries of these tests matter. The post-commit test manually applies the adoption helper after cancelling its saving task; it does not dismiss a live SwiftUI sheet. The gate test invokes the shared gate rather than delivering callbacks from five actual controls. History and adoption tests exercise the policy values and real history type, not Studio's view lifecycle. Recovery-choice tests establish the return-value/storage behavior; they cannot independently establish every presenting-view interaction. No frame-time or device-responsiveness claim follows from the barrier or large-fixture checks.

### Integration assertions were preserved and extended

The existing unsaved-library UI scenario now creates `After first save` while Projects remains open after its first draft save. If the child retains a stale generation closure, that next persisted command cannot reach its asserted result. This is the appropriate native integration check for the first-save identity transition, but it has not run for KF-032 here.

The added large-library UI scenario checks successful load, a genuinely dirty added fourth light, confirmed save, Projects browsing, and relaunch with the fixture flag still enabled. Its independent worker test verifies that the fixture is genuinely large and does not replace saved edits. The UI scenario is functional acceptance, not a timing benchmark.

Root added `waitForCommittedProject` at three StudioSmoke and three Precision save continuations before process termination or room navigation. Each reviewed call follows actual edits in a fresh unsaved setup, so waiting for `Saved locally` establishes the needed receipt boundary there. The shared predicate uses the existing Studio status bound of 10 seconds. Author-owned library scenarios also wait for Projects to become enabled after their two immediate save-then-open actions. No model assertions, precision values, original optics one-Undo assertion, fixture semantics or existing timeouts were weakened.

## Final reviewed source identities

| File | SHA-256 |
| --- | --- |
| `App/ProjectStore.swift` | `8bcd11b1e521d16609857110f954898db2200c841d382022ee453307e7555c9b` |
| `App/ProjectLibraryOperation.swift` | `0c4bff3e4d29c585bc0cd342440a5d7e3ec43fd4bc32eeec457533a87b35c413` |
| `App/StudioView.swift` | `bda97eb61f0525607f5c94a819dd4d5b28b4cd5b1f67f0d85728bff7e7e2da36` |
| `App/ProjectLibraryView.swift` | `755fa0bd68b49243c72688c19788a35b828e38a57e3803b14696ccfc635cea7f` |
| `App/RecoveryCapacityView.swift` | `9472d26320e1b88cdb51534f06e1062c7ed43990edf87ded97a5e638836f4083` |
| `NativeTests/ProjectStoreOperationTests.swift` | `647ee97a8e067b69ea280571f97c753dcbee75d2fe700371bc620276bdd480c6` |
| `UITests/ProjectLibraryUITests.swift` | `005b00dffc2f77eea10fd68c0045114fe8605729d31b752cd98205b4ef42ee99` |
| `UITests/StudioContentReachability.swift` | `4d26e60236bf0320fccfdb293364fe546ed2683d5b264a0fa8822fb6059c5419` |
| `UITests/StudioSmokeTests.swift` | `8588e3ca7804d502542d248fbff35b601a76532590478d78482f9a6c76cc2dd6` |
| `UITests/PrecisionEditingUITests.swift` | `4601a7cd005443472a505d3d26cfb94ec3c82f7f4cbb4d8ef1ab112b3f4c51f3` |
| `UITests/LightingPlanExportUITests.swift` | `fc489759e8a1049802f3d7395b3052c4d8b72f5baa8bbd73b86a04f15a83e114` |

## Reproducibility and retained evidence

Corrected focused results are preserved in [async-library-isolation-debug.log](async-library-isolation-debug.log), SHA-256 `a67501c94af19a2cbf4d6550934598f49cf49b607500e1c100e43ae31fdc3ce3`, and [async-library-isolation-release.log](async-library-isolation-release.log), SHA-256 `2bb6855fd71a6d229fb4b82be7e2f2498533d477bebda78793ee6befdaa68cc2`. Original 14/12 results remain in `async-library-debug.log` and `async-library-release.log` without replacement. Author implementation details remain in [async-library-correction.md](async-library-correction.md).

The independent probe package is `/workspace/scratch/73dcd6a65726/verification/kf032-review-isolation-probe`. It uses a Swift tools 5.9 package, an executable target containing the preserved probe plus actor/helper copies, and the local LightingCore package dependency. Original actor/helper/probe snapshots are retained in its `before` directory. The command executed for each worker snapshot was:

```sh
/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swift run --package-path /workspace/scratch/73dcd6a65726/verification/kf032-review-isolation-probe NamespaceProbe
```

The retained before/after raw log hashes are respectively `a36e56be0220369e8dee1b30067a4f0eea25c78197a26af12b170890b8480400` and `cb5d23f7a80a6fa9a335bd4c54a9264948012bd4db862ce7368558f8f58c7084`. The two `safeExec` signal warnings in those logs are preserved; the functional outputs and process exit codes above are the observed probe results.

The reviewer parsed the eleven files in the source-identity table with `swiftc -frontend -parse` from the same toolchain, and ran `git diff --check --` scoped to those paths. After execution, only the independent probe's reproducible `.build` cache was removed; probe source, original snapshots and raw logs were retained. No broad suite, repeated benchmark or speculative implementation change was added by this review. Native evidence should next identify the integrated KF-032 revision and complete the existing library/recovery/history/export scenarios, including the two new acceptance paths. Missing native evidence remains pending rather than inferred from this review.
