# Slider transaction native failure and correction

## Observed native failure

Source `ff8b683098a720b4c7abdddf212f85a79f3cfd39` failed `StudioSmokeTests.testOpticsEditingUndoRedoAndRelaunch` in the actual studio/export simulator shard of [workflow 45363578829, job 138342789444](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/job/138342789444). The [unaltered native test log](ff8b683-studio-export-native-tests.log) records the Xcode 26.6 `xcodebuild test-without-building` invocation, Debug configuration and simulator destination.

The scenario selected Rectangular softbox, read the initial width, adjusted the width slider to normalized position 0.50, read the changed width and tapped Undo. The emitter-kind assertion passed, but the width assertion at `UITests/StudioSmokeTests.swift:87` failed:

```text
XCTAssertEqual failed: ("Optional("0.8500000000000001 m")") is not equal to ("Optional("0.6 m")")
```

The log records slider adjustment at test time 71.15 seconds, the changed-width lookup at 74.59 seconds and Undo at 81.60 seconds. Between adjustment and Undo it records only width/Undo queries; there is no intervening scroll or other edit. The method failed after 87.589 seconds. These are test-log timings, not a device performance measurement.

The same shard also contains export presentation timeouts and a subsequent app-termination failure. Those are investigated separately in [the export correction report](export-native-correction.md). They do not establish the slider callback order or justify weakening the width assertion.

## Supported diagnosis, not a traced callback sequence

The old slider path sent its value directly to a validated scene binding. That binding called `history.record(previous: scene)` whenever no continuous edit was active. A separate `onEditingChanged(true)` callback began the continuous transaction using the scene at callback time.

This permits the following deterministic counterexample:

1. Width starts at 0.6 m with the emitter selection already recorded separately.
2. The first slider value write changes it to 0.8500000000000001 m before the begin callback. The binding records 0.6 m as a discrete command.
3. The begin callback captures the now-current 0.8500000000000001 m scene as the gesture start.
4. Subsequent width changes occur inside that transaction, and the end callback commits it.
5. One Undo restores 0.8500000000000001 m. Another Undo is required to reach the actual pre-drag 0.6 m.

The isolated baseline-equivalent setter path reproduces this exact intermediate value. It also shows cancellation restoring the intermediate value and the early discrete record discarding redo. **The native log contains no internal binding/begin/end trace.** The counterexample supports the ordering diagnosis and motivates removing the dependency on begin preceding the first write; it does not prove that this precise internal ordering caused the recorded simulator failure. Actual native execution of the corrected candidate remains required.

## Production correction

The candidate is based on `816e7123cafbf214bef47e09d3e14abd993a83c7`; its exact changed source hashes are recorded below. It adds two small App-layer files:

- `StudioSliderEditing.swift` is a UI-independent adapter. For a finite, changed slider value, it calls the captured `onEditingChanged(true)` before invoking the original value writer. Repeated begins for the same owner retain the original scene under the existing `SceneEditHistory` contract. Invalid and unchanged values do not open an edit.
- `StudioSlider.swift` wraps the existing SwiftUI Slider with that adapter. Native begin/end callbacks still go to the existing owner-scoped handler. An explicit accessibility adjustable action executes a changed increment/decrement as begin, write and end synchronously, without waiting for a drag-end callback.

The four existing slider helpers in `StudioView`, `CameraInspector`, `OpticsInspector` and `NeutralCardInspector` each replace `Slider` with `StudioSlider`. The rest of their bindings, accessibility identifiers/readouts, units, steps and ranges remain unchanged. `PrecisionValueButton` retains the original binding, so its exact value application is still a discrete command. No history-entry promotion heuristic, timer, global token or UIKit control replacement is used.

## Preserved contracts and limits

- **Ownership:** Existing captured project/control owners and light UUID scope are retained, as are the matching `.id` scopes. The draft scope remains stable. The adapter forwards that captured closure; it does not look up a new selection or project at callback time. An end from a different owner still cannot close a newer transaction.
- **Lifecycle:** Selection, mode, save, foreground exit and view-disappearance force-closes remain distinct from owner-matched gesture ends. Existing load, recovery and project-switch resets are unchanged. No scene or persistence API was changed.
- **Accessibility:** A changed increment/decrement finishes synchronously. An outward action at a bound is a no-op and opens no transaction. Adjustment bounds include the current finite value, even if it lies outside the usual slider span or the closure predates that value. Clamping therefore cannot reverse the requested direction. Tests use retained camera coordinates `80.123456789` and `-80.123456789`, as well as both width bounds. These are executable adapter tests, not an actual VoiceOver session.
- **Cancellation and redo:** The existing explicit rollback API still returns the transaction's initial scene for the caller to restore. The regression verifies that a first write before the native begin callback no longer loses that initial scene or the preexisting redo branch. It does not claim native touch-cancellation coverage.
- **Precision:** The precision editor uses its original validated binding. A subsequent value of `0.723456789` is preserved exactly and has a separate undo step. The wrapper does not quantize an untouched imported value. The existing slider controls retain their configured step behavior for drag changes.
- **History:** `SceneEditHistory.swift` and its 15 existing tests are unchanged. The sixty-entry bound, custom smaller limits, redo invalidation, legacy API, owner-matched ends and unqualified force-close semantics are retained.
- **Remaining event limits:** Stable owners identify controls, not overlapping generations of gestures from the same control. This correction does not add generation tokens or establish behavior for arbitrary late value writes after a control has ended or disappeared. Actual SwiftUI delivery, multitouch, VoiceOver and physical-device editing remain unverified.

## Executed regression evidence

`NativeTests/StudioSliderEditingTests.swift` adds eight methods that exercise the actual adapter with `SceneEditHistory` and a validated scene-binding harness. The cases cover value-before-begin, begin-before-value/repeated begins, unchanged gestures preserving redo, the preceding emitter command, accessibility completion/bounds/imported coordinates, explicit cancellation, stale other-owner ends, a subsequent exact precision edit and invalid/no-op writes.

The isolated package at `/workspace/scratch/73dcd6a65726/verification/slider-history-order` uses a `KeyAndFill` target containing a byte-identical copy of the production adapter. It copies the actual native test source and the existing `SceneEditHistoryTests.swift` unchanged into its test target, with the repository's real LightingCore package as a dependency. No test-module import adaptation is needed. This executes the adapter and history logic on Linux; it does not compile or execute SwiftUI. The isolated package's build directory is separate from the repository's shared build directory.

| Check | Actual outcome | Raw evidence |
| --- | --- | --- |
| Baseline-equivalent direct setter, before inserting begin-before-write | 8 methods executed; 4 methods failed with 11 assertion failures | [Before log](slider-history-before.log) |
| Corrected isolated Debug | 23/23 methods passed: 8 adapter and 15 existing history | [Debug log](slider-history-after-debug.log) |
| Corrected isolated Release | 23/23 methods passed: 8 adapter and 15 existing history | [Release log](slider-history-after-release.log) |
| Syntax parse of the seven changed/new Swift files | Command exited 0 with no diagnostics | [Empty parse-output log](slider-history-native-parse.log) |
| Corrected Apple SDK build, simulator optics regression and relaunch | **Pending; not executed by this package** | Existing native test and assertions remain unchanged |

The baseline is a deliberately equivalent extracted setter path, not a fresh native run of the old application. Its `setValue` performed the finite/change guard and `write(value)` without the added `onEditingChanged(true)`. The same eight tests were then run against the corrected adapter. The four failing baseline methods were the whole-width gesture/emitter-command case, early-value cancellation, stale-other-owner completion and subsequent precision-command history. The first-width case reproduces 0.8500000000000001 m versus 0.6 m exactly.

The executed toolchain was Swift 6.4.3 on Debian 13 x86_64, from `/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin`. Commands were run with that toolchain on the isolated package:

```sh
swift test --package-path /workspace/scratch/73dcd6a65726/verification/slider-history-order --filter StudioSliderEditingTests
swift test --package-path /workspace/scratch/73dcd6a65726/verification/slider-history-order
swift test -c release --package-path /workspace/scratch/73dcd6a65726/verification/slider-history-order
swiftc -frontend -parse App/StudioSlider.swift App/StudioSliderEditing.swift App/StudioView.swift App/CameraInspector.swift App/OpticsInspector.swift App/NeutralCardInspector.swift NativeTests/StudioSliderEditingTests.swift
```

The first command used the baseline-equivalent adapter; the latter test commands used the corrected adapter. Their stdout/stderr was redirected to the corresponding logs above. An empty parse-output file only records absence of diagnostics; the observed successful exit is a syntax check, not Apple SDK type checking or a native build. No tests were rerun while persisting this evidence.

## SHA-256 evidence identity

Raw logs were copied byte-for-byte from the verification directory. No failed output was removed or rewritten.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `ff8b683-studio-export-native-tests.log` | 54463 | `0f60b9bf4d694cbbc022e3c74dc44a7b61372bdcd73f40e58a8f9f6d725983d3` |
| `slider-history-before.log` | 22120 | `5fb28207371123c61beac7ca67f1c4959379b542b21b5a90c428dbe9af92c8e4` |
| `slider-history-after-debug.log` | 6842 | `b7b13d92d00b0a7d5839438233c56e9ce4a006743e8e65aef13a6102cfb458f9` |
| `slider-history-after-release.log` | 7043 | `dc4fc29b2cae32c36421170741e4bfeb34ad88b072d23f22222a2aca81e959e2` |
| `slider-history-native-parse.log` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

| Source file | SHA-256 at evidence capture |
| --- | --- |
| `App/StudioSlider.swift` | `a144109d5137e414da17da1c437dbed5dfe7cd71b3b53a0890df5b95e5f24cff` |
| `App/StudioSliderEditing.swift` | `b3dc9f5c002f9d68a29034b357cf3514e79f7bca29eb50a073dfab01ab952115` |
| `NativeTests/StudioSliderEditingTests.swift` | `1b1edc611bd2ddd918b555c675d5c898025ffab765dc67b6baf961f49d36f4e9` |
| `App/StudioView.swift` | `2bf6e57bb53e2549493251047bc17ec7bb9fdb23ee8a2770b6756c61907be221` |
| `App/CameraInspector.swift` | `39c5cef83e1cd6b0a958a7adb982feac689c1b948608e69267f48f77a00b220e` |
| `App/OpticsInspector.swift` | `905b03832c3374085c0f520abcc9d56c40536f252d5f2814f4a6271477b2f512` |
| `App/NeutralCardInspector.swift` | `689e6992473463d1a69b8c748038c9397e0a9c108cd5b2d34d21aab2eef8a36a` |
| `Sources/LightingCore/SceneEditHistory.swift` (unchanged) | `e291eab9e8f85341ea7b3c348e1b62ef8be9c73591e9141f3e720663ba4f7d3a` |
| `Tests/LightingCoreTests/SceneEditHistoryTests.swift` (unchanged) | `b61f8b550bbabe259c229dd2b337d417c0b0b3664f616e2aea1e3a232d159c33` |

## Acceptance still required

`StudioSmokeTests.testOpticsEditingUndoRedoAndRelaunch` is unchanged: one Undo must restore the width read before the drag while retaining Rectangular softbox; Redo must restore the complete edited width, and save/relaunch must preserve it. The corrective native candidate must pass that scenario. These isolated passes do not promote the native editing, accessibility, persistence-smoke or regression gates.
