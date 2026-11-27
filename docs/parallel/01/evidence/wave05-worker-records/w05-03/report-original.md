# W05-03 — Feature API contract review

## Verdict and provenance

**Bounded static acceptance of the session API. No new blocking API defect found. Native route acceptance remains pending.**

One reviewer context; no children, repository source edits, code commit, builds, tests, or pushes. Assigned build directory unused. Review scope: callback destination/owner admission, logical identity, accepted no-ops, synchronous retirement, receipt advancement and undo boundaries. The hypothesis was that a stale, mismatched or malformed callback could alter the editor or close another owner's transaction.

Frozen checkout: `ea83fa165916aaa2f55ddb88f6430b8a59ce5565`, detached sparse tree at `/workspace/scratch/e08d5190f17c/workers/w05-03/tree`.

Initial exact inspected source: `c104426644c72676a219262e208525ffd08bc64e`, read through `git show` and `git diff ea83fa1..c104426`; unpublished source was never checked out. Final exact inspected integration: **`721186e93d4f4a511823d4f3013414929e54a56d`**. Its App/Sources/Tests bytes are unchanged from c104426 (`git diff --exit-code`, exit 0); its additional session tests, package membership and interface documentation were inspected separately.

## Concrete findings

- `StudioSession.acceptsFeature` consults its live optional presentation on the MainActor. Callback admission, validation, mutation and receipt update contain no suspension. Loaded/writable/idle admission combines the live storage state with the captured owner, logical `workspaceResetID`, and accepted revision. First save changes storage generation while preserving that logical identity; switch/reload/recovery resets clear the presentation. Revision UUIDs prevent edit-away/undo-back admission.
- `applyFeatureScene` accepts only reference/arrangement; `applyFeatureLight` only target-lux; `applyFeatureRoom` only room/AR. Wrong destinations reject before mutation. Scene/light use validated replacement; room validates before staging. Valid unchanged proposals return true. Scene/light retire synchronously even on no-op; repeated room no-ops leave the owner, history and revision untouched.
- Target-lux resolves the captured UUID and original light, then requires every field except candela to match. Changing selection cannot redirect the result. Invalid output or changed geometry/name rejects without mutating the editor or Plan state.
- Room/AR mutations advance only their own accepted revision and share their owner transaction. Generic apply/update stage closure of that group and publish it only for an actual valid mutation; invalid/no-op unrelated commands preserve it. Subsequent unrelated mutation and undo cannot revive the feature receipt.
- Existing presented owner and missing target UUID reject before ending a gesture. Retirement permits a new owner; old-owner finish cannot clear that newer presentation or close its group. Healthy repeated `.load` rejects before reservation; failed-load retry remains permitted.
- The accepted-mutation Plan correction is present for scene, light and room. Actual changes clear the frozen origin; invalid/no-op callbacks retain it. The new session assertions cover a subsequent drag using its new origin and scale.

## Executed checks and limits

Required AGENTS/protocol/state/product/architecture/roadmap/quality/design and lane handoff/interfaces were read. On the **frozen checkout only**:

- `python3 scripts/agent_cycle.py check`: exit 0; structure and evidence references valid, explicitly not runtime truth.
- `python3 scripts/agent_cycle.py next`: exit 0; M03, outstanding editing/accessibility/persistence gates.
- Final `git --no-optional-locks status --porcelain=v1`: exit 0, empty output. An earlier ordinary status failed exit 128 because the disk filled during index refresh; this was reported to root/scheduler.

All 15 added `StudioFeatureSessionTests` methods were inspected, including busy/first-save, no-op/redo, wrong route, foreign owner, retired-owner replacement, room grouping, ABA, reset/load and Plan regressions. Package.swift includes the file. **None were executed by this worker.** No Swift syntax/build, Debug/Release, Apple SDK, Observation or native UI result is claimed. Earlier 413-test evidence is not transferred to this integration.

Concrete deferred limits remain in `App/StudioView.swift`: legacy scene-equality admission and storage-generation dismissal still drive the native sheets. `ReferenceComparisonView` closes/consumes its session before its Void callback; arrangement and target-lux dismiss after Void callbacks. Rejected-draft retention and native first-save preservation therefore remain unproved and unwired. Room/AR's Bool interface supports later integration. These are known wave-6 integration gaps, not fixed by this review.

## Inspected file fingerprints

- `App/StudioSession.swift`: `36c37cf74b63de1cbdd64be6ec5d6500e0e87b6f73053745323869df45987d1f`
- `NativeTests/StudioFeatureSessionTests.swift`: `0aae7a329fbf0b7f565868c51384e28c84ab3d6f098be46416d61a1dff73852b`

Scheduler owns frozen-tree cleanup after preserving this report and its hash. Root owns execution and integration acceptance.
