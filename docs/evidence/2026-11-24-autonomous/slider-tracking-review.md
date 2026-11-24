# Independent review: explicit native slider tracking

## Decision

**Approved for scoped source integration. The observed P1 optics gesture regression remains open pending actual iOS acceptance.** No remaining concrete source blocker was found in the frozen nine-file candidate after the corrections described below. This recommendation permits the integrated build and native verification; it does not mark the editing, accessibility, persistence, or release gates passed.

Reviewer: existing specialist `/root/w09_ios_critical_review`. Author: existing specialist `/root/w01_evidence_audit`. No additional agent was spawned. The reviewer read source, diffs, actual retained logs, test harness commands, hashes and the original failure evidence. The reviewer did not edit executable source, stage, commit, run another compiler/test suite, or rerun benchmarks. Root subsequently applied the frozen patch on top of the independently reviewed plan-caption changes.

The contract relevant to this decision is precise numeric editing with undo/redo, stable ownership and no lost edits, together with honest evidence at a known revision. `AGENTS.md`, `docs/PRODUCT.md`, `docs/QUALITY.md`, `docs/DESIGN.md` and `docs/ARCHITECTURE.md` require actual native verification and do not allow a portable test or syntax parse to satisfy an unrun native gate.

## Frozen inputs and verification

Candidate base: `5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`, tree `aaf52e62fff970cdc55f5908326523e58a1cf394`. The candidate directory is `/workspace/scratch/73dcd6a65726/verification/slider-tracking-candidate`.

| Frozen artifact | SHA-256 |
| --- | --- |
| [Nine-file patch](slider-tracking-candidate.patch), 44,160 bytes | `07c1d45be04b4c8660e7d5cad3b28fb3d224d4a3ad294d29ef1bd53461c9410b` |
| [Manifest](slider-tracking-manifest.json) | `005a7eba3c37e44e7b9277a0f0e9bf14c676c0e9b60cf110cee063addc682ee0` |
| [Author report](slider-tracking-report.md) | `dde051f2b6ec69d35b4aa9e3352394a76ebf46aa443dc6b397af02a7864d1c40` |

The reviewer independently checked 73 hash/content comparisons: nine candidate source entries, 30 retained artifacts, four unchanged adapter/history contracts, and 30 inputs recorded for the portable tests. All matched. The ten source hashes in the final [syntax record](slider-tracking-raw/native-syntax.json) also matched the frozen files. Test-method discovery was checked against the actual sources: all eight adapter, fifteen history and fifteen tracking methods are enumerated in the harness. The [commands](slider-tracking-raw/commands.json), [runner](slider-tracking-raw/run_pure_tests.py), [input hashes](slider-tracking-raw/pure-inputs.json) and raw logs were read; this was not a second execution of the suite.

The source hashes reviewed are:

| Path | SHA-256 |
| --- | --- |
| `App/StudioSlider.swift` | `a0c3347bc627ebc324a18bef4ab6a5054d2d947f65eef9af956c6f1177b198fb` |
| `App/StudioSliderTracking.swift` | `36c131501b84a0a1b8cc943a28dbbc0399837fbb8e78e593d14630af7e867219` |
| `App/CameraInspector.swift` | `9031067adc702c20bf1bdff78416ccb79248b6988997901e1a6f1f5da8b3b6d3` |
| `App/NeutralCardInspector.swift` | `8d410aa95b108438aa1a5efb55559adda508585d6d724c2ed412ac57b98e89a8` |
| `App/OpticsInspector.swift` | `133c84e6896e3249c35d5ffcbe1fa46fc7a356bd327f9aec5a0c8bc2728f2a5d` |
| `App/StudioView.swift` in the isolated candidate | `2b3f471a4bd5e82cd3b1b1ea3e7371bc35b9533d21f0fc09fbba221feb59556a` |
| `NativeTests/StudioSliderTrackingTests.swift` | `1445374add5093f9cb79515fe1f28e8ff9cc4e54734c2194164c780aca4771f9` |
| `NativeTests/StudioTrackingSliderTests.swift` | `63dd4eb946922e62bf5c99b327b208b3e31bacaa246627b1a66bbc4e45578e4a` |
| `UITests/StudioSmokeTests.swift` | `8f996f519416a4d697270e0987739523cd0dc02b105df1d439cf88a9262d2233` |

`StudioSliderEditing.swift`, its original eight tests, `SceneEditHistory.swift` and its original fifteen tests are byte-identical to the base revision. Their hashes are retained in the manifest. No Core implementation, persisted format, project-store behavior or history representation is changed by this patch.

## Actual failure and controlled reproduction

The actual source-9 failure is retained as a failure. Source `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18` completed the studio/export job with eight of nine methods passing. The optics method compared the width after Undo, `1.3 m`, with its initial `0.6 m`. The retained repository log is `docs/evidence/2026-11-24-autonomous/3b2a4ce-studio-job.log`, SHA-256 `83b475f36d0a12798f2af751e1b647c7a52c7773972838d6d48b458ba95b7a7b`.

The reviewer inspected the genuine recording contact sheet and decoded synthesized pointer event. The event contains one pointer path with a press, move and release, not repeated accessibility increment actions. The sampled recording progresses from `0.6 m` with blue Undo, through `1.85 m`, to `1.3 m` with both history arrows gray. Those observations support the possibility of an unfinished edit preventing the Undo tap. They do not reveal the internal SwiftUI binding/on-edit callback order. The [event summary](slider-tracking-raw/native-event-summary.json) and [original binary attachment](slider-tracking-raw/source9-width-synthesized-event.bplist) preserve that distinction. The binary attachment is 2,669 bytes, SHA-256 `fa758aa1c84e6b33561853d458c821109b888a8e53215fc1668bacc14b84ae67`.

The recording was extracted by bounded archive range reads with entry CRC verification; the reviewer does not claim a local whole-archive download or digest. The inspected contact sheet is at `/workspace/scratch/73dcd6a65726/verification/source9-studio-visual/optics-failure/frames-38-to-55.png`. The video entry hash is `2bf5178a7d258988292b4c85b958c2c004012a86daa6acf1f8fa319202032087`.

Separately, the [unchanged-adapter probe source](slider-tracking-raw/original-adapter-counterexample/main.swift) and [raw output](slider-tracking-raw/original-adapter-counterexample/probe.log) execute the actual adapter and history with controlled ordering. `begin → set 1.85 → end → set 1.3` leaves history editing and the UI's Undo condition false. Bypassing that condition restores `1.85`, which still fails the one-gesture expectation. Ordered final-write-before-end restores `0.6` and redoes `1.3`. This is a reproducible source counterexample, not a captured native event trace. The candidate addresses the demonstrated missing lifetime boundary while native evidence must determine whether it resolves the observed UI failure.

## Concrete review findings and corrections

The following issues were raised while reviewing the candidate and are corrected in the frozen source. They are source findings; none is presented as a proven internal cause of the source-9 native failure.

| Finding | Correction present in the frozen candidate | Evidence and remaining scope |
| --- | --- | --- |
| Writing directly from a long-lived token could bypass a parent force-close or merge a width change into another owner's open history edit. | Every changed value in an active token reasserts the captured owner, then rechecks the token before writing. Post-close values never reach that callback. | Dedicated parent-boundary, different-owner and reentrant-cancellation tests pass in the portable helper suite. |
| Accessibility adjustment captured callbacks and enabled state before closing an existing touch; the close callback could invalidate or reconfigure them. | It closes the touch first, then reads the current enabled state, adapter and mapping. | Source reasoning; actual UIKit cancellation/AX integration remains unrun. |
| An event without an active token could leave a changed native thumb while the authoritative model remained unchanged. | Such an event never writes the model and resynchronizes the idle display. | A native-only regression is authored; not executed locally. |
| Relying on outer SwiftUI accessibility modifiers did not establish that the underlying slider exposes the same label, value and identifier. | All four callers explicitly provide the existing strings/formatter; the UISlider alone owns those properties. Parent owner identities remain. | The real UI scenario now requires a unique `emitterWidth` slider, label `Width` and initial value `0.6 m`. This is a pending rejection gate. |
| A stored formatted value could be stale immediately after an accessibility adjustment and before the next SwiftUI update. | The accessibility value getter formats the current binding's `Double`. | Native tests assert an immediate readout and external-model change, but their execution is pending. |
| Inherited begin/continue work may synchronously dispatch a callback that invalidates the control. Checking only before `super` allowed a stale true return. | Both methods check enabled state and the same native/helper token after inherited work; a mismatch cancels tracking and returns false. Rejected begin and stopped continuation also close explicitly. | Final source check passed; these UIKit paths are not exercised by the portable helper suite. |
| The new native-only test referred to `StudioNumericInput` without importing its module. | `import LightingCore` is present in the frozen native test. | This illustrates why a successful syntax parse alone is insufficient to establish Apple compilation. |

## Ownership, value and lifecycle assessment

The helper stores the binding/read/write callbacks and mapping when a touch starts. It does not look up a later selected control. The parent still captures project generation and control identity, rejects stale or busy setters, uses owner-qualified ends, and preserves `.id(owner)` scopes. Returning an old token or ending it twice cannot write or close a newer helper session. The pure generation test uses a small editor harness with the real history; it verifies the captured-generation contract, not an actual SwiftUI view replacement.

The native wrapper creates the session before inherited begin work. It lets inherited end work run while the session still exists, publishes the final native value, and then retires history. It closes on rejected begin, a false continuation, cancellation, disabled configuration, window loss and dismantling. The helper clears its session before the end callback and checks the token after callbacks that can reenter. Cancellation commits the last published value through the existing history contract; explicit rollback remains the separate existing history operation.

The one-gesture guarantee applies to an uninterrupted native touch. An explicit parent lifecycle/history boundary deliberately commits the first portion; subsequent active values regain their captured owner and form one subsequent portion. The candidate's new parent-boundary test accurately expects those two commands. It does not conceal them as a single transaction or discard the earlier edit.

Model values remain `Double`. Configuration converts only into a normalized native display value, never back into the model. The thumb is not reset by SwiftUI configuration during tracking. An unchanged input or a return to the exact starting `Float` display restores the original captured `Double`, including an off-grid imported value; the tests check bit patterns and retained redo. Changed input alone is stepped and clamped. Mapping rejects nonfinite/degenerate bounds, nonpositive or nonfinite steps, and a nonfinite computed result. The four callers retain their prior range/validation policies, and accessibility adjustment retains the unchanged adapter's exact-Double arithmetic and directional bounds behavior.

The wrapper uses public `UISlider`/`UIControl` tracking, target/action, accessibility and `UIViewRepresentable` APIs. Apple documents the Boolean continuation contract and superclass cleanup requirements for [begin](https://developer.apple.com/documentation/uikit/uicontrol/begintracking(_:with:)), [continue](https://developer.apple.com/documentation/uikit/uicontrol/continuetracking(_:with:)), [end](https://developer.apple.com/documentation/uikit/uicontrol/endtracking(_:with:)) and [cancel](https://developer.apple.com/documentation/uikit/uicontrol/canceltracking(with:)). Continuous updates are the documented [UISlider behavior](https://developer.apple.com/documentation/uikit/uislider/iscontinuous). The chosen public surface is appropriate in source review. Apple SDK type checking, actual event delivery, accessibility overrides and SwiftUI sizing still require native execution.

The code requests a minimum 44-point height both through SwiftUI layout and the native intrinsic height. That is a source layout provision, not an independently measured native hit rectangle. No claim of whole-screen accessibility, Dynamic Type, VoiceOver behavior, actual focus announcements, or physical-device acceptance follows from this review.

## Tests, assertions and unverified integration

| Evidence level | Observed result | What it establishes |
| --- | --- | --- |
| Initial portable run | 35 methods, one failure | A new minimum-width redo fixture tried to decrement below the valid model domain. The validated writer rejected it, so the fixture could not unwrap Undo. Original log/source remain in [iteration-1](slider-tracking-raw/iteration-1/verification/debug-tests.log). |
| Corrected portable Debug | 38/38, zero failures | Eight unchanged adapter + fifteen unchanged history + fifteen new tracking/mapping methods; actual source and full method list checked. [Raw log](slider-tracking-raw/debug-tests.log). |
| Corrected portable Release | 38/38, zero failures | The same method set under optimization. [Raw log](slider-tracking-raw/release-tests.log). |
| Final parser invocation | Exit 0, ten source files | Syntax only, including the final UIKit changes. [Record](slider-tracking-raw/native-syntax.json). |
| Three new UIKit tests | Not executed locally | Configuration/stray-event behavior, current accessibility readout/actions, disabled/invalid state and native height request. They are outside the 38-test count. |
| Real optics UI scenario | Pending for candidate/integrated revision | Touch boundary, actual AX tree, enabled history controls, exact one-step restoration, redo and persisted relaunch. |

The initial failed fixture is preserved and corrected by moving inward at the minimum endpoint. No existing acceptance assertion was relaxed. The final pure helper and its test sources are byte-identical to the inputs of the 38/38 runs; subsequent native/caller corrections are covered only by source review and syntax parsing until Apple verification.

The existing optics UI test retains its emitter-kind, changed-width, one-Undo initial-width, Redo edited-width and save/relaunch checks. Added checks require one slider, the same label and model readout, enabled Undo after the completed adjustment, and enabled Redo after Undo. The diagnostic attachment records readouts and enabled state before the first Undo tap. There are no widened timeouts or removed comparisons. The exact numeric-field tests and save-commit waits remain unchanged.

The optional DEBUG trace is bounded at 64 records per control, requires both UI-testing launch mode and the explicit trace environment flag, and is absent in Release. It does not provide evidence until retrieved from an actual candidate run. A missing trace must not be rephrased as proof of any callback order.

Necessary next acceptance is an Apple build plus the native tests and real optics scenario at the integrated revision. For the P1 symptom, a completed drag must enable Undo, restore `0.6 m` in one step while preserving the rectangular emitter selection, enable Redo, restore the edited value, and pass save/relaunch. The changed shared wrapper also needs the existing camera/card/light and exact-value integration coverage. Actual cancellation/removal/disabled interaction and manual accessibility remain explicitly unverified; portable cancellation tests do not close those native gates.

## Integration and root-owned diagnostic follow-up

The reviewer independently ran read-only `git apply --check` for the frozen nine-file patch against the live tree containing the approved plan-caption modifications; exit was zero. The slider's `StudioView` change is the single control-construction hunk originally near line 651. It does not overlap the plan marker/header changes. The full isolated `StudioView.swift` must not replace the combined file. Root reports applying the narrow patch cleanly, so the integrated `StudioView` hash properly differs from the isolated candidate hash above. Root-owned `UITests/ProjectLibraryUITests.swift` is outside this patch and must be retained.

The reviewer also inspected that separate diagnostic change, SHA-256 `5f4ce8826f360b10f59f753ae03c8d5004bd5fb8ca630c4ac41d7edbcd5dc26d` at review. The predicate remains `exists == true AND enabled == true`, the deadline remains 15 seconds, and the same waiter result is asserted. Only a failed result produces a string attachment and a full-screen screenshot, both retained. The requested-element description is capped at 8,000 characters and app hierarchy at 24,000. These are retained-text bounds, not a time bound on obtaining an XCTest snapshot. `XCUIApplication()` identifies the existing target app; the branch does not launch, retry, tap or mutate it. No diagnostic API or assertion-weakening blocker was found by source review.

The reviewer independently read the final source-10 logs: library/reference executed nine methods with one failure, while room/precision executed five with zero failures. The archived-delete method stopped at its first `openProjectLibrary` readiness check before its save/archive/delete actions. The large-library save/browse/relaunch scenario passed. The readiness failure's cause remains unresolved; the new diagnostics do not repair or reclassify it. Root reported the recording's launch/loading/studio progression; this review does not claim a fresh visual examination of that source-10 recording.

The logs reviewed are `docs/evidence/2026-11-24-autonomous/5cd7eb4-library-job.log` (SHA-256 `6de7f161d9621dfda3a70e4d8e99415c2f6ceefec079927f89d6876a52405492`) and `5cd7eb4-room-job.log` (SHA-256 `86585847ff28089013c4349615455a76d1b22633f6dd61799a908bf301c26cf4`). Those source-10 results do not validate the new slider or plan-caption code. The repository HEAD observed during final read-only verification was documentation checkpoint `6752f4dd0acea314b58d5a31b4d5e6f8c4f23bc7`; the proposed source-11 integration still requires its own exact snapshot and results.

## Repository retention

Root relocated the local evidence links for this repository copy. The frozen independent review was 18,298 bytes, SHA-256 `c89c6117740606b6cb5604d61246d807bd501ffb16f836c1a215a60efdaddf38`. The evidence and source contents are unchanged. `slider-tracking-retention.json` maps original candidate paths to retained paths and hashes.
