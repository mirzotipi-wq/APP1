# w057 owner proposal: revalidate retained preview adoption

**Status:** proposed, unapplied, uncompiled and unrun. Same real worker `/root/w051/w057`; this follow-up adds no worker. Root requested a concrete review artifact. Lane03 owns preview source/tests; lane20 integrates and records the disposition. No external-owner acknowledgment is implied.

## Exact applicability

| Input | Immutable identity |
|---|---|
| Inspected lane03 HEAD | `8ce5e464253144deccb39d838faef70f05e0c38c` |
| `App/ReferenceStudyPreview.swift` | `c96d5cb7a41143867efca160b309d71bfa993c96` |
| `NativeTests/StudyPreviewPipelineTests.swift` | `9d4250cac8296eb6b0825320b6d5df801e127310` |
| Frozen lane04 review input | `5934f291b8e78e378a96ec3e4d294521c79839d0` |
| Frozen lane04 engine blob | `8c1acd852d85cd99671feaba883db1808bbb5e68` |
| Proposed unified diff | [owner-preview-adoption.patch](owner-preview-adoption.patch), blob `85e6d2da8789ef0d0f3a2393f65d64da8b3d7789` |

The diff targets the exact lane03 preview above; it does not assume the lane04 engine or amended native tests are already merged there. Apply only after the owner checks current source and resolves any subsequent owner changes. Four hunks, twenty added and nine removed lines. The fetched baseline reconstructs to the proposed text exactly using an in-memory unified-hunk checker. That is a textual check, not `git apply --check`, Swift parsing, compilation or execution.

## Defect and minimal correction

A successful Metal frame A can remain in the view while request B confirms a permanent engine downgrade and is cancelled before publication. Undo to A currently returns at owner-preview line205 without calling the engine at211. Request-only equality at119 then exposes A with the stored Metal badge at130–135. Those historical pixels remain valid Metal output. The correction aligns the subsequent A request with the engine's permanent backend decision.

The proposed diff:

- Records the existing pipeline ticket in each adopted frame and an active ticket in view state. Current image/backend/warning status requires both request equality and ticket equality.
- Removes the view-local successful-frame return. Every activation consults the engine, whose own bounded cache remains responsible for valid reuse and downgrade invalidation.
- Preserves a retained successful image while revalidation runs; it uses the existing previous/updating presentation, with no current backend badge. Existing same-request error clearing remains limited to failed frames.
- Clears the active ticket on inactivity/disappearance and stamps a frame only inside the existing guarded pipeline publication callback.
- Adds a defaulted internal `renderStudy` closure for deterministic hosted tests. Its production default calls the same shared engine and copies the actual image/backend result. Existing `ReferenceStudyPreview(scene:subject:)` callers retain their defaults. This initializer compatibility is proposed, not compiled evidence.

The existing cancellation guard, generation checks, conversion checks, retry handling, subject filter and 80ms debounce remain. Historical Metal pixels are never relabelled CPU. Precision fallback still uses the returned frame's provenance; an ordinary cache hit can retain Metal when the engine has not downgraded. No continuous broadcast of backend changes to every mounted preview is proposed: this patch addresses subsequent activation/reinstatement.

## Exact regression: hosted consumer plus existing pipeline seam

Proposed native method: `testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade`. Add native-only hosted coverage in the preview test owner scope (conditional SwiftUI/UIKit imports where needed). Preserve all ten existing pipeline methods and their assertions. Verify that `scripts/native_test_shards.py` automatically discovers the additional `NativeTests` method and that CI accounts for its execution without skips; the coordinator confirms discovery is automatic and CI rejects every skip. No shared harness or configuration change is currently required.

Keep one mounted view identity throughout A→B→A; do not use `.id(scene)` or recreate the hosting controller. A MainActor observable holder changes only the scene value. Supply `.environment(\.scenePhase, .active)` and the proposed `renderStudy` hook. Use explicit request/completion continuations like the existing `ControlledRender`; do not infer ordering from sleeps. Every wait must have a bounded assertion deadline and cleanup must release held continuations.

1. Use validated sphere scene A and B differing only in exposure. First A returns a distinctive synthetic image tagged `Metal compute`. Assert one A render invocation, `studyPreview`, and the Metal backend badge. This fixture is a mock output, not GPU evidence.
2. Change to B and wait until its render closure has entered. The controlled producer confirms a permanent downgrade, signals that event, and holds delivery of a cancellation error. A remains the retained image.
3. Undo to A before B's cancellation reaches the publication handler. Release B with `StudyError.cancelled`; late success/failure must not publish.
4. Wait for a **second invocation for A** and hold that invocation before its CPU result is delivered. Assert the visible retained A uses `studyPreviousPreview` and `studyUpdating`, and that `studyBackend` and `studyWarning` are absent as current status. Keep the stored historical Metal provenance unchanged.
5. Deliver the CPU result for second A. Assert current `studyPreview`, backend `CPU reference`, and removal of previous/updating status. Publication must carry the new CPU image and backend together. The existing pipeline seam can independently assert the paired completion values; the hosted check establishes the actual view's request and presentation wiring.
6. Require exactly two A invocations and one B invocation. The original view's local return fails the second-A requirement; removing only that return fails the held-result current-status assertion.

For a meaningful before/fail run, add **only the defaulted render hook** to the baseline fixture while preserving its old return and request-only status predicate. A missing initializer or compile failure is not a reproduction. Then test the complete proposed correction under the same fixture and assertions.

The existing `testReturningToCompletedRequestInvalidatesIntermediateWork` only proves B cannot publish after a new ticket; it cannot detect a skipped A engine call or the view's current badge. Retain its coverage, but never substitute a pipeline-only success for the hosted regression. A controlled pipeline companion can publish A/Metal, begin held B, begin held A again, finish B with cancellation, assert no additional publication, then deliver A/CPU and assert the complete new image/backend pair.

## Integrated engine confirmation after lane04 adoption

Repeat the hosted sequence using the lane04 injected `StudyRenderEngine` factory and its confirmed-failure/cancellation script. Initial A is synthetic backend output; B throws `MetalStudyError.command` (with allocation and invalidComputeOutput variants already covered by engine tests) while the engine's additional cancellation source is raised. The view's injected producer can hold delivery of the resulting cancellation error after the engine has unwound, allowing deterministic undo before its catch is observed.

Confirm the engine has purged Metal entries and retained CPU entries, reset the synthetic cancellation source, then allow A revalidation. Require its engine result to equal `ReferenceStudyRenderer.render(scene: A, width: ...)` at the same width and to carry `.cpu`. The host then requires the CPU badge. This links view behavior to a real CPU oracle and the actual engine downgrade path, without claiming that the scripted compute image or failure was real Metal execution.

Retain companion scenarios: ordinary cancelled B without a confirmed failure (A may reuse engine-cached Metal); precision-only fallback (future eligible requests remain Metal-capable); display-name-only edits (validated cache reuse); subject switches (no cross-subject presentation); inactive/foreground and disappear/reappear; pre-cancelled task entry; retry/conversion errors. Broaden execution only as required by the eventual owner change and gates.

## Limits and preserved evidence

No App or NativeTests file was written, no branch/ref/commit was changed, and no proposed native method was added or run. Local status/HEAD/history, agent_cycle check/next, hash-object, git apply, Swift compile/build/tests, host-kernel execution, simulator Metal, UI/accessibility review and device validation remain unrun by this worker. Native candidate `6e811837c87ff3a8a0d8c87c4b0f877c752aae89` remains CI-pending per the coordinator; this proposal supplies no pass.

Original report blob `f1100c00c5ab074f9e40ef2a491a8bbead89f323` and original [source-review.json](source-review.json) blob `20791defd3bc0f3f7788a2d364bca61c25f30023` remain preserved. The latter retains exact source traces and recorded discovery/output deviations. Root routes this proposal to03/20 through its contracts/handoff; no owner approval or merge is inferred.
