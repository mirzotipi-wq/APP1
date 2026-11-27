# Wave 03 — implementation

- Worker: `/root/w03_acceptance/implementation`
- Input: `35283bed09c609be424df80f36b42391aec19f74`
- Commit: `44550b6837656e86f4fa7b588ac4cfe7a9b1c361`
- Private detached worktree: `/tmp/keyfill05-be879deb/worktrees/w03-implementation`
- Sole committed file: `NativeTests/SpatialEntityUpdateTests.swift` (217 lines; three test methods).
- Patch: `/tmp/keyfill05-be879deb/waves/w03/implementation/SpatialEntityUpdateTests.patch`

## Coverage

1. `testKindTransitionsReplaceShapeWithoutReplacingLiveLampNodes`: drives point → directional → rectangle → point through actual `updateView`. Requires fixture, source node, `SCNLight`, indicator, stand and cylinder identity continuity; requires fresh fixture/outline geometry for each kind transition. Checks source type, meter dimensions, housing front plane, rolled basis and source −Z direction. Stored rectangle dimensions edited while directional must preserve housing/outline geometry.
2. `testRectangleResizingReplacesGeometryWhilePoseAndOutputEditsReuseIt`: changes width and height separately between two unchanged-dimension edits. Pose, subject target, roll, name, output and temperature change concurrently. Checks selective geometry replacement/reuse, matching outline dimensions, output updates and the authored emitting plane.
3. `testStandThresholdDetachesHitsAndReattachesTheSameCylinder`: exercises 0.051 m, exactly 0.05 m, 0.049 m, 1.25 m, zero and 2.5 m. Requires detached stands to lose graph/hit membership; reattachment must reuse the original node/cylinder, update height and midpoint, and restore hit membership without accumulating nodes or replacing fixture/outline geometry.

## Actual verification and limits

Read the pinned implementation, existing spatial native tests, lane plan and project guidance. `git diff --cached --check` passed. Commit inspection confirmed exactly one added file; private worktree is clean. Root sparse-checkout and worktree-config SHA-256 values match their pre-worktree values.

**Three native tests authored; zero native tests executed.** No Swift compiler, build or replacement toolchain was invoked. The environment lacks the required toolchain after reset. Existing native CI `45817222487` refers to source `68c83cc`, not this commit; it supplies no execution evidence for these tests. This work establishes no native pass, performance result or release acceptance.

Test source SHA-256: `23c0415de68fe2a0d300ae70f0c8fdd686e27b96d828d01c14ce7601356d1cd2`.

Patch SHA-256: `c9744cf187064ad1b32345abe4516c76f7e038a96038cc1f559fec4829dd2717`.

Recommendation: independent source review, serial cherry-pick by root, then Apple CI execution with the integrated native inventory. No product/source changes are included. Rollback is removal/revert of this single added test file.
