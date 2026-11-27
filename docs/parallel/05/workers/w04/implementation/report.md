# Wave04 implementation

canonicalID: `/root/w04_acceptance/implementation` (lane05)
inputSHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`
commit: `b35671f971be2e2dd4d05d7531486a3de4ce25c2`

## Finding and authorized repair

At frozen `App/SpatialPreview.swift:212–265`, valid orbit/Fit0 → valid camera → invalid orbit/Fit0 → valid orbit/Fit0 loses the pending Fit. The invalid update publishes `lastCameraMode=false` before returning, while `lastFitRequest=0` remains. Recovery therefore computes both `modeChanged=false` and `needsFit=false`, skipping the fitted pose/lens/clipping replacement. This is a source control-flow finding; no native failure was executed.

The authorized repair publishes `lastCameraMode` only when `valid`, before deriving interaction availability. Invalid content still hides/disables/discards equipment; the last successfully applied mode survives for recovery. Ordinary same-mode invalid→valid orbit retains navigation. Only this app file and new `NativeTests/SpatialNavigationRecoveryTests.swift` changed; no Core/composition/Plan/AR/Study edits.

## Four focused native regressions, unexecuted

Each uses one360×280 coordinator/view and unchanged Fit0, flushing SceneKit transactions:

- Orbit → authored85mm camera → duplicate-UUID invalid orbit → valid orbit.
- Orbit → coincident camera/subject clearing pointOfView → duplicate-UUID invalid orbit → valid orbit.
- Manually positioned orbit camera(7,5,9), target(1,2,3) → invalid orbit → valid orbit: preserve camera identity, position and target.
- Initial valid empty orbit: enable interaction without UUID cancellation or control toggling.

Recovery asserts visible content, enabled controls/interaction, coordinator camera identity, FOV48°, near0.02, and pose/target/far matching fresh bounds Fit using existing Float tolerances. Invalid stages assert hidden content and disabled interaction; authored recovery also checks discarded hit identities.

## Actual evidence

Frozen reads used `git -C /tmp/keyfill05-be879deb/repo show 9725fb1177a5c7afbdf798ffd627e65e604c75b1:<path>` across all four app/five spatial test files and required contracts. `git ... grep` confirmed existing tests cover these transitions separately. HEAD matched input; unrelated checkout changes were untouched.

`git worktree add --detach /tmp/keyfill05-be879deb/worktrees/w04-implementation <inputSHA>` succeeded. In that checkout, `git diff --cached --check` passed; commit succeeded; `git status --short` was empty. Exact committed diff is `change.patch`, SHA256 `6b6165acef74c09df9ba709ece84e5eb390bc7123d83c825b69cd686390e0ec9`.

Original956 source unavailable; lead's unchanged-file verification accepted. No build, compiler, native run, toolchain install, RealityKit/device/VoiceOver evidence. Historical passes do not validate this commit. Root owns exact-patch independent/concurrency review, integration and execution; production UI reachability remains unestablished.
