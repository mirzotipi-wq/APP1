# Optics slider: explicit native tracking candidate

## Decision and scope

The isolated candidate is ready for source integration review. **Apple SDK compilation and the real optics gesture remain unverified.** The local result is 38/38 UI-independent tests in each configuration and a syntax parse; it is not native acceptance.

Base: `5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`, tree `aaf52e62fff970cdc55f5908326523e58a1cf394`. All candidate work is under `/workspace/scratch/73dcd6a65726/verification/slider-tracking-candidate`. No live application files were edited, staged or committed by this task. The nine-file patch changes the shared slider, its four callers, the existing optics UI test, and three new helper/test files. It does not contain the independently developed plan-caption changes in the live `StudioView`.

`StudioSliderEditing.swift`, all eight existing adapter tests, `SceneEditHistory.swift`, and its fifteen existing tests are unchanged. The candidate does not change history storage, persistence, native timeouts or physical/model gates.

## What the actual source-9 evidence establishes

The actual studio/export job for source `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18` completed nine methods with one failure. In `StudioSmokeTests.testOpticsEditingUndoRedoAndRelaunch`, line 87 compared `1.3 m` with the pre-adjustment `0.6 m`. The raw repository log is `docs/evidence/2026-11-24-autonomous/3b2a4ce-studio-job.log`, SHA-256 `83b475f36d0a12798f2af751e1b647c7a52c7773972838d6d48b458ba95b7a7b`. The run is [workflow 45377378521](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521).

The log records one normalized slider adjustment at test time 41.82 seconds, one Undo tap at 50.58 seconds, and the failure at 55.39 seconds. Between these actions it records element queries, without an intervening scrolling gesture. The helper checked whether Undo was hittable, but did not assert that it was enabled.

The extracted synthesized-event attachment `B26619A3-98D3-435F-9813-0FE3BEF6C171` contains one pointer path named `press, hold, drag, and hold`: coordinates `(82.8512648344, 628.166666667)` at offsets 0 and 0.25 seconds, followed by `(201, 628.166666667)` at offset 0.4862974703 seconds and release at that same offset. The archived event-type integers are preserved in `native-event-summary.json`. This is one synthesized pointer drag, not a series of accessibility increment commands.

The actual recording/contact sheet shows width `0.6 m` initially with a blue Undo arrow, then `1.85 m`, and then `1.3 m` with both history arrows gray through the remaining sampled frames. That appearance supports concern that an unfinished edit disabled Undo and the recorded tap did nothing. It does **not** reveal the internal SwiftUI callback sequence or prove that Undo popped a particular history entry. The two extracted UI snapshots contain only the application root and no child control state.

The attachment entries were recovered by the parent through bounded range reads and entry CRC verification. This task does not claim that the full native artifact archive was downloaded or hashed.

## Reproduced invariant violation, separate from the native cause

The small `original-adapter-counterexample` probe compiles the real, unchanged adapter and history code. It supplies controlled callbacks; it does not replay native SwiftUI internals.

| Controlled sequence from width 0.6 | Actual probe result |
| --- | --- |
| Begin, write 1.85, end, write 1.3 | `isEditing=true`, Undo disabled, width 1.3 |
| Tap only if the UI's existing enabled condition is true | No change; width remains 1.3 |
| Bypass that disabled condition and call history Undo directly | Restores 1.85, still not 0.6 |
| Begin, write 1.3, end, write 2, end | A separate counterexample: enabled Undo restores 1.3 |
| Begin, write 1.85, write final 1.3, end | Undo restores 0.6; Redo restores 1.3 |

The original stateless adapter starts history from every changed value. It has no session identity to reject a value delivered after an end. Merely enabling Undo during an open transaction does not fix the demonstrated history boundary. The visual evidence makes the open-edit case especially relevant, while the actual internal event cause remains untraced.

## Candidate behavior

`StudioSlider` now contains a public `UISlider` subclass through `UIViewRepresentable`. UIKit touch tracking supplies the edit boundary. The existing exact-value fields keep their original bindings.

- A touch session captures the adapter closures, including the parent's owner and project generation, and its normalized mapping before inherited begin-tracking work can emit changes. The session has a token; events outside it cannot open or reopen history.
- Continuous value changes remain visible. Inherited end-tracking work completes first, the current native value is published, and history closes once. Rejected begin, stopped continuation, cancellation, disable, window loss and dismantling also retire the session. Begin and continuation recheck the same token/enabled state after inherited work, because a callback may invalidate the view synchronously.
- Each changed value within a valid session reasserts the captured history owner and then rechecks its token before writing. This preserves the existing parent force-close and other-owner contracts without allowing post-close events to begin anything. Focused regressions cover the parent's explicit history boundary and an intervening different owner.
- Cancellation commits the last published value through the existing owner-qualified end contract; it does not manufacture a final conversion from the thumb. The explicit history rollback API is unchanged. Late events are ignored and an idle native thumb is restored to the authoritative model display.
- The normalized native `Float` is only a display coordinate. Programmatic configuration never writes the model. While tracking, SwiftUI updates cannot reset the thumb from a rounded or stale model read. An unchanged touch, or a return to precisely the starting display coordinate, retains the original `Double` bit pattern, including a value between slider steps.
- Actual changed input is mapped through finite bounds and step guards. Endpoints are clamped; invalid configuration disables the control without changing the model. The session retains its original range while subsequent configuration belongs to the next session.
- Native accessibility increment/decrement performs the existing exact-Double, complete discrete command. It finishes any preceding touch and only then rereads the current enabled state and callbacks, so reentrant cancellation cannot use an obsolete configuration. The native hit area is at least 44 points.

All four callers pass the existing label, identifier and exact unit/locale formatter explicitly. The native slider is the sole owner of those accessibility properties. Its `accessibilityValue` reads the current binding dynamically, so an immediate accessibility adjustment does not retain the previous formatted string while waiting for SwiftUI to reconfigure. Parent `.id(owner)` scopes remain intact.

Apple documents public [begin tracking](https://developer.apple.com/documentation/uikit/uicontrol/begintracking(_:with:)), [continuation](https://developer.apple.com/documentation/uikit/uicontrol/continuetracking(_:with:)), [end tracking](https://developer.apple.com/documentation/uikit/uicontrol/endtracking(_:with:)) and [cancellation](https://developer.apple.com/documentation/uikit/uicontrol/canceltracking(with:)) boundaries. Continuation's Boolean decides whether tracking should continue. [UISlider continuous updates](https://developer.apple.com/documentation/uikit/uislider/iscontinuous) support live preview. Apple's [SwiftUI Slider initializer documentation](https://developer.apple.com/documentation/swiftui/slider/init(value:in:oneditingchanged:)) describes begin/end notifications but does not specify their order relative to every binding write. The correction uses explicit public tracking; it does not attribute an undocumented order to the observed failure.

## Tests and retained failures

| Check | Observed result | Evidence |
| --- | --- | --- |
| Original actual-adapter controlled counterexample | Reproduced the open-edit and split-history cases; ordered control passed | `original-adapter-counterexample/main.swift`, `probe.log`, `manifest.json` |
| Initial candidate Debug | Existing 8 adapter + 15 history tests passed; 11/12 new methods passed | `iteration-1/verification/debug-tests.log` |
| Corrected pure Debug | 38/38 passed: 8 unchanged adapter, 15 unchanged history, 15 new tracking/mapping | `debug-tests.log` |
| Corrected pure Release | The same 38/38 passed | `release-tests.log` |
| Final App/native/UI syntax | Exit 0 | `native-syntax.json`, `native-syntax.log` |
| Three new UIKit methods | Authored and syntax-parsed; not executed with Apple SDK | `NativeTests/StudioTrackingSliderTests.swift` |
| Actual optics gesture, Undo, Redo, save/relaunch | Pending for this candidate | Existing UI scenario strengthened, original acceptance assertions retained |

The initial new test failure was an invalid fixture: at minimum width 0.05 it attempted to prepare a redo branch by decrementing below the model's valid width. The validated writer correctly rejected that edit, so the fixture's Undo unwrap failed. The fixture now moves inward at that endpoint. The original failed output and initial sources are retained; it was not a native result or a product failure.

The manual harness uses Swift 6.4.3 on Debian, `-swift-version 5`, `-Onone -DDEBUG` or `-O`, and `-enable-testing`. It compiles the real LightingCore sources and a small KeyAndFill module with the unchanged adapter and new pure helper. It executes the actual test source without rewriting assertions. Exact commands and input hashes are in `commands.json` and `pure-inputs.json`; `run_pure_tests.py` is reproducible. It does not compile SwiftUI or UIKit. The core and pure helper/tests did not change after those runs; later final review changes affect the UIKit wrapper, accessibility callers and native-only tests.

## Native acceptance still required

The optics UI scenario now also requires exactly one slider with identifier `emitterWidth`, label `Width`, initial value `0.6 m`, enabled Undo after the gesture, and enabled Redo after Undo. It attaches the actual initial/edited readouts and control enabled states before Undo. Every original emitter-kind, width restoration, redo, save and relaunch assertion remains.

A DEBUG-only, explicitly opted-in trace emits at most 64 events per control to the app console. It records the new native wrapper's event, model, display and tracking state. Its existence does not imply the trace was collected from a native execution of this candidate. Release has no trace output; no timers, private APIs or widened timeouts were introduced.

The integration still needs the Apple build and the real UI scenario, including the accessibility tree and native touch boundaries. The native-only tests check programmatic display updates, immediate accessibility values/actions, disabled behavior, invalid bounds and a stray event; they do not substitute for an actual touch gesture. Device/VoiceOver use and native cancellation remain unverified. This packet does not promote the native regression or persistence gates.
