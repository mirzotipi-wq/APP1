# W05-07 — feature integration review

**Provenance:** detached sparse tree at `ea83fa165916aaa2f55ddb88f6430b8a59ce5565`; production inspected exclusively through immutable Git show/diff at **`721186e93d4f4a511823d4f3013414929e54a56d`**. Later root `363a7149e4eb6f195f478b3ce0210e33e8ac7ed0` changes only one test file. **Commits: none.**

## Concrete wave 6 work

| Producer | Actual owner interface | Parent adapter |
|---|---|---|
| ReferenceComparisonView | `scene`, `onApply: (LightingScene) -> Void` | Captured context.scene; applyFeatureScene; select Study only after acceptance. |
| SceneArrangementView | `init(scene:onApply:)`, scene callback returns Void | Captured context.scene; applyFeatureScene. |
| LightTargetLuxView | `light`, `scene`, `onApply: (StudioLight) -> Void` | Capture target UUID from destination; obtain its light from context.scene; applyFeatureLight. |
| ManualRoomPlacementView | `init(scene:onRemove:onClose:onChange:)`; optional removal/change callbacks return Bool | Live session.scene; applyFeatureRoom(nil/room); retireFeature on outer close. |
| ARPlacementView | `init(scene:onRoomRemove:onClose:onRoomChange:)`; optional removal/change callbacks return Bool | Same outer AR context and live scene; nested manual close retains outer ownership. |

Call `openFeature(destination, from: capturedStorageGeneration)` before presenting. Context.generation is workspaceResetID, never storage generation. Bind presentation to the matching live session.feature owner and isPresented. A false binding setter/outer close must synchronously retire that captured context; matching onDismiss calls finishFeature. Never finish whichever feature happens to be current. Stable host identity is context.id; accepted scene/lux results already retire synchronously.

**Existing integration blocker:** StudioView:274 calls dismissSceneEditors on every storage-generation change; :1269–1283 clears all feature payloads. Migrating callbacks alone therefore cannot preserve first-save drafts. Separate ordinary storage callback invalidation from logical-document feature teardown. Replace legacy SceneContext, LuxTarget, equality guards and room receipt masking through owned host/session work; leave owner algorithms unchanged.

Room/AR must receive **live session.scene** after their accepted edits, under the same context.id. Freezing context.scene leaves a reopened AR manual sheet initialized from the old room; keying by revision remounts local drafts/controller. ManualRoomPlacementView:158–195 already retains drafts and only acknowledges Bool acceptance. ARPlacementView:63–105 fences its nested manual owner. Its controller captures immutable scene/layout, but ARPlacementLayout uses rig geometry and does not consume placementRoom; accepted room-only changes need refreshed fallback input, not controller reconstruction.

**Owner limitation:** ReferenceComparisonView:117–122 closes/clears photos and candidates before its Void callback. Arrangement:105–107 and lux:114–116 set terminal flags and dismiss unconditionally. Parent admission prevents stale mutation, but cannot retain consumed/rejected drafts. Request narrow synchronous Bool acceptance seams: validate/propose first; consume, mark finished and dismiss only after true; keep draft/error on false. These owner-file changes are outside lane 01.

## Published peer request

At `63d4676b5080ee45476e7f8a9cf8ffd2aa854c6a:docs/parallel/05/OWNER_REQUESTS.md`:

> Requested owner change: key the 3D wrapper with session.workspaceResetID, retain the separately captured generation/live-UUID callback guard, and cover first-save retention plus intentional project-switch reset.

Independently confirmed at inspected StudioView:517: Reality preview still uses `.id(generation)`; Study does too at :510. Composition can change these host identities while retaining selection admission at :513–514. No Reality/Study implementation edit is required. Actual native retention remains unverified.

## Remote scope and checks

Fresh `ls-remote --heads origin`, observed by 2026-11-26T14:25:48Z, advertised main `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318` and finish lanes 01–05. At those immutable commits, **all five producer blobs exactly equal inspected 721186e**; there is no newer acceptance seam in this observed set. Exact heads, blobs, commands and peer quote are preserved in **producer-comparison.json**.

No lane20 head was advertised; checked `docs/parallel/20`, `docs/parallel/BASE_SHA` and root `BASE_SHA` paths were absent in that set. This is scoped evidence, not global absence. Campaign baseline remains `f150f98e35dd735927075aac4d2f8b02295c6a67`.

Actual structural `agent_cycle.py check` and `next` exited 0 at the sparse-tree base; next reports M03 editing/accessibility/persistence outstanding. Worker tree is clean. **No builds, tests, parsing, pushes or owner edits performed.** Native focus, first-save draft retention, Observation, UI and AR remain unverified.

