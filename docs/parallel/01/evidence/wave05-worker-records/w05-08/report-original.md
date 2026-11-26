# W05-08 — accessibility, privacy, draft and first-save source review

## Identity and scope

- Worker: `/root/w05_acceptance/w05_08_privacy`; no children.
- Exact reviewed source: `363a7149e4eb6f195f478b3ce0210e33e8ac7ed0`.
- Detached sparse tree base: `ea83fa165916aaa2f55ddb88f6430b8a59ce5565` at `/workspace/scratch/e08d5190f17c/workers/w05-08/tree`. This is a review worktree, not the final source checkout. Final source was inspected exclusively through `git --no-optional-locks show` and `diff`.
- Commit: **none**. Repository edits, builds, tests, pushes, and tree deletion: **none**. The assigned build directory was unused.
- Recommendation: no new privacy or accessibility source blocker identified in the wave5 delta. Accept only the core ownership/lifecycle scope; native integration and acceptance remain outstanding.

## Source guarantees

`Sources/LightingCore/StudioFeaturePresentation.swift` stores one destination and session receipt. `StudioFeatureContext.swift` stores immutable UUID identity tokens and one `LightingScene` snapshot. These new types do not conform to Codable; `App/StudioSession.swift:35` owns the optional in-memory presentation. The complete delta adds no photo import, image storage, network, telemetry, permissions, camera-start, entitlement, export, or persistent-store behavior. The `LightingScene` definition in `Sources/LightingCore/Scene.swift:44–55` contains scene settings, lights and optional measured room, not photos, image metadata or analysis pixels. User-entered light names and room geometry can still be private scene data: this is an in-memory scene copy, not an anonymous token or a secure-erasure guarantee.

`StudioSession.swift:126–143` creates contexts with `workspaceResetID` and validates against the live parent, current logical workspace, accepted revision and loaded/writable/idle state. `ProjectLibraryOperation.swift:115–133` preserves presentation on Save while rotating storage generation on the first save. `StudioSession.swift:331–334` clears the feature only for a successful adoption that resets presentation, including switch/reload/recovery; failure paths retain it. The final added regression at `NativeTests/StudioFeatureSessionTests.swift:400–432` explicitly exercises failed Save, Reload and Recover followed by accepted feature application. I inspected this test source; I did not run it.

Scene and target-lux acceptance returns true for valid no-ops and retires callbacks synchronously (`StudioSession.swift:148–182`). Lux is restricted to the captured UUID and candela change. Room/AR permits repeated accepted room proposals under the same owner and advances only that owner's accepted revision (`:186–199`). Retirement blocks callbacks but deliberately retains the snapshot until matching teardown; the ID checks in `retireFeature` and `finishFeature` (`:204–213`) prevent delayed owner A from releasing owner B. This permits presentation animations without admitting obsolete work. Matching cleanup still has to be connected by the host.

## Concrete native integration obligations

### 1. First-save sheet and focus preservation is not implemented by this delta

`App/StudioView.swift:274` still observes storage `session.generation` and calls `dismissSceneEditors`; `:1269–1283` clears reference, arrangement, lux, room and AR payloads and closes other editors. First save changes that storage generation. Therefore preserving the new core feature does not preserve an already mounted legacy sheet when such a receipt arrives.

Wave6 must connect native route lifetime to the live feature owner and logical workspace/reset policy, while preserving storage-generation admission for ordinary control callbacks. Stable `editOwner` identity at `StudioSession.swift:274–278` supplies only a source-level prerequisite for preserving numeric drafts/focus. It cannot preserve a field after its containing sheet is removed. `App/StudioTextField.swift:73–74,183–194` dismantles/invalidates the native field and resigns first responder. No actual first-save caret, IME composition, keyboard, VoiceOver focus, or SwiftUI Observation behavior was exercised here.

### 2. Rejected drafts require producer acceptance feedback

`StudioView.swift:154–193,1201–1207,1231–1239` retains the legacy generation/equality guards; it does not route through the new live feature admission. Equal scene content after an intervening edit/undo is therefore not fenced by the new revision token in these native paths.

`App/ReferenceComparisonView.swift:116–122` calls `closeSession()` before its Void `onApply`; `:520–534` clears photo, tones, observations and candidates. Its completed-dismissal observer is at `:146–149`. A parent rejection cannot restore those already-consumed values. `App/SceneArrangementView.swift:99–107` sets `didFinish` before Void `onApply` and dismisses. `App/LightTargetLuxView.swift:108–116` similarly sets `didApply` and dismisses. The new parent Bool cannot by itself fix these producer APIs.

Coordinate an owner-provided acceptance result: preserve drafts and readable rejection feedback on false; consume/close once on true, including valid no-ops. This is a remaining integration gap, not a new regression introduced by the session-only source change.

`App/ManualRoomPlacementView.swift:158–168,185–195` already uses Bool acknowledgement and records rejection without discarding the measured planning draft. `App/ARPlacementView.swift:62–105` forwards nested manual-room changes through matching nested-owner checks. Integration should retain that nested owner under the parent AR presentation and route accepted changes through `applyFeatureRoom`; closing a nested room sheet must not finish the entire AR feature.

### 3. Retirement, cleanup and native acceptance must remain separate

Connect explicit close and actual interactive dismissal to synchronous retirement, then release only the captured owner's payload on matching teardown. Do not use an unrelated nested-sheet disappearance to retire the parent. A cancelled dismissal must retain the active draft. Preserve existing photo clear/inactive concealment and AR explicit Start-camera/lifecycle behavior; the new snapshot has no authority to broaden those paths.

Native acceptance must cover first-save with an active editor and raw draft/focus; rejection during busy or stale work; valid no-op closure; delayed A teardown after B opens; reset/switch/reload; nested/cancelled dismissal; and focus/rejection feedback with assistive technology. These are precise follow-up scenarios, not passed tests or newly alleged privacy defects.

## Actual work and evidence limits

Read required AGENTS, agents operating protocol/handoff/state, PRODUCT, ARCHITECTURE, ROADMAP, QUALITY, DESIGN, lane01 HANDOFF/INTERFACES, final interface changes, and the existing PRIVACY review. Inspected final source diff plus the specific session, persistence-adoption, scene, feature-producer, text-field and regression-test source named above.

Created the prescribed detached `--no-checkout` tree, initialized non-cone sparse checkout, applied `/workspace/scratch/e08d5190f17c/worker-sparse.txt`, and checked out the frozen base. All git commands used `--no-optional-locks`.

Actually ran at that base: `python3 scripts/agent_cycle.py check` and `python3 scripts/agent_cycle.py next`, both exit 0. Check reported valid state/evidence structure and explicitly disclaimed test truth/release readiness. Next selected M03 with editing/accessibility/persistence outstanding. Initial and final status were clean `HEAD (no branch)` at the base SHA. No build, Swift test, compiler parse, native launch, simulator/device, UI, screenshot, VoiceOver, Observation or AR check was run by this worker.

The parent supplied final-source Debug 430/0, 16 actual Session methods, 80 Swift parse exits 0, and independent verification of 173 input hashes. These are parent-reported evidence, not worker-run checks; parsing is syntax-only and portable execution does not prove native behavior. The wave5 evidence location supplied by the parent is `docs/parallel/01/evidence/wave05-final` in the root workspace. Nothing here promotes M03, later milestones, privacy certification or release readiness.

Checkpoint: `/workspace/scratch/e08d5190f17c/workers/w05-08/checkpoint.md`. Report: `/workspace/scratch/e08d5190f17c/workers/w05-08/report.md`. Scheduler owns cleanup of the completed sparse tree.
