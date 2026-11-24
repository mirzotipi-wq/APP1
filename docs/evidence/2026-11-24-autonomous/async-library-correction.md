# KF-032 asynchronous project-library correction

## Ownership and evidence scope

Author/implementation owner: actual specialist `/root/w08_history_ownership`, assigned by the integration lead. Owned production paths are `App/ProjectStore.swift`, `App/ProjectLibraryOperation.swift`, `App/StudioView.swift`, `App/ProjectLibraryView.swift` and `App/RecoveryCapacityView.swift`; focused coverage is in `NativeTests/ProjectStoreOperationTests.swift` and `UITests/ProjectLibraryUITests.swift`. The independent review is assigned to `/root/w09_ios_critical_review`; its findings are recorded separately in `async-library-review.md`. This author report does not claim independent approval.

The implementation follows the integrated source-9 code at `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`. The hashes below identify the exact candidate verified here. Core persistence format, validation, history and the process-wide transaction lock are unchanged. The source-9 slider adapter and export implementation are unchanged; Studio integrates the new operation gate with their existing callbacks. No source was staged or committed by this worker.

## Baseline and demonstrated risk

The existing [storage benchmark](storage-benchmark.md) measured a supported approximately 8 MB legacy-name library on Linux tmpfs: median complete load **319.649 ms** and save **669.938 ms**, with validation, decode, comparison, encoding and atomic replacement included. That is actual previous host evidence, not an observed iPhone stall, a main-actor trace or a before/after UI benchmark.

Source inspection found synchronous `ProjectStore` calls in Studio initial load, save, library mutations and conflict recovery. Initial load called the synchronous function from a SwiftUI `.task`, which did not itself introduce a worker hop. In addition, `ProjectLibrary.create`, `updateActiveScene`, duplicate/import validation and debug fixture creation occurred before the storage call or in `ProjectStore.init()`. Moving only the final write would have left substantial measured work in the UI path.

No executable pre-change UI-thread blocking test was run for this packet. The controlled worker barriers below verify the corrected executor and ordering model; they must not be described as a failing native baseline or a latency speedup.

## Complete serialized worker

`ProjectStore` is now an actor retained in SwiftUI state for the lifetime of its editor. Its initializer captures configuration only. Application Support path resolution, UUID-scoped fixture creation, load/migration, command mutation and validation, full-library validation, expected-snapshot comparison, encoding and atomic replacement execute inside actor-isolated synchronous methods. There is no suspension within a transaction. The core `ProjectLibraryFileStore` process-wide lock continues to serialize comparison/replacement and migration across independent windows and store instances.

The Sendable command enum carries create/import, rename, duplicate, select, archive, restore and archived-deletion intent. The UI sends captured values rather than preparing a potentially expensive validated library first. Bounded new-name input validation remains in the name editor; whole-library and imported-scene validation are on the worker.

A queued task may be cancelled before `perform` starts. Once synchronous work starts, its receipt is authoritative: there is no cancellation check after an atomic replacement. The core recovery operation continues to compare the complete confirmed archived record, recheck capacity under the lock and append without deletion if space became available. Confirmed archived replacement still requires an existing library and cannot trigger legacy migration.

## Reservation, adoption and UI behavior

Studio synchronously reserves one operation before creating its task. The request captures an operation UUID, editor generation, active project ID, expected library and scene. The parent owns the task; child sheets receive its handle and may observe it, but their cancellation or disappearance does not cancel the parent or suppress committed-state adoption.

While reserved, the interface shows progress and disables scene mutation and additional library commands. The gate is also checked by scene bindings and actions; `.disabled` alone is not the protection. Slider and precision bindings, recipe/guided replacement, selection, add/remove, undo and redo reject busy or old-generation callbacks. Generation is included in control ownership and SwiftUI identity. There is no comparison of a large entire library merely to decide whether a completion belongs to the editor.

Adoption depends on intent:

- An ordinary save retains the current scene and history and marks only the worker's captured written scene as saved. A first save advances draft identity without resetting selection, mode or history.
- A metadata-only command retains scene/history. A successful create/import/select changes the active scene and resets history/presentation only after confirmed persistence.
- Initial load adopts its result after success. Explicit conflict reload and recovery adopt the confirmed active scene and reset history/presentation.
- Recovery-candidate reads return only choices to the recovery sheet. They never adopt the latest library over the unsaved editor.
- A stale completion cannot clear another operation's reservation. Failures clear only their own reservation and preserve current scene, saved baseline and history, apart from the preexisting explicit gesture close at a save boundary.

A save failure still exposes conflict recovery when appropriate. Corrupt initial data still enters the protected state; there is no fallback overwrite. No success status is shown before the receipt arrives.

## Import, name entry, recovery and cancellation

Provider reads retain the existing cancellation-aware `ProjectDocumentIO` implementation. Import has distinct read and commit phases. It reserves the parent operation while its read gate is still closed, then switches to commit progress. Cancel/closing during the read cancels the reader and invalidates its request token. Once commit has been accepted, closing Projects only closes the observer; the parent still reconciles the saved library. Child tokens may suppress obsolete messages, not authoritative commit adoption.

The name editor reserves synchronously from both submit-key and button paths, awaits actual persistence before dismissing and retains the draft/error on failure. Once a name save or confirmed recovery replacement is accepted, it displays progress explaining that the step finishes before closing; dismissal is temporarily disabled for that commit. Unsubmitted name entry, provider reads and recovery-choice loading remain cancellable.

Recovery-choice loads have their own cancellable request identity. A failed replacement retains the editor, clears the obsolete selection and asynchronously refreshes choices. The full candidate and capacity rules remain inside the original core operation.

## Independent isolation finding and correction

The first candidate passed its original 14 Debug/12 Release tests but regressed the DEBUG test-directory fallback. It represented `-ui-testing` solely by an optional valid test UUID. A missing or malformed `KEYFILL_UI_TEST_ID` therefore selected the normal `KeyAndFill` directory, unlike the original implementation, which always selected `KeyAndFill-UITests` when the test-launch flag was present.

The independent reviewer reproduced the defect against the frozen worker `34e413a82fc88eecabe0d9fc321bf55553c8eb10eb7b4e251e44057347558132`. With real temporary-file libraries, both missing and malformed ID cases loaded the normal saved library and changed its bytes. The [before probe](async-library-isolation-before.log) exited 1 with `isolationViolationCases=2`. This is an actual reproduced data-isolation regression in the initial candidate, separate from the earlier responsiveness-risk benchmark.

The correction retains `isUITesting` independently from the optional UUID. Every DEBUG `-ui-testing` launch now uses `KeyAndFill-UITests`; a valid UUID appends its child directory. Corrupt/full/large/conflict fixture flags continue to require a valid UUID. The new DEBUG regression sets every fixture flag for both absent/malformed IDs, performs load and two saves through the real worker, verifies the fallback test directory contains the result and checks that the normal saved library remains byte-identical.

The reviewer reran the unchanged probe against corrected worker `8bcd11b1e521d16609857110f954898db2200c841d382022ee453307e7555c9b`. Both cases now report `loadedNormalUserLibrary=false` and `changedNormalUserFile=false`; the [after probe](async-library-isolation-after.log) exited 0 with `isolationViolationCases=0`. The probe source remained SHA-256 `17538ea4b8fb619ac0401a92ba61722cf3015c1d7ad787c92a50ae697926f97a`. Historical logs are retained without overwriting. This correction changes no Core storage contract and adds no new production-file access.

## Executed checks

The isolated package `/workspace/scratch/73dcd6a65726/verification/kf032-store-operation` builds byte-identical copies of `ProjectStore.swift`, `ProjectLibraryOperation.swift` and `ProjectStoreOperationTests.swift`, using the repository's real LightingCore package. It uses a target named `KeyAndFill`, so the native test source needs no import adaptation. Its build directory is separate from the repository. The recorded toolchain is Swift 6.4.3 on Debian 13 x86_64.

| Check | Actual result | Evidence |
| --- | --- | --- |
| Earlier candidate, isolated Debug | **14/14 passed**, before the missing/malformed-ID regression test was added; the defect was present, so this result is historical only | [Original Debug raw log](async-library-debug.log) |
| Earlier candidate, isolated Release | **12/12 passed**; historical only | [Original Release raw log](async-library-release.log) |
| Corrected candidate, isolated Debug | **15/15 passed**, including the new test-launch isolation regression | [Corrected Debug raw log](async-library-isolation-debug.log) |
| Corrected candidate, isolated Release | **12/12 passed**; three DEBUG-only fixture/isolation methods are absent | [Corrected Release raw log](async-library-isolation-release.log) |
| Independent unchanged namespace probe | Original candidate: **2 violating cases, exit 1**. Corrected worker: **0 violations, exit 0** | [Before](async-library-isolation-before.log), [after](async-library-isolation-after.log) |
| Syntax parse of the seven changed/new Swift files | Exit 0, no diagnostics | [Compiler output](async-library-native-parse.log) |
| Whitespace check | `git diff --check` passed | Author command result |
| Corrected Apple SDK build, native unit execution and UI interaction | **Pending** | Must be run at the integrated corrective revision |

The tests use controlled semaphore barriers with a five-second failure bound, never sleep-based scheduling or a claimed latency target. The main-actor continuation releases an occupied actor; a timeout fails the check. Other controlled cases cancel a queued operation before any file creation, and cancel after an actual atomic write but before receipt delivery, then verify the receipt remains adoptable exactly once. Two competing expected-nil saves yield one winner and one stale rejection.

Additional cases cover duplicate command rejection, callback mutation gates, first-save/metadata/switch/reload intent, captured saved scene versus a hypothetical newer current scene, actual temporary-file stale CAS, failed command validation and retry, corrupt bytes, recovery reads preserving unsaved state, full-candidate rejection and newly available recovery capacity.

The two DEBUG fixture cases verify deferred initialization and relaunch preservation; a third DEBUG-only method covers absent/malformed test-ID isolation. The new large-library fixture is real valid persisted data exceeding **8,000,000 bytes** while remaining within the **8 MiB** core limit. It uses the supported legacy combining-mark name, saves an actual added light and reopens the same bytes with the fixture flag still enabled. It introduces no synthetic delay, fabricated success or production-library overwrite. This is a correctness/ordering regression, not a large-library performance benchmark.

Executed commands used the toolchain at `/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin`:

```sh
swift test --package-path /workspace/scratch/73dcd6a65726/verification/kf032-store-operation
swift test -c release --package-path /workspace/scratch/73dcd6a65726/verification/kf032-store-operation
swiftc -frontend -parse App/ProjectStore.swift App/ProjectLibraryOperation.swift App/StudioView.swift App/ProjectLibraryView.swift App/RecoveryCapacityView.swift NativeTests/ProjectStoreOperationTests.swift UITests/ProjectLibraryUITests.swift
```

Both the historical and corrected raw Debug/Release outputs are preserved byte-for-byte below. The same commands were rerun after the isolation correction, using new output files rather than replacing historical results. The empty compiler-output file accompanies an observed successful syntax-parse exit, not Apple SDK type checking. No full Core suite or broad benchmark was rerun by this worker; the lead owns exact integrated-source verification.

## Native acceptance additions and remaining limits

`ProjectLibraryUITests.testLargeValidLibraryCanLoadSaveBrowseAndRelaunch` exercises the actual large fixture through initial load, a dirty fourth light, save, Projects browsing and relaunch without fixture replacement. The existing unsaved-library scenario now creates a named project immediately after its first draft save while Projects stays open, checking that subsequent child callbacks use refreshed identity. The two existing save-then-open scenarios now wait for Projects to become enabled after Save, so their next action follows confirmed asynchronous completion. Existing create/rename/duplicate/select, deletion, conflict reload/recovery, capacity and save/relaunch assertions remain, with no enlarged waits or weakened outcomes.

Neither new UI scenario has run here. Native compilation, actual progress/dismissal/closure refresh, provider read-to-commit cancellation, VoiceOver and real-device responsiveness remain required. The controlled worker checks do not establish iPhone frame time, thermal behavior, low-space durability or interruption safety. The prior core transaction's one-process CAS scope is unchanged. No protected gate is promoted by this report.

## Source and raw-log SHA-256

| File | SHA-256 |
| --- | --- |
| `App/ProjectStore.swift` | `8bcd11b1e521d16609857110f954898db2200c841d382022ee453307e7555c9b` |
| `App/ProjectLibraryOperation.swift` | `0c4bff3e4d29c585bc0cd342440a5d7e3ec43fd4bc32eeec457533a87b35c413` |
| `App/StudioView.swift` | `bda97eb61f0525607f5c94a819dd4d5b28b4cd5b1f67f0d85728bff7e7e2da36` |
| `App/ProjectLibraryView.swift` | `755fa0bd68b49243c72688c19788a35b828e38a57e3803b14696ccfc635cea7f` |
| `App/RecoveryCapacityView.swift` | `9472d26320e1b88cdb51534f06e1062c7ed43990edf87ded97a5e638836f4083` |
| `NativeTests/ProjectStoreOperationTests.swift` | `647ee97a8e067b69ea280571f97c753dcbee75d2fe700371bc620276bdd480c6` |
| `UITests/ProjectLibraryUITests.swift` | `005b00dffc2f77eea10fd68c0045114fe8605729d31b752cd98205b4ef42ee99` |
| `Sources/LightingCore/ProjectLibrary.swift` | `0b6689015a9102d5b5ca6f309553455b48c047534432bc2c2b99726a242d73c4` |
| `Sources/LightingCore/SceneEditHistory.swift` | `e291eab9e8f85341ea7b3c348e1b62ef8be9c73591e9141f3e720663ba4f7d3a` |

| Raw log | Bytes | SHA-256 |
| --- | ---: | --- |
| `async-library-debug.log` | 4866 | `86750522f3b64a653ed34a74a453c7f31e20e14bf00e43e79bc558ef8e390cd5` |
| `async-library-release.log` | 4358 | `0e17f7c92be0036effc2bc6fa961a97099d092a6a7b1e01c4c22ad0265ef8151` |
| `async-library-native-parse.log` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `async-library-isolation-debug.log` | 5262 | `a67501c94af19a2cbf4d6550934598f49cf49b607500e1c100e43ae31fdc3ce3` |
| `async-library-isolation-release.log` | 4356 | `2bb6855fd71a6d229fb4b82be7e2f2498533d477bebda78793ee6befdaa68cc2` |
| `async-library-isolation-before.log` | 602 | `a36e56be0220369e8dee1b30067a4f0eea25c78197a26af12b170890b8480400` |
| `async-library-isolation-after.log` | 492 | `cb5d23f7a80a6fa9a335bd4c54a9264948012bd4db862ce7368558f8f58c7084` |
