# Wave 05 reports

Ten actual contexts; original reports are retained below. Separate completion receipts preserve the interrupted writer/reviewer history.

---

## acceptance

# Wave 05 — acceptance contract

Input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`; canonical worker `/root/w05_acceptance`. Source review only; no native execution.

## Scoped check and acceptance

Reviewed pinned `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, lane 05 PLAN/CHECKPOINT/OWNER_REQUESTS/RECOVERY, and the selection/update paths in the three viewport adapters. The wave accepts the following behavior without changing the existing product thresholds:

1. A fixture, visible descendant/outline, or enabled stand resolves only through a registered live object identity under the current content/anchor. Hidden/disabled descendants and detached/deleted objects resolve nil, including after reintroduction of the same UUID.
2. Invalid content removes equipment registrations and detaches equipment roots. Valid recovery allocates replacement equipment; retained old roots and descendants never regain selection authority.
3. An identical-scene update replaces callback A with B before returning early; changing B to nil clears callback authority without rebuilding live equipment or changing the useful viewpoint. Callback invocation in a unit test is not gesture execution.
4. Actual tap delivery requires current interaction/lifecycle/window/mode eligibility and current-scene membership. A direct resolver may still identify retained live geometry while interaction is disabled; that does not establish delivery.
5. Project replacement with overlapping UUIDs is a composition identity boundary. Ordinary same-UUID scene edits preserve live geometry. Adapter-local evidence cannot prove the parent generation guard or workspace replacement behavior at runtime.

## Source findings and evidence boundary

`SpatialPreview.updateView` refreshes `onSelect` at line 207 before its line 213 early return. `lightID(for:)` at lines 150–162 checks current availability, hidden state, root registration, direct content parent and live UUID membership. Its action at lines 141–145 performs a fresh hit and invokes the current callback after admission. `StudioEntityGraph.lightID(for:)` at lines 127–136 checks enabled ancestors, registered root identity and direct anchor parent; RealityKit delivery additionally checks current-scene UUID membership.

Existing native tests change scene values while exercising callback replacement, and deletion/recovery tests retain only the old fixture. The writer is scoped to at most three new native methods covering unchanged-scene callback transitions and fuller retained-node lifetime. Acceptance of that patch requires an independent exact-diff review, then root-owned native execution. Source evidence supports the contract; current native, RealityKit device, VoiceOver and performance acceptance remain unobserved. Historical 171/25-spatial passing evidence at `68c83` is not a test result for this input.


---

## geometry

# Wave 05 — geometry/invariants

Reviewer: /root/w05_acceptance/geometry  
Frozen source: deffb5e3c93b507ceb4189a414a4ff0e3cf19395

**Verdict:** No source-proven violation of the accepted stale-hit contract found. This is source review, not native acceptance.

**SceneKit:** `SpatialPreview.Coordinator.lightID(for:)` (`App/SpatialPreview.swift:150–162`) requires available, visible orbit content; rejects hidden nodes along the ancestor walk; then requires registered object identity, immediate parent equal to current content, and UUID membership in the current scene. Attached fixture descendants and visible outlines resolve through their registered fixture. Detached descendants have no such ancestor. `updateContent` (349–407) removes deleted fixtures and rebuilds registrations; `discardEquipment` (95–103) clears invalid-scene identities. Reintroducing a removed UUID therefore does not authorize the retained old fixture, outline or stand. Stand registration and attachment track height (405–407,449–460).

**RealityKit:** `StudioEntityGraph.lightID(for:)` (`App/StudioEntityGraph.swift:127–136`) requires an enabled graph and enabled ancestry, registered root identity, `lights[id]?.root === item`, and direct parent equal to the current anchor. `update` (69–79,100–115) unregisters/removes deleted roots and clears invalid graphs. Selection and stand visibility use `isEnabled` (281–284,306). The resolver itself does not verify anchor attachment to a rendered scene; production selection additionally requires `RealityStudioPreview.Coordinator.canInteract` (154–157), rendering state (170–186), and current-scene membership in `selectLight` (273–278).

**Geometry:** `SpatialViewportBounds.init(scene:)` (`App/SpatialViewportGeometry.swift:12–62`) includes housing, outline and stand bounds; it supplies no hit-identity authorization.

**Concrete evidence gap:** `SpatialInteractionTests` (50–85) covers old fixture rejection after same-UUID replacement/invalid recovery. `SpatialEntityUpdateTests` (47–63,187–215) covers current outline/stand hits and stand detachment. `SpatialEmitterGeometryTests` (126–131) checks outline hiding, but never asserts that the hidden outline resolves to nil. Reviewed tests also lack direct negative assertions for hidden/reparented intermediate descendants and old outline/stand objects after replacement; RealityKit behavior here remains source-only.

Evidence boundary: deff inventory is 180 native/34 spatial methods, discovered but unexecuted. Historic 68c8 results (171 native, including 25 spatial) do not validate deff. No repository changes or execution claims.


---

## interfaces

# Wave05 interfaces — source-only review

Frozen revision: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`. Read pinned AGENTS, operating/continuity documents, product, architecture, roadmap, quality and design guidance.

**Result: no newly demonstrated interface gap.** The concrete check distinguishes replacing a project while retaining every light UUID—even an identical scene—from an ordinary scene update.

**Callback refresh:** `SpatialPreview.updateView` assigns the latest callback before its equality exit (`App/SpatialPreview.swift:204–213`). `RealityStudioSurface.Coordinator.update` likewise replaces its callback before updating the graph (`App/RealityStudioPreview.swift:189–199`); `StudioEntityGraph.update` may then return for equal scene/selection (`App/StudioEntityGraph.swift:69–80`). Therefore an unchanged scene does not retain the previous callback.

**Adapter boundary:** Neither adapter receives project identity. Existing UUIDs intentionally reuse nodes/entities (`SpatialPreview.swift:349–368`; `StudioEntityGraph.swift:100–115`). Their ownership checks reject removed/detached objects (`SpatialPreview.Coordinator.lightID:150–161`; `StudioEntityGraph.lightID:127–136`), but a retained object for an unchanged UUID remains current within the same coordinator. UUID-set comparison cannot distinguish replacement from ordinary editing.

**Composition boundary:** `StudioView.workspace` captures generation, rejects obsolete/busy callbacks and checks the live scene for the selected UUID before assignment; `.id(generation)` supplies replacement identity (`App/StudioView.swift:483,506–511`). The underlying guard requires both idle state and matching generation (`App/ProjectLibraryOperation.swift:81–83`); reload/recovery invalidates generation even when the project UUID is unchanged (`adopt:126–133`). Expected behavior is retained geometry/orbit for ordinary edits, current callbacks for equal-scene updates, and a new coordinator for a generation-changing replacement.

No composition edits or new owner request. The previously documented first-save reset remains with its existing owner action.

**Evidence limit:** GitHub source inspection only; executor unavailable. No build, tests, gestures or RealityKit runtime exercised. The supplied deff inventory of 180 native/34 spatial methods remains unexecuted; historical 68c83 results are not deff evidence.


---

## implementation

# Wave 05 implementation checkpoint

Base: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`. Scope: new `NativeTests/SpatialSelectionLifetimeTests.swift` only. **Commit: none.**

Prepared three native methods. The first keeps scene, selection and Fit request identical while changing callback A to B and then nil, checks UUID delivery through direct callback invocation, and verifies persistent content identities, selection indicator, camera identity, orbit position and controller target. The other methods retain fixture, indicator, stand and source references across deletion/reinsertion and invalid-scene/recovery, respectively. They assert lost live-content ancestry, rejection of stale hit objects, fresh node identities after the same UUID returns, and successful lookup of replacement selectable nodes.

Coverage gap: `SpatialInteractionTests` changes metadata/output during callback replacement and retains only the fixture during removal/recovery; `SpatialEntityUpdateTests` covers live mutations and stand thresholds, not removal of all retained equipment. The new indicator assertion allows it to remain under its detached fixture. No production defect or change is claimed.

Completed checks: pinned `git ls-tree` path discovery; `git show` inspection of `AGENTS.md`, startup documents, the three existing spatial test files and three relevant production files; `git status --short --branch`; `git log -4 --oneline` at the pinned base. `git worktree add --detach /tmp/keyfill05-be879deb/worktrees/w05-implementation deffb5e3c93b507ceb4189a414a4ff0e3cf19395` completed successfully.

The environment became unavailable during `apply_patch`. The pending call was terminated without a completion result; **the file write is unconfirmed**. No git diff check, file discovery check, build, native execution or commit completed. No tap, RealityKit, device, VoiceOver or performance execution is claimed.

Exact source, generated new-file patch, report and intended filenames are preserved in functions store. Disk artifacts and commit remain pending restoration. Lead should review the source-only patch, materialize it in the private worktree, run `git diff --check`, commit only the new file, then perform native validation on the integrated revision.



### Separate completion receipt

# Wave 05 implementation completion

Commit: `3d5338dc81000d1316c4d966cdb5eb7211ce4622`. Parent: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`. The private worktree remains detached at `/tmp/keyfill05-be879deb/worktrees/w05-implementation`.

Committed scope is exactly one new file, `NativeTests/SpatialSelectionLifetimeTests.swift`: 162 lines, 8,084 bytes, three test methods. Source SHA-256: `865039692d90744ebb8e23a4fe34c5cf6fb71ed1eb825a93394f8544d4080c27`.

The tests cover callback A→B→nil with an identical scene, selection and Fit request while retaining equipment and orbit; all retained equipment after deletion/reinsertion; and all retained equipment after invalid-scene/recovery. The retained indicator may remain under its detached fixture. Direct callback invocation checks callback publication, without claiming gesture delivery. No production source changed.

Recovery provenance: the resumed functions store lacked the previous source entry. The candidate was reconstructed verbatim from the exact 162-line source in the prior final handoff, which independent review had accepted without corrections. No pre-outage source digest exists, so no comparison against an original cryptographic receipt is claimed. Both the materialized UTF-8 file and committed blob compare equal byte-for-byte to that recovered candidate. Independent comparison of the committed file against the reviewer’s conversation copy is the lead’s next review step.

Completed checks:
- `git diff --cached --check` and `git diff --check`: exit 0.
- `rg -n '^    func test' NativeTests/SpatialSelectionLifetimeTests.swift`: exactly three methods.
- Pinned `project.yml` inspection: `KeyAndFillTests` includes `NativeTests`; the `KeyAndFill` test scheme includes that target.
- `git rev-parse HEAD HEAD^`: expected detached commit and pinned parent.
- `git diff-tree --no-commit-id --name-status -r HEAD`: only the new test file.
- `git status --porcelain`: empty after commit.
- Source comparison, `sha256sum`, and committed-blob comparison: matching source bytes.

The original `report.md` checkpoint is preserved unchanged, with SHA-256 `17874cca44ab0ee772411f1cc0ec073ec5b8040c3768a49196d439352b5cac86`. Companion artifacts are `SpatialSelectionLifetimeTests.swift`, `change.patch`, and `commit.txt`.

Native tests remain unrun. No build, toolchain install, broad test sweep, integration, cherry-pick or push was performed. No RealityKit, device, VoiceOver or performance execution is claimed. Root owns integration and native validation.

---

## concurrency

# Wave 05 — concurrency review

Worker: `/root/w05_acceptance/concurrency`  
Frozen input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`  
Disposition: no concrete ordering defect found; source review only.

One bounded review covered late selection against scene replacement/deletion, disabled or inactive state, window removal, invalid input, and camera/orbit transitions. Read pinned GitHub files plus lane 05 PLAN; no source edits, builds, or test execution.

Both coordinators and their update/gesture methods are MainActor-isolated and synchronous. Selection resolves the current hit and invokes the current callback without an intervening suspension. SceneKit refreshes `onSelect` before its geometry-equality return (`App/SpatialPreview.swift:204–213`); RealityKit refreshes before graph update, whose own equality return therefore cannot retain an old callback (`App/RealityStudioPreview.swift:189–205`).

Changed UUID sets cancel gestures before graph reconciliation. Invalid SceneKit content disables interaction, clears callbacks/equipment, and resets the scene; RealityKit clears `currentScene` and disables interaction; graph bounds failure independently clears ownership. SceneKit publishes the valid camera mode before computing interaction availability, clears the camera-mode callback immediately, and refreshes gesture dependencies after changing camera control (`SpatialPreview.swift:223–250`). Its environment gate follows `updateView` synchronously, so a queued tap cannot execute between those two calls.

Delivery checks current enabled/content/mode/window state in SceneKit (`SpatialPreview.swift:136–145`) and rendering/enabled/current-scene/window state in RealityKit (`RealityStudioPreview.swift:154–186,273–278`). RealityKit window removal also detaches anchors and cancels gestures; both dismantlers remove targets and callbacks. Ownership resolvers reject removed/detached equipment (`SpatialPreview.swift:150–162`; `App/StudioEntityGraph.swift:100–136`). A direct resolver call is only identity resolution: it does not prove a gesture callback can run while disabled or outside a window.

Same-UUID project generation protection was outside this bounded check, as independently reviewed by the parent. Native residual: exercise pending taps through UUID changes, window removal/reattachment, and competing camera gestures on Apple platforms. No native, RealityKit, VoiceOver, or performance execution is claimed; the supplied 180-native/34-spatial counts are discovered coverage only.


---

## resources

# Wave 05 resources review

Frozen source: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`. Read-only, one retained-hit lifetime check; no build or source edits.

**Finding:** source supports revoking old-hit selection authority through deletion, invalid-scene recovery, and SceneKit dismantle. It does not prove object deallocation.

- **SceneKit deletion/recovery:** `lamps` owns the four-node wrapper; `selectionIndicators` separately references its indicator; `lightIDs` stores identity keys and UUIDs. Deletion removes the wrapper/indicator entries, detaches fixture, source and stand, and rebuilds identity entries from surviving fixtures/stands. Invalid input disables/hides content, clears the callback, detaches all equipment and clears all three maps plus `lastScene`. Recovery creates replacement equipment, including for the same UUID. The indicator remains a child of its detached fixture; a retained fixture can therefore retain that indicator. A deliberately retained source or stand can likewise keep its light/geometry. These retained objects do not acquire replacement selection authority. The source is never an identity-map entry; the indicator resolves through its fixture only while current. [Source: `App/SpatialPreview.swift`, 95–103, 148–163, 224–238, 349–369, 405–408, 475–481.]

- **SceneKit dismantle:** `detach` clears callback/gesture links, scene and point-of-view references, content children, equipment maps, base and cached state. The coordinator still owns its empty content/camera nodes; external old-hit references may remain alive. Selection rejects them through unavailable content and cleared maps. [Source: `App/SpatialPreview.swift`, 106–135, 150–163, 200–202.]

- **RealityKit comparison:** deletion/invalid input remove lamp ownership entries, root identity entries and anchor parent links; resolution also requires the currently owned root and its current anchor parent. Coordinator detach removes view anchors, gesture/callback links and current-scene/view state, but does not clear its strongly owned graph or graph maps/subtrees. Thus graph-only resolution is not a view-attachment test; production dispatch is disabled by `isRendering = false`, nil current scene/view and callback. Retained detached subtrees are distinct from active selection authority. [Source: `App/StudioEntityGraph.swift`, 14–22, 69–79, 100–137; `App/RealityStudioPreview.swift`, 98–106, 154–156, 208–225, 273–278.]

**Evidence limit:** no leak, allocation-bound, timing, performance or deallocation conclusion. Existing frozen tests cover retained fixtures; the reported three-method `SpatialSelectionLifetimeTests` candidate extends four-node checks outside this SHA and still needs native execution. Historical `68c83` 171 native/25 spatial passes do not validate `deff`; its 180 native/34 spatial counts are discovery only.


---

## interactions

# Wave 05 — interactions
Worker: /root/w05_acceptance/interactions. Frozen source: deffb5e3c93b507ceb4189a414a4ff0e3cf19395. Pinned git show review includes AGENTS.md/lane-05 PLAN. No source edits, builds, installation, or native execution.

## Finding
SceneKit consumes only hitTest(...).first. Its resolver walks visible ancestors to a registered fixture/stand directly under content, checking current UUID membership. An indicator reaches its fixture; a first non-equipment hit returns nil without searching behind it (App/SpatialPreview.swift:141,150,367,405).

RealityKit uses entity(at:), then enabled ancestry to the identical registered root under its anchor; the handler rechecks membership (App/RealityStudioPreview.swift:273; App/StudioEntityGraph.swift:127). Only point/housing/stand/feet receive collision components; face/outline/aim markers and subject/camera/floor do not (StudioEntityGraph.swift:25,177,220,243). Resolver success therefore does not prove screen acquisition or depth parity.

Live UUID continuity intentionally preserves roots across edits. Deleted/invalid-scene roots are detached and unregistered; reintroducing their UUID creates replacements (SpatialPreview.swift:232,349; StudioEntityGraph.swift:69,100).

## Coverage
SpatialEntityUpdateTests:47 directly asserts fixture/indicator/stand resolution and stand reuse/detachment. SpatialInteractionTests:19,50,67 directly invokes onSelect and checks removal/recovery identities. The three private SpatialSelectionLifetimeTests methods at 3d5338dc81000d1316c4d966cdb5eb7211ce4622 extend callback refresh/clearing and retained-node rejection. These tests do not deliver taps or establish non-equipment depth behavior.

## Bounded native plan
Root-owned execution: active, attached 360×280-point host, VoiceOver off; separately identify SceneKit simulator and RealityKit-capable physical device. Deliver three XCUI coordinate taps per target.

1. Isolated point/rectangle: body/face, selected outline-only edge outside housing, stand midpoint; additionally RealityKit feet. Record screenshots, acquired ancestry, callback UUID/count. Acquired current equipment requires one callback; nil/non-equipment requires zero.
2. Rectangle successively occluded by subject, camera, and floor: verify projected depth, tap overlap and exposed control. Record whether RealityKit selects through visible non-equipment and whether outline-only taps differ. No parity claim without execution.
3. Repeat body taps after metadata edits, deletion, and same-UUID reinsertion: current selection survives edits, deletion gives zero callbacks, replacement selects once.

Disposition: source review only. Supplied deff discovery: 180 native/34 spatial, unexecuted. Historical 68c83 simulator 171/25 passes and captures are fallback evidence; they do not establish this gesture matrix or RealityKit device execution.

---

## accessibility_privacy

# Wave05 accessibility/privacy — selection path

Worker: `/root/w05_acceptance/accessibility_privacy`
Input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`
Disposition: source review supports the list alternative; removed-selection VoiceOver feedback remains unverified. No source changes, builds, or native execution.

**Selection alternative.** `App/StudioView.swift` supplies named Lights buttons with a 52-point minimum row height, checkmark, and selected accessibility trait (L927, L942, L944, L948). Selection does not rely on color alone. Each action checks the current light UUID; `sceneAction` captures and checks the editor generation (L928, L1220). The spatial callback independently checks generation and current membership (L506). This depends on the generation contract already owned by lane01; no new ownership request.

**Removed selection.** Removal uses the captured target and generation (L253). `replace`, undo, and redo call `repairSelection`: retain a live selection, otherwise select the first remaining light or nil (L1321, L1330, L1333, L1338). The inspector follows that UUID, and an empty rig exposes “No light selected” (L114). There is no explicit announcement or accessibility-focus handoff in this reconciliation path. That is a native verification gap, not a demonstrated VoiceOver failure.

**Viewport boundary.** Both renderers hide implementation nodes and reject selection gestures while VoiceOver runs (`SpatialPreview.swift` L136, L187; `RealityStudioPreview.swift` L78, L154). Callback refresh occurs on each update; SceneKit resolves live attached nodes and RealityKit checks resolved UUID membership before dispatch (Spatial L150, L204; Reality L189, L273). The SceneKit unavailable message is separately exposed (Spatial L498).

**Native test plan, unrun.** On an arm64 iPhone running this revision with VoiceOver enabled: select 3D; navigate to Lights; select a nonfirst light; verify its spoken name/selected state and matching inspector. Remove it and verify understandable focus/feedback plus the first remaining selection. Undo/redo, then remove the final light and verify the empty state. Repeat at the largest accessibility text size. Record device/OS, SHA, speech/focus observations and captures; separately exercise stale UUID/generation callbacks in native tests. Intel SceneKit captures alone cannot establish VoiceOver behavior.

**Evidence/privacy limits.** Reviewed the three methods added at `3d5338dc`: callback publication and retained-node resolver tests, not gesture or VoiceOver execution. Historical `68c83` results do not validate this revision’s discovered tests. The traced selection path passes UUIDs locally; no upload invocation was observed in that path. This is not an application privacy audit.


---

## platform_performance

# W05 platform/performance — acquisition boundary

Worker: `/root/w05_acceptance/platform_performance`  
Frozen input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`  
Disposition: source/API review complete; native behavior unexecuted. No source edits, builds, installations, or tests.

## Finding

RealityKit’s tap handler acquires one entity with `entity(at:)`, then walks ancestors through `StudioEntityGraph.lightID(for:)`. Resolution requires enabled ancestors, a current indexed light root, and that root’s direct ownership by the graph anchor; the handler additionally checks the current scene’s light IDs. Apple documents that acquisition ignores entities lacking a collision component.[1]

Only point, housing, stand, and feet receive collisions. Face, outline, aim markers, subject, camera, floor, and grid do not. Consequently, manually resolving a decorative descendant verifies ownership, not its acquisition by a screen tap. A tap over the face may still intersect housing behind it.

SceneKit calls `hitTest(..., options: nil).first` and resolves only that result’s node. The resolver checks visible ancestry, current identity, direct content ownership, and current-scene membership. Apple documents hit testing as geometry search along the screen-point segment.[2] If the first result is non-equipment, this handler returns without considering later results.

**Source/API inference:** non-colliding scenery cannot intercept RealityKit acquisition, while a non-equipment first SceneKit result blocks selection. This is an acquisition-contract difference; actual projection, gesture delivery, and occlusion behavior remain unmeasured.

## Runtime/evidence limits

The `targetEnvironment(simulator) && arch(x86_64)` surface branch returns `SpatialPreview` before constructing the RealityKit surface/coordinator/graph. This establishes fallback routing for that entry path, not RealityKit support.

Parent-supplied inventory: frozen `deff` has 180 native/34 spatial tests discovered, unexecuted; the separate three-test addition gives 183/37, also unexecuted. Historical `68c83` 171/25 passing evidence covers the SceneKit fallback, not RealityKit or `deff`. No device, latency, thermal, frame-rate, or leak conclusions follow.

One remaining native check: on a RealityKit-capable runtime, project a housing/foot and overlap it with subject geometry; record acquired entity and resolved UUID, then compare SceneKit’s first result at equivalent taps.

Source anchors: `App/RealityStudioPreview.swift` (surface/selectLight), `App/StudioEntityGraph.swift` (lightID/resources/lamp construction), `App/SpatialPreview.swift` (selectLight/lightID), read via pinned `git show`.

[1]: https://developer.apple.com/documentation/realitykit/arview/entity(at:).md
[2]: https://developer.apple.com/documentation/scenekit/scnscenerenderer/hittest(_:options:).md


---

## independent_review

# Wave 05 — independent review

Worker: `/root/w05_acceptance/independent_review`  
Frozen input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`  
Candidate: `NativeTests/SpatialSelectionLifetimeTests.swift`, exact two-part source supplied by the lead; three test methods.

**Verdict: accept the candidate source without correction.** This is source review only. No file write, commit, compilation, or native execution is established.

Read AGENTS.md, docs/parallel/05/PLAN.md, docs/DESIGN.md, SpatialInteractionTests.swift, SpatialEntityUpdateTests.swift, Scene.swift and [SpatialPreview.swift at the frozen revision](https://github.com/mirzotipi-wq/APP1/blob/deffb5e3c93b507ceb4189a414a4ff0e3cf19395/App/SpatialPreview.swift).

- **Callback coverage:** the initial render establishes the unchanged scene, selected UUID, orbit mode and Fit request 0. Both A→B and B→nil therefore reach the early-return guard with all change predicates false. A is invoked before replacement; subsequent assertions establish B delivery, no further A delivery, and callback removal. Top-level node identities, indicator identity, camera identity, camera position and controller target are checked after both updates. This adds the unchanged-scene replacement/removal case absent from the existing metadata-edit test.
- **Deletion and invalid recovery:** all four original node objects remain strongly retained. Fixture, stand and source roots must detach; the indicator may remain under its detached fixture. Each old object must reject resolution before and after same-UUID reconstruction. Replacement identities differ, all three roots attach to current content, and current fixture/indicator/stand resolve to the UUID with a visible selection indicator. Source attachment is checked without falsely asserting that a source node is selectable.
- **Fixture and typing checks:** the single point light at height 2 produces one omni source and one cylinder, matching the helper filters. Scene validation accepts an empty rig and rejects the duplicated UUID. Closure unwrapping/invocation, Float array comparisons, object-identity checks and MainActor usage are plausible and consistent with existing native tests; this is not compiler evidence.

**Material residuals:** run these three methods on the restored Apple test target and verify target inclusion. Direct callback/resolver calls do not establish actual gesture delivery, VoiceOver behavior, cross-project composition identity, device performance or release readiness. No production change is requested.



### Separate completion receipt

# Wave 05 — independent review completion

Worker: `/root/w05_acceptance/independent_review` (same-context follow-up; no additional worker).  
Reviewed commit: `3d5338dc81000d1316c4d966cdb5eb7211ce4622`.

**Verdict: accept this commit for integration on source-review grounds.** I found no textual or substantive difference between all 162 lines of the lead-forwarded committed `git show` output and the original two-part candidate messages. The helpers, three methods, assertions, comments, spacing and blank-line boundaries match.

Actual checks:

- One attempted local read-only `exec_command` failed before execution: “No usable execution environment is available.” I did not independently execute Git or filesystem checks.
- I reconstructed the original message text in functions store: 162 newline-terminated lines, 8,084 ASCII bytes. I then compared both forwarded committed-source messages against the original source messages.
- Lead-mediated `git rev-parse <commit>^` reports parent `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`.
- Lead-mediated `git diff-tree --no-commit-id --name-status -r <commit>` reports only `A NativeTests/SpatialSelectionLifetimeTests.swift`.
- Lead-mediated `sha256sum` of the private-worktree file reports `865039692d90744ebb8e23a4fe34c5cf6fb71ed1eb825a93394f8544d4080c27`. This digest was supplied by the lead, not independently calculated here.

The original review and this follow-up are source/text comparisons, not certification against a retained pre-outage byte digest; none existed. No build or test was run. Native compilation/execution remains unverified by this review.

I did not modify `report.md`. Its lead-supplied preservation digest is `2dfee6df1f78433ae766f957d6ec9a61e9575701deb1688ff906c5cc527fc822`. This completion is separate and stored for lead materialization because this context’s executor remains unavailable.

