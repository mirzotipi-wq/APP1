# W04 independent review

canonicalID: `/root/w04_acceptance/independent_review`

Input: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`  
Candidate: `b35671f971be2e2dd4d05d7531486a3de4ce25c2`

**Disposition: no source blocker found in the exact two-file candidate; native validation remains unperformed.**

The conditional mode publication precedes availability for valid input, retaining initial empty-orbit interaction. Invalid input hides/disables content and clears equipment without consuming the pending camera→orbit transition. Recovery then fits; same-mode orbit recovery preserves the user's camera. Repeated invalid updates and undefined authored-camera recovery introduce no contrary source path identified here. The four new tests distinguish these cases and use existing SceneKit/XCTest conventions.

## Coverage challenges

- Recovery assertions check position, target, identity, FOV and clipping, but omit orientation/projected containment. A stale rotation with otherwise corrected properties could satisfy them. Existing native projection coverage examines initial Fit, not this mixed-mode recovery. This limits the coverage claim; the candidate still calls the existing complete `fitOrbit` implementation.
- Baseline `SpatialViewportStateTests.assertFits` projects corners of the bounds produced by the implementation. It does not independently establish that every displayed mesh is inside those bounds. Separate emitter tests check selected SceneKit dimensions/transforms; RealityKit volume containment remains a source/mathematical conclusion.
- The bounded-state far-plane proof applies to `SpatialOrbitState` and its limits. It cannot establish SceneKit clipping after native free-camera handoff. The platform packet correctly leaves fixed-far failure conditional on the active camera retaining manual clipping; its gesture/translation/projection observation is still unrun. Pinch is not evidence of backward translation.
- First-save `.id(generation)` replacement remains a separate composition concern outside these two files; the retained-coordinator tests cannot cover it. SceneKit's VoiceOver selection predicate also does not prove native navigation is gated. Neither source asymmetry establishes observed device interference.

## Actual checks

Immutable `git show SHA:path` reads covered pinned AGENTS, architecture/design/acceptance, candidate diff, geometry, adapter and baseline test sources. Read all wave reports and the exact concurrency/platform packets. `git show -s --format=%P` verified the candidate parent above. `git diff --name-status INPUT CANDIDATE` returned exactly modified `App/SpatialPreview.swift` and added `NativeTests/SpatialNavigationRecoveryTests.swift`; `git diff --check INPUT CANDIDATE` exited 0. Python inspected pinned git bytes: four new test declarations; both candidate blobs equal those in integrated `bc5b137` and preserved `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`.

Files: this report only. Source edits/commits: none. No builds, toolchain, native/tests, rendering, device, VoiceOver or performance execution; inventories and historical passes are not current candidate acceptance.
