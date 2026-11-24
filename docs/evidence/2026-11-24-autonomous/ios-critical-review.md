# Independent iOS state and data-flow review — 2026-11-24

## Outcome and review boundary

No additional demonstrated P0/P1 data-loss, stale-import-adoption or project-switching defect was established in the reviewed source. One remaining name-display defect was identified and corrected by a separately assigned worker during this review: a valid preserved name containing only invisible characters produced an empty studio or backup heading, and empty light names in several studio controls. The correction supplies contextual visible labels without changing stored data. This report also specifies an asynchronous-storage follow-up justified by an actual supported-input benchmark; it does not change the storage API.

Reviewer: actual specialist `w09_ios_critical_review`, independently assigned by the integration lead. Base revision: `0fce248b4e61bace88002b40f6c56fddedb19c8a`. The review includes the pending owner-qualified history callbacks, invisible-name policy, backup UI assertions and reference privacy wording identified by the hashes below. Renderer cancellation and Float32 eligibility were being reviewed by their separate owners; their portable results do not constitute this review's native acceptance.

The protected `AGENTS.md`, product/quality contracts, architecture, design, operating protocol, roadmap and active M01 state were read. This is source inspection plus inspection of existing execution logs. This reviewer ran no Apple SDK, simulator, physical device, Photos/Files provider, VoiceOver session or system export destination, and did not rerun a full test suite. No source edit, staging, commit, quality-threshold change or release approval is implied.

## Concrete finding and correction: visible identity for legacy names

**N1 — P2 accessibility/identity gap for affected light controls; P3 for an isolated blank project heading.** The existing `testInvisibleLegacyNamesRemainStoredButSelectTheVisibleIdentityFallback` passes with valid stored project names such as U+200C, U+200D and U+FE0F. Their bytes survive encoding/reopening, while `StudioDisplayName.display` intentionally returns an empty string. `StudioLight.isValid` also accepts such non-whitespace names. This preserves old data, as intended.

The inspected `StudioView.projectHeading`, light rack text, light inspector heading, plan marker labels and plan selection accessibility labels consume `display(...)` without a fallback. `ProjectBackupView` does the same for its title. Two otherwise similar lights with these names therefore have no useful name in the corresponding text, and the plan's explicit label becomes `Select  on plan`. This is a source-derived reproduction, not a claim that a native accessibility tree was inspected. The Projects and capacity-recovery views already map empty display names to `Unnamed project` and expose a short record identity; room notes already supply a point-kind fallback.

Smallest correction: add contextual visible fallbacks at the affected presentation boundaries, using `Unnamed project` and an ordinal or short stable identity for an unnamed light. Preserve the raw stored name and editable-copy contents. Do not reject existing libraries or rewrite old names to solve a presentation issue. A narrow core/presentation assertion can prove the chosen strings, while the actual plan/rack/backup display and VoiceOver labels remain native verification. This finding was sent to the integration lead before any production edit. The lead assigned a separate `w09_visible_identity_correction` worker to the correction; this report records the reviewed pre-correction state and the reviewer owns only this report.

**Correction reviewed before closing this report.** The worker added `StudioDisplayName.label(_:fallback:)` and contextual callers in the studio, backup title, import confirmation and room measurement headings. Light fallbacks use their scene ordinal, with short identity as a defensive fallback; the project label is `Unnamed project`. `LightingPlan` now uses the same bounded sanitizer, activating its existing report-title and numbered-light fallbacks for these names. The reviewer inspected the narrow diff and the worker's actual `visible-identity-debug.log`: **24/24 targeted name/plan tests passed**, including two added regressions that preserve the editable document's original bytes and ordinary joined Unicode names. Existing history-owner changes and backup accessibility identifiers remain in the working source. N1 is corrected at source/portable-test level; actual native layout and accessibility remain unverified. The separate post-correction hashes below retain this distinction.

## Persistence and project transitions

| Boundary | Source finding | Limit of the conclusion |
| --- | --- | --- |
| Opening existing data | `load()` assigns a returned library only after the store returns. Decode/read failure enters the protected state; editing, saving and export actions are disabled. Initial history/selection reset occurs only after successful load. | Actual locked-device, low-space and interrupted-startup behavior is unrun. |
| Ordinary save | Studio closes the current history transaction, proposes a value copy and calls `saveLibrarySnapshot`. The store validates the proposal, holds one shared process lock while loading/comparing the expected library and replacing bytes, then returns. Studio assigns `library` and `saved` only after success. | Synchronous execution prevents local edit interleaving today, but costs UI time. An asynchronous conversion must preserve the captured-scene semantics described below. |
| Create/select/rename/duplicate/archive/restore/delete | `ProjectLibraryView.apply` requires a clean editor and creates a proposed copy. `StudioView.applyLibrary` independently rechecks cleanliness and the active record, saves first, then adopts the library. A switch resets history and selection only after the successful write. | No native switching or relaunch result for the pending owner changes was executed by this reviewer. |
| Stale window | The complete expected library is compared with the latest stored value. A stale result sets the conflict state and leaves the current editor open. Import goes through this same boundary. | The lock is in-process; it is not a cross-process filesystem transaction or protection from arbitrary external inode mutation. |
| Recovery at capacity | Recovery rechecks the latest data and the complete confirmed archived candidate. If capacity has opened, it appends without deleting; otherwise deletion/insertion remain in a local value until one successful bounded write. The original editor is adopted only afterward. | Ordinary load/recovery may migrate a retained legacy file if `projects.json` is missing. The explicitly confirmed archive-replacement path requires the existing current library. These are different contracts. |
| Destructive operations | Archive deletion and discarding this window's changes require explicit UI confirmation. External exports, Photos originals and retained legacy migration data are not deleted by these paths. | Atomic replacement is not evidence of power-loss durability or secure erasure. |

No additional API change is justified merely to make these already-tested transactions look more asynchronous. The measured cost below supplies a specific follow-up with its own correctness tests.

## Async tasks, actors and lifecycle

### Editable import

The selection callback runs on the main actor. It captures a new request UUID, sets the importing state and awaits `ProjectDocumentIO.read`. That helper moves the actual coordination/read/decode into a utility detached task. Cancellation reaches both the worker task and the lock-protected `NSFileCoordinator` cancellation holder, including cancellation before a coordinator is installed. Security-scoped access encloses coordination and the supplied accessor URL; the shared descriptor reader checks the opened file type and bounds actual bytes.

After awaiting, the UI checks both task cancellation and request identity before applying anything. It drops the importing flag immediately before the synchronous `apply` transaction; there is no suspension between that change and the save/adoption. Success appears only after `onApply` returns. Cancellation invalidates the token and clears the task reference. The Done button also rejects further selections before dismissal.

The `.onDisappear` exception while `showImporter` is true is a deliberate picker-presentation accommodation, not demonstrated lifecycle correctness. Native tests must cover presenting Files, selecting a slow provider, cancelling, interactive dismissal, reopening and a late provider callback. An actual callback that can reach a detached sheet after dismissal should be reproduced before changing this logic; source speculation alone is not grounds for a broad presentation rewrite.

### Editable export

The menu creates an immutable name/scene snapshot. `ProjectBackupView.prepare` encodes that value in a detached utility task; cancellation propagates and a cancelled result cannot set `prepared`. The file document contains immutable bytes. Export completion sets a saved message only on success; neither preparation nor cancellation invokes the project store.

The pending full-capacity UI test verifies preparation of a four-light unsaved snapshot, return with history intact, undo to three lights, preparation of a new snapshot with redo intact, and relaunch with the original saved project. The test deliberately never selects a system destination. It therefore cannot establish successful Files export, destination replacement confirmation, importer/provider behavior or a complete recovery escape on a real device.

### Reference comparison

The view checks cancellation and its request UUID after `loadTransferable`, before constructing/publishing a `UIImage`. Failed or cancelled replacement keeps the old reference, tonal summary and guided work. Explicit Remove, Done and apply clear that session. Applying a rig calls the studio's ordinary reversible replacement path and does not save the project. Candidate geometry/provenance and the retained camera/subject values were inspected; no automatic image-analysis or exact reconstruction claim appears.

`onDisappear { clear() }` must be tested with actual PhotosPicker presentation and dismissal. It does not, by source alone, prove that a cancelled replacement preserves the prior photo under every native covering/presentation sequence. The inactive-photo overlay and released app references also do not prove app-switcher masking, OS-cache deletion or secure memory erasure. Current privacy wording correctly limits the statement to a reduced copy without the original photo metadata.

### Study and meter tasks

The study task identifies work by scene plus subject, debounces, awaits the serial render actor and rejects cancelled output. The displayed frame must match the current request. CPU work and synchronous GPU completion are inside the render actor rather than the view's image-publication path. The neutral-card task captures a scene value and uses a detached worker, then rejects a cancelled result. These source structures support stale-frame prevention; they do not measure native responsiveness.

The pending cancellation work polls more frequently inside the CPU render loops. That does not mean GPU submissions can be interrupted or that setup/decode/validation work has a uniform millisecond cancellation bound. The separate renderer performance report retains those distinctions. The Float32 boundary/kernel/eligibility packet needs its own integrated parity and native Metal checks; no general GPU certification is inferred here.

## Gesture ownership and undo

The existing failure log reproduces the old sequence: gesture A closes, B begins, and a delayed A end closes B. Four assertions fail in the original test. The pending model keeps a transaction owner, commits when a different owner starts, and ignores end events from another owner. The inspected integration captures project, light and field identity when constructing callbacks; it does not look up the selected light when an old callback finishes. Project-scoped `.id` values prevent reusing the corresponding camera, meter, optics and light-edit subtrees across project/light changes. Explicit save, selection, mode and lifecycle boundaries still force-close the current transaction, and successful switching/recovery resets it.

The existing final targeted logs report **15/15 history tests passing in Debug and Release**, including the regression. This establishes the modeled event behavior. It does not prove arbitrary native slider callback ordering. An owner identifies a control, not an event generation: late end A from the same control/project can still be indistinguishable from end B after a new gesture starts. The source now documents that limitation. Actual overlapping/multitouch/interruption behavior must be observed before adding a generation-token API or claiming that every possible callback ordering is handled.

## Room placement and notes

The room sheet receives a scene value and keeps its measured-room state locally. Fields separate draft text from committed values; notes capture `plan.textSummary(locale:)` when the user asks to review. The nested preview and ShareLink use the same immutable string. The note view has no mutable library/scene binding, and dismissing it cannot write a project. Invalid drafts are excluded by construction and the UI explicitly asks the user to press Set before including an edit.

The source preserves signed coordinates, describes the positive rotation convention and labels center/rectangular-face bounds separately. It makes no AR, full-fixture collision or clearance guarantee. These are useful manual measurements with explicit limits. Actual share destination text, nested dismissal, keyboard presentation, Dynamic Type and VoiceOver remain native checks. Their absence does not justify claiming the export gate has passed.

## Safe asynchronous-storage follow-up

The optimized Linux/tmpfs benchmark in [storage-benchmark.md](storage-benchmark.md) uses actual validated records and byte-verified readbacks. Its supported approximately 8 MB legacy-name fixture reports median load **319.649 ms** and save **669.938 ms**, with maximum measured save **723.468 ms** over five measured samples. A 64-project/twelve-light-per-project fixture reports median save **26.964 ms**. These are host transaction costs, not observed iPhone stalls, UI frame times or disk-durability results.

`ProjectStore` remains synchronous, and Studio/Projects/recovery call it directly from UI actions or the initial view task. A view `.task` does not by itself introduce a background hop for the synchronous function it calls. Moving only `Data.write` would leave the measured validation/decode/compare costs in that path.

The smallest safe follow-up is a separate storage executor around the **complete existing operation**, not a new persistence format:

1. Capture immutable expected library, proposed library, scene, active project ID and a UI operation identity on the main actor. Perform validation, load/migration, optimistic comparison, encoding and replacement on the storage executor, keeping the existing process-wide lock and bounds.
2. Choose a concrete edit policy. A short busy state that prevents save, switch, import, destructive operations and scene edits until the operation settles is simpler than allowing interleaving. If ordinary scene editing remains enabled, successful save must assign `saved` to the captured scene, retain any newer current scene as dirty and retain its history. Assigning `saved = scene` at completion would falsely mark later unsaved edits as persisted.
3. Treat write completion as authoritative. Cancellation before starting a transaction can skip it. Cancellation after a committed write must not be reported as if nothing was saved, nor may a stale UI continuation adopt another project's scene. The controller must reconcile the committed library even when a presenting sheet has closed; view disappearance cannot roll back a completed filesystem operation.
4. Preserve failure behavior: stale/corrupt/oversized/disk errors leave the current scene/history and existing saved bytes intact. Recovery must keep the full candidate comparison and the capacity-recheck behavior inside the transaction.
5. Add focused deterministic tests with a controllable storage worker: edits during ordinary save, attempted switch/import while saving, duplicate save taps, cancellation immediately before/after commit, close/reopen after a commit, competing window writes and recovery failure. Then measure the real large-library flow on the baseline iPhone.

This plan was sent to the lead as a follow-up. No asynchronous API or concurrency contract was changed during this review.

## Evidence inspected and acceptance still required

The reviewer inspected the existing raw logs under `/workspace/scratch/73dcd6a65726/verification`:

| Artifact | Observed result | What it establishes |
| --- | --- | --- |
| `cycle4-exact-debug.log`, `cycle4-exact-release.log` | 212 tests, zero failures in each configuration | Portable committed-source coverage at the base packet; not all pending source or iOS execution. |
| `history-ownership-before.log` | Original ownership regression: four failed assertions | The modeled defect existed before the pending correction. |
| `history-ownership-after-debug.log`, `history-ownership-after-release.log` | 15 tests, zero failures in each configuration | Final targeted portable history model behavior. |
| `invisible-names-after.log` | Nine tests, zero failures; legacy invisible names explicitly round-trip | The display returns empty while persisted names remain valid and unchanged, which exposes N1 at remaining UI call sites. |
| `visible-identity-debug.log` | 24 targeted name/plan tests, zero failures | Contextual fallback and report behavior after the independently assigned N1 correction; includes unchanged editable-document bytes. |
| `storage-benchmark.md`, including complete embedded raw output | Five verified measured samples per operation; sizes/timings and limitations recorded | A supported-input synchronous workload and a concrete async-storage rationale. |
| `0fce248-room-precision-failure.log` | Native `CompileMetalFile` failed because the runner lacked the Metal Toolchain; test build exited 65 | An actual current-base runner prerequisite failure, before a completed native UI test run. |

The reviewer read the log retrieved by the integration lead for [run 45355893140 / job 138314533755](https://github.com/mirzotipi-wq/APP1/actions/runs/45355893140/job/138314533755). At `2026-11-24T08:38:03.6177690Z`, the native room build reports that it cannot execute `metal` because the Metal Toolchain is missing. The log then reports `TEST BUILD FAILED` and exit 65. Its compiler paths identify Xcode 26.6 and iPhoneSimulator26.5; this is an observed runner prerequisite failure, not an independently reproduced Swift source defect or a UI test result. The inspected log's SHA-256 is `93cbb6bbb64b2e2c5af41ea215d1359513d04e67b2a99107b96b3ddaf71b1de7`. The lead owns its CI repair. Earlier native build/unit/library successes remain historical and cannot certify the pending history, names, cancellation, backup, provider or kernel work.

Required next evidence remains: integrated Apple Debug/Release build and native units; current room/studio/library UI shards; actual export and reopen/import with local/iCloud/third-party providers; cancellation and late completion; full-capacity recovery; save/relaunch and corruption protection; interruption and low-space behavior; real-device accessibility and performance. M01's current `native_build` and `persistence_smoke` gates must remain unresolved until their actual acceptance evidence exists. No rendering, AR, commerce, customer-validation or release gate is promoted by this review.

## Reviewed source identifiers

These hashes identify the reviewed pre-integration files, including pending work. A later correction to N1 or other source requires updating its acceptance evidence; the hashes should not be silently relabeled as a later tested revision.

| File | SHA-256 |
| --- | --- |
| `App/StudioView.swift` | `3ec981596f8f336c259624393cabf4af34133bda93d7a06cbdd15f3f8443f3fa` |
| `App/ProjectStore.swift` | `332a68434f50448db206632d03dfb35f969324513977c176a802184ffe731f2b` |
| `App/ProjectLibraryView.swift` | `db89c09d25fa1f912b8f2fad3a454ab60d24e93c23fe9bded05e546723c96cc8` |
| `App/ProjectBackupView.swift` | `bd5b36764d070776866cc89bec13c18d2d4a4c6825986a7f5f3ac3d0814b4d2d` |
| `App/ProjectDocumentIO.swift` | `a8f5b7f0be19e81c9f25e1f2a0e022cddb75ec9756e6ae6e0d9a2e99d2d3bf7c` |
| `App/ReferenceComparisonView.swift` | `04fb6ca38623265210ed50b228ac662b541f9ba415756f5bb9bfec79fc86d443` |
| `App/ReferenceStudyPreview.swift` | `598ef28a8c5b0e84e47c09f18a557c1e68ad463c3b82c732a3d3277596312dfe` |
| `App/ManualRoomPlacementView.swift` | `34e32418bbcf585a66583c302a570fbab45a13465a51a70a58e8138c7ba3a753` |
| `App/CameraInspector.swift` | `e80d146c9dfaff52cdb1e54d28fb75c2282ba5583e11f677e9e4ef4ab35325c5` |
| `App/NeutralCardInspector.swift` | `6b9b87d3fd940a851f9f338fb284839adfbdb4e07823c456cebd923eccedb989` |
| `App/OpticsInspector.swift` | `d62d9b43e75f5ab7e3e3feb9446174d37167ad2a88a9aa75d1c21f6bd7c4b475` |
| `Sources/LightingCore/SceneEditHistory.swift` | `e291eab9e8f85341ea7b3c348e1b62ef8be9c73591e9141f3e720663ba4f7d3a` |
| `Sources/LightingCore/StudioDisplayName.swift` | `c4b25fc1489cb12c0a0f8e301c977dcb7e94a53ede28eff28c4db2fb2d106d54` |
| `UITests/LightingPlanExportUITests.swift` | `5ef817d965984662cd04e218c8f6a25dd811766864114232f3d4b8b8dc411be7` |

### Post-correction source inspected for N1

| File | SHA-256 |
| --- | --- |
| `App/StudioView.swift` | `c8c317d7a5ae5c6182dd85fce28f28d49c71c91f73c6cec5865e4d6040104774` |
| `App/ProjectBackupView.swift` | `93b8a57b48977fde6f95d75eb5a2e48d81bed0c9c3c28a2e225245f8dcf54330` |
| `App/ProjectLibraryView.swift` | `7fdaf1d733c6ae8be51e320c17fda78b6047d7dbf23caba6af23ad60d28cd9e8` |
| `App/ManualRoomPlacementView.swift` | `d2f30fa2cd4ff63a58f8a4747dec0e5bdd94d10ee5ccae34e62bba10215fbcb8` |
| `Sources/LightingCore/StudioDisplayName.swift` | `4e257e8ac1924093cafa2a1046b52fa3581f709a9a4ec8bc80ff37f515bdba63` |
| `Sources/LightingCore/LightingPlan.swift` | `099c94268ca31af5e1311b5fc570833967bec61f54674115b7f3ad0188580b8e` |
| `Tests/LightingCoreTests/StudioDisplayNameTests.swift` | `98abca03ccdbfecc65d24441227f06682f402423723128e04a536c4a62d12e61` |
| `Tests/LightingCoreTests/LightingPlanTests.swift` | `b5b7ea1e45f4ef278ba6871820cb2acc9f8f5784d44a97ebda01e5e658618ae5` |
